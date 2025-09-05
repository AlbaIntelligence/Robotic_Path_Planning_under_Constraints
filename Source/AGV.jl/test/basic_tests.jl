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
    2 0 2 0 1
    5 0 1 0 7
    2 0 1 0 2
    0 0 0 0 0
])

teststeps = 400
testdepth = TIME_MULTIPLIER * 400

testcontext = TContext(testplan, teststeps, testdepth)

testparkings = [
    (i, j, find_side_to_face(i, j, testcontext)) for
    i ∈ 1:testcontext.nRow, j ∈ 1:testcontext.nCol if testcontext.plan[i, j] ∈
    [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
]
testcontext.special_locations["parking"] =
    [TLocation("PARK", r, c, d) for (r, c, d) ∈ testparkings]

testslice = testcontext.nRow * testcontext.nCol * nDirection
testvertices = testslice * teststeps


src1_r = 1
src1_c = 1
src1_d = Right
src1_t = 1
src1_rc = Trc(src1_r, src1_c)
src1_rcd = Trcd(src1_r, src1_c, Int64(src1_d))
src1_rcdt = Trcdt(src1_r, src1_c, Int64(src1_d), src1_t)
src1_rcdt_v = c2v_rcdt(src1_rcdt, testcontext)

dst0_r = 5
dst0_c = 2
dst0_d = Left
dst0_rc = Trc(dst0_r, dst0_c)
dst0_rcd = Trcd(dst0_r, dst0_c, Int64(dst0_d))
dst0_rcd_v = c2v_rcd(dst0_rcd, testcontext)
dst0_rcdt = Trcdt(dst0_r, dst0_c, Int64(dst0_d), 1)
dst0_rcdt_v = c2v_rcdt(dst0_rcdt, testcontext)

dst1_r = 5
dst1_c = 1
dst1_d = Left
dst1_rc = Trc(dst1_r, dst1_c)
dst1_rcd = Trcd(dst1_r, dst1_c, Int64(dst1_d))
dst1_rcd_v = c2v_rcd(dst1_rcd, testcontext)
dst1_rcdt = Trcdt(dst1_r, dst1_c, Int64(dst1_d), 2)
dst1_rcdt_v = c2v_rcdt(dst1_rcdt, testcontext)

src2_rc = Trc(4, 4);
src2_d = Down;
src2_t = 1;
dst2_rc = Trc(1, 3);
dst2_t = Right;



AGV1 = TAGV(
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

AGV2 = TAGV(
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

testtask1 = TTask(
    "TASK1",
    TLocation("Palette1", TCoord(0.0, 0.0, Trc(3, 2)), THeight(1.0, 1), Left, true, true),
    TLocation("Palette2", TCoord(0.0, 0.0, Trc(3, 4)), THeight(1.0, 1), Left, true, true),
)

testtask2 = TTask(
    "TASK2",
    TLocation("Palette3", TCoord(0.0, 0.0, Trc(4, 4)), THeight(5.0, 5), Left, true, true),
    TLocation("Palette4", TCoord(0.0, 0.0, Trc(2, 2)), THeight(9.0, 9), Right, true, true),
)

TESTAGVS = [AGV1, AGV2]
TESTTASKS = [testtask1, testtask2]



@testset "Vertex_Generation" begin
    @test c2v_rc(src1_rc, testcontext) == 1
    @test c2v_rcd(src1_rcd, testcontext) == 26
    @test c2v_rcdt(src1_rcdt, testcontext) == 26

    @test c2v_rc(dst0_rc, testcontext) == 10
    @test c2v_rcd(dst0_rcd, testcontext) == 85

    @test c2v_rc(dst1_rc, testcontext) == 5
    @test c2v_rcd(dst1_rcd, testcontext) == 80

    @test c2v_rc(src2_rc, testcontext) == 19
    @test c2v_rc(dst2_rc, testcontext) == 11
end


@testset "Move_Generation" begin

    @test testslice == size(testplan)[1] * size(testplan)[2] * 4

    turns = [m.dest for m ∈ AGV.check_and_add_turns(src1_r, src1_c, src1_d, testcontext)]
    turns_rc = [Trc(r, c) for (r, c, _, _) ∈ unpack.(turns)]
    turns_rcd = [Trcd(r, c, d) for (r, c, d, _) ∈ unpack.(turns)]
    @test CartesianIndex(1, 1) ∈ turns_rc
    @test CartesianIndex(1, 2) ∉ turns_rc
    @test CartesianIndex(2, 1) ∉ turns_rc

    @test CartesianIndex(1, 1, 2) ∈ turns_rcd
    @test CartesianIndex(1, 1, 3) ∈ turns_rcd
    @test CartesianIndex(1, 1, 1) ∉ turns_rcd
    @test CartesianIndex(1, 1, 4) ∉ turns_rcd


    moves =
        [m.dest for m ∈ AGV.check_and_add_moves(src1_r, src1_c, 0, 1, src1_d, testcontext)]
    moves_rc = [Trc(r, c) for (r, c, _, _) ∈ unpack.(moves)]
    moves_rcd = [Trcd(r, c, d) for (r, c, d, _) ∈ unpack.(moves)]
    @test CartesianIndex(1, 2, 2) ∈ moves_rcd
    @test CartesianIndex(1, 2, 1) ∉ moves_rcd
    @test CartesianIndex(1, 2, 3) ∉ moves_rcd

    @test AGV.check_and_add_moves(src1_r, src1_c, 0, 0, src1_d, testcontext) == Any[]
    @test AGV.check_and_add_moves(src1_r, src1_c, -1, 0, src1_d, testcontext) == Any[]
    @test AGV.check_and_add_moves(src1_r, src1_c, 1, 0, src1_d, testcontext) == Any[]
    @test AGV.check_and_add_moves(src1_r, src1_c, 0, -1, src1_d, testcontext) == Any[]


    moves = [m.dest for m ∈ AGV.generate_moves(src1_rcd, testcontext)]
    moves_rc = [Trc(r, c) for (r, c, _, _) ∈ unpack.(moves)]
    moves_rcd = [Trcd(r, c, d) for (r, c, d, _) ∈ unpack.(moves)]
    @test CartesianIndex(1, 1, 2) ∈ moves_rcd
    @test CartesianIndex(1, 1, 3) ∈ moves_rcd
    @test CartesianIndex(1, 2, 2) ∈ moves_rcd
    @test length(moves) == 3

    moves = [m.dest for m ∈ AGV.generate_moves(dst0_rcd, testcontext)]
    moves_rc = [Trc(r, c) for (r, c, _, _) ∈ unpack.(moves)]
    moves_rcd = [Trcd(r, c, d) for (r, c, d, _) ∈ unpack.(moves)]
    @test CartesianIndex(5, 1, 4) ∈ moves_rcd
end


@testset "Graph_Generation" begin
    ug = testcontext.UG3D
    dg = testcontext.G3DT

    @test size(ug)[1] == size(ug)[2] == testvertices
    @test size(dg)[1] == size(dg)[2] == testvertices

    @test LightGraphs.weights(dg)[dst0_rcdt_v, dst1_rcdt_v] == 0
    @test LightGraphs.weights(dg)[dst1_rcdt_v, dst0_rcdt_v] == 1_000
    @test LightGraphs.weights(ug)[dst0_rcdt_v, dst1_rcdt_v] == 1
    @test LightGraphs.weights(ug)[dst1_rcdt_v, dst0_rcdt_v] == 1
end


@testset "Collisions" begin
    ug = testcontext.UG3D
    dg = testcontext.G3DT

    testplanning = full_allocation(
        TESTAGVS,
        20,
        testcontext;
        use_fixed_tasks = TESTTASKS,
        algo = A_Star(),
    )
    testcalctx = AStarCalculationContext(testcontext)

    initialise_parkings!(TESTAGVS, testplanning, testcalctx)
    path_a_b_2D(testtask1.start, testtask1.target, testcalctx)
    path_a_b_2D(testtask2.start, testtask2.target, testcalctx)

    path_vertices(testcontext.G2DT, Trc(4, 4), Left, Trc(2, 2), Right, testcalctx)
    path_vertices(testcontext.G2DT, Trc(2, 2), Right, Trc(4, 4), Left, testcalctx)
end
