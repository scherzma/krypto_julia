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

    Polynomial(const std::vector<FieldElement>& coeffs)
        : coefficients(coeffs), power(coeffs.size()) {
        reduce_pol();
    }

    Polynomial(const std::vector<std::string>& coeffs, Semantic semantic_type);

    bool is_zero() const;

    // Make reduce_pol a const method
    Polynomial reduce_pol() const;

    bool operator<(const Polynomial& other) const;

    Polynomial operator+(const Polynomial& other) const;

    Polynomial operator-(const Polynomial& other) const;

    Polynomial operator*(const Polynomial& other) const;

    Polynomial operator^(int exponent) const;

    std::pair<Polynomial, Polynomial> divide(const Polynomial& divisor) const;

    // Additional methods
    std::vector<std::string> repr() const;
    Polynomial monic() const;
    Polynomial diff() const;
    Polynomial gcd(const Polynomial& other) const;

private:
    // Helper methods
};

#endif // POLYNOM_H
