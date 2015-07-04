module pgm

export @model

# For shits and giggles
using Distributions
import Distributions.rand

# Let's say all variables will have a state and domain
type Domain
	from::Int
	to::Int
end

#Test
function rand(d::Domain)
	du = Distributions.Uniform(d.from, d.to)
	return rand(du)
end
function parse_from_to(expr)
    println(expr)
    tp = nothing
    from = expr.args[2]
    to = expr.args[3]
    if (typeof(from) != Symbol)
        tp = typeof(from)
    elseif (typeof(from) != Symbol)
        tp = typeof(to)
    end

    return from, to, tp
end

function parse_dims(expr)
    dim1 = 1
    dim2 = 1
    if ((typeof(expr) != Expr) && (typeof(expr) == Symbol || isinteger(expr)))
        dim1 = expr
    elseif (length(expr.args) == 2)
        dim1 = expr.args[1]
        dim2 = expr.args[2]
    end

    return (dim1, dim2)
end

function pb(expr::Expr, idx=-1)
    s = string(expr)
    if (contains(s, ">>>=") || contains(s, ".//="))
        error("Sorry, you caught the dirty hack, can't parse that.")
    end
    expr = parse(replace(s, "::", ">>>=")) #Manipulate the precedence priority

    # If it is a block, replace it by the block's contents
    if (expr.head == :block)
        expr = expr.args[length(expr.args)]
    end

    # Left is now new
    l = expr.args[1]
    if (typeof(l) == Symbol) #Great, no array
        var = l
    else #array
        var = l.args[1]
        idx = l.args[2]
    end

    # Right is now the type
    # How do I macros in macros?
    expr = parse(replace(string(expr.args[2]), "^", ".//="))
    from = :inf
    to = :inf
    tp = nothing
    dims = nothing

    if (typeof(expr) == Symbol)
        tp = expr
    elseif (expr.head == :.//=)
        println(expr.args)
        # Left we either have the type# or from_to
        if (typeof(expr.args[1]) == Symbol)
            tp = expr.args[1]
        else
            from, to, tp = parse_from_to(expr.args[1])
        end
        # Right we have either one dimension, or 2
        dims = parse_dims(expr.args[2])
    elseif (expr.args[1] == :..)
        from, to, tp = parse_from_to(expr)

    else
        #println(expr.args)
    end

    return var, idx, from, to, tp, dims
end


function parse_pt(arg::Expr, consts, hyperparams, params, idx=-1)
    if(arg.args[1] == symbol("@constant"))
        (var, idx, from, to, tp, dims) = pb(arg.args[2], idx)
        if (!haskey(consts, var))
            consts[var] = Set()
        end
        push!(consts[var], (var, idx, from, to, tp, dims))
    elseif(arg.args[1] == symbol("@hyperparam"))
        (var, idx, from, to, tp, dims) = pb(arg.args[2], idx)
        if (!haskey(hyperparams, var))
            hyperparams[var] = Set()
        end
        push!(hyperparams[var], (var, idx, from, to, tp, dims))
    elseif(arg.args[1] == symbol("@param"))
        (var, idx, from, to, tp, dims) = pb(arg.args[2], idx)
        if (!haskey(params, var))
            params[var] = Set()
        end
        push!(params[var], (var, idx, from, to, tp, dims))
    else
    end

    return consts, hyperparams, params
end

macro dh(x, s)
    return esc(:($x = $s))
end

macro model(name, rest...)

    eval(:(model = $(string(name)))) #Set the current model in the global scope
    println(model)

    #TODO: By using arrays instead, and indexing by them you can save much space
    # No need for globalization! :-)

    #eval(:(consts = Dict())) # All of these should be specified
    #eval(:(hyperparams = Dict())) # When initializing for now
    #eval(:(params = Dict()))

    consts = Dict()
    hyperparams = Dict()
    params = Dict()

    c = 0
    u = 0

    # First pass to establish parameters
    for(i in rest) # For every top line
        if (typeof(i) == Expr) # If it is not a comment
            for (arg in i.args)
                if(typeof(arg) == Expr)
                    consts, hyperparams, params = parse_pt(arg, consts, hyperparams, params)
                end
            end
        end
    end

    # This closure expects them to create the function
    fparamnames = {}
    for k in keys(consts)
        push!(fparamnames,k )
    end
    for k in keys(hyperparams)
        push!(fparamnames, k)
    end

    println(fparamnames)
    # Generate the function paramters by a nice string concatenation
    s = ""
    for (idx, i) in enumerate(fparamnames)
        #s = s * "(" * string(i) * "=0)"
        s = s * string(i) * "=0"
        if (idx < length(fparamnames))
            s = s * ", "
        end
    end

    println(s)

    # I wish I had a better way to do that
    #s = parse(s)
    # s.head = :kw
    # println(s, " is of type ", typeof(s), s.head)
    #return :(function f((:($s))) println(5) end)
    #return function f(:(($fparamnames)...)) println(5))
    #q = quote
    #    function f2($s)
    #        println($s)
    #        println(5)
    #    end
    #end

    f = parse("function " * model * " (;" * s * ") println(5) end")
    f.args[2] =

    quote
        # Arguments: the model parameters. Returns success or false or something

        # Not even the dirty hack works. I am confused.
        #Initialize the arguments
        #for p in $fparamnames
        #  @dh(p, $p)
        #  val = eval($p)
        #  println(val)
        end

        #Stupid 2 pass, now parameters are established
        for(i in $rest) # For every top line
            if (typeof(i) == Expr) # If it is not a comment
                for (arg in i.args)
                    #println(arg)
                    if(typeof(arg) == Expr)
                        if(arg.head == :for) # We have a loop
                            boundary = arg.args[1]
                            loopvar = boundary.args[1]
                            lfrom = boundary.args[2].args[1]
                            lto = boundary.args[2].args[2]
                            contents = arg.args[2]
                            #println(boundary)
                            println(loopvar," ", typeof(loopvar)," ", lfrom, " ", typeof(lfrom), " ", lto, " ", typeof(lto))
                            #println(contents)

                            # For this part you need the defined fparamnames

                            #for k in lfrom:lto
                            #    for l in contents
                            #        println(l)
                            #consts, hyperparams, params = parse_pt(arg, consts, hyperparams, params, k)
                            #        parse_pt!(arg, k)
                            #    end
                            #end
                        else
                            #println("\"", arg, "\" which is of type:", typeof(arg)," has args of type: ", typeof(arg.args[1]))
                        end
                    end
                end
            end
        end

        if :d in ($fparamnames)
            println("The value of d is ", d)
        else
            print("no d")
        end

        # How do I get the value of a variable with a dynamic name?
        # http://julia-programming-language.2336112.n4.nabble.com/Macro-scoping-or-hygiene-problems-td10933.html
        # and https://groups.google.com/forum/#!topic/julia-users/BHwH1BRitRs *might* help
        for p in $fparamnames
          println(p)
        end

        return $consts, $hyperparams, $params

    end # End inner constructor function

    return f

end # End macro

end
