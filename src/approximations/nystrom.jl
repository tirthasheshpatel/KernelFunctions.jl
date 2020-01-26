using StatsBase
using LinearAlgebra
# Following the algorithm by William and Seeger, 2001
# Cs is equivalent to X_mm and C to X_mn

function sampleindex(X::AbstractMatrix, r::AbstractFloat; obsdim::Integer=defaultobs)
    0 < r <= 1 || throw(ArgumentError("Sample rate `r` must be in range (0,1]"))
    n = size(X, obsdim)
    m = ceil(Int, n*r)
    S = StatsBase.sample(collect(1:n), m; replace=false, ordered=true)
    return S
end

function nystrom_sample(k::Kernel, X::AbstractMatrix, S::Vector{<:Integer}; obsdim::Integer=defaultobs)
    obsdim ∈ [1, 2] || throw(ArgumentError("`obsdim` should be 1 or 2 (see docs of kernelmatrix))"))
    Xₘ = obsdim == 1 ? getindex(X, S, :) : getindex(X, :, S)
    C = k(Xₘ, X; obsdim=obsdim)
    Cs = getindex(C, :, S)
    return (C, Cs)
end

function nystrom_pinv!(Cs::Matrix{T}, tol::T=eps(T)*size(Cs,1)) where {T<:AbstractFloat}
    # Compute eigendecomposition of sampled component of K
    QΛQᵀ = LinearAlgebra.eigen!(LinearAlgebra.Symmetric(Cs))

    # Solve for D = Λ^(-1/2) (pseudo inverse - use tolerance from before factorization)
    D = QΛQᵀ.values
    λ_tol = maximum(D)*tol

    for i in eachindex(D)
        @inbounds D[i] = abs(D[i]) <= λ_tol ? zero(T) : one(T)/sqrt(D[i])
    end

    # Scale eigenvectors by D
    Q = QΛQᵀ.vectors
    QD = LinearAlgebra.rmul!(Q, LinearAlgebra.Diagonal(D))  # Scales column i of Q by D[i]

    # W := (QD)(QD)ᵀ = (QΛQᵀ)^(-1)  (pseudo inverse)
    W = QD*QD'

    # Symmetrize W
    return LinearAlgebra.copytri!(W, 'U')
end

@doc raw"""
    NystromFact

Type for storing a Nystrom factorization. The factorization contains two fields: `W` and
`C`, two matrices satisfying:
```math
\mathbf{K} \approx \mathbf{C}^{\intercal}\mathbf{W}\mathbf{C}
```
"""
struct NystromFact{T<:AbstractFloat}
    W::Matrix{T}
    C::Matrix{T}
end

@doc raw"""
    nystrom(k::Kernel, X::Matrix, S::Vector; obsdim::Int=defaultobs)

Computes a factorization of Nystrom approximation of the square kernel matrix of data
matrix `X` with respect to kernel `k`. Returns a `NystromFact` struct which stores a
Nystrom factorization satisfying:
```math
\mathbf{K} \approx \mathbf{C}^{\intercal}\mathbf{W}\mathbf{C}
```
"""
function nystrom(k::Kernel, X::AbstractMatrix, S::Vector{<:Integer}; obsdim::Int=defaultobs)
    C, Cs = nystrom_sample(k, X, S; obsdim=obsdim)
    W = nystrom_pinv!(Cs)
    T = typeof(first(W))
    return NystromFact{T}(W, C)
end

@doc raw"""
    nystrom(k::Kernel, X::Matrix, r::AbstractFloat; obsdim::Int=defaultobs)

Computes a factorization of Nystrom approximation of the square kernel matrix of data
matrix `X` with respect to kernel `k` using a sample ratio of `r`.
Returns a `NystromFact` struct which stores a Nystrom factorization satisfying:
```math
\mathbf{K} \approx \mathbf{C}^{\intercal}\mathbf{W}\mathbf{C}
```
"""
function nystrom(k::Kernel, X::AbstractMatrix, r::AbstractFloat; obsdim::Int=defaultobs)
    S = sampleindex(X, r; obsdim=obsdim)
    C, Cs = nystrom_sample(k, X, S; obsdim=obsdim)
    W = nystrom_pinv!(Cs)
    T = typeof(first(W))
    return NystromFact{T}(W, C)
end

"""
    nystrom(CᵀWC::NystromFact)

Compute the approximate kernel matrix based on the Nystrom factorization.
"""
function kernelmatrix(CᵀWC::NystromFact{<:AbstractFloat})
    W = CᵀWC.W
    C = CᵀWC.C
    return C'*W*C
end
