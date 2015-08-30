module pgm

include("factor.jl")
export Domain, Variable, Factor, supported_distributions
include("factorgraph.jl")
export FactorGraph, mk_factor_graph
include("core.jl")
export @model

end
