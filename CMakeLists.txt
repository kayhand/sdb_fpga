cmake_minimum_required(VERSION 2.8)

project (SILLICONDB)
message(${SILLICONDB_SOURCE_DIR})
message(${SILLICONDB_BINARY_DIR})

set (CMAKE_CXX_FLAGS "-g -O3 -std=c++1y")
set (CMAKE_ARCHITECTURE_FLAGS "-m64 -msse2")

INCLUDE_DIRECTORIES(/usr/lib/sparcv9)
LINK_DIRECTORIES(/usr/lib/sparcv9)

INCLUDE_DIRECTORIES(/lib)
LINK_DIRECTORIES(/lib)

#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_ARCHITECTURE_FLAGS} -lnsl -Wextra")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_ARCHITECTURE_FLAGS} -Wextra")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_ARCHITECTURE_FLAGS} -lopae-c -luuid -ljson-c")

INCLUDE_DIRECTORIES(${SILLICONDB_SOURCE_DIR}/src)

add_subdirectory(src/)
#add_subdirectory(src/data/comp_test/)
