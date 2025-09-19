cmake_minimum_required(VERSION 3.14)
project(SampleProject)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# CPM: download automatically
file(
    DOWNLOAD
    https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.42.0/CPM.cmake
    ${CMAKE_BINARY_DIR}/CPM.cmake
    EXPECTED_HASH SHA256=2020b4fc42dba44817983e06342e682ecfc3d2f484a581f11cc5731fbe4dce8a
)
include(${CMAKE_BINARY_DIR}/CPM.cmake)

set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)


add_executable(SampleProject main.cpp)
add_executable(SampleProject_Test test.cpp)

CPMAddPackage(
  NAME GTest
  GITHUB_REPOSITORY google/googletest
  VERSION 1.15.0
)

target_link_libraries(SampleProject_Test GTest::gtest GTest::gtest_main)
