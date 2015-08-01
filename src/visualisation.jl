using GraphViz

function make_dot(params, hyperparams, consts, name)
    u = merge(consts, params, hyperparams)

    s = string("digraph ", name, " {")
    # Take each variable by turn
    for (varname, set) in u
        #println("Variable with name: ", varname)
        for var in set
            #println("index: ", var[2], " distribution and deps: ", var[7], typeof(var[7]))
            if !(typeof(var[7]) in [Symbol, Int64, Int])
                #println("trying var", var[7], " with type ", typeof(var[7]))
                for othervar in var[7][2]
                    ov = string(othervar)
                    if contains(ov, "[")
                        ov = replace(replace(ov, "[", "_"), "]", "")
                    end
                    s = string(s, ov, " -> ", varname, "_", var[2], ";\n")
                end
            end
        end
    end

    s = string(s, "}")

    #println("---------")
    #println(s)

    return s
end

function plot_graph(params, hyperparams, consts, name)
    return Graph(make_dot(params, hyperparams, consts, name))
end
