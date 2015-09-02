module pgm

#This would be a prime candidate for decoupling
include("factor.jl")
# Representation
export Domain, Variable, AbstractFactor, Factor, DiscreteFactor
# Algorithms
export compute_Z_brute_force, normalize
# Wrapped distributions
export supported_distributions
# Probably together with that one
include("factorgraph.jl")
export FactorGraph
include("core.jl")
export @model

end
