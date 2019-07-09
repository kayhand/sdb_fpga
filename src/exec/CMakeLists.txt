set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_ARCHITECTURE_FLAGS} -Wextra")

add_executable(sDB_master Master.cpp)
target_link_libraries(
    sDB_master
    api_lib
    network_util
    server_lib
    pthread
    sched_lib
    #ah_lib
    #wrapper_lib
)
