##################################################################################################################
# anytime_SIPP
module_dir = "/home/emmanuel/Documents/Work/Alba/AGV/_gits/AGV.jl/"
module_img_dir = module_dir * "img/"
module_src_dir = module_dir * "src/"
cd(module_dir)

using Pkg;
Pkg.activate(".");

using Revise
using TickTock
using FileIO
using JLD2
using Logging
using Printf
using Profile
using PProf
using Debugger
using BenchmarkTools
using Distributions
using LightGraphs
using SimpleWeightedGraphs
using SparseArrays
using Test

using AGV

break_on(:error)
