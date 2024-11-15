module PaddingOracle

using Sockets 
using Base: zeros
using Base64

struct PaddingClient
    connection::TCPSocket
end

function PaddingClient(hostname::String, port::Int)
    client = connect(hostname, port)
    return PaddingClient(client)
end

# testcase = {'action': 'padding_oracle', 'arguments': {'hostname': 'localhost', 'port': 18652, 'iv': 'hNKeqeiekkJtbzek09qvzw==', 'ciphertext': '/Kfr8O2bMljFI4T3miWJEOaQHu6fsT32dOMzsJnn2vfcGantLjof5SIa+aHV/aCxqx/ICMajeF/AI4e4t6F1ml+E2jwPpE/Dr+7Vn8pcZ9MnoHmyf5Y3d9PamfPxJPzX'}, 'expected': {'plaintext': 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk8=', 'key': 'H+sZ7nyDJAVRR6H8OgtqTQ=='}}


function attack_block(client::PaddingClient, block::Array{UInt8})
    client = PaddingClient(hostname, port)
    write(client.connection, block)  # Send the block to be decrypted
    
    plaintext_block = zeros(UInt8, length(block))

    num_ivs::UInt16 = 256

    for i in length(block):-1:1

        found_iv = false
        for j in 0:num_ivs:255
            write(client.connection, UInt8[num_ivs & 0xFF,num_ivs >> 8])
            ivs::Array{UInt8} = Array{UInt8}(undef, 0)

            for k::UInt16 in j:j+num_ivs - 1
                z_array::Array{UInt8} = zeros(UInt8, i - 1)
                counter::UInt8 = k

                previous_iv = Array{UInt8}(undef, 16 - i)
                for ind in 16:-1:i+1
                    previous_iv[17-ind] = plaintext_block[ind] ^ (17-  i)
                end
                iv = [z_array; counter; previous_iv]
                append!(ivs, iv)
            end

            write(client.connection, ivs)

            response = read(client.connection, num_ivs)


            for ind in eachindex(response)
                if response[ind] == 0x01
                    valid_padding = ind + j - 1
                    used_padding = (17 - i)
                    xi = valid_padding ^ used_padding

                    decrypted_byte::UInt8 = block[i] ^ xi
                    plaintext_block[i] = decrypted_byte
                    found_iv = true
                    break;
                end
            end

            if found_iv
                break;
            end
        end


        println(plaintext_block)
    end

    return plaintext_block
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

    return plaintext
end


plaintext = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk8="
iv = "hNKeqeiekkJtbzek09qvzw=="
ciphertext = "/Kfr8O2bMljFI4T3miWJEOaQHu6fsT32dOMzsJnn2vfcGantLjof5SIa+aHV/aCxqx/ICMajeF/AI4e4t6F1ml+E2jwPpE/Dr+7Vn8pcZ9MnoHmyf5Y3d9PamfPxJPzX"
clear_text = base64decode(plaintext)


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


padding_attack("0.0.0.0", 18652, base64decode(iv), base64decode(ciphertext))

end

