cmake_minimum_required(VERSION 3.10)
project(KryptoCpp)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(BOTAN_LIBRARIES "botan-2")

# Find Botan
#set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -O0 -g -pg")
#set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0 -g -pg")
#set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -pg")
set("-O3")

# Find OpenSSL
find_package(OpenSSL REQUIRED)
find_package(nlohmann_json 3.2.0 REQUIRED)

find_package(PkgConfig REQUIRED)
pkg_check_modules(BOTAN REQUIRED botan-2)

# Recursively find all .cpp files in src/ and its subdirectories
file(GLOB_RECURSE SOURCES "src/*.cpp")

# Add executable
add_executable(KryptoCpp ${SOURCES}
        src/util/helper_functions.h
        src/math/galois.h
        src/algorithms/sff.cpp
        src/algorithms/sff.h
        src/algorithms/ddf.cpp
        src/algorithms/ddf.h
        src/algorithms/edf.cpp
        src/algorithms/edf.h)

# Specify include directories for the target
target_include_directories(KryptoCpp PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/src
        ${CMAKE_SOURCE_DIR}/external/json/include  # Adjust if you have external dependencies
        ${OPENSSL_INCLUDE_DIR}  # Ensure OpenSSL includes are added
        ${BOTAN_INCLUDE_DIRS}
)



# Link libraries
target_link_libraries(KryptoCpp PRIVATE OpenSSL::SSL OpenSSL::Crypto ${BOTAN_LIBRARIES} nlohmann_json::nlohmann_json)

target_compile_options(KryptoCpp PRIVATE ${BOTAN_CFLAGS_OTHER} -msse4.1 -mpclmul)