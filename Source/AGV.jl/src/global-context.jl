"""
$(TYPEDFIELDS)

FloorPlan information structure
"""
@with_kw mutable struct TContext
    # Original plan
    plan::AbstractArray{TLOCATION_FILL,2} = fill(LOC_EMPTY, (1, 1))
    nRow::Int64 = 1
    nCol::Int64 = 1
    slice_size::Int64 = nRow * nCol * nDirection
    initial_occupancy::AbstractArray{Bool,2} = AbstractArray{Bool,2}

    special_locations::Dict{String,Vector{TLocation}} = Dict(
        "parking" => TLocation[],
        "conveyor" => TLocation[],
        "rack" => TLocation[],
        "back" => TLocation[],
        "ground" => TLocation[],
        "quay" => TLocation[],
    )

    # 3D occupancy matrices
    M3D::AbstractArray{TLOCATION_FILL} = fill(LOC_EMPTY, (1, 1, 1))
    G2DT::SimpleWeightedDiGraph = SimpleWeightedDiGraph(slice_size)          # Simple graph without for 2D path planning
    G3DT::SimpleWeightedDiGraph = SimpleWeightedDiGraph()

    # Same but transpose
    UG3D::LightGraphs.SimpleGraph = LightGraphs.SimpleGraph()        # Undirected and unweighted to speed up search for inneighbors
    D::Dict = Dict()
    jumpover_knockoff_vertices::Dict = Dict()
    nVertices::Int64 = 0
    nEdges::Int64 = 0
    # Total depth of the exploration/graph
    nSteps::Int64 = 0
    # When searching, maximum depth from start of search (to limit time)
    depthLimit::Int64 = 0
end


"""
$(TYPEDSIGNATURES)

"""
function TContext(
    plan::AbstractArray{TLOCATION_FILL,2},
    nSteps::Int64,
    depthLimit::Int64,
)::TContext

    @assert nSteps > 2 * STEPS_MAX_TO_KNOCKOUT + 1
    """
    The number of steps modelled ($nSteps) needs to be long enough to capture the full time
    to reach the full height of MAX_RACK_LEVELS (2 * $STEPS_MAX_TO_KNOCKOUT + 1).
    """

    nRow, nCol = size(plan)
    @info "\n" * stimer() * " Starting precomputing"

    m3d = floorplan_to_matrix_3D(plan, nSteps)
    @info stimer() * "  Matrix 3D done"

    slice_size = nRow * nCol * nDirection
    g3t = SimpleWeightedDiGraph(slice_size * nSteps)
    ug3 = LightGraphs.SimpleGraph(slice_size * nSteps)

    c = TContext(;
        plan = plan,
        nRow = nRow,
        nCol = nCol,
        slice_size = slice_size,
        initial_occupancy = .!(can_be_occupied.(plan)),
        M3D = m3d,
        G3DT = g3t,
        UG3D = ug3,
        nVertices = nv(g3t),
        nEdges = ne(g3t),
        nSteps = nSteps,
        depthLimit = depthLimit,
    )
    @info stimer() * "  Empty data structure done"


    c.G2DT, c.G3DT, c.UG3D = floorplan_to_graphs(c)
    @info stimer() * "  Full graph done"

    c.D = edges2dict(c.G3DT)
    @info stimer() * "  Edges hash table done"

    c.jumpover_knockoff_vertices = generate_jumpover_knockoff_vertices(c)
    @info stimer() * "  Jumpover Knockoff vertices pairs done"

    return c
end


"""
$(TYPEDSIGNATURES)

"""
can_be_occupied(rc::Trc, context::TContext)::Bool = can_be_occupied(rc[1], rc[2], context)
can_be_occupied(rcd::Trcd, context::TContext)::Bool =
    can_be_occupied(rcd[1], rcd[2], context)
can_be_occupied(rcdt::Trcdt, context::TContext)::Bool =
    can_be_occupied(rcdt[1], rcdt[2], context)


"""
$(TYPEDSIGNATURES)

"""
function find_side_to_face(row, col, ctx::TContext)::TDirection
    for (r, c, d) ∈ [
        (row + 1, col, Up),
        (row - 1, col, Down),
        (row, col + 1, Left),
        (row, col - 1, Right),
    ]
        if 1 ≤ r ≤ ctx.nRow && 1 ≤ c ≤ ctx.nCol
            if can_be_occupied(r, c, ctx)
                return d
            end
        end
    end
end



"""
$(TYPEDSIGNATURES)

"""
function can_face_after_turning(r, c, ctx::TContext)::Bool
    if 1 ≤ r ≤ ctx.nRow && 1 ≤ c ≤ ctx.nCol
        return can_face_after_turning(ctx.plan[r, c])
    else
        return false
    end
end


"""
$(TYPEDSIGNATURES)

If out of bounds, return false
"""
can_be_occupied(r::Int64, c::Int64, ctx::TContext)::Bool =
    (1 ≤ r ≤ ctx.nRow && 1 ≤ c ≤ ctx.nCol) ? can_be_occupied(ctx.plan[r, c]) : false


"""
$(TYPEDSIGNATURES)

"""
is_location_parking(location_fill::TLOCATION_FILL)::Bool =
    location_fill ∈ [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
is_location_empty(l::TLOCATION_FILL)::Bool = l ∈ [LOC_EMPTY]
is_location_empty(r::Int64, c::Int64, ctx::TContext)::Bool =
    (1 ≤ r ≤ ctx.nRow && 1 ≤ c ≤ ctx.nCol) ? is_location_empty(ctx.plan[r, c]) : false
is_location_empty(rc::Trc, context::TContext)::Bool =
    is_location_empty(rc[1], rc[2], context)
is_location_empty(rcd::Trcd, context::TContext)::Bool =
    is_location_empty(rcd[1], rcd[2], context)
is_location_empty(rcdt::Trcdt, context::TContext)::Bool =
    is_location_empty(rcdt[1], rcdt[2], context)


"""
$(TYPEDSIGNATURES)

# Argument:

    - rct: coordinates in row, column, time of the 3D occupancy matrix
    - M3: 3D occupancy matrix
"""
function is_location_empty(rct::Trct, M3::Array{TLOCATION_FILL})::Bool
    r, c, t = unpack(rct)
    nRow, nCol, nSteps = size(M3)

    # If out of bounds, return false
    if 1 ≤ r ≤ nRow && 1 ≤ c ≤ nCol && t ≤ nSteps
        return is_location_empty(M3[r, c, t])
    else
        return false
    end
end



"""
$(TYPEDSIGNATURES)

"""
# No backward moves.
# Change weights to add back.
function check_and_add_moves(r, c, dr, dc, dir::TDirection, ctx::TContext)
    new_r = r + dr
    new_c = c + dc
    new_moves = []

    # Zero-th: This is a move. dr or dc must be something
    if dr == 0 && dc == 0
        return []
    end

    # First: check that the new location is within bounds
    # Second: If new location is busy: bye bye
    if !can_be_occupied(new_r, new_c, ctx)
        return []
    end

    # Third: check the direction: move along ROW means Up/Down; move along COLUMN mean Left/Right
    if (dr != 0) && !(dir == Up || dir == Down)
        return []
    end
    if (dc != 0) && !(dir == Left || dir == Right)
        return []
    end

    # Fourth: everything is aligned. Now determine, given the direction and
    # target, the time to go there.
    if dir == Down && dr > 0
        t_required = STEPS_FWD
        cost = COST_FWD
    elseif dir == Down && dr < 0
        t_required = STEPS_BCK
        cost = COST_BCK
    elseif dir == Up && dr < 0
        t_required = STEPS_FWD
        cost = COST_FWD
    elseif dir == Up && dr > 0
        t_required = STEPS_BCK
        cost = COST_BCK
    end

    if dir == Right && dc > 0
        t_required = STEPS_FWD
        cost = COST_FWD
    elseif dir == Right && dc < 0
        t_required = STEPS_BCK
        cost = COST_BCK
    elseif dir == Left && dc < 0
        t_required = STEPS_FWD
        cost = COST_FWD
    elseif dir == Left && dc > 0
        t_required = STEPS_BCK
        cost = COST_BCK
    end


    # How long can we stay in this location:
    # We can go forward/backward only if t_max is long enough to make that move
    if t_required ≤ ctx.nSteps - 1
        move_nsteps = Int64(t_required)
        move_cost = Int64(cost)
        new_move = TMove(
            as_rcdt(r, c, dir, 1),
            as_rcdt(new_r, new_c, dir, 1 + move_nsteps),
            move_nsteps,
            move_cost,
        )

        push!(new_moves, new_move)
    end

    return new_moves
end


"""
$(TYPEDSIGNATURES)

"""
# [TODO: What is happening with facing a palette??]
# Can only turn if after turn will face an empty space.
# Remove relevant section
function check_and_add_turns(r, c, dir::TDirection, ctx::TContext)
    new_moves = []

    # How long (NOT until when) can we stay in this location:
    t_max = ctx.nSteps

    # If no time at all, nothing to do. We need at least some time
    if t_max > 0

        # We can stay not moving and not turning if long enough to
        #  stay at least nStepRem time-step
        if t_max ≥ STEPS_REMAIN

            move_nsteps = Int64(STEPS_REMAIN)
            move_cost = Int64(COST_REMAIN)
            new_move = TMove(
                as_rcdt(r, c, dir, 1),
                as_rcdt(r, c, dir, 1 + move_nsteps),
                move_nsteps,
                move_cost,
            )
            push!(new_moves, new_move)
        end

        # AGV can turn on itself only if t_max is long enough to make that turn
        if t_max ≥ STEPS_TRN

            move_nsteps = Int64(STEPS_TRN)
            move_cost = Int64(COST_TRN)

            # If located on parking do what you want
            if is_location_parking(ctx.plan[r, c])
                new_move = TMove(
                    as_rcdt(r, c, dir, 1),
                    as_rcdt(r, c, turn90(dir), 1 + move_nsteps),
                    move_nsteps,
                    move_cost,
                )
                push!(new_moves, new_move)

                new_move = TMove(
                    as_rcdt(r, c, dir, 1),
                    as_rcdt(r, c, turn270(dir), 1 + move_nsteps),
                    move_nsteps,
                    move_cost,
                )
                push!(new_moves, new_move)
            end

            # Check that the AGV will face and empty space
            if (dir == Up && can_face_after_turning(r, c + 1, ctx)) ||
               (dir == Right && can_face_after_turning(r + 1, c, ctx)) ||
               (dir == Down && can_face_after_turning(r, c - 1, ctx)) ||
               (dir == Left && can_face_after_turning(r - 1, c, ctx))

                new_move = TMove(
                    as_rcdt(r, c, dir, 1),
                    as_rcdt(r, c, turn90(dir), 1 + move_nsteps),
                    move_nsteps,
                    move_cost,
                )
                push!(new_moves, new_move)
            end

            if (dir == Up && can_face_after_turning(r, c - 1, ctx)) ||
               (dir == Right && can_face_after_turning(r - 1, c, ctx)) ||
               (dir == Down && can_face_after_turning(r, c + 1, ctx)) ||
               (dir == Left && can_face_after_turning(r + 1, c, ctx))

                new_move = TMove(
                    as_rcdt(r, c, dir, 1),
                    as_rcdt(r, c, turn270(dir), 1 + move_nsteps),
                    move_nsteps,
                    move_cost,
                )
                push!(new_moves, new_move)

            end

            if (dir == Up && can_face_after_turning(r + 1, c, ctx)) ||
               (dir == Right && can_face_after_turning(r, c - 1, ctx)) ||
               (dir == Down && can_face_after_turning(r - 1, c, ctx)) ||
               (dir == Left && can_face_after_turning(r, c + 1, ctx))

                new_move = TMove(
                    as_rcdt(r, c, dir, 1),
                    as_rcdt(r, c, turn180(dir), 1 + 2 * move_nsteps),
                    2 * move_nsteps,
                    2 * move_cost,
                )
                push!(new_moves, new_move)

            end

        end
    end
    return new_moves
end


"""
$(TYPEDSIGNATURES)

3D move generator

The function returns a list of Cartesian indices + direction + cost for each of the possible moves from a given position  = Move generator.

For the moment, backward movements are provisional (need to think more about cost impact and propagation of AGV state over time). Might be as easy as decomposing complex tasks in sub-tasks, and just copy and paste pushing across time in 3D.

# Arguments:
- `p`: current position of the AGV in space and time
- `d`: direction faced
- `context`: general floor information
- `M`: 3D matrix containing the floor and trajectories of previous AGVs

"""
function generate_moves(rcd::Trcd, ctx::TContext)
    r, c, d = unpack(rcd)
    d = TDirection(d)

    # All the moves are horizontal or vertical (no diagonal).
    # Result contains new position + new direction.
    # Change of direction is within a single cell.
    list_moves = TMove[]

    # If there is anything there, no point exploring at all, AGV could never be there
    if can_be_occupied(ctx.plan[r, c])
        # Add turn within spot
        next_moves = check_and_add_turns(r, c, d, ctx)

        if !isempty(next_moves)
            append!(list_moves, next_moves)
        end

        # Add moves in all directions
        for (dr, dc) ∈ [(-1, 0), (1, 0), (0, -1), (0, 1)]
            next_moves = check_and_add_moves(r, c, dr, dc, d, ctx)
            if !isempty(next_moves) && !isnothing(next_moves)
                append!(list_moves, next_moves)
            end
        end
    end

    return list_moves
end


"""
$(TYPEDSIGNATURES)

Create a 3D matrix from the floor plan. The final time is completely set to LOC_BUSY
to prevent any further searches.

[TODO: Check if useful instead of floorplan, then refactor out]
"""
function floorplan_to_matrix_3D(floorplan, nSteps)
    nRow, nCol = size(floorplan)

    M3D = reshape(repeat(floorplan, 1, nSteps), nRow, nCol, nSteps)
    M3D[:, :, nSteps] .= LOC_BUSY
    return M3D
end


"""
$(TYPEDSIGNATURES)

3D graph creation
Graph creatiion is fundamentally about creating the right timecosts from vertex to vertex.

Each path in the list of paths in a pair of list of Cartesian indices + list of transition times.
"""
function floorplan_to_graphs(ctx::TContext)

    @info stimer() * "    --Beginning floorplan_to_graph_3D"

    #########################################################################
    # Create possible moves within
    nRow = ctx.nRow
    nCol = ctx.nCol
    nSteps = ctx.nSteps
    slice_size = ctx.slice_size

    # Lists to store every edge iteratively
    # With an initial value to guarantee that the final sparse matrix
    # has the right size
    list_edge_2D_col = [nRow * nCol * nDirection]
    list_edge_2D_row = [nRow * nCol * nDirection]
    list_edge_2D_costs = [0.0]

    # Propagation is done nSteps-2 times because of pillars vs. gaps, and the last
    # pillar is at t-1 (since t is prefilled with walls)
    list_edge_3D_col = [nRow * nCol * nDirection * nSteps]
    list_edge_3D_row = [nRow * nCol * nDirection * nSteps]
    list_edge_3D_costs = [0.0]

    error_count = 1
    for row ∈ 1:nRow

        @info @sprintf("%s    ---- Preparing row:  %d", stimer(), row)

        @debug @sprintf(
            "%s         Starting length: %d",
            stimer(),
            length(list_edge_3D_col)
        )

        for col ∈ 1:nCol, d ∈ 1:nDirection

            origin_2D_rcd = Trcd(row, col, d)
            origin_2D_v = c2v_rcd(origin_2D_rcd, ctx)

            origin_3D_rcd = Trcd(row, col, d)
            origin_3D_rcdt = Trcdt(row, col, d, 1)
            origin_3D_v = c2v_rcdt(origin_3D_rcdt, ctx)

            list_moves = generate_moves(origin_2D_rcd, ctx)

            for m ∈ list_moves
                # Extract move details
                next_position_3D_rcdt = m.dest
                next_position_3D_v = c2v_rcdt(next_position_3D_rcdt, ctx)
                time_cost = m.cost

                # Where are we going to?
                next_r, next_c, _, next_t = unpack(next_position_3D_rcdt)

                # [_Normally_ useless check]
                if (
                    next_r > 50000 * STEP_TO_COST_MULTIPLIER ||
                    next_c > 50000 * STEP_TO_COST_MULTIPLIER ||
                    next_t > 50000 * STEP_TO_COST_MULTIPLIER ||
                    time_cost > nSteps * STEP_TO_COST_MULTIPLIER
                ) && error_count ≤ 20

                    @info @sprintf(
                        "%s            %s %s %s %s %s %s",
                        stimer(),
                        "Abnormal values from",
                        @show(origin_3D_rcd),
                        " to",
                        @show(next_position_3D_rcdt),
                        " with cost",
                        @show(time_cost)
                    )

                    error_count += 1
                end

                #########################################################################
                ##
                ## Add as 2D moves
                ##
                next_position_2D_rcd = as_rcd(next_position_3D_rcdt)
                next_position_2D_v = c2v_rcd(next_position_2D_rcd, ctx)

                # In 2D, we are no interested in path conflicts, therefore no point in
                # staying in the same location.
                if origin_2D_v != next_position_2D_v
                    push!(list_edge_2D_col, origin_2D_v)
                    push!(list_edge_2D_row, next_position_2D_v)
                    push!(list_edge_2D_costs, time_cost)
                end

                #########################################################################
                ##
                ## Add as 3D moves
                ###
                # Loop over all time steps

                # Need to be careful that the copied moves don't go too far in the future
                # next_t - 1 is how long we need to jump.
                for t ∈ 1:(nSteps-1-(next_t-1))

                    # Fill for current time step
                    push!(list_edge_3D_col, origin_3D_v + slice_size * (t - 1))
                    push!(list_edge_3D_row, next_position_3D_v + slice_size * (t - 1))
                    push!(list_edge_3D_costs, time_cost)
                end
            end
        end

        if error_count > 1
            @debug @sprintf(
                "%s             %s %d",
                stimer(),
                "    !!!! COUNT OF ABNORMAL VALUES",
                error_count - 1
            )
        end

        @debug @sprintf(
            "%s %s %d",
            stimer(),
            "        Finishing length:",
            length(list_edge_3D_col)
        )
    end


    # Construction of the 2D and 3D directed graphs match each other
    # [TODO: refactor to be parallel?]
    list_edge_2D_col_f = Int64.(list_edge_2D_col)
    list_edge_2D_row_f = Int64.(list_edge_2D_row)
    list_edge_2D_costs_f = Int64.(list_edge_2D_costs)

    list_edge_3D_col_f = Int64.(list_edge_3D_col)
    list_edge_3D_row_f = Int64.(list_edge_3D_row)
    list_edge_3D_costs_f = Int64.(list_edge_3D_costs)
    @info stimer() * "    --Edges generation done"



    # WARNING: Creating the transpose matrix
    list_edge_2D_definitions =
        hcat(list_edge_2D_row_f, list_edge_2D_col_f, list_edge_2D_costs_f)

    # WARNING: Creating the transpose matrix
    list_edge_3DT_definitions =
        hcat(list_edge_3D_row_f, list_edge_3D_col_f, list_edge_3D_costs_f)
    @info stimer() * "    --G: Merging move coodinate vertices done"

    # First sort by colptr then rowval
    list_2D_swg =
        sortslices(list_edge_2D_definitions, dims = 1, by = x -> (x[1], x[2]), rev = false)
    @debug stimer() * "    --G: Sorting 2D edges done"

    list_3DT_swg =
        sortslices(list_edge_3DT_definitions, dims = 1, by = x -> (x[1], x[2]), rev = false)
    @debug stimer() * "         Sorting 3D transpose edges done"
    @info stimer() * "    --G: Sorting edges done"

    # Ensure uniqueness
    list_2D_swg = unique(list_2D_swg, dims = 1)
    @info stimer() * "    --G: removing copies 2D done"

    list_3DT_swg = unique(list_3DT_swg, dims = 1)
    @debug stimer() * "    --G: removing copies 3D transpose done"
    @info stimer() * "    --G: removing copies done"

    # Create an empty graph with the right number of vertices
    G2DT = SimpleWeightedDiGraph{Int64,Int64}(nRow * nCol * nDirection)
    G3DT = SimpleWeightedDiGraph{Int64,Int64}(nRow * nCol * nDirection * nSteps)

    # Create the weights matrix as an sparse matrix
    G2DT.weights =
        sparse(Int64.(list_2D_swg[:, 2]), Int64.(list_2D_swg[:, 1]), list_2D_swg[:, 3])
    @info stimer() * "    --G: creation sparse matrix 2D done"

    G3DT.weights =
        sparse(Int64.(list_3DT_swg[:, 2]), Int64.(list_3DT_swg[:, 1]), list_3DT_swg[:, 3])
    @debug stimer() * "    --G: creation sparse matrix 3D transpose done"
    @info stimer() * "    --G: creation sparse matrix done"

    matsize = nRow * nCol * nDirection * nSteps
    UG3D = SimpleGraph(Int64(matsize))
    @inbounds for i = 1:matsize
        @inbounds for j in outneighbors(G3DT, i)
            add_edge!(UG3D, j, i)
        end
    end

    @info stimer() * "    --UG: creating graph done"
    @info stimer() * "    --Floor graphs done."

    return G2DT, G3DT, UG3D
end


"""
$(TYPEDSIGNATURES)

For each location in and around (r, c), starting from t, returns when the location is first occupied. This is to check how long an AGV can stay there.

The time returned is a simulation time!.

[TODO: Remove searches in diagonal _OR_ make search for single location and called on demand.]
"""
function time_available_at_location(r::Int64, c::Int64, t::Int64, context::TContext)
    # Check where and how long can stay in each location in and around
    MFree = fill(Int64(t), (3, 3))

    for dr ∈ -1:1, dc ∈ -1:1

        new_r = r + dr
        new_c = c + dc
        first_time_busy = t

        # First: check that the new location is within bounds
        if 1 ≤ new_r ≤ context.nRow && 1 ≤ new_c ≤ context.nCol
            time_line = context.M3D[r+dr, c+dc, :]

            for i ∈ (t+1):context.nSteps
                # As soon as not empty, we are free until the time before
                if time_line[i] != LOC_EMPTY
                    first_time_busy = i
                    MFree[dr+2, dc+2] = first_time_busy - 1
                    break
                end
            end
        else
            MFree[dr+2, dc+2] = first_time_busy
        end
    end
    return MFree
end


"""
$(TYPEDSIGNATURES)

For a given time ``t_0``` (STEPS_MAX_TO_KNOCKOUT on either side of STEPS_MAX_TO_KNOCKOUT) and for each plan position,
identify all the pairs of vertices ``v_1```, ``v_2``` such that ``v_1``` and ``v_2``` are on that position with
starting and finishing times on either sides of ``t_0``.`
"""
function generate_jumpover_knockoff_vertices(ctx::TContext)
    nRow = ctx.nRow
    nCol = ctx.nCol

    # For each coordinates, we cache the list of pairs of vertices on either side
    JumpoverKnockoffMask = Dict{Tuple{Int64,Int64},Vector{Tuple{Int64,Int64}}}()

    # For each plan position, identify all the pairs of vertices v1
    for r ∈ 1:nRow, c ∈ 1:nCol
        list_vertices_pairs_around_middle = Tuple{Int64,Int64}[]

        for d_end ∈ [Up, Right, Down, Left]

            # Add any vertex that lands on the exact spot coming from anywhere
            v_middle = c2v_rcdt(Trc(r, c), d_end, 1, ctx)

            for v_beg in outneighbors(ctx.G3DT, v_middle)
                push!(list_vertices_pairs_around_middle, (v_middle, v_beg))
            end

            # for t_end ∈ 0:STEPS_MAX_TO_KNOCKOUT
            #     v_end = c2v_rcdt(Trc(r, c), d_end, STEPS_MAX_TO_KNOCKOUT + t_end, ctx)

            #     for v_beg in outneighbors(ctx.G3DT, v_end)
            #         r_beg, c_beg, _, t_beg = unpack(v2c_rcdt(v_beg, ctx))

            #         if Trc(r_beg, c_beg) == Trc(r, c) && t_beg < STEPS_MAX_TO_KNOCKOUT
            #             push!(list_vertices_pairs_around_middle, (v_end, v_beg))
            #         end
            #     end
            # end
        end

        JumpoverKnockoffMask[(r, c)] = list_vertices_pairs_around_middle
    end

    return JumpoverKnockoffMask
end


"""
$(TYPEDSIGNATURES)

"""
function jumpover_knockoff_v_pairs(r, c, t, ctx::TContext)
    list_v_pairs = []

    for (v_end, v_beg) ∈ ctx.jumpover_knockoff_vertices[(r, c)]
        # Adjust for time
        v_2 = v_end + t * ctx.slice_size
        1 ≤ v_2 ≤ ctx.nVertices || continue
        v_1 = v_beg + t * ctx.slice_size
        1 ≤ v_1 ≤ ctx.nVertices || continue

        push!(list_v_pairs, (v_2, v_1))
    end

    return list_v_pairs
end
