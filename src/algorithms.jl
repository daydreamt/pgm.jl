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

function factor_product(fct1::Factor, fct2::Factor)

  V1 = fct1.Scope
  V2 = fct2.Scope

  C = intersect(fct1.Scope, fct2.Scope)
  #TODO

end

