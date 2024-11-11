
module Galois
using Nemo

struct FieldElement
    value::ZZRingElem
    field::ZZRingElem
end

FieldElement(value::Int) = FieldElement(value, ZZ(0x100000000000000000000000000000087))
FieldElement(value::ZZRingElem) = FieldElement(value, ZZ(0x100000000000000000000000000000087))

function FieldElement(value::Array{UInt8}, semantic::String)
    if semantic == "xex"
        aggregate = 0
        one = ZZ(1)

        for i in value
            aggregate += one << (136 - 2 * i % 8)
        end

        FieldElement(aggregate)
    elseif semantic == "gcm"
        aggregate = 0
        one = ZZ(1)

        for i in value
            aggregate += one << 127 - i
        end

        FieldElement(aggregate)
    else
        throw(ArgumentError("Unknown semantic"))
    end

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

import Base: getproperty
function getproperty(gf::FieldElement, sym::Symbol)
    if sym === :block
        return (semantic::String) -> block(gf, semantic)
    end
    return getfield(gf, sym)
end



gf1 = FieldElement(2, 15)
gf2 = FieldElement(3, 15)
println(gf1 + gf2)

poly::Array{UInt8} = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]

gf3 = FieldElement(poly, "gcm")
println(gf3.block("xex"))
end