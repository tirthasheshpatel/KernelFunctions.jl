"""
KernelFunctions. [Github](https://github.com/JuliaGaussianProcesses/KernelFunctions.jl)
[Documentation](https://juliagaussianprocesses.github.io/KernelFunctions.jl/stable/)
"""
module KernelFunctions

export kernelmatrix, kernelmatrix!, kerneldiagmatrix, kerneldiagmatrix!
export transform
export duplicate, set! # Helpers

export Kernel
export ConstantKernel, WhiteKernel, EyeKernel, ZeroKernel, WienerKernel
export CosineKernel
export SqExponentialKernel, RBFKernel, GaussianKernel, SEKernel
export LaplacianKernel, ExponentialKernel, GammaExponentialKernel
export ExponentiatedKernel
export MaternKernel, Matern32Kernel, Matern52Kernel
export LinearKernel, PolynomialKernel
export RationalQuadraticKernel, GammaRationalQuadraticKernel
export MahalanobisKernel, GaborKernel, PiecewisePolynomialKernel
export PeriodicKernel, NeuralNetworkKernel
export KernelSum, KernelProduct
export TransformedKernel, ScaledKernel
export TensorProduct

export Transform, SelectTransform, ChainTransform, ScaleTransform, LinearTransform,
    ARDTransform, IdentityTransform, FunctionTransform

export NystromFact, nystrom

export spectral_mixture_kernel, spectral_mixture_product_kernel


using Compat
using Requires
using Distances, LinearAlgebra
using SpecialFunctions: loggamma, besselk, polygamma
using ZygoteRules: @adjoint, pullback
using StatsFuns: logtwo
using InteractiveUtils: subtypes
using StatsBase

"""
Abstract type defining a slice-wise transformation on an input matrix
"""
abstract type Transform end

abstract type Kernel end
abstract type BaseKernel <: Kernel end
abstract type SimpleKernel <: BaseKernel end

include("utils.jl")
include("distances/pairwise.jl")
include("distances/dotproduct.jl")
include("distances/delta.jl")
include("distances/sinus.jl")
include("transform/transform.jl")

for f in readdir(joinpath(@__DIR__, "basekernels"))
    endswith(f, ".jl") && include(joinpath("basekernels", f))
end

include("kernels/transformedkernel.jl")
include("kernels/scaledkernel.jl")
include("matrix/kernelmatrix.jl")
include("kernels/kernelsum.jl")
include("kernels/kernelproduct.jl")
include("kernels/tensorproduct.jl")
include("approximations/nystrom.jl")
include("generic.jl")

include("zygote_adjoints.jl")

function __init__()
    @require Kronecker="2c470bb0-bcc8-11e8-3dad-c9649493f05e" include("matrix/kernelkroneckermat.jl")
    @require PDMats="90014a1f-27ba-587c-ab20-58faa44d9150" include("matrix/kernelpdmat.jl")
    @require Flux="587475ba-b771-5e3f-ad9e-33799f191a9c" include("trainable.jl")
end

end
