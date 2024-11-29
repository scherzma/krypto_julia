// src/algorithms/xex_fde.cpp
#include "xex_fde.h"
#include "sea128.h"
#include <vector>
#include <string>
#include <stdexcept>

// Helper function to multiply tweak by alpha
void mul_alpha(std::vector<uint8_t>& tweak){
    bool carry = (tweak[15] & 0x80) !=0;
    for(int i=15; i>0; --i){
        tweak[i] = (tweak[i] <<1) | (tweak[i-1] >>7);
    }
    tweak[0] = (tweak[0] <<1);
    if(carry){
        tweak[0] ^= 0x87;
    }
}

std::vector<uint8_t> crypt_fde(const std::vector<uint8_t>& key, std::vector<uint8_t> tweak, const std::vector<uint8_t>& input, const std::string& mode){
    if(key.size() !=32){
        throw std::invalid_argument("Key must be 32 bytes");
    }
    std::vector<uint8_t> k1(key.begin(), key.begin()+16);
    std::vector<uint8_t> k2(key.begin()+16, key.end());

    tweak = encrypt_sea(k2, tweak);

    std::vector<uint8_t> output;
    std::string crypt_mode = mode == "encrypt" ? "encrypt_sea" : "decrypt_sea";

    for(size_t i=0; i < input.size(); i +=16){
        std::vector<uint8_t> block(input.begin()+i, input.begin()+std::min(i+16, input.size()));
        // XOR with tweak
        for(size_t j=0; j<block.size(); ++j){
            block[j] ^= tweak[j];
        }
        // Encrypt/decrypt
        std::vector<uint8_t> crypt_block;
        if(mode == "encrypt"){
            crypt_block = encrypt_sea(k1, block);
        }
        else{
            crypt_block = decrypt_sea(k1, block);
        }
        // XOR with tweak
        for(size_t j=0; j<crypt_block.size(); ++j){
            crypt_block[j] ^= tweak[j];
        }
        // Append to output
        output.insert(output.end(), crypt_block.begin(), crypt_block.end());
        // Multiply tweak by alpha
        mul_alpha(tweak);
    }
    return output;
}

std::vector<uint8_t> encrypt_fde(const std::vector<uint8_t>& key, const std::vector<uint8_t>& tweak, const std::vector<uint8_t>& input){
    std::vector<uint8_t> tweak_copy = tweak;
    return crypt_fde(key, tweak_copy, input, "encrypt");
}

std::vector<uint8_t> decrypt_fde(const std::vector<uint8_t>& key, const std::vector<uint8_t>& tweak, const std::vector<uint8_t>& input){
    std::vector<uint8_t> tweak_copy = tweak;
    return crypt_fde(key, tweak_copy, input, "decrypt");
}
