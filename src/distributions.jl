module distributions

export supported_distributions

# For shits and giggles
using Distributions
import Distributions.rand

# Let's say all variables will have a state and domain
type Domain
	from::Int
	to::Int
end

#Test
function rand(d::Domain)
	du = Distributions.Uniform(d.from, d.to)
	return rand(du)
end

# What do I have to do with them?
# Just pass them on to the factor function
# So that it is a known one.

supported_distributions = {:Categorical=>{:parameters=>1}, :MultivariateNormal=>{:parameters=>2}}

# The other functions and the functionality of this module I must think about

end
