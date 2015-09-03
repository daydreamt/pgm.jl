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
import Base.intersect

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

function hash(d1::Domain)
  return hash(d1.from, hash(d1.to, hash(d1.discrete, hash(d1.interval, hash(d1.allvals)))))
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

# Should I identify variables by some sort of id instead?
# http://stackoverflow.com/a/24546757
type Variable
  name::String
  d::Domain
  Variable(n::String, d::Domain) = new(n,d)
  Variable(n::String) = new(n, Domain(0,1)) #Binary
  Variable(n::Int) = new(string(n), Domain(0,1)) #Binary
end


function ==(v1::Variable, v2::Variable)
  return v1.name == v2.name && v1.d == v2.d
end

function isequal(v1::Variable, v2::Variable)
  return v1.name == v2.name && v1.d == v2.d
end

function hash(v1::Variable)
  return hash(v1.name, hash(v1.d))
end

# Do I need that, or does it work out of the box?
#function intersect(v1s::Array{Variable, 1}, v2s::Array{Variable, 2})
#  res = Variable[]
#  for var in v1s
#    if var in v2s
#      push!(var, res)
#    end
#  end
#  return res
#end

# How can ensure all factors have a Scope and f subfields?
# I don't think I can, but they should be!
abstract AbstractFactor

type Factor <: AbstractFactor
  Scope::Array{Variable, 1} # Variables, in a strict order
  f #function that maps:  Scope -> R (or N, have not decided yet)
  Factor(scope, f) = new(scope, f)
end


type DiscreteFactor <: AbstractFactor
  Scope::Array{Variable, 1} # Variables, in a strict order
  Table # We have discrete variables, let's try that.
  f # We can make the f function from the table!
  #Full constructor
  DiscreteFactor(scope::Array{Variable, 1}, f) = new(scope, None, f)
  DiscreteFactor(scope::Array{Variable, 1}, table,f) = new(scope, table, f)

  function DiscreteFactor(scope::Array{Variable, 1}, table::Array{Int64,1})
    @assert length(table) == reduce(*, map(var->length(var.d), scope))
    #We only need to make the function f now that maps variable instances to a table index

    # Map the variable with value val and idx var_idx to its position in the table
    function find_idx(var_idx, val)
      for (res_idx, other_val) in enumerate(values(scope[var_idx].d))
        if other_val == val
          return res_idx
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

      final_idx = 0
      i = length(xs)
      weight = 1
      while(i>=1)
        final_idx += (idxes[i] - 1) * weight
        weight = length(scope[i].d) * weight
        i-=1
      end

      final_idx += 1 #Start from 1 in julia

      return table[final_idx]
    end

    new(scope, table, f) #Or only f ;-)
  end

  #--------------------------
  # Convenience constructors
  # -------------------------
  # A single table
  function DiscreteFactor(table::Array{Int64,1})
    l = length(table);
    if ((l & (l - 1)) != 0)
      error("Please give a table of length power of two") #TODO: Power of two is only good for all variables binary...
    else
      # Now we assume all variables are binary

      DiscreteFactor([Variable(string(char(x))) for x in 65:(65+int(log2(l))-1)], table)
    end
  end

  #Strings make binary variables that are binary
  function DiscreteFactor(vars::Array{ASCIIString, 1}, table::Array{Int64,1})
    fct = DiscreteFactor(table)
    assert(length(vars) == length(fct.Scope))
    fct.Scope = map(Variable, vars)
    return fct
  end

end

# You can only prove they are equivalent
function ==(f1::Factor, f2::Factor)
  f1.Scope == f2.Scope  && f1.f == f2.f
end

function ==(f1::DiscreteFactor, f2::DiscreteFactor)
  f1.Scope == f2.Scope && f1.Table == f2.Table
end

# Given an array of variables, and a function that for every configuration
# of them returns a value generate a factor
# This is probably useless now
function generate_factor(vars::Array{Variable, 1}, f)
  assert(length(vars) == f.env.max_args)
  #for tuple in possible configurations
  res = Int[]
  for tuple in apply(product, (map(x->tuple(values(x.d)...), vars)))
    push!(res, apply(f, tuple))
  end

  return DiscreteFactor(vars, res)
end

############################################
# Part 2: Mapping of distribution to factors
############################################
supported_distributions = {:Categorical=>{:parameters=>1}, :MultivariateNormal=>{:parameters=>2}}



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


# The other functions and the functionality of this module I must think about
