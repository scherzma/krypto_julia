// src/algorithms/padding_oracle.cpp
#include "padding_oracle.h"
#include <boost/asio.hpp>
#include <vector>
#include <cstdint>
#include <iostream>

using boost::asio::ip::tcp;

struct PaddingClient {
    tcp::socket socket;
    PaddingClient(boost::asio::io_context& io_context, const std::string& hostname, int port)
        : socket(io_context) {
        tcp::resolver resolver(io_context);
        boost::asio::connect(socket, resolver.resolve(hostname, std::to_string(port)));
    }

    void send(const std::vector<uint8_t>& data){
        boost::asio::write(socket, boost::asio::buffer(data));
    }

    std::vector<uint8_t> receive(int length){
        std::vector<uint8_t> data(length);
        boost::asio::read(socket, boost::asio::buffer(data, length));
        return data;
    }
};

std::vector<uint8_t> attack_block(const std::string& hostname, int port, const std::vector<uint8_t>& block, const std::vector<uint8_t>& previous_block){
    // Implement attack logic
    // Placeholder implementation
    std::vector<uint8_t> plaintext_block(block.size(), 0);
    // Actual implementation needed
    return plaintext_block;
}

std::vector<uint8_t> padding_attack(const std::string& hostname, int port, const std::vector<uint8_t>& iv, const std::vector<uint8_t>& ciphertext){
    std::vector<uint8_t> plaintext;
    std::vector<uint8_t> text = iv;
    text.insert(text.end(), ciphertext.begin(), ciphertext.end());

    for(size_t i=16; i < text.size(); i +=16){
        std::vector<uint8_t> block_to_decrypt(text.begin()+i, text.begin()+i+16);
        std::vector<uint8_t> previous_block(text.begin()+i-16, text.begin()+i);
        std::vector<uint8_t> decrypted_block = attack_block(hostname, port, block_to_decrypt, previous_block);
        plaintext.insert(plaintext.end(), decrypted_block.begin(), decrypted_block.end());
    }

    // Remove padding
    if(!plaintext.empty()){
        uint8_t pad = plaintext.back();
        if(pad <=16){
            plaintext.erase(plaintext.end() - pad, plaintext.end());
        }
    }
    return plaintext;
}
