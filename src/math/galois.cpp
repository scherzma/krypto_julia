// src/math/galois_fast.cpp
#include "galois.h"
#include <algorithm>
#include <array>
#include <stdexcept>
#include <bitset>
#include <complex>
#include <cstring>
#include <openssl/bn.h>
#include "util/base64_utils.h"
#include "util/helper_functions.h"
#include <immintrin.h>
#include <random>

FieldElement::FieldElement(unsigned __int128 val, Semantic sem, bool skip) {
    if (skip) {
        this->value = reverse_bits(val);
        this->semantic = sem;
        this->skip_manipulation = true;
    } else {
        this->value = int_to_semantic(val, sem);
        this->semantic = sem;
        this->skip_manipulation = false;
    }
}

FieldElement::FieldElement(const std::vector<uint8_t>& val, Semantic sem) {
    __uint128_t aggregate = 0;
    __uint128_t one = 1;
    for(uint8_t x : val) {
        aggregate |= (one << 127 - x);
    }
    this->value = aggregate;
    this->semantic = sem;
    this->skip_manipulation = true;
}

FieldElement::FieldElement(const std::string& block, Semantic sem) {
    std::vector<uint8_t> bytes = base64_decode(block);
    __uint128_t temp = bytes_to_uint128(bytes);
    __uint128_t val = int_to_semantic(temp, sem);
    this->value = val;
    this->semantic = sem;
    this->skip_manipulation = false;
}


bool FieldElement::operator!=(const FieldElement& other) const {
    return !(*this == other);
}

bool FieldElement::operator==(const FieldElement& other) const {
    return this->value == other.value &&
           this->semantic == other.semantic;
}


FieldElement FieldElement::operator^(const __uint128_t& power) const { //pfusch
    FieldElement result(1, this->semantic, true);
    __uint128_t base = this->value;
    __uint128_t exponent = power;

    for(int i=0; i<128; ++i){
        if(exponent & 1) {
            result = result * base;
        }
        result = result * result;
        exponent >>=1;
    }
    return result;
}

FieldElement FieldElement::power(__uint128_t exponent) const { //pfusch
    FieldElement result(1, this->semantic, true);
    FieldElement base = *this;
    while(exponent){
        if (exponent & 1){
            result = result * base;
        }
        base = base * base;
        exponent >>=1;
    }
    return result;
}

FieldElement FieldElement::operator/(const FieldElement& other) const { // TODO: Implement this
    return *this * other.inverse();
}

FieldElement FieldElement::sqrt() const {
    if (this->is_zero()) {
        return *this; // Square root of 0 is 0
    }

    // Check if the value is in a valid field for sqrt operation
    if (this->semantic != Semantic::GCM) {
        throw std::invalid_argument("Square root is only supported in GCM semantic.");
    }

    // In GF(2^n), the square root operation is equivalent to raising the element to the power of 2^(n-1)
    // For GCM, n = 128, so sqrt(a) = a^(2^(128 - 1))
    __uint128_t sqrt_exponent = (__uint128_t(1) << 127);

    return this->power(sqrt_exponent);
}

std::string FieldElement::bit_string() const {
    return std::bitset<128>(value).to_string();
}

std::string FieldElement::to_block() const {

    std::vector<uint8_t> bytes;

    if(semantic == Semantic::GCM) {
        __uint128_t reversed = value;
        bytes = int_to_bytes(reversed);
        reverse_bytes_vector(bytes);
    } else if(semantic == Semantic::XEX) {
        bytes = int_to_bytes(reverse_bits(value));
    }

    return base64_encode(bytes);
}

std::vector<uint8_t> FieldElement::to_polynomial() const {
    std::vector<uint8_t> poly;
    __uint128_t temp = reverse_bits(value);
    uint8_t position = 0;
    while (temp != 0) {
        if (temp & 1)
            poly.push_back(position);
        temp >>= 1;
        ++position;
    }
    return poly;
}

std::vector<uint8_t> FieldElement::to_vector() const {
    return int_to_bytes(reverse_bits(value));
}

bool FieldElement::is_zero() const {
    return value == 0;
}

FieldElement FieldElement::operator+(const FieldElement& other) const {
    return {this->value ^ other.value, this->semantic, false};
}

FieldElement FieldElement::operator+(const std::vector<uint8_t>& other) const {
    return {this->value ^ int_to_semantic(bytes_to_uint128(other), this->semantic), this->semantic, false};
}

FieldElement FieldElement::operator-(const FieldElement& other) const {
    return *this + other; // same as addition in GF(2^n)
}

FieldElement FieldElement::operator*(const FieldElement& other) const {
    return *this * other.value;
}

bool FieldElement::operator<(const FieldElement& other) const {
    return this->value > other.value;
}

FieldElement FieldElement::operator*(const __uint128_t& other) const {
    __uint128_t a_val = this->value;
    __uint128_t b_val = other;

    // Split into high and low 64-bit parts
    uint64_t a_hi = static_cast<uint64_t>(a_val >> 64);
    uint64_t a_lo = static_cast<uint64_t>(a_val);
    uint64_t b_hi = static_cast<uint64_t>(b_val >> 64);
    uint64_t b_lo = static_cast<uint64_t>(b_val);

    // Load into __m128i registers
    __m128i a = _mm_set_epi64x(a_hi, a_lo);
    __m128i b = _mm_set_epi64x(b_hi, b_lo);

    // Carry out the multiplication algorithm
    __m128i tmp3 = _mm_clmulepi64_si128(a, b, 0x00);
    __m128i tmp4 = _mm_clmulepi64_si128(a, b, 0x10);
    __m128i tmp5 = _mm_clmulepi64_si128(a, b, 0x01);
    __m128i tmp6 = _mm_clmulepi64_si128(a, b, 0x11);

    tmp4 = _mm_xor_si128(tmp4, tmp5);
    tmp5 = _mm_slli_si128(tmp4, 8);
    tmp4 = _mm_srli_si128(tmp4, 8);
    tmp3 = _mm_xor_si128(tmp3, tmp5);
    tmp6 = _mm_xor_si128(tmp6, tmp4);

    __m128i tmp7 = _mm_srli_epi32(tmp3, 31);
    __m128i tmp8 = _mm_srli_epi32(tmp6, 31);
    tmp3 = _mm_slli_epi32(tmp3, 1);
    tmp6 = _mm_slli_epi32(tmp6, 1);

    __m128i tmp9 = _mm_srli_si128(tmp7, 12);
    tmp8 = _mm_slli_si128(tmp8, 4);
    tmp7 = _mm_slli_si128(tmp7, 4);
    tmp3 = _mm_or_si128(tmp3, tmp7);
    tmp6 = _mm_or_si128(tmp6, tmp8);
    tmp6 = _mm_or_si128(tmp6, tmp9);

    // Reduction steps
    tmp7 = _mm_slli_epi32(tmp3, 31);
    tmp8 = _mm_slli_epi32(tmp3, 30);
    tmp9 = _mm_slli_epi32(tmp3, 25);
    tmp7 = _mm_xor_si128(tmp7, tmp8);
    tmp7 = _mm_xor_si128(tmp7, tmp9);
    tmp8 = _mm_srli_si128(tmp7, 4);
    tmp7 = _mm_slli_si128(tmp7, 12);
    tmp3 = _mm_xor_si128(tmp3, tmp7);

    __m128i tmp2 = _mm_srli_epi32(tmp3, 1);
    tmp4 = _mm_srli_epi32(tmp3, 2);
    tmp5 = _mm_srli_epi32(tmp3, 7);
    tmp2 = _mm_xor_si128(tmp2, tmp4);
    tmp2 = _mm_xor_si128(tmp2, tmp5);
    tmp2 = _mm_xor_si128(tmp2, tmp8);
    tmp3 = _mm_xor_si128(tmp3, tmp2);
    tmp6 = _mm_xor_si128(tmp6, tmp3);

    // Extract result back to __uint128_t
    uint64_t result_hi, result_lo;
    result_hi = _mm_extract_epi64(tmp6, 1);
    result_lo = _mm_extract_epi64(tmp6, 0);

    __uint128_t result = (static_cast<__uint128_t>(result_hi) << 64) | result_lo;
    return {result, this->semantic, false};
}

FieldElement FieldElement::inverse() const {
    if(this->is_zero()){
        throw std::invalid_argument("Cannot invert zero element");
    }
    return *this ^ ~0 -1; // Should work?
}

__uint128_t fast_random(__uint128_t& seed) {
    seed = (seed + 1) * 6364136223846793005ULL;
    return seed;
}

FieldElement FieldElement::random() {
    FieldElement result;
    result.value = static_cast<__uint128_t>(rand()) << 96 |
                       static_cast<__uint128_t>(rand()) << 64 |
                       static_cast<__uint128_t>(rand()) << 32 |
                       static_cast<__uint128_t>(rand());;
    result.semantic = Semantic::GCM;
    return result;
}