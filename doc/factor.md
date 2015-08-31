How would you write a factor type?



For all functions (either with discrete, or even with real valued or infinite domains etc), I guess you could give a function that returns a value for all variable configurations.
```julia
type Factor
	Scope::Array{Variables, 1} # Where variables must have a domain field
	factor::(Variables_in_some_form -> R)
end
```

This is the most general form, good for both discrete and continuous functions.
The manipulation of products and automatic merging of factors might be tricky in that case, but we will work around it.


For discrete Factors, I something like that would be enough and probably more suitable.
```julia
type Factor
	Scope::Array{Variables, 1}
	Table # of length == reduce(+, map(var->length(var.d), scope)
end
```

 where scopes gives the names and the values for combinations are then in increasing order for each configuration.



Can I make them both from an abstract type?


However, for that the signature of the factor function should be decided on.

Three candidates:
```julia


              f((a,b)) #Ugly, easy to implement with f(params)
              f(a=1,b=2,...) #Good for smaller graphs, cumbersome and meaningless for large generated graphs. Didn't I use that in @model?
              f(a,b) # I prefer that, ooh, look, apply(f,params)
```

I think I am going with the third.

The ideal case for me would be to use the third form everywhere I want to, and for the
users making factor graphs maybe a convenience function could be made:

It takes a function f(a,b,c...) that takes the parameters in a strict order,
returns a function f(a=0,b=0,c=0,...) that takes keyword arguments.

I currently do not know how to write that function.
