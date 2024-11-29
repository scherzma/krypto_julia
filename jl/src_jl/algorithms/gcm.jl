arr_to_int(arr::Array{UInt8}) = reinterpret(UInt128, reverse(arr))[1]
padl(len::Int) = (16 - (len % 16)) % 16 ## pad with zeros to the next multiple of 16
pad_array(arr::Array{UInt8}) = [arr; zeros(UInt8, padl(length(arr)))]

function ghash(key::Array{UInt8}, nonce::Array{UInt8}, text::Array{UInt8}, ad::Array{UInt8}, algorithm::String)

    enc_func = algorithm == "aes128" ? encrypt : encrypt_sea 
    auth_key = enc_func("aes128", key, zeros(UInt8, 16))
    println("auth_key: ", auth_key)
    println("auth_key: ", arr_to_int(auth_key))
    auth_key = FieldElement(arr_to_int(auth_key), GCM, false)
    println("auth_key: ", auth_key)

    len_block = vcat(
        reverse(reinterpret(UInt8, [length(ad) << 3])),
        reverse(reinterpret(UInt8, [length(text) << 3]))
    )
    println("len_block: ", len_block)
    
    Y = FieldElement(UInt128(0), GCM, false)
    data = [pad_array(ad); pad_array(text); len_block]

    println("data: ", data)
    for i in 1:16:(length(data) - 1)
        Y += data[i:i+15]
        println("Y: ", Y, " : ", i)
        Y *= auth_key
        println("Y*: ", Y, " : ", i)
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
        block = text[i:end_idx]
        enc_block = enc_i[1:length(block)]
        append!(result_text, block .⊻ enc_block)
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
