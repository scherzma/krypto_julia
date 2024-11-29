// src/algorithms/gcm.cpp
#include "gcm.h"
#include "../util/semantic_types.h"
#include "../util/helper_functions.h"
#include "../math/galois.h"
#include "../algorithms/sea128.h"
#include <vector>
#include <cstdint>
#include <stdexcept>
#include <tuple>
#include <algorithm>

#include <functional>


std::vector<uint8_t> pad_array(const std::vector<uint8_t>& arr) {
    size_t pad_len = (16 - (arr.size() % 16)) % 16;
    std::vector<uint8_t> padded = arr;
    padded.resize(arr.size() + pad_len, 0);
    return padded;
}


std::tuple<FieldElement, std::vector<uint8_t>, FieldElement> ghash(
    const std::vector<uint8_t>& key,
    const std::vector<uint8_t>& nonce,
    const std::vector<uint8_t>& text,
    const std::vector<uint8_t>& ad,
    const std::string& algorithm) {

    std::function<std::vector<uint8_t>(const std::vector<uint8_t>&, const std::vector<uint8_t>&)> enc_func;
    enc_func = algorithm == "aes128" ? aes_encrypt : encrypt_sea;

    std::vector<uint8_t> zero_block(16, 0);
    std::vector<uint8_t> encrypted_zero = enc_func(key, zero_block);
    __uint128_t auth_key_int = bytes_to_uint128(encrypted_zero);
    FieldElement auth_key(auth_key_int, Semantic::GCM, false);

    uint64_t ad_bit_len = static_cast<uint64_t>(ad.size()) * 8;
    uint64_t text_bit_len = static_cast<uint64_t>(text.size()) * 8;

    // Convert to big endian bytes
    std::vector<uint8_t> len_block(16, 0);
    for(int i = 0; i < 8; ++i){
        len_block[15 - i] = (text_bit_len >> (i * 8)) & 0xFF;
        len_block[7 - i] = (ad_bit_len >> (i * 8)) & 0xFF;
    }

    std::vector<uint8_t> padded_ad = pad_array(ad);
    std::vector<uint8_t> padded_text = pad_array(text);


    // Concatenate padded AD, padded text, and len_block
    std::vector<uint8_t> data;
    data.reserve(padded_ad.size() + padded_text.size() + len_block.size());
    data.insert(data.end(), padded_ad.begin(), padded_ad.end());
    data.insert(data.end(), padded_text.begin(), padded_text.end());
    data.insert(data.end(), len_block.begin(), len_block.end());

    // Initialize Y as zero
    FieldElement Y(0, Semantic::GCM, false);

    // Iterate over each 16-byte block
    for(size_t i = 0; i < data.size(); i += 16){
        std::vector<uint8_t> block(data.begin() + i, data.begin() + i + 16);
        __uint128_t block_int = bytes_to_uint128(block);
        FieldElement block_fe(block_int, Semantic::GCM, false);
        Y = Y + block_fe;
        Y = Y * auth_key;
    }

    std::vector<uint8_t> ctr_block = nonce;
    if(nonce.size() != 12){
        throw std::invalid_argument("Nonce must be 12 bytes for GCM.");
    }
    ctr_block.insert(ctr_block.end(), {0, 0, 0, 1}); // TODO: Fix this
    std::vector<uint8_t> S = enc_func(key, ctr_block);

    // Convert tag_int to bytes
    FieldElement tag = Y + S;

    return {tag, len_block, auth_key};
}

std::vector<uint8_t> crypt_gcm(
        const std::vector<uint8_t>& key,
        const std::vector<uint8_t>& text,
        const std::vector<uint8_t>& nonce,
        const std::string& algorithm) {
    std::vector<uint8_t> result_text;


    std::function<std::vector<uint8_t>(const std::vector<uint8_t>&, const std::vector<uint8_t>&)> enc_func;
    enc_func = algorithm == "aes128" ? aes_encrypt : encrypt_sea;

    uint32_t counter = 2;
    for (size_t i = 0; i < text.size(); i += 16) {
        std::vector<uint8_t> temp_nonce = nonce;
        temp_nonce.push_back((counter >> 24) & 0xFF);
        temp_nonce.push_back((counter >> 16) & 0xFF);
        temp_nonce.push_back((counter >> 8) & 0xFF);
        temp_nonce.push_back(counter & 0xFF);
        std::vector<uint8_t> enc_ctr = enc_func(key, temp_nonce);

        std::vector<uint8_t> block(text.begin() + i, text.begin() + std::min(i + 16, text.size()));
        std::vector<uint8_t> encrypted = enc_func(key, block);
        // XOR with encrypted counter block
        for (size_t j = 0; j < encrypted.size(); ++j) {
            encrypted[j] = enc_ctr[j] ^ block[j];
        }
        result_text.insert(result_text.end(), encrypted.begin(), encrypted.end());
        counter++;
    }

    return result_text;
}


std::tuple<std::vector<uint8_t>, FieldElement, std::vector<uint8_t>, FieldElement> encrypt_gcm(
        const std::vector<uint8_t>& key,
        const std::vector<uint8_t>& plaintext,
        const std::vector<uint8_t>& ad,
        const std::vector<uint8_t>& nonce,
        const std::string& algorithm) {

    auto cipertext = crypt_gcm(key, plaintext, nonce, algorithm);
    auto [auth_tag, len_block, auth_key] = ghash(key, nonce, cipertext, ad, algorithm);

    return {cipertext, auth_tag, len_block, auth_key};
}


std::tuple<std::vector<uint8_t>, std::vector<uint8_t>, std::vector<uint8_t>, std::vector<uint8_t>> decrypt_gcm(
        const std::vector<uint8_t>& key,
        const std::vector<uint8_t>& ciphertext,
        const std::vector<uint8_t>& ad,
        const std::vector<uint8_t>& nonce,
        const std::string& algorithm) {

    auto [auth_tag, len_block, auth_key] = ghash(key, nonce, ciphertext, ad, algorithm);
    auto plaintext = crypt_gcm(key, ciphertext, nonce, algorithm);

    return {plaintext, auth_tag.to_vector(), len_block, auth_key.to_vector()};
}