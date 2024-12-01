//
// Created by user on 01/12/24.
//

#include "sff.h"

#include <set>

std::set<std::tuple<Polynomial, int>> sff(const Polynomial& fx) {
    Polynomial one = Polynomial({FieldElement(1, Semantic::GCM, true)});
    Polynomial f =  fx.monic();

    Polynomial c = f.gcd(f.diff());
    f = f / c;
    std::set<std::tuple<Polynomial, int>> z;
    int e = 1;

    while (f != one) {
        Polynomial y = f.gcd(c);
        if(f != y){
            z.emplace(f/y, e);
        }
        f = y;
        c = c / y;
        e = e + 1;
    }

    if(c != one) {
        for(const auto& [t, exponent] : sff(c.sqrt())){
            z.emplace(t, exponent + exponent);
        }
    }
    return z;
}
