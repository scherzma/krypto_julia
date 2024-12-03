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
            result *= base;
        }
        result *= result;
        exponent >>=1;
    }
    return result;
}

FieldElement FieldElement::power(__uint128_t exponent) const {
    FieldElement result(1, this->semantic, true);
    FieldElement base = *this;
    while(exponent){
        if (exponent & 1){
            result *= base;
        }
        base *= base;
        exponent >>=1;
    }
    return result;
}

FieldElement FieldElement::operator/(const FieldElement& other) const { // TODO: Implement this with extended euclidean algorithm
    return *this * other.inverse();
}

FieldElement FieldElement::sqrt() const {
    if (this->is_zero()) {
        return *this; // Square root of 0 is 0
    }

    if (this->semantic != Semantic::GCM) {
        throw std::invalid_argument("Square root is only supported in GCM semantic.");
    }

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

FieldElement& FieldElement::operator+=(const FieldElement& other) {
    this->value ^= other.value;
    return *this;
}

FieldElement FieldElement::operator-(const FieldElement& other) const {
    return *this + other; // same as addition in GF(2^n)
}

bool FieldElement::operator<(const FieldElement& other) const {
    return this->value > other.value;
}

inline FieldElement inv_pow(FieldElement base_fe) {
    __uint128_t base = base_fe.value;
    for(int i=0; i<127; ++i){
        base_fe *= base;
        base_fe *= base_fe;
    }
    base_fe *= base_fe;
    return base_fe;
}


FieldElement FieldElement::inverse() const {
    if(this->is_zero()){
        throw std::invalid_argument("Cannot invert zero element");
    }
    return inv_pow(*this);
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