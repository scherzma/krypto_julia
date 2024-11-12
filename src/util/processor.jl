

module Processing
using JSON
using Base64
include("../math/galois.jl")
include("conversions.jl")
using .Galois: FieldElement
using .Conversions: base64_to_Nemo

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

    println("Block: ", block)
    println("Semantic: ", semantic)



    gf = FieldElement(base64_to_Nemo(block, semantic))

    result = gf.to_polynomial(semantic)
    println("Result: ", [Int(b) for b in result])
    return result
end

function gfmul(jsonContent::Dict)
    semantic::String = jsonContent["semantic"]
    a::String = jsonContent["a"]
    b::String = jsonContent["b"]

    a_ZZ = base64_to_Nemo(a, semantic)
    b_ZZ = base64_to_Nemo(b, semantic)

    println("a_ZZ: ", a_ZZ)
    println("b_ZZ: ", b_ZZ)

    gf_a = FieldElement(a_ZZ)
    gf_b = FieldElement(b_ZZ)

    product = gf_a * gf_b
    return (product).to_block(semantic)
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
    "block2poly" => [block2poly, ["coefficients"]],
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
            if length(ACTIONS[action][2]) == 1
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