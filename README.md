# KryptoCpp

## Overview

KryptoCpp is a C++ port of the original Julia project `krypto_julia`. It includes implementations of cryptographic algorithms, finite field arithmetic, and JSON-based processing.

## Directory Structure
```
krypto_cpp/
├── src/
│   ├── algorithms/
│   │   ├── gcm.cpp
│   │   ├── gcm.h
│   │   ├── padding_oracle.cpp
│   │   ├── padding_oracle.h
│   │   ├── sea128.cpp
│   │   ├── sea128.h
│   │   ├── xex_fde.cpp
│   │   ├── xex_fde.h
│   │   ├── ...
│   ├── math/
│   │   ├── galois_fast.cpp
│   │   ├── galois_fast.h
│   │   ├── polynom.cpp
│   │   ├── polynom.h
│   ├── util/
│   │   ├── processor.cpp
│   │   ├── processor.h
│   │   ├── semantic_types.h
│   ├── Krypto.cpp
│   ├── Krypto.h
│   ├── main.cpp
├── include/        
├── build/
├── .gitignore
├── CMakeLists.txt
├── README.md
├── sample.json
├── sample_small.json
└── script.py
```



## Dependencies

- **C++23**: Modern C++ features.
- **CMake**: Build system.
- **OpenSSL**: Cryptographic functions.
- **nlohmann/json**: JSON parsing (header-only library).

## Some commands

´´´
gprof KryptoCpp | gprof2dot | dot -Tpng -o output.png

cmake --build . --clean-first


gprof ./KryptoCpp gmon.out > analysis.txt
´´´
