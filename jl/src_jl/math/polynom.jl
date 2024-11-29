
struct Polynomial
    coefficients::Array{FieldElement}
    power::Int

    function Polynomial(coefficients::Array{FieldElement})::Polynomial
        new(coefficients, length(coefficients))
    end
end

function Polynomial(coefficients::Array{String})::Polynomial
    elements::Array{FieldElement} = [FieldElement(x, GCM) for x in coefficients]
    return Polynomial(elements)   # Probably have to reverse the coefficients
end


function is_zero(p::Polynomial)::Bool
    return p.power == 0 || (p.power == 1 && p.coefficients[1].is_zero())
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
        return Polynomial([FieldElement(UInt128(0), GCM, true)])
    end
    
    return Polynomial(p.coefficients[1:new_power])
end

function Base.isless(a::Polynomial, b::Polynomial)::Bool
    if a.power < b.power
        return true
    elseif a.power > b.power
        return false
    else
        # Degrees are equal, compare coefficients from highest to lowest
        for i in a.power:-1:1
            if isless(a.coefficients[i], b.coefficients[i])
                return true
            elseif isless(b.coefficients[i], a.coefficients[i])
                return false
            end
        end
        return false  # Polynomials are equal
    end
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

function Base.:-(a::Polynomial, b::Polynomial)::Polynomial
    return a + b
end

function Base.:*(a::Polynomial, b::Polynomial)::Polynomial
    result_coefficients::Array{FieldElement} = Array{FieldElement}(undef, a.power + b.power)
    for i in 1:length(result_coefficients)
        result_coefficients[i] = FieldElement(UInt128(0), GCM, false)
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
        return Polynomial([FieldElement(UInt128(1), GCM, true)])
    end
    
    result = Polynomial([FieldElement(UInt128(1), GCM, true)])
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
    if b.power == 0 && b.coefficients[1].value == 0
        throw(DivError("Polynomial division by zero"))
    end

    if a.power < b.power
        quotient = Polynomial([FieldElement(UInt128(0), GCM, true)])
        remainder = reduce_pol(a)
        return (quotient, remainder)
    end

    quotient_degree = a.power - b.power
    zero_fe = FieldElement(UInt128(0), GCM, false)
    quotient_coeffs = fill(zero_fe, quotient_degree + 1)
    remainder_coeffs = copy(a.coefficients)
    remainder_degree = a.power
    b_lead_coeff = b.coefficients[b.power]
    b_inv_lead = b_lead_coeff.inverse()  # Assuming an inverse method exists

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
        remainder = Polynomial([FieldElement(UInt128(0), GCM, true)])
    else
        remainder = Polynomial(remainder_coeffs[1:remainder_degree]).reduce_pol()
    end

    return (quotient, remainder)
end

function gfpoly_powmod(A::Polynomial, M::Polynomial, k::Integer)::Polynomial
    if k < 0
        throw(ArgumentError("Exponent must be non-negative"))
    end
    one_fe = FieldElement(UInt128(1), GCM, true)
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


function Base.:√(Q::Polynomial)::Polynomial

    # Validate that Q has only even exponents with non-zero coefficients
    for i in 0:(Q.power - 1)
        if isodd(i) && Q.coefficients[i + 1].value != 0
            throw(ArgumentError("Polynomial Q must have only even exponents with non-zero coefficients."))
        end
    end

    # The degree of the square root polynomial S will be floor(Q.power / 2)
    m = div(Q.power, 2)
    S_coeffs = Vector{FieldElement}(undef, m + 1)

    for i in 0:m
        q_2i = Q.coefficients[2 * i + 1]
        S_coeffs[i + 1] = √q_2i
    end

    return Polynomial(S_coeffs).reduce_pol()
end


function monic(A::Polynomial)::Polynomial
    if A.power == 0 && A.coefficients[1].value == 0
        throw(ArgumentError("Cannot make the zero polynomial monic"))
    end
    c = A.coefficients[A.power]
    c_inv = c.inverse()
    new_coeffs = [coeff * c_inv for coeff in A.coefficients]
    return Polynomial(new_coeffs).reduce_pol()
end


function diff(poly::Polynomial)::Polynomial
    derivative_coeffs::Array{FieldElement} = []
    coeff::FieldElement = FieldElement(UInt128(0), GCM, false)

    for i in 1:poly.power
        if isodd(i)
            coeff = poly.coefficients[i + 1]
            push!(derivative_coeffs, coeff)
        else
            push!(derivative_coeffs, FieldElement(UInt128(0), GCM, false))
        end
    end

    derivative_poly = Polynomial(derivative_coeffs).reduce_pol()

    return derivative_poly
end



function gcd(A::Polynomial, B::Polynomial)::Polynomial
    a = reduce_pol(A)
    b = reduce_pol(B)

    while !is_zero(b)
        _, r = a / b
        a, b = b, r
    end

    return monic(a)
end



function repr(p::Polynomial)::Array{String}
    return [gfe.to_block() for gfe in p.coefficients]
end


@inline function getproperty(p::Polynomial, sym::Symbol)
    if sym === :repr
        return () -> repr(p)
    end
    if sym === :reduce_pol
        return () -> reduce_pol(p)
    end
    if sym === :monic
        return () -> monic(p)
    end
    if sym === :diff
        return () -> diff(p)
    end
    if sym === :gcd
        return (b::Polynomial) -> gcd(p, b)
    end
    return getfield(p, sym)
end