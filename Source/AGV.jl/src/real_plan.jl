#############################################################################
#
# FULL EXAMPLE
#
module_dir = "/home/emmanuel/Documents/Work/Alba/AGV/_gits/AGV.jl/"
module_img_dir = module_dir * "img/"
module_src_dir = module_dir * "src/"
cd(module_dir)

using Revise, TickTock, FileIO, JLD2, Logging, Printf
using Profile, PProf
using Distributions, LightGraphs, SimpleWeightedGraphs, SparseArrays
using AGV

Profile.clear()
Profile.init(delay = 0.001)

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


nSteps = 300
depthLimit = TIME_MULTIPLIER * 300
Logging.disable_logging(Logging.Warn)

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


###############################################################################
#
# ALLOCATION TEST
#
####

AGV1 = TAGV(
    "AGV1",
    TCoord(0.0, 0.0, Trc(84, 34)),
    Right,                        # start
    TTime(1.0, 1),                                               # Time
    THeight(0.0, 0),
    false,
    true,                                # Fork height, is loaded?, is free to go?
    [],                                                          # List of allocated tasks
    TLocation(),
)                                                 # Allocated parking

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



LIST_AGVS = [AGV1, AGV2, AGV3, AGV4]
LIST_AGVS = [AGV1, AGV2, AGV3, AGV4, AGV5]

# 10 random tasks
#
FI = copy_context(ctx)
planning_10 =
    with_logger(AGVLogger(open(module_src_dir * "AGV_log_10.txt", "w+"), Logging.Debug)) do
        full_allocation(LIST_AGVS, 10, FI; queue_size = 10)
    end

tick();
full_allocation(LIST_AGVS, 10, FI; queue_size = 10);
tock();

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



# convert -size 360x360 xc:white -font "FreeMono" -pointsize 12 -fill black -draw @ascii.txt image.png
