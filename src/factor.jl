#=
This file contains a factor graph library for pgm.jl
It could/would/should be swapped with a more efficient C++/GPU one in the
future for inference and training purposes but for now it will do.

The Distributions module we will wrap (for the DSL) should be converted to
factors too. We will wrap them here.
=#

using Distributions
import Distributions.rand
import Base.values
import Base.isequal
import Base.==
import Base.length
using Iterators
import Iterators.product

export Domain, Variable, Factor, supported_distributions, generate_factor

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

function length(d::Domain)
  return 1 + d.to - d.from
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
      return d.from:d.to
    else
      error("Bad domain specification.")
    end
end


type Variable
  name::String
  d::Domain
end

# How can I give this type the Scope and f subfields?
abstract AbstractFactor

type Factor
  Scope::Array{Variable, 1} # Variables, in a strict order
  f #function that maps:  Scope -> R (or N, have not decided yet)
  Factor(scope, f) = new(scope, f)
end


type DiscreteFactor #:< Factor #Hm... should I just make a discrete factor?
  Scope::Array{Variable, 1} # Variables, in a strict order
  Table # We have discrete variables, let's try that.
  f # We can make the f function from the table!
  #Full constructor
  DiscreteFactor(scope, table,f) = new(scope, table, f)

  function DiscreteFactor(scope::Array{Variable, 1}, table)
    @assert length(table) == reduce(+, map(var->length(var.d), scope))
    #We only need to make the function f now that maps variable instances to a table index

    # Map the variable with value val and idx var_idx to its position in the table
    function find_idx(var_idx, val)
      for (res_idx, other_val) in enumerate(values(Variable[var_idx].d))
        if other_val == val
          return res
        end
      end
      error("variable not in there")
    end

    #For variable in variables
    # reduce(+ , map(find_idx, _VARIABLES_OF_FUNCTION_PROGRAMMATICALY_))

    function f(xs...)
      @assert length(scope) == length(xs)
      # Now every parameter in xs is in the same position as in array
      # Find its index for its given value in its domain
      idxes = Int[]
      for (var_idx, val) in enumerate(xs)
        push!(idxes, find_idx(var_idx, val))
      end
      println(idxes)

      final_idx = reduce(+, idxes)
      println(final_idx)

      return final_idx
    end

    new(scope, table, f) #Or only f ;-)
  end

    # A single table
  function DiscreteFactor(table::Array{Int64,1})
    l = length(table);
    if ((l & (l - 1)) != 0)
      error("Please give a table of length power of two") #Power of two is only good for all variables binary...
    else
      DiscreteFactor([range(0, int(log2(l)))], table)
    end
  end

  #Named variables
  function DiscreteFactor(Vars::Array{ASCIIString, 1}, table::Array{Int64,1})
    fct = DiscreteFactor(table)
    assert(length(Vars) == length(fct.Scope))
    fct.Scope = Vars
    return fct
  end

  #From variables with finite domains
  #TODO: What happens with the order of the given factors here?
  function DiscreteFactor(Vars::Array{Variable, 1}, table::Array{Int64,1})
    names = map(x -> x.name, Vars)

    #Assert the given configurations are equal to all possible configurations
    total_domains = 0
    for var in Vars
        if (!var.d.discrete || !var.d.interval)
          error("Sorry, discrete interval variables only for now")
        end
        total_domains += var.d.to - var.d.from + 1
    end

    if length(table) != total_domains
        error("Bad table given")
    end

    # Finally, make a factor with that
    return DiscreteFactor(names, table)

  end
end


function ==(f1::Factor, f2::Factor)
  f1.Scope == f2.Scope  && f1.f == f2.f
end

function ==(f1::DiscreteFactor, f2::DiscreteFactor)
  f1.Scope == f2.Scope && f1.Table == f2.Table && f1.f == f2.f
end


# Given an array of variables, and a function that for every configuration
# of them returns a value generate a factor
function generate_factor(vars::Array{Variable, 1}, f)
  assert(length(vars) == f.env.max_args)
  #for tuple in possible configurations
  res = Int[]
  for tuple in apply(product, (map(x->tuple(values(x.d)...), vars)))
    push!(res, apply(f, tuple))
  end

  return DiscreteFactor(vars, res)
end



supported_distributions = {:Categorical=>{:parameters=>1}, :MultivariateNormal=>{:parameters=>2}}
#=
# Contingengy tables are factors too, they inherrit from factor
# Operations that contingency tables support
# should by supported by most factors too
function contingency() #Could return a factor I think, subtyping not neccessary
end


#CPTs are arrays, really
a = Array(Int64, 5,2,2,2)
a[:,:,:,1] = 52
a[:,:,:,2] = 53

# What do I have to do with them?
# Just pass them on to the factor function
# So that it is a known one.
=#

# The other functions and the functionality of this module I must think about
