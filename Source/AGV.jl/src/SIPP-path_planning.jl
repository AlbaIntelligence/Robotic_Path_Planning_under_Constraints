"""
$(TYPEDSIGNATURES)

Calculate heuristic distance between two SIPP states using Euclidean distance.

# Arguments
- `cfg1::Trcd`: Source configuration (row, column, direction)
- `cfg2::Trcd`: Target configuration (row, column, direction)

# Returns
- `Float64`: Euclidean distance between the two positions

# Examples
```julia
h = state_heuristic(Trcd(1, 1, 0), Trcd(5, 5, 2))
```

# Notes
- Uses Euclidean distance for position-based heuristic
- Direction changes are not included in the heuristic
- Consider pre-calculating point-to-point A* path durations for better heuristics
"""
function state_heuristic(cfg1::Trcd, cfg2::Trcd)
    # Making 3 turns is the cost of doing 1 turn in the other direction
    # delta_d = abs(cfg2[3] - cfg1[3]) == 3 ? 1 : abs(cfg2[3] - cfg1[3])
    # return (STEPS_FWD * abs(cfg2[1] - cfg1[1]) + STEPS_FWD * abs(cfg2[2] - cfg1[2]) + STEPS_TRN * delta_d)

    # Euclidean distance
    return sqrt((cfg2[1] - cfg1[1])^2 + (cfg2[2] - cfg1[2])^2)
end

"""
$(TYPEDSIGNATURES)

Calculate heuristic distance between two SIPP state contexts.

# Arguments
- `g1::SIPPStateContext`: Source SIPP state context
- `g2::SIPPStateContext`: Target SIPP state context

# Returns
- `Float64`: Euclidean distance between the two state configurations

# Examples
```julia
h = state_heuristic(context1, context2)
```

# Notes
- Delegates to the configuration-based state_heuristic function
- Used in SIPP algorithm for state prioritization
"""
state_heuristic(g1::SIPPStateContext, g2::SIPPStateContext) =
    state_heuristic(g1.cfg, g2.cfg)


"""
$(TYPEDSIGNATURES)

Improved heuristic function for bounded suboptimal search algorithms.

# Arguments
- `h::Float64`: Heuristic cost estimate
- `g::Float64`: Actual cost from start to current state
- `ϵ::Float64`: Suboptimality bound (ϵ ≥ 1, where 1 = optimal)

# Returns
- `Float64`: Improved f-score for bounded suboptimal search

# Examples
```julia
f_score = Φ(heuristic_cost, actual_cost, 1.1)  # 10% suboptimal
```

# Notes
Implements the "Convex Downward Parabola" from:
"Conditions for Avoiding Node Re-Expansions for Bounded Suboptimal Search" (2019)
by Jingwei Chen and Nathan R. Sturtevant.

This function improves on traditional A* f-score (f = g + h) by providing
better bounds for suboptimal search algorithms. The convexity properties
help avoid unnecessary node re-expansions.

# References
- Chen, J., & Sturtevant, N. R. (2019). Conditions for Avoiding Node Re-Expansions for Bounded Suboptimal Search.
"""
Φ(h, g, ϵ) = (g + (2 * ϵ - 1) * h + sqrt((g - h)^2 + 4 * ϵ * g * h)) / (2 * ϵ)


"""
$(TYPEDSIGNATURES)

"""
function path_a_b_3D(
    src_rcd::Trcd,
    dst_rcd::Trcd,
    time_shift::Int64,
    list_allocation_paths::Vector{TPath_rcdt},
    sippcalctx::SIPP_CalculationContext,
)

    @debug "$(stimer())     Starting search"

    # Create intervals
    sippcalctx.occupancy = fill_blockages!(time_shift, list_allocation_paths, sippcalctx)

    result_paths = anytime_SIPP(
        src_rcd,
        dst_rcd,
        50.0,
        0.9,
        time_shift,
        list_allocation_paths,
        sippcalctx,
    )

    # We only keep the last path
    best_path_rcdt = [as_rcdt(p[1], p[2]) for p ∈ result_paths[end][1]]

    if isempty(best_path_rcdt)
        @debug "$(stimer())    --- Path search: NO PATH FOUND !!!!"
    else
        @debug "$(stimer())    --- Path search: Path found with $(length(best_path_rcdt)) vertices and final time $(best_path_rcdt[end][4])."
    end

    @assert path_rcdt_is_stricly_increasing(best_path_rcdt) "WRONG RESULT - PATH IS NOT INCREASING."

    return best_path_rcdt, [], []
end



"""
$(TYPEDSIGNATURES)

TODO: Convert to iterator.
"""
function anytime_SIPP(
    src::Trcd,
    dst::Trcd,
    ϵ_start::Float64,
    ϵ_target::Float64,
    time_shift::Int64,
    list_allocation_paths,
    sippctx::SIPP_CalculationContext;
    iterationlimit::Int64=typemax(Int64),
)

    # Initialise the calculation context

    # Populate the occupancy of the intervals at every single location.
    # TODO make that incremental.
    sippctx.occupancy = fill_blockages!(time_shift, list_allocation_paths, sippctx)

    sippctx.exploredstates = Dict{SIPPState,SIPPStateContext}()

    ϵ_prime = ϵ_start

    PQ_open = PriorityQueue{SIPPState,Float64}()
    PQ_inconsistent = PriorityQueue{SIPPState,Float64}()

    # The starting state is initialised (using the Φ function to optimise the number of re-expansions)
    # The source comes from nowhere and starts moving at time 0.
    src_state = SIPPState(cfg=src, interval=(0, 0), isoptimal=true)
    g_score = 0
    h_score = Φ(state_heuristic(src, dst), g_score, ϵ_start)
    f_score = g_score + ϵ_prime * h_score
    sippctx.exploredstates[src_state] =
        SIPPStateContext(; g_score, h_score, f_score, camefrom=nothing)
    enqueue!(PQ_open, src_state, sippctx.exploredstates[src_state].f_score)

    dst_state = SIPPState(cfg=dst, interval=(0, 0), isoptimal=true)
    g_score = STEPS_IMPOSSIBLE
    h_score = Φ(state_heuristic(dst, dst), g_score, ϵ_start)
    f_score = g_score + ϵ_prime * h_score
    sippctx.exploredstates[dst_state] =
        SIPPStateContext(; g_score, h_score, f_score, camefrom=dst_state)


    result_paths = []
    while ϵ_prime > ϵ_target
        # Decrease ϵ_prime
        ϵ_prime /= 1.2

        # Move all non-optimal states into Open states
        merge!(PQ_open, PQ_inconsistent)
        empty!(PQ_inconsistent)

        # Update all the f_scores in PQ_open using the new \epsilon
        for node ∈ keys(PQ_open)
            PQ_open[node] = Φ(
                state_heuristic(node.cfg, dst),
                sippctx.exploredstates[node].g_score,
                ϵ_prime,
            )
        end

        @debug """
               ############################################################################################
               Starting improvepath! with ϵ = $(ϵ_prime). Sizes PQ_open = $(length(PQ_open)),PQ_closed = $(length(PQ_inconsistent))
               """
        improved_path, PQ_closed = improve_path!(
            dst_state,
            ϵ_prime,
            PQ_open,
            PQ_inconsistent,
            time_shift,
            sippctx;
            iterationlimit=iterationlimit,
        )

        @debug """
               New path created with ϵ = $(ϵ_prime). New sizes PQ_open = $(length(PQ_open))
                   PQ_inconsistent = $(length(PQ_inconsistent)), improved path = $(length(improved_path)) and PQ_closed = $(length(PQ_closed))
               """
        push!(result_paths, (improved_path, PQ_closed))

        # Reset ϵ
        gh_PQ_open = [
            sippctx.exploredstates[s].g_score + sippctx.exploredstates[s].h_score for
            s in keys(PQ_open)
        ]
        gh_PQ_inconsistent = [
            sippctx.exploredstates[s].g_score + sippctx.exploredstates[s].h_score for
            s in keys(PQ_inconsistent)
        ]

        if isempty(PQ_open)
            break
        else
            d = round(minimum(append!(gh_PQ_open, gh_PQ_inconsistent)); digits=3)
            if d != 0.0
                ϵ_prime = min(ϵ_prime, sippctx.exploredstates[dst_state].g_score / d)
                ϵ_prime = round(ϵ_prime; digits=3)
                @debug "New calculated ϵ = $(ϵ_prime). Sizes PQ_open = $(length(PQ_open)), PQ_closed = $(length(PQ_inconsistent))\n"
            end
        end
    end
    return result_paths
end


"""
$(TYPEDSIGNATURES)

"""
function anytime_SIPP(
    task::TTask,
    ϵ_start::Float64,
    ϵ_target::Float64,
    time_shift::Int64,
    list_allocation_paths,
    sippctx::SIPP_CalculationContext;
    iterationlimit::Int64=typemax(Int64),
)
    return anytime_SIPP(
        as_rcd(task.start),
        as_rcd(task.target),
        ϵ_start,
        ϵ_target,
        time_shift,
        list_allocation_paths,
        sippctx;
        iterationlimit=iterationlimit,
    )
end


"""
$(TYPEDSIGNATURES)

"""
function improve_path!(
    dst::SIPPState,
    ϵ::Float64,
    PQ_open,
    PQ_inconsistent,
    time_shift::Int64,
    sippctx::SIPP_CalculationContext;
    iterationlimit::Int64=typemax(Int64),
)

    # The CLOSED queue keeps track of fully explored (with optimal or sub-optimal scores)
    # PQ_closed = PriorityQueue{GraphNode,Float64}()
    PQ_closed = SIPPState[]

    interruption_count = 0
    while !isempty(PQ_open) && interruption_count < iterationlimit
        interruption_count += 1
        @debug "\n############################################################################################\n"
        @debug "Iteration $(interruption_count) - PQ_open - number of nodes = $(length(PQ_open))\n"
        # println(
        #     "Iteration $(interruption_count) - PQ_open - number of nodes = $(length(PQ_open))\n",
        # )
        cur = dequeue!(PQ_open)
        push!(PQ_closed, cur)

        # If we have reached we don't need to continue.
        (cur.cfg == dst.cfg) && (
            @debug "            dst is reached with at iteration $(interruption_count) and " *
                   "$(length(PQ_closed)) states in the CLOSED set.\n";
            break
        )

        cur_row, cur_col, src_dir = unpack(cur.cfg)
        cur_current_time = sippctx.exploredstates[cur].g_score

        # If the currently best temporary f score to reach the goal is better than
        # exploring the best state, no point in continuing.
        # Note: The published algo runs the `while` loop as long as the destination's f_score  exceeds
        # the minimum all of the nodes in PQ_open. Since we just popped the node with the lowest score,
        # we can compare with that popped value. By construction, this is enough.

        # Mark the best node as CLOSED
        (sippctx.exploredstates[dst].f_score ≤ sippctx.exploredstates[cur].f_score) && (
            @debug "PQ_closed - adding nodes = ($(cur_row), $(cur_col), $(src_dir), $(cur_current_time)) - " *
                   "f_score = $(sippctx.exploredstates[cur].f_score) opt. = $(cur.isoptimal)\n";
            break
        )

        # This list is the list of safe intervals at the location of s. The values are BLANKED before time_shift, and NOT shifted
        src_safe_intervals = list_safe_intervals(
            sippctx.occupancy[cur_row, cur_col],
            sippctx;
            time_shift=time_shift,
        )

        # s represents an AGV being at a specific location at a specific time. It is therefore located in a unique interval.
        s_containing_interval = containing_interval(src_safe_intervals, cur_current_time)

        if isnothing(s_containing_interval)
            @debug "State $(cur) with safe intervals $(src_safe_intervals) has no containing intervals!!!! " *
                   "Occupancy: $([s for s in sippctx.occupancy[cur_row, cur_col].segments if s != (0,0)]) at time: $(cur_current_time)\n"
            continue
        else
            @debug "State containing intersection: ($(s_containing_interval[1]), $(s_containing_interval[2]))\n"
        end

        src_safeintv_beg, src_safeintv_end = s_containing_interval

        # If the values don't make sense, skip to next interval. We could prebably make the tests with strict comparison...
        if !(
            0 ≤ src_safeintv_beg &&
            src_safeintv_beg ≤ src_safeintv_end ≤ sippctx.ctx.nSteps
        )
            continue
        end

        # Each move is of type TMove(from::Trcdt, dest::Trcdt, no. of steps, cost) (cost: if necessary to make a move impossible for A*)
        potential_moves = generate_moves(cur.cfg, sippctx.ctx)
        @debug "Moves: Need to consider $(length(potential_moves)) moves\n"

        for move ∈ potential_moves
            @debug "\n    Current move $(move)\n"

            # WARNING: Moves are generated assuming that the AGV starts from time 1.
            (_, _, _, move_time_start) = unpack(move.from)
            (s_prime_row, s_prime_col, s_prime_dir, move_time_final) = unpack(move.dest)
            s_prime_rcd = Trcd(s_prime_row, s_prime_col, s_prime_dir)

            # How long is the move?
            move_time = move_time_final - move_time_start

            # Adjust starting and arrival times from where the source is
            move_time_start = cur_current_time
            move_time_final = cur_current_time + move_time

            # If the remaining length of the containing interval where s is located is not long enough to effect that move,
            # no point in exploring that possibility
            (src_safeintv_end - cur_current_time < move_time) &&
                (@debug "            src safe interval too short\n"; continue)

            # Let's look at the list of safe intervals at cfg_new to study the overlap
            # TODO: Find a way to avoid deep copies. Probably push / pop?
            clean_busy_intervals = deepcopy(sippctx.occupancy[s_prime_row, s_prime_col])

            # Considering the interval in which s is located, evereything before the interval containing s is out of reach (no backward in time)
            # and everything after the end of the interval currently containing s is also imposibble to reach.
            push!(clean_busy_intervals, (0, max(0, src_safeintv_beg - 1)))
            push!(
                clean_busy_intervals,
                (min(sippctx.ctx.nSteps, src_safeintv_end + 1), sippctx.ctx.nSteps),
            )

            # We can extract the exact intersection of the 2 intervals. new_safe_intervals is NOT shifted.
            new_safe_intervals =
                list_safe_intervals(clean_busy_intervals, sippctx; time_shift=time_shift)

            # if no interval, then no point in continuing
            isempty(new_safe_intervals) && continue

            # We review each interval in the list of safe intervals at cfg_new.
            # For each of them, we start at the original interval containing s and wait as little as possible
            # to reach the destination.
            @debug "    $(length(new_safe_intervals)) intervals to consider\n"
            for (s_prime_safeintv_beg, s_prime_safeintv_end) ∈ new_safe_intervals
                @debug "            Interval: $(s_prime_safeintv_beg), $(s_prime_safeintv_end)\n"
                # If the destination interval is not long enough (for example free for 3 steps when we need to
                # us 15 steps to rotate), then no point considering that interval and we consider the next one.
                (s_prime_safeintv_end - s_prime_safeintv_beg < move_time) &&
                    (@debug "            dst safe interval too short\n"; continue)

                # t_start and t_end are the minimum and maximum times at which the AGV can reach cfg_new based only on the
                # minimum and maximum times it can leave the safe interval of s.
                # Note that the test of src_safeintv_end - src_current_time < move_time guarantees that
                # t_latest_start > t_earliest_start
                # The only useful information is t_earliest_start. Others are FYI only.
                t_earliest_start = max(cur_current_time, s_prime_safeintv_beg - move_time)
                t_latest_start = min(src_safeintv_end, s_prime_safeintv_end - move_time)

                t_earliest_arrival = max(cur_current_time + move_time, s_prime_safeintv_beg)
                t_latest_arrival = min(src_safeintv_end + move_time, s_prime_safeintv_end)

                !(
                    cur_current_time ≤ t_earliest_start ≤ t_latest_start ≤ src_safeintv_end
                ) && (@debug "            src earliest / latest not satisfied\n"; continue)

                !(
                    s_prime_safeintv_beg ≤
                    t_earliest_arrival ≤
                    t_latest_arrival ≤
                    s_prime_safeintv_end
                ) && (@debug "            dst earliest / latest not satisfied\n"; continue)

                @debug "            Start: earliest = $(t_earliest_start), latest = $(t_latest_start) - " *
                       "Arrival earliest = $(t_earliest_arrival), latest = $(t_latest_arrival)\n"

                t_earliest_arrival_shifted = t_earliest_arrival - time_shift
                s_prime_rcdt =
                    Trcdt(s_prime_row, s_prime_col, s_prime_dir, t_earliest_arrival_shifted)
                @debug "            t_earliest_arrival_shifted = $(t_earliest_arrival_shifted)\n\n"

                # Consider adding to the non-optimal priority queue (false = as non-optimal)
                optimal_status = [false]

                # And if actually optimal, consider adding to the optimal priority queue. Optimality is contagious.
                if cur.isoptimal
                    push!(optimal_status, true)
                end

                # Add if the node has not been already considered AND improves timings
                # Note: the from - 1 is necessary because t_earliest_start is calculated of the beginning of the
                # _safe_ interval and not from where the AGV is currently located in time.
                for status ∈ optimal_status
                    s_prime = SIPPState(;
                        cfg=s_prime_rcd,
                        interval=(s_prime_safeintv_beg, s_prime_safeintv_end),
                        isoptimal=status,
                    )

                    # If the state has never been seen before
                    if !haskey(sippctx.exploredstates, s_prime)
                        # Mark explored
                        # Keep track of its source and scores in a node
                        sippctx.exploredstates[s_prime] = SIPPStateContext(;
                            g_score=STEPS_IMPOSSIBLE,
                            h_score=STEPS_IMPOSSIBLE,
                            f_score=STEPS_IMPOSSIBLE,
                            camefrom=cur,
                        )
                        @debug "    Creating SIPPState $(s_prime_rcdt) - all scores = $(STEPS_IMPOSSIBLE) - opt. = $(status)\n"
                    end

                    if sippctx.exploredstates[s_prime].g_score > t_earliest_arrival_shifted
                        sippctx.exploredstates[s_prime].g_score = t_earliest_arrival_shifted
                        @debug "    Updating SIPPState $(s_prime_rcdt) - g_score = $(sippctx.exploredstates[s_prime].g_score) - opt. = $(status)\n"

                        if s_prime ∉ PQ_closed
                            if s_prime.isoptimal
                                sippctx.exploredstates[s_prime].f_score =
                                    ϵ * (
                                        sippctx.exploredstates[s_prime].g_score +
                                        state_heuristic(s_prime.cfg, dst.cfg)
                                    )
                            else
                                sippctx.exploredstates[s_prime].f_score =
                                    sippctx.exploredstates[s_prime].g_score +
                                    ϵ * state_heuristic(s_prime.cfg, dst.cfg)
                            end

                            PQ_open[s_prime] = sippctx.exploredstates[s_prime].f_score
                            @debug "    Queuing to PQ_open: SIPPState $(s_prime_rcdt) - f_score = $(sippctx.exploredstates[s_prime].f_score) - opt. = $(status)\n"
                        else
                            PQ_inconsistent[s_prime] =
                                sippctx.exploredstates[s_prime].f_score
                            @debug "    Queuing to PQ_inconsistent: SIPPState $(s_prime_rcdt) - f_score = $(sippctx.exploredstates[s_prime].f_score) - opt. = $(status)\n"
                        end
                    end
                end
            end
        end
    end

    # PQ_closed contains all the nodes that are pootentially on the path. Reverse from destination to find
    # the actual nodes on the path.
    @debug "Finished constructing PQ_closed with length = $(length(PQ_closed))\n"
    # println("Finished constructing PQ_closed with length = $(length(PQ_closed))\n")

    current_rcd = dst.cfg
    current_StateContext =
        [sippctx.exploredstates[cs] for cs in PQ_closed if cs.cfg == current_rcd]

    result_path = []
    if isempty(current_StateContext)
        @debug "Could not find the destinaton in the list of closed nodes!!!!!"
        # println("Could not find the destinaton in the list of closed nodes!!!!!")
    else
        current_StateContext = current_StateContext[1]
        backward_path = [current_StateContext]

        while true
            came_from = current_StateContext.camefrom
            came_from === nothing && break
            current_StateContext = sippctx.exploredstates[came_from]
            push!(backward_path, current_StateContext)
        end

        reverse!(backward_path)
        @debug "Created backward path with length = $(length(backward_path))\n"

        # Shift some values within the path to have the right arrival times
        for i ∈ 1:length(backward_path)-1
            from = backward_path[i]
            to = backward_path[i+1]
            push!(
                result_path,
                (
                    to.camefrom.cfg,
                    from.g_score,
                    from.h_score,
                    from.f_score,
                    to.camefrom.interval,
                    to.camefrom.isoptimal,
                ),
            )
        end

        cs = backward_path[end]
        push!(
            result_path,
            (dst.cfg, cs.g_score, cs.h_score, cs.f_score, cs.camefrom.interval, true),
        )
    end

    return result_path, PQ_closed
end
