#!/usr/local/bin/julia

using PackageCompiler


create_app(".", "Krypto",
    precompile_execution_file="./kauma",
    force=true,
    filter_stdlibs=true,
    cpu_target="native",
)

# julia --threads=auto --project=. kauma
