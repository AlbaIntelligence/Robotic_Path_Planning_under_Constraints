#############################################################################
#
# FULL EXAMPLE
#
module_dir = "/home/emmanuel/Documents/Work/Alba/AGV/"
module_img_dir = module_dir * "_gits/AGV.jl/img/"
module_src_dir = module_dir * "_gits/AGV.jl/src/"
cd(module_dir)

using Revise, TickTock, FileIO, JLD2, Logging, Printf
using Profile, PProf
using Distributions, LightGraphs, SimpleWeightedGraphs, SparseArrays
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
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
            1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 1 1
            1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
            1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 1
            1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
            1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1 1 2 0 2 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 2 1 1 0 1 1
            1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
            1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1
            1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 1 1 1 1 1 1 1
            1 1 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 0 7 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 0 7 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 5 0 0 1 0 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
        ],
    )


nSteps = Int32(350)
depthLimit = Int32(TIME_MULTIPLIER * 350)

# If not done
ctx = with_logger(AGVLogger(open(module_src_dir * "AGV_log.txt", "w+"), Logging.Debug)) do
    TContext(realPlan, nSteps, depthLimit)
end
path_c_2_graphic(Trcd[], ctx; flip = false)

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


@save (dirname(@__FILE__) * "/../data/realFloor.jld2") realctx = realctx

@load (dirname(@__FILE__) * "../data/realFloor.jld2") realctx

ctx_backup = deepcopy(ctx)


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

l1 = TCoord(Float64(dst1_rc[1]), Float64(dst1_rc[2]), dst1_rc)
h1 = THeight(0.0, 0)
palette1 = TLocation("", l1, h1, dst1_dir, true, false)



src2_rc = Trc(36, 13);
src2_dir = Up;
src2_t = 1;
src2_rcd = as_rcd(src2_rc, src2_dir)
src2_rcdt = as_rcdt(src2_rc, src2_dir, src2_t)
src2_r, src2_c, src2_d = unpack(src2_rcd)

dst2_rc = Trc(3, 30);
dst2_dir = Right;
dst2_rcd = as_rcd(dst2_rc, dst2_dir)
dst2_r, dst2_c, dst2_d = unpack(dst2_rcd)

l2 = TCoord(Float64(dst2_rc[1]), Float64(dst2_rc[2]), dst2_rc)
h2 = THeight(0.0, 0)
palette2 = TLocation("", l2, h2, dst2_dir, true, false)


#####################
# 2D Paths
calctx = TCalculationContext(ctx)
path_a_b_2D(src1_rc, src1_dir, dst1_rc, dst1_dir, calctx, ctx)
path_a_b_2D(Trc(83, 6), Right, Trc(39, 8), Left, calctx, ctx)


#####################
# PATH 1: ACTUAL CHECK

FI1 = copy_context(ctx);
nothing;
src1_v = c2v_rcdt(src1_rcdt, FI1)
dst1_v = c2v_rcdt(Trcdt(dst1_r, dst1_c, dst1_d, depthLimit - 1), FI1)

FI1.plan[1, 1]
FI1.plan[src1_r, src1_c]
FI1.plan[src1_r, src1_c+1]
FI1.plan[src1_r, src1_c+2]
FI1.plan[src1_r+1, src1_c]
FI1.plan[src1_r+2, src1_c]
FI1.plan[src1_r-1, src1_c]
FI1.plan[src1_r-2, src1_c]

FI1.plan[dst1_r, dst1_c]
FI1.plan[dst1_r-1, dst1_c]

gm = generate_moves(src1_rcd, FI1)
gm = generate_moves(dst1_rcd, FI1)


generate_moves(CartesianIndex(3, 40, 1), FI1)


# DO NOT USE on BIG with 10_000. No depth limit
FI1 = copy_context(ctx)

tick();
av, aw = path_vertices!(FI1.G3DT, src1_v, dst1_v, calculationctx);
tock();
length(av)

ac = [v2c_rcdt(v, FI1) for v ∈ av]
ac_rc = [(c[1], c[2]) for c ∈ ac]
ac_rcd = [Trcd(c[1], c[2], c[3]) for c ∈ ac]
path_c_2_graphic(ac_rcd, FI1)


tick();
pc1, pv1, t1 = path_a_b_3D(src1_rcd, dst1_rcd, 1, TPath_rcdt[], calculationctx, FI1);
tock();
length(pc1)
path_c_2_graphic(pc1, FI1)



#####################
# Path 2

FI2 = copy_context(ctx)

src2_v = c2v_rcdt(src2_rcdt, FI2)
dst2_v = c2v_rcdt(Trcdt(dst2_r, dst2_c, dst2_d, depthLimit - 1), FI2)

tick();
av, aw = path_vertices!(FI2.G3DT, src2_v, dst2_v, calculationctx);
tock();
length(av);

ac = [v2c_rcdt(v, FI2) for v ∈ av]
ac_rc = [(c[1], c[2]) for c ∈ ac]
ac_rcd = [Trcd(c[1], c[2], c[3]) for c ∈ ac]
fc = findfirst(isequal((dst2_r, dst2_c)), ac_rc)
path_c_2_graphic(ac_rcd, FI2)


tick();
pc2, pv2, t2 = path_a_b_3D(src2_rcd, dst2_rcd, 1, TPath_rcdt[], calculationctx, FI2);
tock();
length(pc2)
path_c_2_graphic(pc2, FI2)



#####################
# PATH 2: ACTUAL CHECK - ALONE

FI2 = copy_context(ctx);
nothing;

src2_v = c2v_rcdt(src2_rcdt, FI2)
dst2_v = c2v_rcdt(as_rcdt(dst2_rcd, nSteps - 1), FI2)

tick();
pc2, pv2, t2 = path_a_b_3D(src2_rcd, dst2_rcd, 1, TPath_rcdt[], calculationctx, FI2);
tock();
length(pc2);
path_c_2_graphic(pc2, FI2)

# check warp travel reversed
sliceSize = ctx.nRow * ctx.nCol * nDirection
nVertices = ctx.nRow * ctx.nCol * nDirection * nSteps

example_dst2_v = c2v_rcdt(as_rcdt(dst2_rcd, 200), FI2)
example_dst2_v + sliceSize
all_neighbors(FI1.UG3D, example_dst2_v)
example_dst2_v in all_neighbors(FI1.UG3D, example_dst2_v + sliceSize)

all_neighbors(FI1.UG3D, example_dst2_v + sliceSize)
example_dst2_v + sliceSize in all_neighbors(FI1.UG3D, example_dst2_v)

weights(FI2.G3DT)[example_dst2_v, example_dst2_v+sliceSize]
weights(FI2.G3DT)[example_dst2_v+sliceSize, example_dst2_v]


#####################
# PATH 2: ACTUAL CHECK - WITH INSERTION OF THE OTHER PATH

FI12 = copy_context(ctx);
nothing;

tick();
pc12, pv12, t12 = path_a_b_3D(src2_rcd, dst2_rcd, 1, TPath_rcdt[pc1], calculationctx, FI12);
tock();
length(pc12);
sum(t12)
path_c_2_graphic(pc12, FI12)

FI21 = copy_context(ctx);
nothing;

tick();
pc21, pv21, t21 = path_a_b_3D(src1_rcd, dst1_rcd, 1, [pc2], calculationctx, FI21);
tock();
length(pc21);
sum(t21)
path_c_2_graphic(pc21, FI21)


###############################################################################
#
# ALLOCATION TEST
#
####

# 3 AGVs

AGV1 = TAGV(
    "AGV1",
    TCoord(0.0, 0.0, Trc(84, 34)),
    Right,                        # start
    TTime(1.0, 1),                                                  # Time
    THeight(0.0, 0),
    false,
    true,                                   # Fork height, is loaded?, is free to go?
    [],                                                             # List of allocated tasks
    TLocation(),
)                                                     # Allocated parking

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
    "TASK1",                          # ID
    TLocation(                               # FROM
        "Palette1",                                     # ID
        TCoord(0.0, 0.0, Trc(33, 50)),               # Where
        THeight(5.0, 5),                                # Height
        Up,                                             # Side to face
        true,
        true,
    ),
    TLocation(                               # TO
        "Palette2",                                     # ID
        TCoord(0.0, 0.0, Trc(40, 94)),               # Where
        THeight(1.0, 1),                                # Height
        Right,                                          # Side to face
        true,
        true,
    ),
)                                    # is full

task2 = TTask(
    "TASK2",
    TLocation("Palette3", TCoord(0.0, 0.0, Trc(5, 14)), THeight(3.0, 3), Left, true, true),
    TLocation("Palette4", TCoord(0.0, 0.0, Trc(15, 94)), THeight(3.0, 3), Left, true, true),
)

task3 = TTask(
    "TASK3",
    TLocation("Palette5", TCoord(0.0, 0.0, Trc(5, 12)), THeight(5.0, 5), Down, true, true),
    TLocation("Palette6", TCoord(0.0, 0.0, Trc(28, 67)), THeight(9.0, 9), Down, true, true),
)

task4 = TTask(
    "TASK4",
    TLocation("Palette7", TCoord(0.0, 0.0, Trc(3, 61)), THeight(7.0, 7), Right, true, true),
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


LIST_AGVS = [AGV1, AGV2, AGV3, AGV4]
LIST_AGVS = [AGV1, AGV2, AGV3, AGV4, AGV5]
# LIST_TASKS = [task1, task2, task3, task4, task5, task6]; nothing
# LIST_TASKS = [task1, task2, task3]; nothing


# Should be uturn
calctx = TCalculationContext(ctx)
path_a_b_2D(AGV1, ctx.special_locations["parking"][1], calctx, ctx)
path_a_b_2D(Trc(34, 90), Right, Trc(34, 90), Right, calctx, ctx)

# Should be something
path_a_b_2D(AGV1, ctx.special_locations["parking"][2], calctx, ctx)
path_a_b_2D(Trc(34, 90), Right, Trc(34, 90), Right, calctx, ctx)


[task_optimal_perf(t, calctx, ctx) for t ∈ LIST_TASKS]


AGVs_plans = initialise_plans(LIST_AGVS)
tick();
with_logger(AGVLogger(open(module_src_dir * "AGV_log.txt", "a+"), Logging.Debug)) do
    initialise_parkings!(LIST_AGVS, AGVs_plans, calctx, ctx)
end;

# The AGV should do an initial U-turn? CHECK
generate_moves(CartesianIndex(38, 94, 2), ctx)
generate_moves(CartesianIndex(38, 94, 1), ctx)
generate_moves(CartesianIndex(38, 94, 4), ctx)
generate_moves(CartesianIndex(39, 7, 1), ctx)


AGVs_plans[1].parking
AGVs_plans[1].time_at_parking
path_c_2_graphic(AGVs_plans[1].path_to_park, ctx)

AGVs_plans[2].parking
AGVs_plans[2].time_at_parking
path_c_2_graphic(AGVs_plans[2].path_to_park, ctx)

AGVs_plans[3].parking
AGVs_plans[3].time_at_parking
path_c_2_graphic(AGVs_plans[3].path_to_park, ctx)

# USING LIST OF TASKS
#
FI = copy_context(ctx);
nothing;
planning =
    with_logger(AGVLogger(open(module_src_dir * "AGV_log.txt", "a+"), Logging.Debug)) do
        full_allocation(LIST_AGVS, 20, FI; use_fixed_tasks = LIST_TASKS)
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
        println(
            "AGV ",
            a,
            " Step: ",
            i,
            " = ",
            check_path(planning_100[a].steps[i].path, ctx),
        )
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
