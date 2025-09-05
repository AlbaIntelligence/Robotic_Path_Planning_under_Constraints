
# %% End Tables
# %%
# %% \newpage
# %%



# using Weave
# Weave.weave("AGV_markup.jl"; doctype="pandoc2pdf", cache=:refresh, pandoc_options=["--table-of-contents", "--number-sections", "--reference-links"])

using LightGraphs
using SimpleWeightedGraphs

# %%
# %% # [TODO]
# %%
# %% - [TODO: Consider variants to A*]
# %% - CHANGE ALL TO CartesianCoordinates
# %% - For the moment, provision for backward movements in the move generators (need to think about cost impact and propagation of AGV state over time). Might be as easy as decomposing complex tasks in sub-tasks, and just copy and paste pushing across time in 3D.
# %% - Delete simTime constants once tests finished.
# %%
# %% # NOTES
# %%
# %% - Single planning (next task allocation): matrix 2D because only sorting by distance (cost = time) without considering collisions.
# %%
# %% - Multiple planning: 3D
# %%
# %% - $T_{Max}$ is currently fixed at 300s. It could just be a minimum to be dynamically increased if A* search is unsuccessful.
# %%
# %%
# %%

# %%
# %% Coding of locations within floorplan matrices
# %%

const LOCATION_EMPTY = 0
const LOCATION_BUSY = 1


# HARDCODED IN SECONDS. ALL SPEEDS ARE MULTIPLES.
# THIS WAY: TURN = 1 UNIT. BCK = 2 UNITS. FWD = 4 UNITS.

const Tmax = 5 * 60
const TStep = 0.50
const SliceMax = Int64(ceil(Tmax / TStep))

const AGVLength = 4.0
const AGVWidth = 3.0

const TTransitCostOnTarget = 0.001 # See assumptions

# [TODO: To be deleted] Completely arbitrary

const simTimeFwd = 1
const simTimeBck = 4
const simTimeTrn = 10

const TimeToReach = 6 * 2 # Time to go up or down 1 level in Simulation time (from Youtube)
const TimeInOut = 6 # Time to go in and out a rack

# %%
# %%
# %% # Assumptions
# %%
# %% - Everything in SI.
# %%
# %% - Time-step short enough to never have jump-overs even at full speed.
# %%
# %% - AGV dimensions approximated in multiple of twice the grid so that all dimensions / tests can be done as centre location +/- value in integers.
# %%
# %% - AGV dimensions include palettes.
# %%
# %% - Should include security perimeter monitored by AGV?
# %%
# %% - All standardised dimensions in floating point. All simulation dimensions in integers. Type mistakes are easier to pick up.
# %%
# %% - Dimensions of the floor plan is in units of the gridsize.
# %%
# %% - Once a palette is taken off a shelf, it cannot be put back (putting back might mess up warehouse software and really not obvious is a lot of time would actually be saved).
# %% - Basically, any movement up or dowm to do anything will not be cancelled or replanned half-way through.
# %% - The logic to track if any TPaletteLocation is occupied or not is ignored. We rely on the warehousing software to track that for us.
# %%
# %% - Transition time on target location $TTransitCostOnTarget$ = 0.001 = 1ms since nil weight on a graph means no edge.
# %%
# %% # Data structures
# %%
# %% ## Data types
# %%
# %% ### Location / Time
# %%
# %% $TLocation$:
# %%
# %% - $x, y:: Float64$ for standardised units
# %%
# %% - $s = CartesianIndex(simx, simx::Int64)$ for simulation units
# %%

abstract type AbstractLocation end

struct TLocation <: AbstractLocation
    x::Float64
    y::Float64
    s::CartesianIndex{2}
end

# %%
# %% $height$:
# %%
# %% Represents how high a fork is at a particular time. This is necessary since any pick-up / delivery can be interrupted.
# %%
# %% - $h:: Float64$ for standardised units
# %%
# %% - $simh::Int64$ for simulation units
# %%
# %%

struct THeight
    h::Float64
    simh::Int64
end

# %%
# %% $TTime$:
# %%
# %% - $t:: Float64$ for standardised units
# %%
# %% - $simt::Int64$ for simulation units
# %%
# %%

struct TTime
    t::Float64
    simt::Int64
end


# %%
# %% ### Direction of an AGV
# %%
# %% $TDirection$::
# %% - Enum: [Up, Down, Left, Right]
# %%

@enum TDirection begin
    Up
    Down
    Left
    Right
end
const nDirection = 4

# %%
# %% ## Structures
# %%
# %% ### Parkings:
# %%
# %% - Parking ID
# %%
# %% - Parking location: $TLocation$
# %%
# %%


struct TParking <: AbstractLocation
    ID::String
    loc::TLocation
end


# %% ### Palette location (they do more than palettes!)
# %%
# %% Palette locations is any spot that can have a palette!
# %%
# %%   - Conveyor or Delivery belt, Top or Bottom drop areas, Quay
# %%   - Which side of that location needs to be faced to pick up/drop. This is the face that the AGV needs to have to load/unload. If the rack is open towards the right, the AGV needs to face left and this is the direction recorded.
# %%   - NEED TO SEPARATE TIMES RELATED TO THE TASK PROVIDED BY THE QUEUING SYSTEM, VS. TIME CALCULATED FOR A GIVEN AGV MODEL.
# %%
# %% - ID
# %%
# %% - Location: $TLocation$
# %%
# %% - How high a paletter is located:.level is an Integer that wil be = 0 for ground located
# %%
# %% - Whether the location is currently occupied. Logic for change of occupancy NOT implemented (see Assumptions)

struct TPaletteLocation <: AbstractLocation
    ID::String

    loc::TLocation
    height::THeight

    sideToFace::TDirection
    isFull::Bool
end


# %%
# %% ### Tasks: Know at algo start
# %%
# %% - Task ID ([TODO: Transform to data type])
# %%
# %% - Location start ($s_j$): $TLocation$, $onrack$, $level$. $level$ only in on racks ($onrack == true$)
# %%
# %% - Location target ($g_j$): $TLocation$, $onrack$, $level$. $level$ only in on racks ($onrack == true$)
# %%

struct TTask
    ID::String
    start::TPaletteLocation
    target::TPaletteLocation
end

# %%
# %% ### AGV:
# %%
# %% - ID number: Known at algo start
# %% - Initial position: $TLocation$ Known at algo start
# %% - Current position: $TLocation$.
# %% - Final position: $TLocation$.
# %% - Final time stamp: $TTime$
# %% - State:
# %%
# %%   - $Direction$: $TDirection$
# %%   - $forkHeight$: how high the fork currently is (in shelf simulation units!) since movements up or down can be interrupted at any time for replanning.
# %%   - $isLoaded$: $Bool$
# %%   - $isSideways$:: $Bool$ - is the AGV facing a shelf but otherwise ready to go (about to load or after loading, but no idea where to go).
# %%   - [TODO: More TBD]
# %%
# %% - List of tasks as list of tuples allocated to that AGV: Initialised empty
# %%
# %%   - Task ID
# %%   - time $TTime$ in simulation units from previous step to reach task. The list is updated at each iteration using the release time calculated by A*. $t = 0$ at the start.
# %%
# %% - Allocated parking . Full structure for the moment. (Maybe $Parking_{ID}$ later?).
# %%
# %%

struct TAGV
    ID::String
    start::TLocation
    start_direction::TDirection

    current::TLocation
    current_direction::TDirection

    target::TLocation
    target_direction::TDirection

    time::TTime

    direction::TDirection

    forkHeight::THeight
    isLoaded::Bool
    isSideways::Bool

    listTasks::AbstractVector{TTask}
    park::TParking

    # AGV Move parameters
    simSpeedFwd::Int64
    simSpeedBck::Int64
    simSpeedTrn::Int64
end

# %%
# %%
# %% ### FloorPlan information structure
# %%

struct FloorInfo
    plan::AbstractMatrix{Integer}
    nRow::Integer
    nCol::Integer
end

function FloorInfo(FloorPlan::AbstractMatrix{})
    return FloorInfo(FloorPlan, size(FloorPlan)[1], size(FloorPlan)[2])
end


# %%
# %% ## Global variables
# %%
# %% Precompute FloorPlan information
# %%
# %% ### Task end to task end optimal times
# %%
# %%
# %% - Initialise matrix $\tau$ with dimensions $length(ListTasks) \times length(ListTasks)$ Pre-calculate transfers from the end of one task to the end of another: $\tau_{i, j} = time\_2D(\mathbb{G}, g_i, g_j)$. That matrix is NOT symmetrical. It includes transfer time + and up/down fork movement. Each task ends with the AGV facing its pick-up/delivery point.
# %%
# %%

paletting_time(h::THeight) = 2*TimeToReach + TimeInOut
paletting_time(p::TPaletteLocation) = paletting_time(p.height)

function τ(G::SimpleWeightedDiGraph, listOfTasks, floor::FloorInfo)
    nTasks = length(listOfTasks)
    M = Matrix{TTime}(undef, (nTasks, nTasks))

    for i ∈ 1:nTasks, j ∈ 1:nTasks

        # Transfer time
        if i == j
            t = 0.0
        else
            _, _, t = path_a_b(listOfTasks[i], listOfTasks[j], floor)
        end

        M[i, j] = t + paletting_time(listOfTasks[j].target)
    end

    return M
end


# %%
# %% # Utility Functions
# %%
# %% ## Reciprocal conversions between simulation coordinates and node numbers.
# %%
# %% Coordinates are expressed in $CartesianIndex()$. Nodes are vertices expessed as $Int64$
# %%
# %% ### Conversions in 2 dimensions
# %%

function c2v(p::CartesianIndex{2}, floor::FloorInfo)::Int64
  # Beware of 0 vs. 1 indexing
    return (p[1] - 1) * floor.nCol + (p[2] - 1) + 1
end

function c2v(l::TLocation, floor::FloorInfo)::Int64
    return c2v(TLocation.s, floor)
end

function c2v(p::TPaletteLocation, floor::FloorInfo)::Int64
    return c2v(p.loc, floor)
end

function v2c(n::Integer, floor::FloorInfo)::CartesianIndex{2}
  # Beware of 0 vs. 1 indexing
    x = 1 + div(n - 1, floor.nCol)
    y = 1 + rem(n - 1, floor.nCol)
    return CartesianIndex(x, y)
end


# %%
# %% ### Conversions in 2 dimensions including directions
# %%

# %% Direction is kept separate in the type signature to avoid confusing the dispatch.
# %% [TODO: Extract to a type or use $TAGV$ (although a pain to do all the conversions)]

# Beware of 0 vs. 1 indexing
function c2v(p::CartesianIndex{2},
    dir::TDirection,
    floor::FloorInfo)::Int64

    # No Int64(dir)-1 here since enums start at 0
    return ((p[1] - 1) * floor.nCol + (p[2] - 1)) * nDirection + Int64(dir) + 1
end

function c2v(l::TLocation,
    dir::TDirection,
    floor::FloorInfo)::Int64
    x, y = l.s
    return c2v(CartesianIndex(x, y), dir, floor)
end

function c2v(p::TPaletteLocation,
    dir::TDirection,
    floor::FloorInfo)::Int64

    return c2v(p.loc, floor, dir)
end

function v2c(v::Integer,
    withdir::Bool,
    floor::FloorInfo)

    # Beware of 0 vs. 1 indexing
    v0 = v - 1

    nCol = floor.nCol

    xy = 1 + div(v0, nDirection)
    x = 1 + div(xy - 1, nCol)
    y = 1 + rem(xy - 1, nCol)

    # No 1+ here since enums start at 0
    dir = rem(v0, nDirection)

    return [CartesianIndex(x, y), TDirection(dir)]
end



# %%
# %% ### Conversions in 3 dimensions
# %%
# %% 3 dimensions is the 2 (x, y) plus time
# %%

# Beware of 0 vs. 1 indexing
function c2v(p::CartesianIndex{3},
    nTime::Integer,
    floor::FloorInfo)::Int64

    return ((p[1] - 1) * floor.nCol + (p[2] - 1)) * nTime + (p[3] - 1) + 1
end

function c2v(l::TLocation, time::TTime,
    nTime::Integer,
    floor::FloorInfo)::Int64
    x, y = l.s
    return c2v(CartesianIndex(x, y, time.simt), floor, nTime)
end

function c2v(p::TPaletteLocation, time::TTime,
    nTime::Integer,
    floor::FloorInfo)::Int64

    return c2v(p.loc, time, floor, nTime)
end

function v2c(v::Integer,
    nTime::Integer,
    floor::FloorInfo)::CartesianIndex{3}

    # Beware of 0 vs. 1 indexing
    v0 = v - 1

    nCol = floor.nCol

    xy = 1 + div(v0, nTime)
    x = 1 + div(xy - 1, nCol)
    y = 1 + rem(xy - 1, nCol)

    t = 1 + rem(v0, nTime)

    return CartesianIndex(x, y, t)
end

# Given a list of vertices, return the coodinates of the path steps
function v2c(path::AbstractVector{}, floor::FloorInfo)

    return [v2c(v, floor) for v in path]
end

# %%
# %% ### Create list of obstacles in Cartesian and vertex coordinates
# %%

function cFloorPlanObstacles(floor::FloorInfo)
    return [CartesianIndex(i, j) for i in 1:floor.nRow,
                                     j in 1:floor.nCol
                                 if floor.plan[i, j] == 1]
end

function vFloorPlanObstacles(floor::FloorInfo)
    return [c2v(CartesianIndex(i, j), floor) for i in 1:floor.nRow,
                                                 j in 1:floor.nCol
                                             if floor.plan[i, j] == 1]
end


# %%
# %% ## $create\_list\_of\_parkings(n)$
# %%
# %% Create $n$ parking positions with:
# %%
# %%   - All values are in standardised dimensions
# %%
# %%   - Number of parkings located next to sources of tasks in proportion of coming orders. Assume that this being done, equal probability of use is acceptable (no priority in the order of filling the parking).
# %%
# %%   - All different
# %%
# %%   - At least one per AGV
# %%
# %%   - Ensure parking positions do not prevent any traffic once an AGV is occupying it.
# %%
# %%     - WARNING: this is necessary to guarantee that searches will always find solution:
# %%

function create_list_parkings(M)::AbstractVector{TParking}
    return []
end


# %%
# %% [TODO: Why is that here when we have $\tau$???]
# %% ## $create\_task\_pairing\_times(listOfTasks)$
# %%
# %% Precomputes the optimal time to go from one finished task to the end of another for any pairing of tasks.
# %% This is not symmetrical and calculated both ways.
# %% If only a single task, nothing to do!

# [CHECK: do we need to include the path in each result?]
function create_task_pairing_times(
    G::SimpleWeightedDiGraph,
    listOfTasks::AbstractVector{TTask},
    floor::FloorInfo)::AbstractVector{TTime}

    nTasks = length(listOfTasks)

    # Result matrix
    M = Array{TTime}(undef, (nTasks, nTasks))

    # TODO: As list comprehension?
    if nTasks > 1
        for i ∈ 1:nTasks
            for j ∈ 1:nTasks
                # Tasks
                t1 = listOfTasks[i].target
                t2 = listOfTasks[j].target

                # nodes at the end of task i and at the end of task j
                v1 = c2v(t1, floor)
                v2 = c2v(t2, floor)

                M[i, j] = path_2D(G, v1, v2)
            end
        end
    end

    return M
end


# %%
# %%
# %% ## $scale\_to\_simulation(object)$
# %%
# %% Generic function to rescale the floor plan or object locations from standardised to simulation
# %%
# %%

# Convert any Float64 to Int64. Can be used for location or time
function scale_to_simulation(x::Float64, factor::Float64)::Int64
    return Int64(ceil(x / factor))
end

function scale_to_simulation(p::THeight, tStep)::TTime
    r = deepcopy(p)
    r.simh = scale_to_simulation(p.h, tStep)
    return r
end

function scale_to_simulation(t::TTime, tStep)::TTime
    r = deepcopy(t)
    r.simt = scale_to_simulation(t.t, tStep)
    return r
end

function scale_to_simulation(loc::TLocation, gridSize::Float64)::TLocation
    l = deepcopy(loc)
    simx = scale_to_simulation(loc.x, gridSize)
    simy = scale_to_simulation(loc.y, gridSize)
    l.s = CartesianIndex(simx, simy)
    return l
end

function scale_to_simulation(p::TParking, gridSize::Float64)::TParking
    l = deepcopy(p)
    l.loc = scale_to_simulation(p.loc, gridSize)
    return l
end

function scale_to_simulation(p::TPaletteLocation, gridSize::Float64)::TPalette
    l = deepcopy(p)
    l.loc = scale_to_simulation(p.loc, gridSize)
    l.height = scale_to_simulation(p.height, gridSize)
    return l
end

function scale_to_simulation(t::TTask, gridSize::Float64)::TTask
    l = deepcopy(t)
    l.start = scale_to_simulation(t.start, gridSize)
    l.target = scale_to_simulation(t.target, gridSize)
    return l
end

function scale_to_simulation(t::Vector{TTask}, gridSize::Float64)::Vector{TTask}
    l = deepcopy(t)
    return map(t -> scale_to_simulation(t, gridSize), l)
end

function scale_to_simulation(a::TAGV, gridSize::Float64, tStep::Float64)::TAGV
    l = deepcopy(a)
    l.start = scale_to_simulation(a.start, gridSize)
    l.current = scale_to_simulation(a.current, gridSize)
    l.target = scale_to_simulation(a.target, gridSize)
    l.forkHeight = scale_to_simulation(a.forkHeight, gridSize)
    l.time = scale_to_simulation(a.time, tStep)
    l.listTasks = scale_to_simulation(a.listTasks, gridSize)
    l.park = scale_to_simulation(a.park, gridSize)
    return l
end

# %% Starting for a floorplan, create a matrix where each position of the floorplan is converted into a square of equal content but broken down into simulation units
# %%

function scale_to_simulation(F::AbstractMatrix{Int64}, GridSize::Real)

    GridSimMultiplier = Int64(ceil(1.0 / GridSize))

    # Create an empty matrix that will contain the simulation scaled properly.
    nRow, nCol = size(F)

    nSimRow = GridSimMultiplier * nRow
    nSimCol = GridSimMultiplier * nCol

    M = zeros(Int64, (nSimRow, nSimCol))

    # For each location in the resulting matrix, change to the floorplan value.
    for i ∈ 1:nRow
        for j ∈ 1:nCol
            # Calculate the beginning- and end-rows to be changed
            i_beg =  1 + GridSimMultiplier * (i - 1)
            i_end =      GridSimMultiplier * i

            # ditto for columns
            j_beg =  1 + GridSimMultiplier * (j - 1)
            j_end =      GridSimMultiplier * j

            # Block change
            M[i_beg:i_end, j_beg:j_end] .= F[i, j]
        end
    end

    return FloorInfo(M)
end



# %%
# %%
# %% ## $scale\_to\_standardised(object)$
# %%
# %% Generic function to rescale the floor plan or object locations from simulation to standardised
# %%
# %%

# Convert any Float64 to Int64. Can be used for location or time
function scale_to_standardised(v::Int64, factor::Float64)::Float64
    return Float64(factor * Float64(v))
end

function scale_to_standardised(p::THeight, tStep)::TTime
    r = deepcopy(p)
    r.h = scale_to_standardised(p.simh, tStep)

    return r
end

function scale_to_standardised(t::TTime, tStep)::TTime
    r = deepcopy(t)
    r.t = scale_to_standardised(t.simt, tStep)
    return r
end

function scale_to_standardised(loc::TLocation, gridSize::Float64)::TLocation
    l = deepcopy(loc)
    l.x = scale_to_standardised(loc.s[1], gridSize)
    l.y = scale_to_standardised(loc.s[2], gridSize)
    return l
end

function scale_to_standardised(p::TParking, gridSize::Float64)::TParking
    l = deepcopy(p)
    l.loc = scale_to_standardised(p.loc, gridSize)
    return l
end

function scale_to_standardised(p::TPaletteLocation, gridSize::Float64)::TPalette
    l = deepcopy(p)
    l.height = scale_to_standardised(p.height, gridSize)
    return l
end

function scale_to_standardised(t::TTask, gridSize::Float64)::TTask
    l = deepcopy(t)
    l.start = scale_to_standardised(t.start, gridSize)
    l.target = scale_to_standardised(t.target, gridSize)
    return l
end

function scale_to_standardised(t::Vector{TTask}, gridSize::Float64)::Vector{TTask}
    l = deepcopy(t)
    return map(t -> scale_to_standardised(t, gridSize), l)
end

function scale_to_standardised(a::TAGV, gridSize::Float64, tStep::Float64)::TAGV
    l = deepcopy(a)
    l.start = scale_to_standardised(a.start, gridSize)
    l.current = scale_to_standardised(a.current, gridSize)
    l.target = scale_to_standardised(a.target, gridSize)
    l.forkHeight = scale_to_standardised(a.forkHeight, gridSize)
    l.time = scale_to_standardised(a.time, tStep)
    l.listTasks = scale_to_simulation(a.listTasks, gridSize)
    l.park = scale_to_standardised(a.park, gridSize)
    return l
end

# %%
# %%
# %% # Algorithm
# %%
# %% ## Expected inputs
# %%
# %% All inputs are in Standardised dimensions.
# %%
# %% - $F$: _Required_ Floor plan matrix
# %% - $ListAGV$: _Required_. Check list length >= 1
# %% - $ListTasks = []$: _Required_. List length can be 0. Must include the list of tasks that are already allocated at the start of the simulation.
# %% - $ListOfParking = create\_list\_of\_parkings(length(ListAGV))$: _Optional_ List of parking slots. Created if missing.
# %% - Speeds: _Required_ forward, backward, turn
# %%
# %%
# %% ## Wrapping
# %%
# %% First call point is $optimise\_standardised\_units()$.
# %%
# %% ### Timing and Sizing parameters
# %%
# %% Estimate adequate time step $t_{step}$ to scaled matrix to $M$. [CHECK: Default to 200ms]
# %%
# %% Max simulation time $T_{Max}$: This time will be used when planning a path. It has to be long enough so that, given any configuration, A* will find a path from any current position, to achieve any task and go to any parking position. Currently 300s (converted to simulation time using $t_{step}$ in ${Step}_{Max}$). Track A* failures to check if long enough.
# %%
# %% ${Step}_{Max} = T_{Max} / t_{step}$ is the depth of the 3D planning matrix.
# %%
# %% $GridSize$:
# %%
# %% - size of each simulation square. AGV dimensions = +/- 1/2 width, +/- 1/2 length.
# %% - Ensures never jumps over even max speed.
# %%
# %%
# %% ### Scale everything to Simulation dimensions
# %%
# %% Rescale all relevant values from Standardised to Simulation:
# %%
# %% - Matrix of the full floor plan: $M = Rescale(F)$
# %% - Same for $ListOfParkings = [Parking_i]$, $\alpha_i$, $s_j$, $g_j$ to be appropriately scaled given $t_{step}$.
# %%
# %% ### Call main algo in simulation units
# %%
# %% Call $optimise\_simulation\_units()$
# %%
# %%
# %% ### Scale everything back to standardise units
# %%
# %% Rescale all relevant values from Simulation to Standardised
# %%
# %%
# %% ### Return
# %%
# %% Results are returned in Standardised units.
# %%
# %%

# %%
# %% ### Code
# %%

function optimise_standardise_units(
    F::AbstractMatrix{Float64},
    listAGVs::AbstractVector{TAGV},
    listTasks::AbstractVector{TTask};
    speedFwd::Float64=2.0,
    speedBck::Float64=1.0,
    speedTrn::Float64=0.5,
    listParkings::AbstractVector{TParking}=create_list_of_parkings(length(listAGVs)))

    # 600 STEPS - MATRIX DEPTH
    StepMax = Int64(ceil(TMax / TStep))

    # GridSize = 50 cm
    GridSize = Float64(ceil(speedTrn / TStep))
    M = scale_to_simulation(F, GridSize)

    simAGVLength = Int64(ceil(AVGLength / GridSize))
    simAGVWidth = Int64(ceil(AVGWidth / GridSize))

    # ALERT: FINALISE RETURN FORMAT
    simulation_optim = optimise_standardise_units(
        M, StepMax,
        scale_to_simulation(listAGVs),
        scale_to_simulation(listTasks),
        scale_to_simulation(1.0 / speedFwd),
        scale_to_simulation(1.0 / speedBck),
        scale_to_simulation(1.0 / speedTrn),
        scale_to_simulation(listParkings))
end

# %%
# %%
# %% ## $optimise\_simulation\_units()$ - Preparation of the Main Loop
# %%
# %% ### Preamble
# %%
# %% Each AGV will have:
# %%
# %% - a list of tasks with a list of release time.
# %%
# %% (BUSY WITH TASK --- RELEASE TIME)+ --- GO TO PARKING
# %%
# %% The number of busy times can be 0. Each AGV has a final release time.
# %%
# %%
# %% ### Initialisation
# %%
# %% - Using $M$, precompute 2D graph $\mathbb{G}$.
# %%
# %%
# %%
# %% - Using $M$, precompute $M_0$ with $T_{Max}$ slices.
# %%
# %%

function pre_computed_3DMatrix(
    M::AbstractMatrix{Int64},
    nSlices::Int64)::AbstractArray{Int64}

    return repeat(M, nSlices)
end

# %%
# %%
# %% - For each AGV, if it already has a task, calculate its completion time $time\ 2D(\mathbb{G}, \alpha_i, g_j)$. This is the starting point of the planning loops.
# %%
# %% - Initialise the list of tasks of each AGV to just initial position $PlanningList = [\alpha_i=[\alpha_{i, 0}]]$. Each $\alpha_i$ will grow with a list of tasks $\alpha_i = [\alpha_{i, 0}, \tau_{i, 1}, , \tau_{i, 2}, ...]$
# %%
# %% - $PlanningList = [\alpha_i]$ will later contain a list of AGVs $\alpha_i$ each containing their allocated tasks (if any). It does not contain the list of parking locations which may vary from iteration to iteration.
# %%
# %%
# %% ## Start Main Loop
# %%


function optimise_simulation_units(
    floor::FloorInfo,
    StepMax::Int64,
    listAGVs::AbstractVector{TAGV},
    listTasks::AbstractVector{TTask},
    simTimeFwd::Int64,
    simTimeBck::Int64,
    simTimeTrn::Int64,
    listParkings::AbstractVector{TParking})

    floorGraph = pre_computed_2Dgraph(floor)
    M0 = pre_computed_3DMatrix(floor, StepMax)


    unAllocatedTasks = deepcopy(listTasks)

    while true

        for current_task ∈ unAllocatedTasks

            # Start simulation at t = 0
            t::Int64 = 0
        end

        # Replicate a Repeat-Until loop
        isempty(unAllocatedTasks) && break
    end

    # ALERT: FINALISE RETURN FORMAT
    return Nothing
end

# %%
# %% $UnAllocatedTasks = ListTasks$ (That is the initial list of tasks)
# %%
# %%
# %% __REPEAT__ ------------------------------------------------------------------------------
# %%
# %%
# %% ### Optimal time for the best AGV/Task pair
# %%
# %% Planning time starts at time $t::Int64=0$.
# %%
# %%
# %% #### Assuming some tasks are not allocated yet
# %%
# %% $ListTimePairings = []$ will contain the list of times: time(AGV $\alpha_i$, unallocated task $\tau_j$)
# %%
# %%
# %% - For each Task $\tau_j$ in $UnAllocatedTasks != []$ (if $UnAllocatedTasks[]$ is not empty):
# %%
# %%   - For each $\alpha_i$:
# %%
# %%     - Take the time of where the AGV is: get the final position $current_i$ of $\alpha_i$, where $position_i$ is its initial position for the first iteration (if no task), or the position of its final release location $g_j$ given its list of tasks.
# %%
# %%     - Take the time to complete the new tasks: $offset_i = time\_2D(\mathbb{G}, \alpha_i, g_i)$ when the list of tasks is empty, $offset_i = \tau_{i, j}$ for $i$ being the last task in $\alpha_i$.
# %%
# %%     - Calculate $time(\alpha_i, g_j) = current_i + offset_i$
# %%
# %%     - Push the result (with all relevant information) into $ListTimePairings$
# %%
# %%
# %% #### Sort
# %%
# %% $ListTimePairings$ contains all the current $\alpha_i$ with each of them has been allocated a single new task. $ListTimePairings$ may be $[]$.
# %%
# %% - Sort all times in $ListTimePairings$ in increasing order and find the shortest. This is the only pair AGV / Task (if any) that will be added to the planning..
# %%
# %% - Add the task to that AGV with a time which is the one stored in $ListTimePairings$. Take the previous $PlanningList$ and replace the $\alpha_i$ which has a new task.
# %%
# %% - Reorder all the AGVs in decreasing order of total (including updated) release time. Store into  $PlanningList$.
# %%
# %%   - By construction, that list will contain all the tasks which were previously allocated + only one additional task.
# %%
# %%   - The list should only contain entries where there is a new task added to already existing $\alpha_i$. In other words, choosing an entry will always guarantee that only a single new task is added to the Planning List.
# %%
# %%   - We now have a new list of $\alpha_i=[\alpha_{i, 0}, \tau_{i, 1}, , \tau_{i, 2}, ...]$ where AT MOST ONE of them has an additional task. This is the list to be sorted in decreasing order of total time (total release time + time to achieve new task). ONLY ONE if a task was available or NOTHING if the list of tasks was empty to start with.
# %%
# %% - Remove the newly allocated task from $UnAllocatedTasks[]$.
# %%
# %%
# %% ### Planning Loop
# %%
# %% $ListAllocationParking = []$: To store all parking allocation as it happens one by one.
# %%
# %% $PlanningListWithParkings$: To store all the $\alpha_i$ with their respective parking before planning.
# %%
# %%
# %% #### Allocate parking locations
# %%
# %% Given the list of tasks and the parking position already allocated in $ListAllocationParking$, create list of remaining parking positions accounting.
# %%
# %% Looping on the AGVs, allocate to each $\alpha_i$ the closest parking $Parking_i$ from its last $\tau_{i, j}$ in its list of tasks. Push each into $PlanningListWithParkings$.
# %%
# %% Sort $PlanningListWithParkings$ in decreasing time order.
# %%
# %%
# %% #### Start planning loop
# %%
# %% $ListFullPath = []$: To store all paths one by one.
# %%
# %%
# %% __FOR__ ------------
# %%
# %% For each $\alpha_i \in PlanningList$:
# %%
# %% - $M_i = M_{i-1}$ (Note that $M_0$ is precalculated)
# %%
# %% - Add slices to $M_i$ so that at least $T_{Max}$ slices of buffer.
# %%
# %% __Create detailed plan for $Path_i$__
# %%
# %% - Reset the clock of the AGV: $t_i = 0$
# %%
# %% - Plan $PlanningListWithParkings[i]$ on $M_i$. The planning must record the times of the final realease time at which all tasks for that $\alpha_i$ are completed [CHECK: Is the time of parking to be recorded as well]. The result is $FullPath$. If not solution, raise error to increase $T_{Max}$.
# %%
# %% - Push $FullPath$ into $ListFullPath$
# %%
# %% - Push found path $FullPath$ into $M_i$ (i.e. obstruct that path).
# %%
# %% -  __NEXT__
# %%
# %% __UNTIL __ All tasks have been planned
# %%
# %%
# %%
# %% $optimise\_simulation\_units$: Return list of $\alpha_i=[\alpha_{i, 0}, \tau_{i, 1}, , \tau_{i, 2}, ...]$, and $ListFullPath$
# %%
# %%


# %% ----------
# %%
# %% # LOST BLOCK?
# %%
# %% $\tau()$ matrix can be done on 2D.
# %% TODO: However, the graph needs to be from 3D matrix without path back.
# %% - from the 3D matrix
# %% - without path back
# %% - provide turns. Means 2D for location + 1D (4 values) for direction + 1D for time.
# %% - when generating $generate_moves_2D$ needs also a counter reflecting how long an AGV stays in a loction going up / down, how long to turn once turning has been decided.
# %% - the changes from one node to the other is therefore highly dependent on AGV, therefore need to regenerate full matrix + graph for each path search.
# %%
# %% ----------


# %%
# %% # Path search
# %%
# %%
# %% ## 2D paths
# %%
# %%
# %% ### $time\_2D(\mathbb{G}, a, b)$
# %%
# %% - Time the optimal paths in 2D from location $a$ to $b$ in a precomputed graph $\mathbb{G}$ using Dijkstra.
# %% - All dimensions are in simulation dimensions.
# %% - Returns full path and total execution time.
# %%
# %% NOTE: This returns ONLY the path and does not in any time for pivoting towards the rack and loading/unloading.
# %%
# %%

function path_2D(
    G::SimpleWeightedDiGraph,
    start_v::Integer, dest_v::Integer)
    return enumerate_paths(dijkstra_shortest_paths(G, start_v), dest_v)
end

function path_2D(
    G::SimpleWeightedDiGraph,
    start::CartesianIndex{2}, start_dir::TDirection,
    dest::CartesianIndex{2}, dest_dir::TDirection,
    floor::FloorInfo)

    start_v = c2v(start, start_dir, floor)
    dest_v = c2v(dest, dest_dir, floor)
    return path_2D(G, start_v, dest_v)
end


# %% ### 2D move generator

# %% The function returns a list of Cartesian indices + direction + cost for each of the possible moves from a given position  = Move generator.
# %%
# %% For the moment, backward movements are provisional (need to think more about cost impact and propagation of AGV state over time). Might be as easy as decomposing complex tasks in sub-tasks, and just copy and paste pushing across time in 3D.
# %%

# [CHECK: Should never add a vertex which is already busy!!!!]
function generate_moves_2D(p::CartesianIndex{2}, d::TDirection, floor::FloorInfo)

    dr = 0
    dc = 0

    r = p[1]
    c = p[2]

    # All the moves are horizontal or vertical (no diagonal).
    # Result contains new position + new direction.
    # Change of direction is within a single cell.
    listMoves = []

    # Check (1) within bounds, (2) destination not empty and (3) directions
    # are compatible, then can accept move.

    # Go Up
    dr = -1
    dc = 0
    if r > 1
        if floor.plan[r + dr, c + dc] == LOCATION_EMPTY
            if d == Up
                push!(listMoves, (c2v(CartesianIndex(r + dr, c + dc), d, floor), simTimeFwd))
                # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)
            elseif d == Down
                push!(listMoves, (c2v(CartesianIndex(r + dr, c + dc), d, floor), simTimeBck))
                # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)
            end
        end
    end

    # Go down
    dr = 1
    dc = 0
    if r < floor.nRow
        if floor.plan[r + dr, c + dc] == LOCATION_EMPTY
            if d == Up
                push!(listMoves, (c2v(CartesianIndex(r + dr, c + dc), d, floor), simTimeBck))
                # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)
            elseif d == Down
                push!(listMoves, (c2v(CartesianIndex(r + dr, c + dc), d, floor), simTimeFwd))
                # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)
            end
        end
    end

    # Go left
    dr = 0
    dc = -1
    if c > 1
        if floor.plan[r + dr, c + dc] == LOCATION_EMPTY
            if d == Left
                push!(listMoves, (c2v(CartesianIndex(r + dr, c + dc), d, floor), simTimeFwd))
                # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)
            else d == Right
                push!(listMoves, (c2v(CartesianIndex(r + dr, c + dc), d, floor), simTimeBck))
                # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)
            end
        end
    end

    # Go towards right
    dr = 0
    dc = 1
    if c < floor.nCol
        if floor.plan[r + dr, c + dc] == LOCATION_EMPTY
            if d == Right
                push!(listMoves, (c2v(CartesianIndex(r + dr, c + dc), d, floor), simTimeFwd))
                # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)
            else d == Left
                push!(listMoves, (c2v(CartesianIndex(r + dr, c + dc), d, floor), simTimeBck))
                # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)
            end
        end
    end

    # Turn around. If not turning, waiting on the spot during 1 time step.
    dr = 0
    dc = 0
    if d == Up
        push!(listMoves, (c2v(CartesianIndex(r, c), Up,    floor), 1))
        push!(listMoves, (c2v(CartesianIndex(r, c), Left,  floor), simTimeTrn))
        push!(listMoves, (c2v(CartesianIndex(r, c), Right, floor), simTimeTrn))
        # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)

    elseif d == Right
        push!(listMoves, (c2v(CartesianIndex(r, c), Right, floor), 1))
        push!(listMoves, (c2v(CartesianIndex(r, c), Up,    floor), simTimeTrn))
        push!(listMoves, (c2v(CartesianIndex(r, c), Down,  floor), simTimeTrn))
        # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)

    elseif d == Down
        push!(listMoves, (c2v(CartesianIndex(r, c), Down,  floor), 1))
        push!(listMoves, (c2v(CartesianIndex(r, c), Right, floor), simTimeTrn))
        push!(listMoves, (c2v(CartesianIndex(r, c), Left,  floor), simTimeTrn))
        # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)

    elseif d == Left
        push!(listMoves, (c2v(CartesianIndex(r, c), Left,  floor), 1))
        push!(listMoves, (c2v(CartesianIndex(r, c), Down,  floor), simTimeTrn))
        push!(listMoves, (c2v(CartesianIndex(r, c), Up,    floor), simTimeTrn))
        # println("d: ", d, " r: ", r, " c: ", c, " dr: ", dr, " dc: ", dc)

    end

    return listMoves
end


# %%
# %% ### 2D graph creation (including directions)
# %%

function floorplan_to_2Dgraph(floor::FloorInfo)
    nRow = floor.nRow
    nCol = floor.nCol
    graph = SimpleWeightedDiGraph(nRow * nCol * nDirection)

    for row in 1:nRow,
        col in 1:nCol,
        direction in instances(TDirection)

        moves =  generate_moves_2D(CartesianIndex(row, col), direction, floor)
        # @show moves

        for (target, time_cost) in moves
            origin = c2v(CartesianIndex(row, col), direction, floor)

            # [TODO: To be extracted, generalised, cObstables pre-computed.]
            add_edge!(graph, origin, target, time_cost)
        end
    end

    return graph
end


# %% ### 2D path search
# %%
# %% Those methods only return the time to transit from one location to another. They do not calculate the time to load/unload.
# %%

# start and dest are CartesianIndex()
function path_a_b(
    start::CartesianIndex{2}, start_dir::TDirection,
    dest::CartesianIndex{2}, dest_dir::TDirection,
    floor::FloorInfo)

    #########################################################################
    # Generate graph:
    #   iterate through each position
    #   create an edge from there to each successive move (N, S, E, W).
    #   move into obstacles are penalised with 100, possible moves cost 1.
    #
    # Missing nodes are created automatically and not used?

    G = floorplan_to_2Dgraph(floor)

    # Path is from top left to bottom right
    path = path_2D(G, start, start_dir, dest, dest_dir, floor)
    path_time = sum(G.weights[i, i + 1] for i ∈ 1:length(path) - 1)

    # println("Solution has cost $(path_time):\n", path)

    return (G, path, path_time)
end

# %%
# %% Generic variations for different struct
# %%

function path_a_b(a::TPaletteLocation, p::TPaletteLocation, floor::FloorInfo)
    return path_a_b(
        a.loc.s, a.sideToFace,
        p.loc.s, p.sideToFace,
        floor)
end

function path_a_b(a::TAGV, p::TPaletteLocation, floor::FloorInfo)
    return path_a_b(
        a.current.s, a.current_direction,
        p.loc.s, p.sideToFace,
        floor)
end

function path_a_b(task::TTask, floor::FloorInfo)
    return path_a_b(task.start, task.target, floor)
end

# From AGV to start of task
function path_a_b(agv::TAGV, task::TTask, floor::FloorInfo)
    return path_a_b(
        agv.current.s, agv.current_direction,
        task.start.loc.s, task.start.sideToFace,
        floor)
end

# From end of task_a to the start of task b
function path_a_b(task_a::TTask, task_b::TTask, floor::FloorInfo)
    return path_a_b(task_a.target, task_b.start, floor)
end



# %%
# %% ## time3D
# %%
# %% Note:
# %%
# %%  - end point is a line in 3D. To arrive as early as possible means penalising delays. Transitions through time located at end point should be 0 when staying anywhere else costs time.
# %% - [https://stackoverflow.com/questions/48977068/how-to-add-free-edge-to-graph-in-lightgraphs-julia/48994712#48994712] Please pay attention to the fact that zero-weight edges are discarded by add_edge!. This is due to the way the graph is stored (a sparse matrix). A possible workaround is to set a very small weight instead.


# %% ### 2D move generator

# Returns a list of Cartesian indices for each of the possible moves from a
# given position  = Move generator.

# [TODO: LOGIC COMPLETELY WRONG TO GENERATE TIMES]
# [CHECK: Should never add a vertex which is already busy!!!!]
function next_moves_3D(p::CartesianIndex{3}, floor::FloorInfo, nsteps)
    x, y, t = p

    if t == nsteps
        return []
    end

    down = x > 1 ? x - 1 : x
    up = x < floor.nRow ? x + 1 : x
    left = y > 1 ? y - 1 : y
    right = y < floor.nCol ? y + 1 : y

    [TODO:CALCULATE TIME COST]
    time_cost = 1

    return [(CartesianIndex(x, y), time_cost) for x in down:up, y in left:right]
end


# %%
# %% ### 3D graph creation
# %%
# %% Graph creatiion is fundamentally about creating the right timecosts from vertex to vertex.
# %%

function floorplan_to_3Dgraph(floor::FloorInfo, nsteps, targetTask::TTask)
    nRow = floor.nRow
    nCol = floor.nCol
    graph = SimpleWeightedDiGraph(nRow * nCol * nsteps)

    vTargetTask = c2v(targetTask.target.loc.s, floor)

        for row ∈ 1:nRow,
        col ∈ 1:nCol,
        t ∈ 1:nsteps - 1
        (target3D, time_cost) ∈ next_moves_3D(CartesianIndex(row, col, t), floor)


        origin3D = CartesianIndex(row, col, t)
        origin2D = CartesianIndex(row, col)
        vOrigin2D = c2v(origin2D, floor)

        target2D = CartesianIndex(target3D[1], target3D[2])
        vTarget3D = c2v(target2D, floor)

        # WARNING: If transiting along the target, the minimum time $TTransitCostOnTarget$
        # BOTH LEGS OF THE TEST WORK ONLY BECAUSE $next\_moves\_3D$ DOES NOT INCLUDE BUSY VERTICES!!!!
        # BUT $next\_moves\_3D$ SHOULD ACTUALLY HAVE GENERATED THE RIGHT COST.
        if vOrigin2D == vTarget2D && vTarget2D == vTargetTask
            add_edge!(graph, c2v(origin3D, floor, nsteps),
                             c2v(target3D, floor, nsteps), TTransitCostOnTarget)
        else
            add_edge!(graph, c2v(origin3D, floor, nsteps),
                             c2v(target3D, floor, nsteps), time_cost)
        end
    end

    return graph
end



# %% ### 3D path search


# start and dest are CartesianIndex{3}
function path_a_b(
    start::CartesianIndex{2}, start_dir::TDirection,
    dest::CartesianIndex{2}, dest_dir::TDirection,
    nsteps,
     floor::FloorInfo)

    #########################################################################
    # Generate graph:
    #   iterate through each position
    #   create an edge from there to each successive move (N, S, E, W).
    #   move into obstacles are penalised with 100, possible moves cost 1.
    #
    # Missing nodes are created automatically and not used?

    G = floorplan_to_3Dgraph(floor, nsteps)

    # Path is from top left to bottom right
    path = path_2D(G, start, dest, floor)
    path_time = sum(map(v -> (v in vFloorPlanObstacles(floor) ? 100 : 1), path[2:end]))

    # println("Solution has cost $(path_time):\n", v2c_path(path, floor))

    return (path_time, G, v2c_path(path, floor))
end


# ' ------
# ' title: Algorithm for Multi-AGVs Flow Optimisation
# ' author: Emmanuel RIALLAND - ALBA INTELLIGENCE Hong Kong
# ' date: 2021
# ' weave_options:
# '     title: "Algorithm of Multi-AGVs Flow Optimisation"
# '     author: "Emmanuel RIALLAND - ALBA INTELLIGENCE HONG KONG"
# '     date: `j import Dates; Dates.Date(Dates.now())`
# '
# '     # documentclass: book
# '     fontfamily: roboto
# '     mainfont: GilliusADFNo2
# '     pandoc_options:
# '         table-of-contents
# '         number-sections
# '         reference-links
# '         mainfont: GilliusADFNo2
# '     wrap: true
# ' pandoc_options:
# '     table-of-contents
# '     number-sections
# '     reference-links
# '     mainfont: GilliusADFNo2
# ' fontfamily: GilliusADFNo2
# ' mainfont: GilliusADFNo2
# '
# ' ------
