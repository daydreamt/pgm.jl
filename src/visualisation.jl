require GraphViz

function make_dot(params, hyperparams, consts, name)
  u = merge(consts, params, hyperparams)

  s = string("graph ", name, " {")
  # Take each variable by turn
  for (varname, set) in u
    println("Variable with name: ", varname)
    for var in set
      println("index: ", var[2], " distribution and deps: ", var[7]) #TODO: MultivariateNormal(mu[z[i]],sig[z[i]]) needs splitting to a tuple (Dist, deps) and only deps need replacing
      for othervar in var[7][2]
        s = string(s, othervar, " -> ", var, "\n")
      end
    end
  end

  s = string(s, "}")
end

function plot_graph(params, hyperparams, consts, name)

  return Graph(make_dot(params, hyperparams, consts, name))
end
