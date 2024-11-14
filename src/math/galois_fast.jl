
module Galois_quick

using ..SemanticTypes: Semantic, GCM, XEX
using Base64

import Base: +, *, ⊻, <<, >>, %, show, length

struct FieldElement_quick
    value::UInt128
    semantic::Semantic

    function FieldElement_quick(value::UInt128, semantic::Semantic, skip_mani::Bool=false)
        new(value, semantic)
    end
end

const GF128_MODULUS = UInt128(0x87)  # x^128 + x^7 + x^2 + x + 1
const MASK_128 = UInt128(1) << 127

const BIT_REVERSE_TABLE = UInt8[0, 128, 64, 192, 32, 160, 96, 224, 16, 144, 80, 208, 48, 176, 112, 240, 8, 136, 72, 200, 40, 168, 104, 232, 24, 152, 88, 216, 56, 184, 120, 248, 4, 132, 68, 196, 36, 164, 100, 228, 20, 148, 84, 212, 52, 180, 116, 244, 12, 140, 76, 204, 44, 172, 108, 236, 28, 156, 92, 220, 60, 188, 124, 252, 2, 130, 66, 194, 34, 162, 98, 226, 18, 146, 82, 210, 50, 178, 114, 242, 10, 138, 74, 202, 42, 170, 106, 234, 26, 154, 90, 218, 58, 186, 122, 250, 6, 134, 70, 198, 38, 166, 102, 230, 22, 150, 86, 214, 54, 182, 118, 246, 14, 142, 78, 206, 46, 174, 110, 238, 30, 158, 94, 222, 62, 190, 126, 254, 1, 129, 65, 193, 33, 161, 97, 225, 17, 145, 81, 209, 49, 177, 113, 241, 9, 137, 73, 201, 41, 169, 105, 233, 25, 153, 89, 217, 57, 185, 121, 249, 5, 133, 69, 197, 37, 165, 101, 229, 21, 149, 85, 213, 53, 181, 117, 245, 13, 141, 77, 205, 45, 173, 109, 237, 29, 157, 93, 221, 61, 189, 125, 253, 3, 131, 67, 195, 35, 163, 99, 227, 19, 147, 83, 211, 51, 179, 115, 243, 11, 139, 75, 203, 43, 171, 107, 235, 27, 155, 91, 219, 59, 187, 123, 251, 7, 135, 71, 199, 39, 167, 103, 231, 23, 151, 87, 215, 55, 183, 119, 247, 15, 143, 79, 207, 47, 175, 111, 239, 31, 159, 95, 223, 63, 191, 127, 255]


Base.:⊻(a::FieldElement_quick, b::FieldElement_quick) = FieldElement_quick(a.value ⊻ b.value, a.semantic)
Base.:⊻(a::FieldElement_quick, b::UInt128) = FieldElement_quick(a.value ⊻ b, a.semantic)
Base.:>>(a::FieldElement_quick, b::Int) = FieldElement_quick(a.value >> b, a.semantic)
Base.:>>(a::FieldElement_quick, b::Int) = FieldElement_quick(a.value >> b, a.semantic)
Base.:%(a::FieldElement_quick, b::UInt128) = FieldElement_quick(a.value % b, a.semantic)
Base.:%(a::FieldElement_quick, b::FieldElement_quick) = FieldElement_quick(a.value % b.value, a.semantic)
Base.show(io::IO, a::FieldElement_quick) = print(io, "FieldElement($(a.value), $(a.semantic))")
bit_string(a::FieldElement_quick) = join(reverse(digits(a.value, base=2, pad=128)))
to_polynomial(a::FieldElement_quick) = [x for x in 0:127 if (a.value >> x) % 2 == 1]
get_bytes(a::FieldElement_quick) = base64decode(a.to_block())
Base.:+(a::FieldElement_quick, b::FieldElement_quick) = FieldElement_quick(a.value ⊻ b.value, a.semantic)



function int_to_semantic(x::UInt128, semantic::Semantic)
    if semantic == GCM
        return bitreverse(x)
    elseif semantic == XEX
        return bswap(x)
    end
end


function uint8_to_uint128(bytes::Vector{UInt8})::UInt128
    length(bytes) == 16 || throw(ArgumentError("Input must be exactly 16 bytes"))
    @inbounds begin
        result = (UInt128(bytes[1]) << 120) | (UInt128(bytes[2]) << 112) | (UInt128(bytes[3]) << 104) | (UInt128(bytes[4]) << 96) |
                 (UInt128(bytes[5]) << 88)  | (UInt128(bytes[6]) << 80)  | (UInt128(bytes[7]) << 72)  | (UInt128(bytes[8]) << 64) |
                 (UInt128(bytes[9]) << 56)  | (UInt128(bytes[10]) << 48) | (UInt128(bytes[11]) << 40) | (UInt128(bytes[12]) << 32) |
                 (UInt128(bytes[13]) << 24) | (UInt128(bytes[14]) << 16) | (UInt128(bytes[15]) << 8)  | UInt128(bytes[16])
    end
    return result
end



function FieldElement_quick(x::UInt128, semantic::Semantic)
    FieldElement_quick(int_to_semantic(x, semantic), semantic, true)
end

function FieldElement_quick(poly::Array{UInt8}, semantic::Semantic)
    aggregate::UInt128 = 0
    one::UInt128 = 1
    for i in poly
        if i < 128
            aggregate |= (one << i)
        end
    end
    FieldElement_quick(aggregate, semantic, true)
end

function FieldElement_quick(base64::String, semantic::Semantic)
    a_array = base64decode(base64)
    value::UInt128 = uint8_to_uint128(a_array)
    FieldElement_quick(int_to_semantic(value, semantic), semantic, true)
end



function Base.:+(a::FieldElement_quick, b::Vector{UInt8})

    length(b) == 16 || throw(ArgumentError("Input must be exactly 16 bytes"))

    value = uint8_to_uint128(b)
    int_value = int_to_semantic(value, a.semantic)

    return FieldElement_quick(int_value ⊻ a.value, a.semantic, true)
end


function Base.:*(a::FieldElement_quick, b::FieldElement_quick)
    aggregate = UInt128(0)
    tmp_a::UInt128 = a.value
    tmp_b::UInt128 = b.value


    if (tmp_b & UInt128(1)) == 1
        aggregate ⊻= tmp_a
    end

    prev_high_bit = UInt128(0)

    @inbounds for i in 1:128
        prev_high_bit = tmp_a >> 127
        tmp_a <<= 1
        tmp_a ⊻= GF128_MODULUS * prev_high_bit
        
        bit_test = tmp_b & 1           # Test LSB directly
        aggregate ⊻= tmp_a * bit_test
        tmp_b >>= 1

    end
    
    return FieldElement_quick(aggregate, a.semantic, true)
end


function to_block(a::FieldElement_quick)
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


import Base: getproperty
function getproperty(gf::FieldElement_quick, sym::Symbol)
    if sym === :bit_string
        return () -> bit_string(gf)
    end
    if sym === :to_block
        return () -> to_block(gf)
    end
    if sym === :to_polynomial
        return () -> to_polynomial(gf)
    end
    return getfield(gf, sym)
end


end



