
module GCM


include("../util/semantic_types.jl")
using .SemanticTypes

include("sea128.jl")
include("../math/galois_fast.jl")
using Nettle
using Base64
using .Sea128: encrypt_sea, decrypt_sea
using .Galois_quick: FieldElement


arr_to_int(arr::Array{UInt8}) = reinterpret(UInt128, reverse(arr))[1]
padl(len::Int) = (16 - (len % 16)) % 16 ## pad with zeros to the next multiple of 16
pad_array(arr::Array{UInt8}) = [arr; zeros(UInt8, padl(length(arr)))]

function ghash(key::Array{UInt8}, nonce::Array{UInt8}, text::Array{UInt8}, ad::Array{UInt8}, algorithm::String)

    enc_func = algorithm == "aes128" ? encrypt : encrypt_sea 
    auth_key = enc_func("aes128", key, zeros(UInt8, 16))
    auth_key = FieldElement(arr_to_int(auth_key), SemanticTypes.GCM)

    len_block = vcat(
        reverse(reinterpret(UInt8, [length(ad) << 3])),
        reverse(reinterpret(UInt8, [length(text) << 3]))
    )
    
    Y = FieldElement(UInt128(0), SemanticTypes.GCM)
    data = [pad_array(ad); pad_array(text); len_block]

    for i in 1:16:(length(data) - 1)
        Y += data[i:i+15]
        Y *= auth_key
    end

    tag = Y + enc_func("AES128", key, [nonce; UInt8[0,0,0,1]])

    return tag, len_block, auth_key
end


function crypt_gcm(key::Array{UInt8}, text::Array{UInt8}, nonce::Array{UInt8}, algorithm::String)

    result_text = Array{UInt8}(undef, 0)
    enc_func = algorithm == "aes128" ? encrypt : encrypt_sea


    counter = 2
    for i in 1:16:(length(text))
        temp_nonce = [nonce; reverse!(reinterpret(UInt8, [UInt32(counter)]))]
        enc_i = enc_func("AES128", key, temp_nonce)
        end_idx = min(i+15, length(text))
        enc_block = enc_i[1:length(block)]
        append!(result_text, text[i:end_idx] .⊻ enc_block)
        counter += 1
    end

    return result_text
end

function decrypt_gcm(key::Array{UInt8}, ciphertext::Array{UInt8}, ad::Array{UInt8}, nonce::Array{UInt8}, algorithm::String)
    auth_tag = ghash(key, nonce, ciphertext, ad, algorithm)
    plaintext = crypt_gcm(key, ciphertext, nonce, algorithm)
    return plaintext, auth_tag[1], auth_tag[2], auth_tag[3]
end


function encrypt_gcm(key::Array{UInt8}, plaintext::Array{UInt8}, ad::Array{UInt8}, nonce::Array{UInt8}, algorithm::String)
    ciphertext = crypt_gcm(key, plaintext, nonce, algorithm)
    auth_tag = ghash(key, nonce, ciphertext, ad, algorithm)
    return ciphertext, auth_tag[1], auth_tag[2], auth_tag[3]
end


end

