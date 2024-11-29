# KryptoCpp

## Overview

KryptoCpp is a C++ port of the original Julia project `krypto_julia`. It includes implementations of cryptographic algorithms, finite field arithmetic, and JSON-based processing.

## Directory Structure
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
├── include/                  // Optional: For additional headers
├── build/
├── .gitignore
├── CMakeLists.txt
├── README.md
├── sample.json
├── sample_small.json
└── script.py


## Dependencies

- **C++17**: Modern C++ features.
- **CMake**: Build system.
- **OpenSSL**: Cryptographic functions.
- **Boost.Asio**: Networking (for padding oracle).
- **nlohmann/json**: JSON parsing (header-only library).

## Setup Instructions

1. **Install Dependencies:**

   - **Ubuntu:**
     ```bash
     sudo apt-get update
     sudo apt-get install build-essential cmake libssl-dev libboost-system-dev
     ```
   
   - **nlohmann/json:**
     Download and place the single-header `json.hpp` from [here](https://github.com/nlohmann/json/releases) into `external/json/include/nlohmann/`.

2. **Clone the Repository:**
   
   ```bash
   git clone <repository_url>
   cd krypto_cpp
