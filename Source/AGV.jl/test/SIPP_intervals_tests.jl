module_dir = "/home/emmanuel/Documents/Work/Alba/AGV/_gits/AGV.jl/"
module_img_dir = module_dir * "img/"
module_src_dir = module_dir * "src/"
cd(module_dir)

import Pkg;
Pkg.activate(".");

using LightGraphs, SimpleWeightedGraphs, Test
using AGV


@testset "Convex Downward Parabola" begin
    # Φ(h, g, ϵ) = (g + (2 * ϵ - 1 ) * h + sqrt((g - h)^2 + 4 * ϵ  * g * h)) / (2 * ϵ)
    @test Φ(0, 0, 1) == 0.0
    @test Φ(0, 1, 1) == 1.0
    @test Φ(1, 0, 1) == 1.0
end


# Heuristic function
@testset "heuristic" begin
    @test state_heuristic(as_rcd(1, 1, Up), as_rcd(2, 1, Up)) ∈ [1.0, STEPS_FWD]
    @test state_heuristic(as_rcd(1, 1, Up), as_rcd(1, 2, Up)) ∈ [1.0, STEPS_FWD]

    @test state_heuristic(as_rcd(1, 2, Up), as_rcd(1, 1, Up)) ∈ [1.0, STEPS_FWD]
    @test state_heuristic(as_rcd(1, 1, Up), as_rcd(2, 1, Up)) ∈ [1.0, STEPS_FWD]

    # 2 possible results depending on the type of distance used
    @test state_heuristic(as_rcd(1, 1, Up), as_rcd(1, 1, Right)) ∈ [0.0, STEPS_TRN]
    @test state_heuristic(as_rcd(1, 1, Down), as_rcd(1, 1, Right)) ∈ [0.0, STEPS_TRN]
    @test state_heuristic(as_rcd(1, 1, Up), as_rcd(1, 1, Left)) ∈ [0.0, STEPS_TRN]
    @test state_heuristic(as_rcd(1, 1, Down), as_rcd(1, 1, Left)) ∈ [0.0, STEPS_TRN]
    @test state_heuristic(as_rcd(1, 1, Up), as_rcd(1, 1, Down)) ∈ [0.0, 2 * STEPS_TRN]
end


@testset "Segment push pop" begin
    list_intervals = [(2, 2), (1, 1), (5, 7), (10, 15), (9, 11), (6, 10)]

    intervals = SIPPBusyIntervals(10)
    @test size(intervals) == 10

    for segment ∈ list_intervals
        push!(intervals, segment)
    end
    @test size(intervals) == 10
    @test length(intervals) == length(list_intervals)

    for _ ∈ list_intervals
        pop!(intervals)
    end
    @test size(intervals) == 10
    @test length(intervals) == 0
    @test isempty(intervals)

    for segment ∈ list_intervals
        push!(intervals, segment)
        @test pop!(intervals) == segment
    end

    s = SIPPBusyIntervals(10)
    push!(s, (1, 5))
    push!(s, (1, 4))
    @test s.ordering[1] == 2 && s.ordering[2] == 1
    s = SIPPBusyIntervals(10)
    push!(s, (1, 5))
    push!(s, (1, 6))
    @test s.ordering[1] == 1 && s.ordering[2] == 2
    s = SIPPBusyIntervals(10)
    push!(s, (3, 5))
    push!(s, (3, 5))
    @test (s.ordering[1] == 2 && s.ordering[2] == 1) ||
          (s.ordering[1] == 1 && s.ordering[2] == 2)
    s = SIPPBusyIntervals(10)
    push!(s, (3, 5))
    push!(s, (1, 2))
    @test s.ordering[1] == 2 && s.ordering[2] == 1
    s = SIPPBusyIntervals(10)
    push!(s, (3, 5))
    push!(s, (1, 4))
    @test s.ordering[1] == 2 && s.ordering[2] == 1
    s = SIPPBusyIntervals(10)
    push!(s, (3, 5))
    push!(s, (1, 6))
    @test s.ordering[1] == 2 && s.ordering[2] == 1
    s = SIPPBusyIntervals(10)
    push!(s, (3, 5))
    push!(s, (3, 4))
    @test s.ordering[1] == 2 && s.ordering[2] == 1
    s = SIPPBusyIntervals(10)
    push!(s, (3, 5))
    push!(s, (3, 8))
    @test s.ordering[1] == 1 && s.ordering[2] == 2
    s = SIPPBusyIntervals(10)
    push!(s, (3, 5))
    push!(s, (5, 8))
    @test s.ordering[1] == 1 && s.ordering[2] == 2
    s = SIPPBusyIntervals(10)
    push!(s, (3, 5))
    push!(s, (6, 8))
    @test s.ordering[1] == 1 && s.ordering[2] == 2
end


# Test random intervals and checks for properties
@testset "Segment stack random intervals" begin
    NTEST = 10_000
    results = []
    for n in Int64.(ceil.(rand(NTEST) .* 15))
        s = SIPPBusyIntervals(64)
        for _ = 1:n
            a = Int64(ceil(rand() * 100))
            b = Int64(ceil(rand() * 100))
            a, b = sort([a, b])
            push!(s, (a, b))
        end

        # Check that each ordering only appears once
        l = s.ordering
        mask_not_zero = (l .!= 0)
        l_not_zero = l[mask_not_zero]
        l_are_zero = length(l_not_zero) + 1
        @test allunique(l[mask_not_zero])
        @test all(l[l_are_zero:end] .== 0)

        # Check that the segments are in the right order
        do_print = false
        for i = 1:length(s)-1
            r = s.segments[i+1][1] >= s.segments[i][1]
            if !r
                do_print = true
                println(
                    "$(s.segments[i][1]) $(s.segments[i][2]) -- $(s.segments[i + 1][1]) $(s.segments[i + 1][2])",
                )
            end
            push!(results, r)
        end
        if do_print
            show(s.ordering[mask_not_zero])
            println()
            show(s.segments[mask_not_zero])
            println()
        end

        # Test list_safe_intervals
        lsi = list_safe_intervals(s, MAX_NUMBER_BUSY_INTERVALS, time_shift = 0)

        for i ∈ 1:length(lsi) - 1
            @test lsi[i][1] < lsi[i + 1][1]
            @test lsi[i][2] < lsi[i + 1][2]
            @test lsi[i][2] < lsi[i + 1][1]
        end

    end
    @test all(results)
end


# If any random set of intervals trigerred an error, add it here
@testset "Segment stack - troublesome random intervals" begin
    bad_tuples = [
        (1, 81),
        (7, 30),
        (9, 22),
        (11, 27),
        (9, 34),
        (21, 90),
        (25, 70),
        (45, 81),
        (53, 56),
        (74, 99),
    ]
    bad_order = [4, 1, 9, 8, 6, 2, 7, 3, 5, 10]
    ordered_bad_tuples = [bad_tuples[i] for i ∈ bad_order]

    s = SIPPBusyIntervals(length(bad_order) + 5)
    for t ∈ ordered_bad_tuples
        push!(s, t)
    end

    # Check that each ordering only appears once
    l = s.ordering
    mask_not_zero = (l .!= 0)
    l_not_zero = l[mask_not_zero]
    l_are_zero = length(l_not_zero) + 1
    @test allunique(l[mask_not_zero]) && all(l[l_are_zero:end] .== 0)

    # Check that the segments are in the right order
    do_print = false
    for i = 1:length(s)-1
        r = s.segments[i+1][1] >= s.segments[i][1]
        if !r
            do_print = true
            println(
                "$(s.segments[i][1]) $(s.segments[i][2]) -- $(s.segments[i + 1][1]) $(s.segments[i + 1][2])",
            )
        end
        @test r
    end
    if do_print
        show(s.ordering[mask_not_zero])
        println()
        show(s.segments[mask_not_zero])
        println()
    end
end



@testset "safe intervals from busy intervals - random tests" begin
    for _ ∈ 1:10_000

        # NO TIME SHIFT

        r0 = Int64(ceil(rand(Uniform(15, 2000))))

        # Bottom busy
        t = SIPPBusyIntervals(10)
        push!(t, (0, r0))
        l = list_safe_intervals(t, 1024; time_shift = 0)
        if r0 < 1022
            @test l[1] == (r0 + 1, 1024)
        else
            @test isempty(l)
        end


        # Top busy
        t = SIPPBusyIntervals(10)
        push!(t, (r0, 1000_000))
        l = list_safe_intervals(t, 1024; time_shift = 0)
        if isempty(l)
            println("Problem with top intv $(l)")
            break
        end
        @test l[1] == (0, r0 - 1)

        # Middle busy
        r1 = Int64(ceil(rand(Uniform(25, 500))))
        r2 = Int64(ceil(rand(Uniform(600, 1000))))

        t = SIPPBusyIntervals(10)
        push!(t, (r1, r2))
        l = list_safe_intervals(t, 1024; time_shift = 0)
        if length(l) < 2
            println("Problem with middle intv $(l)")
            break
        end
        @test l[1] == (0, r1 - 1)
        @test l[2] == (r2 + 1, 1024)

        # WITH TIME SHIFT

        time_shift = Int64(ceil(rand(Uniform(0, 500))))
        r0 = Int64(ceil(rand(Uniform(15, 1_000))))

        # Bottom busy
        t = SIPPBusyIntervals(10)
        push!(t, (1, r0))
        l = list_safe_intervals(t, 1024; time_shift = time_shift)

        if r0 > 1024 || time_shift > 1024
            @test isempty(l)
        else
            @test l[1] == (max(1 + r0, 1 + time_shift), 1_024)
        end

        # Top busy
        t = SIPPBusyIntervals(10)
        push!(t, (r0, 10_000))
        l = list_safe_intervals(t, 1024; time_shift = time_shift)

        if r0 > 1024 || time_shift > 1024
            @test isempty(l)
        elseif r0 <= time_shift
            @test isempty(l)
        else
            @test l[1] == (time_shift, r0 - 1)
        end
    end
end



@testset "Broken examples" begin
    path = [
        CartesianIndex(90, 40, 4, 2), CartesianIndex(90, 40, 4, 0), CartesianIndex(90, 39, 4, 0), CartesianIndex(90, 38, 4, 0),
        CartesianIndex(90, 38, 3, 12), CartesianIndex(91, 38, 3, 11), CartesianIndex(92, 38, 3, 10), CartesianIndex(92, 38, 2, 23),
        CartesianIndex(92, 39, 2, 23), CartesianIndex(92, 39, 2, 88), CartesianIndex(92, 39, 2, 0), CartesianIndex(92, 39, 4, 0),
        CartesianIndex(92, 38, 4, 0), CartesianIndex(92, 38, 1, 0), CartesianIndex(91, 38, 1, 0), CartesianIndex(90, 38, 1, 0),
        CartesianIndex(89, 38, 1, 0), CartesianIndex(88, 38, 1, 0), CartesianIndex(87, 38, 1, 0), CartesianIndex(86, 38, 1, 0),
        CartesianIndex(85, 38, 1, 0), CartesianIndex(84, 38, 1, 0), CartesianIndex(83, 38, 1, 0), CartesianIndex(82, 38, 1, 0),
        CartesianIndex(81, 38, 1, 0), CartesianIndex(80, 38, 1, 0), CartesianIndex(79, 38, 1, 0), CartesianIndex(78, 38, 1, 0),
        CartesianIndex(77, 38, 1, 0), CartesianIndex(76, 38, 1, 0), CartesianIndex(75, 38, 1, 0), CartesianIndex(74, 38, 1, 0),
        CartesianIndex(73, 38, 1, 0), CartesianIndex(72, 38, 1, 0), CartesianIndex(71, 38, 1, 0), CartesianIndex(70, 38, 1, 0),
        CartesianIndex(69, 38, 1, 0), CartesianIndex(68, 38, 1, 0), CartesianIndex(67, 38, 1, 0), CartesianIndex(66, 38, 1, 0),
        CartesianIndex(65, 38, 1, 0), CartesianIndex(64, 38, 1, 0), CartesianIndex(63, 38, 1, 0), CartesianIndex(62, 38, 1, 0),
        CartesianIndex(61, 38, 1, 0), CartesianIndex(60, 38, 1, 0), CartesianIndex(59, 38, 1, 0), CartesianIndex(58, 38, 1, 0),
        CartesianIndex(57, 38, 1, 0), CartesianIndex(56, 38, 1, 0), CartesianIndex(55, 38, 1, 0), CartesianIndex(54, 38, 1, 0),
        CartesianIndex(53, 38, 1, 0), CartesianIndex(52, 38, 1, 0), CartesianIndex(51, 38, 1, 0), CartesianIndex(50, 38, 1, 0),
        CartesianIndex(49, 38, 1, 0), CartesianIndex(48, 38, 1, 0), CartesianIndex(47, 38, 1, 0), CartesianIndex(46, 38, 1, 0),
        CartesianIndex(45, 38, 1, 0), CartesianIndex(44, 38, 1, 0), CartesianIndex(43, 38, 1, 0), CartesianIndex(42, 38, 1, 0),
        CartesianIndex(41, 38, 1, 0), CartesianIndex(40, 38, 1, 0), CartesianIndex(39, 38, 1, 0), CartesianIndex(38, 38, 1, 0),
        CartesianIndex(37, 38, 1, 0), CartesianIndex(36, 38, 1, 0), CartesianIndex(35, 38, 1, 0), CartesianIndex(34, 38, 1, 0),
        CartesianIndex(33, 38, 1, 0), CartesianIndex(32, 38, 1, 0), CartesianIndex(31, 38, 1, 0), CartesianIndex(30, 38, 1, 0),
        CartesianIndex(29, 38, 1, 0), CartesianIndex(28, 38, 1, 0), CartesianIndex(27, 38, 1, 0), CartesianIndex(26, 38, 1, 0),
        CartesianIndex(25, 38, 1, 0), CartesianIndex(24, 38, 1, 0), CartesianIndex(23, 38, 1, 0), CartesianIndex(22, 38, 1, 0),
        CartesianIndex(21, 38, 1, 0), CartesianIndex(20, 38, 1, 0), CartesianIndex(19, 38, 1, 0), CartesianIndex(18, 38, 1, 0),
        CartesianIndex(17, 38, 1, 0), CartesianIndex(16, 38, 1, 0), CartesianIndex(15, 38, 1, 0), CartesianIndex(14, 38, 1, 0),
        CartesianIndex(13, 38, 1, 0), CartesianIndex(12, 38, 1, 0), CartesianIndex(11, 38, 1, 0), CartesianIndex(10, 38, 1, 0),
        CartesianIndex(9, 38, 1, 0), CartesianIndex(8, 38, 1, 0), CartesianIndex(7, 38, 1, 0), CartesianIndex(6, 38, 1, 0),
        CartesianIndex(5, 38, 1, 0), CartesianIndex(4, 38, 1, 0), CartesianIndex(3, 38, 1, 0), CartesianIndex(3, 38, 4, 0),
        CartesianIndex(3, 37, 4, 0), CartesianIndex(3, 36, 4, 0), CartesianIndex(3, 35, 4, 0), CartesianIndex(3, 34, 4, 0),
        CartesianIndex(3, 33, 4, 0), CartesianIndex(3, 32, 4, 0), CartesianIndex(3, 31, 4, 0), CartesianIndex(3, 30, 4, 0),
        CartesianIndex(3, 29, 4, 0), CartesianIndex(3, 28, 4, 0), CartesianIndex(3, 27, 4, 0), CartesianIndex(3, 26, 4, 0),
        CartesianIndex(3, 25, 4, 0), CartesianIndex(3, 24, 4, 0), CartesianIndex(3, 23, 4, 0), CartesianIndex(3, 22, 4, 0),
        CartesianIndex(3, 21, 4, 0), CartesianIndex(3, 20, 4, 0), CartesianIndex(3, 19, 4, 0), CartesianIndex(3, 18, 4, 0),
        CartesianIndex(3, 17, 4, 0), CartesianIndex(3, 16, 4, 0), CartesianIndex(3, 15, 4, 0), CartesianIndex(3, 14, 4, 0),
        CartesianIndex(3, 13, 4, 0), CartesianIndex(3, 12, 4, 0), CartesianIndex(3, 11, 4, 0), CartesianIndex(3, 10, 4, 0),
        CartesianIndex(3, 9, 4, 0), CartesianIndex(3, 8, 4, 0), CartesianIndex(3, 8, 3, 0), CartesianIndex(4, 8, 3, 0),
        CartesianIndex(5, 8, 3, 0), CartesianIndex(6, 8, 3, 0), CartesianIndex(6, 8, 2, 0), CartesianIndex(6, 8, 2, 65),
        ]
end


@testset "SIPP_occupancy_at_location" begin
    testplan = TLOCATION_FILL.([
        0 0 0 1 1
        2 0 2 0 1
        5 0 1 0 7
        2 0 1 0 2
        0 0 0 0 0
    ])

    teststeps = 132
    testdepth = TIME_MULTIPLIER * teststeps
    ctx = TContext(testplan, teststeps, testdepth)

    testparkings = [
        (i, j, find_side_to_face(i, j, ctx)) for
        i ∈ 1:ctx.nRow, j ∈ 1:ctx.nCol if ctx.plan[i, j] ∈
        [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
    ]

    ctx.special_locations["parking"] =
        [TLocation("PARK", r, c, d) for (r, c, d) ∈ testparkings]


    ##################################################################################################################
    # WITHOUT ANY PATH

    # empty location - not occupied at all
    testtimeshift = 0
    time_shift = 0
    list_allocation_paths = TPath_rcdt[]

    sippctx = SIPPCalculationContext(ctx)
    sippctx.occupancy = fill_blockages!(time_shift, list_allocation_paths, sippctx)

    for x ∈ 1:sippctx.ctx.nRow, y ∈ 1:sippctx.ctx.nCol
        @test can_be_occupied(x, y, ctx) == (length(sippctx.occupancy[x, y]) == 0)
    end

    @test size(sippctx.occupancy[1, 1].segments)[1] == teststeps
    @test length(sippctx.occupancy[1, 1]) == 0
    @test sippctx.occupancy[1, 1].segments[1] == (0, 0)

    @test size(sippctx.occupancy[2, 1]) == teststeps
    @test length(sippctx.occupancy[2, 1]) == 1
    @test sippctx.occupancy[2, 1].segments[1] == (0, teststeps)
end


@testset "SIPP_Safe_intervals" begin
    testplan = TLOCATION_FILL.([
        0 0 0 1 1
        2 0 2 0 1
        5 0 1 0 7
        2 0 1 0 2
        0 0 0 0 0
    ])

    teststeps = 132
    testdepth = TIME_MULTIPLIER * teststeps
    ctx = TContext(testplan, teststeps, testdepth)

    testparkings = [
        (i, j, find_side_to_face(i, j, ctx)) for
        i ∈ 1:ctx.nRow, j ∈ 1:ctx.nCol if ctx.plan[i, j] ∈
        [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
    ]

    ctx.special_locations["parking"] =
        [TLocation("PARK", r, c, d) for (r, c, d) ∈ testparkings]


    ##################################################################################################################
    # WITHOUT ANY PATH

    # empty location - not occupied at all
    time_shift = 0
    list_allocation_paths = []

    sippctx = SIPPCalculationContext(ctx)
    sippctx.occupancy = fill_blockages!(time_shift, list_allocation_paths, sippctx)

    @test can_be_occupied(1, 1, sippctx) == true
    @test size(sippctx.occupancy[1, 1]) == teststeps
    @test length(sippctx.occupancy[1, 1]) == 0
    @test sippctx.occupancy[1, 1].segments[1] == (0, 0)

    @test can_be_occupied(2, 1, sippctx) == false
    @test size(sippctx.occupancy[2, 1]) == teststeps
    @test length(sippctx.occupancy[2, 1]) == 1
    @test sippctx.occupancy[2, 1].segments[1] == (0, teststeps)
    @test sippctx.occupancy[2, 1].segments[2] == (0, 0)

    @test can_be_occupied(3, 1, sippctx) == true
    @test size(sippctx.occupancy[3, 1]) == teststeps
    @test length(sippctx.occupancy[3, 1]) == 0
    @test sippctx.occupancy[3, 1].segments[1] == (0, 0)

    @test can_be_occupied(4, 4, sippctx) == true
    @test size(sippctx.occupancy[4, 4]) == teststeps
    @test length(sippctx.occupancy[4, 4]) == 0
    @test sippctx.occupancy[4, 4].segments[1] == (0, 0)

    @test can_be_occupied(4, 5, sippctx) == false
    @test size(sippctx.occupancy[4, 5]) == teststeps
    @test length(sippctx.occupancy[4, 5]) == 1
    @test sippctx.occupancy[4, 5].segments[1] == (0, teststeps)
    @test sippctx.occupancy[4, 5].segments[2] == (0, 0)

    @test can_be_occupied(4, 2, sippctx) == true
    @test size(sippctx.occupancy[4, 2]) == teststeps
    @test length(sippctx.occupancy[4, 2]) == 0
    @test sippctx.occupancy[4, 2].segments[1] == (0, 0)

    @test can_be_occupied(5, 2, sippctx) == true
    @test size(sippctx.occupancy[5, 2]) == teststeps
    @test length(sippctx.occupancy[5, 2]) == 0
    @test sippctx.occupancy[5, 2].segments[1] == (0, 0)

    @test can_be_occupied(5, 1, sippctx) == true
    @test size(sippctx.occupancy[5, 1]) == teststeps
    @test length(sippctx.occupancy[5, 1]) == 0
    @test sippctx.occupancy[5, 1].segments[1] == (0, 0)

    # TODO: This is a sort of stupid test. If a location is busy in the future due to a path, it doesn't mean that it cannot be occupied in theory.
    for x ∈ 1:sippctx.ctx.nRow, y ∈ 1:sippctx.ctx.nCol
        @test can_be_occupied(x, y, ctx) == (length(sippctx.occupancy[x, y]) == 0)
    end


    ##################################################################################################################
    # WITH PATH

    testtimeshift = 0
    list_allocation_paths =
        [[Trcdt(4, 2, 3, 10), Trcdt(5, 2, 3, 11), Trcdt(5, 2, 4, 26), Trcdt(5, 1, 4, 27)]]

    sippctx = SIPPCalculationContext(ctx)
    sippctx.occupancy = fill_blockages!(time_shift, list_allocation_paths, sippctx)

    @test can_be_occupied(1, 1, sippctx) == true
    @test size(sippctx.occupancy[1, 1]) == teststeps
    @test length(sippctx.occupancy[1, 1]) == 0
    @test sippctx.occupancy[1, 1].segments[1] == (0, 0)

    @test can_be_occupied(2, 1, sippctx) == false
    @test size(sippctx.occupancy[2, 1]) == teststeps
    @test length(sippctx.occupancy[2, 1]) == 1
    @test sippctx.occupancy[2, 1].segments[1] == (0, teststeps)
    @test sippctx.occupancy[2, 1].segments[2] == (0, 0)

    @test can_be_occupied(3, 1, sippctx) == true
    @test size(sippctx.occupancy[3, 1]) == teststeps
    @test length(sippctx.occupancy[3, 1]) == 0
    @test sippctx.occupancy[3, 1].segments[1] == (0, 0)

    @test can_be_occupied(4, 4, sippctx) == true
    @test size(sippctx.occupancy[4, 4]) == teststeps
    @test length(sippctx.occupancy[4, 4]) == 0
    @test sippctx.occupancy[4, 4].segments[1] == (0, 0)

    @test can_be_occupied(4, 5, sippctx) == false
    @test size(sippctx.occupancy[4, 5]) == teststeps
    @test length(sippctx.occupancy[4, 5]) == 1
    @test sippctx.occupancy[4, 5].segments[1] == (0, teststeps)
    @test sippctx.occupancy[4, 5].segments[2] == (0, 0)

    @test can_be_occupied(4, 2, sippctx) == true
    @test size(sippctx.occupancy[4, 2]) == teststeps
    @test length(sippctx.occupancy[4, 2]) == 1
    @test sippctx.occupancy[4, 2].segments[1] ==
          (10 - STEP_SAFETY_BUFFER, 11 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[4, 2].segments[2] == (0, 0)

    @test can_be_occupied(5, 2, sippctx) == true
    @test size(sippctx.occupancy[5, 2]) == teststeps
    @test length(sippctx.occupancy[5, 2]) == 4
    @test sippctx.occupancy[5, 2].segments[1] ==
          (10 - STEP_SAFETY_BUFFER, 11 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 2].segments[2] ==
          (11 - STEP_SAFETY_BUFFER, 26 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 2].segments[3] ==
          (11 - STEP_SAFETY_BUFFER, 26 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 2].segments[4] ==
          (26 - STEP_SAFETY_BUFFER, 27 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 2].segments[5] == (0, 0)

    @test can_be_occupied(5, 1, sippctx) == true
    @test size(sippctx.occupancy[5, 1]) == teststeps
    @test length(sippctx.occupancy[5, 1]) == 1
    @test sippctx.occupancy[5, 1].segments[1] ==
          (26 - STEP_SAFETY_BUFFER, 27 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 1].segments[2] == (0, 0)


    @test list_safe_intervals(sippctx.occupancy[1, 1], ctx; time_shift = time_shift) ==
          [(0, teststeps)]

    @test list_safe_intervals(sippctx.occupancy[2, 1], ctx; time_shift = time_shift) == []

    @test list_safe_intervals(sippctx.occupancy[4, 2], ctx; time_shift = time_shift) == [
        (0, max(0, 10 - time_shift - STEP_SAFETY_BUFFER - 1)),
        (max(1, 11 - time_shift + STEP_SAFETY_BUFFER + 1), teststeps),
    ]

    @test list_safe_intervals(sippctx.occupancy[5, 2], ctx; time_shift = time_shift) ==
          [(0, 10 - STEP_SAFETY_BUFFER - 1), (27 + STEP_SAFETY_BUFFER + 1, teststeps)]

    @test list_safe_intervals(sippctx.occupancy[5, 1], ctx; time_shift = time_shift) ==
          [(0, 26 - STEP_SAFETY_BUFFER - 1), (27 + STEP_SAFETY_BUFFER + 1, teststeps)]



    ##################################################################################################################
    # TIME SHIFT = 7
    time_shift = 7
    list_allocation_paths =
        [[Trcdt(4, 2, 3, 10), Trcdt(5, 2, 3, 11), Trcdt(5, 2, 4, 26), Trcdt(5, 1, 4, 27)]]

    sippctx = SIPPCalculationContext(ctx)
    sippctx.occupancy = fill_blockages!(time_shift, list_allocation_paths, sippctx)

    @test can_be_occupied(1, 1, sippctx) == true
    @test sippctx.occupancy[1, 1].segments[1] == (0, 0)

    @test can_be_occupied(2, 1, sippctx) == false
    @test size(sippctx.occupancy[2, 1]) == teststeps
    @test length(sippctx.occupancy[2, 1]) == 1
    @test sippctx.occupancy[2, 1].segments[1] == (0, teststeps)
    @test sippctx.occupancy[2, 1].segments[2] == (0, 0)

    @test can_be_occupied(3, 1, sippctx) == true
    @test size(sippctx.occupancy[3, 1]) == teststeps
    @test length(sippctx.occupancy[3, 1]) == 0
    @test sippctx.occupancy[3, 1].segments[1] == (0, 0)

    @test can_be_occupied(4, 4, sippctx) == true
    @test sippctx.occupancy[4, 4].segments[2] == (0, 0)

    @test can_be_occupied(4, 5, sippctx) == false
    @test sippctx.occupancy[4, 5].segments[1] == (0, teststeps)

    @test can_be_occupied(4, 2, sippctx) == true
    @test sippctx.occupancy[4, 2].segments[1] ==
          (10 - STEP_SAFETY_BUFFER, 11 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[4, 2].segments[2] == (0, 0)

    @test can_be_occupied(5, 2, sippctx) == true
    @test sippctx.occupancy[5, 2].segments[1] ==
          (10 - STEP_SAFETY_BUFFER, 11 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 2].segments[2] ==
          (11 - STEP_SAFETY_BUFFER, 26 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 2].segments[3] ==
          (11 - STEP_SAFETY_BUFFER, 26 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 2].segments[4] ==
          (26 - STEP_SAFETY_BUFFER, 27 + STEP_SAFETY_BUFFER)

    @test can_be_occupied(5, 1, sippctx) == true
    @test sippctx.occupancy[5, 1].segments[1] ==
          (26 - STEP_SAFETY_BUFFER, 27 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 1].segments[2] == (0, 0)


    @test list_safe_intervals(sippctx.occupancy[1, 1], ctx; time_shift = time_shift) ==
          [(0, teststeps)]

    @test list_safe_intervals(sippctx.occupancy[2, 1], ctx; time_shift = time_shift) == []

    @test list_safe_intervals(sippctx.occupancy[4, 2], ctx; time_shift = time_shift) == [
        (
            min(time_shift, 10 - STEP_SAFETY_BUFFER - 1),
            max(time_shift, 10 - STEP_SAFETY_BUFFER - 1),
        ),
        (max(time_shift, 11 + STEP_SAFETY_BUFFER + 1), teststeps),
    ]

    @test list_safe_intervals(sippctx.occupancy[5, 2], ctx; time_shift = time_shift) == [
        (time_shift, 10 - STEP_SAFETY_BUFFER - 1),
        (27 + STEP_SAFETY_BUFFER + 1, teststeps),
    ]

    @test list_safe_intervals(sippctx.occupancy[5, 1], ctx; time_shift = time_shift) == [
        (min(time_shift, 26 - STEP_SAFETY_BUFFER - 1), 26 - STEP_SAFETY_BUFFER - 1),
        (max(time_shift, 27 + STEP_SAFETY_BUFFER + 1), teststeps),
    ]



    ##################################################################################################################
    # TIME SHIFT = 17
    time_shift = 17
    list_allocation_paths =
        [[Trcdt(4, 2, 3, 10), Trcdt(5, 2, 3, 11), Trcdt(5, 2, 4, 26), Trcdt(5, 1, 4, 27)]]

    sippctx = SIPPCalculationContext(ctx)
    sippctx.occupancy = fill_blockages!(time_shift, list_allocation_paths, sippctx)

    @test can_be_occupied(1, 1, sippctx) == true
    @test size(sippctx.occupancy[1, 1]) == teststeps
    @test length(sippctx.occupancy[1, 1]) == 0
    @test sippctx.occupancy[1, 1].segments[1] == (0, 0)

    @test can_be_occupied(2, 1, sippctx) == false
    @test size(sippctx.occupancy[2, 1]) == teststeps
    @test length(sippctx.occupancy[2, 1]) == 1
    @test sippctx.occupancy[2, 1].segments[1] == (0, teststeps)
    @test sippctx.occupancy[2, 1].segments[2] == (0, 0)

    @test can_be_occupied(3, 1, sippctx) == true
    @test size(sippctx.occupancy[3, 1]) == teststeps
    @test length(sippctx.occupancy[3, 1]) == 0
    @test sippctx.occupancy[3, 1].segments[1] == (0, 0)

    @test can_be_occupied(4, 4, sippctx) == true
    @test size(sippctx.occupancy[4, 4]) == teststeps
    @test length(sippctx.occupancy[4, 4]) == 0
    @test sippctx.occupancy[4, 4].segments[1] == (0, 0)

    @test can_be_occupied(4, 5, sippctx) == false
    @test size(sippctx.occupancy[4, 5]) == teststeps
    @test length(sippctx.occupancy[4, 5]) == 1
    @test sippctx.occupancy[4, 5].segments[1] == (0, teststeps)
    @test sippctx.occupancy[4, 5].segments[2] == (0, 0)

    @test can_be_occupied(4, 2, sippctx) == true
    @test size(sippctx.occupancy[4, 2]) == teststeps
    @test length(sippctx.occupancy[4, 2]) == 0
    @test sippctx.occupancy[4, 2].segments[1] == (0, 0)

    @test can_be_occupied(5, 2, sippctx) == true
    @test size(sippctx.occupancy[5, 2]) == teststeps
    @test length(sippctx.occupancy[5, 2]) == 3
    @test sippctx.occupancy[5, 2].segments[1] ==
          (11 - STEP_SAFETY_BUFFER, 26 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 2].segments[2] ==
          (11 - STEP_SAFETY_BUFFER, 26 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 2].segments[3] ==
          (26 - STEP_SAFETY_BUFFER, 27 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 2].segments[4] == (0, 0)

    @test can_be_occupied(5, 1, sippctx) == true
    @test size(sippctx.occupancy[5, 1]) == teststeps
    @test length(sippctx.occupancy[5, 1]) == 1
    @test sippctx.occupancy[5, 1].segments[1] ==
          (26 - STEP_SAFETY_BUFFER, 27 + STEP_SAFETY_BUFFER)
    @test sippctx.occupancy[5, 1].segments[2] == (0, 0)


    @test list_safe_intervals(sippctx.occupancy[1, 1], ctx; time_shift = time_shift) ==
          [(0, teststeps)]

    @test list_safe_intervals(sippctx.occupancy[2, 1], ctx; time_shift = time_shift) == []

    @test list_safe_intervals(sippctx.occupancy[4, 2], ctx; time_shift = time_shift) ==
          [(0, teststeps)]

    @test list_safe_intervals(sippctx.occupancy[5, 2], ctx; time_shift = time_shift) ==
          [(max(time_shift, 27 + STEP_SAFETY_BUFFER + 1), teststeps)]

    @test list_safe_intervals(sippctx.occupancy[5, 1], ctx; time_shift = time_shift) == [
        (
            min(time_shift, 26 - STEP_SAFETY_BUFFER - 1),
            max(time_shift, 26 - STEP_SAFETY_BUFFER - 1),
        ),
        (max(time_shift, 27 + STEP_SAFETY_BUFFER + 1), teststeps),
    ]
end
