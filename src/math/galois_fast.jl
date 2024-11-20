
module Galois_quick

using ..SemanticTypes: Semantic, GCM, XEX
using Base64

import Base: +, *, ⊻, <<, >>, %, show, length, /, -, ÷

struct FieldElement
    value::UInt128
    semantic::Semantic

    function FieldElement(value::UInt128, semantic::Semantic, skip_mani::Bool=false)::FieldElement
        new(value, semantic)
    end
end

const GF128_MODULUS = UInt128(0x87)  # x^128 + x^7 + x^2 + x + 1
const MASK_128 = UInt128(1) << 127

const BIT_REVERSE_TABLE = UInt8[0, 128, 64, 192, 32, 160, 96, 224, 16, 144, 80, 208, 48, 176, 112, 240, 8, 136, 72, 200, 40, 168, 104, 232, 24, 152, 88, 216, 56, 184, 120, 248, 4, 132, 68, 196, 36, 164, 100, 228, 20, 148, 84, 212, 52, 180, 116, 244, 12, 140, 76, 204, 44, 172, 108, 236, 28, 156, 92, 220, 60, 188, 124, 252, 2, 130, 66, 194, 34, 162, 98, 226, 18, 146, 82, 210, 50, 178, 114, 242, 10, 138, 74, 202, 42, 170, 106, 234, 26, 154, 90, 218, 58, 186, 122, 250, 6, 134, 70, 198, 38, 166, 102, 230, 22, 150, 86, 214, 54, 182, 118, 246, 14, 142, 78, 206, 46, 174, 110, 238, 30, 158, 94, 222, 62, 190, 126, 254, 1, 129, 65, 193, 33, 161, 97, 225, 17, 145, 81, 209, 49, 177, 113, 241, 9, 137, 73, 201, 41, 169, 105, 233, 25, 153, 89, 217, 57, 185, 121, 249, 5, 133, 69, 197, 37, 165, 101, 229, 21, 149, 85, 213, 53, 181, 117, 245, 13, 141, 77, 205, 45, 173, 109, 237, 29, 157, 93, 221, 61, 189, 125, 253, 3, 131, 67, 195, 35, 163, 99, 227, 19, 147, 83, 211, 51, 179, 115, 243, 11, 139, 75, 203, 43, 171, 107, 235, 27, 155, 91, 219, 59, 187, 123, 251, 7, 135, 71, 199, 39, 167, 103, 231, 23, 151, 87, 215, 55, 183, 119, 247, 15, 143, 79, 207, 47, 175, 111, 239, 31, 159, 95, 223, 63, 191, 127, 255]

@inline Base.:⊻(a::FieldElement, b::FieldElement)::FieldElement = FieldElement(a.value ⊻ b.value, a.semantic)
@inline Base.:⊻(a::FieldElement, b::UInt128)::FieldElement = FieldElement(a.value ⊻ b, a.semantic)
@inline Base.:>>(a::FieldElement, b::Int)::FieldElement = FieldElement(a.value >> b, a.semantic)
@inline Base.:>>(a::FieldElement, b::Int)::FieldElement = FieldElement(a.value >> b, a.semantic)
@inline Base.:%(a::FieldElement, b::UInt128)::FieldElement = FieldElement(a.value % b, a.semantic)
@inline Base.:%(a::FieldElement, b::FieldElement)::FieldElement = FieldElement(a.value % b.value, a.semantic)
@inline Base.show(io::IO, a::FieldElement)::Nothing = print(io, "FieldElement($(a.value), $(a.semantic))")
@inline bit_string(a::FieldElement)::String = join(reverse(digits(a.value, base=2, pad=128)))
@inline to_polynomial(a::FieldElement)::Array{UInt8} = [x for x in 0:127 if (a.value >> x) % 2 == 1]
@inline get_bytes(a::FieldElement)::Vector{UInt8} = base64decode(a.to_block())
@inline Base.:+(a::FieldElement, b::FieldElement)::FieldElement = FieldElement(a.value ⊻ b.value, a.semantic, true)



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



function FieldElement(x::UInt128, semantic::Semantic)::FieldElement
    FieldElement(int_to_semantic(x, semantic), semantic, true)
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

function Base.:-(a::FieldElement, b::FieldElement)::FieldElement
    return a + b
end


function inverse(a::FieldElement, p::FieldElement)::FieldElement
    t = FieldElement(UInt128(0), a.semantic, true)
    newt = FieldElement(UInt128(1), a.semantic, true)
    r = p
    newr = a

    while newr.value != 0
        quotient = r ÷ newr
        r, newr = newr, r - quotient * newr
        t, newt = newt, t - quotient * newt
    end

    if r.value == 0
        throw(ErrorException("Either p is not irreducible or a is a multiple of p"))
    end

    # Multiply by multiplicative inverse of leading coefficient of r
    return t ÷ r
end


function Base.:/(a::FieldElement, b::FieldElement)::FieldElement
    if b.value == 0
        throw(ErrorException("Division by zero"))
    end
    return a * inverse(b, FieldElement(UInt128(1), a.semantic, true))
end



function Base.:÷(a::FieldElement, b::FieldElement)::FieldElement # http://www.ee.unb.ca/cgi-bin/tervo/calc.pl?num=100100101010101011011111000111&den=1111001110010101&f=d&e=1&p=1&m=1
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
    return FieldElement(numerator, a.semantic, true)
end


function to_block(a::FieldElement)::String
    bytes = Vector{UInt8}(undef, 16)
    value::UInt128 = a.value

    
    if a.semantic == XEX
        bytes = reinterpret(UInt8, [value])
    elseif a.semantic == GCM
        value = bitreverse(value)
        bytes = reverse!(reinterpret(UInt8, [value]))
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
    return getfield(gf, sym)
end





end



