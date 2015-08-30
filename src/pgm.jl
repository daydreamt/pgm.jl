module pgm

using Iterators.product

#This would be a prime candidate for decoupling
include("factor.jl")
export Domain, Variable, Factor, supported_distributions
# Probably together with that one
include("factorgraph.jl")
export FactorGraph
include("core.jl")
export @model

end
