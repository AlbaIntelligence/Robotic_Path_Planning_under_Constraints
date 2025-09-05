"""
   $(TYPEDFIELDS)

Represents how high a fork is at a particular time. This is necessary since any pick-up / delivery can be interrupted.

- h:: Float64 for standardised units

- simh::Int64 for simulation units
"""
@with_kw struct THeight
    h::Float64 = 0.0
    simh::Int64 = 0
end

Base.print(io::IO, ::Type{THeight}) = print(io, "")
Base.print(io::IO, h::THeight) = print(io, "H[" * string(h.h) * ", " * string(h.simh) * "]")

const MAX_RACK_LEVELS = 9
# const STEPS_MAX_TO_KNOCKOUT = maximum([STEPS_REMAIN, STEPS_FWD, 2 * STEPS_TRN, STEPS_INOUT + MAX_RACK_LEVELS * STEPS_LEVEL])
const STEPS_MAX_TO_KNOCKOUT =
    maximum([STEPS_REMAIN, STEPS_FWD, 2 * STEPS_TRN, STEPS_INOUT + STEPS_LEVEL])



"""
   $(TYPEDFIELDS)

- t:: Float64 for standardised units

- simt::Int64 for simulation units
"""
@with_kw struct TTime
    t::Float64 = 0.0
    simt::Int64 = 0
end

Base.print(io::IO, ::Type{TTime}) = print(io, "")
Base.print(io::IO, t::TTime) = print(io, "T[" * string(t.t) * ", " * string(t.simt) * "]")



######################################################################################################################
# Existing path planning algo
abstract type AbstractCalculationContext end

abstract type AbstractPathPlanning end
struct A_Star <: AbstractPathPlanning end
struct AnytimeSIPP <: AbstractPathPlanning end
