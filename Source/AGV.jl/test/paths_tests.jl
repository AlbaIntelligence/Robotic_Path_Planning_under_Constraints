module_dir = "/home/emmanuel/Documents/Work/Alba/AGV/_gits/AGV.jl/"
module_img_dir = module_dir * "img/"
module_src_dir = module_dir * "src/"
cd(module_dir)

import Pkg;
Pkg.activate(".");

using LightGraphs, SimpleWeightedGraphs, Test
using AGV


##################################################################################################################
# Simple filling of the occupancy matrix

@testset "Fill_blockages_occupancy_matrix_1" begin

    ##################################################################################################################
    # Simple filling of the occupancy matrix

    testplan = TLOCATION_FILL.([
        1 4 2 4 2 4 2 4 1
        1 0 0 0 0 0 0 0 1
        1 4 2 4 2 4 2 4 1
    ])

    teststeps = 132
    testdepth = teststeps * TIME_MULTIPLIER

    testctx = TContext(testplan, teststeps, testdepth)
    testparkings = [
        (i, j, find_side_to_face(i, j, testctx)) for
        i ∈ 1:testctx.nRow, j ∈ 1:testctx.nCol if testctx.plan[i, j] ∈
        [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
    ]

    testctx.special_locations["parking"] =
        [TLocation("PARK", r, c, d) for (r, c, d) ∈ testparkings]

    testslice = testctx.nRow * testctx.nCol * nDirection
    testvertices = testslice * teststeps

    # WARNING: OCCUPANCY IS EVERYWHERE AROUND AT A STEP_SAFETY_BUFFER DISTANCE OF THE ALLOCATION PATH
    #          SUGGESTS. THIS GUARANTEES A SAFE SPACE (AND LESS SPURIOUS COLLISION IN THE SIMULATION)

    ##################################################################################################################
    # Single obstacle remaining on the same spot for entire duration

    ##############################################################################
    # No time shift
    testtimeshift = 0
    testalloactionpath = Trcdt[]
    testcalctx = AStarCalculationContext(testctx)

    # BEFORE FILLING BLOCKAGES
    fill_blockages!(testtimeshift, [testalloactionpath], testcalctx)

    for dr ∈ -STEP_SAFETY_BUFFER:STEP_SAFETY_BUFFER,
        dc ∈ -STEP_SAFETY_BUFFER:STEP_SAFETY_BUFFER

        println(
            "($(2 + dr), $(5 + dc)): $(can_be_occupied(2 + dr, 5 + dc, testcalctx.ctx))",
        )
    end


    for i ∈ 1:teststeps
        @test testcalctx.occupancy[1, 1, i] === true
        @test testcalctx.occupancy[1, 2, i] === false
        @test testcalctx.occupancy[1, 3, i] === true
        @test testcalctx.occupancy[1, 4, i] === false
        @test testcalctx.occupancy[1, 5, i] === true
        @test testcalctx.occupancy[1, 6, i] === false
        @test testcalctx.occupancy[1, 7, i] === true

        @test testcalctx.occupancy[2, 1, i] === true
        @test testcalctx.occupancy[2, 2, i] === false
        @test testcalctx.occupancy[2, 3, i] === false
        @test testcalctx.occupancy[2, 4, i] === false
        @test testcalctx.occupancy[2, 5, i] === false
        @test testcalctx.occupancy[2, 6, i] === false
        @test testcalctx.occupancy[2, 7, i] === false

        @test testcalctx.occupancy[3, 1, i] === true
        @test testcalctx.occupancy[3, 2, i] === false
        @test testcalctx.occupancy[3, 3, i] === true
        @test testcalctx.occupancy[3, 4, i] === false
        @test testcalctx.occupancy[3, 5, i] === true
        @test testcalctx.occupancy[3, 6, i] === false
        @test testcalctx.occupancy[3, 7, i] === true
    end


    @test testcalctx.occupancy[2, 5, 1] === false
    @test testcalctx.occupancy[2, 5, 2] === false
    @test testcalctx.occupancy[2, 5, 3] === false
    @test testcalctx.occupancy[2, 5, 4] === false
    @test testcalctx.occupancy[2, 5, 5] === false
    @test testcalctx.occupancy[2, 5, 63] === false
    @test testcalctx.occupancy[2, 5, 64] === false
    @test testcalctx.occupancy[2, 5, 65] === false
    @test testcalctx.occupancy[2, 5, 66] === false
    @test testcalctx.occupancy[2, 5, 67] === false

    @test testcalctx.occupancy[2, 4, 1] === testcalctx.occupancy[2, 5, 1]
    @test testcalctx.occupancy[2, 4, 2] === testcalctx.occupancy[2, 5, 2]
    @test testcalctx.occupancy[2, 4, 3] === testcalctx.occupancy[2, 5, 3]
    @test testcalctx.occupancy[2, 4, 4] === testcalctx.occupancy[2, 5, 4]
    @test testcalctx.occupancy[2, 4, 5] === testcalctx.occupancy[2, 5, 5]
    @test testcalctx.occupancy[2, 4, 63] === testcalctx.occupancy[2, 5, 63]
    @test testcalctx.occupancy[2, 4, 64] === testcalctx.occupancy[2, 5, 64]
    @test testcalctx.occupancy[2, 4, 65] === testcalctx.occupancy[2, 5, 65]
    @test testcalctx.occupancy[2, 4, 66] === testcalctx.occupancy[2, 5, 66]
    @test testcalctx.occupancy[2, 4, 67] === testcalctx.occupancy[2, 5, 67]

    @test testcalctx.occupancy[2, 6, 1] === testcalctx.occupancy[2, 5, 1]
    @test testcalctx.occupancy[2, 6, 2] === testcalctx.occupancy[2, 5, 2]
    @test testcalctx.occupancy[2, 6, 3] === testcalctx.occupancy[2, 5, 3]
    @test testcalctx.occupancy[2, 6, 4] === testcalctx.occupancy[2, 5, 4]
    @test testcalctx.occupancy[2, 6, 5] === testcalctx.occupancy[2, 5, 5]
    @test testcalctx.occupancy[2, 6, 63] === testcalctx.occupancy[2, 5, 63]
    @test testcalctx.occupancy[2, 6, 64] === testcalctx.occupancy[2, 5, 64]
    @test testcalctx.occupancy[2, 6, 65] === testcalctx.occupancy[2, 5, 65]
    @test testcalctx.occupancy[2, 6, 66] === testcalctx.occupancy[2, 5, 66]
    @test testcalctx.occupancy[2, 6, 67] === testcalctx.occupancy[2, 5, 67]

    rb, nrb = reacheability(2, 5, 2, 63, testcalctx)
    @test rb === true

    # AFTER FILLING BLOCKAGES
    testtimeshift = 0
    testalloactionpath = [
        Trcdt(2, 5, 2, 3),
        Trcdt(2, 5, 2, 5),
        Trcdt(2, 5, 2, 20),
        Trcdt(2, 5, 2, 30),
        Trcdt(2, 5, 2, 64),
    ]
    testcalctx = AStarCalculationContext(testctx)

    fill_blockages!(testtimeshift, [testalloactionpath], testcalctx)

    for dr ∈ -STEP_SAFETY_BUFFER:STEP_SAFETY_BUFFER,
        dc ∈ -STEP_SAFETY_BUFFER:STEP_SAFETY_BUFFER

        println(
            "($(2 + dr), $(5 + dc)): $(can_be_occupied(2 + dr, 5 + dc, testcalctx.ctx))",
        )
    end


    @test testcalctx.occupancy[1, 1, 1] === true
    @test testcalctx.occupancy[2, 1, 1] === true
    @test testcalctx.occupancy[3, 1, 1] === true
    @test testcalctx.occupancy[1, 2, 1] === false
    @test testcalctx.occupancy[1, 3, 1] === true

    @test testcalctx.occupancy[2, 5, 1] === false
    @test testcalctx.occupancy[2, 5, 2] === false
    @test testcalctx.occupancy[2, 5, 3] === true
    @test testcalctx.occupancy[2, 5, 4] === true
    @test testcalctx.occupancy[2, 5, 5] === true
    @test testcalctx.occupancy[2, 5, 63] === true
    @test testcalctx.occupancy[2, 5, 64] === true

    # WARNING: fill_blockages! fills until the end!
    @test testcalctx.occupancy[2, 5, 65] === true
    @test testcalctx.occupancy[2, 5, 66] === true
    @test testcalctx.occupancy[2, 5, 67] === true

    @test testcalctx.occupancy[2, 4, 1] === testcalctx.occupancy[2, 5, 1]
    @test testcalctx.occupancy[2, 4, 2] === testcalctx.occupancy[2, 5, 2]
    @test testcalctx.occupancy[2, 4, 3] === testcalctx.occupancy[2, 5, 3]
    @test testcalctx.occupancy[2, 4, 4] === testcalctx.occupancy[2, 5, 4]
    @test testcalctx.occupancy[2, 4, 5] === testcalctx.occupancy[2, 5, 5]
    @test testcalctx.occupancy[2, 4, 63] === testcalctx.occupancy[2, 5, 63]
    @test testcalctx.occupancy[2, 4, 64] === testcalctx.occupancy[2, 5, 64]
    @test testcalctx.occupancy[2, 4, 65] === testcalctx.occupancy[2, 5, 65]
    @test testcalctx.occupancy[2, 4, 66] === testcalctx.occupancy[2, 5, 66]
    @test testcalctx.occupancy[2, 4, 67] === testcalctx.occupancy[2, 5, 67]

    @test testcalctx.occupancy[2, 6, 1] === testcalctx.occupancy[2, 5, 1]
    @test testcalctx.occupancy[2, 6, 2] === testcalctx.occupancy[2, 5, 2]
    @test testcalctx.occupancy[2, 6, 3] === testcalctx.occupancy[2, 5, 3]
    @test testcalctx.occupancy[2, 6, 4] === testcalctx.occupancy[2, 5, 4]
    @test testcalctx.occupancy[2, 6, 5] === testcalctx.occupancy[2, 5, 5]
    @test testcalctx.occupancy[2, 6, 63] === testcalctx.occupancy[2, 5, 63]
    @test testcalctx.occupancy[2, 6, 64] === testcalctx.occupancy[2, 5, 64]
    @test testcalctx.occupancy[2, 6, 65] === testcalctx.occupancy[2, 5, 65]
    @test testcalctx.occupancy[2, 6, 66] === testcalctx.occupancy[2, 5, 66]
    @test testcalctx.occupancy[2, 6, 67] === testcalctx.occupancy[2, 5, 67]

    rb, nrb = reacheability(2, 5, 2, 63, testcalctx)
    # @test nrb === true
end


@testset "Fill_blockages_occupancy_matrix_2" begin
    testplan = TLOCATION_FILL.([
        1 4 2 4 2 4 2 4 1
        1 0 0 0 0 0 0 0 1
        1 4 2 4 2 4 2 4 1
    ])

    teststeps = 132
    testdepth = teststeps * TIME_MULTIPLIER

    testctx = TContext(testplan, teststeps, testdepth)
    testparkings = [
        (i, j, find_side_to_face(i, j, testctx)) for
        i ∈ 1:testctx.nRow, j ∈ 1:testctx.nCol if testctx.plan[i, j] ∈
        [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
    ]

    testctx.special_locations["parking"] =
        [TLocation("PARK", r, c, d) for (r, c, d) ∈ testparkings]

    testslice = testctx.nRow * testctx.nCol * nDirection
    testvertices = testslice * teststeps

    testtimeshift = 0
    # Before and after filling obstacles
    testcalctx = AStarCalculationContext(testctx)
    fill_blockages!(testtimeshift, TPath_rcdt[], testcalctx)

    @test testcalctx.occupancy[2, 5, 3] === false
    @test testcalctx.occupancy[2, 5, 4] === false
    @test testcalctx.occupancy[2, 4, 5] === false
    @test testcalctx.occupancy[2, 5, 5] === false
    @test testcalctx.occupancy[2, 6, 5] === false
    @test testcalctx.occupancy[2, 5, 6] === false
    @test testcalctx.occupancy[2, 5, 7] === false
    @test testcalctx.occupancy[2, 5, 8] === false

    @test any(list_cost_to_reach_3D(2, 4, 2, testcalctx) .=== COST_IMPOSSIBLE) === false
    @test any(list_cost_to_reach_3D(2, 4, 3, testcalctx) .=== COST_IMPOSSIBLE) === false
    @test any(list_cost_to_reach_3D(2, 4, 4, testcalctx) .=== COST_IMPOSSIBLE) === false
    @test any(list_cost_to_reach_3D(2, 4, 5, testcalctx) .=== COST_IMPOSSIBLE) === false

    rb, nrb, _, _ = reacheability(2, 4, 2, 5, testcalctx)
    @test rb === true

    @test any(list_cost_to_reach_3D(2, 5, 2, testcalctx) .=== COST_IMPOSSIBLE) === false
    @test any(list_cost_to_reach_3D(2, 5, 3, testcalctx) .=== COST_IMPOSSIBLE) === false
    @test any(list_cost_to_reach_3D(2, 5, 4, testcalctx) .=== COST_IMPOSSIBLE) === false
    @test any(list_cost_to_reach_3D(2, 5, 5, testcalctx) .=== COST_IMPOSSIBLE) === false
    @test any(list_cost_to_reach_3D(2, 5, 6, testcalctx) .=== COST_IMPOSSIBLE) === false

    rb, nrb, o, r = reacheability(2, 5, 2, 6, testcalctx)
    println(rb)
    println(nrb)
    println(o)
    println(r)
    @test rb === true

end

@testset "Fill_blockages_occupancy_matrix_3" begin
    testplan = TLOCATION_FILL.([
        1 4 2 4 2 4 2 4 1
        1 0 0 0 0 0 0 0 1
        1 4 2 4 2 4 2 4 1
    ])

    teststeps = 132
    testdepth = teststeps * TIME_MULTIPLIER

    testctx = TContext(testplan, teststeps, testdepth)
    testparkings = [
        (i, j, find_side_to_face(i, j, testctx)) for
        i ∈ 1:testctx.nRow, j ∈ 1:testctx.nCol if testctx.plan[i, j] ∈
        [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
    ]

    testctx.special_locations["parking"] =
        [TLocation("PARK", r, c, d) for (r, c, d) ∈ testparkings]

    testslice = testctx.nRow * testctx.nCol * nDirection
    testvertices = testslice * teststeps

    testtimeshift = 0
    testalloactionpath = [Trcdt(2, 5, 2, 10), Trcdt(2, 6, 2, 20)]
    testcalctx = AStarCalculationContext(testctx)
    fill_blockages!(testtimeshift, [testalloactionpath], testcalctx)

    rb, nrb, _, _ = reacheability(2, 4, 2, 5, testcalctx)
    @test rb === true

    rb, nrb, o, r = reacheability(2, 5, 2, 6, testcalctx)
    println(rb)
    println(nrb)
    println(o)
    println(r)
    @test rb === true
end

@testset "Fill_blockages_occupancy_matrix_4" begin
    testplan = TLOCATION_FILL.([
        1 4 2 4 2 4 2 4 1
        1 0 0 0 0 0 0 0 1
        1 4 2 4 2 4 2 4 1
    ])

    teststeps = 132
    testdepth = teststeps * TIME_MULTIPLIER

    testctx = TContext(testplan, teststeps, testdepth)
    testparkings = [
        (i, j, find_side_to_face(i, j, testctx)) for
        i ∈ 1:testctx.nRow, j ∈ 1:testctx.nCol if testctx.plan[i, j] ∈
        [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
    ]

    testctx.special_locations["parking"] =
        [TLocation("PARK", r, c, d) for (r, c, d) ∈ testparkings]

    testslice = testctx.nRow * testctx.nCol * nDirection
    testvertices = testslice * teststeps

    ##############################################################################
    # With time shift
    testtimeshift = 3
    testalloactionpath = [
        Trcdt(2, 5, 2, 1),
        Trcdt(2, 5, 2, 5),
        Trcdt(2, 5, 2, 20),
        Trcdt(2, 5, 2, 30),
        Trcdt(2, 5, 2, 64),
    ]
    testcalctx = AStarCalculationContext(testctx)
    fill_blockages!(testtimeshift, [testalloactionpath], testcalctx)

    @test testcalctx.occupancy[1, 1, 1] === true
    @test testcalctx.occupancy[2, 1, 1] === true
    @test testcalctx.occupancy[3, 1, 1] === true
    @test testcalctx.occupancy[1, 2, 1] === false
    @test testcalctx.occupancy[1, 3, 1] === true

    rb, nrb = reacheability(2, 5, 2, 63, testcalctx)
    # @test nrb === true
end


@testset "Fill_blockages_occupancy_matrix_5" begin
    testplan = TLOCATION_FILL.([
        1 4 2 4 2 4 2 4 1
        1 0 0 0 0 0 0 0 1
        1 4 2 4 2 4 2 4 1
    ])

    teststeps = 132
    testdepth = teststeps * TIME_MULTIPLIER

    testctx = TContext(testplan, teststeps, testdepth)
    testparkings = [
        (i, j, find_side_to_face(i, j, testctx)) for
        i ∈ 1:testctx.nRow, j ∈ 1:testctx.nCol if testctx.plan[i, j] ∈
        [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
    ]

    testctx.special_locations["parking"] =
        [TLocation("PARK", r, c, d) for (r, c, d) ∈ testparkings]

    testslice = testctx.nRow * testctx.nCol * nDirection
    testvertices = testslice * teststeps

    ##############################################################################
    # With time shift starting after start of occupancy, finishing after end of occupancy
    testtimeshift = 10
    testalloactionpath = [Trcdt(2, 5, 2, 15), Trcdt(2, 5, 2, 30)]
    testcalctx = AStarCalculationContext(testctx)
    fill_blockages!(testtimeshift, [testalloactionpath], testcalctx)

    @test testcalctx.occupancy[1, 1, 1] === true
    @test testcalctx.occupancy[2, 1, 1] === true
    @test testcalctx.occupancy[3, 1, 1] === true
    @test testcalctx.occupancy[1, 2, 1] === false
    @test testcalctx.occupancy[1, 3, 1] === true

    rb, nrb = reacheability(2, 5, 2, 4, testcalctx)
    @test rb === true

    # Check occupancy from time 15 = 10 (time shift) + 5 (start of occupancy)
    #                   to time 73 = 10              + 63 (end of occupancy)
    rb, nrb = reacheability(2, 5, 5, 63, testcalctx)
    # @test nrb === true
end


@testset "Fill_blockages_graph_reacheability" begin
    testplan = TLOCATION_FILL.([
        1 4 2 4 2 4 2 4 1
        1 0 0 0 0 0 0 0 1
        1 4 2 4 2 4 2 4 1
    ])

    teststeps = 132
    testdepth = teststeps * TIME_MULTIPLIER

    testctx = TContext(testplan, teststeps, testdepth)
    testparkings = [
        (i, j, find_side_to_face(i, j, testctx)) for
        i ∈ 1:testctx.nRow, j ∈ 1:testctx.nCol if testctx.plan[i, j] ∈
        [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
    ]

    testctx.special_locations["parking"] =
        [TLocation("PARK", r, c, d) for (r, c, d) ∈ testparkings]

    testslice = testctx.nRow * testctx.nCol * nDirection
    testvertices = testslice * teststeps

    # Single obstacle for ever

    # WARNING: OCCUPANCY STARTS 3 STEPS BEFORE AND ENDS 3 STEPS LATER THAN THE ALLOCATION PATH
    #          SUGGESTS. THIS GUARANTEES A SAFE SPACE (AND LESS SPURIOUS COLLISION IN THE SIMULATION)

    # No time shift
    testtimeshift = 0
    testalloactionpath = [Trcdt(2, 5, 2, 10), Trcdt(2, 6, 2, 20)]
    testcalctx = AStarCalculationContext(testctx)
    fill_blockages!(testtimeshift, [testalloactionpath], testcalctx)

    # (2, 4) is never occupied.
    rb, nrb = reacheability(2, 4, 2, 63, testcalctx)
    @test_skip rb === true

    # Occupancy of (2, 5) only starts at t=10. Occupancy starts at t=7.
    # t=6 is fine. t=9 is not.
    rb, nrb, o, r = reacheability(2, 5, 2, 6, testcalctx)
    println(rb)
    println(nrb)
    println(o)
    println(r)
    @test_skip rb === true

    rb, nrb = reacheability(2, 5, 2, 9, testcalctx)
    @test_skip rb === false

    # Occupancy of (2, 5) only ends at t=20. t=19 is not possible.
    rb, nrb = reacheability(2, 5, 10, 19, testcalctx)
    @test_skip nrb === true

    rb, nrb = reacheability(2, 5, 20, 63, testcalctx)
    @test_skip rb === false

    rb, nrb = reacheability(2, 6, 2, 9, testcalctx)
    @test_skip rb === false

    rb, nrb = reacheability(2, 6, 10, 20, testcalctx)
    @test_skip nrb === true

    rb, nrb = reacheability(2, 6, 21, 63, testcalctx)
    @test_skip nrb === true


    # Time shift = 15

    testtimeshift = 15
    testalloactionpath = [Trcdt(2, 5, 2, 10), Trcdt(2, 6, 2, 20)]
    testcalctx = AStarCalculationContext(testctx)
    fill_blockages!(testtimeshift, [testalloactionpath], testcalctx)

    rb, nrb = reacheability(2, 4, 2, 63, testcalctx)
    @test_skip rb === true
    rb, nrb = reacheability(2, 5, 2, 4, testcalctx)
    @test_skip nrb === true
    rb, nrb = reacheability(2, 5, 5, 63, testcalctx)
    @test_skip rb === false
    rb, nrb = reacheability(2, 6, 2, 63, testcalctx)
    @test_skip nrb === true


    testtimeshift = 25
    testalloactionpath = [Trcdt(2, 5, 2, 10), Trcdt(2, 6, 2, 20), Trcdt(2, 7, 2, 30)]
    testcalctx = AStarCalculationContext(testctx)
    fill_blockages!(testtimeshift, [testalloactionpath], testcalctx)

    rb, nrb = reacheability(2, 4, 2, 63, testcalctx)
    @test rb === true
    rb, nrb = reacheability(2, 5, 2, 63, testcalctx)
    @test rb === true
    rb, nrb = reacheability(2, 6, 2, 4, testcalctx)
    @test nrb === true
    rb, nrb = reacheability(2, 6, 5, 63, testcalctx)
    @test rb === false
    rb, nrb = reacheability(2, 7, 2, 63, testcalctx)
    @test nrb === true
end
