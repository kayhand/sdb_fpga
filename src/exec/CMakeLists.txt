find_package(UUID REQUIRED)

include(opae_devpkgs_cmake_install)
include(ase_add_module)

find_package(Quartus)
find_package(Questa)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_ARCHITECTURE_FLAGS} -Wextra")

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
	rb_lib
    wrapper_lib
  	
  	opae-c
  	opae-c-ase
  	uuid
  	MPF
  	${libjson-c_LIBRARIES}
)