"""
$(TYPEDFIELDS)

### Tasks: Know at algo start

- Task ID ([TODO: Transform to data type])
- Location start (``s_j``): ``TCoord``, ``onrack``, ``level``. ``level`` only in on racks (``onrack == true``)
- Location target (``g_j``): ``TCoord``, ``onrack``, ``level``. ``level`` only in on racks (``onrack == true``)
"""
struct TTask
    ID::String
    start::TLocation
    target::TLocation
end


"""
$(TYPEDSIGNATURES)

"""
Base.print(io::IO, t::TTask) = @printf(
    io,
    "Task[%s].  From: %s (%3d, %3d, %s, %2d) to: %s (%3d, %3d, %s, %2d)",
    t.ID,
    t.start.ID,
    t.start.loc.s[1],
    t.start.loc.s[2],
    string(t.start.sideToFace),
    t.start.height.simh,
    t.target.ID,
    t.target.loc.s[1],
    t.target.loc.s[2],
    string(t.target.sideToFace),
    t.target.height.simh
)


"""
$(TYPEDSIGNATURES)

List of tasks with final arrival time
"""
TTaskList = Vector{TTask}


"""
$(TYPEDFIELDS)

"""
struct TPlanStep
    task::TTask                     # Task to be completed at the end of this step
    path::TPath_rcdt                # Detailed path to achieve that task
    time_completed::Int64           # Time
end


"""
$(TYPEDFIELDS)

"""
mutable struct TPlan
    steps::Vector{TPlanStep}
    parking::TLocation       # Escape parking
    path_to_park::TPath_rcdt        # Path to parking
    time_at_parking::Int64          # Final time at parking
end


"""
$(TYPEDSIGNATURES)

"""
function is_identical_locations(src::TLocation, dst::TLocation)::Bool
    src_r = src.loc.s[1]
    src_c = src.loc.s[2]
    src_d = Int64(src.sideToFace)

    # To as CartesianIndex (without time)
    dst_r = dst.loc.s[1]
    dst_c = dst.loc.s[2]
    dst_d = Int64(dst.sideToFace)

    return src_r == dst_r && src_c == dst_c && src_d == dst_d
end


"""
$(TYPEDSIGNATURES)

"""
function is_identical_locations(src::TTask, dst::TTask)::Bool
    src_r = src.target.loc.s[1]
    src_c = src.target.loc.s[2]
    src_d = Int64(src.target.sideToFace)

    # To as CartesianIndex (without time)
    dst_r = dst.target.loc.s[1]
    dst_c = dst.target.loc.s[2]
    dst_d = Int64(dst.target.sideToFace)

    return src_r == dst_r && src_c == dst_c && src_d == dst_d
end


"""
$(TYPEDSIGNATURES)

Converts a parking into a task.
A parking is much simpler: go there, load nothing, stay there, unload nothing.
"""
function TTask(p::TLocation)::TTask
    return TTask(
        p.ID,
        # The From is important to make sure that the time cost of executing
        # a parking as a task is nothing.
        # Ditto for heights.
        TLocation(
            p.ID,                           # ID
            p.loc,                          # Where
            THeight(0.0, 0),                # Height
            p.sideToFace,                   # Side to face
            true,
            false,
        ),
        TLocation(
            p.ID,                           # ID
            p.loc,                          # Where
            THeight(0.0, 0),                # Height
            p.sideToFace,                   # Side to face
            true,
            false,
        ),
    )                   # Not relevant
end
