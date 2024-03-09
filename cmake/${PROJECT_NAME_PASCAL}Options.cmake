include(StandardOptions)

opt(${PROJECT_NAME_DEFINE}_OUTPUT_PATH STRING
    "$${PROJECT_OUTPUT_PATH}" 
    "Default output path for compiled ${PROJECT_NAME} binaries.")

opt(${PROJECT_NAME_DEFINE}_ENABLE_TESTS BOOL OFF
    "Build ${PROJECT_NAME} unit tests")

opt(${PROJECT_NAME_DEFINE}_RUN_TESTS_ON_BUILD BOOL OFF
    "Run ${PROJECT_NAME} unit tests on build")

opt(${PROJECT_NAME_DEFINE}_ENABLE_CPPCHECK BOOL ON
    "Enable CppCheck static code analysis for ${PROJECT_NAME}")

opt(${PROJECT_NAME_DEFINE}_WARNINGS_AS_ERRORS BOOL $${WARNINGS_AS_ERRORS}
    "Treat ${PROJECT_NAME} project compiler warnings as compiler errors")
