#include <nlohmann/json.hpp>
#include <fstream>
#include <iostream>
#include <util/processor.h>

using json = nlohmann::json;

int main(int argc, char* argv[]) {
    // std::string file = "/home/user/Documents/Uni/Krypto/krypto_julia/sample.json";



    // std::string file = "../sample_small.json";
    std::string file = "../sample_current.json";


    if(argc == 2) {
        file = argv[1];
    }

    std::ifstream ifs(file);
    if(!ifs.is_open()) {
        std::cerr << "Failed to open file: " << file << std::endl;
        return 1;
    }

    json jsonContent;
    try {
        ifs >> jsonContent;
    }
    catch(const std::exception& e) {
        std::cerr << "JSON parse error: " << e.what() << std::endl;
        return 1;
    }

    for (int i = 0; i < 1000; ++i) {
        json result = process(jsonContent);
        //std::cout << result.dump() << std::endl;
    }
    json result = process(jsonContent);
    std::cout << result.dump() << std::endl;

    return 0;
}