cmake_minimum_required(VERSION 2.8)

project (SILLICONDB)
message(${SILLICONDB_SOURCE_DIR})
message(${SILLICONDB_BINARY_DIR})

set (CMAKE_CXX_FLAGS "-g -O3 -std=c++1y")
set (CMAKE_ARCHITECTURE_FLAGS "-m64 -mmmx -msse -msse2 -mbmi2")

INCLUDE_DIRECTORIES(/lib)
LINK_DIRECTORIES(/lib)

INCLUDE_DIRECTORIES(${SILLICONDB_SOURCE_DIR}/src)

add_subdirectory(src/)
