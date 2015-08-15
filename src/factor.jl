module factor
#Factors, yo, they wrap distributions too
using Distributions
import Distributions.rand
import Base.values
import Base.isequal
import Base.==


export Domain, Variable, Factor, supported_distributions

type Domain
	from::Int
	to::Int
  discrete::Bool
  interval::Bool #Whether it contains every value from from to to
  allvals #Set of all values. Probably redudant
  #TODO: This is 1d. to agree with pgm.pb, maybe more dimensions
  Domain(from::Int, to::Int) = from > to ? error("invalid interval") : new(from, to, true, true, nothing)
  Domain(vals::Set{Int}) = new(minimum(vals), maximum(vals), true, vals == Set(range(minimum(vals), maximum(vals) - 1)), vals)
  Domain(vals::Array{Int, 1}) = Domain(Set{Int}(vals))
  Domain(from::Int, to::Int, d::Bool, i::Bool, allvals) = new(from, to, d, i, allvals)

end


function ==(d1::Domain, d2::Domain)
  d1.from == d2.from && d1.to == d2.to && d1.discrete == d2.discrete && d1.interval == d2.interval && ((d1.interval && d1.discrete) || d1.allvals == d2.allvals)
end

function isequal(d1::Domain, d2::Domain)
  isequal(d1.from, d2.from) && isequal(d1.to, d2.to) && isequal(d1.discrete, d2.discrete) &&
  isequal(d1.interval, d2.interval) && ((d1.interval && d1.discrete) || isequal(d1.allvals, d2.allvals))
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
#print(a)

# What do I have to do with them?
# Just pass them on to the factor function
# So that it is a known one.

supported_distributions = {:Categorical=>{:parameters=>1}, :MultivariateNormal=>{:parameters=>2}}

# The other functions and the functionality of this module I must think about


end
