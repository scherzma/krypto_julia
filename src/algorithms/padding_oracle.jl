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


function padding_attack(hostname::String, port::Int, iv::Array{UInt8}, ciphertext::Array{UInt8})
    return "plaintext"
end


end

