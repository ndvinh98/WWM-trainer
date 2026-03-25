cmake_minimum_required(VERSION 3.20)
project(wwm_inject LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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

# Put the DLL next to inject.cpp (the injector expects it here)
set_target_properties(Test PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY_DEBUG   "${CMAKE_SOURCE_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_SOURCE_DIR}"
    RUNTIME_OUTPUT_DIRECTORY         "${CMAKE_SOURCE_DIR}"
)
