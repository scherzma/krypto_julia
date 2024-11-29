// src/util/base64_utils.h
#ifndef BASE64_UTILS_H
#define BASE64_UTILS_H

#include <string>
#include <vector>
#include <cstdint>

// Encode bytes to base64 string
std::string base64_encode(const std::vector<uint8_t>& data);

// Decode base64 string to bytes
std::vector<uint8_t> base64_decode(const std::string& base64_str);

#endif // BASE64_UTILS_H
