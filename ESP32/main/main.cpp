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
#include "esp_console.h"
#include "i2c_driver.h"

#include <stdio.h> 
#include <inttypes.h> 
#include "esp_log.h" 
#include <string> 
#include <vector> 
#include <sstream> 
#include <cmath>

#include "database.cpp"
#include "pH_driver.h"
#include "model.h"
#include "custom_globals.h"

static void print_info()
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

static int print_info_params(int argc, char **argv) { print_info(); return 0; }

static void reboot()
{
    for (int i = 10; i >= 0; i--) {
        printf("Restarting in %d seconds...\n", i);
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
    printf("Restarting now.\n");
    fflush(stdout);
    esp_restart();
}

static void main_full_model_init()
{
    model_init();
    model_set_target_ppm(30.0f);
    model_set_change_threshold_ppm(0.0f);   // trigger on any change
    model_start_watcher_task();             // <-- start the watcher
}

void init_all(void)
{
    printf("Initializing all modules...\n");

    // Ryon Model
    main_full_model_init();

    // database/GUI
    xTaskCreate((TaskFunction_t)(database_app_main_loop), "database_app_main_loop", 4096, NULL, 2, NULL);

    // pH driver/ADC
    pH_driver_init();
    
    // I2C driver
    I2C_Driver::i2c_init();

    printf("Ready!\n");
}

int init_cmd(int argc, char **argv)
{
    if (argc != 2)
    {
        printf("init expects one argument\n");
        return 1;
    }

    std::string typ = argv[1];
    if (typ == "all")
    {
        init_all();
    }
    else if (typ == "ds")
    {
        I2C_Driver::i2c_init();
    }
    else if (typ == "ph")
    {
        pH_driver_init();
    }
    else if (typ == "model")
    {
        main_full_model_init();
    }
    else if (typ == "db" || typ == "database")
    {
        xTaskCreate((TaskFunction_t)(database_app_main_loop), "database_app_main_loop", 4096, NULL, 2, NULL);
    }

    return 0;
}

int set_valve_duty_cycle_cmd(int argc, char **argv)
{
    if (argc != 3)
    {
        printf("valve expects two parameters\n");
        // valve <1/2/lime/water> <0-100>
        return 1;
    }

    std::string dutyCycleStr = argv[2];
    double dutyCycleFloat = std::stof(dutyCycleStr);
    dutyCycleFloat /= 100;

    std::string typ = argv[1];
    if (typ == "1" || typ == "lime")
    {
        I2C_Driver::set_duty_cycle_1(dutyCycleFloat);
        printf("set_duty_cycle_1 %f\n", dutyCycleFloat);
    }
    else if (typ == "2" || typ == "water")
    {
        I2C_Driver::set_duty_cycle_2(dutyCycleFloat);
        printf("set_duty_cycle_2 %f\n", dutyCycleFloat);
    }

    return 0;
}

int set_lime_rate_cmd(int argc, char **argv)
{
    if (argc != 2)
    {
        printf("set_lime_rate expects one parameter\n");
        // set_lime_rate <targetRate in mL/s>
        return 1;
    }

    std::string rateStr = argv[1];
    float rateFloat = std::stof(rateStr);

    I2C_Driver::set_lime_rate(rateFloat);

    printf("set_duty_cycle_1 %f\n", I2C_Driver::duty_cycle_1);
    return 0;
}

int reboot_cmd(int argc, char **argv)
{
    fflush(stdout);
    esp_restart();
    return 0;
}

void init_console()
{
    esp_console_repl_t *repl = NULL;
    esp_console_repl_config_t repl_config = ESP_CONSOLE_REPL_CONFIG_DEFAULT();
    repl_config.prompt = CONFIG_IDF_TARGET ">";
    repl_config.max_cmdline_length = 255;

    esp_console_dev_uart_config_t hw_config = ESP_CONSOLE_DEV_UART_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_console_new_repl_uart(&hw_config, &repl_config, &repl));
    ESP_ERROR_CHECK(esp_console_start_repl(repl));

    // register commands
    const esp_console_cmd_t cmd1 = {
        .command = "print_info",
        .help = "Print chip information",
        .hint = NULL,
        .func = &print_info_params,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd1));
    const esp_console_cmd_t cmd2 = {
        .command = "init",
        .help = "Initialize subsystems (all/ds/ph/model/db)",
        .hint = NULL,
        .func = &init_cmd,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd2));
    const esp_console_cmd_t cmd3 = {
        .command = "valve",
        .help = "Set valve duty cycle (valve <1/2/lime/water> <0-100>). 1 = lime, 2 = water",
        .hint = NULL,
        .func = &set_valve_duty_cycle_cmd,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd3));
    const esp_console_cmd_t cmd4 = {
        .command = "set_lime_rate",
        .help = "Execute I2C_Driver::set_lime_rate (set_lime_rate <targetRate in mL/s>)",
        .hint = NULL,
        .func = &set_lime_rate_cmd,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd4));
    const esp_console_cmd_t cmd5 = {
        .command = "reboot",
        .help = "Reboot the microcontroller immediately",
        .hint = NULL,
        .func = &reboot_cmd,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd5));
}

extern "C" void app_main(void)
{
    if (DEBUG_MODE)
    {
        init_console();
        printf("\nDEBUG MODE: READY\n");
        print_info();
    }
    else
    {
        init_all();
        print_info();
    }

    //I2C_Driver::i2c_deinit();
    //reboot();
}
