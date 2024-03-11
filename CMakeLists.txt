cmake_minimum_required(VERSION 3.28)

#
# Configure CMake properties
list(PREPEND CMAKE_MODULE_PATH "$${CMAKE_CURRENT_SOURCE_DIR}/cmake")

#
# Includes
include(${PROJECT_NAME_PASCAL}Options)

#
# Project setup
generate_version_header("$${CMAKE_CURRENT_SOURCE_DIR}/VERSION"
                        "$${CMAKE_CURRENT_SOURCE_DIR}/include/${PROJECT_NAME_SNAKE}/${PROJECT_NAME_SNAKE}_version.h"
                        FROM_TEMPLATE  "${PROJECT_NAME_SNAKE}_version.h.in"
                        VARIABLE        ${PROJECT_NAME_DEFINE}_VERSION)
project(${PROJECT_NAME_SNAKE} VERSION $${${PROJECT_NAME_DEFINE}_VERSION} LANGUAGES C CXX )

#
# Source files
add_subdirectory(src)

#
# Unit Testing
if (${PROJECT_NAME_DEFINE}_RUN_TESTS_ON_BUILD)
    set(${PROJECT_NAME_DEFINE}_ENABLE_TESTS ON)
endif()

message_bool(${PROJECT_NAME_DEFINE}_ENABLE_TESTS
    "-- ${PROJECT_NAME}: Testing is enabled"
    "-- ${PROJECT_NAME}: Testing is disabled")
message_bool(${PROJECT_NAME_DEFINE}_RUN_TESTS_ON_BUILD
    "-- ${PROJECT_NAME}: Tests will run on build"
    "-- ${PROJECT_NAME}: Tests will not run on build")

if (${PROJECT_NAME_DEFINE}_ENABLE_TESTS)
	enable_testing()
	add_subdirectory(tests)
endif()
