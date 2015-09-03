using Base.Test
using pgm
# Domains
d1 = Domain(2,5)
d2 = Domain(2,5,true,true,nothing)
@test isequal(d1,d2)
@test d1 == d2
@test length(d1) == 4

@test Domain(2,5) == Domain(Int[2,3,4,5])
@test Domain(Int[2,3,4,5]) == Domain(2,5)
@test Domain(Int[2,3,4,5]) != Domain(2,6)

#Variables
v1 = Variable("X", Domain(0,1))
v2 = Variable("Y", Domain(1,2))

v1eq = Variable("X")

@test v1 == v1eq
@test v2 == Variable("Y", Domain(1,2))

# Multiple ways to define Factors

function f(x, y)
  return ((x==1 && y==1) || (x== 0 && y == 2)) * 50 + 2
end
fct2 = DiscreteFactor(Variable[v1,v2], [2,52,52,2])

@test fct2.f(0,1) == 2
@test fct2.f(0,2) == 52
@test fct2.f(1,1) == 52
@test fct2.f(1,2) == 2

v3 = Variable("X", Domain(3,4))
v4 = Variable("Y", Domain(5,6))
v5 = Variable("X", Domain(0,1))

@test v1 == v5
@test isequal(v1,v5)
@test hash(v1) == hash(v5)
@test v1 in intersect( Variable[v1,v2], Variable[v3,v4,v5])

@test symdiff(Variable[v1,v2], Variable[v3,v4,v5]) == Variable[v2,v3,v4]
symdiff(Variable[v1,v2], Variable[v3,v4,v5])

fct0 = DiscreteFactor(Variable[v3,v4], [100,-100,-100,100])
@test v3 in fct0.Scope
@test v4 in fct0.Scope

@test fct0.f(3,5) == 100
@test fct0.f(3,6) == -100
@test fct0.f(4,5) == -100
@test fct0.f(4,6) == 100
@test compute_Z_brute_force(fct0) == 0


f1 = DiscreteFactor(["a","b"], [30, 5, 1, 5])

fct1 = DiscreteFactor([2,52,52,2])
@test compute_Z_brute_force(fct1) == 108
fct1n = normalize(fct1)
@test fct1n.f(0,0) == fct1n.f(1,1) == 2/ 108
@test fct1n.f(0,1) == fct1n.f(1,0) == 52 /108

#Disagreement more likely factor with two variables (4 = 2^2)
fct3 = DiscreteFactor(["X","Y"],[2,52,52,2])
fct4 = generate_factor([v1,v2], f)
#And with three variables
DiscreteFactor([2, 50, 50, 50, 50, 50, 50, 2])


#FIXME: Equality not completely working
#@test fct1 == DiscreteFactor([0,1], [2,52,52,2])
#@test fct1 == fct2 == fct3 == fct4
#f(x=2,y=2) #Named parameters not done yet.

