struct GhostDerivativeOperator{T, E<:AbstractDiffEqLinearOperator{T}, F<:AbstractBC{T}} <: AbstractDiffEqLinearOperator{T}
    L :: E
    Q :: F
end

function Base.:*(L::AbstractDiffEqLinearOperator{T}, Q::AbstractBC{T}) where{T}
    return GhostDerivativeOperator{T, typeof(L), typeof(Q)}(L,Q)
end

function *(A::GhostDerivativeOperator{T,E,F}, u::AbstractArray{T}) where {T,E,F}
    #TODO Implement a function domaincheck(L::AbstractDiffEqLinearOperator, u) to see if components of L along each dimension match the size of u
    x = similar(u)
    LinearAlgebra.mul!(x, A.L, A.Q*u)
    return x
end

function \(A::GhostDerivativeOperator{T,E,F}, u::AbstractArray{T,N}) where {T,E,F,N}
    #TODO implement check that A has compatible size with u
    s = size(u)
    (A_l,A_b) = sparse(A, s)
    x = A_l\Vector(reshape(u, length(u)).-A_b) #Has to be converted to vector to work, A_b being sparse was causing a conversion to sparse.
    return reshape(x, s)
end

function \(A::GhostDerivativeOperator{T,E,F}, u::AbstractVector{T}) where {T,E,F}
    @assert length(u) == size(A.L, 1)
    (A_l,A_b) = sparse(A,length(u))
    A_l\Vector(u.-A_b)
end

# update coefficients
function DiffEqBase.update_coefficients!(A::GhostDerivativeOperator{T,E,F},u,p,t) where {T,E,F}
    DiffEqBase.update_coefficients!(A.L,u,p,t)
end

function *(coeff_func::Function, A::GhostDerivativeOperator{T,N,Wind}) where {T,N,Wind}
    (coeff_func*A.L)*A.Q
end

# length and sizes
Base.ndims(A::GhostDerivativeOperator) = 2
Base.size(A::GhostDerivativeOperator) = (size(A.L, 2), size(A.L, 2))
Base.size(A::GhostDerivativeOperator,i::Integer) = size(A)[i]
Base.length(A::GhostDerivativeOperator) = reduce(*, size(A))
