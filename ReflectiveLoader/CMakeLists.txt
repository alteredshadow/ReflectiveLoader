cmake_minimum_required(VERSION 3.10)
project(ReflectiveLoader LANGUAGES CXX OBJCXX)
set(CMAKE_OSX_ARCHITECTURES "arm64")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_BUILD_TYPE Debug)

add_executable(ReflectiveLoader main.mm)

# Specify the path to the library
set(LIBRARY_PATH "${CMAKE_SOURCE_DIR}/../Distribute/")

# Link the static library
target_link_libraries(ReflectiveLoader "${LIBRARY_PATH}/libloader.a")

target_link_libraries(ReflectiveLoader "-framework Foundation")

