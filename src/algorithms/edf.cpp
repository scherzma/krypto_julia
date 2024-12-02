//
// Created by user on 12/2/24.
//

#include "edf.h"


std::set<Polynomial> edf(const Polynomial& f, int d) {
    Polynomial one = Polynomial({FieldElement(1, Semantic::GCM, true)});
    Polynomial h = one; // TODO: Default constructor implementation

    __uint128_t q = 1 << 128;
    __uint128_t n = f.power / d;
    std::set<Polynomial> z;
    z.insert(f);

    while(z.size() < n) {
        h = one; // TODO: RandPoly()
        Polynomial temp = one; // TODO: das exponent zeug
        Polynomial g = (temp - one) % f;

        for(Polynomial u : z) {
            if (u.power > d) {
                Polynomial j = u.gcd(g);
                if (j != one && j != u) {
                    z.erase(u);
                }
            }
        }
    }
}