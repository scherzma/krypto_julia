// src/algorithms/padding_oracle.h
#ifndef PADDING_ORACLE_H
#define PADDING_ORACLE_H

#include <vector>
#include <string>
#include <cstdint>

// Function to perform padding oracle attack
std::vector<uint8_t> padding_attack(const std::string& hostname, int port, const std::vector<uint8_t>& iv, const std::vector<uint8_t>& ciphertext);

#endif // PADDING_ORACLE_H
