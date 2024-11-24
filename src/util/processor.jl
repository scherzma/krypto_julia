

module Processing
using JSON
using Base64

include("../util/semantic_types.jl")
using .SemanticTypes: Semantic, from_string
include("../math/galois_fast.jl")
using .Galois_quick: FieldElement
include("../math/polynom.jl")
using .Polynom: Polynomial
include("../algorithms/sea128.jl")
include("../algorithms/xex_fde.jl")
include("../algorithms/gcm.jl")
include("../algorithms/padding_oracle.jl")
using .PaddingOracle: PaddingClient, padding_attack
using .Galois_quick: FieldElement
using .Polynom: Polynomial
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
    gf = FieldElement(coefficients, semantic)
    return gf.to_block()
end

function block2poly(jsonContent::Dict)
    semantic = from_string(jsonContent["semantic"])
    block::String = jsonContent["block"]

    gf = FieldElement(block, semantic)

    result = gf.to_polynomial()
    return result
end

function gfmul(jsonContent::Dict)
    semantic = from_string(jsonContent["semantic"])
    a::String = jsonContent["a"]
    b::String = jsonContent["b"]

    gf_a = FieldElement(a, semantic)
    gf_b = FieldElement(b, semantic)

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

function polynomial_add(jsonContent::Dict)
    A::Array{String} = jsonContent["A"]
    B::Array{String} = jsonContent["B"]

    poly_A = Polynomial(A)
    poly_B = Polynomial(B)

    return (poly_A + poly_B).repr()
end

function polynomial_mul(jsonContent::Dict)
    A::Array{String} = jsonContent["A"]
    B::Array{String} = jsonContent["B"]

    poly_A = Polynomial(A)
    poly_B = Polynomial(B)

    return (poly_A * poly_B).repr()
end

function polynomial_pow(jsonContent::Dict)
    A::Array{String} = jsonContent["A"]
    B::Int = jsonContent["k"]

    poly_A = Polynomial(A)
    return (poly_A ^ B).repr()
end

function gfdiv(jsonContent::Dict)
    A::String = jsonContent["a"]
    B::String = jsonContent["b"]

    a = FieldElement(A, from_string("gcm"))
    b = FieldElement(B, from_string("gcm"))
    c = a / b
    return c.to_block()
end

function polynomial_divmod(jsonContent::Dict)
    A::Array{String} = jsonContent["A"]
    B::Array{String} = jsonContent["B"]

    poly_A = Polynomial(A)
    poly_B = Polynomial(B)
    #println(poly_A)
    #println(poly_B)

    result = poly_A / poly_B
    return result[1].repr(), result[2].repr()
end

ACTIONS::Dict{String, Vector{Any}} = Dict(
    "add_numbers" => [add_numbers, ["sum"]],
    "subtract_numbers" => [subtract_numbers, ["difference"]],
    "poly2block" => [poly2block, ["block"]],
    "block2poly" => [block2poly, ["coefficients"]],
    "gfmul" => [gfmul, ["product"]],
    "sea128" => [sea128, ["output"]],
    "xex" => [xex, ["output"]],
    "gcm_encrypt" => [gcm_encrypt, ["ciphertext", "tag", "L", "H"]],
    "gcm_decrypt" => [gcm_decrypt, ["authentic", "plaintext"]],
    "padding_oracle" => [padding_oracle, ["plaintext"]],
    "gfpoly_add" => [polynomial_add, ["S"]],
    "gfpoly_mul" => [polynomial_mul, ["P"]],
    "gfpoly_pow" => [polynomial_pow, ["Z"]],
    "gfdiv" => [gfdiv, ["q"]],
    "gfpoly_divmod" => [polynomial_divmod, ["Q", "R"]],
)

function process(jsonContent::Dict)

    result_testcases = Dict()

    for (key, value) in jsonContent["testcases"]
        action = value["action"]
        arguments = value["arguments"]

        if !haskey(ACTIONS, action)
            #throw(ErrorException("Unknown action: $action"))
            continue
        end


        output_key = ACTIONS[action][2]
        result = nothing
        try
            result = ACTIONS[action][1](arguments)
        catch e
            #println(stderr, "Error: $e")
            continue
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

    println(JSON.json(Dict("responses" => result_testcases)))

end

end
