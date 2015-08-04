using GraphLayout
using factor

if (OS_NAME != :Windows)
  using GraphViz
  function make_dot(params, name)

      s = string("digraph ", name, " {")
      # Take each variable by turn
      for (varname, set) in params
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

  function plot_graph(params, name)
      return Graph(make_dot(params, name))
  end
end

function save_svg(g::FactorGraph, name)
  am = full(adjacency_matrix(g.G))
  loc_x, loc_y = layout_spring_adj(am)
  draw_layout_adj(am, loc_x, loc_y, filename=name)
end
