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
    #result = padding_attack(hostname, port, iv, ciphertext)
    #return base64encode(result)
    return "test"
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
    result = poly_A / poly_B
    return result[1].repr(), result[2].repr()
end

function polynomial_powmod(jsonContent::Dict)
    A::Array{String} = jsonContent["A"]
    M::Array{String} = jsonContent["M"]
    k::Int = jsonContent["k"]

    poly_A = Polynomial(A)
    poly_M = Polynomial(M)

    return gfpoly_powmod(poly_A, poly_M, k).repr()
end

function polynomial_sort(jsonContent::Dict)
    polys_str::Array{Array{String}} = jsonContent["polys"]
    polys = [Polynomial(poly) for poly in polys_str]
    sorted_polys = sort(polys)
    return [poly.repr() for poly in sorted_polys]
end

function polynomial_make_monic(jsonContent::Dict)
    A::Array{String} = jsonContent["A"]
    poly_A = Polynomial(A)
    return poly_A.monic().repr()
end

function polynomial_sqrt(jsonContent::Dict)
    Q::Array{String} = jsonContent["Q"]
    poly_Q = Polynomial(Q)
    return (√poly_Q).repr()
end

function polynomial_diff(jsonContent::Dict)
    F::Array{String} = jsonContent["F"]
    poly_F = Polynomial(F)
    return poly_F.diff().repr()
end

function polynomial_gcd(jsonContent::Dict)
    A::Array{String} = jsonContent["A"]
    B::Array{String} = jsonContent["B"]
    poly_A = Polynomial(A)
    poly_B = Polynomial(B)
    ans = poly_A.gcd(poly_B)
    return ans.repr()
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
    "gfpoly_powmod" => [polynomial_powmod, ["Z"]],
    "gfpoly_sort" => [polynomial_sort, ["sorted_polys"]],
    "gfpoly_make_monic" => [polynomial_make_monic, ["A*"]],
    "gfpoly_sqrt" => [polynomial_sqrt, ["S"]],
    "gfpoly_diff" => [polynomial_diff, ["F'"]],
    "gfpoly_gcd" => [polynomial_gcd, ["G"]],
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
        #println("Processing $action >>> ")
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