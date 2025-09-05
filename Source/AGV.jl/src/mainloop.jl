"""
$(TYPEDSIGNATURES)

Initialise a list of plans for each AGV.
The first plan is to stay on their starting location to avoid messing arond with indices when iterating.
This first plan has no reason to ever be changed / replanned.
The first step of the plan is for the AGV to be at a spot and remain there immobile.
"""
function create_initial_plans(list_AGVs::Vector{TAGV})::Vector{TPlan}
    AGVs_plans = TPlan[]
    for a ∈ 1:length(list_AGVs)
        agv = list_AGVs[a]

        src_rcdt = as_rcdt(agv, 1)
        dst_rcdt = as_rcdt(agv, 2)

        first_step = TPlanStep(AGV2Task(agv), [src_rcdt, dst_rcdt], 2)

        plan = TPlan([first_step], TLocation(), TPath_rcdt(), 0)
        push!(AGVs_plans, plan)
    end
    return AGVs_plans
end


"""
$(TYPEDSIGNATURES)

TODO: complete paths are useless. Should only have a list after time_shift. Preallocate return list?
"""
function enumerate_paths(plan::TPlan, replanning_window_beg::Int64)::Vector{TPath_rcdt}
    l_rcdt = TPath_rcdt[]

    for s ∈ plan.steps
        if !isempty(s.path) && s.path[end][4] ≥ replanning_window_beg
            push!(l_rcdt, s.path)
        end
    end

    if !isempty(plan.path_to_park)
        push!(l_rcdt, plan.path_to_park)
    end

    @debug "Full path list_complete: $(l_rcdt)"
    return l_rcdt
end


"""
$(TYPEDSIGNATURES)

"""
function enumerate_all_paths(AGVs_Plan::Vector{TPlan}, replanning_window_beg::Int64)
    l = TPath_rcdt[]

    for p ∈ AGVs_Plan
        append!(l, enumerate_paths(p, replanning_window_beg))
    end
    return l
end


"""
$(TYPEDSIGNATURES)

Plan a single parking trip from `src` to `parking`.
"""
function plan_single_parking(
    src::Trcdt,
    parking::TLocation,
    AGVs_plans::Vector{TPlan},
    replanning_window_beg,
    calctx::AbstractCalculationContext,
)

    @info "$(stimer())        --- plan_single_parking from: $(src) to parking: $(parking.ID)"
    list_allocated_plans = enumerate_all_paths(AGVs_plans, replanning_window_beg)

    # Create a 'fake' parking task and plan to reach it
    path_rcdt, path_final_t = plan_task(src, as_rcd(parking), 0, list_allocated_plans, calctx)

    # If a plan is found, add it to the list of allocation plans (w/ parkings)
    if length(path_rcdt) > 0
        @debug  """
                $(stimer())        --- plan_single_parking: Allocating $(parking.ID) (final time: $(path_t))
                """
        @assert path_rcdt_is_stricly_increasing(path_rcdt)
                """
                The path $(path_rcdt) from $(src) to the parking $(parking) is malformmed with times not strictly increasing
                """

        return path_rcdt, path_final_t
    else
        @error "$(stimer()) COULD NOT ALLOCATE PARKING\n"
        return [], 0
    end
end



"""
$(TYPEDSIGNATURES)

Initialise a list of parkings: for each AGV, find a single best parking.
"""
function create_initial_parkings_allocation!(list_AGVs::Vector{TAGV}, AGVs_plans::Vector{TPlan}, calctx::AbstractCalculationContext)

    nAGVs = length(list_AGVs)
    @debug "$(stimer())    --- Initialise parkings. Number of AGVs to plan: $(nAGVs)"

    list_parking_times = list_completion_times(AGVs_plans, calctx.ctx.special_locations["parking"], calctx)

    AGVs_parking_dict = Dict{Int64,TLocation}()
    AGVs_parking_plans_dict = Dict{Int64,TPath_rcdt}()
    AGVs_parking_times_dict = Dict{Int64,Int64}()

    # We need to keep track of which parkings were already allocated to
    # remove them from the occupancy matrix
    list_AGVs_with_parking = Int64[]

    for _ ∈ 1:nAGVs
        best_pair = argmin(list_parking_times)
        best_parking = best_pair[1]
        best_AGV = best_pair[2]
        # best_time = list_parking_times[best_pair]

        @debug  """
                $(stimer())    --- Initialise parkings. AGV: $(best_AGV) chooses parking: $(best_parking) (cost: $(best_time))
                """

        src_rcdt = as_rcdt(AGVs_plans[best_AGV].steps[end].task.target, AGVs_plans[best_AGV].steps[end].time_completed)

        path_c, path_t =
            plan_single_parking(src_rcdt, calctx.ctx.special_locations["parking"][best_parking], AGVs_plans, 1, calctx)

        # If a plan is found, add it to the list of allocation plans (w/ parkings)
        if length(path_c) > 0
            @debug  """
                    $(stimer())    --- Initialise parkings. AGV: $(best_parking) has path to parking: $(best_AGV) (final time: $(path_t))
                    """
        else
            @error "$(stimer()) No transit to parking\n"
        end

        push!(AGVs_parking_dict, best_AGV => calctx.ctx.special_locations["parking"][best_parking])
        push!(AGVs_parking_plans_dict, best_AGV => path_c)
        push!(AGVs_parking_times_dict, best_AGV => path_t)

        # Add this parking to the list of allocated parkings
        push!(list_AGVs_with_parking, best_AGV)

        # Get rid of that pair by making them impossible to be chosen
        list_parking_times[:, best_AGV] .= COST_IMPOSSIBLE
        list_parking_times[best_parking, :] .= COST_IMPOSSIBLE
    end

    for a ∈ 1:nAGVs
        AGVs_plans[a].parking = AGVs_parking_dict[a]
        AGVs_plans[a].path_to_park = AGVs_parking_plans_dict[a]
        AGVs_plans[a].time_at_parking = AGVs_parking_times_dict[a]
    end

    return nothing
end


"""
$(TYPEDSIGNATURES)

"""
function best_combination(transfer_times)
    best_time = minimum(transfer_times)
    best_combination = argmin(transfer_times)
    best_task = best_combination[1]
    best_AGV = best_combination[2]

    return best_AGV, best_task, best_time
end


"""
$(TYPEDSIGNATURES)

"""
function replan_agv_from_time(
    AGV_to_plan::Int64,
    replanning_window_beg,
    AGVs_plans,
    list_allocated_paths,
    calctx::AbstractCalculationContext,
)::Vector{TPlanStep}

    plan_temp = [AGVs_plans[AGV_to_plan].steps[1]]

    # Note: If replanning tasks, the very first task is __NEVER__ replanned
    if length(AGVs_plans[AGV_to_plan].steps) == 1
        return plan_temp
    end

    for s ∈ 2:length(AGVs_plans[AGV_to_plan].steps)
        current_step = AGVs_plans[AGV_to_plan].steps[s]

        # If this step finishes before the replanning window, move on to the next
        if AGVs_plans[AGV_to_plan].steps[s-1].path[end][4] ≤ replanning_window_beg
            push!(plan_temp, current_step)
            continue
        end

        # Otherwise we need to completely replan it starting from where the previous step finished
        # Start an empty path starting at the very last known position
        step_task = current_step.task
        step_path = [AGVs_plans[AGV_to_plan].steps[s-1].path[end]]
        step_time_completed = AGVs_plans[AGV_to_plan].steps[s-1].path[end][4]

        # 0 - Replan from the end of previous task to the beginning of the new one
        # (that the transit from the last job to starting the next one)
        # If src and dst are identical, nothing to plan

        # 1 - First replan from end of previous task to the start of the new one
        # Get the tasks to replan (careful about posts / fences)
        src_rcd = as_rcd(step_path[end])
        dst_rcd = as_rcd(AGVs_plans[AGV_to_plan].steps[s].task.start)
        start_time = step_time_completed

        # TODO -- Do we need to actually acconut for it in subsequent calcs?
        load_time_buffer = paletting_time(AGVs_plans[AGV_to_plan].steps[s].task.start)

        path_rcdt, path_t = plan_task(src_rcd, dst_rcd, start_time + load_time_buffer, list_allocated_paths, calctx)

        # If a plan is found, add it to the list of allocation plans as well as the time to load/unload
        if length(path_rcdt) > 0
            append!(step_path, path_rcdt)
            step_time_completed = path_t

            @info   """
                    $(stimer())     Success of AGV $(AGV_to_plan) to transit from its task $(s-1) to its task $(s). Transit size: $(length(path_rcdt))
                    """
        else
            @error """
                    $(stimer())     ERROR - AGV $(AGV_to_plan) NO transit from its task $(s-1) to its task $(s). Transit size: $(length(path_rcdt))
                    """
        end

        # Adding staying on the spot for a while to load the palette. Add as single-step waits to match existing vertices.
        if load_time_buffer > 0
            lr, lc, ld, _ = unpack(step_path[end])
            append!(step_path, [as_rcdt(lr, lc, ld, step_time_completed + load_time_buffer)])
            step_time_completed = step_time_completed + load_time_buffer
        end

        # 2 - Next replan from start of new task to the target of the new task
        src_rcd = as_rcd(step_path[end])
        dst_rcd = as_rcd(AGVs_plans[AGV_to_plan].steps[s].task.target)
        unload_time_buffer = paletting_time(AGVs_plans[AGV_to_plan].steps[s].task.target)

        path_c, path_t =
            plan_task(src_rcd, dst_rcd, step_time_completed + unload_time_buffer, list_allocated_paths, calctx)

        # If a plan is found, add it to the list as a new tuple (since immutable)
        if length(path_c) > 0
            # Add to schedule: this best_task is allocated to the
            # best_AGV and update duration
            append!(step_path, path_c)
            step_time_completed = path_t

            @info @sprintf(
                "%s     Success of AGV %3d for execution of its task %3d. Additional path size = %d",
                stimer(),
                AGV_to_plan,
                s,
                length(path_c)
            )
        else
            @error @sprintf(
                "%s     ERROR - AGV %3d NO EXECUTION from its task %3d to its task %3d. Transit size: %d",
                stimer(),
                AGV_to_plan,
                s - 1,
                s,
                length(path_c)
            )
        end

        # Adding staying on the spot for a while to load the palette. Add as single-step waits to match existing vertices.
        if unload_time_buffer > 0
            lr, lc, ld, _ = unpack(step_path[end])
            # append!(step_path,
            #         [as_rcdt(lr, lc, ld, lt) for lt ∈ step_time_completed + 1:step_time_completed + unload_time_buffer])
            append!(step_path, [as_rcdt(lr, lc, ld, step_time_completed + unload_time_buffer)])
            step_time_completed = step_time_completed + unload_time_buffer
        end

        # Collect the results into a new step struct and push into the plan
        @debug @sprintf("%s         --- Pushing step %d replanned ", stimer(), s)
        push!(plan_temp, TPlanStep(step_task, step_path, step_time_completed))
    end

    return plan_temp
end




"""
$(TYPEDSIGNATURES)

Returns a path as list of CartesianIndex{4} and the time to perform that path.
"""
function plan_task(
    src_rcd::Trcd,
    dst_rcd::Trcd,
    time_shift::Int64,
    list_allocated_paths::Vector{TPath_rcdt},
    calctx::AbstractCalculationContext,
)

    # If src and dst are identical, nothing to plan
    if is_identical_locations(src_rcd, dst_rcd)
        @info stimer() * "--- plan_task: Start and destination are identical. No path to plan."
        return [], 0

    else
        # Plan the path
        @info "$(stimer()) --- plan_task: Planning from $(src) to $(dst) starting from time $(time_shift)"
        path_rcdt, _, _ = path_a_b_3D(src_rcd, dst_rcd, time_shift, list_allocated_paths, calctx)

        # TODO: Add path simplification to merge all movements in the same direction as one-by one to have a single path.
        # Prettier to write - BUT impact on performance?
        if length(path_rcdt) > 0
            @debug "$(stimer()) --- plan_task: Found path from ($(path_rcdt[1])) to ($(path_rcdt[end]))"
            return path_rcdt, path_rcdt[end][4]
        else
            return [], 0
        end
    end
end


"""
$(TYPEDSIGNATURES)

Returns a path as list of CartesianIndex{4} and the time to perform that path.

If the source is passed as Trcdt (instead of Trcd), the `t` component is used for the time shift.
"""
function plan_task(
    src_rcdt::Trcdt,
    dst_rcd::Trcd,
    list_allocated_plans::Vector{TPath_rcdt},
    calctx::AbstractCalculationContext,
)

    time_shift = src_rcdt[4]
    return plan_task(as_rcd(src_rcdt), dst_rcd, time_shift, list_allocated_plans, calctx)
end

"""
$(TYPEDSIGNATURES)

"""
plan_task(
    src_rcdt::Trcdt,
    dst_rcd::Trcd,
    time_shift::Int64,
    list_allocated_paths::Vector{TPath_rcdt},
    calctx::AbstractCalculationContext,
) = plan_task(as_rcd(src_rcdt), dst_rcd, time_shift, list_allocated_paths, calctx)


#######################################################################################################################
##
## Main allocation loop
##
#######################################################################################################################
"""
$(TYPEDSIGNATURES)

Main allocation loop
"""
function full_allocation(
    list_AGVs::Vector{TAGV},
    n_tasks::Int64,
    ctx::TContext;
    use_fixed_tasks = TTask[],
    queue_size = 10,
    algo::AbstractPathPlanning = AnytimeSIPP(),
)

    tick()

    ######################################################################
    #
    # PREAMBLE
    #
    ######################################################################

    # Preallocate memory for A* calculations
    calctx = create_calculation_context(ctx, algo)

    # At the start, no tasks is allocated. We use the optional list provided or populate.
    unallocated_tasks = TTask[]
    order_number = 1
    if isempty(use_fixed_tasks)
        for _ ∈ 1:queue_size
            push!(unallocated_tasks, generate_order!(order_number, ctx))
            order_number += 1
        end
    else
        unallocated_tasks = deepcopy(use_fixed_tasks)
    end


    # At the very beginning, every AGV starts from where it is.
    @debug stimer() * " --- Initialising data structures"
    nAGVs = length(list_AGVs)
    AGVs_plans::Vector{TPlan} = create_initial_plans(list_AGVs)
    create_initial_parkings_allocation!(list_AGVs, AGVs_plans, calctx)

    # Allocate each task one by one
    task_planning_counter = 0
    remaining_orders_no = n_tasks
    while !isempty(unallocated_tasks) && remaining_orders_no > 0
        task_planning_counter += 1

        @info @sprintf(
            "\n\n\n%s== %s\n== Task planning counter: %4d \n== Size of order queue: %3d \n%s",
            "=======================================================================================\n",
            stimer(),
            task_planning_counter,
            length(unallocated_tasks),
            "==\n==\n======================================================================================="
        )

        @printf(
            stdout,
            "%s Task planning counter: %4d == Size of order queue: %3d \n",
            stimer(),
            task_planning_counter,
            length(unallocated_tasks)
        )


        ######################################################################
        #
        # DETERMINE AND ALLOCATE NEXT TASK
        #
        ######################################################################

        # ### Optimal time for the best AGV/Task pair

        # Calculate all the current the cross time pairs between a task and an AGV starting from the end
        # of the current task allocations for that AGV. Result may be an empty matrix.
        # The times are from t = 2 (very beginning of the planning) since this is
        # this initial value specified in the AGVs Initialisation function.

        # Precalculate the optimal time to perform a task on its own. This is the time from
        # just arriving at the start TLocation, loading, transiting to the target TLocation and unloading.
        # This needs to be refreshed each time the list of tasks is changed
        # [TODO: Only refresh the newly added task]
        @info stimer() * " --- Calculating optimal task execution time"
        optimal_task_times = [task_optimal_perf(t, calctx) for t ∈ unallocated_tasks]

        @info stimer() * " --- Calculating list_completion_times: AGVs -> TASKS"
        cross_completion_times = list_completion_times(AGVs_plans, unallocated_tasks, optimal_task_times, calctx)

        # Sort all times in increasing order and find the shortest. This is the only pair AGV / Task
        # (if any) that will be added to the planning.
        best_AGV, best_task, best_time = best_combination(cross_completion_times)
        @info @sprintf(
            "\n%s     **** Best AGV: %s will attempt to execute the best task: %s\n\n",
            stimer(),
            list_AGVs[best_AGV].ID,
            unallocated_tasks[best_task].ID
        )


        # To prepare for the replanning, we need to keep in mind what was the latest time
        # of the best AGV (before adding new task). Any AGV with a plan already longer
        # than that will not be replanned.
        # Any AGV with time shorter will be replanned from its latest time before
        # that cutoff.
        replanning_window_beg = AGVs_plans[best_AGV].steps[end].time_completed
        replanning_window_end = replanning_window_beg + best_time
        @info @sprintf(
            "%s --- Replanning window start: %d, end: %d (with STEP_TO_COST_MULTIPLIER = %d)\n",
            stimer(),
            replanning_window_beg,
            replanning_window_end,
            STEP_TO_COST_MULTIPLIER
        )


        # Update the list of tasks of the best_AGV with the best_task and remove from
        # unallocated. Remove the newly allocated task from ``UnAllocatedTasks[]``.
        # The +1 is to ensure that the time is late than the beginning of the window to trigger its replanning
        push!(
            AGVs_plans[best_AGV].steps,
            TPlanStep(unallocated_tasks[best_task], TPath_rcdt(), replanning_window_beg + 1),
        )


        # [TODO We allocate and remove even if a plan has not been determined yet (which might not happen...)]
        @info @sprintf("%s Removing task %s from unallocated list\n", stimer(), unallocated_tasks[best_task].ID)
        deleteat!(unallocated_tasks, best_task)



        # Reorder all the AGVs in decreasing order of total (including updated) release
        # time. Store into  ``planning_list``.
        # By construction, that list will contain all the tasks which were previously
        # allocated + only one additional task.
        # The list should only contain entries where there is a new task added
        # to already  existing ``\alpha_i``. In other words, choosing an entry will
        # always guarantee that only a single new task is added to the Planning List.
        # We now have a new list of ``\alpha_i=[\alpha_{i, 0}, \tau_{i, 1}, , \tau_{i, 2}, ...]``
        # where AT MOST ONE of them has an additional task. This is the list to be
        # sorted in decreasing order of total time (total release time + time to
        #  achieve new task). ONLY ONE if a task was available or NOTHING if the
        # list of tasks was empty to start with.


        #######################################################################
        #
        # FOR EACH AGV, REPLAN THEIR LATEST TASK IN DECREASING ORDER OF TIME
        #
        #######################################################################

        # List the time at which the allocation plans are completed before the
        # new allocation. The longest is planned in priority
        # duration_allocated_tasks = [AGVs_plans[agv].steps[end].time_completed for agv ∈ 1:nAGVs]
        duration_allocated_tasks = [AGVs_plans[agv].time_at_parking for agv ∈ 1:nAGVs]

        # Adjust the the duration of the best_AGV (otherwise would still be at the value before
        # allocation) and sort in decreasing order.
        duration_allocated_tasks[best_AGV] = replanning_window_end
        planning_order = sortperm(duration_allocated_tasks, rev = true)

        @info @sprintf(
            "%s\n%s    Replanning in the following order: %s\n",
            "=======================================================================================",
            stimer(),
            string(planning_order)
        )


        # Iterating through the planning order and remove AGVs outside of the replanning window
        AGVs_to_skip = []
        for agv ∈ 1:nAGVs
            # Make sure we don't touch best_AGV
            if agv ≠ best_AGV
                tasks_plan_time = AGVs_plans[agv].steps[end].time_completed

                # This check should be useless, but...
                time_at_parking =
                    isempty(AGVs_plans[agv].path_to_park) ? tasks_plan_time : AGVs_plans[agv].time_at_parking


                # 1)
                # let's check if the existing plan of the tasks of this AGV (excluding parking)
                # is above the cutoff time. If so, nothing to do.
                # + 1 is just ot be safe
                if tasks_plan_time > replanning_window_end + 1
                    push!(AGVs_to_skip, agv)
                    @debug @sprintf(
                        "%s     Planning AGV: Removing AGV %s from replanning. Latest time (exc. parking) %d is later than the best_AGV replanning window",
                        stimer(),
                        list_AGVs[agv].ID,
                        tasks_plan_time
                    )


                    # 2)
                    # let's check if the existing plan of the tasks of this AGV (including parking)
                    # is below the previous cutoff time. If so, nothing to do.
                elseif time_at_parking ≤ replanning_window_beg
                    push!(AGVs_to_skip, agv)
                    @debug @sprintf(
                        "%s     Planning AGV: Removing AGV %s from replanning. AGV is parked on %d is before the replanning window.",
                        stimer(),
                        list_AGVs[agv].ID,
                        tasks_plan_time
                    )

                    # Otherwise, this AGV is to be replanned. Delete its parking path
                else
                    AGVs_plans[agv].path_to_park = TPath_rcdt()
                    AGVs_plans[agv].time_at_parking = tasks_plan_time
                end
            end
        end


        # Create an accumulator of all the existing plans to create planning blockages
        list_allocated_paths = TPath_rcdt[]
        for agv ∈ AGVs_to_skip
            append!(list_allocated_paths, enumerate_paths(AGVs_plans[agv], 1))
        end

        # What is the very best parking for each AGV?
        @info "\n\n\n" * stimer() * " --- Calculating list_completion_times for PARKINGS"
        list_parking_times = list_completion_times(AGVs_plans, ctx.special_locations["parking"], calctx)


        # Iterating through the planning order
        AGVs_to_replan = [p for p ∈ planning_order if p ∉ AGVs_to_skip]
        # [CHECK] should we keep the best for the end?


        @info @sprintf(
            "\n\n%s --- Starting replanning for AGVs. Original order: %s, skipping %s for final replanning %s",
            stimer(),
            string(planning_order),
            string(AGVs_to_skip),
            string(AGVs_to_replan)
        )

        for AGV_to_plan ∈ AGVs_to_replan
            # What is the actual AGV begin considered? Skip if necessary
            @info @sprintf(
                "\n%s\n%s     Planning AGV: %3d having %d steps",
                "---------------------------------------------------------------------------------------",
                stimer(),
                AGV_to_plan,
                length(AGVs_plans[AGV_to_plan].steps)
            )


            AGV_to_plan == best_AGV && @info @sprintf("%s     --- THIS IS THE BEST AGV ---", stimer())
            @info @sprintf("List of blocking paths: %s", string(list_allocated_paths))


            # Replan all the AGV's tasks starting from anything possibly affected after the beginning of
            # the replanning window
            @info @sprintf(
                "\n%s     Steps length before replanning: %d",
                stimer(),
                length(AGVs_plans[AGV_to_plan].steps)
            )
            @info @sprintf("%s     Steps before replanning: %s\n", stimer(), string(AGVs_plans[AGV_to_plan].steps))

            AGVs_plans[AGV_to_plan].steps =
                replan_agv_from_time(AGV_to_plan, 1, AGVs_plans, list_allocated_paths, calctx)

            @info @sprintf("\n%s     Replanned steps length: %d", stimer(), length(AGVs_plans[AGV_to_plan].steps))
            @info @sprintf("%s     Replanned steps: %s\n", stimer(), string(AGVs_plans[AGV_to_plan].steps))


            #######################################################################
            #
            # Allocate parking locations to guarantee allocation completion
            #
            @info @sprintf(
                "%s --- Searching closest parking to AGV: %3d \n%s",
                stimer(),
                AGV_to_plan,
                "---------------------------------------------------------------------------"
            )

            best_parking = argmin(list_parking_times[:, AGV_to_plan])
            best_time = minimum(list_parking_times[:, AGV_to_plan])

            @info @sprintf(
                "\n\n%s Choosing parking: %3d for AGV: %3d with optimal travel cost: %6d",
                stimer(),
                best_parking,
                AGV_to_plan,
                best_time
            )
            @debug @sprintf(
                "%s         AGV: %3d, n steps: %3d",
                stimer(),
                AGV_to_plan,
                length(AGVs_plans[AGV_to_plan].steps)
            )
            @debug @sprintf(
                "%s         AGV: %3d, n paths: %3d, ",
                stimer(),
                AGV_to_plan,
                length(AGVs_plans[AGV_to_plan].steps[end].path)
            )

            src_rcd = as_rcd(AGVs_plans[AGV_to_plan].steps[end].path[end])
            dst_rcd = as_rcd(ctx.special_locations["parking"][best_parking])

            @info @sprintf("%s         From %s to %s", stimer(), string(src_rcd), string(dst_rcd))

            start_time = AGVs_plans[AGV_to_plan].steps[end].path[end][4]
            path_c, path_t = plan_task(src_rcd, dst_rcd, start_time, list_allocated_paths, calctx)


            # If a plan is found, add it to the list of allocation plans (w/ parkings)
            if length(path_c) > 0
                AGVs_plans[AGV_to_plan].parking = ctx.special_locations["parking"][best_parking]
                AGVs_plans[AGV_to_plan].path_to_park = path_c
                AGVs_plans[AGV_to_plan].time_at_parking = path_t

                @info @sprintf(
                    "%s     Successful allocation of AGV %3d to rest at parking %s",
                    stimer(),
                    AGV_to_plan,
                    ctx.special_locations["parking"][best_parking].ID
                )
            else
                @error @sprintf(
                    "%s     ERROR - AGV %3d NO PATH TO PARKING %s",
                    stimer(),
                    AGV_to_plan,
                    ctx.special_locations["parking"][best_parking].ID
                )
            end

            # Get rid of that pair by making them impossible to be chosen
            list_parking_times[:, AGV_to_plan] .= COST_IMPOSSIBLE
            list_parking_times[best_parking, :] .= COST_IMPOSSIBLE

            # Update the existing blockage plans
            # append!(blocking_paths, list_complete_path(AGVs_plans[AGV_to_plan], replanning_window_beg))
            append!(list_allocated_paths, enumerate_paths(AGVs_plans[AGV_to_plan], 1))

            @info @sprintf(
                "%s ----FINISHED AGV: %3d \n %s",
                stimer(),
                AGV_to_plan,
                "------------------------------------------------------------------------"
            )

        end

        if isempty(use_fixed_tasks)
            push!(unallocated_tasks, generate_order!(order_number, ctx))
            order_number += 1
        end

        remaining_orders_no -= 1
    end

    # Restore the floor's matrix to its original state
    # ctxt.G3DT.weights.nzval[:] .= calctx.copy_nzval[:]

    tock()
    return AGVs_plans
end
