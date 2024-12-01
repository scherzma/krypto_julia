// src/math/galois.h

#ifndef GALOIS_FAST_H
#define GALOIS_FAST_H

#include <cstdint>
#include <string>
#include <vector>
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
    FieldElement operator>>(int b) const;
    FieldElement operator/(const FieldElement& other) const;
    FieldElement operator%(const __uint128_t& b) const;
    FieldElement operator%(const FieldElement& other) const;
    FieldElement operator+(const FieldElement& other) const;
    FieldElement operator+(const std::vector<uint8_t> &other) const;
    FieldElement operator-(const FieldElement& other) const;
    FieldElement operator*(const FieldElement& other) const;
    FieldElement operator*(const __uint128_t& other) const;


    [[nodiscard]] std::string bit_string() const;
    [[nodiscard]] std::string to_block() const;
    [[nodiscard]] std::vector<uint8_t> to_polynomial() const;
    [[nodiscard]] bool is_zero() const;
    [[nodiscard]] std::vector<uint8_t> to_vector() const;
    [[nodiscard]] FieldElement power(__uint128_t exponent) const;
    [[nodiscard]] FieldElement inverse() const;
    [[nodiscard]] FieldElement sqrt() const;
};

#endif // GALOIS_FAST_H
