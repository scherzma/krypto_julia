// src/math/polynom.cpp
#include "polynom.h"
#include <algorithm>
#include <stdexcept>

Polynomial::Polynomial(const std::vector<std::string>& coeffs, Semantic semantic_type){
    coefficients.reserve(coeffs.size());
    for(const auto& s : coeffs){
        // Assume from_string to be a base64 decoder or similar
        // Implement as needed
        __uint128_t val = 0; // Placeholder
        // Decode s to val (Implement base64 decoding)
        // For example purposes, setting val to 0
        coefficients.emplace_back(FieldElement(val, semantic_type, true));
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
        if(this->coefficients[i].value < other.coefficients[i].value){
            return true;
        }
        if(other.coefficients[i].value < this->coefficients[i].value){
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
    std::vector<FieldElement> result_coeffs(this->power + other.power -1, FieldElement(0, Semantic::GCM, true));
    for(int i=0; i<this->power; ++i){
        for(int j=0; j<other.power; ++j){
            result_coeffs[i+j] = result_coeffs[i+j] + (this->coefficients[i] * other.coefficients[j]);
        }
    }
    Polynomial result(result_coeffs);
    return result.reduce_pol();
}

Polynomial Polynomial::operator^(int exponent) const {
    if(exponent ==0){
        return Polynomial({FieldElement(1, Semantic::GCM, true)});
    }
    Polynomial result({FieldElement(1, Semantic::GCM, true)});
    Polynomial base = *this;
    while(exponent >0){
        if(exponent &1){
            result = result * base;
        }
        base = base * base;
        exponent >>=1;
    }
    return result.reduce_pol();
}

std::pair<Polynomial, Polynomial> Polynomial::divide(const Polynomial& divisor) const {
    if(divisor.is_zero()){
        throw std::invalid_argument("Division by zero polynomial");
    }
    Polynomial dividend = *this;
    Polynomial quotient({FieldElement(0, Semantic::GCM, true)});
    int quotient_degree = dividend.power - divisor.power;
    if(quotient_degree <0){
        return {quotient, dividend};
    }
    quotient.coefficients.resize(quotient_degree +1, FieldElement(0, Semantic::GCM, true));
    while(dividend.power >= divisor.power && !dividend.is_zero()){
        int shift = dividend.power - divisor.power;
        FieldElement factor = dividend.coefficients[dividend.power -1] * divisor.coefficients[divisor.power -1].inverse();
        quotient.coefficients[shift] = quotient.coefficients[shift] + factor;
        // Subtract (divisor * factor * x^shift) from dividend
        for(int i=0; i<divisor.power; ++i){
            dividend.coefficients[i + shift] = dividend.coefficients[i + shift] - (divisor.coefficients[i] * factor);
        }
        dividend.reduce_pol();
    }
    quotient.reduce_pol();
    return {quotient, dividend};
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
        coeff = coeff * lead_coeff_inv;
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