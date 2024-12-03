// src/math/polynom.cpp
#include "polynom.h"
#include <algorithm>
#include <iostream>
#include <stdexcept>

Polynomial::Polynomial(const std::vector<std::string>& coeffs, Semantic semantic_type){
    coefficients.reserve(coeffs.size());
    for(const auto& s : coeffs){
        coefficients.emplace_back(FieldElement(s, semantic_type));
    }
    power = coefficients.size();
    reduce_pol();
}

bool Polynomial::is_zero() const {
    return power == 0 || (power ==1 && coefficients[0].is_zero());
}

Polynomial Polynomial::reduce_pol() const {
    Polynomial reduced = *this; // Create a copy
    int new_power = reduced.power;
    while(new_power > 0 && reduced.coefficients[new_power -1].value == 0){
        new_power--;
    }
    reduced.power = new_power;
    reduced.coefficients.resize(new_power);
    if(reduced.power == 0){
        reduced.coefficients.emplace_back(FieldElement(0, Semantic::GCM, true));
    }
    return reduced;
}

bool Polynomial::operator<(const Polynomial& other) const {
    if(this->power < other.power){
        return true;
    }
    if(this->power > other.power){
        return false;
    }
    for(int i = power -1; i>=0; --i){
        if(this->coefficients[i] < other.coefficients[i]){
            return true;
        }
        if(other.coefficients[i] < this->coefficients[i]){
            return false;
        }
    }
    return false;
}

Polynomial Polynomial::operator+(const Polynomial& other) const {
    int max_power = std::max(this->power, other.power);
    std::vector<FieldElement> result_coeffs(max_power, FieldElement(0, Semantic::GCM, false));
    for(int i=0; i<max_power; ++i){
        FieldElement a = (i < this->power) ? this->coefficients[i] : FieldElement(0, Semantic::GCM, true);
        FieldElement b = (i < other.power) ? other.coefficients[i] : FieldElement(0, Semantic::GCM, true);
        result_coeffs[i] = a + b;
    }
    Polynomial result(result_coeffs);
    return result.reduce_pol();
}

Polynomial Polynomial::operator-(const Polynomial& other) const {
    return *this + other; // same as addition in GF(2^n)
}

Polynomial Polynomial::operator*(const Polynomial& other) const {
    Polynomial result = *this; // Initialize result as a copy of the current polynomial
    result *= other; // Use the in-place multiplication operator
    return result;
}


Polynomial& Polynomial::operator*=(const Polynomial& other) {
    if (this->power == 0 || other.power == 0) {
        this->coefficients = {FieldElement(0, Semantic::GCM, true)};
        this->power = 1;
        return *this;
    }

    std::vector<FieldElement> result_coeffs(this->power + other.power - 1, FieldElement(0, Semantic::GCM, true));
    FieldElement temp;
    for (int i = 0; i < this->power; ++i) {
        for (int j = 0; j < other.power; ++j) {
            temp = this->coefficients[i];
            temp *= other.coefficients[j];
            result_coeffs[i + j] += temp;
        }
    }

    this->coefficients = result_coeffs;
    this->power = this->coefficients.size();
    *this = this->reduce_pol();
    return *this;
}

Polynomial Polynomial::operator^(int exponent) const {
    if(exponent ==0){
        return Polynomial({FieldElement(1, Semantic::GCM, true)});
    }
    Polynomial result({FieldElement(1, Semantic::GCM, true)});
    Polynomial base = *this;
    while(exponent > 0){
        if(exponent &1){
            result *= base;
        }
        base *= base;
        exponent >>=1;
    }
    return result.reduce_pol();
}

Polynomial Polynomial::operator/(const Polynomial& divisor) const {
    auto [Q, _] = this->divide(divisor);
    return Q;
}

Polynomial Polynomial::operator%(const Polynomial& divisor) const {
    auto [_, R] = this->divide(divisor);
    return R;
}

bool Polynomial::operator!=(const Polynomial& other) const {
    return !(*this == other);
}

bool Polynomial::operator==(const Polynomial& other) const {
    return coefficients == other.coefficients;
}


std::pair<Polynomial, Polynomial> Polynomial::divide(const Polynomial& divisor) const {
    if(divisor.is_zero()){
        throw std::invalid_argument("Division by zero polynomial");
    }

    Polynomial dividend = this->reduce_pol();
    Polynomial divisor_reduced = divisor.reduce_pol();

    if(dividend.power < divisor_reduced.power){
        Polynomial quotient({FieldElement(0, Semantic::GCM, true)});
        return {quotient, dividend};
    }

    int quotient_degree = dividend.power - divisor_reduced.power;
    std::vector<FieldElement> quotient_coeffs(quotient_degree +1, FieldElement(0, Semantic::GCM, true));

    std::vector<FieldElement> remainder_coeffs = dividend.coefficients;
    int remainder_degree = dividend.power;

    FieldElement divisor_lead = divisor_reduced.coefficients[divisor_reduced.power -1];
    FieldElement divisor_inv = divisor_lead.inverse();

    while(remainder_degree >= divisor_reduced.power){
        FieldElement lead_coeff_rem = remainder_coeffs[remainder_degree -1];
        FieldElement factor = lead_coeff_rem * divisor_inv;
        int degree_diff = remainder_degree - divisor_reduced.power;
        quotient_coeffs[degree_diff] = quotient_coeffs[degree_diff] + factor;

        for(int i=0; i< divisor_reduced.power; ++i){
            int j = i + degree_diff;
            remainder_coeffs[j] = remainder_coeffs[j] - (divisor_reduced.coefficients[i] * factor);
        }

        while(remainder_degree >0 && remainder_coeffs[remainder_degree -1].is_zero()){
            remainder_degree--;
        }

        if(remainder_degree ==0){
            break;
        }
    }

    Polynomial quotient(quotient_coeffs);
    quotient = quotient.reduce_pol();

    std::vector<FieldElement> remainder_final_coeffs(remainder_coeffs.begin(), remainder_coeffs.begin() + remainder_degree);
    Polynomial remainder(remainder_final_coeffs);
    remainder = remainder.reduce_pol();

    return {quotient, remainder};
}


std::vector<std::string> Polynomial::repr() const {
    std::vector<std::string> representation;
    for(const auto& fe : coefficients){
        representation.push_back(fe.to_block());
    }
    return representation;
}

Polynomial Polynomial::monic() const {
    if(this->is_zero()){
        throw std::invalid_argument("Cannot make zero polynomial monic");
    }
    FieldElement lead_coeff_inv = this->coefficients[this->power -1].inverse();
    std::vector<FieldElement> new_coeffs = this->coefficients;
    for(auto& coeff : new_coeffs){
        coeff *= lead_coeff_inv;
    }
    Polynomial result(new_coeffs);
    return result.reduce_pol();
}

Polynomial Polynomial::diff() const {
    std::vector<FieldElement> derivative_coeffs;
    for(int i=1; i<this->power; ++i){
        if(i %2 ==1){
            derivative_coeffs.push_back(this->coefficients[i]);
        }
        else{
            derivative_coeffs.emplace_back(FieldElement(0, Semantic::GCM, true));
        }
    }
    Polynomial derivative(derivative_coeffs);
    return derivative.reduce_pol();
}


Polynomial Polynomial::gcd(const Polynomial& other) const {
    Polynomial a = this->reduce_pol();
    Polynomial b = other.reduce_pol();
    while(!b.is_zero()){
        auto [q, r] = a.divide(b);
        a = b;
        b = r;
    }
    return a.monic();
}


Polynomial Polynomial::gfpoly_powmod(const Polynomial& M, int k) const {
    if (k < 0) {
        throw std::invalid_argument("Exponent must be non-negative");
    }

    Polynomial one_fe({FieldElement(1, Semantic::GCM, true)});
    Polynomial result = one_fe;

    // Perform modular reduction on *this
    auto [_, base] = this->divide(M);

    while (k > 0) {
        if (k & 1) {
            // result = (result * base) % M
            auto [tmp_q, tmp_r] = (result * base).divide(M);
            result = tmp_r;
        }
        // base = (base * base) % M
        auto [tmp_q, tmp_r] = (base * base).divide(M);
        base = tmp_r;

        k >>= 1; // Divide k by 2
    }

    return result;
}


Polynomial Polynomial::sqrt() const {
    // Validate that the polynomial has only even exponents with non-zero coefficients
    for (int i = 0; i < power; ++i) {
        if ((i % 2 == 1) && !coefficients[i].is_zero()) {
            throw std::invalid_argument("Polynomial must have only even exponents with non-zero coefficients.");
        }
    }

    // Determine the degree of the resulting square root polynomial
    int m = power / 2;
    std::vector<FieldElement> S_coeffs(m + 1);

    // Compute the coefficients of the square root polynomial
    for (int i = 0; i <= m; ++i) {
        FieldElement q_2i = coefficients[2 * i];
        S_coeffs[i] = q_2i.sqrt(); // Ensure FieldElement has a sqrt() method implemented
    }

    // Create and return the reduced polynomial
    Polynomial S(S_coeffs);
    return S.reduce_pol();
}

Polynomial Polynomial::random(int degree) {
    Polynomial result;

    for (int i = 0; i < degree; ++i) {
        result.coefficients.push_back(FieldElement::random());
    }
    result.power = result.coefficients.size();

    return result;
}