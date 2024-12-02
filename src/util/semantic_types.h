#ifndef SEMANTIC_TYPES_H
#define SEMANTIC_TYPES_H

#include <string>

enum class Semantic {
    GCM,
    XEX
};

inline Semantic from_string(const std::string& s) {
    if (s == "gcm") {
        return Semantic::GCM;
    }
    return Semantic::XEX;
}

#endif