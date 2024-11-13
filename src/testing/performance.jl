using BenchmarkTools

# Original function
function int_to_semantic(x::UInt128, semantic::String)
    value::UInt128 = 0
    if semantic == "gcm"
        x = (x << 64) | (x >> 64)                           # Swap 64-bit halves
        x = ((x << 32) & 0xFFFFFFFF00000000FFFFFFFF00000000) | ((x >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF)
        x = ((x << 16) & 0xFFFF0000FFFF0000FFFF0000FFFF0000) | ((x >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF)
        x = ((x << 8)  & 0xFF00FF00FF00FF00FF00FF00FF00FF00) | ((x >> 8)  & 0x00FF00FF00FF00FF00FF00FF00FF00FF)
        x = ((x << 4)  & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0) | ((x >> 4)  & 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F)
        x = ((x << 2)  & 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC) | ((x >> 2)  & 0x3333333333333333333333333333333333)
        x = ((x << 1)  & 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA) | ((x >> 1)  & 0x5555555555555555555555555555555555)
        value = x
    elseif semantic == "xex"
        x = (x << 64) | (x >> 64)                           # Swap 64-bit halves
        x = ((x << 32) & 0xFFFFFFFF00000000FFFFFFFF00000000) | ((x >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF)
        x = ((x << 16) & 0xFFFF0000FFFF0000FFFF0000FFFF0000) | ((x >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF)
        x = ((x << 8)  & 0xFF00FF00FF00FF00FF00FF00FF00FF00) | ((x >> 8)  & 0x00FF00FF00FF00FF00FF00FF00FF00FF)
        value = x
    else
        throw(ArgumentError("Unknown semantic: $semantic"))
    end

    return value
end

@enum Semantic GCM XEX
# XEX case - just byte reversal
function int_to_semantic(x::UInt128, ::Val{:xex})
    return bswap(x)
end

# GCM case - bit reversal 
function int_to_semantic(x::UInt128, ::Val{:gcm})
    return bitreverse(x)
end

# Wrapper function for backward compatibility if needed
function int_to_semantic(x::UInt128, semantic::String)
    if semantic == "gcm"
        return int_to_semantic(x, Val(:gcm))
    elseif semantic == "xex"
        return int_to_semantic(x, Val(:xex))
    else
        throw(ArgumentError("Unknown semantic: $semantic"))
    end
end


test_bytes = rand(UInt128, 1000)

# Original function
func1(x) = int_to_semantic(x, "gcm")
func1_xex(x) = int_to_semantic(x, "xex")

# Optimized function 
func2(x) = int_to_semantic_claude(x, "gcm")
func2_xex(x) = int_to_semantic_claude(x, "xex")

# Verify correctness for GCM
for x in test_bytes[1:10]  # Test first 10 values
    @assert func1(x) == func2(x) "Mismatch in GCM mode for value: $x"
end

# Verify correctness for XEX
for x in test_bytes[1:10]  # Test first 10 values
    @assert func1_xex(x) == func2_xex(x) "Mismatch in XEX mode for value: $x"
end

println("GCM mode benchmarks:")
@btime func1($(test_bytes[1]))        # Original GCM function
@btime func2($(test_bytes[1]))        # Optimized GCM function

println("\nXEX mode benchmarks:")
@btime func1_xex($(test_bytes[1]))    # Original XEX function
@btime func2_xex($(test_bytes[1]))    # Optimized XEX function