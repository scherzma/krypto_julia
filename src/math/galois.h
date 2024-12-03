// src/math/galois.h

#ifndef GALOIS_FAST_H
#define GALOIS_FAST_H

#include <cstdint>
#include <smmintrin.h>
#include <string>
#include <vector>
#include <wmmintrin.h>

#include "util/semantic_types.h"

class FieldElement {
public:
    __uint128_t value;
    Semantic semantic;
    bool skip_manipulation;

    // Default constructor
    FieldElement()
        : value(0), semantic(Semantic::GCM), skip_manipulation(false) {}

    // Parameterized constructor
    FieldElement(__uint128_t val, Semantic sem, bool skip = false);

    FieldElement(const std::vector<uint8_t>& val, Semantic sem);
    FieldElement(const std::string& block, Semantic sem);


    FieldElement(const FieldElement&) = default;
    FieldElement(FieldElement&&) noexcept = default;

    bool operator!=(const FieldElement& other) const;
    bool operator==(const FieldElement& other) const;
    FieldElement& operator=(const FieldElement&) = default;
    FieldElement& operator=(FieldElement&&) noexcept = default;
    FieldElement operator^(const __uint128_t& other) const;
    FieldElement operator/(const FieldElement& other) const;
    FieldElement operator+(const FieldElement& other) const;
    FieldElement& operator+=(const FieldElement& other);

    FieldElement operator+(const std::vector<uint8_t> &other) const;
    FieldElement operator-(const FieldElement& other) const;

    inline FieldElement operator*(const FieldElement& other) const {
        return *this * other.value;
    }

    inline FieldElement operator*(const __uint128_t& other) const {
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

    inline FieldElement& operator*=(const FieldElement& other) {
        return *this *= other.value;
    }

    inline FieldElement& operator*=(const __uint128_t& other) {
        // Perform multiplication and update the current value
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

        this->value = (static_cast<__uint128_t>(result_hi) << 64) | result_lo;
        return *this;
    }

    bool operator<(const FieldElement& other) const;
    [[nodiscard]] std::string bit_string() const;
    [[nodiscard]] std::string to_block() const;
    [[nodiscard]] std::vector<uint8_t> to_polynomial() const;
    [[nodiscard]] bool is_zero() const;
    [[nodiscard]] std::vector<uint8_t> to_vector() const;
    [[nodiscard]] FieldElement power(__uint128_t exponent) const;
    [[nodiscard]] FieldElement inverse() const;
    [[nodiscard]] FieldElement sqrt() const;
    static FieldElement random();
};

#endif // GALOIS_FAST_H
