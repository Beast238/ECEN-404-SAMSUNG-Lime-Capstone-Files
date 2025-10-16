/*
    Property of Texas A&M University. All rights reserved.
*/

#ifndef PHDRIVER_H
#define PHDRIVER_H

volatile bool pH_driver_ready = 0;
volatile double currentpH = 0;

double pH_driver_single_read();
void pH_driver_loop();
void pH_driver_init();
void pH_driver_deinit();

#endif /* PHDRIVER_H */
