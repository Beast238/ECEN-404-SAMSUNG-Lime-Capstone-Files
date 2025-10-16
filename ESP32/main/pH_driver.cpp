/*
    Property of Texas A&M University. All rights reserved.
*/

#include "pH_driver.h"

#include <stdlib.h>
#include "sdkconfig.h"
#include "driver/adc.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

volatile bool pH_driver_ready = 0;
volatile double currentpH = 0;

double pH_driver_single_read()
{
    adc1_config_width(ADC_WIDTH_BIT_12);
    adc1_config_channel_atten(ADC1_CHANNEL_0, ADC_ATTEN_DB_2_5);
    double sumOfReadings = 0;
    int numReadings = 100;
    for (int i = 0; i < numReadings; i++) // take 100 readings and average
    {
        sumOfReadings += adc1_get_raw(ADC1_CHANNEL_0);
        vTaskDelay(10 / portTICK_PERIOD_MS); // small delay between readings
    }
    double averageOfReadings = sumOfReadings / numReadings;
    return averageOfReadings;
}

void pH_driver_loop()
{
    while (pH_driver_ready)
    {
        double val = pH_driver_single_read();
        double pH = (val - 2861) / -160; // pH calibration curve results    
        //printf("%f\n", val);
        printf("PH: %f\n", pH);

        currentpH = pH;
    }
    vTaskDelete(NULL);
}

void pH_driver_init()
{
    pH_driver_ready = 1;
    xTaskCreate((TaskFunction_t)(pH_driver_loop), "pH_driver_loop", 4096, NULL, 2, NULL);
}

void pH_driver_deinit()
{
    pH_driver_ready = 0;
}
