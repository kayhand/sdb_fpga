# to avoid long include statements in some headers
# be careful not to create ambiguous file names  
INCLUDE_DIRECTORIES(${SILLICONDB_SOURCE_DIR}/src/fpga/processing/)

add_subdirectory(api)
add_subdirectory(data)
add_subdirectory(exec)
add_subdirectory(network)
add_subdirectory(sched)
add_subdirectory(fpga)