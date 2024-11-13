module Sea128

using Nettle

const SEA_CONST = Array{UInt8}([0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee, 0x11])

function encrypt_sea(key::Array{UInt8}, input::Array{UInt8})
    return encrypt("AES128", key, input) .⊻ SEA_CONST
end

function encrypt_sea(algorithm::String, key::Array{UInt8}, input::Array{UInt8})
    return encrypt(algorithm, key, input) .⊻ SEA_CONST
end

function decrypt_sea(key::Array{UInt8}, input::Array{UInt8})
    return decrypt("AES128", key, input .⊻ SEA_CONST)
end

function decrypt_sea(algorithm::String, key::Array{UInt8}, input::Array{UInt8})
    return decrypt(algorithm, key, input .⊻ SEA_CONST)
end

end