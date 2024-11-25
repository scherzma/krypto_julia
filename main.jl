include("src/util/processor.jl")
using .Processing: process
using JSON

# Main function
function main(file::String="./sample.json")

    if length(ARGS) == 1
        file = ARGS[1]
    end
    
    jsonContent = JSON.parsefile(file)
    return process(jsonContent)
end