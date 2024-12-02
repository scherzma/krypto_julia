// src/algorithms/gcm.h
#ifndef GCM_H
#define GCM_H

#include <vector>
#include <string>
#include <cstdint>
#include <tuple>

#include "math/galois.h"




std::tuple<std::vector<uint8_t>, std::string, std::vector<uint8_t>, std::vector<uint8_t>> decrypt_gcm(
        const std::vector<uint8_t>& key,
        const std::vector<uint8_t>& ciphertext,
        const std::vector<uint8_t>& ad,
        const std::vector<uint8_t>& nonce,
        const std::string& algorithm);

std::tuple<std::vector<uint8_t>, FieldElement, std::vector<uint8_t>, FieldElement> encrypt_gcm(
        const std::vector<uint8_t>& key,
        const std::vector<uint8_t>& plaintext,
        const std::vector<uint8_t>& ad,
        const std::vector<uint8_t>& nonce,
        const std::string& algorithm);

std::vector<uint8_t> crypt_gcm(
        const std::vector<uint8_t>& key,
        const std::vector<uint8_t>& text,
        const std::vector<uint8_t>& nonce,
        const std::string& algorithm);

std::tuple<FieldElement, std::vector<uint8_t>, FieldElement> ghash(
    const std::vector<uint8_t>& key,
    const std::vector<uint8_t>& nonce,
    const std::vector<uint8_t>& text,
    const std::vector<uint8_t>& ad,
    const std::string& algorithm);


std::vector<uint8_t> pad_array(const std::vector<uint8_t>& arr);

#endif // GCM_H
