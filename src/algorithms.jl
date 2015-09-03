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
function reduced_factor(fct::Factor, newvars::Array{Variables, 1})
  # Get summed out variables
  summed_out = setdiff(fct.Scope, Y)
  # For ... in ...
  #TODO: Implement
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
