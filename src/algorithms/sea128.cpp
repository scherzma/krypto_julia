// sea128.cpp
#include "sea128.h"
#include <botan/block_cipher.h>
#include <botan/aes.h>
#include <stdexcept>
#include "gcm.h" // If needed

std::vector<uint8_t> aes_encrypt(const std::vector<uint8_t>& key, const std::vector<uint8_t>& input) {
    Botan::AES_128 aes;
    aes.set_key(key);
    std::vector<uint8_t> output(input.size());

    for(size_t i = 0; i < input.size(); i += 16) {
        aes.encrypt_n(&input[i], &output[i], 1);
    }

    return output;
}

std::vector<uint8_t> aes_decrypt(const std::vector<uint8_t>& key, const std::vector<uint8_t>& input) {
    Botan::AES_128 aes;
    aes.set_key(key);
    std::vector<uint8_t> output(input.size());

    for(size_t i = 0; i < input.size(); i += 16) {
        aes.decrypt_n(&input[i], &output[i], 1);
    }

    return output;
}

const std::vector<uint8_t> SEA_CONST = {
    0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee, 0xc0, 0xff,
    0xee, 0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee, 0x11
};

std::vector<uint8_t> encrypt_sea(const std::vector<uint8_t>& key, const std::vector<uint8_t>& input){
    // Encrypt using SEA
    std::vector<uint8_t> encrypted = aes_encrypt(key, input);
    for(size_t i = 0; i < encrypted.size(); ++i){
        encrypted[i] ^= SEA_CONST[i];
    }
    return encrypted;
}

std::vector<uint8_t> decrypt_sea(const std::vector<uint8_t>& key, const std::vector<uint8_t>& input){
    // Decrypt using SEA (XOR with SEA_CONST)
    std::vector<uint8_t> decrypted(input.size());
    for(size_t i = 0; i < input.size(); ++i){
        decrypted[i] = input[i] ^ SEA_CONST[i];
    }

    return aes_decrypt(key, decrypted);
}
