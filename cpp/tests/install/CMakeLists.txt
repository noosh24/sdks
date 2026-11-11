cmake_minimum_required(VERSION 3.25...4.4)

project(noosh24_install_check LANGUAGES CXX)

find_package(noosh24 0.1 CONFIG REQUIRED)

add_executable(install_check main.cpp)
target_link_libraries(install_check PRIVATE noosh24::noosh24)
