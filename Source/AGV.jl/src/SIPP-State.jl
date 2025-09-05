"""
$(TYPEDFIELDS)
"""
@with_kw struct SIPPState
    cfg::Trcd = Trcd(x = 1, y = 1, d = Up)
    interval::Tuple{Int64,Int64} = (0, 0)
    isoptimal::Bool = false
end


"""
$(TYPEDSIGNATURES)

TODO: REWRITE

Data structure that represents a state of an AGV at particular location on the map, at a particular location
in a safe interval, and its associated scores/labels when exploring the A* algorithms steps. It includes
location, time, information about the safe intervals at that map location, optimality (used for weighted
A*) and the three tracked scores (g = actual cost to location, h = estimated heuristics to destination when optimal
step or not, and f = a score that skews the ordering of the nodes to explore to speed up reaching the destination whatever the cost).
Note that the scores are calculated using a convexity adjustment.

The safe intervals refer to those in the SIPPBusyIntervals.
"""
@with_kw mutable struct SIPPStateContext <: AbstractCalculationContext
    g_score::Int64 = STEPS_IMPOSSIBLE    # g_score represents a time
    h_score::Float64 = STEPS_IMPOSSIBLE
    f_score::Float64 = STEPS_IMPOSSIBLE
    camefrom::Union{SIPPState,Nothing} = nothing
end
