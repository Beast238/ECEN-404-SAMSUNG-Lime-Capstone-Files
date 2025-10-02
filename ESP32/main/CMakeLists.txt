idf_component_register(SRCS "database.cpp" "i2c_driver.cpp" "main.cpp"
                       PRIV_REQUIRES spi_flash
                       PRIV_REQUIRES esp_driver_i2c
                       EMBED_TXTFILES "PolyCoefficients.txt"
                       EMBED_TXTFILES "PIDCoefficients.txt"
                       INCLUDE_DIRS "")
