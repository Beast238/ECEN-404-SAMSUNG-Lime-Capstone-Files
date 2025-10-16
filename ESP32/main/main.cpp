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
#include "model.h"

extern "C" volatile float g_fluoride_ppm = NAN;  // DEFINITION for test


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

/* static void test_setter_task(void*) {
    vTaskDelay(pdMS_TO_TICKS(500));       // let watcher start
    g_fluoride_ppm = 250.0f;              // 1st measurement
    printf("TEST: fluoride = %.2f ppm\n", g_fluoride_ppm);

    vTaskDelay(pdMS_TO_TICKS(2000));      // simulate time until next reading
    g_fluoride_ppm = 40.0f;               // 2nd measurement
    printf("TEST: fluoride = %.2f ppm\n", g_fluoride_ppm);

    vTaskDelete(NULL);
} */

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

    //Ryon Model
    model_init();
    model_set_target_ppm(30.0f);
    model_set_change_threshold_ppm(0.0f);   // trigger on any change
    model_start_watcher_task();             // <-- start the watcher
    
    // Launch the one-shot setter
    // xTaskCreatePinnedToCore(test_setter_task, "test_setter", 2048, nullptr, 5, nullptr, tskNO_AFFINITY);
    
    // TEST MATTHEW DATABASE
    if (true)
    {
        database_app_main();
    }

    // test ADC
    if (true)
    {
        pH_driver_init();
    }
    
    // test i2c code
    if (true)
    {
        I2C_Driver::i2c_init();
        printf("\nBooted up.\n0, 0 for 0 seconds\n");

        //vTaskDelay(10000 / portTICK_PERIOD_MS);
        I2C_Driver::set_duty_cycle_1(0.75);
        I2C_Driver::set_duty_cycle_2(0.25);
        printf("\n0.75, 0.25 for 10 seconds\n");

        vTaskDelay(10000 / portTICK_PERIOD_MS);
        I2C_Driver::set_duty_cycle_1(0.5);
        I2C_Driver::set_duty_cycle_2(0.5);
        printf("\n0.5, 0.5 for 10 seconds\n");

        // shut down everything
        printf("\nAll done.\n");
        I2C_Driver::i2c_deinit();
    }

    reboot();
}
