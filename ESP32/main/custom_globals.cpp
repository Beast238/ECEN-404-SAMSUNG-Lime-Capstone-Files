#include "custom_globals.h"

volatile bool DEBUG_MODE = false;
volatile bool ENABLE_DEBUG_LOGGING = false;
volatile bool ENABLE_INFO_LOGGING = false;

volatile bool ENABLE_VALVE_TWO = true; // set to false if bus switch non functional; plug I2C bus lines into first PCB instead of second for this mode (solder jumper wire between master bus lines and SD0/SC0 lines)
