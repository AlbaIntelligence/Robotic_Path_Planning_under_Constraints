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

Calculate A* heuristic between two vertices using Manhattan distance and direction change cost.

# Arguments
- `v1::Int64`: Source vertex index
- `v2::Int64`: Target vertex index
- `ctx::TContext`: Context containing graph information

# Returns
- `Float64`: Heuristic cost estimate combining distance and direction change

# Examples
```julia
h = astar_heuristic(1, 100, context)
```

# Notes
The heuristic combines:
- Manhattan distance (row and column differences) weighted by forward movement cost
- Direction change cost (turning penalty)
- Handles wraparound for direction changes (3 steps = 1 step in opposite direction)
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

Core A* algorithm implementation with priority queue and closed set management.

# Arguments
- `g::SimpleWeightedDiGraph`: The graph to search
- `goal::Int64`: Target vertex index
- `open_set::PriorityQueue`: Priority queue containing vertices to explore
- `calctx::AbstractCalculationContext`: Calculation context with scores and parent tracking

# Returns
- `Vector{Int64}`: Path from start to goal, or zeros if no path found

# Algorithm
1. While open set is not empty:
   - Dequeue vertex with lowest f-score
   - If goal reached, reconstruct and return path
   - Mark current vertex as closed
   - For each neighbor:
     - Skip if already closed
     - Calculate tentative g-score
     - Update if better path found
     - Add to open set with priority

# Notes
- Uses f-score (g + h) for vertex prioritization
- Maintains closed set to avoid revisiting vertices
- Returns empty path (zeros) if no solution exists
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

Find shortest path between two vertices using A* search algorithm.

# Arguments
- `g::SimpleWeightedDiGraph`: The graph to search
- `src::Int64`: Source vertex index
- `dst::Int64`: Destination vertex index
- `calctx::AbstractCalculationContext`: Pre-initialized calculation context

# Returns
- `Vector{Int64}`: Path from source to destination, or zeros if no path found

# Examples
```julia
path = astar!(graph, start_vertex, goal_vertex, context)
if path[1] != 0
    println("Path found with $(length(path)) vertices")
else
    println("No path found")
end
```

# Notes
- Uses Manhattan distance heuristic with direction change costs
- Requires pre-initialized calculation context with proper bounds
- Returns zeros array if no path exists
- Path vertices are in reverse order (destination to source)
- Initializes all scores to impossible cost and resets closed set
"""
function astar!(
    g::SimpleWeightedDiGraph,
    src::Int64,
    dst::Int64,
    calctx::AbstractCalculationContext,
)

    # Initialize priority queue with source vertex
    open_set = PriorityQueue{Int64,Int64}()
    enqueue!(open_set, src, 0)

    # Reset calculation context for new search
    calctx.closed_set[:] .= false
    calctx.g_score[:] .= COST_IMPOSSIBLE
    calctx.g_score[src] = 0

    calctx.came_from[:] .= -1
    calctx.came_from[src] = src

    return astar_impl!(g, dst, open_set, calctx)
end
