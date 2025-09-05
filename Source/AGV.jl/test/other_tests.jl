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
end
