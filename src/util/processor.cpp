// src/util/processor.cpp
#include "processor.h"
#include "../math/galois.h"
#include "../math/polynom.h"
#include "../algorithms/gcm.h"
#include "../algorithms/sea128.h"
#include "../algorithms/xex_fde.h"
#include "../algorithms/padding_oracle.h"
#include "semantic_types.h"
#include "base64_utils.h"

#include <unordered_map>
#include <functional>
#include <stdexcept>
#include <vector>
#include <string>
#include <iostream>


using json = nlohmann::json;

// Define all action functions
json add_numbers(const json& arguments) {
    return arguments["number1"].get<int>() + arguments["number2"].get<int>();
}

json subtract_numbers(const json& arguments){
    return arguments["number1"].get<int>() - arguments["number2"].get<int>();
}

json poly2block(const json& arguments){
    std::vector<uint8_t> coefficients = arguments["coefficients"].get<std::vector<uint8_t>>();
    Semantic semantic = from_string(arguments["semantic"].get<std::string>());
    FieldElement fieldElement = FieldElement(coefficients, semantic);
    return fieldElement.to_block();
}

json block2poly(const json& arguments){
    Semantic semantic = from_string(arguments["semantic"].get<std::string>());
    std::string block = arguments["block"].get<std::string>();
    FieldElement fieldElement = FieldElement(block, semantic);
    return fieldElement.to_polynomial();
}

json gfmul(const json& arguments){
    Semantic semantic = from_string(arguments["semantic"].get<std::string>());

    std::string a_str = arguments["a"].get<std::string>();
    std::string b_str = arguments["b"].get<std::string>();
    // Convert to FieldElement
    FieldElement a(a_str, semantic);
    FieldElement b(b_str, semantic);

    FieldElement product = a * b;

    return product.to_block();
}

json sea128_operation(const json& arguments){
    std::string mode = arguments["mode"].get<std::string>();
    std::string key_str = arguments["key"].get<std::string>();
    std::string input_str = arguments["input"].get<std::string>();
    // Decode base64 key and input
    std::vector<uint8_t> key = base64_decode(key_str);
    std::vector<uint8_t> input = base64_decode(input_str);
    std::vector<uint8_t> result;
    if(mode == "encrypt"){
        result = encrypt_sea(key, input);
    }
    else{
        result = decrypt_sea(key, input);
    }
    // Encode result to base64
    return base64_encode(result);
}

json xex_fde_operation(const json& arguments){
    std::string mode = arguments["mode"].get<std::string>();
    std::string key_str = arguments["key"].get<std::string>();
    std::string tweak_str = arguments["tweak"].get<std::string>();
    std::string input_str = arguments["input"].get<std::string>();

    // Decode base64
    std::vector<uint8_t> key = base64_decode(key_str); 
    std::vector<uint8_t> tweak = base64_decode(tweak_str); 
    std::vector<uint8_t> input = base64_decode(input_str); 

    std::vector<uint8_t> result;
    if (mode == "encrypt"){
        result = encrypt_fde(key, tweak, input);
    }
    else{
        result = decrypt_fde(key, tweak, input);
    }

    // Encode result to base64
    std::string result_b64 = base64_encode(result); // Replace with actual encoding
    return result_b64;
}

json padding_oracle_attack(const json& arguments){
    std::string hostname = arguments["hostname"].get<std::string>();
    int port = arguments["port"].get<int>();
    std::string iv_str = arguments["iv"].get<std::string>();
    std::string ciphertext_str = arguments["ciphertext"].get<std::string>();

    // Decode base64
    std::vector<uint8_t> iv;          // Implement base64 decoding
    std::vector<uint8_t> ciphertext;  // Implement base64 decoding

    // Perform padding oracle attack
    std::vector<uint8_t> plaintext = padding_attack(hostname, port, iv, ciphertext);

    // Encode plaintext to base64
    std::string plaintext_b64 = "plaintext_b64"; // Replace with actual encoding
    return plaintext_b64;
}

json gcm_crypt_process(const json& arguments, bool encrypt){
    std::string algorithm = arguments["algorithm"].get<std::string>();
    std::string nonce_str = arguments["nonce"].get<std::string>();
    std::string key_str = arguments["key"].get<std::string>();
    std::string ad_str = arguments["ad"].get<std::string>();

    std::vector<uint8_t> key = base64_decode(key_str);
    std::vector<uint8_t> ad = base64_decode(ad_str);
    std::vector<uint8_t> nonce = base64_decode(nonce_str);

    if(encrypt){
        std::string plaintext_str = arguments["plaintext"].get<std::string>();
        std::vector<uint8_t> plaintext = base64_decode(plaintext_str);
        auto [ciphertext, tag, L, H] = encrypt_gcm(key, plaintext, ad, nonce, algorithm);
        return {base64_encode(ciphertext), tag.to_block(), base64_encode(L), H.to_block()};
    }
    else{
        std::string ciphertext_str = arguments["ciphertext"].get<std::string>();
        std::string tag_str = arguments["tag"].get<std::string>();
        std::vector<uint8_t> ciphertext = base64_decode(ciphertext_str);
        auto [plaintext, auth_tag, len_block, auth_key] = decrypt_gcm(key, ciphertext, ad, nonce, algorithm);

        return {auth_tag == tag_str, base64_encode(plaintext)};
    }
}

json gcm_encrypt(const json& arguments){
    return gcm_crypt_process(arguments, true);
}

json gcm_decrypt(const json& arguments){
    return gcm_crypt_process(arguments, false);
}



json polynomial_add(const json& arguments){
    std::vector<std::string> A = arguments["A"].get<std::vector<std::string>>();
    std::vector<std::string> B = arguments["B"].get<std::vector<std::string>>();

    Polynomial poly_A(A, Semantic::GCM);
    Polynomial poly_B(B, Semantic::GCM);

    Polynomial sum = poly_A + poly_B;
    return sum.repr();
}

json polynomial_mul(const json& arguments){
    std::vector<std::string> A = arguments["A"].get<std::vector<std::string>>();
    std::vector<std::string> B = arguments["B"].get<std::vector<std::string>>();

    Polynomial poly_A(A, Semantic::GCM);
    Polynomial poly_B(B, Semantic::GCM);

    Polynomial product = poly_A * poly_B;
    return product.repr();
}

json polynomial_pow(const json& arguments){
    std::vector<std::string> A = arguments["A"].get<std::vector<std::string>>();
    int k = arguments["k"].get<int>();

    Polynomial poly_A(A, Semantic::GCM);
    Polynomial power = poly_A ^ k;
    return power.repr();
}

json gfdiv(const json& arguments){
    std::string a_str = arguments["a"].get<std::string>();
    std::string b_str = arguments["b"].get<std::string>();


    FieldElement a(a_str, Semantic::GCM);
    FieldElement b(b_str, Semantic::GCM);
    FieldElement c = a / b; // Implement division

    return c.to_block();
}

json polynomial_divmod(const json& arguments){
    std::vector<std::string> A = arguments["A"].get<std::vector<std::string>>();
    std::vector<std::string> B = arguments["B"].get<std::vector<std::string>>();

    Polynomial poly_A(A, Semantic::GCM);
    Polynomial poly_B(B, Semantic::GCM);

    auto [Q, R] = poly_A.divide(poly_B);
    return {Q.repr(), R.repr()};
}

json polynomial_powmod(const json& arguments){
    std::vector<std::string> A = arguments["A"].get<std::vector<std::string>>();
    std::vector<std::string> M = arguments["M"].get<std::vector<std::string>>();
    int k = arguments["k"].get<int>();

    Polynomial poly_A(A, Semantic::GCM);
    Polynomial poly_M(M, Semantic::GCM);

    // Implement gfpoly_powmod
    // Placeholder:
    Polynomial result = poly_A ^ k; // Replace with actual powmod
    return result.repr();
}

json polynomial_sort(const json& arguments){
    std::vector<std::vector<std::string>> polys_str = arguments["polys"].get<std::vector<std::vector<std::string>>>();
    std::vector<Polynomial> polys;
    for(const auto& poly_str : polys_str){
        polys.emplace_back(Polynomial(poly_str, Semantic::GCM));
    }
    std::sort(polys.begin(), polys.end());
    std::vector<std::vector<std::string>> sorted_polys;
    for(const auto& poly : polys){
        sorted_polys.emplace_back(poly.repr());
    }
    return sorted_polys;
}

json polynomial_make_monic(const json& arguments){
    std::vector<std::string> A = arguments["A"].get<std::vector<std::string>>();
    Polynomial poly_A(A, Semantic::GCM);
    Polynomial monic = poly_A.monic();
    return monic.repr();
}

json polynomial_sqrt(const json& arguments){
    std::vector<std::string> Q = arguments["Q"].get<std::vector<std::string>>();
    Polynomial poly_Q(Q, Semantic::GCM);
    // Implement sqrt
    // Placeholder:
    Polynomial sqrt_poly = poly_Q; // Replace with actual sqrt
    return sqrt_poly.repr();
}

json polynomial_diff(const json& arguments){
    std::vector<std::string> F = arguments["F"].get<std::vector<std::string>>();
    Polynomial poly_F(F, Semantic::GCM);
    Polynomial derivative = poly_F.diff();
    return derivative.repr();
}

json polynomial_gcd(const json& arguments){
    std::vector<std::string> A = arguments["A"].get<std::vector<std::string>>();
    std::vector<std::string> B = arguments["B"].get<std::vector<std::string>>();
    Polynomial poly_A(A, Semantic::GCM);
    Polynomial poly_B(B, Semantic::GCM);
    Polynomial ans = poly_A.gcd(poly_B);
    return ans.repr();
}

struct Action {
    std::function<json(const json&)> func;
    std::vector<std::string> output_keys;
};

std::unordered_map<std::string, Action> ACTIONS{
    std::pair<std::string, Action>{"add_numbers", Action{add_numbers, {"sum"}}},
    std::pair<std::string, Action>{"subtract_numbers", Action{subtract_numbers, {"difference"}}},
    std::pair<std::string, Action>{"poly2block", Action{poly2block, {"block"}}},
    std::pair<std::string, Action>{"block2poly", Action{block2poly, {"coefficients"}}},
    std::pair<std::string, Action>{"gfmul", Action{gfmul, {"product"}}},
    std::pair<std::string, Action>{"sea128", Action{sea128_operation, {"output"}}},
    std::pair<std::string, Action>{"xex", Action{xex_fde_operation, {"output"}}},
    std::pair<std::string, Action>{"gcm_encrypt", Action{gcm_encrypt, {"ciphertext", "tag", "L", "H"}}},
    std::pair<std::string, Action>{"gcm_decrypt", Action{gcm_decrypt, {"authentic", "plaintext"}}},
    std::pair<std::string, Action>{"padding_oracle", Action{padding_oracle_attack, {"plaintext"}}},
    std::pair<std::string, Action>{"gfpoly_add", Action{polynomial_add, {"S"}}},
    std::pair<std::string, Action>{"gfpoly_mul", Action{polynomial_mul, {"P"}}},
    std::pair<std::string, Action>{"gfpoly_pow", Action{polynomial_pow, {"Z"}}},
    std::pair<std::string, Action>{"gfdiv", Action{gfdiv, {"q"}}},
    std::pair<std::string, Action>{"gfpoly_divmod", Action{polynomial_divmod, {"Q", "R"}}},
    std::pair<std::string, Action>{"gfpoly_powmod", Action{polynomial_powmod, {"Z"}}},
    std::pair<std::string, Action>{"gfpoly_sort", Action{polynomial_sort, {"sorted_polys"}}},
    std::pair<std::string, Action>{"gfpoly_make_monic", Action{polynomial_make_monic, {"A*"}}},
    std::pair<std::string, Action>{"gfpoly_sqrt", Action{polynomial_sqrt, {"S"}}},
    std::pair<std::string, Action>{"gfpoly_diff", Action{polynomial_diff, {"F'"}}},
    std::pair<std::string, Action>{"gfpoly_gcd", Action{polynomial_gcd, {"G"}}}
};

json process(const json& jsonContent){
    json result_testcases;

    for(auto& [key, value] : jsonContent["testcases"].items()){
        std::string action = value["action"].get<std::string>();
        json arguments = value["arguments"];

        if(ACTIONS.find(action) == ACTIONS.end()){
            std::cerr << "Action '" << action << "' not found" << std::endl;
            continue;
        }

        Action act = ACTIONS[action];
        json result;
        try{
            result = act.func(arguments);
        }
        catch(const std::exception& e){
            std::cerr << "Error processing action '" << action << "': " << e.what() << std::endl;
            continue;
        }

        json json_result;
        if(act.output_keys.size() ==1){
            json_result[act.output_keys[0]] = result;
        }
        else{
            for(size_t i=0; i<act.output_keys.size(); ++i){
                json_result[act.output_keys[i]] = result[i];
            }
        }

        result_testcases[key] = json_result;
    }

    return {{"responses", result_testcases}};
}
