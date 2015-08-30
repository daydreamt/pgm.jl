How would you write a factor type?

For discrete Factors, I something like that would be enough
type Factor
	Scope::Array{String}
	Table # of length 2^length(Scope) when binary variables etc
end
 where scopes gives the names and the values for combinations are then in increasing order for each configuration.

For other functions (with real valued or infinite domains etc), I guess you could give a function that returns a value for all variable configurations.
type Factor
	Scope::Array{Variables} # Where variables have a domain field
	factor::(Variables_in_some_form -> R)
end

However, for that the signature of the factor function should be decided on.

Three candidates:
```julia


              f((a,b)) #Ugly, easy to implement with f(params)
              f(a=1,b=2,...) #Good for smaller graphs, cumbersome and meaningless for large generated graphs. Didn't I use that in @model?
              f(a,b) # I prefer that, ooh, look, apply(f,params)
```

I think I am going with the third.

