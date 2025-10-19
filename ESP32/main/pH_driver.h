/*
    Property of Texas A&M University. All rights reserved.
*/

#pragma once

#include "custom_globals.h"

extern volatile bool pH_driver_ready;
extern volatile double currentpH;

double pH_driver_single_read();
void pH_driver_loop();
void pH_driver_init();
void pH_driver_deinit();

