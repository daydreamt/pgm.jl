# Some algorithms operating on factors
function compute_Z_brute_force(fct::AbstractFactor)
  vars = fct.Scope
  Z = 0
  for tuple in apply(product, (map(x->tuple(values(x.d)...), vars)))
    Z += apply(fct.f, tuple)
  end
  return Z
end

function normalize(fct::AbstractFactor)
  vars = fct.Scope
  Z = 0
  min_val = 0

  # Compute minimum and normalization factor
  for tuple in apply(product, (map(x->tuple(values(x.d)...), vars)))
    val = apply(fct.f, tuple)
    Z += val
    min_val = min(min_val, val)
  end

  offset = 0
  if min_val < 0 then
    offset = -1 * min_val
  end

  function fnew(xs...)
    return (apply(fct.f, (xs)) + offset) / (Z + length(vars) * offset)
  end
  return Factor(vars, fnew)
end

# Return a reduced factor
function reduce_factor(fct::AbstractFactor, newvars::Array{Variable, 1})
  fullvars = fct.Scope
  # Get summed out variables
  summed_out = setdiff(fullvars, newvars)
  # and their indexes
  summed_out_idxes = Int[]
  # As well as the idxes from the new variables
  new_var_idxes = Int[]

  for (idx, v) in enumerate(fullvars)
    if v in summed_out
      push!(summed_out_idxes, idx)
    else
      @assert v in newvars # Potentially slow, n^2 slow
      push!(new_var_idxes, idx)
    end
  end
  @assert issorted(new_var_idxes)

  if length(newvars) == length(fullvars)
    return fct
  else
    # The returned factor function gets only the newvars as arguments
    function f(newxs...)
      @assert length(newxs) == length(newvars)

      array_that_will_be_tuple = zeros(Int, length(fullvars))
      # Initialize the newxs only once in the array
      for (idx, var) in enumerate(newxs)
        array_that_will_be_tuple[new_var_idxes[idx]] = var
      end

      # And
      res = 0

      # enumerate the summed out variables
      for t in apply(product, (map(x->tuple(values(x.d)...), summed_out)))

        for (idx, newvar) in enumerate(t)
          array_that_will_be_tuple[summed_out_idxes[idx]] = newvar
        end
        # apply the old factor and sum
        res += apply(fct.f, apply(tuple, array_that_will_be_tuple))
      end
      return res
    end
    return Factor(newvars, f)
  end

end

function factor_product(fct1::AbstractFactor, fct2::AbstractFactor)

  V1 = fct1.Scope
  V2 = fct2.Scope

  Y = intersect(V1, V2)
  X = setdiff(V1, Y)
  Z = setdiff(V2, Y)

  # Now there are two approaches possible
  # i) For finite factors you can precompute every value, make a table, have a function return one of those
  # ii) Or, you can return a function here that does the work at runtime.
  # We are going with ii) for the time being.

  function ff(ys...)
     #The expected parameters
     @assert length(Y) == length(ys)
     r1 = reduce_factor(fct1, X)
     r2 = reduce_factor(fct2, Z)

    return r1.f(ys) * r2.f(ys)
  end

  return Factor(Y, ff)
end
