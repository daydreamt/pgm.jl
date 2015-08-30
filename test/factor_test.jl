using Base.Test

# Domains
d1 = Domain(2,5)
d2 = Domain(2,5,true,true,nothing)
@test isequal(d1,d2)
@test d1 == d2

@test Domain(2,5) == Domain(Int[2,3,4,5])
@test Domain(Int[2,3,4,5]) == Domain(2,5)
@test Domain(Int[2,3,4,5]) != Domain(2,6)


#Variables
v1 = Variable("X", Domain(0,1))
v2 = Variable("Y", Domain(1,2))

# Multiple ways to define Factors
fct1 = Factor([2,52,52,2])
@test fct1 == Factor([0,1], [2,52,52,2],nothing) #Disagreement more likely factor with two variables (4 = 2^2)

fct2 = Factor(Variable[v1,v2], [2,52,52,2])

fct1.Scope = ["X","Y"]
fct3 = Factor(["X","Y"],[2,52,52,2])
@test fct1 == fct2 == fct3

Factor([2, 50, 50, 50, 50, 50, 50, 2]) #And with three



#=
function f(;x=0,y=0)
  return (x==y) * 50 + 2
end

Variable("X",Domain(0,1))
Variable("Y",Domain(0,1))
f(x=2,y=2)
=#
