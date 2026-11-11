cmake_minimum_required(VERSION 3.25...4.4)

project(noosh24
    VERSION 0.1.0
    DESCRIPTION "Official C++ client for the Noosh24 Open API"
    HOMEPAGE_URL "https://developer.noosh24.com"
    LANGUAGES CXX)

option(NOOSH24_BUILD_TESTS "Build the noosh24 tests" ${PROJECT_IS_TOP_LEVEL})
option(NOOSH24_INSTALL "Generate the noosh24 install rules" ON)
option(NOOSH24_WARNINGS_AS_ERRORS "Treat compiler warnings as errors on noosh24 targets" ${PROJECT_IS_TOP_LEVEL})

include(FetchContent)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

find_package(CURL REQUIRED)

if(NOOSH24_INSTALL)
    set(JSON_Install ON CACHE BOOL "" FORCE)
endif()
FetchContent_Declare(nlohmann_json
    URL https://github.com/nlohmann/json/releases/download/v3.12.0/json.tar.xz
    URL_HASH SHA256=42f6e95cad6ec532fd372391373363b62a14af6d771056dbfc86160e6dfff7aa
    DOWNLOAD_EXTRACT_TIMESTAMP ON
    SYSTEM
    FIND_PACKAGE_ARGS 3.12.0 CONFIG)
FetchContent_MakeAvailable(nlohmann_json)

add_library(noosh24
    src/client.cpp
    src/convert.cpp
    src/curl_transport.cpp
    src/errors.cpp
    src/models.cpp
    src/resources.cpp
    src/where.cpp)
add_library(noosh24::noosh24 ALIAS noosh24)

target_compile_features(noosh24 PUBLIC cxx_std_20)
set_target_properties(noosh24 PROPERTIES
    CXX_EXTENSIONS OFF
    EXPORT_NAME noosh24
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR})
target_include_directories(noosh24
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    PRIVATE
        ${PROJECT_SOURCE_DIR}/src)
target_link_libraries(noosh24
    PUBLIC nlohmann_json::nlohmann_json
    PRIVATE CURL::libcurl)

set(NOOSH24_WARNINGS
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra -Wpedantic>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>)
set(NOOSH24_WERROR
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Werror>
    $<$<CXX_COMPILER_ID:MSVC>:/WX>)
target_compile_options(noosh24 PRIVATE ${NOOSH24_WARNINGS})
if(NOOSH24_WARNINGS_AS_ERRORS)
    target_compile_options(noosh24 PRIVATE ${NOOSH24_WERROR})
endif()

if(NOOSH24_INSTALL)
    install(TARGETS noosh24
        EXPORT noosh24Targets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
    install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
    install(EXPORT noosh24Targets
        NAMESPACE noosh24::
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/noosh24)
    configure_package_config_file(cmake/noosh24Config.cmake.in
        ${PROJECT_BINARY_DIR}/noosh24Config.cmake
        INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/noosh24)
    write_basic_package_version_file(${PROJECT_BINARY_DIR}/noosh24ConfigVersion.cmake
        COMPATIBILITY SameMinorVersion)
    install(FILES
        ${PROJECT_BINARY_DIR}/noosh24Config.cmake
        ${PROJECT_BINARY_DIR}/noosh24ConfigVersion.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/noosh24)
    install(FILES LICENSE DESTINATION ${CMAKE_INSTALL_DATADIR}/licenses/noosh24)
endif()

if(NOOSH24_BUILD_TESTS)
    enable_testing()
    set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
    set(BUILD_GMOCK OFF CACHE BOOL "" FORCE)
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_Declare(googletest
        URL https://github.com/google/googletest/releases/download/v1.18.0/googletest-1.18.0.tar.gz
        URL_HASH SHA256=6e3191c1455468b3fc35a417fb565c1c5071aee1b7e7f85e30cf48a98d37d8b5
        DOWNLOAD_EXTRACT_TIMESTAMP ON
        SYSTEM
        FIND_PACKAGE_ARGS 1.18.0 NAMES GTest)
    FetchContent_MakeAvailable(googletest)
    include(GoogleTest)

    add_executable(noosh24_tests
        tests/test_client.cpp
        tests/test_curl_transport.cpp
        tests/test_errors.cpp
        tests/test_resources.cpp
        tests/test_where.cpp)
    set_target_properties(noosh24_tests PROPERTIES CXX_EXTENSIONS OFF)
    target_link_libraries(noosh24_tests PRIVATE noosh24::noosh24 GTest::gtest_main)
    target_compile_options(noosh24_tests PRIVATE ${NOOSH24_WARNINGS})
    if(NOOSH24_WARNINGS_AS_ERRORS)
        target_compile_options(noosh24_tests PRIVATE ${NOOSH24_WERROR})
    endif()
    gtest_discover_tests(noosh24_tests DISCOVERY_MODE PRE_TEST)
endif()
