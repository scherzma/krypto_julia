module Polynom



include("../util/semantic_types.jl")
using .SemanticTypes: Semantic, from_string
using Base64

include("galois_fast.jl")
using .Galois_quick: FieldElement

import Base: +, *, ⊻, <<, >>, %, show, length, ^, ÷, /

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


function reduce_polynomial(p::Polynomial)::Polynomial
    new_power = p.power
    while new_power > 0 && p.coefficients[new_power].value == 0
        new_power -= 1
    end
    
    if new_power == p.power
        return p
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


# Overload the division operator to perform polynomial long division
# Returns a tuple (quotient, remainder)
function ÷(a::Polynomial, b::Polynomial)::Tuple{Polynomial, Polynomial}

    if b.power < 0 || all(fe.value == 0 for fe in b.coefficients)
        error("Division by zero polynomial is not allowed.")
    end

    dividend = a.coefficients
    divisor = b.coefficients

    deg_dividend = a.power
    deg_divisor = b.power

    if deg_divisor > deg_dividend
        return Polynomial([FieldElement(UInt128(0), from_string("gcm"), true)]), a
    end

    quotient = [FieldElement(UInt128(0), from_string("gcm"), true) for _ in 1:(deg_dividend - deg_divisor + 1)]

    while length(dividend) >= length(divisor)
        leading_term = dividend[end] / divisor[end]
        quotient[length(dividend) - length(divisor) + 1] = leading_term

        # Subtract the scaled divisor from the dividend

        for i in 1:length(divisor)
            dividend[length(dividend) - length(divisor) + i] += leading_term * divisor[i]
        end

        # Remove leading zeros
        dividend = dividend.reduce()
    end

    return Polynomial(quotient), a - Polynomial(quotient) * b
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
        return () -> reduce_polynomial(p)
    end
    return getfield(p, sym)
end

end