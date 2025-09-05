"""
$(TYPEDSIGNATURES)

- All dimensions are in simulation dimensions.
- Returns full path and total execution time.

NOTE: This returns ONLY the path and does not in any time for pivoting towards the rack and loading/unloading.
"""
function path_vertices(
    reverse_graph::SimpleWeightedDiGraph,
    src::Integer,
    dst::Integer,
    calctx::AbstractCalculationContext,
)
    vs = []
    ws = []

    # To go from A to B, the search algorithm is more efficient if starting from B back to A.
    # We therefore swap the extremities and use the transpose matrix / reverse graph.
    vs = astar!(reverse_graph, dst, src, calctx)
    n_vertices = findfirst(isequal(0), vs) - 1
    if n_vertices == 0
        return [], Int64[]
    else
        # build a list of vertices from the edges`
        ws = [Int64(floor(weights(reverse_graph)[vs[i+1], vs[i]])) for i ∈ 1:n_vertices-1]
        return vs[1:n_vertices], ws
    end
end


"""
$(TYPEDSIGNATURES)

"""
function path_vertices(
    reverse_graph::AbstractGraph,
    src::Trc,
    src_dir::TDirection,
    dst::Trc,
    dst_dir::TDirection,
    calctx::AbstractCalculationContext,
)

    can_be_occupied(src, calctx.ctx) || @error "Source $(src) cannot be occupied."
    can_be_occupied(dst, calctx.ctx) || @error "Destination $(dst) cannot be occupied."

    src_v = c2v_rcd(src, src_dir, calctx.ctx)
    dst_v = c2v_rcd(dst, dst_dir, calctx.ctx)
    return path_vertices(reverse_graph, src_v, dst_v, calctx)
end


"""
$(TYPEDSIGNATURES)

2D path search

Those methods only return the time to transit from one location to another. They do not calculate the time to load/unload.

start and dest are Trc()
"""
function path_a_b_2D(
    src::Trc,
    src_dir::TDirection,
    dst::Trc,
    dst_dir::TDirection,
    calctx::AbstractCalculationContext,
)

    path_v, path_w = path_vertices(calctx.ctx.G2DT, src, src_dir, dst, dst_dir, calctx)

    if isempty(path_v)
        return format_path([], [], 0, calctx.ctx)
    else
        return format_path(path_v, path_w, 0, calctx.ctx)
    end
end


"""
$(TYPEDSIGNATURES)

"""
function path_a_b_2D(a::TLocation, p::TLocation, calctx::AbstractCalculationContext)
    return path_a_b_2D(a.loc.s, a.sideToFace, p.loc.s, p.sideToFace, calctx)
end


"""
$(TYPEDSIGNATURES)

"""
function path_a_b_2D(a::TAGV, p::TLocation, calctx::AbstractCalculationContext)
    return path_a_b_2D(a.loc.s, a.dir, p.loc.s, p.sideToFace, calctx)
end


"""
$(TYPEDSIGNATURES)

"""
function path_a_b_2D(
    a::TAGV,
    dest::Tuple{TCoord,TDirection},
    calctx::AbstractCalculationContext,
)
    return path_a_b_2D(a.loc.s, a.dir, dest[1].s, dest[2], calctx)
end


"""
$(TYPEDSIGNATURES)

"""
function path_a_b_2D(t::TTask, p::TLocation, calctx::AbstractCalculationContext)
    return path_a_b_2D(t.target, p, calctx)
end


"""
$(TYPEDSIGNATURES)

"""
function path_a_b_2D(
    t::TTask,
    dest::Tuple{TCoord,TDirection},
    calctx::AbstractCalculationContext,
)
    return path_a_b_2D(t.target.loc.s, t.target.sideToFace, dest[1].s, dest[2], calctx)
end


"""
$(TYPEDSIGNATURES)

"""
function path_a_b_2D(task::TTask, calctx::AbstractCalculationContext)
    return path_a_b_2D(task.start, task.target, calctx)
end


"""
$(TYPEDSIGNATURES)

"""
function path_a_b_2D(agv::TAGV, task::TTask, calctx::AbstractCalculationContext)
    return path_a_b_2D(agv.loc.s, agv.dir, task.start.loc.s, task.start.sideToFace, calctx)
end


"""
$(TYPEDSIGNATURES)

Remove all duplicates as the end of the path.
"""
function clean_end_path_2D(path_c, path_times)

    if length(path_c) == 0
        return [], []
    else
        final_position = Trcd(path_c[end][1], path_c[end][2], path_c[end][3])

        for i ∈ length(path_c)-1:-1:1
            if Trcd(path_c[i][1], path_c[i][2], path_c[i][3]) != final_position
                return path_c[1:i+1], path_times[1:i]
            end
        end
    end
end
