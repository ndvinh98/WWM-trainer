cmake_minimum_required(VERSION 3.20)
project(wwm_inject LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- Match VS2026 project settings ---
# Use static CRT (/MT for Release, /MTd for Debug) instead of dynamic CRT (/MD).
# This is critical: the injected DLL must not depend on vcruntime140.dll etc.
# which may not be present or compatible in the target process.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# Use Windows subsystem (not Console) to match the working VS project
set(CMAKE_WIN32_EXECUTABLE OFF)  # Still a DLL, but linker subsystem = Windows

# --- MinHook via FetchContent ---
include(FetchContent)
FetchContent_Declare(
    minhook
    GIT_REPOSITORY https://github.com/TsudaKageyu/minhook.git
    GIT_TAG        master
)
FetchContent_MakeAvailable(minhook)

# --- Build Test.dll ---
add_library(Test SHARED inject.cpp)
target_link_libraries(Test PRIVATE minhook)
target_link_libraries(Test PRIVATE psapi)

# Match VS project: Unicode charset
target_compile_definitions(Test PRIVATE UNICODE _UNICODE)

# Match VS project: Windows subsystem for the DLL
target_link_options(Test PRIVATE "/SUBSYSTEM:WINDOWS")

# Match VS project: Whole-program optimization for Release
target_compile_options(Test PRIVATE
    $<$<CONFIG:Release>:/GL>        # Whole program optimization
    $<$<CONFIG:Release>:/Gy>        # Function-level linking
    $<$<CONFIG:Release>:/Oi>        # Enable intrinsic functions
)
target_link_options(Test PRIVATE
    $<$<CONFIG:Release>:/LTCG>      # Link-time code generation (matches /GL)
)

# Put the DLL next to inject.cpp (the injector expects it here)
set_target_properties(Test PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY_DEBUG   "${CMAKE_SOURCE_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_SOURCE_DIR}"
    RUNTIME_OUTPUT_DIRECTORY         "${CMAKE_SOURCE_DIR}"
)
