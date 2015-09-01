How would you write a factor type?



For all functions (either with discrete, or even with real valued or infinite domains etc), I guess you could give a function f that returns a value for all variable configurations.
```julia
type Factor
	Scope::Array{Variables, 1} # Where variables must have a domain field
	f::(Variables_in_some_form -> R)
end
```

This is the most general form, good for both discrete and continuous functions.
The manipulation of products and automatic merging of factors might be tricky in that case, but we will work around it.


For discrete Factors, I something like that would be enough and probably more suitable.
```julia
type DiscreteFactor
	Scope::Array{Variables, 1}
	Table # of length == reduce(+, map(var->length(var.d), scope)
end
```

In practice, it has a factor function too.

```julia
type DiscreteFactor
	Scope::Array{Variables, 1}
	Table # of length == reduce(+, map(var->length(var.d), scope)
	f::(Variables_in_some_form -> R)

end
```

Both are subtypes of the AbstractFactor type.



For the signature of the factor function, I am going with
```julia
              f(a,b) # I prefer that, ooh, look, apply(f,params)
```


The ideal case for me would be to use this form everywhere I want to, and for the
users making factor graphs maybe a convenience function could be made:

It takes a function f(a,b,c...) that takes the parameters in a strict order,
returns a function f(a=0,b=0,c=0,...) that takes keyword arguments.

I currently do not know how to write that function.
