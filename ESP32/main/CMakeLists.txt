idf_component_register(SRCS "pH_driver.cpp" "database.cpp" "model.cpp" "i2c_driver.cpp" "main.cpp"
                       PRIV_REQUIRES spi_flash
                       PRIV_REQUIRES esp_driver_i2c
                       PRIV_REQUIRES esp_wifi
                       PRIV_REQUIRES nvs_flash
                       PRIV_REQUIRES esp_http_client
                       PRIV_REQUIRES esp_adc
                       PRIV_REQUIRES driver
                       PRIV_REQUIRES esp_timer
                       PRIV_REQUIRES mbedtls
                       EMBED_TXTFILES "PolyCoefficients.txt"
                       EMBED_TXTFILES "PIDCoefficients.txt"
                       INCLUDE_DIRS "")
