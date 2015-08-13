# Contingengy tables are factors too, they inherrit from factor
# Operations that contingency tables support
# should by supported by most factors too
#
#
module contingency

type Factor
  #dict, but Array might be ok too  #keys(var_to_idx) give variables
  var_to_idx #give position to internal location
  #Give position to function parameter
  var_to_fun_idx
  #the function that gets values for the variables and returns a value
  f
end


type contingency <: Factor

end


function


#CPTs are arrays, really
a = Array(Int64, 5,2,2,2)
a[:,:,:,1] = 52
a[:,:,:,2] = 53
print(a)








end
