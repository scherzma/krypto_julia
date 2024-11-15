module PaddingOracle

using Sockets 
using Base: zeros


struct PaddingClient
    connection::TCPSocket
end

function PaddingClient(hostname::String, port::Int)
    client = connect(hostname, port)
    return PaddingClient(client)
end



function attack_block(client::PaddingClient, block::Array{UInt8})
    # write(client.connection, block)

    plaintext_block = zeros(UInt8, length(block))

    num_ivs::UInt16 = 8

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
                    previous_iv[17-ind] = plaintext_block[ind] ^ (16 - i)
                end
                iv = [z_array; counter; previous_iv]
                append!(ivs, iv)
            end

            write(client.connection, ivs)

            response = read(client.connection, num_ivs)


            for ind in eachindex(response)
                if response[ind] == 0x01
                    decrypted_byte::UInt8 = block[i] ^ (ind + j - 1) ^ (16 - i)
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
    client = PaddingClient(hostname, port)

    plaintext = Array{UInt8}(undef, 0)
    text = [iv; ciphertext]
    for i in length(text)-15:-16:16
        block = text[i:i+15]
        previous_block = text[i-16:i-1]
        write(client.connection, previous_block)
        append!(plaintext, attack_block(client, block))
    end

    return plaintext
end


end

