# Some algorithms operating on factors
function compute_Z_brute_force(fct::DiscreteFactor)
  vars = fct.Scope
  Z = 0
  for tuple in apply(product, (map(x->tuple(values(x.d)...), vars)))
    Z += apply(fct.f, tuple)
  end
  return Z
end

function normalize(fct::DiscreteFactor)
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
  return DiscreteFactor(vars, fnew)
end

# Return a reduced factor
function reduced_factor(fct::Factor, newvars::Array{Variable, 1})
  fullvars = fct.Scope
  # Get summed out variables
  summed_out = setdiff(fullvars, Y)
  # Get their indexes
  idxes = Int[]
  for (idx, v) in enumerate(fullvars)
    if v in summed_out
      push!(idxes, idx)
    end
  end

  if length(newvars) == length(fullvars)
    return fct
  else
    # The returned factor function gets only the newvars as arguments
    function f(newxs...)
      @assert length(newxs) == length(newvars)
      res = 0

      # enumerate the summed out variables
      for tuple in apply(product, (map(x->tuple(values(x.d)...), summed_out)))
        println(tuple)
        # Get them in their correct order
        this_will_be_a_tuple = []
        cur_idx = 1 # On the idxes array
        #for (idx, t) in enumerate(tuple)
        #  while
      end
      # apply the old factor and sum
    end
  end

end

function factor_product(fct1::Factor, fct2::Factor)

  V1 = fct1.Scope
  V2 = fct2.Scope

  Y = intersect(V1, V2)
  X = setdiff(V1, Y)
  Z = setdiff(V2, Y)
  #TODO
  # Now there are two approaches possible
  # i) For finite factors you can precompute every value, make a table, have a function return one of those
  # ii) Or, you can return a function here that does the work at runtime.
  # I think I am going with ii) for the time being.
  # function ff(ys...)
  #   #The expected parameters
  #   @assert length(Y) == length(ys)
  #   return sum_out(fct1.f, Y, ys) * sum_out(fct2.f, Z, ys)
  # end
  # return Factor(Y, ff)
end
