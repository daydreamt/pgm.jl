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
        if idx == -1
            idx = l.args[2]
        end
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

    # Clean up
    if dims == nothing || dims == 1
        dims = (1,1)
    end
    #TODO: Think about concrete types. Inference will be hard for large domains.
    typelookup = Dict()
    typelookup[:float64] = Float64
    typelookup[:Float64] = Float64
    typelookup[:int] = Int
    typelookup[:Integer] = Int64
    typelookup[:integer] = Int64

    if haskey(typelookup, tp)
      tp = typelookup[tp]
    end
    return var, idx, from, to, tp, dims
end
function parse_pt(arg::Expr, consts, hyperparams, params, idx=-1, distvalue=None)

    before = (length(consts), length(hyperparams), length(params))

    if(arg.args[1] in Set{Symbol}([symbol("@constant"),  symbol("@hyperparam"), symbol("@param")]))
        (var, idx, from, to, tp, dims) = pb(arg.args[2], idx)

        if(arg.args[1] == symbol("@constant"))
          if (!haskey(consts, var))
              consts[var] = Set()
          end
          push!(consts[var], (var, idx, from, to, tp, dims, :const))

        elseif(arg.args[1] == symbol("@hyperparam"))
          if (!haskey(hyperparams, var))
              hyperparams[var] = Set()
          end
          push!(hyperparams[var], (var, idx, from, to, tp, dims, :hyperparam))
        elseif(arg.args[1] == symbol("@param"))
          if (!haskey(params, var))
              params[var] = Set()
          end
          push!(params[var], (var, idx, from, to, tp, dims, :unk))
        else
          println("This should not happen")
        end


    elseif(arg.head == :macrocall)

      if arg.args[1] == symbol("@~") # type foo ~ bar
        (var, idx, from, to, tp, dims) = pb(arg.args[2], idx)
        #(var, idx, from, to, tp, dims, _) = parse_pt(Expr(:macrocall, :@param, arg.args[2]), consts, hyperparams, params, idx, arg.args[3])
        if (!haskey(params, var))
              params[var] = Set()
        end
        push!(params[var], (var, idx, from, to, tp, dims, arg.args[3]))
      end

    else
      if arg.head != :line
        println("parse_pt called with something not a line: ", arg.head)
        #println(arg.args)
      end
    end

    after = (length(consts), length(hyperparams), length(params))
    if before != after && false
        println("Changed params")
    end
    return consts, hyperparams, params
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

    f = parse("function " * model * " (;ks... ) end")
    f.args[2] =

    quote
        # Arguments: the model parameters. Returns success or false or something
        #Initialize the arguments

        #Stupid 2 pass, now parameters are established

        #TODO: FIRST REPLACE THE PARAMETERS IN PARAMS, CONSTANTS, HYPERPARAMS WITH THE GIVEN ONES

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
                            println(loopvar," ", typeof(loopvar)," lfrom: ", lfrom, " ", typeof(lfrom), " lto: ", Dict(ks)[symbol(lto)], " ", typeof(lto))
                            #println(contents)

                            # For this part you need the defined fparamnames, which are given to the constructor

                            for k in lfrom:Dict(ks)[symbol(lto)]
                                #println(contents)
                                for l in contents.args
                                    if (typeof(l) == Expr) # If it is not a comment
                                        println("------start------")
                                        println(l, " ", typeof(l.head))
                                        #println("**")
                                        #println(l.head)
                                        #println(l.args)
                                        consts, hyperparams, params = parse_pt(l, $consts, $hyperparams, $params, k)
                                        #TODO: If type == bla ~ blu then ...
                                        #end
                                        println("------end-------")
                                    end
                                #    consts, hyperparams, params = parse_pt(arg, consts, hyperparams, params, idx=k)
                                 end
                            end
                        else
                            #println("\"", arg, "\" which is of type:", typeof(arg)," has args of type: ", typeof(arg.args[1]))
                        end
                    end
                end
            end
        end

        return $consts, $hyperparams, $params

    end # End inner constructor function

    return f

end # End macro


end
