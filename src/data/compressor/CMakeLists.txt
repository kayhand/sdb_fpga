set(DATA_SRC
    Compressor.h
    Compressor.cpp
)

add_library(data_lib ${DATA_SRC})

add_executable(data_gen Generator.cpp)

target_link_libraries(
    data_gen
    data_lib
)