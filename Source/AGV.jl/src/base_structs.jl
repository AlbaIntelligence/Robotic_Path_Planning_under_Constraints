"""
$(TYPEDFIELDS)

Represents the height of an AGV's fork at a particular time.

This is necessary since any pick-up or delivery operation can be interrupted,
requiring the system to track the current fork height for resumption.

# Fields
- `h::Float64`: Height in standardized units (meters)
- `simh::Int64`: Height in simulation units (discrete steps)

# Examples
```julia
fork_height = THeight(h=2.5, simh=50)  # 2.5 meters, 50 simulation steps
```
"""
@with_kw struct THeight
    h::Float64 = 0.0
    simh::Int64 = 0
end

Base.print(io::IO, ::Type{THeight}) = print(io, "")
Base.print(io::IO, h::THeight) = print(io, "H[" * string(h.h) * ", " * string(h.simh) * "]")

"""
    MAX_RACK_LEVELS

Maximum number of levels in warehouse racks.
Used for calculating maximum movement costs and path planning bounds.
"""
const MAX_RACK_LEVELS = 9

"""
    STEPS_MAX_TO_KNOCKOUT

Maximum time steps required for any single AGV operation.
Calculated as the maximum of all possible movement costs to ensure
adequate time allocation for path planning and collision avoidance.
"""
const STEPS_MAX_TO_KNOCKOUT =
    maximum([STEPS_REMAIN, STEPS_FWD, 2 * STEPS_TRN, STEPS_INOUT + STEPS_LEVEL])



"""
$(TYPEDFIELDS)

Represents time in both standardized and simulation units.

Used throughout the system to maintain consistency between real-world time
and discrete simulation time steps.

# Fields
- `t::Float64`: Time in standardized units (seconds)
- `simt::Int64`: Time in simulation units (discrete steps)

# Examples
```julia
current_time = TTime(t=125.5, simt=251)  # 125.5 seconds, 251 simulation steps
```
"""
@with_kw struct TTime
    t::Float64 = 0.0
    simt::Int64 = 0
end

Base.print(io::IO, ::Type{TTime}) = print(io, "")
Base.print(io::IO, t::TTime) = print(io, "T[" * string(t.t) * ", " * string(t.simt) * "]")



######################################################################################################################
# Path Planning Algorithm Types

"""
    AbstractCalculationContext

Abstract type for path planning calculation contexts.
Provides common interface for different pathfinding algorithms.
"""
abstract type AbstractCalculationContext end

"""
    AbstractPathPlanning

Abstract type for path planning algorithms.
Used to implement different pathfinding strategies (A*, SIPP, etc.).
"""
abstract type AbstractPathPlanning end

"""
    A_Star

A* pathfinding algorithm implementation.
Provides optimal pathfinding with heuristic guidance.
"""
struct A_Star <: AbstractPathPlanning end

"""
    AnytimeSIPP

Anytime Safe Interval Path Planning algorithm.
Provides bounded suboptimal solutions with anytime properties.
"""
struct AnytimeSIPP <: AbstractPathPlanning end
