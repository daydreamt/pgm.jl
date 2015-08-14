module factor
#Factors, yo, they wrap too
using Distributions
import Distributions.rand
import Base.values

export Domain, Variable, Factor, supported_distributions

type Domain
	from::Int
	to::Int
  discrete::Bool
  interval::Bool #Whether it contains every value from from to to
  allvals #Set of all values. Probably redudant

  Domain(from::Int, to::Int) = from > to ? error("invalid interval") : new(from, to, true, true, nothing)
  Domain(vals::Set{Int}) = new(minimum(vals), maximum(vals), true, false, vals)
  Domain(vals::Array{Int, 1}) = Domain(Set{Int}(vals))

end

function rand(d::Domain)
  res = nothing
  if d.interval
    if d.discrete
      du = Distributions.DiscreteUniform(d.from, d.to)
    else
      du = Distributions.Uniform(d.from, d.to)
    end
    res = rand(du)
  else
    res = sample(allvals)
  end

	return res
end


#Bad name: returns all possible values of a domain
function values(d::Domain)
    if d.allvals != nothing
      return allvals
    elseif d.discrete && d.interval
      return range(d.from, d.to)
    else
      error("Bad domain specification.")
    end
end

type Variable
  name::String
  d::Domain
end

type Factor
  Scope
  f #The function Scope -> R_+
  Table # potentially in table form too?
  #dict, but Array might be ok too  #keys(var_to_idx) give variables
  var_to_idx #give position to internal location
  #Give position to function parameter
  var_to_fun_idx
  #the function that gets values for the variables and returns a value

end

# Contingengy tables are factors too, they inherrit from factor
# Operations that contingency tables support
# should by supported by most factors too
function contingency() #Could return a factor I think, subtyping not neccessary
end



#CPTs are arrays, really
a = Array(Int64, 5,2,2,2)
a[:,:,:,1] = 52
a[:,:,:,2] = 53
print(a)

# What do I have to do with them?
# Just pass them on to the factor function
# So that it is a known one.


println(Domain(2,5))
println(Domain(Int[1,2,4,5]))


supported_distributions = {:Categorical=>{:parameters=>1}, :MultivariateNormal=>{:parameters=>2}}

# The other functions and the functionality of this module I must think about


end
