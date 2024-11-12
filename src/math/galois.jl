
module Galois
using Nemo
using Base64

struct FieldElement
    value::ZZRingElem
    semantic::String
    field::ZZRingElem
end

FieldElement(value::Int, semantic::String) = FieldElement(ZZ(value), semantic, ZZ(0x100000000000000000000000000000087))
FieldElement(value::UInt128, semantic::String) = FieldElement(ZZ(value), semantic, ZZ(0x100000000000000000000000000000087))
FieldElement(value::ZZRingElem, semantic::String) = FieldElement(value, semantic, ZZ(0x100000000000000000000000000000087))

function FieldElement(poly::Array{UInt8}, semantic::String)
    aggregate = ZZ(0)
    one = ZZ(1)
    if semantic == "xex"
        for i in poly
            if i < 128
                aggregate |= one << (120 + i&0b0000_0111 -i&0b1111_1000)
            end
        end
    elseif semantic == "gcm"
        for i in poly
            if i < 128
                aggregate |= one << (127 - i)
            end
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
    elseif semantic == "gcm"
        for (i, b) in enumerate(a_array)

            b = (b & 0xF0) >> 4 | (b & 0x0F) << 4
            b = (b & 0xCC) >> 2 | (b & 0x33) << 2
            b = (b & 0xAA) >> 1 | (b & 0x55) << 1
            
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


import Base.show
function Base.show(io::IO, a::FieldElement)
    print(io, "FieldElement($(a.value), $(a.field))")
end

function bit_string(a::FieldElement)
    return join(reverse(digits(a.value, base=2, pad=128))) # return join(reverse([(a.value >> i) % 2 == 1 ? 1 : 0 for i in 1:nbits(a.value)]))
end

function to_polynomial(a::FieldElement)
    result = Vector{UInt8}(undef, 0)

    if a.semantic == "xex"
        for i in 0:127
            if (a.value >> i) % 2 == 1
                push!(result, 120 + i&0b0000_0111 -i&0b1111_1000)
            end
        end
    elseif a.semantic == "gcm"
        for i in 0:127
            if (a.value >> i) % 2 == 1
                push!(result, 127 - i)
            end
        end
    else
        throw(ArgumentError("Unknown semantic"))
    end

    return result
end


function to_block(a::FieldElement)
    # Always work with 128 bits (16 bytes)
    BLOCK_SIZE = 16
    bytes = Vector{UInt8}(undef, BLOCK_SIZE)
    value = a.value
    
    # Initialize bytes to zero
    fill!(bytes, 0x00)
    
    mask = ZZ(0xFF)
    
    if a.semantic == "xex"
        # For xex semantic, store in little-endian order
        for i in 0:(BLOCK_SIZE-1)
            shift = i * 8
            byte_val = Int((value >> shift) & mask)
            bytes[i + 1] = UInt8(byte_val)
        end
    elseif a.semantic == "gcm"
        # For gcm semantic, store in big-endian order
        for i in 0:(BLOCK_SIZE-1)
            shift = (BLOCK_SIZE - 1 - i) * 8
            byte_val = Int((value >> shift) & mask)
            bytes[i + 1] = UInt8(byte_val)
        end
    else
        throw(ArgumentError("Unknown semantic: $semantic"))
    end
    
    return base64encode(bytes)
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



