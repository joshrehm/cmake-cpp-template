#
# Set up our executable
add_executable(${PROJECT_NAME_SNAKE}
    "${PROJECT_NAME_SNAKE}.cpp"
 )

set_standard_target_options(${PROJECT_NAME_SNAKE})

#
# Enable CppCheck
if (${PROJECT_NAME_DEFINE}_ENABLE_CPPCHECK)
    include(CppCheck)
    enable_cppcheck(${PROJECT_NAME_SNAKE})
endif()

#
# Set output directory
set_target_properties(${PROJECT_NAME_SNAKE} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY $${${PROJECT_NAME_DEFINE}_OUTPUT_PATH})

# Set target includes
target_include_directories(${PROJECT_NAME_SNAKE}
    PRIVATE $${CMAKE_CURRENT_SOURCE_DIR}/../include
    PUBLIC  $${CMAKE_CURRENT_SOURCE_DIR}/../include)

#
# Set target libraries
find_package(fmt REQUIRED)
target_link_libraries(${PROJECT_NAME_SNAKE} PRIVATE
    fmt::fmt
)
