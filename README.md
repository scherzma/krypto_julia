# Krypto Julia

A cryptographic toolkit implementing various encryption algorithms and Galois field operations in Julia.

## Installation

```julia
using Pkg
Pkg.add("JSON")
Pkg.add("Nettle")
Pkg.add("BenchmarkTools")  # Only needed for running tests
```

## Usage

Run the program with:
```bash
julia --threads=auto --project=. kauma [input_file]
```

The program accepts JSON input files. If no input file is specified, it uses `./sample.json` by default.

See `sample.json` and `sample_small.json` for example inputs.
