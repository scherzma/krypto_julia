module Sea128

using Nettle: encrypt, decrypt

const SEA_CONST = Array{UInt8}([0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee, 0x11])

encrypt_sea(algorithm::String, key::Array{UInt8}, input::Array{UInt8}) = encrypt(algorithm, key, input) .⊻ SEA_CONST
decrypt_sea(algorithm::String, key::Array{UInt8}, input::Array{UInt8}) = decrypt(algorithm, key, input .⊻ SEA_CONST)

end