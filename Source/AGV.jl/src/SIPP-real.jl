#############################################################################
#
# FULL EXAMPLE
#
module_dir = "/home/emmanuel/Documents/Work/Alba/AGV/_gits/AGV.jl/"
module_img_dir = module_dir * "img/"
module_src_dir = module_dir * "src/"
cd(module_dir)

# using Revise, TickTock, FileIO, JLD2, Logging, Printf
# using Profile, PProf, BenchmarkTools
# using Distributions, LightGraphs, SimpleWeightedGraphs, SparseArrays

using Pkg
Pkg.activate(".")
using AGV

# using Debugger
# break_on(:error)

###############################################################################
#
# PLAN SPECIFIC -           REALISTIC
#
####
realPlan =
    TLOCATION_FILL.(
        [
            # . . .   . . . . 1 . . . . 1 . . . . 2 . . . . 2 . . . . 3 . . . . 3 . . . . 4 . . . . 4
            # . . . 5 . . . . 0 . . . . 5 . . . . 0 . . . . 5 . . . . 0 . . . . 5 . . . . 0 . . . . 5
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1     # 1
            1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 1 1
            1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
            1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1     # 5
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1     # 10
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1     # 15
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1     # 20
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1     # 25
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1     # 30
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1     # 35
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1     # 40
            1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 1
            1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
            1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 1     # 45
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1     # 50
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1     # 55
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1     # 60
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1     # 65
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1     # 70
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1     # 75
            1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 1
            1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1     # 80
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1     # 85
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 1 1 1 1 1 1 1
            1 1 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 0 7 1 1 1 1 1     # 90
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 0 7 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 1 1 1 1 1 1 1     # 95
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
            # . . .   . . . . 1 . . . . 1 . . . . 2 . . . . 2 . . . . 3 . . . . 3 . . . . 4 . . . . 4
            # . . . 5 . . . . 0 . . . . 5 . . . . 0 . . . . 5 . . . . 0 . . . . 5 . . . . 0 . . . . 5
        ],
    );


nSteps = 350
depthLimit = TIME_MULTIPLIER * nSteps


# If not done
ctx = with_logger(AGVLogger(open(module_src_dir * "AGV_log.txt", "w+"), Logging.Info)) do
    TContext(realPlan, nSteps, depthLimit)
end;
path_c_2_graphic(Trcd[], ctx; flip = false)
path_c_2_graphic(Trcd[], ctx; flip = true)

# Describe special locations
list_conveyors = [(83, 7, Right), (85, 7, Right), (87, 7, Right)]
list_conveyors_locations = [(r, c) for (r, c, _) ∈ list_conveyors]

list_quays = [(81, 23, Down)]
list_quays_locations = [(r, c) for (r, c, _) ∈ list_quays]

list_backs = [(2, c, Up) for c ∈ 2:2:42]
list_backs_locations = [(r, c) for (r, c, _) ∈ list_backs]

list_ground = [
    (i, j, find_side_to_face(i, j, ctx)) for
    i ∈ 1:ctx.nRow, j ∈ 5:5:ctx.nCol if ctx.plan[i, j] == LOC_PALETTE
]
list_ground_locations = [(r, c) for (r, c, _) ∈ list_ground]

list_parkings = [
    (i, j, find_side_to_face(i, j, ctx)) for
    i ∈ 1:ctx.nRow, j ∈ 1:ctx.nCol if ctx.plan[i, j] ∈
    [LOC_PARKING_UP, LOC_PARKING_RIGHT, LOC_PARKING_DOWN, LOC_PARKING_LEFT]
]


list_racks = [
    (i, j, find_side_to_face(i, j, ctx)) for
    i ∈ 1:ctx.nRow, j ∈ 1:ctx.nCol if ctx.plan[i, j] == LOC_PALETTE &&
    (i, j) ∉ list_backs_locations &&
    (i, j) ∉ list_ground_locations
]

ctx.special_locations["conveyor"] =
    [TLocation("CONV", r, c, d) for (r, c, d) ∈ list_conveyors]
ctx.special_locations["quay"] = [TLocation("QUAY", r, c, d) for (r, c, d) ∈ list_quays]
ctx.special_locations["back"] = [TLocation("BACK", r, c, d) for (r, c, d) ∈ list_backs]
ctx.special_locations["ground"] = [TLocation("GRND", r, c, d) for (r, c, d) ∈ list_ground]
ctx.special_locations["parking"] =
    [TLocation("PARK", r, c, d) for (r, c, d) ∈ list_parkings]
ctx.special_locations["rack"] = [TLocation("RACK", r, c, d) for (r, c, d) ∈ list_racks]


src1_rc = Trc(33, 28);
src1_dir = Down;
src1_t = 1;
src1_rcd = as_rcd(src1_rc, src1_dir)
src1_rcdt = as_rcdt(src1_rc, src1_dir, src1_t)
src1_r, src1_c, src1_d = unpack(src1_rcd)

dst1_rc = Trc(36, 3);
dst1_dir = Up;
dst1_rcd = as_rcd(dst1_rc, dst1_dir)
dst1_r, dst1_c, dst1_d = unpack(dst1_rcd)


time_shift = 0

# Empty
list_allocation_paths = [Trcdt[]]

# Moving non-blocking
list_allocation_paths = [[Trcdt(25, 3, 3, 10), Trcdt(45, 3, 3, 30)]]

# Moving blocking
list_allocation_paths = [[Trcdt(42, 12, 1, 1), Trcdt(42, 12, 1, 200)]]

# list_allocation_paths = [[Trcdt(4, 2, 3, 10), Trcdt(5, 2, 3, 11), Trcdt(5, 2, 4, 26), Trcdt(5, 1, 4, 27)]]
sippctx = SIPPCalculationContext(ctx)
sippctx.occupancy = fill_blockages!(time_shift, list_allocation_paths, sippctx)


# Test anytime_SIPP
@time result_paths = with_logger(
    AGVLogger(open(module_src_dir * "AGV_log.txt", "w+"), Logging.LogLevel(-10_000)),
) do
    anytime_SIPP(src1_rcd, dst1_rcd, 50.0, 0.9, time_shift, list_allocation_paths, sippctx)
end


length(result_paths)
length(result_paths[1])
length(result_paths[1][1])
length(result_paths[1][2])

length(result_paths[2])
length(result_paths[2][1])
length(result_paths[2][2])



for i ∈ 1:length(result_paths)
    # println(result_paths[1][i])
    result_paths_rcd = [p[1] for p ∈ result_paths[i][1]]
    isempty(result_paths_rcd) ||
        path_c_2_graphic(result_paths_rcd, sippctx.ctx; flip = true)
end


result_paths[1][1]
result_paths[1][2]

result_paths_full = [as_rcdt(p[1], p[2]) for p ∈ result_paths[1][1]]
result_paths_full = [p for p ∈ result_paths[2][1]]

result_paths_full = [as_rcdt(p[1], p[2]) for p ∈ result_paths[end][1]]


# Same thing with path_a_b_3D
@time result_paths, _, _ = with_logger(
    AGVLogger(open(module_src_dir * "AGV_log.txt", "w+"), Logging.LogLevel(-10_000)),
) do
    path_a_b_3D(src1_rcd, dst1_rcd, time_shift, list_allocation_paths, sippctx)
end

# We only received the last and best bath as Trcdt[]
length(result_paths)


result_paths_rcd = [as_rcd(p) for p ∈ result_paths]
isempty(result_paths_rcd) || path_c_2_graphic(result_paths_rcd, sippctx.ctx; flip = true)




###############################################################################
#
# ALLOCATION TEST
#
####

# AGVs all located in parkings at the bottom right facing right / left.

AGV1 = TAGV(
    "AGV1",
    TCoord(0.0, 0.0, Trc(84, 34)),
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
    TCoord(0.0, 0.0, Trc(86, 34)),
    Right,
    TTime(1.0, 1),
    THeight(0.0, 0),
    false,
    true,
    [],
    TLocation(),
)


AGV3 = TAGV(
    "AGV3",
    TCoord(0.0, 0.0, Trc(90, 40)),
    Left,
    TTime(1.0, 1),
    THeight(0.0, 0),
    false,
    true,
    [],
    TLocation(),
)

AGV4 = TAGV(
    "AGV4",
    TCoord(0.0, 0.0, Trc(92, 40)),
    Left,
    TTime(1.0, 1),
    THeight(0.0, 0),
    false,
    true,
    [],
    TLocation(),
)

AGV5 = TAGV(
    "AGV5",
    TCoord(0.0, 0.0, Trc(88, 34)),
    Right,
    TTime(1.0, 1),
    THeight(0.0, 0),
    false,
    true,
    [],
    TLocation(),
)


task1 = TTask(
    "TASK1",                                # ID
    TLocation(                              # FROM
        "Palette1",                         # ID
        TCoord(0.0, 0.0, Trc(6, 8)),        # Where
        THeight(5.0, 5),                    # Height
        Right,                              # Side to face
        true,
        true,
    ),
    TLocation(                              # TO
        "Palette2",                         # ID
        TCoord(0.0, 0.0, Trc(92, 39)),      # Where
        THeight(1.0, 1),                    # Height
        Right,                              # Side to face
        true,
        true,                               # is full?
    ),
)
task2 = TTask(
    "TASK2",
    TLocation(
        "Palette3",
        TCoord(0.0, 0.0, Trc(92, 39)),
        THeight(3.0, 3),
        Right,
        true,
        true,
    ),
    TLocation("Palette4", TCoord(0.0, 0.0, Trc(6, 8)), THeight(3.0, 3), Right, true, true),
)

task3 = TTask(
    "TASK3",
    TLocation("Palette5", TCoord(0.0, 0.0, Trc(3, 10)), THeight(5.0, 5), Up, true, true),
    TLocation("Palette6", TCoord(0.0, 0.0, Trc(68, 28)), THeight(9.0, 9), Left, true, true),
)

task4 = TTask(
    "TASK4",
    TLocation("Palette7", TCoord(0.0, 0.0, Trc(3, 10)), THeight(7.0, 7), Up, true, true),
    TLocation("Palette8", TCoord(0.0, 0.0, Trc(30, 53)), THeight(6.0, 6), Left, true, true),
)

task5 = TTask(
    "TASK5",
    TLocation("Palette9", TCoord(0.0, 0.0, Trc(2, 94)), THeight(0.0, 0), Right, true, true),
    TLocation("Quay", TCoord(0.0, 0.0, Trc(23, 17)), THeight(0.0, 0), Left, true, true),
)

task6 = TTask(
    "TASK6",
    TLocation(
        "Palette11",
        TCoord(0.0, 0.0, Trc(43, 91)),
        THeight(1.0, 1),
        Down,
        true,
        true,
    ),
    TLocation("Quay", TCoord(0.0, 0.0, Trc(23, 17)), THeight(0.0, 0), Left, true, true),
)


LIST_AGVS = [AGV1, AGV2, AGV3]
LIST_TASKS = [task1, task2, task3]

# LIST_AGVS  = [AGV1, AGV2, AGV3, AGV4, AGV5]
# LIST_TASKS = [task1, task2, task3, task4, task5, task6]

# Should be uturn
calctx = SIPPCalculationContext(ctx)
calctx.occupancy = fill_blockages!(time_shift, list_allocation_paths, sippctx)

##########################################################################################33
#
# AGV1 to Parking 1
#
p = ctx.special_locations["parking"][1]
p.loc
p.loc.s
p.sideToFace
c2v_rcd(p.loc.s, p.sideToFace, calctx)
AGV1.loc.s
AGV1.dir
calctx = SIPPCalculationContext(ctx)
calctx.occupancy = fill_blockages!(time_shift, list_allocation_paths, sippctx)
pth = path_a_b_2D(AGV1, p, calctx)
path_c_2_graphic(pth[1], calctx.ctx)

p = ctx.special_locations["parking"][2]
p.loc.s
p.sideToFace
c2v_rcd(p.loc.s, p.sideToFace, calctx)
pth = path_a_b_2D(AGV1, p, calctx)
path_c_2_graphic(pth[1], calctx.ctx)


##########################################################################################33
#
# Checking tasks paths
#

##############################################
# TASK 1
p1 = task1.start
p1.loc.s
p1.sideToFace
c2v_rcd(p1.loc.s, p1.sideToFace, calctx)

p2 = task1.target
p2.loc.s
p2.sideToFace
c2v_rcd(p2.loc.s, p2.sideToFace, calctx)

path = path_a_b_2D(p1, p2, calctx)
path[1] # Coordinates
path[2] # Times
path[3] # Costs
path_c_2_graphic(path[1], calctx.ctx)

task_optimal_perf(task1, calctx)


##############################################
# TASK 2
p1 = task2.start
p1.loc.s
p1.sideToFace
c2v_rcd(p1.loc.s, p1.sideToFace, calctx)

p2 = task2.target
p2.loc.s
p2.sideToFace
c2v_rcd(p2.loc.s, p2.sideToFace, calctx)

path = path_a_b_2D(p1, p2, calctx)
path[1] # Coordinates
path[2] # Times
path[3] # Costs
path_c_2_graphic(path[1], calctx.ctx)


##############################################
# TASK 3
p1 = task3.start
p1.loc.s
p1.sideToFace
c2v_rcd(p1.loc.s, p1.sideToFace, calctx)

p2 = task3.target
p2.loc.s
p2.sideToFace
c2v_rcd(p2.loc.s, p2.sideToFace, calctx)

path = path_a_b_2D(p1, p2, calctx)
path[1] # Coordinates
path[2] # Times
path[3] # Costs
path_c_2_graphic(path[1], calctx.ctx)



##############################################
##############################################
##############################################

[task_optimal_perf(t, calctx) for t ∈ LIST_TASKS]


AGVs_plans = initialise_plans(LIST_AGVS)

initialise_parkings!(LIST_AGVS, AGVs_plans, calctx)


Logging.disable_logging(Logging.Debug)
with_logger(
    AGVLogger(open(module_src_dir * "AGV_log.txt", "a+"), Logging.LogLevel(-10_000)),
) do
    initialise_parkings!(LIST_AGVS, AGVs_plans, calctx)
end;

# The AGV should do an initial U-turn? CHECK
generate_moves(CartesianIndex(94, 38, 1), ctx)
generate_moves(CartesianIndex(94, 38, 2), ctx)
generate_moves(CartesianIndex(94, 38, 3), ctx)
generate_moves(CartesianIndex(94, 38, 4), ctx)


AGVs_plans[1].path_to_park

AGVs_plans[1].parking
AGVs_plans[1].time_at_parking
path_c_2_graphic(AGVs_plans[1].path_to_park, calctx.ctx)

AGVs_plans[2].parking
AGVs_plans[2].time_at_parking
path_c_2_graphic(AGVs_plans[2].path_to_park, ctx)

AGVs_plans[3].parking
AGVs_plans[3].time_at_parking
path_c_2_graphic(AGVs_plans[3].path_to_park, ctx)

# USING LIST OF TASKS
#
planning =
    with_logger(AGVLogger(open(module_src_dir * "AGV_log.txt", "a+"), Logging.Info)) do
        full_allocation(
            LIST_AGVS,
            20,
            ctx;
            use_fixed_tasks = LIST_TASKS,
            algo = AnytimeSIPP(),
        )
    end;



describe_planning(planning)












latest_move = maximum([p.steps[end].path[end][4] for p ∈ planning])
p_per_h = 6 * 3600 / latest_move


# 10 random tasks
#
using PProf
Profile.clear()
Profile.init(delay = 0.001)

FI = copy_context(ctx)
planning_10 =
    with_logger(AGVLogger(open(module_src_dir * "AGV_log_10.txt", "w+"), Logging.Debug)) do
        full_allocation(LIST_AGVS, 10, FI; queue_size = 10)
    end

describe_planning(planning_10)
list_nonsingle_step_changes(planning_10[1])
list_nonsingle_step_changes(planning_10[2])
list_nonsingle_step_changes(planning_10[3])
list_nonsingle_step_changes(planning_10[4])
list_nonsingle_step_changes(planning_10[5])

latest_move = maximum([p.steps[end].path[end][4] for p ∈ planning_10])
p_per_h = 10 * 3600 / latest_move
latest_parking =
    maximum([p.path_to_park[end][4] for p ∈ planning_10 if !isempty(p.path_to_park)])

open(module_img_dir * "plan_printout_10.txt", "w+") do io
    for i ∈ 1:max(latest_move, latest_parking)
        render_plan_at_time(io, planning_10, i, ctx; flip = true)
        print(io, "\f")
    end
end

for i ∈ 1:latest_parking
    io = open(module_img_dir * "p10/planning_10_" * @sprintf("%04d", i) * ".txt", "w")
    render_plan_at_time(io, planning_10, i, ctx; flip = true)
    close(io)
end


# 20 random tasks
#
Profile.clear()
Profile.init(n = 1^8, delay = 0.01)

FI = copy_context(ctx)
planning_20 =
    with_logger(AGVLogger(open(module_src_dir * "AGV_log_20.txt", "w+"), Logging.Debug)) do
        full_allocation(LIST_AGVS, 20, FI; queue_size = 20)
    end

describe_planning(planning_20)
list_nonsingle_step_changes(planning_20[1])
list_nonsingle_step_changes(planning_20[2])
list_nonsingle_step_changes(planning_20[3])
list_nonsingle_step_changes(planning_20[4])
list_nonsingle_step_changes(planning_20[5])

latest_move = maximum([p.steps[end].path[end][4] for p ∈ planning_20])
p_per_h = 20 * 3600 / latest_move
latest_parking =
    maximum([p.path_to_park[end][4] for p ∈ planning_20 if !isempty(p.path_to_park)])

open(module_img_dir * "plan_printout_20.txt", "w+") do io
    for i ∈ 1:max(latest_move, latest_parking)
        render_plan_at_time(io, planning_20, i, ctx; flip = true)
        print(io, "\f")
    end
end


for i ∈ 1:latest_move
    io = open(module_img_dir * "p20/planning_20_" * @sprintf("%04d", i) * ".txt", "w")
    render_plan_at_time(io, planning_20, i, ctx; flip = true)
    close(io)
end


# 100 random tasks
#
FI = copy_context(ctx)
planning_100 =
    with_logger(AGVLogger(open(module_src_dir * "AGV_log_100.txt", "w+"), Logging.Debug)) do
        full_allocation(LIST_AGVS, 100, FI; queue_size = 15)
    end

describe_planning(planning_100)
list_nonsingle_step_changes(planning_100[1])
list_nonsingle_step_changes(planning_100[2])
list_nonsingle_step_changes(planning_100[3])
list_nonsingle_step_changes(planning_100[4])
list_nonsingle_step_changes(planning_100[5])

latest_move = maximum([p.steps[end].path[end][4] for p ∈ planning_100 if !isempty(p.steps)])
p_per_h = 100 * 3600 / latest_move
latest_parking =
    maximum([p.path_to_park[end][4] for p ∈ planning_100 if !isempty(p.path_to_park)])

open(module_img_dir * "plan_printout_100.txt", "w+") do io
    for i ∈ 1:2800
        render_plan_at_time(io, planning_100, i, ctx; flip = true)
        print(io, "\f")
    end
end


for a ∈ 1:5
    for i ∈ 1:length(planning_100[a].steps)
        println("AGV $(a) Step: $(i), = $(check_path(planning_100[a].steps[i].path, ctx))")
    end
end





planning[3].steps[7]


planning[1].steps
path_c_2_graphic(planning[1].steps[1].path, FI)
path_c_2_graphic(planning[1].steps[2].path, FI)
path_c_2_graphic(planning[1].steps[3].path, FI)
path_c_2_graphic(planning[1].steps[4].path, FI)
path_c_2_graphic(planning[1].path_to_park, FI)
planning[1].steps[end].path[end][4]

planning[2].steps
path_c_2_graphic(planning[2].steps[1].path, FI)
path_c_2_graphic(planning[2].steps[2].path, FI)
path_c_2_graphic(planning[2].steps[3].path, FI)
path_c_2_graphic(planning[2].steps[4].path, FI)
path_c_2_graphic(planning[2].steps[5].path, FI)
path_c_2_graphic(planning[2].path_to_park, FI)
planning[2].steps[end].path[end][4]

planning[3].steps
path_c_2_graphic(planning[3].steps[1].path, FI)
path_c_2_graphic(planning[3].steps[2].path, FI)
path_c_2_graphic(planning[3].steps[3].path, FI)
path_c_2_graphic(planning[3].steps[4].path, FI)
path_c_2_graphic(planning[3].steps[5].path, FI)
path_c_2_graphic(planning[3].steps[6].path, FI)
path_c_2_graphic(planning[3].steps[7].path, FI)
path_c_2_graphic(planning[3].path_to_park, FI)
planning[3].steps[end].path[end][4]

planning[4].steps
path_c_2_graphic(planning[4].steps[1].path, FI)
path_c_2_graphic(planning[4].steps[2].path, FI)
path_c_2_graphic(planning[4].steps[3].path, FI)
path_c_2_graphic(planning[4].path_to_park, FI)
planning[4].steps[end].path[end][4]

planning[5].steps
path_c_2_graphic(planning[5].steps[1].path, FI)
path_c_2_graphic(planning[5].steps[2].path, FI)
path_c_2_graphic(planning[5].steps[3].path, FI)
path_c_2_graphic(planning[5].path_to_park, FI)
planning[5].steps[end].path[end][4]



open(module_img_dir * "plan_printout.txt", "w") do io
    for i ∈ 1:latest_move
        render_plan_at_time(io, planning, i, ctx)
    end
end

# convert -size 360x360 xc:white -font "FreeMono" -pointsize 12 -fill black -draw @ascii.txt image.png



































using PProf
Profile.clear()
Profile.init(delay = 0.001)

result_paths, dest = @profile anytime_SIPP(
    src1_rcd,
    dst1_rcd,
    50.0,
    1.0,
    time_shift,
    list_allocation_paths,
    sippctx,
)

pprof()
