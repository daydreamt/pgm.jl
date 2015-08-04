# define the factor graph on top of a normal undirected graph

module factor

using LightGraphs
using GraphLayout

export FactorGraph, mk_factor_graph

# Probably not needed anymore, LightGraphs probably has those
function getParents(g, vertex)
    res = Set()
    for edge in g.edges
        s = edge.source
        t = edge.target
        if (t.label == vertex) push!(res, s)
        end
    end
    return res
end

function getChildren(g, vertex)
    res = Set()
    for edge in g.edges
        s = edge.source
        t = edge.target
        if (s.label == vertex) push!(res, t)
        end
    end
    return res
end

#use bfs_tree to traverse now

type FactorGraph
    G::Graph # The data structure on which we are operating
    Variables #is a list of hashmaps: Each one contains the mapping from variable name to node id
    Factors #a mapping of node_id to {:nodes=>list_of_specific_order, :factor=>function(nodes)}
end

# Given the params a model returns, build a factor graph
# Bipartite graph, factors are nodes, variables are nodes
# This function expects a params returned from a model and then postprocessed so that
#
function mk_factor_graph(params)
  g = Graph()
  lookup_map = Dict{String, Integer}()

  # Take each variable by turn
  for (varname, set) in params
    for var in set

      fullvarname = string(varname, "_",  var[2]) #the index

      if !haskey(lookup_map, fullvarname)
        lookup_map[fullvarname] = add_vertex!(g)
      end

      #TODO: Add every one of those to the factor. The factor from the rhs of a ~ expression is probably unique
      # But what is the factor? Is
      if !(typeof(var[7]) in [Symbol, Int64, Int]) #Maybe the whole factor at once?
        #println("trying var", var[7], " with type ", typeof(var[7]))
        for othervar in var[7][2]
          ov = string(othervar)
          if contains(ov, "[")
            ov = replace(replace(ov, "[", "_"), "]", "")
          end
          if !haskey(lookup_map, ov)
            lookup_map[ov] = add_vertex!(g)
          end
          add_edge!(g, lookup_map[ov], lookup_map[fullvarname])
        end
      end
    end
  end
  return FactorGraph(g, lookup_map, {})
end


end
