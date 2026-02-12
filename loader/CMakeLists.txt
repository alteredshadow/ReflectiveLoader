cmake_minimum_required(VERSION 3.10)
project(loader LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_OSX_ARCHITECTURES "arm64")

add_library(loader STATIC
    src/ImageLoader.cpp
    src/ImageLoaderMachO.cpp
    src/ImageLoaderMachOCompressed.cpp
    src/ImageLoaderProxy.cpp
    src/custom_dlfcn.cpp
    src/dyld_stubs.cpp
)

target_include_directories(loader PUBLIC include)
target_compile_definitions(loader PRIVATE UNSIGN_TOLERANT=1)
target_compile_options(loader PRIVATE -Wno-deprecated)
