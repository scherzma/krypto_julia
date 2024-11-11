

module Processing
using JSON
include("../math/galois.jl")
using .Galois: FieldElement, galois_to_base64_alt

function add_numbers(jsonContent::Dict)
    return jsonContent["number1"] + jsonContent["number2"]
end

function subtract_numbers(jsonContent::Dict)
    return jsonContent["number1"] - jsonContent["number2"]
end

function poly2block(jsonContent::Dict)
    coefficients::Array{UInt8} = jsonContent["coefficients"]
    semantic::String = jsonContent["semantic"]
    gf = FieldElement(coefficients, semantic)
    return gf.to_block(semantic)
end

function block2poly(jsonContent::Dict)
    semantic::String = jsonContent["semantic"]
    block::String = jsonContent["block"]
    gf = FieldElement(base64decode(block), semantic)
    return gf.to_polynomial()
end

function gfmul(jsonContent::Dict)
    semantic::String = jsonContent["semantic"]
    a::String = jsonContent["a"]
    b::String = jsonContent["b"]
    gf_a = FieldElement(base64decode(a), semantic)
    gf_b = FieldElement(base64decode(b), semantic)
    return (gf_a * gf_b).to_block(semantic)
end

function sea128(jsonContent::Dict)
    println("sea128")
    println("jsonContent: ", jsonContent)
    return "ciphertext"
end

function xex(jsonContent::Dict)
    println("xex")
    println("jsonContent: ", jsonContent)
    return "ciphertext"
end

function gcm_encrypt(jsonContent::Dict)
    println("gcm_encrypt")
    println("jsonContent: ", jsonContent)
    return ("ciphertext", "234234234234324", "H", "MAC")
end

function gcm_decrypt(jsonContent::Dict)
    println("gcm_decrypt")
    println("jsonContent: ", jsonContent)
    return "plaintext"
end

function padding_oracle_chaggpt(jsonContent::Dict)
    println("padding_oracle_chaggpt")
    println("jsonContent: ", jsonContent)
    return "plaintext"
end


ACTIONS::Dict{String, Vector{Any}} = Dict(
    "add_numbers" => [add_numbers, ["sum"]],
    "subtract_numbers" => [subtract_numbers, ["difference"]],
    "poly2block" => [poly2block, ["block"]],
    "block2poly" => [block2poly, ["polynomial"]],
    "gfmul" => [gfmul, ["polynomial"]],
    "sea128" => [sea128, ["ciphertext"]],
    "xex" => [xex, ["ciphertext"]],
    "gcm_encrypt" => [gcm_encrypt, ["ciphertext", "asdf", "H", "MAC"]],
    "gcm_decrypt" => [gcm_decrypt, ["plaintext"]],
    "padding_oracle" => [padding_oracle_chaggpt, ["plaintext"]],
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

        result = ACTIONS[action][1](arguments)
        json_result = Dict()

        for (i, key) in enumerate(output_key)
            if isa(result, String)
                json_result[key] = result
            else
                json_result[key] = result[i]
            end
        end

        result_testcases[key] = json_result
    end

    println(JSON.json(result_testcases, 1))

end
end