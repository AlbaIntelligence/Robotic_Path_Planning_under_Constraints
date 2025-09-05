#
# Used in tests mainly
#
"""
$(TYPEDSIGNATURES)

Returns a list of costs (extracted from the reverse 3D graph). Each cost is the cost
of landing on (r, c) at time t (in any direction) coming from wherever.

Only if all the costs are COST_IMPOSSIBLE can a location be unreacheable.

Note: The occupancy matrix is stored in `calctx`.
"""
function list_cost_to_reach_3D(r, c, t, calctx::AStar_CalculationContext)
    lw = []
    for vs in [c2v_rcdt(as_rcdt(r, c, d, t), calctx.ctx) for d in [Up, Right, Down, Left]]
        vouts = outneighbors(calctx.ctx.G3DT, vs)
        edge_indices = [vertices2edgenum(calctx.ctx.G3DT, vs, v) for v in vouts]
        for e in edge_indices
            push!(lw, calctx.G3DT.weights.nzval[e])
        end
    end
    return lw
end


"""
$(TYPEDSIGNATURES)

Takes a list of costs from testrct() and returns a Bool representing if there is any
way to reach that rct. It is not reacheable if the list is empty (no way to get there)
or if the all the costs to get there are marked COST_IMPOSSIBLE.
"""
is_not_reachable(l) = isempty(l) || all(l .== COST_IMPOSSIBLE)


"""
$(TYPEDSIGNATURES)

Returns v1, v2, l1, l2 whether an interval is __entirely__ reachable.
    If v1 == true: everything is reachable.
    If v2 == true: none       is reachable.

    l1: vector of the actual occupancy, time step after time step
    l2: vector of the actual reacheability, time step after time step

Note: The occupancy matrix is stored in `calctx`.
"""
function reacheability(
    r::Int64,
    c::Int64,
    time_from::Int64,
    time_to::Int64,
    calctx::AStar_CalculationContext,
)
    occupied = [calctx.occupancy[r, c, t] for t = time_from:time_to]
    unreachable =
        is_not_reachable.([
            list_cost_to_reach_3D(r, c, t, calctx) for t = time_from:time_to
        ])
    return all(occupied .== false) && all(unreachable .== false),
    all(occupied .== true) && all(unreachable .== true),
    occupied,
    unreachable
end



"""
$(TYPEDSIGNATURES)

Destructively modifies the occupancy matrix with the information from the allocation paths. The occupancy matrix is stored in `calctx`.
The occupancy IS shifted by `time_shift` (so that the first time step is time_shift).

Is addition, The vertices weights of G3DT (G#DT.weights.nzwal), edge_mask and occupancy are destructively modified for perforamance reasons.
"""
function fill_blockages!(
    time_shift::Int64,
    list_allocation_paths::Vector{TPath_rcdt},
    calctx::AStar_CalculationContext,
)

    @assert time_shift ≥ 0 "Attempting to shift the planning by a negative time."


    # Restore a fresh copy of the original edge weights of the directed 3D graph.
    # Create empty occupancy (false means empty) using the preallocated matrix in the calculation context
    # Use the pre-allocated empty mask to change edges
    size_nzval = length(calctx.ctx.G3DT.weights.nzval)
    calctx.G3DT.weights.nzval[:] = calctx.ctx.G3DT.weights.nzval[:]
    calctx.edge_mask[:] .= false
    calctx.occupancy =
        repeat(calctx.ctx.initial_occupancy; outer = (1, 1, calctx.ctx.nSteps))

    isempty(list_allocation_paths) && return nothing
    isempty(list_allocation_paths[1]) && return nothing

    # Go through each of the paths to block. In principle, one path = one AGV
    @debug "n paths = $(length(list_allocation_paths))"
    for path ∈ list_allocation_paths

        # Collect the times at which things happen with a maximum impossible time
        rcdt_times = [rcdt[4] for rcdt ∈ path]

        for path_idx ∈ 1:length(path)-1

            # Starting and ending points of the segment to fill up as blockages. Direction is not relevant.
            r1, c1, _, t1 = unpack(path[path_idx])
            r2, c2, _, t2 = unpack(path[path_idx+1])
            # We should not have any move where the time does not change or decreases
            @assert t2 > t1 "flill_blocages: two successive times are not strictly increasing from t1=$(t1) t2=$(t2) %s.\n"

            # Make sure that the segment falls at least in part within the depth starting from time_shift
            rcdt_times[path_idx+1] < time_shift && continue

            # Add a bit of time margin on either side of the time segment. [TODO: check if really appropriate]
            # Then Convert in the starting and ending points shifted by time_shift.
            shifted_t_beg = t1 - time_shift
            shifted_t_end = t2 - time_shift

            # Enforce very conservative basic rules
            # beginning has to be at least 1, end doesn't exceed max depth.
            # TODO: restore the depth_limit mechanism.
            shifted_t_beg = max(1, shifted_t_beg)
            shifted_t_beg = min(shifted_t_beg, calctx.ctx.nSteps)

            # if end before beginning, beginning is not adjusted, end is.
            shifted_t_end = max(shifted_t_beg, shifted_t_end)
            shifted_t_end = min(shifted_t_end, calctx.ctx.nSteps)

            # TODO: Go fast by increasing increasing the filling index by slice_time
            for shifted_t ∈ shifted_t_beg:shifted_t_end,
                dr ∈ -STEP_SAFETY_BUFFER:STEP_SAFETY_BUFFER,
                dc ∈ -STEP_SAFETY_BUFFER:STEP_SAFETY_BUFFER

                # Fill occupancy
                # THIS ASSUMES THAT (r1, c1) and (r2, c2) are identical or contiguous
                # TODO: If we merge successive location, CHANGE TO FULL INTERMEDIARY!!!
                calctx.occupancy[r1+dr, c1+dc, shifted_t_beg:shifted_t_end] .= true
                calctx.occupancy[r2+dr, c2+dc, shifted_t_beg:shifted_t_end] .= true

                if can_be_occupied(r1 + dr, c1 + dc, calctx.ctx)
                    @debug "Filling ($(r1 + dr), $(c1 + dc)) and ($(r2 + dr), $(c2 + dc)) at time $(shifted_t).\n"

                    for (v_end, v_beg) ∈
                        jumpover_knockoff_v_pairs(r1 + dr, c1 + dc, shifted_t, calctx.ctx)

                        index_to_knock_off = vertices2edgenum(v_end, v_beg, calctx.ctx)
                        if !isnothing(index_to_knock_off)
                            calctx.G3DT.weights.nzval[index_to_knock_off] = COST_IMPOSSIBLE
                        end
                    end
                end

                if can_be_occupied(r2 + dr, c2 + dc, calctx.ctx)
                    for (v_end, v_beg) ∈
                        jumpover_knockoff_v_pairs(r2 + dr, c2 + dc, shifted_t, calctx.ctx)

                        index_to_knock_off = vertices2edgenum(v_end, v_beg, calctx.ctx)
                        if !isnothing(index_to_knock_off)
                            calctx.G3DT.weights.nzval[index_to_knock_off] = COST_IMPOSSIBLE
                        end
                    end
                end
            end
        end

        # Add occupancy to infinity (after stopping moving, stay on the spot)
        final_r, final_c, _, final_t = unpack(path[end])
        shifted_final_t = final_t - time_shift

        # Enforce basic rules
        shifted_final_t = max(1, shifted_final_t)
        shifted_final_t = min(shifted_final_t, calctx.ctx.nSteps)

        # Don't really need to go to depthLimit. shifted_depthLimit should be enough
        # TODO - PREVENT JUMPOVER FOR EACH TO HORIZON
        @debug "fr $(final_r), fc $(final_c), tfrom $(t_from), tto $(depthLimit)"
        for shifted_t ∈ shifted_final_t:calctx.ctx.nSteps,
            dr ∈ -STEP_SAFETY_BUFFER:STEP_SAFETY_BUFFER,
            dc ∈ -STEP_SAFETY_BUFFER:STEP_SAFETY_BUFFER

            calctx.occupancy[final_r+dr, final_c+dc, shifted_final_t:calctx.ctx.nSteps] .=
                true
            if can_be_occupied(final_r + dr, final_c + dc, calctx.ctx)
                for (v_end, v_beg) ∈ jumpover_knockoff_v_pairs(
                    final_r + dr,
                    final_c + dc,
                    shifted_t,
                    calctx.ctx,
                )

                    index_to_knock_off = vertices2edgenum(v_end, v_beg, calctx.ctx)
                    if !isnothing(index_to_knock_off)
                        calctx.G3DT.weights.nzval[index_to_knock_off] = COST_IMPOSSIBLE
                    end
                end
            end
        end
    end

    @assert length(calctx.G3DT.weights.nzval) == size_nzval @sprintf(
        "Size of G3DT nzval changed from %s to %s",
        string(calctx.G3DT.weights.nzval),
        string(size_nzval)
    )
    return nothing
end


"""
$(TYPEDSIGNATURES)

"""
function find_segments(segment::AbstractVector{Bool})
    list_segments = []

    searching_from = 1
    while searching_from < length(segment) - 1
        # Time to start the first segment
        t1 = findfirst(isequal(false), segment[searching_from:end])

        # If nothing is found, no more segments. Bye bye
        isnothing(t1) && break


        # Extend the first segment as much as possible
        t1 = t1 + searching_from - 1
        t2 = findfirst(isequal(true), segment[t1+1:end])

        # If nothing is found, it means only `empties` until latest_time
        if isnothing(t2)
            t2 = length(segment)
        else
            t2 = t2 + t1 - 1
        end

        push!(list_segments, (t1, t2))
        searching_from = t2 + 1
    end
    return list_segments
end


"""
$(TYPEDSIGNATURES)

Determines a list of segment (t1, t2) where within each segment dest is completely free. Just before t1 and just after t2 are not free.
The search starts at `1` and ends no later than `depthLimit` steps after that `1`.
The times are in shifted time
"""
function list_time_segments(dest_rcd::Trcd, calctx::AStar_CalculationContext)
    @debug "$(stimer())        --- List segments: Looking for segments from: 1"

    # Force stop before end of times since the last slice is set at all-busy
    nSteps = calctx.ctx.nSteps - 1
    dest_r, dest_c, _ = unpack(dest_rcd)

    # Anywhere where impossible is marked as true.

    # Find all spots where the search cannot take place since too expensive
    # 1) Where is the occupancy matrix busy?
    mask = vec(calctx.occupancy[dest_r, dest_c, 1:nSteps]) .== true

    # 2) Nothing to look for before 1...
    mask[1:1] .= true

    # 3) ...or after just under depthLimit steps later (if start at 1, stop at depthLimit)
    list_segments = find_segments(mask)

    @debug "$(stimer())        --- New list of time segments: $(list_segments)"
    return list_segments
end


"""
$(TYPEDSIGNATURES)

!!!
    TODO: We should only run the loop such that the time between t and t2 is always enough to complete the task to be performed at destination. Maybe means we should add the desination only after the constraints of adding all paths have been added.]

"""
function warp_travel_to_destination!(
    dest_rcd::Trcd,
    list_segments,
    calctx::AStar_CalculationContext,
)
    for (t1, t2) ∈ list_segments
        for t ∈ t1:(t2-1)
            src_vertex = c2v_rcdt(as_rcdt(dest_rcd, t), calctx.ctx)
            dst_vertex = c2v_rcdt(as_rcdt(dest_rcd, t + 1), calctx.ctx)
            i = vertices2edgenum(calctx.ctx.G3DT, dst_vertex, src_vertex)
            calctx.G3DT.weights.nzval[i] = COST_WARP_TRAVEL
        end
    end
    return nothing
end


"""
$(TYPEDSIGNATURES)

3D path search. This is the key function that plans a path that satisfies the map and all existing dynamic obstacles.

- start and dest are Trcdt

- end point is a line in 3D. To arrive as early as possible means penalising delays. Transitions through time located
  at end point should be 0 when staying anywhere else costs time.

- [https://stackoverflow.com/questions/48977068/how-to-add-free-edge-to-graph-in-lightgraphs-julia/48994712#48994712]
  Please pay attention to the fact that zero-weight edges are discarded by add_edge!. This is due to the way the graph
  is stored (a sparse matrix). A possible workaround is to set a very small weight instead.
"""
function path_a_b_3D(
    src_rcd::Trcd,
    dst_rcd::Trcd,
    time_shift::Int64,
    list_allocation_paths::Vector{TPath_rcdt},
    astarcalctx::AStar_CalculationContext,
)

    @debug @sprintf("%s     Starting search", stimer())

    # Create occupancy matrix - false is NOT busy - true is busy
    fill_blockages!(time_shift, list_allocation_paths, astarcalctx)

    # Get the list of empty segments at destination seaching from after the start
    # Impossible to complete a path in less than min_time
    # Times are in shifted time.
    list_segments = list_time_segments(dst_rcd, astarcalctx)

    @debug @sprintf(
        "%s    --- Path search: found empty segments: %s",
        stimer(),
        string(list_segments)
    )

    # Add destination warp travel on each of the empty segments
    @debug "$(stimer())    --- Path search: Adding warp travel to destination: (dst_rcd)"
    warp_travel_to_destination!(dst_rcd, list_segments, astarcalctx)

    # Loop through all possible time segments
    src_v = c2v_rcd(src_rcd, astarcalctx.ctx)

    @assert can_be_occupied(src_rcd, astarcalctx.ctx) "IMPOSSIBLE TO PLAN - THE SOURCE LOCATION $(src_rcd) IS NOT EMPTY ON THE PLAN."
    @assert can_be_occupied(dst_rcd, astarcalctx.ctx) "IMPOSSIBLE TO PLAN - THE TARGET LOCATION $(dst_rcd) IS NOT EMPTY ON THE PLAN."

    path_v = []
    path_w = []
    for (t1, t2) ∈ list_segments
        # Try to get to t2 and keep enough time to load/unload.
        # If possible earlier, we can throughwrap travel accounting for time load/unload
        latest_time = t2
        latest_time < t1 && continue

        @debug "$(stimer())    --- Path search: Searching reverse path from t = $(t2)  back to: $(min_time)"
        dst_v = c2v_rcdt(as_rcdt(dst_rcd, latest_time), astarcalctx.ctx)
        path_v, path_w = path_vertices(astarcalctx.ctx.G3DT, src_v, dst_v, astarcalctx)

        !isempty(path_v) && break
    end

    if isempty(path_v)
        @debug "$(stimer())    --- Path search: NO PATH FOUND !!!!"
    else
        @debug "$(stimer())    --- Path search: Path found with $(length(best_path_rcdt)) vertices and final time $(best_path_rcdt[end][4])."
    end

    return format_path(path_v, path_w, time_shift, astarcalctx.ctx)
end



