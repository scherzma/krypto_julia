module PaddingOracle

using Sockets 
using Base: zeros
using Base64
using Nettle

struct PaddingClient
    connection::TCPSocket
end

function PaddingClient(hostname::String, port::Int)
    client = connect(hostname, port)
    return PaddingClient(client)
end

function attack_block(hostname::String, port::Int, block::Array{UInt8}, previous_block::Array{UInt8})
    client = PaddingClient(hostname, port)
    write(client.connection, block)  # Send the block to be decrypted
    
    plaintext_block = zeros(UInt8, length(block))
    num_ivs::UInt16 = 128
    x_values = UInt8[]

    for current_byte in length(block):-1:1

        known_iv = zeros(UInt8, 16 - current_byte)
        for i in 1:16-current_byte
            known_iv[i] = x_values[i] ⊻ (17 - current_byte)
        end
        z_array::Array{UInt8} = zeros(UInt8, current_byte - 1)


        found_iv = false
        for current_iv_block in 0:num_ivs:255
            write(client.connection, UInt8[num_ivs & 0xFF,num_ivs >> 8])

            ivs = zeros(UInt8, num_ivs << 4)
            @inbounds for (block_iv_num, total_iv_num) in enumerate((current_iv_block:current_iv_block+num_ivs-1))
                #=
                This loop is a bit shitty. The ivs array could be created on the very top
                and always just changed a bit. But this is easier.
                =#
                base_idx = (block_iv_num-1) << 4 + 1
                ivs[base_idx+length(z_array)] = UInt8(total_iv_num)
                ivs[base_idx+length(z_array)+1 : base_idx+15] .= known_iv
            end

            write(client.connection, ivs)
            response = read(client.connection, num_ivs)

            for response_ind in eachindex(response)
                if response[response_ind] == 0x01
                    valid_padding_at = response_ind + current_iv_block - 1
                    result_padding = (17 - current_byte)
                    xi = valid_padding_at ⊻ result_padding
                    pushfirst!(x_values, xi)

                    decrypted_byte::UInt8 = previous_block[current_byte] ⊻ xi
                    plaintext_block[current_byte] = decrypted_byte
                    found_iv = true
                    break;
                end
            end

            if found_iv
                break;
            end
        end

    end

    close(client.connection)
    return plaintext_block
end

function de_pad(plaintext::Array{UInt8})
    return plaintext[1:end-plaintext[end]]
end


function padding_attack(hostname::String, port::Int, iv::Array{UInt8}, ciphertext::Array{UInt8})
    plaintext = Array{UInt8}(undef, 0)
    text = [iv; ciphertext]

    for i in 16:16:length(text)-16
        block_to_decrypt = text[i+1:i+16]
        previous_block = text[i-15:i]
        decrypted_block = attack_block(hostname, port, block_to_decrypt, previous_block)
        append!(plaintext, decrypted_block)
    end

    return de_pad(plaintext)
end



end

#=
iv = base64decode("AAECAwQFBgcICQoLDA0ODw==")
println("iv: ", iv)
ciphertext = base64decode("qMMTOpg/u2Woj5jhLFVl4PT+wBAyagheULVfdI8FQsU=")

key = base64decode("8PHy8/T19vf4+fr7/P3+/w==")
println("key: ", key)


plaintext = UInt8['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P']
padding = UInt8[0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10]

padded_plaintext = [plaintext; padding]
println("length(padded_plaintext): ", length(padded_plaintext))
println("padded_plaintext: ", padded_plaintext)

xor = iv .⊻ padded_plaintext[1:16]
block1 = encrypt("aes128", key, xor)

xor = padded_plaintext[17:32] .⊻ block1
block2 = encrypt("aes128", key, xor)

ciphertext_self = [block1; block2]

println("ciphertext_self: ", ciphertext_self)

println(length(iv))
println(length(ciphertext))
println("iv: ", iv)
println("ciphertext: ", ciphertext)



x = padding_attack("0.0.0.0", 18652, iv, ciphertext)
println("x: ", x)

=#










#plaintext = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk8="
#iv = "hNKeqeiekkJtbzek09qvzw=="
#ciphertext = "/Kfr8O2bMljFI4T3miWJEOaQHu6fsT32dOMzsJnn2vfcGantLjof5SIa+aHV/aCxqx/ICMajeF/AI4e4t6F1ml+E2jwPpE/Dr+7Vn8pcZ9MnoHmyf5Y3d9PamfPxJPzX"
#clear_text = base64decode(plaintext)


# fca7ebf0ed9b3258c52384f79a258910
# e6901eee9fb13df674e333b099e7daf7
# dc19a9ed2e3a1fe5221af9a1d5fda0b1
# ab1fc808c6a3785fc02387b8b7a1759a
# 5f84da3c0fa44fc3afeed59fca5c67d3
# 27a079b27f963777d3da99f3f124fcd7

# X1 = 0x70 = 112


# IV 84d29ea9e89e92426d6f37a4d3daafcf
# 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 
# 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 
# 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 
# 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 
# 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f

