

module Processing
using JSON
using Base64

include("../util/semantic_types.jl")
using .SemanticTypes: Semantic, from_string
include("../math/galois_fast.jl")
include("../algorithms/sea128.jl")
include("../algorithms/xex_fde.jl")
include("../algorithms/gcm.jl")
include("../algorithms/padding_oracle.jl")
using .PaddingOracle: PaddingClient, padding_attack
using .Galois_quick: FieldElement_quick
using .Sea128: encrypt_sea, decrypt_sea
using .FDE: encrypt_fde, decrypt_fde
using .GCM: encrypt_gcm, decrypt_gcm
using Base.Threads



function add_numbers(jsonContent::Dict)
    return jsonContent["number1"] + jsonContent["number2"]
end

function subtract_numbers(jsonContent::Dict)
    return jsonContent["number1"] - jsonContent["number2"]
end

function poly2block(jsonContent::Dict)
    coefficients::Array{UInt8} = jsonContent["coefficients"]
    semantic = from_string(jsonContent["semantic"])
    gf = FieldElement_quick(coefficients, semantic)
    return gf.to_block()
end

function block2poly(jsonContent::Dict)
    semantic = from_string(jsonContent["semantic"])
    block::String = jsonContent["block"]

    gf = FieldElement_quick(block, semantic)

    result = gf.to_polynomial()
    return result
end

function gfmul(jsonContent::Dict)
    semantic = from_string(jsonContent["semantic"])
    a::String = jsonContent["a"]
    b::String = jsonContent["b"]

    gf_a = FieldElement_quick(a, semantic)
    gf_b = FieldElement_quick(b, semantic)

    product = gf_a * gf_b
    return product.to_block()
end

function sea128(jsonContent::Dict)
    mode::String = jsonContent["mode"]
    key::String = jsonContent["key"]
    input::String = jsonContent["input"]
    
    key_bytes = base64decode(key)
    input_bytes = base64decode(input)

    if mode == "encrypt"
        result_bytes = encrypt_sea("aes128", key_bytes, input_bytes)
    elseif mode == "decrypt"
        result_bytes = decrypt_sea("aes128", key_bytes, input_bytes)
    end

    return base64encode(result_bytes)
end

function xex(jsonContent::Dict)
    mode::String = jsonContent["mode"]
    key::String = jsonContent["key"]
    tweak::String = jsonContent["tweak"]
    input::String = jsonContent["input"]

    key_bytes = base64decode(key)
    tweak_bytes = base64decode(tweak)
    input_bytes = base64decode(input)

    if mode == "encrypt"
        result_bytes = encrypt_fde(key_bytes, tweak_bytes, input_bytes)
    elseif mode == "decrypt"
        result_bytes = decrypt_fde(key_bytes, tweak_bytes, input_bytes)
    end

    return base64encode(result_bytes)
end

function gcm_crypt(jsonContent::Dict, mode::String)
    algorithm::String = jsonContent["algorithm"]
    key::String = jsonContent["key"]
    ad::String = jsonContent["ad"]
    nonce::String = jsonContent["nonce"]

    text::String = ""
    if mode == "encrypt"
        text = jsonContent["plaintext"]
    elseif mode == "decrypt"
        text = jsonContent["ciphertext"]
        tag::String = jsonContent["tag"]
    end

    key_bytes = base64decode(key)
    ad_bytes = base64decode(ad)
    nonce_bytes = base64decode(nonce)
    text_bytes = base64decode(text)

    if mode == "encrypt"
        result = encrypt_gcm(key_bytes, text_bytes, ad_bytes, nonce_bytes, algorithm)
        return base64encode(result[1]), result[2].to_block(), base64encode(result[3]), result[4].to_block()
    elseif mode == "decrypt"
        result = decrypt_gcm(key_bytes, text_bytes, ad_bytes, nonce_bytes, algorithm)
        return result[2].to_block() == tag, base64encode(result[1])
    end

    return result
end

function gcm_decrypt(jsonContent::Dict)
    mode::String = "decrypt"
    return gcm_crypt(jsonContent, mode)
end

function gcm_encrypt(jsonContent::Dict)
    mode::String = "encrypt"
    return gcm_crypt(jsonContent, mode)
end

function padding_oracle(jsonContent::Dict)
    hostname::String = jsonContent["hostname"]
    if hostname == "localhost"
        hostname = "127.0.0.1"
    end
    port::Int = jsonContent["port"]
    iv::Array{UInt8} = base64decode(jsonContent["iv"])
    ciphertext::Array{UInt8} = base64decode(jsonContent["ciphertext"])
    result = padding_attack(hostname, port, iv, ciphertext)
    return base64encode(result)
end


ACTIONS::Dict{String, Vector{Any}} = Dict(
    "add_numbers" => [add_numbers, ["sum"]],
    "subtract_numbers" => [subtract_numbers, ["difference"]],
    "poly2block" => [poly2block, ["block"]],
    "block2poly" => [block2poly, ["coefficients"]],
    "gfmul" => [gfmul, ["polynomial"]],
    "sea128" => [sea128, ["ciphertext"]],
    "xex" => [xex, ["ciphertext"]],
    "gcm_encrypt" => [gcm_encrypt, ["ciphertext", "tag", "L", "H"]],
    "gcm_decrypt" => [gcm_decrypt, ["authentic", "plaintext"]],
    "padding_oracle" => [padding_oracle, ["plaintext"]],
)

function process(jsonContent::Dict)

    result_testcases = Dict()

    for (key, value) in jsonContent["testcases"]
        action = value["action"]
        arguments = value["arguments"]
        output_key = ACTIONS[action][2]

        if !haskey(ACTIONS, action)
            throw(ProcessingError("Unknown action: $action"))
        end

        result = nothing
        try
            result = ACTIONS[action][1](arguments)
        catch e
            println(stderr, "Error: $e")
        end

        json_result = Dict()

        for (i, key) in enumerate(output_key)
            if length(ACTIONS[action][2]) == 1
                json_result[key] = result
            else
                json_result[key] = result[i]
            end
        end

        result_testcases[key] = json_result
    end

    println(JSON.json(Dict("testcases" => result_testcases)))

end
end