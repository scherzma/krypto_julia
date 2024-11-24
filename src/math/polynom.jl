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


function reduce_pol(p::Polynomial)::Polynomial
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

    return Polynomial(result_coefficients).reduce_pol()
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
    return Polynomial(result_coefficients).reduce_pol()
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

    return result.reduce_pol()
end

Base.copy(p::Polynomial) = Polynomial(copy(p.coefficients))

function Base.:/(a::Polynomial, b::Polynomial)::Tuple{Polynomial, Polynomial}
    # Handle division by zero
    if b.power == 0 && b.coefficients[1].value == 0
        throw(DivError("Polynomial division by zero"))
    end

    # If the degree of a is less than b, quotient is 0 and remainder is a
    if a.power < b.power
        quotient = Polynomial([FieldElement(UInt128(0), from_string("gcm"), true)])
        remainder = reduce_pol(a)
        return (quotient, remainder)
    end

    # Initialize quotient coefficients with zeros
    quotient_degree = a.power - b.power
    # Preallocate with FieldElement zeros
    zero_fe = FieldElement(UInt128(0), from_string("gcm"))
    quotient_coeffs = fill(zero_fe, quotient_degree + 1)

    # Make a mutable copy of a for the remainder
    remainder_coeffs = copy(a.coefficients)
    remainder_degree = a.power

    # Cache divisor's leading coefficient and store its inverse
    b_lead_coeff = b.coefficients[b.power]
    b_inv_lead = b_lead_coeff.inverse()  # Assuming an inverse method exists

    # Cache divisor coefficients for faster access
    b_coeffs = b.coefficients
    b_power = b.power

    # Main division loop
    while remainder_degree >= b_power && remainder_degree > 0
        lead_coeff_rem = remainder_coeffs[remainder_degree]
        factor = lead_coeff_rem * b_inv_lead
        degree_diff = remainder_degree - b_power
        quotient_coeffs[degree_diff + 1] += factor
        @inbounds for i in 1:b_power
            j = i + degree_diff
            remainder_coeffs[j] -= b_coeffs[i] * factor
        end
        while remainder_degree > 0 && remainder_coeffs[remainder_degree].value == 0
            remainder_degree -= 1
        end
    end

    quotient = Polynomial(quotient_coeffs).reduce_pol()

    if remainder_degree == 0 && remainder_coeffs[1].value == 0
        remainder = Polynomial([FieldElement(UInt128(0), from_string("gcm"), true)])
    else
        remainder = Polynomial(remainder_coeffs[1:remainder_degree]).reduce_pol()
    end

    return (quotient, remainder)
end

function gfpoly_powmod(A::Polynomial, M::Polynomial, k::Integer)::Polynomial
    if k < 0
        throw(ArgumentError("Exponent must be non-negative"))
    end
    one_fe = FieldElement(UInt128(1), from_string("gcm"), true)
    result = Polynomial([one_fe])

    _, base = A / M

    while k > 0
        if (k & 1) == 1
            tmp = result * base
            _, result = tmp / M
        end
        tmp = base * base
        _, base = tmp / M
        k >>= 1
    end

    return result
end



function repr(p::Polynomial)::Array{String}
    return [gfe.to_block() for gfe in p.coefficients]
end


import Base: getproperty
@inline function getproperty(p::Polynomial, sym::Symbol)
    if sym === :repr
        return () -> repr(p)
    end
    if sym === :reduce_pol
        return () -> reduce_pol(p)
    end
    return getfield(p, sym)
end

end