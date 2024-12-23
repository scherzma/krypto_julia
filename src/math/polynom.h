// src/math/polynom.h

#ifndef POLYNOM_H
#define POLYNOM_H

#include <vector>
#include <string>
#include "galois.h"

class Polynomial {
public:
    std::vector<FieldElement> coefficients;
    int power;

    Polynomial() = default;
    Polynomial(const std::vector<FieldElement>& coeffs)
        : coefficients(coeffs), power(coeffs.size()) {
        reduce_pol();
    }

    Polynomial(const std::vector<std::string>& coeffs, Semantic semantic_type);

    [[nodiscard]] bool is_zero() const;

    // Make reduce_pol a const method
    Polynomial reduce_pol() const;

    bool operator<(const Polynomial& other) const;

    Polynomial(const Polynomial&) = default;
    Polynomial& operator=(const Polynomial&) = default;
    Polynomial& operator=(Polynomial&&) noexcept = default;
    bool operator!=(const Polynomial& other) const;
    bool operator==(const Polynomial& other) const;

    Polynomial operator+(const Polynomial& other) const;
    Polynomial operator-(const Polynomial& other) const;
    Polynomial operator*(const Polynomial& other) const;
    Polynomial operator^(int exponent) const;

    Polynomial& operator*=(const Polynomial& other);


    Polynomial operator/(const Polynomial& divisor) const;
    Polynomial operator%(const Polynomial& divisor) const;
    [[nodiscard]] std::pair<Polynomial, Polynomial> divide(const Polynomial& divisor) const;

    // Additional methods
    [[nodiscard]] std::vector<std::string> repr() const;
    [[nodiscard]] Polynomial monic() const;
    [[nodiscard]] Polynomial diff() const;
    [[nodiscard]] Polynomial gcd(const Polynomial& other) const;
    [[nodiscard]] Polynomial gfpoly_powmod(const Polynomial& M, int k) const;
    [[nodiscard]] Polynomial sqrt() const;
    static Polynomial random(int degree);
private:
    // Helper methods
};

#endif // POLYNOM_H
