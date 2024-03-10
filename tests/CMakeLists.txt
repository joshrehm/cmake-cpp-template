#
# Add our test executable
add_executable(${PROJECT_NAME_SNAKE}_tests
    "${PROJECT_NAME_SNAKE}_tests.cpp"
)

set_standard_target_options(${PROJECT_NAME_SNAKE}_tests)

#
# Enable CppCheck
if (${PROJECT_NAME_DEFINE}_ENABLE_CPPCHECK)
    include(CppCheck)
    enable_cppcheck(${PROJECT_NAME_SNAKE}_tests)
endif()

#
# Set output directory
set_target_properties(${PROJECT_NAME_SNAKE}_tests PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY $${${PROJECT_NAME_DEFINE}_OUTPUT_PATH})

# Set target includes
target_include_directories(${PROJECT_NAME_SNAKE}_tests
    PRIVATE $${CMAKE_CURRENT_SOURCE_DIR}/../include
    PUBLIC  $${CMAKE_CURRENT_SOURCE_DIR}/../include)

#
# Set target libraries
find_package(Catch2 REQUIRED)
find_package(fmt REQUIRED)

target_link_libraries(${PROJECT_NAME_SNAKE}_tests PRIVATE
    Catch2::Catch2WithMain
    fmt::fmt
)

#
# Discover tests and automatically run on build
include(Catch)
catch_discover_tests(${PROJECT_NAME_SNAKE}_tests)

if (${PROJECT_NAME_DEFINE}_RUN_TESTS_ON_BUILD)
    add_custom_command(TARGET ${PROJECT_NAME_SNAKE}_tests POST_BUILD
                       COMMAND ctest --output-on-failure
                       WORKING_DIRECTORY "$${CMAKE_CURRENT_BINARY_DIR}")
endif()
