"""
    Time and Cost Constants

Time constants are hardcoded in seconds to enable negligible costs (1ms) when needed.
All speeds are multiples of TIME_MULTIPLIER to favor reaching task targets ASAP.

Note: Using a time multiplier increases the depth of the modeling matrix and graph by the same multiple.
Therefore, use the smallest possible multiplier.

Movement cost hierarchy: TURN = 1 UNIT, BACKWARD = 2 UNITS, FORWARD = 4 UNITS.
"""
const TIME_MULTIPLIER = 1
const STEP_TO_COST_MULTIPLIER = 1_000

"""
    COST_WARP_TRAVEL

Cost for warping to destination to ensure AGVs reach targets ASAP and can stay forever.
Must be different from parking costs to maintain algorithm correctness.
"""
const COST_WARP_TRAVEL = 1

"""
    STEPS_IMPOSSIBLE

Time steps to mark an edge as impossible to follow.
Used to represent blocked or unreachable paths in the graph.
"""
const STEPS_IMPOSSIBLE = 1_000_000_000
const COST_IMPOSSIBLE = STEPS_IMPOSSIBLE * STEP_TO_COST_MULTIPLIER

"""
    TIME_MAX

Maximum simulation time in seconds.
Currently set to 5 minutes (300 seconds).
"""
const TIME_MAX = 5 * 60 * TIME_MULTIPLIER

"""
    TIME_STEP

Time step size in seconds for simulation discretization.
Currently set to 0.5 seconds.
"""
const TIME_STEP = 0.5 * TIME_MULTIPLIER

"""
    SLICE_MAX

Maximum number of time slices in the 3D simulation matrix.
Calculated as TIME_MAX / TIME_STEP.
"""
const SLICE_MAX = Int64(ceil(TIME_MAX / TIME_STEP))

"""
    MAX_PATH_LENGTH

Maximum path length for pre-allocation of path storage.
Used to avoid dynamic memory allocation during pathfinding.
"""
const MAX_PATH_LENGTH = 512

"""
    STEP_SAFETY_BUFFER

Safety buffer in time steps before and after each occupancy.
Prevents edge cases in collision detection and path planning.
"""
const STEP_SAFETY_BUFFER = 1


"""
    AGV Physical Constants

Physical dimensions of AGVs in simulation units.
These constants define the size of vehicles for collision detection and path planning.
"""
const AGV_LENGTH = 4
const AGV_WIDTH = 3

"""
    Movement Cost Constants

Time costs for different AGV movements in simulation steps.
These costs are used in pathfinding algorithms to determine optimal routes.

Movement hierarchy: REMAIN < FORWARD < TURN < LEVEL_CHANGE < INOUT
"""
const STEPS_REMAIN = 1 * TIME_MULTIPLIER
const COST_REMAIN = STEPS_REMAIN * STEP_TO_COST_MULTIPLIER

const STEPS_FWD = 1 * TIME_MULTIPLIER
const COST_FWD = STEPS_FWD * STEP_TO_COST_MULTIPLIER

"""
    STEPS_BCK

Backward movement is currently disabled (set to impossible).
This prevents AGVs from moving backward, simplifying path planning.
"""
const STEPS_BCK = STEPS_IMPOSSIBLE
const COST_BCK = STEPS_BCK * STEP_TO_COST_MULTIPLIER

"""
    STEPS_TRN

Time steps required for AGV to turn 90 degrees.
Based on real-world AGV turning capabilities.
"""
const STEPS_TRN = 15
const COST_TRN = STEPS_TRN * STEP_TO_COST_MULTIPLIER

"""
    STEPS_LEVEL

Time steps to move up or down one shelf level.
Includes both up and down movement (2 * 20 = 40 steps total).
Based on real-world forklift performance data.
"""
const STEPS_LEVEL = 2 * 20
const COST_LEVEL = STEPS_LEVEL * STEP_TO_COST_MULTIPLIER

"""
    STEPS_INOUT

Time steps to move in and out of a shelf (loading/unloading).
Includes approach, load/unload, and retreat movements.
"""
const STEPS_INOUT = 25
const COST_INOUT = STEPS_INOUT * STEP_TO_COST_MULTIPLIER


"""
    MAX_NUMBER_BUSY_INTERVALS

Maximum number of busy intervals in SIPP (Safe Interval Path Planning) algorithm.
Used to pre-allocate memory for SIPPBusyIntervals structure to avoid dynamic allocation
during pathfinding in dynamic environments with moving obstacles.
"""
const MAX_NUMBER_BUSY_INTERVALS = 1024
