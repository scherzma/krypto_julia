struct FieldElement
    value::UInt128
    semantic::Semantic
    skip_manipulation::Bool

    function FieldElement(value::UInt128, semantic::Semantic, skip_manipulation::Bool)::FieldElement
        if skip_manipulation
            return new(value, semantic, skip_manipulation)
        else
            return new(int_to_semantic(value, semantic), semantic, true)
        end
    end
end


@inline Base.:⊻(a::FieldElement, b::FieldElement)::FieldElement = FieldElement(a.value ⊻ b.value, a.semantic, true)
@inline Base.:⊻(a::FieldElement, b::UInt128)::FieldElement = FieldElement(a.value ⊻ b, a.semantic, true)
@inline Base.:>>(a::FieldElement, b::Int)::FieldElement = FieldElement(a.value >> b, a.semantic, true)
@inline Base.:%(a::FieldElement, b::UInt128)::FieldElement = FieldElement(a.value % b, a.semantic, true)
@inline Base.:%(a::FieldElement, b::FieldElement)::FieldElement = FieldElement(a.value % b.value, a.semantic, true)
@inline Base.show(io::IO, a::FieldElement)::Nothing = print(io, "FieldElement($(a.value), $(a.semantic))")
@inline bit_string(a::FieldElement)::String = join(reverse(digits(a.value, base=2, pad=128)))
@inline to_polynomial(a::FieldElement)::Array{UInt8} = [x for x in 0:127 if (a.value >> x) % 2 == 1]
@inline get_bytes(a::FieldElement)::Vector{UInt8} = base64decode(a.to_block())
@inline Base.:+(a::FieldElement, b::FieldElement)::FieldElement = FieldElement(a.value ⊻ b.value, a.semantic, true)
@inline Base.:-(a::FieldElement, b::FieldElement)::FieldElement = FieldElement(a.value ⊻ b.value, a.semantic, true)
@inline Base.:<(a::FieldElement, b::FieldElement)::Bool = a.value < b.value
@inline Base.:>(a::FieldElement, b::FieldElement)::Bool = a.value > b.value
@inline Base.:(==)(a::FieldElement, b::FieldElement)::Bool = a.value == b.value
@inline Base.isless(a::FieldElement, b::FieldElement)::Bool = a.value < b.value

function Base.:√(a::FieldElement)::FieldElement
    if is_zero(a)
        return a
    end
    result = a
    for _ in 1:127
        result = result * result
    end
    return result
end


@inline function int_to_semantic(x::UInt128, semantic::Semantic)::UInt128
    if semantic == GCM
        return bitreverse(x)
    elseif semantic == XEX
        return bswap(x)
    end
end


@inline function uint8_to_uint128(bytes::Vector{UInt8})::UInt128
    # length(bytes) == 16 || throw(ArgumentError("Input must be exactly 16 bytes")) # This should really be checked, but it's a tiny bit slower
    @inbounds begin
        result = (UInt128(bytes[1]) << 120) | (UInt128(bytes[2]) << 112) | (UInt128(bytes[3]) << 104) | (UInt128(bytes[4]) << 96) |
                 (UInt128(bytes[5]) << 88)  | (UInt128(bytes[6]) << 80)  | (UInt128(bytes[7]) << 72)  | (UInt128(bytes[8]) << 64) |
                 (UInt128(bytes[9]) << 56)  | (UInt128(bytes[10]) << 48) | (UInt128(bytes[11]) << 40) | (UInt128(bytes[12]) << 32) |
                 (UInt128(bytes[13]) << 24) | (UInt128(bytes[14]) << 16) | (UInt128(bytes[15]) << 8)  | UInt128(bytes[16])
    end
    return result
end

function FieldElement(poly::Array{UInt8}, semantic::Semantic)::FieldElement
    aggregate::UInt128 = 0
    one::UInt128 = 1
    for i in poly
        if i < 128
            aggregate |= (one << i)
        end
    end
    FieldElement(aggregate, semantic, true)
end

function FieldElement(base64::String, semantic::Semantic)::FieldElement
    a_array = base64decode(base64)
    value::UInt128 = uint8_to_uint128(a_array)
    FieldElement(int_to_semantic(value, semantic), semantic, true)
end



function Base.:+(a::FieldElement, b::Vector{UInt8})::FieldElement

    length(b) == 16 || throw(ArgumentError("Input must be exactly 16 bytes"))

    value = uint8_to_uint128(b)
    int_value = int_to_semantic(value, a.semantic)

    return FieldElement(int_value ⊻ a.value, a.semantic, true)
end


function Base.:*(a::FieldElement, b::FieldElement)::FieldElement
    aggregate = UInt128(0)
    tmp_a::UInt128 = a.value
    tmp_b::UInt128 = b.value


    if (tmp_b & UInt128(1)) == 1
        aggregate ⊻= tmp_a
    end

    prev_high_bit = UInt128(0)

    @inbounds for i in 1:128
        prev_high_bit = tmp_a >> 127
        tmp_a <<= UInt128(1)
        tmp_a ⊻= GF128_MODULUS * prev_high_bit

        tmp_b >>= UInt128(1)
        aggregate ⊻= tmp_a * (tmp_b & UInt128(1))
    end
    
    return FieldElement(aggregate, a.semantic, true)
end

function power(a::FieldElement, exponent::UInt128)::FieldElement
    result = FieldElement(UInt128(1), a.semantic, true)  # Initialize to 1
    base = a

    @inbounds for i in 0:127
        if (exponent >> i) & 1 == 1
            result = result * base
        end
        base = base * base
    end

    return result
end

function inverse(a::FieldElement)::FieldElement
    if is_zero(a)
        throw(ArgumentError("Cannot invert the zero element"))
    end
    exponent = UInt128(~UInt128(0)) - UInt128(1)  # 2^128 - 2
    return power(a, exponent)
end


# Corrected Division Function Using the Correct Inverse
function Base.:/(a::FieldElement, b::FieldElement)::FieldElement
    if b.value == 0
        throw(ErrorException("Division by zero"))
    end
    return a * inverse(b)
end


# Corrected Polynomial Long Division (÷)
function Base.:÷(a::FieldElement, b::FieldElement)::FieldElement # Polynomial Long Division
    if b.value == 0
        throw(ErrorException("Division by zero"))
    end
    if a.value == 0
        return FieldElement(UInt128(0), a.semantic, true)
    end
    if b.value == 1
        return a
    end

    numerator = a.value
    denominator = b.value
    quotient = UInt128(0)

    numerator_degree = 127 - leading_zeros(numerator)
    denominator_degree = 127 - leading_zeros(denominator)

    while numerator >= denominator
        shift = numerator_degree - denominator_degree
        shifted_divisor = denominator << shift
        numerator = numerator ⊻ shifted_divisor
        quotient |= UInt128(1) << shift
        numerator_degree = 127 - leading_zeros(numerator)
    end
    return FieldElement(quotient, a.semantic, true)
end


function to_block(a::FieldElement)::String
    bytes = Vector{UInt8}(undef, 16)
    value::UInt128 = a.value
    println(a.value)
    
    if a.semantic == XEX
        bytes = reinterpret(UInt8, [value])
    elseif a.semantic == GCM
        value = bitreverse(value)
        println(value)
        bytes = reverse!(reinterpret(UInt8, [value]))
        println(bytes)
    end
    
    return base64encode(bytes)
end


function is_zero(a::FieldElement)::Bool
    return a.value == 0
end


import Base: getproperty
@inline function getproperty(gf::FieldElement, sym::Symbol)
    if sym === :bit_string
        return () -> bit_string(gf)
    end
    if sym === :to_block
        return () -> to_block(gf)
    end
    if sym === :to_polynomial
        return () -> to_polynomial(gf)
    end
    if sym === :is_zero
        return () -> is_zero(gf)
    end
    if sym === :inverse
        return () -> inverse(gf)
    end
    return getfield(gf, sym)
end
