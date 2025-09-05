module_dir = "/home/emmanuel/Documents/Work/Alba/AGV/_gits/AGV.jl/"
module_img_dir = module_dir * "img/"
module_src_dir = module_dir * "src/"
cd(module_dir)

import Pkg;
Pkg.activate(".");

using LightGraphs, SimpleWeightedGraphs, Test
using AGV



###############################################################################################################33
#
# SIPP Calculation ontext
#
@testset "SIPP Calculation Context" begin
    time_shift = 0

    testplan = TLOCATION_FILL.([
        0 0 0 1 1
        2 0 1 0 1
        5 0 1 0 7
        2 0 1 0 1
        0 0 0 0 0
    ])

    # For the moment, no 2D backstop
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


    testAGV1 = TAGV(
        "AGV1",
        TCoord(0.0, 0.0, Trc(1, 1)),
        Right,
        TTime(1.0, 1),
        THeight(0.0, 0),
        false,
        true,
        [],
        TLocation(),
    )
    testAGV2 = TAGV(
        "AGV2",
        TCoord(0.0, 0.0, Trc(5, 5)),
        Left,
        TTime(1.0, 1),
        THeight(0.0, 0),
        false,
        true,
        [],
        TLocation(),
    )
    TESTAGVS = [testAGV1, testAGV2]
    testplans = initialise_plans(TESTAGVS)


    testtask1 = TTask(
        "TASK1",
        TLocation(
            "Palette1",
            TCoord(0.0, 0.0, Trc(3, 2)),
            THeight(1.0, 1),
            Left,
            true,
            true,
        ),
        TLocation(
            "Palette2",
            TCoord(0.0, 0.0, Trc(3, 4)),
            THeight(1.0, 1),
            Left,
            true,
            true,
        ),
    )
    testtask2 = TTask(
        "TASK2",
        TLocation(
            "Palette3",
            TCoord(0.0, 0.0, Trc(4, 4)),
            THeight(5.0, 5),
            Right,
            true,
            true,
        ),
        TLocation(
            "Palette4",
            TCoord(0.0, 0.0, Trc(2, 2)),
            THeight(9.0, 9),
            Right,
            true,
            true,
        ),
    )

    list_allocation_paths = []
    sippctx = SIPPCalculationContext(ctx)
    sippctx.occupancy = fill_blockages!(time_shift, list_allocation_paths, sippctx)
end
