using BenchmarkTools

@enum Semantic GCM XEX


# First implementation using if-else
@inline first(x::UInt128, ::Val{GCM}) = bitreverse(x)
@inline first(x::UInt128, ::Val{XEX}) = bswap(x)

# Alternative implementation using ternary operator
@inline function second(x::UInt128, semantic::Semantic)
    if semantic == GCM
        return bitreverse(x)
    elseif semantic == XEX
        return bswap(x)
    end
end

function run_benchmarks()
    # Quick correctness check
    test_val = rand(UInt128)
    @assert first(test_val, Val(GCM)) == second(test_val, GCM)
    @assert first(test_val, Val(XEX)) == second(test_val, XEX)

    # Large-scale performance test
    test_size = 100_000_000
    test_numbers = [rand(UInt128) for _ in 1:test_size]
    
    println("\nLarge-scale performance test with $test_size iterations:")

    println("\n1:")
    @btime for x in $test_numbers
        first(x, Val(GCM))
    end

    @btime for x in $test_numbers
        first(x, Val(XEX))
    end

    println("\n2:")
    @btime for x in $test_numbers
        second(x, XEX)
    end

    @btime for x in $test_numbers
        second(x, GCM)
    end

end

run_benchmarks()