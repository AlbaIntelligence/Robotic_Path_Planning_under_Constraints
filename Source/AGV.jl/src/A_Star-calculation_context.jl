"""
$(TYPEDFIELDS)
Structure containing various caches to be used to save allocation time
"""
@with_kw mutable struct AStar_CalculationContext <: AbstractCalculationContext
    ctx::TContext

    # Mutable to change during calcs
    G2DT::SimpleWeightedDiGraph            # Simple graph without for 2D path planning
    G3DT::SimpleWeightedDiGraph           # Same but transpose
    UG3D::LightGraphs.SimpleGraph         # Undirected and unweighted to speed up search for inneighbors

    # A* algo
    closed_set::Vector{Bool}
    g_score::Vector{Int64}
    came_from::Vector{Int64}
    occupancy::BitArray{3}
    edge_mask::BitArray{1}

end


"""
$(TYPEDSIGNATURES)

"""
function create_calculation_context(ctx::TContext, algo::A_Star)
    # Note that the same vectors are used for 2D and 3D planning.
    # Presumably taking the max is excess care, but cheap to do.

    max_vertices = max(nv(ctx.G2DT), nv(ctx.G3DT))
    max_edges = max(ne(ctx.G2DT), ne(ctx.G3DT))

    AStar_CalculationContext(;
        ctx = ctx,
        G2DT = deepcopy(ctx.G2DT),
        G3DT = deepcopy(ctx.G3DT),
        UG3D = deepcopy(ctx.UG3D),
        closed_set = zeros(Bool, max_vertices),
        g_score = zeros(Int64, max_vertices),
        came_from = deepcopy(ctx.G3DT.weights.nzval),
        occupancy = falses(ctx.nRow, ctx.nCol, ctx.nSteps),
        edge_mask = falses(max_edges),
    )
end
