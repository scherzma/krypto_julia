include("src/util/processor.jl")
using .Processing: process
using JSON

# Main function to process the JSON file
function main(file::String="./sample.json")

    if length(ARGS) == 1
        file = ARGS[1]
    end
    
    jsonContent = JSON.parsefile(file)
    return process(jsonContent)
end