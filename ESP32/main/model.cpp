/*
    Property of Texas A&M University. All rights reserved.
*/

#include "model.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "custom_globals.h"

#include <vector>
#include <string>
#include <sstream>
#include <cmath>
#include <cstdint>
#include <math.h>

#include "i2c_driver.h"

// ================= External fluoride value =================
// Define EXACTLY ONCE in the sensor/MCU reader module as:
//     volatile float g_fluoride_ppm = NAN;
extern "C" {
    volatile float g_fluoride_ppm = 0;
    volatile float g_flow_rate = 0;
}

// ========== Embedded coefficient blobs (linker symbols) ==========
extern "C" {
    extern const uint8_t _binary_PolyCoefficients_txt_start[] asm("_binary_PolyCoefficients_txt_start");
    extern const uint8_t _binary_PolyCoefficients_txt_end[]   asm("_binary_PolyCoefficients_txt_end");
    extern const uint8_t _binary_PIDCoefficients_txt_start[]  asm("_binary_PIDCoefficients_txt_start");
    extern const uint8_t _binary_PIDCoefficients_txt_end[]    asm("_binary_PIDCoefficients_txt_end");
}

// ===================== Internal state =====================
struct PID { float Kp; float Ki; };

static std::vector<float> s_poly;       // expect 4 coeffs: a3 a2 a1 a0
static std::vector<PID>   s_pidTable;   // rows for integer errors [errorMin .. errorMax]
static int                s_errorMin = -50;   // table[0] corresponds to error = -50 ppm

// runtime tuning
static float   s_target_ppm = 30.0f;
static float   s_change_threshold_ppm = 0.0f;   // trigger on any delta by default

// watcher/task lifecycle
static bool    s_watcher_started = false;

// ---------- Control behavior ----------
static bool        s_ff_done   = false;   // initial polynomial dose applied?
static double      s_u_last    = 0.0;     // last command (mL/s) == limeFlow(k-1)
static TickType_t  s_last_tick = 0;       // for dt calculation

// Incremental PI history (errors)
static float s_prev_err  = 0.0f;          // e[k-1]
static float s_prev2_err = 0.0f;          // e[k-2] (kept if you later enable derivative)

// Dosing limits (tune for your plant)
static constexpr double DOSE_MIN_FLOOR = 0.005; // mL/s minimum to keep CSTR wetted
static constexpr double DOSE_MAX       = 20.0;  // mL/s hardware/chemistry max
static constexpr float  ERR_DEADBAND   = 0.0f;  // e.g. 0.2f ppm to “hold” when on target

// =================== Forward declarations ===================
static void   load_poly_from_flash();
static void   load_pid_table_from_flash();
static double poly_eval_cubic(double x);
static PID    pid_for_error(float err);
static void   run_model_from_fluoride(float fluoride_ppm);
static void   fluoride_watch_task(void* arg);

// ======================== Public API ========================
extern "C" void model_init(void)
{
    load_poly_from_flash();
    load_pid_table_from_flash();

    // reset behavior
    s_ff_done   = false;
    s_u_last    = 0.0;
    s_last_tick = 0;
    s_prev_err  = 0.0f;
    s_prev2_err = 0.0f;
}

extern "C" void model_set_target_ppm(float target_ppm)
{
    s_target_ppm = target_ppm;
}

extern "C" void model_set_change_threshold_ppm(float threshold_ppm)
{
    if (threshold_ppm < 0.0f) threshold_ppm = 0.0f;
    s_change_threshold_ppm = threshold_ppm;
}

extern "C" void model_start_watcher_task(void)
{
    if (s_watcher_started) return;
    s_watcher_started = true;
    xTaskCreatePinnedToCore(fluoride_watch_task, "fluoride_watch", 4096, nullptr, 6, nullptr, tskNO_AFFINITY);
}

// ====================== Implementation ======================
static void load_poly_from_flash()
{
    const size_t length = _binary_PolyCoefficients_txt_end - _binary_PolyCoefficients_txt_start;
    if (ENABLE_DEBUG_LOGGING) printf("MODEL: PolyCoefficients.txt size = %d bytes\n", (int)length);

    std::string file(reinterpret_cast<const char*>(_binary_PolyCoefficients_txt_start), length);
    std::stringstream ss(file);

    s_poly.clear();
    float v;
    while (ss >> v) s_poly.push_back(v);

    if (s_poly.size() < 4) {
        if (ENABLE_INFO_LOGGING) printf("MODEL: Expected 4 polynomial coefficients (a3 a2 a1 a0); got %u\n", (unsigned)s_poly.size());
        while (s_poly.size() < 4) s_poly.push_back(0.0f); // pad to avoid OOB
    } else if (s_poly.size() > 4) {
        if (ENABLE_INFO_LOGGING) printf("MODEL: Found %u polynomial coefficients; using the first 4\n", (unsigned)s_poly.size());
        s_poly.resize(4);
    }
}

static void load_pid_table_from_flash()
{
    const size_t length = _binary_PIDCoefficients_txt_end - _binary_PIDCoefficients_txt_start;
    std::string file(reinterpret_cast<const char*>(_binary_PIDCoefficients_txt_start), length);
    std::stringstream ss(file);

    s_pidTable.clear();
    float Kp, Ki;
    while (ss >> Kp >> Ki) {
        s_pidTable.push_back(PID{Kp, Ki});
    }

    if (s_pidTable.empty()) {
        if (ENABLE_DEBUG_LOGGING) printf("MODEL: PID table is empty! PI corrections will be zero.\n");
    } else {
        const int errorMax = s_errorMin + (int)s_pidTable.size() - 1;
        if (ENABLE_DEBUG_LOGGING) printf("MODEL: PID rows loaded: %u (error range: %d..%d ppm)\n", (unsigned)s_pidTable.size(), s_errorMin, errorMax);
    }
}

static inline int clamp_int(int v, int lo, int hi)
{
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

static double poly_eval_cubic(double x)
{
    // a3*x^3 + a2*x^2 + a1*x + a0
    return (double)s_poly[0]*x*x*x + (double)s_poly[1]*x*x + (double)s_poly[2]*x + (double)s_poly[3];
}

static PID pid_for_error(float err)
{
    if (s_pidTable.empty()) return PID{0.f, 0.f};
    int idx = (int)roundf(err) - s_errorMin;
    idx = clamp_int(idx, 0, (int)s_pidTable.size() - 1);
    return s_pidTable[(size_t)idx];
}

// --------- Initial polynomial once, then incremental PI ----------
static void run_model_from_fluoride(float fluoride_ppm)
{
    const float Fpred_ppm = fluoride_ppm; // if you later filter/predict, use that value instead

    // dt (s)
    TickType_t now = xTaskGetTickCount();
    float dt = 0.0f;
    if (s_last_tick != 0) {
        dt = (now - s_last_tick) * (portTICK_PERIOD_MS / 1000.0f);
        if (dt <= 0.0f) dt = (portTICK_PERIOD_MS / 1000.0f);
    } else {
        dt = (portTICK_PERIOD_MS / 1000.0f);
    }
    s_last_tick = now;

    // ---- 1) Initial dose: polynomial ONLY ----
    if (!s_ff_done) {
        const double u_ff = poly_eval_cubic((double)Fpred_ppm);
        s_u_last   = u_ff;       // this is limeFlow(k-1) for the next PID step
        s_prev_err = 0.0f;
        s_prev2_err= 0.0f;
        s_ff_done  = true;

        if (ENABLE_DEBUG_LOGGING) printf("MODEL: INIT: FF-only | Fpred=%.2f ppm | u_ff=%.4f mL/s", Fpred_ppm, u_ff);
        return;
    }

    // ---- 2) Proper incremental PI (no polynomial in the loop) ----
    const float err = Fpred_ppm - s_target_ppm;

    // Gain scheduling by current error
    const PID pid = pid_for_error(err);
    const float Kp = pid.Kp;
    const float Ki = pid.Ki;

    // Optional: deadband "hold"
    if (fabsf(err) <= ERR_DEADBAND && fabsf(s_prev_err) <= ERR_DEADBAND) {
        // hold last output
        if (ENABLE_DEBUG_LOGGING) printf("MODEL: PID inc (hold) | Fpred=%.2f | err=%.2f | cmd=%.4f mL/s", Fpred_ppm, err, s_u_last);
        return;
    }

    // Increments: Δu = Kp*(e_k - e_{k-1}) + Ki*dt*e_k
    const float dP = Kp * (err - s_prev_err);
    const float dI = Ki * dt * err;
    // If you add derivative later: dD = Kd * ((e_k - 2e_{k-1} + e_{k-2}) / dt)

    double u = s_u_last + (double)dP + (double)dI;

    // Clamp to safe range with a small floor for CSTR
    if (!std::isfinite(u)) u = DOSE_MIN_FLOOR;
    if (u < DOSE_MIN_FLOOR) u = DOSE_MIN_FLOOR;
    if (u > DOSE_MAX)       u = DOSE_MAX;

    g_flow_rate = u;
    I2C_Driver::set_lime_rate(g_flow_rate);

    // Shift history
    s_prev2_err = s_prev_err;
    s_prev_err  = err;
    s_u_last    = u;

    if (ENABLE_DEBUG_LOGGING) printf(
             "MODEL: PID inc | Fpred=%.3f | err=%.3f | dt=%.3fs | Kp=%.4f Ki=%.5f | "
             "dP=%.5f dI=%.5f | cmd=%.6f mL/s",
             Fpred_ppm, err, dt, Kp, Ki, dP, dI, u);

        
}

static void fluoride_watch_task(void* /*arg*/)
{
    float last = NAN;

    for (;;) {
        float cur = g_fluoride_ppm;

        bool changed = false;
        if (isnan(last)) {
            changed = !isnan(cur); // first valid sample
        } else if (!isnan(cur) && fabsf(cur - last) > s_change_threshold_ppm) {
            changed = true;
        }

        if (changed) {
            last = cur;
            run_model_from_fluoride(cur);
        }

        vTaskDelay(pdMS_TO_TICKS(50));  // polling period; adjust if needed
    }
}
