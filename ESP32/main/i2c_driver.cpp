/*
    Property of Texas A&M University. All rights reserved.
*/

#include "i2c_driver.h"

bool I2C_Driver::i2c_ready = 0;
i2c_master_bus_handle_t I2C_Driver::bus_handle;
i2c_master_dev_handle_t I2C_Driver::valve_select_handle;
i2c_master_dev_handle_t I2C_Driver::duty_cycle_select_handle;
double I2C_Driver::duty_cycle_1 = 0;
double I2C_Driver::duty_cycle_2 = 0;

void I2C_Driver::set_duty_cycle_1(double dc) { I2C_Driver::duty_cycle_1 = dc; }
void I2C_Driver::set_duty_cycle_2(double dc) { I2C_Driver::duty_cycle_2 = dc; }

void I2C_Driver::i2c_write_byte(i2c_master_dev_handle_t handl, uint8_t dat)
{
    if (!I2C_Driver::i2c_ready)
    {
        printf("I2C not ready\n");
        return;
    }

    uint8_t* write_buf = (uint8_t*)malloc(sizeof(uint8_t) * 2);
    write_buf[0] = 0x00; // reg addr
    write_buf[1] = dat;
    esp_err_t err = i2c_master_transmit(handl, write_buf, 2, -1);
    free(write_buf);

    if (err != ESP_OK)
    {
        printf("Error during i2c write: %d\n", err);
    }
}

uint8_t I2C_Driver::i2c_read_byte(i2c_master_dev_handle_t handl)
{
    if (!I2C_Driver::i2c_ready)
    {
        printf("I2C not ready\n");
        return 0;
    }
    uint8_t* read_buf = (uint8_t*)malloc(sizeof(uint8_t));

    esp_err_t err = i2c_master_receive(handl, read_buf, 1, -1);
    if (err != ESP_OK)
    {
        printf("Error during i2c read: %d\n", err);
        free(read_buf);
        return 0;
    }

    // get output
    uint8_t read_out = *read_buf;
    free(read_buf);
    return read_out;
}

uint8_t I2C_Driver::i2c_select_valve(uint8_t valve)
{
    i2c_write_byte(I2C_Driver::valve_select_handle, valve);
    uint8_t new_valve = i2c_read_byte(I2C_Driver::valve_select_handle);
    if (new_valve != valve)
    {
        printf("Error selecting valve %x, read back %x\n", valve, new_valve);
    }
    return new_valve;
}

double I2C_Driver::i2c_set_duty_cycle(double dc)
{
    uint8_t dc_byte = (uint8_t)(dc * 256.0); // 100% is impossible with our DAC, so 256 not 255
    i2c_write_byte(I2C_Driver::duty_cycle_select_handle, dc_byte);
    uint8_t new_dc_byte = i2c_read_byte(I2C_Driver::duty_cycle_select_handle);
    double new_dc = ((double)new_dc_byte) / 256.0;
    if (new_dc_byte != dc_byte)
    {
        printf("Error setting duty cycle %f, wrote byte %x, read back %x (%f)\n", dc, dc_byte, new_dc_byte, new_dc);
    }
    return new_dc;
}

void I2C_Driver::i2c_loop()
{
    while (true)
    {
        if (!I2C_Driver::i2c_ready) break;
        I2C_Driver::i2c_select_valve(1); // write 0x00 0x01 to 0x70 and read back
        I2C_Driver::i2c_set_duty_cycle(I2C_Driver::duty_cycle_1); // write 0x00 0xXX to 0x48 and read back

        I2C_Driver::i2c_select_valve(2); // write 0x00 0x01 to 0x70 and read back
        I2C_Driver::i2c_set_duty_cycle(I2C_Driver::duty_cycle_2); // write 0x00 0xXX to 0x48 and read back

        vTaskDelay(100 / portTICK_PERIOD_MS); // execute approximately 10 times a second
    }
    
    i2c_master_bus_rm_device(I2C_Driver::valve_select_handle);
    i2c_master_bus_rm_device(I2C_Driver::duty_cycle_select_handle);
    i2c_del_master_bus(I2C_Driver::bus_handle);
    vTaskDelete(NULL);
}

void I2C_Driver::i2c_init()
{
    I2C_Driver::i2c_ready = 0;

    // initialize
    i2c_master_bus_config_t i2c_mst_config;
    i2c_mst_config.clk_source = I2C_CLK_SRC_DEFAULT;
    i2c_mst_config.i2c_port = I2C_NUM_0;
    i2c_mst_config.scl_io_num = static_cast<gpio_num_t>(I2C_MASTER_SCL_IO);
    i2c_mst_config.sda_io_num = static_cast<gpio_num_t>(I2C_MASTER_SDA_IO);
    i2c_mst_config.clk_source = I2C_CLK_SRC_DEFAULT,
    i2c_mst_config.glitch_ignore_cnt = 7;
    i2c_mst_config.intr_priority = 0;
    i2c_mst_config.trans_queue_depth = 0; // synchronous only
    i2c_mst_config.flags.enable_internal_pullup = false; // pull-up resistors are installed on driving board
    i2c_mst_config.flags.allow_pd = false; // fails if true

    esp_err_t err = i2c_new_master_bus(&i2c_mst_config, &I2C_Driver::bus_handle);
    if (err != ESP_OK)
    {
        // failed to create master bus; cannot continue
        printf("Error creating I2C master bus: %d\n", err);
        i2c_ready = 0;
        return;
    }

    i2c_device_config_t valve_select_cfg;
    valve_select_cfg.dev_addr_length = I2C_ADDR_BIT_LEN_7;
    valve_select_cfg.device_address = 0x70; // 0x70 = I2C bus switch
    valve_select_cfg.scl_speed_hz = 100000; // 100 kHz
    valve_select_cfg.scl_wait_us = 0;
    valve_select_cfg.flags.disable_ack_check = 0;

    i2c_device_config_t duty_cycle_select_cfg;
    duty_cycle_select_cfg.dev_addr_length = I2C_ADDR_BIT_LEN_7;
    duty_cycle_select_cfg.device_address = 0x48; // 0x48 = all DACs (bus switch controls which DAC to use)
    duty_cycle_select_cfg.scl_speed_hz = 100000; // 100 kHz
    duty_cycle_select_cfg.scl_wait_us = 0;
    duty_cycle_select_cfg.flags.disable_ack_check = 0;

    err = i2c_master_bus_add_device(I2C_Driver::bus_handle, &valve_select_cfg, &I2C_Driver::valve_select_handle);
    if (err != ESP_OK)
    {
        printf("Error adding valve select device: %d\n", err);
    }
    err = i2c_master_bus_add_device(I2C_Driver::bus_handle, &duty_cycle_select_cfg, &I2C_Driver::duty_cycle_select_handle);
    if (err != ESP_OK)
    {
        printf("Error adding duty cycle select device: %d\n", err);
    }

    I2C_Driver::i2c_ready = 1;

    // init loop task
    xTaskCreate((TaskFunction_t)(I2C_Driver::i2c_loop), "i2c_loop", 4096, NULL, 2, NULL);
}

void I2C_Driver::i2c_deinit()
{
    I2C_Driver::i2c_ready = 0;
}
