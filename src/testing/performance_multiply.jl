using BenchmarkTools

# Constants
const GF128_MODULUS = UInt128(0x87)  # Standard GF(2^128) modulus

# Original struct definition modified to use only UInt128
struct FieldElement_quick
    value::UInt128
    semantic::Symbol  # Using Symbol instead of String for better performance
    reduced::Bool
end

# Original multiplication function
@inline function mult_original(a::FieldElement_quick, b::FieldElement_quick)
    aggregate = UInt128(0)
    tmp_a::UInt128 = a.value
    tmp_b::UInt128 = b.value
    
    if (tmp_b & UInt128(1)) == 1
        aggregate ⊻= tmp_a
    end
    
    @inbounds for _ in 1:16  # 128/8 = 16 iterations
        for _ in 1:8
            prev_high_bit = tmp_a >> 127
            tmp_a <<= UInt128(1)
            tmp_a ⊻= GF128_MODULUS * prev_high_bit

            tmp_b >>= 1
            aggregate ⊻= tmp_a * (tmp_b & UInt128(1))
        end
    end
    
    return FieldElement_quick(aggregate, a.semantic, true)
end


# SIMD-optimized version (experimental)
@inline function mult_safe(a::FieldElement_quick, b::FieldElement_quick)
    aggregate = UInt128(0)
    tmp_a = a.value
    tmp_b = b.value


    if (tmp_b & UInt128(1)) == 1
        aggregate ⊻= tmp_a
    end

    prev_high_bit = UInt128(0)

    @inbounds for i in 1:128
        prev_high_bit = (tmp_a & (UInt128(1) << 127)) != 0
        tmp_a <<= UInt128(1)
        
        if prev_high_bit
            tmp_a ⊻= GF128_MODULUS
        end
        
        if (tmp_b >> i) & UInt128(1) == 1
            aggregate ⊻= tmp_a
        end

    end
    
    return FieldElement_quick(aggregate, a.semantic, true)
end








# Benchmark setup
function run_benchmarks()
    # Generate random test values
    test_a = FieldElement_quick(rand(UInt128), :xex, true)
    test_b = FieldElement_quick(rand(UInt128), :xex, true)
    
    # Verify correctness
    result_original = mult_original(test_a, test_b)
    result_simd = mult_safe(test_a, test_b)
    
    @assert result_original.value == result_simd.value "SIMD version produces different results!"

        
    println("\nSafe implementation:")
    @btime mult_safe($(test_a), $(test_b))


    println("Original implementation:")
    @btime mult_original($(test_a), $(test_b))

    
    # Additional stress test
    stress_test_size = 10000
    test_data = [(FieldElement_quick(rand(UInt128), :gcm, true), 
                  FieldElement_quick(rand(UInt128), :gcm, true)) 
                 for _ in 1:stress_test_size]
    
    println("\nStress test with $stress_test_size random pairs:")
    println("Original:")
    @btime for (a, b) in $test_data
        mult_original(a, b)
    end

    
    println("\nSafe:")
    @btime for (a, b) in $test_data
        mult_safe(a, b)
    end
end

# Run the benchmarks
run_benchmarks()