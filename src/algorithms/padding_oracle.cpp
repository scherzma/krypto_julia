// src/algorithms/padding_oracle.cpp
#include "padding_oracle.h"
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <vector>
#include <cstdint>
#include <iostream>

struct PaddingClient {
    int sockfd;
    PaddingClient(const std::string& hostname, int port) {
        struct addrinfo hints{}, *addrs;
        hints.ai_family = AF_INET;
        hints.ai_socktype = SOCK_STREAM;

        std::string port_str = std::to_string(port);

        int res = getaddrinfo(hostname.c_str(), port_str.c_str(), &hints, &addrs);
        if (res != 0) {
            std::cerr << "getaddrinfo: " << gai_strerror(res) << std::endl;
            sockfd = -1;
            return;
        }

        for (struct addrinfo* addr = addrs; addr != nullptr; addr = addr->ai_next) {
            sockfd = socket(addr->ai_family, addr->ai_socktype, addr->ai_protocol);
            if (sockfd == -1)
                continue;

            if (connect(sockfd, addr->ai_addr, addr->ai_addrlen) == 0)
                break;

            close(sockfd);
            sockfd = -1;
        }

        freeaddrinfo(addrs);

        if (sockfd == -1) {
            std::cerr << "Failed to connect to " << hostname << ":" << port << std::endl;
        }
    }

    ~PaddingClient() {
        if (sockfd != -1) {
            close(sockfd);
        }
    }

    void send(const std::vector<uint8_t>& data) {
        ssize_t total_sent = 0;
        while (total_sent < data.size()) {
            ssize_t sent = ::send(sockfd, data.data() + total_sent, data.size() - total_sent, 0);
            if (sent == -1) {
                std::cerr << "send error" << std::endl;
                break;
            }
            total_sent += sent;
        }
    }

    std::vector<uint8_t> receive(int length) {
        std::vector<uint8_t> data(length);
        ssize_t total_received = 0;
        while (total_received < length) {
            ssize_t received = ::recv(sockfd, data.data() + total_received, length - total_received, 0);
            if (received == -1) {
                std::cerr << "recv error" << std::endl;
                break;
            } else if (received == 0) {
                std::cerr << "Connection closed by peer" << std::endl;
                break;
            }
            total_received += received;
        }
        data.resize(total_received);
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

    for(size_t i = 16; i < text.size(); i += 16){
        std::vector<uint8_t> block_to_decrypt(text.begin() + i, text.begin() + i + 16);
        std::vector<uint8_t> previous_block(text.begin() + i - 16, text.begin() + i);
        std::vector<uint8_t> decrypted_block = attack_block(hostname, port, block_to_decrypt, previous_block);
        plaintext.insert(plaintext.end(), decrypted_block.begin(), decrypted_block.end());
    }

    // Remove padding
    if(!plaintext.empty()){
        uint8_t pad = plaintext.back();
        if(pad <= 16){
            plaintext.erase(plaintext.end() - pad, plaintext.end());
        }
    }
    return plaintext;
}
