//
// Created by user on 01/12/24.
//

#include "ddf.h"

#include <iostream>
#include <ostream>

Polynomial powmod_128(const Polynomial A, const Polynomial& M) {
    Polynomial one_fe({FieldElement(1, Semantic::GCM, true)});
    Polynomial result = one_fe;

    // Perform modular reduction on *this
    auto [_, base] = A.divide(M);

    for(int i=0; i<128; ++i){
        auto [tmp_q, tmp_r] = (base * base).divide(M);
        base = tmp_r;
    }

    auto [tmp_q, tmp_r] = (result * base).divide(M);
    result = tmp_r;

    return result;
}



std::set<std::tuple<Polynomial, int>> ddf(const Polynomial& f) {
    std::set<std::tuple<Polynomial, int>> z;

    __uint128_t q = 1 << 128;
    std::cout << (q == 0) << std::endl;
    __uint128_t d = 1;
    Polynomial fstar = f;
    Polynomial one = Polynomial({FieldElement(1, Semantic::GCM, true)});
    Polynomial zero = Polynomial({FieldElement(0, Semantic::GCM, true)});
    Polynomial X = Polynomial({FieldElement(1, Semantic::GCM, true), FieldElement(0, Semantic::GCM, true)});

    while(fstar.power - 1 >= d + d) {
        Polynomial h = zero;
        for (int i = 0; i < d - 1; ++i) {
            h = powmod_128(X, fstar);
        }
        Polynomial g = h.gcd(fstar);
        if(g != one){
            z.emplace(g, d);
            fstar = fstar / g;
        }
        d += 1;
    }

    if(fstar != one){
        z.emplace(fstar, fstar.power - 1);
    } else if (z.empty()) {
        z.emplace(f, 1);
    }

    return z;
}
