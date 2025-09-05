"""
$(TYPEDSIGNATURES)

Calculate optimal 2D plan from start location to target location
"""
function task_optimal_perf(task::TTask, calctx::AbstractCalculationContext)::Int64

    # Calculate optimal 2D plan from start location to target location
    src = task.start
    println(typeof(src))
    dst = task.target
    path_rcdt, _, _ = path_a_b_2D(src, dst, calctx)

    # [TODO: would that break if src == dst?]
    if path_rcdt == []
        return STEPS_IMPOSSIBLE
    else
        # If src != dst then a task, otherwise parking [TODO change to something using
        # something more abstracted]
        # If there is a path, calculate loading and offloading times.
        if is_identical_locations(src, dst)
            lift1 = 0
            lift2 = 0
        else
            lift1 = paletting_time(src)
            lift2 = paletting_time(dst)
        end

        return lift1 + path_rcdt[end][4] + lift2
    end
end


"""
$(TYPEDSIGNATURES)

`list_completion_times = []` returns the list of times: time(AGV ``\\alpha_i``, unallocated task ``\\tau_j``) which
contains all the current cross timepairs between  an AGV (starting from the end of its latest allocated task of that
AGV) and a task.

`list_completion_times` may return `[]`.

For each Task ``\\tau_i`` in `UnAllocatedTasks != []` (if `UnAllocatedTasks[]` is not
empty), and for each ``AGV_j``:

    - Take the time of where the AGV is: get the final position of ``AGV_i``. The position is its starting position for
      the first iteration (if no task has yet been allocated), or the position of its final release location given
      its list of tasks.

    - Take the time to complete the new task in 2D assuming no other AGV is around. That is: it is the time for the AGV
      to reach the start TPalletteLocation, load the palette, reach the target TLocation and offload.

    - Calculate the total final time for that pair. It is the latest time in the allocation of that AGV + time to
      start of task + load palette + time to target of the task +

    - Push the result (with all relevant information) into ``ListTimePairings``

Note that the `i` row index is for tasks and `j` column index is for AGVs.
"""
function list_completion_times(
    AGVs_plans::Vector{TPlan},
    list_destinations::Vector{TLocation},
    optimal_task_times::Vector{Int64},
    calctx::AbstractCalculationContext,
)::Array{Int64,2}

    nAGVs = length(list_AGVs)
    nDestinations = length(list_destinations)

    # Result matrix
    M = zeros(Int64, (nDestinations, nAGVs))

    # @info stimer() * "        --- list_completion_times: TLocation / AGVs"

    for dest_i ∈ 1:nDestinations, AGV_j ∈ 1:nAGVs
        current_dest = list_destinations[dest_i]
        path_rcdt, _, _ =
            path_a_b_2D(AGVs_plans[AGV_j].plan[end].task, current_dest, calctx)

        @debug "$(stimer())          --- list_completion_times: task = $(task_i) AGV: $(AGV_j) path length: $(length(path_rcdt)) cost: $(path_rcdt[end][4])"

        # What is the current latest time in the tasks allocated to the AGV?
        current_AGV_time = AGVs_plans[AGV_j].steps[end].time_completed

        M[dest_i, AGV_j] =
            isempty(path_rcdt) ? STEPS_IMPOSSIBLE :
            Int64(current_AGV_time + path_rcdt[end][4] + optimal_task_times[dest_i])
    end
    return M
end


"""
$(TYPEDSIGNATURES)

"""
function list_completion_times(
    AGVs_plans::Vector{TPlan},
    list_tasks::TTaskList,
    optimal_task_times::Vector{Int64},
    calctx::AbstractCalculationContext,
)::Array{Int64,2}

    nAGVs = length(AGVs_plans)
    nTasks = length(list_tasks)

    # Result matrix
    M = zeros(Int64, (nTasks, nAGVs))

    # Note: rows = task / columns = AGV
    for AGV_j ∈ 1:nAGVs, task_i ∈ 1:nTasks
        current_task = list_tasks[task_i]
        @debug "\n$(stimer())        --- Completion time: AGV: $(AGV_j) executes task no. = $(task_i)      task description: $(current_task)"

        # An AGV should at least have an allocated task being be located in its start position
        # Calculate the tome from the AGV to the start TLocation
        path_rcdt, _, _ =
            path_a_b_2D(AGVs_plans[AGV_j].steps[end].task, current_task.start, calctx)

        # What is the current latest time in the tasks allocated to the AGV?
        current_AGV_time = AGVs_plans[AGV_j].steps[end].time_completed

        if !isempty(path_rcdt)
            @debug "$(stimer())                             AGV: $(AGV_j) (latest time: $(current_AGV_time)) executes task = $(task_i) " *
                   "(optimal time: $(optimal_task_times[task_i])) with path length: length(path_c) cost: $(path_rcdt[end][4])"

            M[task_i, AGV_j] =
                isempty(path_rcdt) ? STEPS_IMPOSSIBLE :
                Int64(current_AGV_time + path_rcdt[end][4] + optimal_task_times[task_i])
        else
            @debug "$(stimer())                             AGV: $(AGV_j) (latest time: $(current_AGV_time)) executes task = $(task_i) " *
                   "(optimal time: $(optimal_task_times[task_i]))  -> HAS NO SOLUTION "
        end
    end

    @debug "$(stimer())        --- list_completion_times: M:\n$(string(M))\n\n"
    return M
end


"""
$(TYPEDSIGNATURES)

Similar calculation to move an AGV to a parking location. Therefore without any loading / offloading and intra-task trasit.
"""
function list_completion_times(
    AGVs_plans::Vector{TPlan},
    list_parkings::Vector{TLocation},
    calctx::AbstractCalculationContext,
)::Array{Int64,2}

    destinations = [TTask(parking) for parking ∈ list_parkings]

    # TODO: Add @assert that all results cannot be all STEP_IMPOSSIBLE
    M = list_completion_times(
        AGVs_plans,
        destinations,
        zeros(Int64, length(destinations)),
        calctx,
    )
    return M
end
