# define the factor graph on top of a normal undirected graph

module factor

using LightGraphs
import Graphs # For the cliques #and connected_components
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

      if !(typeof(var[7]) in [Symbol, Int64, Int])
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

  dependency_graph = g

  # Factors can be retrieved from the dependency_graph
  # Factors are just cliques, right?
  # Maybe they are connected components?
  # Maybe subgraphs of some sort?

  #so get the cliques, but build the Graphs graph first
  s = Graphs.simple_graph(nv(g), is_directed=LightGraphs.is_directed(g))
  for e in LightGraphs.edges(g)
    Graphs.add_edge!(s,src(e), dst(e))
  end
  cliques = Graphs.maximal_cliques(s)

  #Also the strongly connected components
  components = Graphs.connected_components(s)

  println(full(adjacency_matrix(g)))
  println(" -----       Cliques              ------")
  println(cliques)
  println(" ----        Components            -----")
  println(components)

  return FactorGraph(g, lookup_map, {})
end


end
