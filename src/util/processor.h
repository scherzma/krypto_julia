// src/util/processor.h
#ifndef PROCESSOR_H
#define PROCESSOR_H

#include <string>
#include <vector>
#include <cstdint>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

// Function to process JSON content
json process(const json& jsonContent);

#endif // PROCESSOR_H
