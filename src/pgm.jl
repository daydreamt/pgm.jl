module pgm

#This would be a prime candidate for decoupling
include("factor.jl")
# Representation of factors
export Domain, Variable, AbstractFactor, Factor, DiscreteFactor, generate_factor
# Algorithms
include("algorithms.jl")
export compute_Z_brute_force, normalize, reduce_factor, factor_product
# Wrapped distributions
export supported_distributions
# Probably together with that one
include("factorgraph.jl")
export FactorGraph
include("core.jl")
export @model

end
