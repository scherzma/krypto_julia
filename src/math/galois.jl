
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
    return FieldElement(a.value ⊻ b.value, a.field)
end

import Base.:⊻
function Base.:⊻(a::FieldElement, b::FieldElement)
    return FieldElement(a.value ⊻ b.value, a.field)
end

function Base.:⊻(a::FieldElement, b::ZZRingElem)
    return FieldElement(a.value ⊻ b, a.field)
end

import Base.:<<
function Base.:<<(a::FieldElement, b::Int)
    return FieldElement(a.value << b, a.field)
end

import Base.:>>
function Base.:>>(a::FieldElement, b::Int)
    return FieldElement(a.value >> b, a.field)
end

import Base.:%
function Base.:%(a::FieldElement, b::FieldElement)
    return FieldElement(a.value % b.value, a.field)
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
    
    return FieldElement(aggregate, a.field)
end


import Base.show
function Base.show(io::IO, a::FieldElement)
    print(io, "FieldElement($(a.value), $(a.field))")
end

function bit_string(a::FieldElement)
    return join(reverse(digits(a.value, base=2, pad=128))) # return join(reverse([(a.value >> i) % 2 == 1 ? 1 : 0 for i in 1:nbits(a.value)]))
end

function to_polynomial(a::FieldElement, semantic::String)
    result = Vector{UInt8}(undef, 0)

    if semantic == "xex"
        for i in 0:127
            if (a.value >> i) % 2 == 1
                push!(result, 120 + i&0b0000_0111 -i&0b1111_1000)
            end
        end
    elseif semantic == "gcm"
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
    if sym === :to_polynomial
        return (semantic::String) -> to_polynomial(gf, semantic)
    end
    return getfield(gf, sym)
end


#a = FieldElement(0b11000100, 0b100000000000000000000)
#b = FieldElement(0b00000010, 0b100000000000000000000)
#c = a * b
#println(c)
#println(c.bit_string())

# 1422689339238542770217355994206306432
# 2658455991569831745807614120560689152

a = FieldElement(ZZRingElem(1422689339238542770217355994206306432)) # GF:340282366920938463463374607431768211591
b = FieldElement(ZZRingElem(2658455991569831745807614120560689152))
println(a)
println(b)
c = a * b    # 176974246126301064890833436885137752064
println(c)   # 10000101001001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
println(c.bit_string())



end



