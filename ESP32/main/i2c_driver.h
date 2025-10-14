/*
    Property of Texas A&M University. All rights reserved.
*/

#ifndef I2CDRIVER_H
#define I2CDRIVER_H

#include <stdlib.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "driver/i2c_master.h"

#define I2C_MASTER_SCL_IO    22    /*!< gpio number for I2C master clock */
#define I2C_MASTER_SDA_IO    21    /*!< gpio number for I2C master data  */

class I2C_Driver
{
    public:
        // internal functions
        static volatile bool i2c_ready;
        static i2c_master_bus_handle_t bus_handle;
        static i2c_master_dev_handle_t valve_select_handle;
        static i2c_master_dev_handle_t duty_cycle_select_handle;
        static void i2c_write_byte(i2c_master_dev_handle_t handl, uint8_t dat);
        static uint8_t i2c_read_byte(i2c_master_dev_handle_t handl);
        static double i2c_set_duty_cycle(double dc);
        static uint8_t i2c_select_valve(uint8_t valve);
        static void i2c_loop();

        // to be used externally
        static volatile double duty_cycle_1;
        static volatile double duty_cycle_2;

        static void set_duty_cycle_1(double dc);
        static void set_duty_cycle_2(double dc);
        static void i2c_init();
        static void i2c_deinit();
};


#endif /* I2CDRIVER_H */
