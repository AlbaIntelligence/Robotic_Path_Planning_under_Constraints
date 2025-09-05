module_dir = "/home/emmanuel/Documents/Work/Alba/AGV/_gits/AGV.jl/"
module_img_dir = module_dir * "img/"
module_src_dir = module_dir * "src/"
cd(module_dir)

import Pkg;
Pkg.activate(".");

using LightGraphs, SimpleWeightedGraphs, Test
using AGV

@testset "All tests" begin

    include("basic_tests.jl")

    include("paths_tests.jl")
    include("paths_2D_tests.jl")
    include("paths_AStar_tests.jl")
    include("SIPP_intervals_tests.jl")
    include("paths_SIPP_tests.jl")

    include("other_tests.jl")
end
