"""
$(TYPEDSIGNATURES)

"""
function fill_with_path(
    src::Trc,
    src_dir::TDirection,
    dst::Trc,
    dst_dir::TDirection,
    calctx::TCalculationContext,
)

    # Identify a path
    path2D_cs, path2D_vs, path2D_ws = path_a_b_2D(src, src_dir, dst, dst_dir, calctx)

    println(path2D_cs, " ", path2D_vs, " ", path2D_ws)

    filled_plan = zeros(Int64, calctx.ctx.nRow, calctx.ctx.nCol)

    if !isempty(path2D_vs)

        time_count = 1
        r1, c1, _, t1 = unpack(path2D_cs[1])
        filled_plan[r1, c1] = time_count

        total_time = Int64.(cumsum(Float64.(path2D_ws)) ./ STEP_TO_COST_MULTIPLIER)

        for (rcdt1, rcdt2, t1, t2) ∈ zip(
            path2D_cs[1:end-1],
            path2D_cs[2:end],
            total_time[1:end-1],
            total_time[2:end],
        )
            r1, c1, _, _ = unpack(rcdt1)
            r2, c2, _, _ = unpack(rcdt2)
            @assert abs(r2 - r1) + abs(c2 - c1) ≤ 1 "Malformed path: difference between coordinates exceeds 1."

            if r1 == r2 && c1 == c2
                time_count += t2 - t1
                filled_plan[r1, c1] = time_count
            else
                for t ∈ t1+1:t2
                    fraction = Int64(ceil((t - t1) / (t2 - t1)))
                    time_count += 1
                    r = r1 + Int64(ceil((r2 - r1) * (t - t1) / (t2 - t1)))
                    c = c1 + Int64(ceil((c2 - c1) * (t - t1) / (t2 - t1)))
                    filled_plan[r, c] = time_count
                end
            end
        end
    end

    return filled_plan
end


"""
    $(TYPEDSIGNATURES)
"""
function allocation_fill2D(
    list_AGVs::Vector{TAGV},
    n_tasks::Int64,
    ctxt::TContext;
    use_fixed_tasks = TTask[],
    queue_size = 10,
)

    tick()

    ######################################################################
    #
    # PREAMBLE
    #
    ######################################################################

    # Preallocate memory for A* calculations
    calctxt = TCalculationContext(ctxt)

    # At the start, no tasks is allocated. We use the optional list provided or populate.
    unallocated_tasks = TTask[]
    order_number = 1
    if isempty(use_fixed_tasks)
        for _ ∈ 1:queue_size
            push!(unallocated_tasks, generate_order!(order_number, ctxt))
            order_number += 1
        end
    else
        unallocated_tasks = deepcopy(use_fixed_tasks)
    end


    # At the very beginning, every AGV starts from where it is.
    @debug stimer() * " --- Initialising data structures"
    nAGVs = length(list_AGVs)
    AGVs_plans::Vector{TPlan} = initialise_plans(list_AGVs)
    initialise_parkings!(list_AGVs, AGVs_plans, calctxt, ctxt)

    # Allocate each task one by one
    task_planning_counter = 0
    remaining_orders_no = n_tasks
    while !isempty(unallocated_tasks) && remaining_orders_no > 0
        task_planning_counter += 1

        # nTasks = length(unallocated_tasks)

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
        optimal_task_times = [task_optimal_perf(t, calctxt, ctxt) for t ∈ unallocated_tasks]

        @info stimer() * " --- Calculating list_completion_times: AGVs -> TASKS"
        cross_completion_times = list_completion_times(
            AGVs_plans,
            unallocated_tasks,
            optimal_task_times,
            calctxt,
            ctxt,
        )

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
            TPlanStep(
                unallocated_tasks[best_task],
                TPath_rcdt(),
                replanning_window_beg + 1,
            ),
        )

        # [TODO We allocate and remove even if a plan has not been determined yet (which might not happen...)]
        @info @sprintf(
            "%s Removing task %s from unallocated list\n",
            stimer(),
            unallocated_tasks[best_task].ID
        )
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
                    isempty(AGVs_plans[agv].path_to_park) ? tasks_plan_time :
                    AGVs_plans[agv].time_at_parking

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
        blocking_paths = TPath_rcdt[]
        for agv ∈ AGVs_to_skip
            # append!(blocking_paths, list_complete_path(AGVs_plans[agv], replanning_window_beg))
            append!(blocking_paths, list_complete_path(AGVs_plans[agv], 1))
        end

        # What is the very best parking for each AGV?
        @info "\n\n\n" * stimer() * " --- Calculating list_completion_times for PARKINGS"
        list_parking_times = list_completion_times(
            AGVs_plans,
            ctxt.special_locations["parking"],
            calctxt,
            ctxt,
        )

        # Iterating through the planning order
        AGVs_to_replan = [p for p ∈ planning_order if p ∉ AGVs_to_skip]
        # [CHECK: check that at the beginning of the transit planning, if an AGV is loaded, skip it?
        # or, if unloaded, use it? Is it useful at all since planning is not in execution and we partially
        # rewind]
        #
        # [CHECK: should we keep the best for the end?]
        # AGVs_to_replan = [p for p ∈ planning_order if p ∉ AGVs_to_skip && p ≠ best_AGV] !!! If using
        # this line, need to push at the backend.
        # push!(AGVs_to_replan, best_AGV)

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

            AGV_to_plan == best_AGV &&
                @info @sprintf("%s     --- THIS IS THE BEST AGV ---", stimer())
            @info @sprintf("List of blocking paths: %s", string(blocking_paths))

            # Replan all the AGV's tasks starting from anything possibly affected after the beginning of
            # the replanning window
            @info @sprintf(
                "\n%s     Steps length before replanning: %d",
                stimer(),
                length(AGVs_plans[AGV_to_plan].steps)
            )
            @info @sprintf(
                "%s     Steps before replanning: %s\n",
                stimer(),
                string(AGVs_plans[AGV_to_plan].steps)
            )

            # AGVs_plans[AGV_to_plan].steps = replan_agv_from_time(AGV_to_plan, replanning_window_beg,
            #                                     AGVs_plans, blocking_paths, calctxt, ctxt)
            AGVs_plans[AGV_to_plan].steps = replan_agv_from_time(
                AGV_to_plan,
                1,
                AGVs_plans,
                blocking_paths,
                calctxt,
                ctxt,
            )

            @info @sprintf(
                "\n%s     Replanned steps length: %d",
                stimer(),
                length(AGVs_plans[AGV_to_plan].steps)
            )
            @info @sprintf(
                "%s     Replanned steps: %s\n",
                stimer(),
                string(AGVs_plans[AGV_to_plan].steps)
            )

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
            dst_rcd = as_rcd(ctxt.special_locations["parking"][best_parking])
            @info @sprintf(
                "%s         From %s to %s",
                stimer(),
                string(src_rcd),
                string(dst_rcd)
            )

            start_time = AGVs_plans[AGV_to_plan].steps[end].path[end][4]
            path_c, path_t =
                plan_task(src_rcd, dst_rcd, start_time, 0, blocking_paths, calctxt, ctxt)

            # If a plan is found, add it to the list of allocation plans (w/ parkings)
            if length(path_c) > 0
                AGVs_plans[AGV_to_plan].parking =
                    ctxt.special_locations["parking"][best_parking]
                AGVs_plans[AGV_to_plan].path_to_park = path_c
                AGVs_plans[AGV_to_plan].time_at_parking = path_t

                @info @sprintf(
                    "%s     Successful allocation of AGV %3d to rest at parking %s",
                    stimer(),
                    AGV_to_plan,
                    ctxt.special_locations["parking"][best_parking].ID
                )
            else
                @error @sprintf(
                    "%s     ERROR - AGV %3d NO PATH TO PARKING %s",
                    stimer(),
                    AGV_to_plan,
                    ctxt.special_locations["parking"][best_parking].ID
                )
            end

            # Get rid of that pair by making them impossible to be chosen
            list_parking_times[:, AGV_to_plan] .= COST_IMPOSSIBLE
            list_parking_times[best_parking, :] .= COST_IMPOSSIBLE

            # Update the existing blockage plans
            # append!(blocking_paths, list_complete_path(AGVs_plans[AGV_to_plan], replanning_window_beg))
            append!(blocking_paths, list_complete_path(AGVs_plans[AGV_to_plan], 1))

            @info """
                  $(stimer()) ----FINISHED AGV: $(AGV_to_plan)
                  ------------------------------------------------------------------------
                  """
        end

        if isempty(use_fixed_tasks)
            push!(unallocated_tasks, generate_order!(order_number, ctxt))
            order_number += 1
        end

        remaining_orders_no -= 1
    end

    # Restore the floor's matrix to its original state
    ctxt.G3DT.weights.nzval[:] .= calctxt.copy_nzval[:]

    tock()
    return AGVs_plans
end
