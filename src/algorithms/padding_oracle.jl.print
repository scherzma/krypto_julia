module PaddingOracle

using Sockets 
using Base: zeros
using Base64
using Nettle

struct PaddingClient
    connection::TCPSocket
end

function PaddingClient(hostname::String, port::Int)
    println("[PaddingClient] Attempting to connect to $hostname on port $port")
    client = connect(hostname, port)
    println("[PaddingClient] Connection established: $client")
    return PaddingClient(client)
end

function attack_block(hostname::String, port::Int, block::Array{UInt8}, previous_block::Array{UInt8})
    println("[attack_block] Starting attack_block with block: $(bytestring(block)) and previous_block: $(bytestring(previous_block))")
    client = PaddingClient(hostname, port)
    println("[attack_block] Sending block to be decrypted: $(bytestring(block))")
    write(client.connection, block)  # Send the block to be decrypted
    println("[attack_block] Block sent successfully")

    plaintext_block = zeros(UInt8, length(block))
    println("[attack_block] Initialized plaintext_block with zeros: $plaintext_block")
    
    num_ivs::UInt16 = 256
    println("[attack_block] Number of IVs set to: $num_ivs")
    
    x_values = UInt8[]
    println("[attack_block] Initialized x_values as empty array")

    for current_byte in length(block):-1:1
        println("[attack_block] Processing byte position: $current_byte")
        
        known_iv = zeros(UInt8, 16 - current_byte)
        println("[attack_block] Initialized known_iv with zeros: $known_iv")
        
        for i in 1:16-current_byte
            known_iv[i] = x_values[i] ⊻ (17 - current_byte)
            println("[attack_block] Updated known_iv[$i] to: $(known_iv[i])")
        end
        println("[attack_block] Final known_iv: $known_iv")
        
        z_array::Array{UInt8} = zeros(UInt8, current_byte - 1)
        println("[attack_block] Initialized z_array with zeros: $z_array")

        found_iv = false
        println("[attack_block] Starting IV search loop")
        
        for current_iv_block in 0:num_ivs:255
            println("[attack_block] Trying IV block range: $current_iv_block to $(current_iv_block + num_ivs - 1)")
            write(client.connection, UInt8[num_ivs & 0xFF, num_ivs >> 8])
            println("[attack_block] Sent IV count to server: $(UInt8[num_ivs & 0xFF, num_ivs >> 8])")

            ivs = zeros(UInt8, num_ivs << 4)
            println("[attack_block] Initialized IVs array with zeros: Length = $(length(ivs))")
            
            @inbounds for (block_iv_num, total_iv_num) in enumerate(current_iv_block:(current_iv_block + num_ivs - 1))
                #=
                This loop is a bit shitty. The ivs array could be created on the very top
                and always just changed a bit. But this is easier.
                =#
                base_idx = ((block_iv_num - 1) << 4) + 1
                ivs[base_idx + length(z_array)] = UInt8(total_iv_num)
                println("[attack_block] Set ivs[$(base_idx + length(z_array))] to: $(UInt8(total_iv_num))")
                
                ivs[(base_idx + length(z_array) + 1):(base_idx + 15)] .= known_iv
                println("[attack_block] Updated ivs[$(base_idx + length(z_array) + 1)) : $(base_idx + 15)] with known_iv: $known_iv")
            end
            println("[attack_block] Completed IVs setup for current IV block")

            write(client.connection, ivs)
            println("[attack_block] Sent IVs to server: $(bytestring(ivs))")
            
            response = read(client.connection, num_ivs)
            println("[attack_block] Received response from server: $(bytestring(response))")

            for response_ind in eachindex(response)
                println("[attack_block] Checking response[$response_ind]: $(response[response_ind])")
                if response[response_ind] == 0x01
                    println("[attack_block] Valid padding found at response index: $response_ind")
                    valid_padding_at = response_ind + current_iv_block - 1
                    println("[attack_block] Calculated valid_padding_at: $valid_padding_at")
                    
                    result_padding = (17 - current_byte)
                    println("[attack_block] Calculated result_padding: $result_padding")
                    
                    xi = valid_padding_at ⊻ result_padding
                    println("[attack_block] Calculated xi: $xi")
                    
                    pushfirst!(x_values, xi)
                    println("[attack_block] Updated x_values: $x_values")
                    
                    decrypted_byte::UInt8 = previous_block[current_byte] ⊻ xi
                    plaintext_block[current_byte] = decrypted_byte
                    println("[attack_block] Decrypted byte at position $current_byte: $decrypted_byte")
                    
                    found_iv = true
                    println("[attack_block] Found valid IV, breaking out of response loop")
                    break
                else
                    println("[attack_block] Invalid padding at response index: $response_ind")
                end
            end

            if found_iv
                println("[attack_block] IV found, breaking out of IV search loop")
                break
            else
                println("[attack_block] IV not found in current block, continuing search")
            end
        end

        println("[attack_block] Completed processing for byte position: $current_byte")
    end

    println("[attack_block] Closing client connection")
    close(client.connection)
    println("[attack_block] Connection closed")

    println("[attack_block] Returning decrypted plaintext block: $plaintext_block")
    return plaintext_block
end

function de_pad(plaintext::Array{UInt8})
    println("[de_pad] Original plaintext: $(bytestring(plaintext))")
    padding_length = plaintext[end]
    println("[de_pad] Detected padding length: $padding_length")
    de_padded = plaintext[1:end - padding_length]
    println("[de_pad] De-padded plaintext: $(bytestring(de_padded))")
    return de_padded
end

function padding_attack(hostname::String, port::Int, iv::Array{UInt8}, ciphertext::Array{UInt8})
    println("[padding_attack] Starting padding_attack with hostname: $hostname, port: $port")
    println("[padding_attack] IV: $(bytestring(iv))")
    println("[padding_attack] Ciphertext: $(bytestring(ciphertext))")
    
    plaintext = Array{UInt8}(undef, 0)
    println("[padding_attack] Initialized plaintext as empty array")
    
    text = [iv; ciphertext]
    println("[padding_attack] Combined IV and ciphertext into text: $(bytestring(text))")

    for i in 16:16:length(text)-16
        println("[padding_attack] Processing block index: $i")
        block_to_decrypt = text[i+1:i+16]
        previous_block = text[i-15:i]
        println("[padding_attack] Block to decrypt: $(bytestring(block_to_decrypt))")
        println("[padding_attack] Previous block: $(bytestring(previous_block))")
        
        decrypted_block = attack_block(hostname, port, block_to_decrypt, previous_block)
        println("[padding_attack] Decrypted block: $(bytestring(decrypted_block))")
        
        append!(plaintext, decrypted_block)
        println("[padding_attack] Appended decrypted block to plaintext: $(bytestring(plaintext))")
    end

    println("[padding_attack] Completed all blocks, starting de-padding")
    final_plaintext = de_pad(plaintext)
    println("[padding_attack] Final plaintext after de-padding: $(bytestring(final_plaintext))")
    
    return final_plaintext
end

end
