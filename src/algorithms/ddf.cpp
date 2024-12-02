//
// Created by user on 01/12/24.
//

#include "ddf.h"

#include <iostream>
#include <ostream>
#include <set>


Polynomial powmod_128(const Polynomial A, const Polynomial& M, __uint128_t k) {
    Polynomial one_fe({FieldElement(1, Semantic::GCM, true)});

    Polynomial base = A % M;

    for(int i=0; i<128 * k; ++i){
        base = (base * base) % M;
    }


    return base;
}




std::set<std::tuple<Polynomial, int>> ddf(const Polynomial& f) {
    std::set<std::tuple<Polynomial, int>> z;

    __uint128_t d = 1;
    Polynomial fstar = f;
    Polynomial one = Polynomial({FieldElement(1, Semantic::GCM, true)});
    Polynomial zero = Polynomial({FieldElement(0, Semantic::GCM, true)});
    Polynomial X = Polynomial({FieldElement(0, Semantic::GCM, true), FieldElement(1, Semantic::GCM, true)});

    while(fstar.power - 1 >= 2*d) {
        Polynomial h = zero;
        h = powmod_128(X, fstar, d);
        h  = h - X;
        h = h % fstar;
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
