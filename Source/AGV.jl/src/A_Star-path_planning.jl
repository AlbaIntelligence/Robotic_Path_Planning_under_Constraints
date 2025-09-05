"""
$(TYPEDSIGNATURES)

A* shortest-path algorithm

Note: `calctx.came_from` is a vector holding the parent of each node in the A* exploration
"""
function reconstruct_path(calctx::AbstractCalculationContext, end_idx)

    vs = zeros(Int64, MAX_PATH_LENGTH)
    v_idx = 1
    vs[v_idx] = end_idx

    curr_idx = end_idx
    while calctx.came_from[curr_idx] != curr_idx
        v_idx += 1
        vs[v_idx] = calctx.came_from[curr_idx]
        curr_idx = calctx.came_from[curr_idx]
    end
    return vs
end


"""
$(TYPEDSIGNATURES)

"""
function astar_heuristic(v1, v2, ctx::TContext)
    r1, c1, d1 = unpack(v2c_rcd(v1, ctx))
    r2, c2, d2 = unpack(v2c_rcd(v2, ctx))

    delta_d = abs(Int64(d2) - Int64(d1))
    delta_d = delta_d == 3 ? 1 : delta_d

    return abs(r2 - r1) * COST_FWD + abs(c2 - c1) * COST_FWD + delta_d * COST_TRN
end


"""
$(TYPEDSIGNATURES)

** Arguments

g: the graph
goal: the end vertex
open_set: an initialized heap containing the active vertices
calctx::AbstractCalculationContext
"""
function astar_impl!(g, goal, open_set, calctx::AbstractCalculationContext)

    while !isempty(open_set)
        current = dequeue!(open_set)

        if current == goal
            return reconstruct_path(calctx, current)
        end

        calctx.closed_set[current] = true
        for nb in outneighbors(g, current)
            calctx.closed_set[nb] && continue

            tentative_g_score =
                calctx.g_score[current] + astar_heuristic(current, nb, calctx.ctx)

            if tentative_g_score < calctx.g_score[nb]
                calctx.g_score[nb] = tentative_g_score
                priority = tentative_g_score
                open_set[nb] = priority
                calctx.came_from[nb] = current
            end
        end
    end

    # If no path found
    return zeros(Int64, MAX_PATH_LENGTH)
end


"""
$(TYPEDSIGNATURES)

Return a vector of edges comprising the shortest path between vertices `s` and `t`
using the [A* search algorithm](http://en.wikipedia.org/wiki/A%2A_search_algorithm).
An optional heuristic function and edge distance matrix may be supplied. If missing,
the distance matrix is set to [`LightGraphs.DefaultDistance`](@ref) and the heuristic is set to
`n -> 0`.
"""
function astar!(
    g::SimpleWeightedDiGraph,
    src::Int64,
    dst::Int64,
    calctx::AbstractCalculationContext,
)

    # if we do checkbounds here, we can use @inbounds in a_star_impl!
    # checkbounds(distmx, Base.OneTo(nv(g)), Base.OneTo(nv(g)))

    open_set = PriorityQueue{Int64,Int64}()
    enqueue!(open_set, src, 0)

    calctx.closed_set[:] .= false
    calctx.g_score[:] .= COST_IMPOSSIBLE
    calctx.g_score[src] = 0

    calctx.came_from[:] .= -1
    calctx.came_from[src] = src

    return astar_impl!(g, dst, open_set, calctx)
end
