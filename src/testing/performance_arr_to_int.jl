using BenchmarkTools

# Original function
@inline function uint8_to_uint128_original(bytes::Vector{UInt8})::UInt128
    # length(bytes) == 16 || throw(ArgumentError("Input must be exactly 16 bytes")) # This should really be checked, but it's a tiny bit slower
    @inbounds begin
        result = (UInt128(bytes[1]) << 120) | (UInt128(bytes[2]) << 112) | 
                 (UInt128(bytes[3]) << 104) | (UInt128(bytes[4]) << 96) |
                 (UInt128(bytes[5]) << 88)  | (UInt128(bytes[6]) << 80) | 
                 (UInt128(bytes[7]) << 72)  | (UInt128(bytes[8]) << 64) |
                 (UInt128(bytes[9]) << 56)  | (UInt128(bytes[10]) << 48) | 
                 (UInt128(bytes[11]) << 40) | (UInt128(bytes[12]) << 32) |
                 (UInt128(bytes[13]) << 24) | (UInt128(bytes[14]) << 16) | 
                 (UInt128(bytes[15]) << 8)  | UInt128(bytes[16])
    end
    return result
end

# Alternative implementation using folding
@inline function uint8_to_uint128_folded(bytes::Vector{UInt8})::UInt128
    @inbounds begin
        # Split into 4 parts for better pipelining
        upper = (UInt128(bytes[1]) << 120) | (UInt128(bytes[2]) << 112) | 
                (UInt128(bytes[3]) << 104) | (UInt128(bytes[4]) << 96)
        
        upper_mid = (UInt128(bytes[5]) << 88) | (UInt128(bytes[6]) << 80) | 
                    (UInt128(bytes[7]) << 72) | (UInt128(bytes[8]) << 64)
        
        lower_mid = (UInt128(bytes[9]) << 56) | (UInt128(bytes[10]) << 48) | 
                    (UInt128(bytes[11]) << 40) | (UInt128(bytes[12]) << 32)
        
        lower = (UInt128(bytes[13]) << 24) | (UInt128(bytes[14]) << 16) | 
                (UInt128(bytes[15]) << 8) | UInt128(bytes[16])

        # Combine the parts
        result = upper | upper_mid | lower_mid | lower
    end
    return result
end

# Benchmark setup
function run_benchmarks()
    # Generate random test data
    test_bytes = rand(UInt8, 16)
    
    # Verify correctness
    result_original = uint8_to_uint128_original(test_bytes)
    result_folded = uint8_to_uint128_folded(test_bytes)
    @assert result_original == result_folded "Implementations produce different results!"

    println("\nOriginal implementation:")
    @btime uint8_to_uint128_original($(test_bytes))
    
    println("\nFolded implementation:")
    @btime uint8_to_uint128_folded($(test_bytes))

    # Stress test
    stress_test_size = 10000
    test_data = [rand(UInt8, 16) for _ in 1:stress_test_size]
    
    println("\nStress test with $stress_test_size random byte arrays:")
    println("Original:")
    @btime for bytes in $test_data
        uint8_to_uint128_original(bytes)
    end

    println("\nFolded:")
    @btime for bytes in $test_data
        uint8_to_uint128_folded(bytes)
    end
end

# Run the benchmarks
run_benchmarks()