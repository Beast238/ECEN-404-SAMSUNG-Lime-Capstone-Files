/*
    Property of Texas A&M University. All rights reserved.
*/

#include <stdlib.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_chip_info.h"
#include "esp_flash.h"
#include "esp_system.h"
#include "i2c_driver.h"

#include <stdio.h> 
#include <inttypes.h> 
#include "esp_log.h" 
#include <string> 
#include <vector> 
#include <sstream> 
#include <cmath>

#include "database.cpp"
#include "pH_driver.cpp"

//sets up flashing all of the coefficient files
extern const uint8_t _binary_PolyCoefficients_txt_start[] asm("_binary_PolyCoefficients_txt_start"); 
extern const uint8_t _binary_PolyCoefficients_txt_end[] asm("_binary_PolyCoefficients_txt_end");
extern const uint8_t _binary_PIDCoefficients_txt_start[] asm("_binary_PIDCoefficients_txt_start");
extern const uint8_t _binary_PIDCoefficients_txt_end[]   asm("_binary_PIDCoefficients_txt_end");

// Simple struct to hold PID coefficients
struct PID {
    float Kp;
    float Ki;
};

void print_info()
{
    printf("Hello world! This is the Samsung Lime Treatment system, on the ESP32 MCU.\n");

    // https://github.com/espressif/esp-idf/blob/v5.5.1/LICENSE
    
    /* Print chip information */
    esp_chip_info_t chip_info;
    uint32_t flash_size;
    esp_chip_info(&chip_info);
    printf("This is %s chip with %d CPU core(s), %s%s%s%s, ",
           CONFIG_IDF_TARGET,
           chip_info.cores,
           (chip_info.features & CHIP_FEATURE_WIFI_BGN) ? "WiFi/" : "",
           (chip_info.features & CHIP_FEATURE_BT) ? "BT" : "",
           (chip_info.features & CHIP_FEATURE_BLE) ? "BLE" : "",
           (chip_info.features & CHIP_FEATURE_IEEE802154) ? ", 802.15.4 (Zigbee/Thread)" : "");

    unsigned major_rev = chip_info.revision / 100;
    unsigned minor_rev = chip_info.revision % 100;
    printf("silicon revision v%d.%d, ", major_rev, minor_rev);
    if(esp_flash_get_size(NULL, &flash_size) != ESP_OK) {
        printf("Get flash size failed");
        return;
    }

    printf("%" PRIu32 "MB %s flash\n", flash_size / (uint32_t)(1024 * 1024),
           (chip_info.features & CHIP_FEATURE_EMB_FLASH) ? "embedded" : "external");

    printf("Minimum free heap size: %" PRIu32 " bytes\n", esp_get_minimum_free_heap_size());
}

void reboot()
{
    for (int i = 10; i >= 0; i--) {
        printf("Restarting in %d seconds...\n", i);
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
    printf("Restarting now.\n");
    fflush(stdout);
    esp_restart();
}

extern "C" void app_main(void)
{
    print_info();

    //TESTING COMPUTATIONAL MODEL
    double inputFluoride = 350; 
    printf("Input Fluoride = %f ppm\n", inputFluoride);

    //TEST POLYNOMIAL ARITHMETIC
    size_t length = _binary_PolyCoefficients_txt_end - _binary_PolyCoefficients_txt_start; 
    ESP_LOGI("EMBED", "PolyCoefficients.txt size = %d bytes", (int)length);

    // Put file contents into a std::string 
    std::string fileContent(reinterpret_cast<const char*>(_binary_PolyCoefficients_txt_start), length);

    // Parse into floats 
    std::vector<float> coefficients; 
    std::stringstream ss(fileContent); 
    float value; while (ss >> value) { coefficients.push_back(value); } 
    double outputLimeDosage = coefficients[0] * pow(inputFluoride, 3) + coefficients[1] * pow(inputFluoride, 2) + 
    coefficients[2] * pow(inputFluoride, 1) + coefficients[3]; 
    printf("Output Lime Dosage = %f mL/s\n", outputLimeDosage);

    // Testing PID Logic
    // Example measured error
    float measuredFluoride = 45; //ppm, data from sensor
    float targetFluoride = 30; //ppm, target

    float errMeasured = measuredFluoride - targetFluoride;

    float dt = 1; //s, time between fluoride sensor measurements
    // 1) Load PID coefficients from embedded array
    size_t pidLength = _binary_PIDCoefficients_txt_end - _binary_PIDCoefficients_txt_start;
    std::string pidFileContent(reinterpret_cast<const char*>(_binary_PIDCoefficients_txt_start), pidLength);

    std::vector<PID> pidTable;
    std::stringstream pidSS(pidFileContent);
    float Kp, Ki;
    while (pidSS >> Kp >> Ki) {
        pidTable.push_back({Kp, Ki});
    }

    // 2) Map measured error to nearest index
    int errorMin = -50;  // assuming file starts at -50 ppm
    int idx = static_cast<int>(round(errMeasured)) - errorMin;
 
    // Safety checks
    if (idx < 0) idx = 0;
    if (idx >= pidTable.size()) idx = pidTable.size() - 1;

    // 3) Get PID coefficients
    PID selectedPID = pidTable[idx];

    float pCorrection = selectedPID.Kp * errMeasured;
    float iCorrection = selectedPID.Ki * errMeasured;
    float offset = pCorrection + iCorrection;
    float CorrectLimeFlow = outputLimeDosage;
    
    // TEST MATTHEW DATABASE
    if (true)
    {
        database_app_main();
    }

    // test ADC
    if (false)
    {
        pH_driver_init();
    }
    
    // test i2c code
    if (false)
    {
        I2C_Driver::i2c_init();
        printf("\nBooted up.\n0, 0 for 10 seconds\n");

        vTaskDelay(10000 / portTICK_PERIOD_MS);
        I2C_Driver::set_duty_cycle_1(0.75);
        I2C_Driver::set_duty_cycle_2(0.25);
        printf("\n0.75, 0.25 for 10 seconds\n");

        vTaskDelay(10000 / portTICK_PERIOD_MS);
        I2C_Driver::set_duty_cycle_1(1);
        I2C_Driver::set_duty_cycle_2(1);
        printf("\n1, 1 for 10 seconds\n");

        // shut down everything
        printf("\nAll done.\n");
        I2C_Driver::i2c_deinit();
    }

    reboot();
}
