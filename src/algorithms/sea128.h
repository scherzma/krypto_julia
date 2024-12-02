// sea128.h
#ifndef SEA128_H
#define SEA128_H

#include <string>
#include <vector>
#include <cstdint>

// Encrypt using SEA128
std::vector<uint8_t> encrypt_sea(const std::vector<uint8_t>& key, const std::vector<uint8_t>& input);

// Decrypt using SEA128
std::vector<uint8_t> decrypt_sea(const std::vector<uint8_t>& key, const std::vector<uint8_t>& input);

// AES Encrypt
std::vector<uint8_t> aes_encrypt(const std::vector<uint8_t>& input, const std::vector<uint8_t>& key);

// AES Decrypt
std::vector<uint8_t> aes_decrypt(const std::vector<uint8_t>& input, const std::vector<uint8_t>& key);

#endif // SEA128_H
