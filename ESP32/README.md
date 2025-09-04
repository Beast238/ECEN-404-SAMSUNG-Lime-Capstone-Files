# Samsung Lime ESP32 Firmware

This is the full source code for the firmware that will be implemented on the central ESP32 microcontroller. It contains integrated logic for:

* interpreting data from the connected PCB sensor
* computing an optimal lime dosage rate based on current pH and fluoride values
* drivers for controlling the delivery system hardware via I2C
* performing two-way communication with the online database and GUI via WiFi
