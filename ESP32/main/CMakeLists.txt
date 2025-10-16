idf_component_register(SRCS "pH_driver.cpp" "database.cpp" "i2c_driver.cpp" "main.cpp" "model.cpp"
                       PRIV_REQUIRES spi_flash
                       PRIV_REQUIRES esp_driver_i2c
                       PRIV_REQUIRES esp_wifi
                       PRIV_REQUIRES nvs_flash
                       PRIV_REQUIRES esp_http_client
                       PRIV_REQUIRES esp_adc
                       PRIV_REQUIRES driver
                       EMBED_TXTFILES "PolyCoefficients.txt"
                       EMBED_TXTFILES "PIDCoefficients.txt"
                       INCLUDE_DIRS "")
