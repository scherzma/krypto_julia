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


function generate_ivs(num_ivs::UInt8, plaintext::Array{UInt8})
    block_size = 16
        ivs = Array{UInt8}(undef, num_ivs * block_size)
    
    for i in 0:num_ivs-1
        block = zeros(UInt8, block_size)
        counter_bytes = reinterpret(UInt8, [UInt32(i)])
        start_idx = block_size - length(counter_bytes) + 1
        block[1:start_idx-1] .= 0x00  # Pad with zeros
        block[start_idx:end] .= counter_bytes
        start_pos = (i * block_size) + 1
        ivs[start_pos:start_pos+block_size-1] = block
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

