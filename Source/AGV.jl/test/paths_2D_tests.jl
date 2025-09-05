module_dir = "/home/emmanuel/Documents/Work/Alba/AGV/_gits/AGV.jl/"
module_img_dir = module_dir * "img/"
module_src_dir = module_dir * "src/"
cd(module_dir)

import Pkg;
Pkg.activate(".");

using LightGraphs, SimpleWeightedGraphs, Test
using AGV


testplan = TLOCATION_FILL.([
    0 0 0 1 1
    2 0 1 0 1
    5 0 1 0 7
    2 0 1 0 1
    0 0 0 0 0
])

teststeps = 400
testdepth = TIME_MULTIPLIER * teststeps
testctx = TContext(testplan, teststeps, testdepth)
testparkings = [
    (i, j, find_side_to_face(i, j, testctx)) for
    i ∈ 1:testctx.nRow, j ∈ 1:testctx.nCol if testctx.plan[i, j] ∈
    [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
]

testctx.special_locations["parking"] =
    [TLocation("PARK", r, c, d) for (r, c, d) ∈ testparkings]


@testset "Mini path" begin
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
        TCoord(0.0, 0.0, Trc(1, 1)),
        Left,
        TTime(1.0, 1),
        THeight(0.0, 0),
        false,
        true,
        [],
        TLocation(),
    )

    testtask1 = TTask(
        "TASK1",
        TLocation(
            "Palette1",
            TCoord(0.0, 0.0, Trc(1, 1)),
            THeight(1.0, 1),
            Right,
            true,
            true,
        ),
        TLocation(
            "Palette2",
            TCoord(0.0, 0.0, Trc(1, 1)),
            THeight(1.0, 1),
            Right,
            true,
            true,
        ),
    )

    testcalctx = AStarCalculationContext(testctx)

    list_rcdt, list_vertices, list_costs = path_a_b_2D(testtask1, testcalctx)
    @test list_rcdt == Any[]
    @test list_vertices == Int64[]
    @test list_costs == Any[]

    # Move 1 to right
    testtask2 = TTask(
        "TASK2",
        TLocation(
            "Palette3",
            TCoord(0.0, 0.0, Trc(1, 1)),
            THeight(5.0, 5),
            Right,
            true,
            true,
        ),
        TLocation(
            "Palette4",
            TCoord(0.0, 0.0, Trc(1, 2)),
            THeight(9.0, 9),
            Right,
            true,
            true,
        ),
    )

    list_rcdt, list_vertices, list_costs = path_a_b_2D(testtask2, testcalctx)
    @test list_rcdt == [CartesianIndex(1, 1, 2, 0), CartesianIndex(1, 2, 2, 1)]
    @test list_costs == [COST_FWD]


    # Move 3 to right
    testtask3 = TTask(
        "TASK2",
        TLocation(
            "Palette3",
            TCoord(0.0, 0.0, Trc(1, 1)),
            THeight(5.0, 5),
            Right,
            true,
            true,
        ),
        TLocation(
            "Palette4",
            TCoord(0.0, 0.0, Trc(1, 3)),
            THeight(9.0, 9),
            Right,
            true,
            true,
        ),
    )

    list_rcdt, list_vertices, list_costs = path_a_b_2D(testtask3, testcalctx)
    @test list_rcdt == [
        CartesianIndex(1, 1, 2, 0),
        CartesianIndex(1, 2, 2, 1),
        CartesianIndex(1, 3, 2, 2),
    ]
    @test list_costs == [COST_FWD, COST_FWD]


    # Move 1, 1 => 2, 2
    testtask4 = TTask(
        "TASK2",
        TLocation(
            "Palette3",
            TCoord(0.0, 0.0, Trc(1, 1)),
            THeight(5.0, 5),
            Right,
            true,
            true,
        ),
        TLocation(
            "Palette4",
            TCoord(0.0, 0.0, Trc(2, 2)),
            THeight(9.0, 9),
            Down,
            true,
            true,
        ),
    )

    list_rcdt, list_vertices, list_costs = path_a_b_2D(testtask4, testcalctx)
    @test list_rcdt == [
        CartesianIndex(1, 1, 2, 0),
        CartesianIndex(1, 2, 2, 1),
        CartesianIndex(1, 2, 3, 16),
        CartesianIndex(2, 2, 3, 17),
    ]
    @test list_costs == [COST_FWD, COST_TRN, COST_FWD]
end



#@testset "Stationary path" begin
#     testAGV1 = TAGV(
#         "AGV1",
#         TCoord(0.0, 0.0, Trc(1, 1)),
#         Right,
#         TTime(1.0, 1),
#         THeight(0.0, 0),
#         false,
#         true,
#         [],
#         TLocation(),
#     )

#     testAGV2 = TAGV(
#         "AGV2",
#         TCoord(0.0, 0.0, Trc(1, 1)),
#         Left,
#         TTime(1.0, 1),
#         THeight(0.0, 0),
#         false,
#         true,
#         [],
#         TLocation(),
#     )

#     testtask1 = TTask(
#         "TASK1",
#         TLocation(
#             "Palette1",
#             TCoord(0.0, 0.0, Trc(1, 1)),
#             THeight(1.0, 1),
#             Right,
#             true,
#             true,
#         ),
#         TLocation(
#             "Palette2",
#             TCoord(0.0, 0.0, Trc(1, 1)),
#             THeight(1.0, 1),
#             Right,
#             true,
#             true,
#         ),
#     )

#     testcalctx = AStarCalculationContext(testctx)
#     path_a_b_2D(testtask1, testcalctx)

#     testtask2 = TTask(
#         "TASK2",
#         TLocation(
#             "Palette3",
#             TCoord(0.0, 0.0, Trc(4, 4)),
#             THeight(5.0, 5),
#             Right,
#             true,
#             true,
#         ),
#         TLocation(
#             "Palette4",
#             TCoord(0.0, 0.0, Trc(2, 2)),
#             THeight(9.0, 9),
#             Right,
#             true,
#             true,
#         ),
#     )




# #end

# #@testset "Minimum path" begin
#     testAGV1 = TAGV(
#         "AGV1",
#         TCoord(0.0, 0.0, Trc(1, 1)),
#         Right,
#         TTime(1.0, 1),
#         THeight(0.0, 0),
#         false,
#         true,
#         [],
#         TLocation(),
#     )

#     testAGV2 = TAGV(
#         "AGV2",
#         TCoord(0.0, 0.0, Trc(5, 5)),
#         Left,
#         TTime(1.0, 1),
#         THeight(0.0, 0),
#         false,
#         true,
#         [],
#         TLocation(),
#     )

#     TESTAGVS = [testAGV1, testAGV2]
#     testplans = initialise_plans(TESTAGVS)

#     testtask1 = TTask(
#         "TASK1",
#         TLocation(
#             "Palette1",
#             TCoord(0.0, 0.0, Trc(3, 2)),
#             THeight(1.0, 1),
#             Left,
#             true,
#             true,
#         ),
#         TLocation(
#             "Palette2",
#             TCoord(0.0, 0.0, Trc(3, 4)),
#             THeight(1.0, 1),
#             Left,
#             true,
#             true,
#         ),
#     )

#     testtask2 = TTask(
#         "TASK2",
#         TLocation(
#             "Palette3",
#             TCoord(0.0, 0.0, Trc(4, 4)),
#             THeight(5.0, 5),
#             Right,
#             true,
#             true,
#         ),
#         TLocation(
#             "Palette4",
#             TCoord(0.0, 0.0, Trc(2, 2)),
#             THeight(9.0, 9),
#             Right,
#             true,
#             true,
#         ),
#     )

#     testcalctx = AStarCalculationContext(testctx)
#     testoptimaltimes = [task_optimal_perf(t, testcalctx) for t ∈ [testtask1, testtask2]]

#     # No path can be found because facing 2, 2, R or 4, 4, R is not allowed (wall ≠ parking)
#     @test testoptimaltimes == [131, 1000000000]

#end
