
module GCM

include("sea128.jl")
include("../math/galois.jl")

using Nettle
using Base64
using .Sea128: encrypt_sea, decrypt_sea
using .Galois: FieldElement


function ghash(key::Array{UInt8}, nonce::Array{UInt8}, text::Array{UInt8}, ad::Array{UInt8}, algorithm::String)

    enc_func = algorithm == "aes128" ? encrypt : encrypt_sea 
    auth_key = enc_func("aes128", key, zeros(UInt8, 16))

    len_block = vcat(
        reverse(reinterpret(UInt8, [length(ad) << 3])),
        reverse(reinterpret(UInt8, [length(text) << 3]))
    )

    ad_pad_bytes = [ad; zeros(UInt8, (16 - length(ad) % 16))]
    text_pad_bytes = [text; zeros(UInt8, (16 - length(text) % 16))]

    ad_pad_int = (reinterpret(UInt128, ad_pad_bytes))[1]
    ad_pad_gf = FieldElement(ad_pad_int, "gcm")
    auth_key_gf = FieldElement(auth_key, "gcm")

    ad_pad_gf *= auth_key_gf

    for i in 1:16:(length(text_pad_bytes) - 1)
        ad_pad_gf +=  text_pad_bytes[i:i+15]
        ad_pad_gf *=  auth_key_gf
    end

    ad_pad_gf += len_block
    ad_pad_gf *= auth_key_gf

    return ad_pad_gf + enc_func("AES128", key, [nonce; UInt8[0,0,0,1]])

end


function crypt_gcm(key::Array{UInt8}, text::Array{UInt8}, ad::Array{UInt8}, nonce::Array{UInt8}, algorithm::String)

    result_text = Array{UInt8}(undef, 0)
    enc_func = algorithm == "aes128" ? encrypt : encrypt_sea

    for i in 1:16:length(text)
        temp_nonce = [nonce; reverse!(reinterpret(UInt8, [UInt32(i+1)]))]
        enc_i = enc_func("AES128", key, temp_nonce)
        append!(result_text, text[i:i+15] .⊻ enc_i)
    end

    return result_text
end



function decrypt_gcm(key::Array{UInt8}, ciphertext::Array{UInt8}, ad::Array{UInt8}, nonce::Array{UInt8}, algorithm::String)
    plaintext = decrypt("AES128", key, ciphertext)
    return plaintext
end


function encrypt_gcm(key::Array{UInt8}, plaintext::Array{UInt8}, ad::Array{UInt8}, nonce::Array{UInt8}, algorithm::String)
    ciphertext = crypt_gcm(key, plaintext, ad, nonce, algorithm)
    return ciphertext
end




key = base64decode("Xjq/GkpTSWoe3ZH0F+tjrQ==")
text = base64decode("RGFzIGlzdCBlaW4gVGVzdA==")
ad = base64decode("QUQtRGF0ZW4=")
nonce = base64decode("4gF+BtR3ku/PUQci")
algorithm = "aes128"

println(nonce)

text = crypt_gcm(key, text, ad, nonce, algorithm)
println(text)
println(base64encode(text))

auth_tag = ghash(key, nonce, text, ad, algorithm)
println(auth_tag)


end