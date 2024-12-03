//
// Created by user on 28/11/24.
//

#ifndef HELPER_FUNCTIONS_H
#define HELPER_FUNCTIONS_H


#include <cstdint>
#include <sstream>
#include <vector>
#include <cstdint>
#include <immintrin.h>
#include <algorithm>
#include <iostream>


inline void print_uint128(__uint128_t value) {
    if (value == 0) {
        std::cout << 0;
        return;
    }

    char buffer[40] = {0};
    int pos = 39;
    while (value > 0) {
        buffer[--pos] = '0' + (value % 10);
        value /= 10;
    }

    std::cout << &buffer[pos] << std::endl;
}

inline std::string uint128_to_string(__uint128_t value) {
    if (value == 0) return "0";
    std::string result;
    while (value > 0) {
        result.insert(result.begin(), '0' + (value % 10));
        value /= 10;
    }
    return result;
}


//idk. 1:1 von chatgpt
inline std::vector<uint8_t> int_to_bytes(__uint128_t input) {
    std::vector<uint8_t> output(16);
    __m128i simd_value = _mm_set_epi64x(static_cast<uint64_t>(input >> 64), static_cast<uint64_t>(input));
    _mm_storeu_si128(reinterpret_cast<__m128i*>(output.data()), simd_value);
    return output;
}



inline __uint128_t bytes_to_uint128(const std::vector<uint8_t>& bytes) {
    __uint128_t result = 0;
    for (size_t i = 0; i < 16; ++i) {
        result = (result << 8) | bytes[i];
    }
    return result;
}


inline void reverse_bytes_vector(std::vector<uint8_t>& bytes) {
    std::reverse(bytes.begin(), bytes.end());
}


inline __uint128_t reverse_bytes_int(__uint128_t value) {
    uint64_t high = static_cast<uint64_t>(value >> 64);
    uint64_t low = static_cast<uint64_t>(value);
    high = __builtin_bswap64(high);
    low = __builtin_bswap64(low);
    return (static_cast<__uint128_t>(low) << 64) | high;
}




inline __uint128_t reverse_bits(__uint128_t n) {
    // Define masks for swapping bits
    const __uint128_t m1  = ((__uint128_t)0x5555555555555555ULL << 64) | 0x5555555555555555ULL;
    const __uint128_t m2  = ((__uint128_t)0x3333333333333333ULL << 64) | 0x3333333333333333ULL;
    const __uint128_t m4  = ((__uint128_t)0x0F0F0F0F0F0F0F0FULL << 64) | 0x0F0F0F0F0F0F0F0FULL;
    const __uint128_t m8  = ((__uint128_t)0x00FF00FF00FF00FFULL << 64) | 0x00FF00FF00FF00FFULL;
    const __uint128_t m16 = ((__uint128_t)0x0000FFFF0000FFFFULL << 64) | 0x0000FFFF0000FFFFULL;
    const __uint128_t m32 = ((__uint128_t)0x00000000FFFFFFFFULL << 64) | 0x00000000FFFFFFFFULL;

    // Swap bits in progressively larger groups
    n = ((n >> 1) & m1)  | ((n & m1)  << 1);
    n = ((n >> 2) & m2)  | ((n & m2)  << 2);
    n = ((n >> 4) & m4)  | ((n & m4)  << 4);
    n = ((n >> 8) & m8)  | ((n & m8)  << 8);
    n = ((n >> 16) & m16)| ((n & m16) << 16);
    n = ((n >> 32) & m32)| ((n & m32) << 32);
    n = (n >> 64)        | (n << 64);
    return n;
}



inline __uint128_t int_to_semantic(__uint128_t val, Semantic sem) {
    if(sem == Semantic::GCM) {
        return val;
    }
    return reverse_bits(reverse_bytes_int(val));
}

#endif //HELPER_FUNCTIONS_H
