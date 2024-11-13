module FDE

include("sea128.jl")
using .Sea128: encrypt_sea, decrypt_sea
using Base64


function mul_alpha!(tweak::Vector{UInt8})
    carry = (tweak[16] & 0x80) != 0
    for i in 16:-1:2
        tweak[i] = ((tweak[i] << 1) & 0xFF) | (tweak[i-1] >> 7)
    end
    tweak[1] = ((tweak[1] << 1) & 0xFF)
    tweak[1] = tweak[1] ⊻ (carry ? 0x87 : 0x00)
end


function crypt_fde(key::Array{UInt8}, tweak::Array{UInt8}, input::Array{UInt8}, mode::String)
    k1, k2 = key[1:16], key[17:32]

    tweak = encrypt_sea(k2, tweak)
    text = Array{UInt8}(undef, 0)
    crypt_function = mode == "encrypt" ? encrypt_sea : decrypt_sea

    for i in 1:16:length(input)
        block = input[i:i+15] .⊻ tweak
        append!(text, (crypt_function(k1, block) .⊻ tweak)) 
        mul_alpha!(tweak)
    end
    return text
end

function encrypt_fde(key::Array{UInt8}, tweak::Array{UInt8}, input::Array{UInt8})
    return crypt_fde(key, tweak, input, "encrypt")
end

function decrypt_fde(key::Array{UInt8}, tweak::Array{UInt8}, input::Array{UInt8})
    return crypt_fde(key, tweak, input, "decrypt")
end

end