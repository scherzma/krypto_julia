module Poly_diff

include("../util/semantic_types.jl")
using .SemanticTypes: from_string

include("../math/polynom.jl")
using .Polynom: Polynomial
include("../math/galois_fast.jl")
using .Galois_quick: FieldElement

function gfpoly_diff(F::Array{String})::Polynomial
    # Convert the input array of Base64 strings to a Polynomial
    poly = Polynomial(F)

    # Initialize an array to hold the derivative coefficients
    derivative_coeffs::Array{FieldElement} = []

    # Compute the derivative: F'(x) = a1 + 2*a2*x + 3*a3*x^2 + ...
    # In characteristic 2, 2*a2 = 0, 3*a3 = a3, etc.
    coeff::FieldElement = FieldElement(UInt128(0), from_string("gcm"))

    for i in 1:poly.power
        if isodd(i)
            coeff = poly.coefficients[i + 1]
            push!(derivative_coeffs, coeff)
        else
            push!(derivative_coeffs, FieldElement(UInt128(0), from_string("gcm")))
        end
    end

    derivative_poly = Polynomial(derivative_coeffs).reduce_pol()
    F_prime = repr(derivative_poly)

    return F_prime
end



end