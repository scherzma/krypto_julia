
module Galois
using Nemo
using Base64

struct FieldElement
    value::ZZRingElem
    semantic::String
    field::ZZRingElem
end

const BIT_REVERSE_TABLE = UInt8[0, 128, 64, 192, 32, 160, 96, 224, 16, 144, 80, 208, 48, 176, 112, 240, 8, 136, 72, 200, 40, 168, 104, 232, 24, 152, 88, 216, 56, 184, 120, 248, 4, 132, 68, 196, 36, 164, 100, 228, 20, 148, 84, 212, 52, 180, 116, 244, 12, 140, 76, 204, 44, 172, 108, 236, 28, 156, 92, 220, 60, 188, 124, 252, 2, 130, 66, 194, 34, 162, 98, 226, 18, 146, 82, 210, 50, 178, 114, 242, 10, 138, 74, 202, 42, 170, 106, 234, 26, 154, 90, 218, 58, 186, 122, 250, 6, 134, 70, 198, 38, 166, 102, 230, 22, 150, 86, 214, 54, 182, 118, 246, 14, 142, 78, 206, 46, 174, 110, 238, 30, 158, 94, 222, 62, 190, 126, 254, 1, 129, 65, 193, 33, 161, 97, 225, 17, 145, 81, 209, 49, 177, 113, 241, 9, 137, 73, 201, 41, 169, 105, 233, 25, 153, 89, 217, 57, 185, 121, 249, 5, 133, 69, 197, 37, 165, 101, 229, 21, 149, 85, 213, 53, 181, 117, 245, 13, 141, 77, 205, 45, 173, 109, 237, 29, 157, 93, 221, 61, 189, 125, 253, 3, 131, 67, 195, 35, 163, 99, 227, 19, 147, 83, 211, 51, 179, 115, 243, 11, 139, 75, 203, 43, 171, 107, 235, 27, 155, 91, 219, 59, 187, 123, 251, 7, 135, 71, 199, 39, 167, 103, 231, 23, 151, 87, 215, 55, 183, 119, 247, 15, 143, 79, 207, 47, 175, 111, 239, 31, 159, 95, 223, 63, 191, 127, 255]


FieldElement(value::Int, semantic::String) = FieldElement(ZZ(value), semantic, ZZ(0x100000000000000000000000000000087))
FieldElement(value::UInt128, semantic::String) = FieldElement(ZZ(value), semantic, ZZ(0x100000000000000000000000000000087))
FieldElement(value::UInt128) = FieldElement(ZZRingElem(value), "XEX", ZZ(0x100000000000000000000000000000087))
FieldElement(value::ZZRingElem, semantic::String) = FieldElement(value, semantic, ZZ(0x100000000000000000000000000000087))

function FieldElement(poly::Array{UInt8}, semantic::String)
    aggregate = ZZ(0)
    one = ZZ(1)
    for i in poly
        if i < 128
            aggregate |= (one << Int(i))
        end
    end
    FieldElement(aggregate, semantic)
end


function FieldElement(base64::String, semantic::String)

    result::ZZRingElem = 0
    a_array = base64decode(base64)


    if semantic == "xex"
        for (i, byte) in enumerate(a_array)
            result = result | ZZRingElem(byte) << (8 * (i-1))
        end
    elseif semantic == "gcm" # + i&0b0000_0111 - i&0b1111_1000
        for (i, b) in enumerate(a_array)

            b = BIT_REVERSE_TABLE[b+1]
            
            result = result | (ZZRingElem(b) << ((i-1) * 8))
        end
    end

    return FieldElement(result, semantic)
end

import Base.:+
function Base.:+(a::FieldElement, b::FieldElement)
    if a.field != b.field
        throw(ArgumentError("Cannot add elements from different fields"))
    end
    return FieldElement(a.value ⊻ b.value, a.semantic, a.field)
end

function Base.:+(a::FieldElement, b::Vector{UInt8})

    println("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
    value = a.value

    for i in 1:length(b)
        value = value ⊻ (ZZ(b[i]) << (8 * (i-1)))
    end
    return FieldElement(value+0x0103924afa, a.semantic, a.field)
end

import Base.:⊻
function Base.:⊻(a::FieldElement, b::FieldElement)
    return FieldElement(a.value ⊻ b.value, a.semantic, a.field)
end

function Base.:⊻(a::FieldElement, b::ZZRingElem)
    return FieldElement(a.value ⊻ b, a.semantic, a.field)
end


import Base.:<<
function Base.:<<(a::FieldElement, b::Int)
    return FieldElement(a.value << b, a.semantic, a.field)
end

import Base.:>>
function Base.:>>(a::FieldElement, b::Int)
    return FieldElement(a.value >> b, a.semantic, a.field)
end

import Base.:%
function Base.:%(a::FieldElement, b::FieldElement)
    return FieldElement(a.value % b.value, a.semantic, a.field)
end


# .length() returns the number of bits in the value
import Base.length
Base.length(a::FieldElement) = nbits(a.value)

import Base.:*
function Base.:*(a::FieldElement, b::FieldElement)
    if a.field != b.field
        throw(ArgumentError("Cannot multiply elements from different fields"))
    end

    aggregate = ZZRingElem(0)

    tmp_a = a.value
    tmp_b = b.value

    highest_field_bit = ZZRingElem(1) << (nbits(a.field) - 1)


    if (tmp_b) % 2 == 1
        aggregate ⊻= tmp_a
    end

    for i in 1:length(b)
        tmp_a <<= 1
        
        if (tmp_a & highest_field_bit) != 0
            tmp_a ⊻= a.field
        end
        
        if (tmp_b >> i) % 2 == 1
            aggregate ⊻= tmp_a
        end

    end
    
    return FieldElement(aggregate, a.semantic, a.field)
end



import Base: iterate, eltype, length
function Base.iterate(fe::FieldElement)
    # Start with first byte (index 0)
    return iterate(fe, 0)
end

function Base.iterate(fe::FieldElement, state)
    # Stop after 16 bytes (128 bits)
    if state >= 16
        return nothing
    end
    
    # Extract the current byte using bit shifting and masking
    mask = ZZ(0xFF)
    shift = state * 8
    
    byte_val = UInt8((fe.value >> shift) & mask)
    return (byte_val, state + 1)
end


import Base.show
function Base.show(io::IO, a::FieldElement)
    print(io, "FieldElement($(a.value), $(a.field))")
end

function bit_string(a::FieldElement)
    return join(reverse(digits(a.value, base=2, pad=128)))
end

function to_polynomial(a::FieldElement)
    return [x for x in 0:127 if (a.value >> x) % 2 == 1] 
end


function to_block(a::FieldElement)
    # Always work with 128 bits (16 bytes)
    BLOCK_SIZE = 16
    bytes = Vector{UInt8}(undef, BLOCK_SIZE)
    value = a.value
    
    mask = ZZ(0xFF)
    
    if a.semantic == "xex"
        for i in 0:(BLOCK_SIZE-1)
            shift = i * 8
            byte_val = UInt8((value >> shift) & mask)
            bytes[i + 1] = byte_val
        end
    elseif a.semantic == "gcm"
        for i in 0:(BLOCK_SIZE-1)
            shift = i * 8
            b = UInt8((value >> shift) & mask)
            bytes[i + 1] = BIT_REVERSE_TABLE[b + 1]
        end
    else
        throw(ArgumentError("Unknown semantic: $semantic"))
    end
    
    return base64encode(bytes)
end


function get_bytes(a::FieldElement)
    return base64decode(a.to_block())
end


import Base: getproperty
function getproperty(gf::FieldElement, sym::Symbol)
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



