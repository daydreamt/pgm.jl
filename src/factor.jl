# define the factor graph on top of a normal undirected graph

#require("Graphs")
using SimpleGraphs

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

pairs = [(1,3), (2,3), (3,4), (3,5)]

gd = graph(ExVertex[], ExEdge{ExVertex}[], is_directed=false)
map((x) -> add_vertex!(gd, string(x)), 1:5)
V = vertices(gd)
map((edg) -> add_edge!(gd, V[edg[1]], V[edg[2]]), pairs)

# GenericIncidenceList is best for the graph
priority = topological_sort_by_dfs(gd)
for vertex in priority
    idx = vertex.index
    # can now access in V[idx]
end

# So you just go through it topologically

#eds = Edge{Int}[Edge(i,p[1],p[2]) for (i,p) in enumerate(pairs)]
#gd = simple_edgelist(5, eds)

#gd = simple_inclist(length(pairs))
#for i = 1 : length(pairs)
#    a = pairs[i]
#    add_edge!(gd, a[1], a[2])   # add edge
#end


type FactorGraph
    Graph::GenericGraph{ExVertex,ExEdge{ExVertex},Array{ExVertex,1},Array{ExEdge{ExVertex},1},Array{Array{ExEdge{ExVertex},1},1}}
    Variables #is a list of hashmaps: Each one contains the #Edit: ???
    Factors #a mapping of node_id to {:nodes=>list_of_specific_order, :factor=>function(nodes)}

end
