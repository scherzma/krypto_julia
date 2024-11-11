

function process(jsonContent::Dict)
    test()
    println(jsonContent)


    actions::Dict{String, Function} = {
        "add_numbers" => add_numbers,
        "subtract_numbers" => subtract_numbers,
        "poly2block" => poly2block,
        "block2poly" => block2poly,
        "gfmul" => gfmul,
        "sea128" => sea128,
        "xex" => xex,
        "gcm_encrypt" => gcm_encrypt,
        "gcm_decrypt" => gcm_decrypt,
        "padding_oracle" => padding_oracle_chaggpt # padding_oracle,
    }
end


function test()
    println("Hello, world!")
end