"""
$(TYPEDSIGNATURES)

"""
function empty_render(ctx::TContext; flip = false)

    # Graphic size
    nRow = ctx.nRow
    nCol = ctx.nCol
    if flip
        nCol, nRow = nRow, nCol
    end

    # Empty floor plan with margin of 4 char
    empty_map = Array{Char,2}(undef, (nRow + 8, nCol + 8))
    empty_map[:, :] .= ' '


    # Create top 4 lines with column number
    for c ∈ 1:nCol
        if mod(c, 100) == 0
            empty_map[1, c+4] = Char('0' + c ÷ 100)
            empty_map[nRow+6, c+4] = Char('0' + c ÷ 100)
        else
            empty_map[1, c+4] = '_'
            empty_map[nRow+6, c+4] = '_'
        end

        if mod(c, 10) ∈ [0, 5]
            empty_map[2, c+4] = Char('0' + rem(c, 100) ÷ 10)
            empty_map[nRow+7, c+4] = Char('0' + rem(c, 100) ÷ 10)
        else
            empty_map[2, c+4] = '_'
            empty_map[nRow+7, c+4] = '_'
        end

        empty_map[3, c+4] = Char('0' + rem(c, 10))
        empty_map[nRow+8, c+4] = Char('0' + rem(c, 10))
    end

    # Create leftmost 4 columns with row number
    for r ∈ 1:nRow
        if mod(r, 100) == 0
            empty_map[r+4, 1] = Char('0' + r ÷ 100)
            empty_map[r+4, nCol+6] = Char('0' + r ÷ 100)
        else
            empty_map[r+4, 1] = '_'
            empty_map[r+4, nCol+6] = '_'
        end

        if mod(r, 10) ∈ [0, 5]
            empty_map[r+4, 2] = Char('0' + rem(r, 100) ÷ 10)
            empty_map[r+4, nCol+7] = Char('0' + rem(r, 100) ÷ 10)
        else
            empty_map[r+4, 2] = '_'
            empty_map[r+4, nCol+7] = '_'
        end

        empty_map[r+4, 3] = Char('0' + rem(r, 10))
        empty_map[r+4, nCol+8] = Char('0' + rem(r, 10))
    end


    for i ∈ 1:nRow, j ∈ 1:nCol
        if flip
            loc = Int64(ctx.plan[j, i])
        else
            loc = Int64(ctx.plan[i, j])
        end
        empty_map[i+4, j+4] = LOC_RENDERING_SYMBOLS[loc+1]
    end

    return empty_map
end


"""
$(TYPEDSIGNATURES)

"""
function add_path_to_render!(path_rcdt::TPath_rcdt, render, ctx::TContext; flip = false)

    # Graphic size
    nRow = ctx.nRow
    nCol = ctx.nCol
    if flip
        nRow, nCol = nCol, nRow
    end

    # Layer the path
    add_path_to_render!(as_rcd.(path_rcdt), render, ctx; flip = flip)

    # Iterate through to print a digit marker every 100's
    _, _, _, t0 = unpack(path_rcdt[1])

    for i ∈ 2:length(path_rcdt)
        _, _, _, t1 = unpack(path_rcdt[i-1])
        r, c, _, t2 = unpack(path_rcdt[i])
        if flip
            c, r = r, c
        end

        # If changed 100's in a segment, print a marker (but will break above 1,000)
        if (t1 ÷ 100) < (t2 ÷ 100)
            render[r+4, c+4] = Char('0' + ((t2 - t0) ÷ 100))
        end
    end

    return nothing
end


"""
$(TYPEDSIGNATURES)

Print floor map
"""
function add_path_to_render!(path_rcd::TPath_rcd, render, ctx::TContext; flip = false)

    for e ∈ path_rcd
        # @show v2c(e, true, context)
        r, c, d = unpack(e)
        if flip
            c, r, d = r, c, turn270(d)
            render[r+4, c+4] = ['↓', '→', '↑', '←'][d]
        else
            render[r+4, c+4] = ['↑', '→', '↓', '←'][d]
        end
    end
    return nothing
end


"""
$(TYPEDSIGNATURES)

"""
function print_render(io::IO, path_render)
    nRow, nCol = size(path_render)
    for row = 1:nRow
        for col = 1:nCol
            print(io, path_render[row, col])
        end
        print(io, '\n')
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

"""
print_render(path_render) = print_render(stdout, path_render)


"""
$(TYPEDSIGNATURES)

Print floor map
"""
function path_c_2_graphic(io::IO, path::TPath_rcd, ctx::TContext; flip = false)
    # Graphic size
    nRow = ctx.nRow
    nCol = ctx.nCol

    if flip
        nRow, nCol = nCol, nRow
    end

    path_render = empty_render(ctx; flip)

    isempty(path) || add_path_to_render!(path, path_render, ctx; flip)

    for row = 1:nRow+8
        for col = 1:nCol+8
            print(io, path_render[row, col])
        end
        println()
    end

    return nothing
end


"""
$(TYPEDSIGNATURES)

"""
path_c_2_graphic(path::TPath_rcd, ctx::TContext; flip = false) =
    path_c_2_graphic(stdout, path, ctx; flip)
path_c_2_graphic(path::TPath_rcdt, ctx::TContext; flip = false) =
    path_c_2_graphic(stdout, as_rcd.(path), ctx; flip)


"""
$(TYPEDSIGNATURES)

"""
function render_plan_at_time(
    io::IO,
    planning::Vector{TPlan},
    time::Int64,
    ctx::TContext;
    flip = false,
)
    # Header
    println(io, "")
    println(io, "Rendering plan at time: ", time)
    println(io, "")
    println(io, "--- LIST OF AGVs ---")
    println(io, "")

    # Graphic size
    nRow = ctx.nRow
    nCol = ctx.nCol
    if flip
        nRow, nCol = nCol, nRow
    end

    nAGVs = length(planning)

    # Empty render
    path_render = empty_render(ctx; flip = flip)
    list_statuses = []
    list_current_task = []

    # Loop through AGV
    for a ∈ 1:nAGVs
        found = false
        for s ∈ planning[a].steps
            r1, c1, d1, t1 = 0, 0, 0, 0
            r2, c2, d2, t2 = 0, 0, 0, 0
            task = nothing

            for p ∈ 1:length(s.path)-1

                if s.path[p+1][4] < time
                    continue
                else
                    found = true
                    r1, c1, d1, t1 = unpack(s.path[p])
                    r2, c2, d2, t2 = unpack(s.path[p+1])
                    task = s.task
                    break
                end
            end

            if found
                # Print the direction at the front and the AGV no at the back
                if flip == true
                    r1, c1, d1 = c1, r1, turn270(d1)
                    r2, c2, d2 = c2, r2, turn270(d2)
                    path_render[r1+4-1, c1+4+1] = ['↓', '→', '↑', '←'][d1]
                else
                    path_render[r1+4-1, c1+4+1] = ['↑', '→', '↓', '←'][d1]
                end
                path_render[r1+4, c1+4] = Char('0' + a)

                @printf(
                    io,
                    "AGV %2d: (rendering direction) rcdt from: (%3d, %3d, %3d, %3d) ",
                    a,
                    r1,
                    c1,
                    d1,
                    t1
                )
                @printf(io, "     rcdt   to: (%3d, %3d, %3d, %3d) ", r2, c2, d2, t2)
                @printf(io, "     to perform task (actual plan direction): %s\n", task)
                break
            end
        end
        # If idx is first time over, we want the segment starting one before that
    end

    # Print the render
    print_render(io, path_render)

    println(io, "")
    println(io, "--- END OF PLAN ---")
    println(io, "")
    return nothing
end


"""
$(TYPEDSIGNATURES)

"""
render_plan_at_time(plan::Vector{TPlan}, time::Int64, ctx::TContext; flip = false) =
    render_plan_at_time(stdout, plan, time, ctx; flip)


"""
$(TYPEDSIGNATURES)

"""
function describe_plan(plan::TPlan)
    n_steps = length(plan.steps)
    println("Number of steps: ", n_steps)

    for s ∈ 1:n_steps
        first_step = plan.steps[s].path[1]
        last_step = plan.steps[s].path[end]
        final_time = plan.steps[s].time_completed
        path_length = length(plan.steps[s].path)
        @printf(
            "  Step %d. From: %s to %s (final time %d) - No. Trcdts = %d \n",
            s,
            string(first_step),
            string(last_step),
            final_time,
            path_length
        )
    end

    @printf(
        "  Parking %s. From %s to %s (final time %d) - No. Trcdts = %d \n",
        plan.parking.ID,
        string(plan.path_to_park[1]),
        string(plan.path_to_park[end]),
        plan.time_at_parking,
        length(plan.path_to_park)
    )
end


"""
$(TYPEDSIGNATURES)

"""
function describe_planning(planning::Vector{TPlan})
    nAGVs = length(planning)
    println("Number of AGVs: ", nAGVs)

    for p ∈ planning
        describe_plan(p)
        println()
    end
end
