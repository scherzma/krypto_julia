
module Galois
using Nemo
using Base64

struct FieldElement
    value::ZZRingElem
    field::ZZRingElem
end

FieldElement(value::Int) = FieldElement(value, ZZ(0x100000000000000000000000000000087))
FieldElement(value::UInt128) = FieldElement(ZZ(value), ZZ(0x100000000000000000000000000000087))
FieldElement(value::ZZRingElem) = FieldElement(value, ZZ(0x100000000000000000000000000000087))

function FieldElement(value::Array{UInt8}, semantic::String)
    aggregate = ZZ(0)
    one = ZZ(1)
    if semantic == "xex"
        for i in value
            if i < 128
                aggregate |= one << (120 + i&0b0000_0111 -i&0b1111_1000)
            end
        end
    elseif semantic == "gcm"
        for i in value
            if i < 128
                aggregate |= one << (127 - i)
            end
        end
    else
        throw(ArgumentError("Unknown semantic"))
    end
    FieldElement(aggregate)
end

import Base.:+
function Base.:+(a::FieldElement, b::FieldElement)
    if a.field != b.field
        throw(ArgumentError("Cannot add elements from different fields"))
    end
    return FieldElement(a.value ^ b.value, a.field)
end

import Base.:*
function Base.:*(a::FieldElement, b::FieldElement)
    if a.field != b.field
        throw(ArgumentError("Cannot multiply elements from different fields"))
    end
    return FieldElement(a.value ^ b.value, a.field)
end

import Base.show
function Base.show(io::IO, a::FieldElement)
    print(io, "FieldElement($(a.value), $(a.field))")
end

function block(a::FieldElement, semantic::String)
    if semantic == "xex"
        return a.value >> 136
    elseif semantic == "gcm"
        return a.value >> 127
    else
        throw(ArgumentError("Unknown semantic"))
    end
end

function bit_string(a::FieldElement)
    return join(reverse(digits(a.value, base=2, pad=128))) # return join(reverse([(a.value >> i) % 2 == 1 ? 1 : 0 for i in 1:nbits(a.value)]))
end


function to_block(a::FieldElement, semantic::String)
    # Calculate number of bytes needed
    value = a.value
    bit_size = nbits(value)
    num_bytes = ceil(Int, bit_size / 8)
    
    bytes = Vector{UInt8}(undef, num_bytes)
    
    mask = ZZ(0xFF)
    for i in 0:(num_bytes-1)
        shift = i * 8
        byte_val = Int((value >> shift) & mask)
        bytes[num_bytes - i] = UInt8(byte_val)
    end
    
    return base64encode(bytes)
end



import Base: getproperty
function getproperty(gf::FieldElement, sym::Symbol)
    if sym === :block
        return (semantic::String) -> block(gf, semantic)
    end
    if sym === :bit_string
        return () -> bit_string(gf)
    end
    if sym === :to_block
        return (semantic::String) -> to_block(gf, semantic)
    end
    return getfield(gf, sym)
end
end