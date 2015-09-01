#From Koller and Friedman, 2009, Probabilistic graphical models: principles and techniques

f1 = DiscreteFactor(["a","b"], [30, 5, 1, 5])
f2 = DiscreteFactor(["b","c"], [100, 1, 1, 100])
f3 = DiscreteFactor(["c","d"], [1, 100, 100, 1])
f4 = DiscreteFactor(["d", "a"], [100, 1, 1, 100])

union(f4.Scope,f1.Scope)
reduce(union, map(x->x.Scope, [f1,f2,f3,f4]))

fg = FactorGraph([f1,f2,f3,f4], false)
fg.Variables

fg.Factors

# Log form. How should I best allow it? Allow factors be floats?
#f11 = Factor(["a","b"], [-3.4, -1.61, 0, -2.3])
#f22 = Factor(["b","c"], [-4.61, 0, 0, -4.61])
#f33 = Factor(["c","d"], [0, -4.61, -4.61, 0])
#f4 = Factor(["d", "a"], [-4.61, 0, 0, -4.61])


