# Samsung Lime ESP32 Firmware

This is the full source code for the firmware that is implemented on the central ESP32 microcontroller. It contains integrated logic for:

* interpreting data from the connected pH sensor
* computing an optimal lime dosage rate based on input fluoride concentration
* drivers for controlling the delivery system hardware via I2C
* performing two-way communication with the online database and GUI via WiFi
