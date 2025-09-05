"""
$(TYPEDSIGNATURES)

"""
function is_step_change(rcdt1::Trcdt, rcdt2::Trcdt)
    r1, c1, d1, t1 = unpack(rcdt1)
    r2, c2, d2, t2 = unpack(rcdt2)

    no_move = r1 == r2 && c1 == c2 && d1 == d2 && t2 > t1
    updown = abs(r2 - r1) == 1 && c1 == c2 && t2 - t1 == STEPS_FWD
    leftright = r1 == r2 && abs(c2 - c1) == 1 && t2 - t1 == STEPS_FWD
    singleturn =
        r1 == r2 &&
        c1 == c2 &&
        (abs(d2 - d1) == 1 || abs(d2 - d1) == 3) &&
        t2 - t1 == STEPS_TRN
    uturn = r1 == r2 && c1 == c2 && abs(d2 - d1) == 2 && t2 - t1 == 2 * STEPS_TRN

    return 1 == count([no_move, updown, leftright, singleturn, uturn])
end


"""
$(TYPEDSIGNATURES)

"""
function list_nonsingle_step_changes(plan::TPlan)
    full_path = []
    for s ∈ plan.steps
        append!(full_path, s.path)
    end
    append!(full_path, plan.path_to_park)
    n_rcdt = length(full_path)

    errors = []
    for i ∈ 1:n_rcdt-1
        rcdt1 = as_rcdt(full_path[i])
        rcdt2 = as_rcdt(full_path[i+1])
        if !is_step_change(rcdt1, rcdt2)
            push!(errors, (i, full_path[i], full_path[i+1]))
        end
    end
    return errors
end


"""
$(TYPEDSIGNATURES)

"""
function check_path(path::TPath_rcdt, context::TContext)
    for i ∈ 1:length(path)-1
        if as_rcd(path[i+1]) ∉
           [as_rcd(m.dest) for m ∈ generate_moves(as_rcd(path[i]), context)]
            println("Not good at ", i)
            return false
        end
    end
    return true
end


"""
$(TYPEDSIGNATURES)

"""
check_paths(paths::Vector{CartesianIndex{4}}, context::TContext) =
    all([check_path(p, context) for p ∈ paths])
check_paths(paths::Vector{TPath_rcdt}, context::TContext) =
    all([check_path(p, context) for p ∈ paths])
check_paths(planning::Vector{TPlan}, context::TContext) =
    all([check_paths(plan.steps, context) for plan ∈ planning])
check_paths(steps::Vector{TPlanStep}, context::TContext) =
    all([check_paths(s.path, context) for s ∈ steps])
check_paths(plan::TPlan, context::TContext) = check_paths(plan.steps, context)
check_paths(step::TPlanStep, context::TContext) =
    all([check_path(s.path, context) for s ∈ step])


"""
$(TYPEDSIGNATURES)

"""
function planstep_timing(planstep::TPlanStep)
    task = planstep.task
    t_src = as_rc(task.start.loc)

    path_as_locations = [as_rc(rcdt) for rcdt ∈ planstep.path]

    starting_time = planstep.path[1][4]

    start_load = findfirst(isequal(t_src), path_as_locations)
    loading_time =
        isnothing(start_load) ? planstep.path[end][4] : planstep.path[start_load][4]

    finish_time = planstep.path[end][4]

    return finish_time - starting_time, loading_time - starting_time
end


"""
$(TYPEDSIGNATURES)

"""
function describe_plan(plan::TPlan)
    nsteps = length(plan.steps)
    println("Number of steps: ", nsteps)

    total_plan = 0
    total_loaded = 0
    total_unloaded = 0

    longest_loaded = 0
    longest_unloaded = 0

    for i ∈ 1:nsteps
        t, tu = planstep_timing(plan.steps[i])
        @printf("    Step %d: %d unloaded - %d loaded.\n", i, tu, t - tu)

        longest_loaded = max(longest_loaded, t - tu)
        longest_unloaded = max(longest_unloaded, tu)

        total_plan += t
        total_loaded += t - tu
        total_unloaded += tu
    end

    @printf(
        "\nTotal: %d total = %d unloaded (%3.2f%%) + %d loaded (%3.2f%%)\n",
        total_plan,
        total_unloaded,
        Float64(100 * total_unloaded / total_plan),
        total_loaded,
        Float64(100 * total_loaded / total_plan)
    )

    @printf("Longest depth. Loaded: %d, Unloaded: %d\n", longest_loaded, longest_unloaded)
end
