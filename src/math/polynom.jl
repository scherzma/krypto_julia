module Polynom



include("../util/semantic_types.jl")
using .SemanticTypes: Semantic, from_string
using Base64

include("galois_fast.jl")
using .Galois_quick: FieldElement

import Base: +, *, ⊻, <<, >>, %, show, length, ^, ÷, /, copy

struct Polynomial
    coefficients::Array{FieldElement}
    power::Int

    function Polynomial(coefficients::Array{FieldElement})::Polynomial
        new(coefficients, length(coefficients))
    end
end

function Polynomial(coefficients::Array{String})::Polynomial
    elements::Array{FieldElement} = [FieldElement(x, from_string("gcm")) for x in coefficients]
    return Polynomial(elements)   # Probably have to reverse the coefficients
end


function reduce(p::Polynomial)::Polynomial
    new_power = p.power
    while new_power > 0 && p.coefficients[new_power].value == 0
        new_power -= 1
    end
    
    if new_power == p.power
        return p
    end

    if new_power == 0
        return Polynomial([FieldElement(UInt128(0), from_string("gcm"), true)])
    end
    
    return Polynomial(p.coefficients[1:new_power])
end


function Base.:+(a::Polynomial, b::Polynomial)::Polynomial

    max_power = max(a.power, b.power)
    longer, shorter = a.power > b.power ? (a, b) : (b, a)
    result_coefficients::Array{FieldElement} = Array{FieldElement}(undef, max_power)

    for i in 1:max_power
        if i <= shorter.power
            result_coefficients[i] = longer.coefficients[i] + shorter.coefficients[i]
        else
            result_coefficients[i] = longer.coefficients[i]
        end
    end

    return Polynomial(result_coefficients).reduce()
end

function Base.:*(a::Polynomial, b::Polynomial)::Polynomial
    result_coefficients::Array{FieldElement} = Array{FieldElement}(undef, a.power + b.power)
    for i in 1:length(result_coefficients)
        result_coefficients[i] = FieldElement(UInt128(0), from_string("gcm"))
    end

    for i in 1:a.power
        for j in 1:b.power
            result_coefficients[i+j - 1] += a.coefficients[i] * b.coefficients[j]
        end
    end
    return Polynomial(result_coefficients).reduce()
end

function Base.:^(a::Polynomial, b::Int)::Polynomial
    if b == 0
        return Polynomial([FieldElement(UInt128(1), from_string("gcm"), true)])
    end
    
    result = Polynomial([FieldElement(UInt128(1), from_string("gcm"), true)])
    base = a
    exponent = b

    while exponent > 0
        if exponent & 1 == 1
            result *= base
        end
        base *= base
        exponent >>= 1
    end

    return result.reduce()
end

Base.copy(p::Polynomial) = Polynomial(copy(p.coefficients))

function Base.:/(a::Polynomial, b::Polynomial)::Tuple{Polynomial, Polynomial}
    # Handle division by zero
    if b.power == 0 && b.coefficients[1].value == 0
        throw(DivError("Polynomial division by zero"))
    end

    # If the degree of a is less than b, the quotient is 0 and remainder is a
    if a.power < b.power
        quotient = Polynomial([FieldElement(UInt128(0), from_string("gcm"), true)])
        remainder = reduce(a)
        return (quotient, remainder)
    end

    # Initialize quotient coefficients with zeros
    quotient_degree = a.power - b.power
    quotient_coeffs = [FieldElement(UInt128(0), from_string("gcm")) for _ in 0:quotient_degree]

    # Make a mutable copy of a for the remainder
    remainder = copy(a).reduce()

    while remainder.power >= b.power && remainder.power > 0
        lead_coeff_rem = remainder.coefficients[remainder.power]
        lead_coeff_b = b.coefficients[b.power]
        factor = lead_coeff_rem / lead_coeff_b
        degree_diff = remainder.power - b.power
        quotient_coeffs[degree_diff + 1] += factor

        for i in 1:b.power
            j = i + degree_diff
            remainder.coefficients[j] = remainder.coefficients[j] - (b.coefficients[i] * factor)
        end
        remainder = reduce(remainder)
    end
    quotient = Polynomial(quotient_coeffs).reduce()

    return (quotient, remainder)
end




function repr(p::Polynomial)::Array{String}
    return [gfe.to_block() for gfe in p.coefficients]
end


import Base: getproperty
@inline function getproperty(p::Polynomial, sym::Symbol)
    if sym === :repr
        return () -> repr(p)
    end
    if sym === :reduce
        return () -> reduce(p)
    end
    return getfield(p, sym)
end

end