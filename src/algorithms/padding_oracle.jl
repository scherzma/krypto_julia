module PaddingOracle

using Sockets 


struct PaddingClient
    connection::TCPSocket
end

function PaddingClient(hostname::String, port::Int)
    client = connect(hostname, port)
    return PaddingClient(client)
end



function send_to_server(a::PaddingClient, data::Array{UInt8})
    write(a.connection, data)
end


function generate_ivs(padding_length::Int, decrypted_bytes::Array{UInt8}, original_iv::Array{UInt8}=zeros(UInt8, 16))
    ivs = UInt8[]  # Initialize an empty array to hold the concatenated IVs

    for i in 0:255
        # Copy the original IV to modify it for each attempt
        iv = copy(original_iv)

        # Adjust the known decrypted bytes to conform to the current padding length
        for j in 1:(padding_length - 1)
            position = 16 - (j - 1)
            iv[position] = iv[position] ⊻ decrypted_bytes[end - (j - 1)] ⊻ UInt8(padding_length)
        end

        # Modify the byte we're currently attacking
        position = 16 - (padding_length - 1)
        iv[position] = iv[position] ⊻ UInt8(i) ⊻ UInt8(padding_length)

        # Append the modified IV to the list
        append!(ivs, iv)
    end

    return ivs
end


function attack_block(client::PaddingClient, block::Array{UInt8})
    write(client.connection, block)

    dec_block = Array{UInt8}(undef, 0)

    num_ivs::UInt8 = 255

    for i in 1:length(block)
        write(client.connection, UInt8[num_ivs,00])
        ivs = generate_ivs(num_ivs, dec_block)
        println(ivs)
        write(client.connection, ivs)
    end

    return dec_block
end


function padding_attack(hostname::String, port::Int, iv::Array{UInt8}, ciphertext::Array{UInt8})
    client = PaddingClient(hostname, port)

    plaintext = Array{UInt8}(undef, 0)

    for i in 1:16:length(ciphertext)
        block = ciphertext[i:i+15]
        append!(plaintext, attack_block(client, block))
    end

    return plaintext
end


end

