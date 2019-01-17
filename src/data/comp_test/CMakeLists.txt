set(DATA_SRC
    Compressor.h
    Compressor.cpp
)

add_library(data_lib ${DATA_SRC})

add_executable(test MicroBench.cpp)

target_link_libraries(
    test
    data_lib
)