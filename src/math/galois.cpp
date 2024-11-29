// src/math/galois_fast.cpp
#include "galois.h"
#include <algorithm>
#include <array>
#include <stdexcept>
#include <bitset>
#include <cstring>
#include <openssl/bn.h>
#include "util/base64_utils.h"
#include "util/helper_functions.h"
#include <immintrin.h>


FieldElement::FieldElement(unsigned __int128 val, Semantic sem, bool skip) {
    if (skip) {
        this->value = val;
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
        aggregate |= (one << x);
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


FieldElement FieldElement::operator^(const FieldElement& other) const {
    return {this->value ^ other.value, this->semantic, true};
}

FieldElement FieldElement::operator>>(int b) const {
    return {this->value >> b, this->semantic, true};
}

FieldElement FieldElement::operator%(const __uint128_t& b) const {
    return {this->value % b, this->semantic, true};
}

FieldElement FieldElement::operator%(const FieldElement& other) const {
    return *this;
}

std::string FieldElement::bit_string() const {
    return std::bitset<128>(value).to_string();
}

std::string FieldElement::to_block() const {

    std::vector<uint8_t> bytes;

    if(semantic == Semantic::GCM) {
        __uint128_t reversed = reverse_bits(value);
        bytes = int_to_bytes(reversed);
        reverse_bytes_vector(bytes);
    } else if(semantic == Semantic::XEX) {
        bytes = int_to_bytes(value);
    }

    return base64_encode(bytes);
}

std::vector<uint8_t> FieldElement::to_polynomial() const {
    std::vector<uint8_t> poly;
    __uint128_t temp = value;
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
    return int_to_bytes(value);
}

bool FieldElement::is_zero() const {
    return value == 0;
}

FieldElement FieldElement::operator+(const FieldElement& other) const {
    return {this->value ^ other.value, this->semantic, true};
}

FieldElement FieldElement::operator+(const std::vector<uint8_t>& other) const {
    return {this->value ^ bytes_to_uint128(other), this->semantic, true};
}

FieldElement FieldElement::operator-(const FieldElement& other) const {
    return *this + other; // same as addition in GF(2^n)
}

FieldElement FieldElement::operator*(const FieldElement& other) const {
    __uint128_t a = this->value;
    __uint128_t b = other.value;
    __uint128_t result = 0;
    __uint128_t modulus = 0x87; // x^128 + x^7 + x^2 + x + 1 represented as 0x87

    for(int i=0; i<128; ++i){
        if (b & 1){
            result ^= a;
        }
        bool carry = (a & (__uint128_t(1) << 127)) != 0;
        a <<= 1;
        if (carry){
            a ^= modulus;
        }
        b >>=1;
    }
    return {result, this->semantic, true};
}

FieldElement FieldElement::power(__uint128_t exponent) const {
    FieldElement result(1, this->semantic, true);
    FieldElement base = *this;
    while(exponent > 0){
        if (exponent & 1){
            result = result * base;
        }
        base = base * base;
        exponent >>=1;
    }
    return result;
}

FieldElement FieldElement::inverse() const {
    if(this->is_zero()){
        throw std::invalid_argument("Cannot invert zero element");
    }
    // Use Extended Euclidean Algorithm for GF(2^128)
    // Placeholder: actual implementation needed
    return *this; // Placeholder
}