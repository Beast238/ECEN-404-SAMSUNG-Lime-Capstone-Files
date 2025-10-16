#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// ================= External fluoride value =================
// Define EXACTLY ONCE in the sensor/MCU reader module as:
//     volatile float g_fluoride_ppm = NAN;
extern volatile float g_fluoride_ppm;

// Call once at boot. Loads polynomial + PID tables from embedded files.
void model_init(void);

// Optional tuning at runtime:
void model_set_target_ppm(float target_ppm);
void model_set_change_threshold_ppm(float threshold_ppm);

// Starts the watcher FreeRTOS task that runs computations whenever the shared
// fluoride value changes. Non-blocking. Safe to call once.
void model_start_watcher_task(void);

#ifdef __cplusplus
}
#endif
