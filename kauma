#!/usr/local/bin/julia

using JSON
#using PackageCompiler

include("src/Krypto.jl")
using .Krypto: process

function main()
    file::String = "./sample.json"

    if length(ARGS) == 1
        file = ARGS[1]
    end
    
    jsonContent = JSON.parsefile(file)
    process(jsonContent)
end



main()


#create_app(".", "Krypto",
#    precompile_execution_file="./kauma",
#    force=true,
#    filter_stdlibs=true,
#    cpu_target="native",
#)

# julia --threads=auto --project=. kauma
