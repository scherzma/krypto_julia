#!/usr/local/bin/julia

using PackageCompiler


create_app(".", "Krypto",
    precompile_execution_file="./kauma.jl",
    cpu_target="native",
    force=true,
)

# julia --threads=auto --project=. kauma
