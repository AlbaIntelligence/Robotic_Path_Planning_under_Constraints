"""
Docstring of the [`AGV`](@ref) module itself.

List of exported symbols [`EXPORTS`](@ref):

$(EXPORTS)

Required imports:

$(IMPORTS)

Under License:

[`LICENSE`](@ref) as in the `LICENSE.md` file.

"""
module AGV

using Documenter, DocStringExtensions

using Logging, Dates, Printf, TickTock, Parameters
using DataStructures, Distributions
using SparseArrays, LightGraphs, SimpleWeightedGraphs

# Necessary to extend methods on SIPPSafeIntervals
using Base: push!, pop!, isempty

# No idea why error is thrown because missing constructors. Scattergun method definitions.
SimpleWeightedGraphs.SimpleWeightedEdge{UInt64,Int64}(x::UInt64, y::UInt64) =
    SimpleWeightedGraphs.SimpleWeightedEdge{UInt64,Int64}(x, y, one(Float64))

SimpleWeightedGraphs.SimpleWeightedEdge{UInt64,Int64}(x::Int64, y::UInt64) =
    SimpleWeightedGraphs.SimpleWeightedEdge{UInt64,Int64}(UInt64(x), y, one(Float64))

SimpleWeightedGraphs.SimpleWeightedEdge{UInt64,Int64}(x::UInt64, y::Int64) =
    SimpleWeightedGraphs.SimpleWeightedEdge{UInt64,Int64}(x, UInt64(y), one(Float64))

SimpleWeightedGraphs.SimpleWeightedEdge{UInt64,Int64}(x::Int64, y::Int64) =
    SimpleWeightedGraphs.SimpleWeightedEdge{UInt64,Int64}(
        UInt64(x),
        UInt64(y),
        one(Float64),
    )

SimpleWeightedGraphs.SimpleWeightedEdge{Int64,Int64}(x::UInt64, y::UInt64) =
    SimpleWeightedGraphs.SimpleWeightedEdge{Int64,Int64}(x, y, one(Float64))

SimpleWeightedGraphs.SimpleWeightedEdge{Int64,Int64}(x::Int64, y::UInt64) =
    SimpleWeightedGraphs.SimpleWeightedEdge{Int64,Int64}(UInt64(x), y, one(Float64))

SimpleWeightedGraphs.SimpleWeightedEdge{Int64,Int64}(x::UInt64, y::Int64) =
    SimpleWeightedGraphs.SimpleWeightedEdge{Int64,Int64}(x, UInt64(y), one(Float64))

SimpleWeightedGraphs.SimpleWeightedEdge{Int64,Int64}(x::Int64, y::Int64) =
    SimpleWeightedGraphs.SimpleWeightedEdge{Int64,Int64}(UInt64(x), UInt64(y), one(Float64))




export TCoord,

    # Type definitions
    Trc,
    Trcd,
    Trct,
    Trcdt,
    TPath_rcdt,
    TPathList_rcdt,
    unpack,
    as_rc,
    as_rcd,
    as_rcdt,
    TTask,
    TTaskList,
    TPlan,
    TPlanList,
    TAGV,
    TLocation,
    TParking,
    THeight,
    TTime,


    # Context / plan
    find_side_to_face,

    # utilities
    c2v_rc,
    v2c_rc,
    c2v_rct,
    v2c_rct,
    c2v_rcd,
    v2c_rcd,
    c2v_rcdt,
    v2c_rcdt,

    # Logging
    stimer,
    AGVLogger,
    shouldlog,
    min_enabled_level,
    catch_exceptions,
    handle_message,

    # graph manipulation
    vertices2edgenum,
    vertices2weight,
    edgenum2vertices,

    # Types and constants.
    STEPS_REMAIN,
    STEPS_FWD,
    STEPS_BCK,
    STEPS_TRN,
    STEPS_IMPOSSIBLE,
    STEPS_LEVEL,
    STEPS_INOUT,
    STEPS_MAX_TO_KNOCKOUT,
    STEP_SAFETY_BUFFER,
    STEP_TO_COST_MULTIPLIER,
    COST_REMAIN,
    COST_FWD,
    COST_BCK,
    COST_TRN,
    COST_IMPOSSIBLE,
    COST_LEVEL,
    COST_INOUT,
    COST_IMPOSSIBLE,
    COST_STAY_ON_PARKING,
    COST_WARP_TRAVEL,
    COST_INOUT,
    TIME_MULTIPLIER,


    # Related to warehouse
    # Note: enums need to export all symbols.
    MAX_RACK_LEVELS,
    TLOCATION_FILL,
    LOC_EMPTY,
    LOC_PALETTE,
    LOC_CONVEYOR,
    LOC_WALL,
    LOC_PARKING,
    LOC_PARKING_UP,
    LOC_PARKING_RIGHT,
    LOC_PARKING_DOWN,
    LOC_PARKING_LEFT,
    LOC_BUSY,
    LOCATIONS_INFO,
    LOC_RENDERING_SYMBOLS,
    LOC_CAN_BE_OCCUPIED,
    can_be_occupied,
    is_location_empty,
    is_location_parking,
    TDirection,
    Up,
    Down,
    Left,
    Right,
    nDirection,

    # Floor/Context manipulation
    AbstractCalculationContext,
    STEPS_MAX_TO_KNOCKOUT,
    TContext,
    copy_context,
    listParkings,
    list_time_segments,
    generate_jumpover_knockoff_vertices,
    jumpover_knockoff_v_pairs,
    turn90,
    turn180,
    turn270,

    # 2D
    path_a_b_2D,
    path_vertices,
    clean_end_path_2D,
    cFloorPlanObstacles,
    vFloorPlanObstacles,
    format_path,


    # 3D
    floorplan_to_matrix_3D,
    floorplan_to_graphs,
    generate_moves,
    check_and_add_moves,
    check_and_add_turns,


    # Planning
    AbstractPathPlanning,
    MAX_PATH_LENGTH,
    path_planning,
    initialise_tasks,
    create_initial_plans,
    create_initial_parkings_allocation!,
    path_2_list_edges,
    assign_impossible_weight_to_vertices!,
    warp_travel_to_destination!,
    time_available_at_location,
    generate_moves,
    path_a_b_3D,
    clean_end_path,
    task_optimal_perf,
    plan_task,
    list_cost_to_reach_3D,
    is_not_reachable,
    reacheability,
    fill_blockages!,

    # A-*
    create_calculation_context,
    A_Star,
    astar!,
    astar_impl!,
    reconstruct_path!,


    # Segment stack
    MAX_NUMBER_BUSY_INTERVALS,
    SIPPBusyIntervals,
    push!,
    pop!,
    fill_blockages,
    list_safe_intervals,
    containing_interval,

    # SIPP
    SIPPState,
    SIPPStateContext,
    SIPP_CalculationContext,
    AnytimeSIPP,
    state_heuristic,
    Φ,
    occupancy_at_location,
    anytime_SIPP,


    # AStar Main loop
    list_competion_times,
    listParkings,
    full_allocation,

    # SIPP Main loop
    # SIPP_full_allocation,


    # Rendering
    describe_plan,
    describe_planning,
    path_c_2_graphic,
    print_render,
    render_plan_at_time,


    # Testing
    check_full_allocation,
    check_path,
    check_paths,


    # Simulation
    poisson_lambda,
    ORDER_TYPE_1_CONV2RACK,
    PCT_1_CONV2RACK,
    ORDER_TYPE_2_CONV2QUAY,
    PCT_2_CONV2QUAY,
    ORDER_TYPE_3_RACK2BACK,
    PCT_3_RACK2BACK,
    ORDER_TYPE_4_RACK2GRND,
    PCT_4_RACK2GRND,
    generate_order!,


    # Analysis
    planstep_timing,
    describe_plan,
    describe_planning,
    check_path,
    is_step_change,
    list_nonsingle_step_changes


# File includes
include("global-constants.jl")
include("base_structs.jl")

include("location.jl")
include("task.jl")
include("vehicle.jl")

include("global-context.jl")
include("global-context_utilities.jl")

include("A_Star-graph.jl")
include("A_Star-calculation_context.jl")
include("A_Star-path_planning_2D.jl")
include("A_Star-path_planning_3D.jl")
include("A_Star-path_planning.jl")

include("SIPP-State.jl")
include("SIPP-Safe_intervals.jl")
include("SIPP-calculation_context.jl")
include("SIPP-path_planning.jl")

include("path_planning.jl")

include("mainloop.jl")

include("rendering.jl")
include("order_generation.jl")

include("analysis.jl")

end
