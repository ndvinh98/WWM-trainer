cmake_minimum_required(VERSION 3.20)
project(wwm_inject_android LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- Dobby (ARM64 inline hook framework) ---
include(FetchContent)
FetchContent_Declare(
    dobby
    GIT_REPOSITORY https://github.com/jmpews/Dobby.git
    GIT_TAG        master
)
# Dobby build options
set(DOBBY_GENERATE_SHARED OFF CACHE BOOL "" FORCE)
set(DOBBY_DEBUG OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(dobby)

# --- Build libinject.so ---
add_library(inject SHARED inject_android.cpp)

target_link_libraries(inject PRIVATE
    dobby
    log          # __android_log_print
    dl           # dl_iterate_phdr
)

target_include_directories(inject PRIVATE
    ${dobby_SOURCE_DIR}/include
)

# Strip debug symbols for smaller .so
set_target_properties(inject PROPERTIES
    LINK_FLAGS "-s"
)
