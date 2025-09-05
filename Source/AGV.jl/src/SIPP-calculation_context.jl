"""
$(TYPEDFIELDS)

"""
@with_kw mutable struct SIPP_CalculationContext <: AbstractCalculationContext
    ctx::TContext
    obstacles::TPathList_rcdt
    occupancy::AbstractArray{SIPPBusyIntervals,2}
    exploredstates::Dict{SIPPState,SIPPStateContext}

    # A* algo used for 2D path finding
    closed_set::Vector{Bool}
    g_score::Vector{Int64}
    came_from::Vector{Int64}
    edge_mask::BitArray{1}
end


"""
$(TYPEDSIGNATURES)

"""
function create_calculation_context(ctx::TContext, algo::AnytimeSIPP)
    return SIPP_CalculationContext(
        ctx,
        TPath_rcdt[],
        Array{SIPPBusyIntervals,2}(undef, ctx.nRow, ctx.nCol),
        Dict{SIPPState,SIPPStateContext}(),
        zeros(Bool, ctx.nVertices),
        zeros(Int64, ctx.nVertices),
        deepcopy(ctx.G3DT.weights.nzval),
        zeros(Bool, ctx.nEdges),
    )
end


"""
$(TYPEDSIGNATURES)

"""
can_be_occupied(r::Int64, c::Int64, sippctx::SIPP_CalculationContext)::Bool =
    can_be_occupied(r, c, sippctx.ctx)


"""
$(TYPEDSIGNATURES)

"""
SIPPBusyIntervals(sippctx::SIPP_CalculationContext) = SIPPBusyIntervals(sippctx.ctx.nSteps)


"""
$(TYPEDSIGNATURES)

"""
list_safe_intervals(
    stack::SIPPBusyIntervals,
    sippctx::SIPP_CalculationContext;
    time_shift::Int64 = 0,
) = list_safe_intervals(stack, sippctx.ctx.nSteps; time_shift = time_shift)


"""
$(TYPEDSIGNATURES)

"""
function containing_interval(
    list_intervals::SIPPBusyIntervals,
    t::Int64,
    sippctx::SIPP_CalculationContext;
    time_shift = 1,
)::Union{SIPPInterval,Nothing}
    return containing_interval(
        list_safe_intervals(list_intervals, sippctx; time_shift = time_shift),
        t,
    )
end


"""
$(TYPEDSIGNATURES)

This is mostly a copy of `fill_blocages` that fills the entire occupancy matrix. Here we only identify a single (r, c).
"""
function fill_blockages!(
    time_shift::Int64,
    list_allocation_paths,
    sippctx::SIPP_CalculationContext,
)

    @assert time_shift ≥ 0 "Attempting to shift the planning by a negative time."

    nRow = sippctx.ctx.nRow
    nCol = sippctx.ctx.nCol

    # Create an empty interval matrix
    intervalmap = Array{SIPPBusyIntervals,2}(undef, nRow, nCol)
    for row ∈ 1:nRow, col ∈ 1:nCol
        intervalmap[row, col] = SIPPBusyIntervals(sippctx)
        if !can_be_occupied(row, col, sippctx)
            push!(intervalmap[row, col], (0, sippctx.ctx.nSteps))
        end
    end

    # Go through each of the paths to block. In principle, one path = one AGV
    @debug "n paths = $(length(list_allocation_paths))"
    for path ∈ list_allocation_paths
        println("Path: $(path)")

        for path_idx ∈ 1:(length(path)-1)

            # Starting and ending points of the segment to fill up as blockages. Direction is not relevant.
            r1, c1, _, t1 = unpack(path[path_idx])
            r2, c2, _, t2 = unpack(path[path_idx+1])
            @debug "Filling from $(r1), $(c1), $(t1) to  $(r2), $(c2), $(t2)"

            # We should not have any move where the time does not change or decreases
            # For the moment, we throw an error and break the loop
            if t2 < t1
                @error "\n"
                @error "******* WARNING *******. \n"
                @error "fill_blocages: two successive times are not strictly increasing (moving from $(r1), $(c1), $(t1) to  $(r2), $(c2), $(t2)) for path: $(path) at intdex $(path_idx). \n"
                @error "******* WARNING *******. \n"
                @error "\n"
                break
            end

            # Make sure that the segment falls at least in part within the depth starting from time_shift
            if t2 < time_shift
                continue
            end

            # For the moment, we do NOT shift to ensure that the list of empty intervals is also NOT shifted.
            # shifted_t_beg = t1 - time_shift
            # shifted_t_end = t2 - time_shift
            shifted_t_beg = t1 - 0
            shifted_t_end = t2 - 0

            # Enforce very conservative basic rules
            # beginning has to be at least 1, end doesn't exceed max depth.
            # TODO: restore the depth_limit mechanism.
            shifted_t_beg = max(1, shifted_t_beg)
            shifted_t_beg = min(shifted_t_beg, sippctx.ctx.nSteps)

            # if end before beginning, beginning is not adjusted, end is. Should never happen given @assert above.
            shifted_t_end = max(shifted_t_beg, shifted_t_end)
            shifted_t_end = min(shifted_t_end, sippctx.ctx.nSteps)

            # Fill occupancy
            # THIS ASSUMES THAT (r1, c1) and (r2, c2) are identical or contiguous.
            # Also occludes an entire area around to keep the +/- STEP_SAFETY_BUFFER free around.
            # TODO: If we merge successive location, CHANGE TO FULL INTERMEDIARY!!!
            @debug "Pushing the tuplet $(shifted_t_beg), $(shifted_t_end) into $(r1), $(c1) and $(r2), $(c2)"
            for dr ∈ -STEP_SAFETY_BUFFER:STEP_SAFETY_BUFFER,
                dc ∈ -STEP_SAFETY_BUFFER:STEP_SAFETY_BUFFER

                can_be_occupied(r1 + dr, c1 + dc, sippctx) &&
                    push!(intervalmap[r1+dr, c1+dc], (shifted_t_beg, shifted_t_end))
                can_be_occupied(r2 + dr, c2 + dc, sippctx) &&
                    push!(intervalmap[r2+dr, c2+dc], (shifted_t_beg, shifted_t_end))
            end
            @debug "Full filling from $(shifted_t_beg) to  $(shifted_t_end)"
            @debug "intervalmap $(r1), $(c1): $(intervalmap[r1, c1].segments)"
        end
    end
    return intervalmap
end
