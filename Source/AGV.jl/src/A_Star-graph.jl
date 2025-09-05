"""
$(TYPEDSIGNATURES)

Takes a couple of vertices forming an edge and return the index of that index in the weight matrix of the graph. Or nothing if that edge does not exist.
"""
# FOR GENERIC GRAPHS!!!
@inline function vertices2edgenum(
    G::SimpleWeightedDiGraph,
    edge_start_vertex::Int64,
    edge_final_vertex::Int64,
)
    row_index_beg = G.weights.colptr[edge_start_vertex]
    row_index_end = G.weights.colptr[edge_start_vertex+1] - 1

    n = findfirst(isequal(edge_final_vertex), G.weights.rowval[row_index_beg:row_index_end])

    return isnothing(n) ? nothing : row_index_beg + n - 1
end


"""
$(TYPEDSIGNATURES)

"""
@inline vertices2edgenum(G::SimpleWeightedDiGraph, src::UInt64, dst::UInt64) =
    vertices2edgenum(G, Int64(src), Int64(dst))

# FOR THE DIRECTED INVERTED GRAPHS!!!
"""
$(TYPEDSIGNATURES)

"""
vertices2edgenum(src::UInt64, dst::UInt64, ctx::TContext) =
    vertices2edgenum(ctx.G3DT, Int64(src), Int64(dst))
vertices2edgenum(src::Int64, dst::Int64, ctx::TContext) =
    vertices2edgenum(ctx.G3DT, src, dst)
vertices2edgenum(pair_v::Tuple{UInt64,UInt64}, ctx::TContext) =
    vertices2edgenum(ctx.G3DT, Int64(pair_v[1]), Int64(pair_v[2]))
vertices2edgenum(pair_v::Tuple{Int64,Int64}, ctx::TContext) =
    vertices2edgenum(ctx.G3DT, pair_v[1], pair_v[2])

# For list of pairs
"""
$(TYPEDSIGNATURES)

"""
@inline function vertices2edgenum(pairs::Vector{}, ctx::TContext)
    results = Int64[]
    for p in pairs
        i = vertices2edgenum(p, ctx)
        if !isnothing(i)
            push!(results, i)
        end
    end
    return results
end


"""
$(TYPEDSIGNATURES)

Takes a couple of vertices forming an edge and return the weight of that edge in the weight matrix of the graph. Or nothing if that edge does not exist.
"""
@inline function vertices2weight(G::SimpleWeightedDiGraph, src::Int64, dst::Int64)
    index = vertices2edgenum(G, src, dst)

    return isnothing(index) ? nothing : G.weights.nzval[index]
end

@inline vertices2weight(G::SimpleWeightedDiGraph, src::UInt64, dst::UInt64) =
    vertices2weight(G::SimpleWeightedDiGraph, Int64(src), Int64(dst))


"""
$(TYPEDSIGNATURES)

Takes the index of an edge in the weight matrix and returns the two vertices the edge refers to.
"""
@inline edgenum2vertices(G::SimpleWeightedDiGraph, n::Int64) =
    findlast(G.weights.colptr .≤ n), G.weights.rowval[n]


"""
$(TYPEDSIGNATURES)

Converts the weight matrix of a graph to a dictionary pointing each tuple (v1, v2) of vertices forming an edge to the index in the weight sparse matrix.
"""
@inline function edges2dict(G::SimpleWeightedDiGraph)
    d = Dict()

    for col_index ∈ 1:length(G.weights.colptr)-1
        listedges_beg = G.weights.colptr[col_index]
        listedges_end = G.weights.colptr[col_index+1] - 1

        for edge ∈ listedges_beg:listedges_end
            push!(d, (col_index, G.weights.rowval[edge]) => edge)
        end
    end

    return d
end
