// src/algorithms/xex_fde.h
#ifndef XEX_FDE_H
#define XEX_FDE_H

#include <vector>
#include <string>
#include <cstdint> // Added to define uint8_t

// Encrypt using XEX FDE
std::vector<uint8_t> encrypt_fde(const std::vector<uint8_t>& key, const std::vector<uint8_t>& tweak, const std::vector<uint8_t>& input);

// Decrypt using XEX FDE
std::vector<uint8_t> decrypt_fde(const std::vector<uint8_t>& key, const std::vector<uint8_t>& tweak, const std::vector<uint8_t>& input);

#endif // XEX_FDE_H
