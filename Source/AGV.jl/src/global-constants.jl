"""
    Time constants

HARDCODED IN SECONDS (SO THAT WE CAN HAVE 1 ms NEGLIGEABLE COSTS WHEN NEEDED). ALL SPEEDS ARE MULTIPLES of the TIME_MULTIPLIER  BEING CURRENTLY 100 TO GET '00th s TO BE ABLE TO FAVOUR REACHING
TASK TARGETS ASAP.

However, using the time multiplier means increasing the depth of the modelling matrix and graph by the same multiple. Therefore should use as small as possible.

THIS WAY: TURN = 1 UNIT. BCK = 2 UNITS. FWD = 4 UNITS.
"""
const TIME_MULTIPLIER = 1
const STEP_TO_COST_MULTIPLIER = 1_000

# To ensure that reach parking ASAP and can stay forever
# const COST_STAY_ON_PARKING = 1

# !!!
#    DANGER : needs to be different than TStayOnParking
# To ensure that reach destination ASAP and can stay forever
const COST_WARP_TRAVEL = 1

# Time to mark an edge as impossible to follow
const STEPS_IMPOSSIBLE = 1_000_000_000
const COST_IMPOSSIBLE = STEPS_IMPOSSIBLE * STEP_TO_COST_MULTIPLIER

# [CHECK: unused?]
const TIME_MAX = 5 * 60 * TIME_MULTIPLIER
const TIME_STEP = 0.5 * TIME_MULTIPLIER
const SLICE_MAX = Int64(ceil(TIME_MAX / TIME_STEP))

# Used in pre-allocation
const MAX_PATH_LENGTH = 512

# Safety buffer in steps before and after each occupancy
const STEP_SAFETY_BUFFER = 1


"""
    Simulation constants

Somewhat arbitrary

AGV constants

Size of a vehicle in simulation units
THIS WAY: TURN = 1 UNIT. BCK = 2 UNITS. FWD = 4 UNITS

TimeToReach: Time to go up or down 1 level in Simulation time (from Youtube)
TimeInOut: Time to go in and out a rack
"""
const AGVLength = 4
const AGVWidth = 3

# Number of simulation steps to achieve remaining, go forward, go backward, turn, reach
# 1 level (up and down), get in and out a shelf
const STEPS_REMAIN = 1 * TIME_MULTIPLIER
const COST_REMAIN = STEPS_REMAIN * STEP_TO_COST_MULTIPLIER

const STEPS_FWD = 1 * TIME_MULTIPLIER
const COST_FWD = STEPS_FWD * STEP_TO_COST_MULTIPLIER

# For the moment, no backward travel
const STEPS_BCK = STEPS_IMPOSSIBLE
const COST_BCK = STEPS_BCK * STEP_TO_COST_MULTIPLIER

const STEPS_TRN = 15
const COST_TRN = STEPS_TRN * STEP_TO_COST_MULTIPLIER

# 6 s per level - times 2 for one up + one down
const STEPS_LEVEL = 2 * 20
const COST_LEVEL = STEPS_LEVEL * STEP_TO_COST_MULTIPLIER

const STEPS_INOUT = 25
const COST_INOUT = STEPS_INOUT * STEP_TO_COST_MULTIPLIER


"""
    SIPP_MAX_INTERVALS

Maximum number of intervals in a list of busy intervals used for the SIPP algorithms as represented by the SIPPBusyIntervals structure.
"""
const MAX_NUMBER_BUSY_INTERVALS = 1024
