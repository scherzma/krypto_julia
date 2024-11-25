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
    num_ivs::UInt16 = 256
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





