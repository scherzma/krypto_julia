//
// Created by user on 12/2/24.
//

#include "edf.h"

#include <iostream>
#include <ostream>


Polynomial powmod_128_div3(const Polynomial A, const Polynomial& M, __uint128_t k) {
    Polynomial one_fe({FieldElement(1, Semantic::GCM, true)});

    Polynomial result = one_fe;
    for(int i=0; i<((128 * k) - 1) / 2; ++i){
        result = result * A % M;
        result = (result * result) % M;
        result = (result * result) % M;
    }
    result = result * A;
    return result;
}


std::set<Polynomial> edf(const Polynomial& f, int d) {
    Polynomial one = Polynomial({FieldElement(1, Semantic::GCM, true)});
    Polynomial h = Polynomial();

    // q = 1 << 128
    __uint128_t n = (f.power - 1) / d;
    std::set<Polynomial> z;
    z.insert(f);

    while(z.size() < n) {
        h = Polynomial::random(f.power - 1);
        Polynomial g = powmod_128_div3(h, f, d) - one;
        if (z.size() >= 2) {
            std::cout << z.size() << std::endl;
        }

        for(Polynomial u : z) {
            if (u.power > d) {
                Polynomial j = u.gcd(g);
                if (j != one && j != u) {
                    z.erase(u);
                    z.insert(j);
                    z.insert(u / j);
                }
            }
        }
    }

    return z;
}