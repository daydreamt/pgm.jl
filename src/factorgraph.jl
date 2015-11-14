# define the factor graph on top of a normal undirected graph
# The compiler functions are currently in here

using LightGraphs
import Graphs # For the cliques #and connected_components
using Graphs.strongly_connected_components_recursive
using GraphLayout

export FactorGraph

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
    Product::Bool

  # Make factorgraph the boring way, from an array of factors :-)
  function FactorGraph{Fct<:AbstractFactor}(factors::Array{Fct,1}, sum=false::Bool)
    # Get all variables
    vars = reduce(union, map(x->x.Scope, factors))
    # Make a graph, and add the factors as nodes first
    G = LightGraphs.Graph()
    Factors = Dict()
    Variables = Dict()

    fct2id = Dict() #temporary
    # Add factors
    for f in factors
      vertex_id = add_vertex!(G)
      Factors[vertex_id] = Dict{Any,Any}(:nodes=>Int[], :factor=>f) #TODO: Maybe only the factor function? Depends on their specification
      fct2id[f] = vertex_id
    end
    # Add variables, and variables to factors
    for f in factors
      for var in f.Scope
        # Add variable if it doesn't exist
        if !(haskey(Variables, var))
          var_id = add_vertex!(G)
          Variables[var] = var_id
        end
        var_id = Variables[var]
        # Add factor mapping
        push!(Factors[fct2id[f]][:nodes], var_id)
      end
    end
    return new(G, Variables, Factors, !sum)
  end

  # Given the params a model returns, build a factor graph
  # Bipartite graph, factors are nodes, variables are nodes
  # This function expects a params returned from a model and then postprocessed so that
  function FactorGraph(params)
    g = LightGraphs.DiGraph()
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
              ov = replace(replace(ov, "[", "_"), "]", "") #TODO: use parse_something
            end
            if !haskey(lookup_map, ov)
              lookup_map[ov] = add_vertex!(g) #TODO: Change order, as that graph is temporary
            end
            add_edge!(g, lookup_map[ov], lookup_map[fullvarname])
          end
        end
      end
    end

    dependency_graph = g
    if is_cyclic(dependency_graph)
      error("Not implemented yet, please give DAGs")
    end

    # Factors can be retrieved from the dependency_graph by noting that
    # Every node can form a factor, if it has incoming nodes
    ## (Explanation: If these incoming nodes do not have any dependencies then it is
    ## clear, if they do then the dependency is a factor, but we will still add the
    ## variable to the factor because that is how factor graphs work)

    #Uh oh, this complicates mapping from variables to nodes in the graphs though, I think. TODO:
    new_lookup_map = Dict{String, Integer}() #TOODLES
    old_graph_to_new = Dict{Int, Int}()
    old_id_to_nodes = Dict{Int, Array{Int}}()
    new_g = Graph()
    ff = Dict{Int, Any}()

    for v in vertices(dependency_graph)
        # Nodes with a edge towards v
        ns = filter(n->LightGraphs.Pair(n, v) in edges(dependency_graph), vertices(dependency_graph))
        if length(ns) != 0
          #Make a new factor
          factor_id = add_vertex!(new_g)
          # Add connections from all neighbours and v to it #TODO: Order is important
          for n in [ns; v]
            if !(n in keys(old_graph_to_new))
                neighbour_id = add_vertex!(new_g)
                old_graph_to_new[n] = neighbour_id
                # Also to the auxilliary data structure
                old_id_to_nodes[n] = Int[]
            end
            # The id of that node in the new graph
            neighbour_id = old_graph_to_new[n]

            add_edge!(new_g, neighbour_id, factor_id)
            push!(old_id_to_nodes[n], factor_id)
            ff[factor_id] = :FIXME_ORDER_OF_PARAMS
          end
        end
    end

    # println(" ----        Components            -----")
    # println(weakly_connected_components(g))

    return new(new_g, lookup_map, ff, true)
  end




end

