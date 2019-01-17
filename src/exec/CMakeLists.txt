add_executable(sDB_master Master.cpp)
target_link_libraries(
    sDB_master
    api_lib
    network_util
    server_lib
    pthread
    sched_lib
)

add_executable(sDB_client Client.cpp)
target_link_libraries(sDB_client
    server_lib
    network_util
)
