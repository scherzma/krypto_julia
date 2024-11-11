

module Processing
using JSON

function add_numbers(jsonContent::Dict)
    return jsonContent["number1"] + jsonContent["number2"]
end

function subtract_numbers(jsonContent::Dict)
    return jsonContent["number1"] - jsonContent["number2"]
end

function poly2block(jsonContent::Dict)
    println("poly2block")
    println("jsonContent: ", jsonContent)
    return "block"
end

function block2poly(jsonContent::Dict)
    println("block2poly")
    println("jsonContent: ", jsonContent)
    return "polynomial"
end

function gfmul(jsonContent::Dict)
    println("gfmul")
    println("jsonContent: ", jsonContent)
    return "polynomial"
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
    "poly2block" => [poly2block, ["polynomial"]],
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
            json_result[key] = result[i]
        end

        result_testcases[key] = json_result
    end

    println(JSON.json(result_testcases))

end
end