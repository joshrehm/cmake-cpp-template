# Modern CMake C++ Template

This is an opinionated CMake template for C++ development. It includes cppcheck and 
Conan2 support.

Default compiler flags and preprocessor definitions are provided for the MSVC compiler
on Windows. However, it should be fairly easy to add GCC or Clang flags by modifying
the helper functions in `cmake/Utilities.cmake`.


# Using the template

To use the template, clone or download the template source files to your local machine.
Navigate to the template root directory using a PowerShell prompt (Note future shells or
a python version may come at a later time).

Execute the following command

```
./.template/ConvertFrom-Template 'Project Name' ~/path/to/project
```

This will create the project "Project Name" in the `~/path/to/project` directory.


# Building the project

To configure and build the project, use CMake. The resulting project cmake files 
automatically invoke the conan package manager to download and build packages.

Note that the CMake presets defined in `CMakeUserPresets.json` are identical to the conan
profile names in `conan_profiles`.

```
cmake --preset=win32-x64-debug -DPROJECT_NAME_ENABLE_TESTS=ON
cmake --build --preset=win32-x64-debug
```

The resulting binaries are, by default, stored in the '.bin' directory. This can be
changed by setting the `PROJECT_OUTPUT_PATH` or `PROJECT_NAME_OUTPUT_PATH` CMake cache
variables.

To see a list of available CMake cache variables, refer to the 
`cmake/ProjectNameOptions.cmake` and `cmake/StandardOptions.cmake` files.
