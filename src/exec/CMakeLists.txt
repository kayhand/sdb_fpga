add_executable(sDB_master Master.cpp)
target_link_libraries(
    sDB_master
    api_lib
    network_util
    server_lib
    pthread
    sched_lib
	mrw_lib
	rp_lib
    wrapper_lib
)

add_executable(sDB_client Client.cpp)
target_link_libraries(sDB_client
    server_lib
    network_util
)
