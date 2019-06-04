cmake_minimum_required(VERSION 2.8)

project (SILLICONDB)
message(${SILLICONDB_SOURCE_DIR})
message(${SILLICONDB_BINARY_DIR})

############################################################################
######################### OPAE Configuration ###############################
############################################################################

set(OPAE_SDK_SOURCE "/homes/kayhan/opae-sdk")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${OPAE_SDK_SOURCE}/cmake/modules")

set(COMMON_DIR        ${OPAE_SDK_SOURCE}/common)
set(OPAE_INCLUDE_DIR  ${OPAE_SDK_SOURCE}/include CACHE PATH "Path to include directory" FORCE)

# Install common header files
install(DIRECTORY common/include/opae
  DESTINATION include
  COMPONENT libopaeheaders)

install(DIRECTORY common/include/safe_string
  DESTINATION include
  COMPONENT safestrheaders)

set (CMAKE_CXX_FLAGS "-g -O3 -std=c++1y")
set (CMAKE_ARCHITECTURE_FLAGS "-m64 -mmmx -msse -msse2 -mbmi2")

INCLUDE_DIRECTORIES(/lib)
LINK_DIRECTORIES(/lib)

INCLUDE_DIRECTORIES(/homes/kayhan/intel-fpga-bbb/BBB_cci_mpf/sw/build)
LINK_DIRECTORIES(/homes/kayhan/intel-fpga-bbb/BBB_cci_mpf/sw/build)
#include(intel_fpga_bbb)

INCLUDE_DIRECTORIES(${SILLICONDB_SOURCE_DIR}/src)

add_subdirectory(src/)