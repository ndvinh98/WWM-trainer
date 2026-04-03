cmake_minimum_required(VERSION 3.20)
project(wwm_inject_android LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- Dobby (ARM64 inline hook framework) ---
# Pinned to last stable commit before breaking refactor chain
include(FetchContent)
FetchContent_Declare(
    dobby
    GIT_REPOSITORY https://github.com/jmpews/Dobby.git
    GIT_TAG        e9fe7fb
)
set(DOBBY_GENERATE_SHARED OFF CACHE BOOL "" FORCE)
set(DOBBY_DEBUG OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(dobby)

# Patch Dobby's Logger::Shared() missing inline — upstream bug in e9fe7fb
file(READ "${dobby_SOURCE_DIR}/external/logging/logging/logging.h" _logging_h)
string(REPLACE
    "Logger *Logger::Shared()"
    "inline Logger *Logger::Shared()"
    _logging_h "${_logging_h}"
)
file(WRITE "${dobby_SOURCE_DIR}/external/logging/logging/logging.h" "${_logging_h}")

# --- Build libinject.so ---
add_library(inject SHARED inject_android.cpp)

target_link_libraries(inject PRIVATE
    dobby_static
    log          # __android_log_print
    dl           # dl_iterate_phdr
    OpenSLES     # Forces linker to load libOpenSLES.so to satisfy libGame.so
)

target_include_directories(inject PRIVATE
    ${dobby_SOURCE_DIR}/include
)

# Strip debug symbols for smaller .so
set_target_properties(inject PROPERTIES
    LINK_FLAGS "-s"
)
