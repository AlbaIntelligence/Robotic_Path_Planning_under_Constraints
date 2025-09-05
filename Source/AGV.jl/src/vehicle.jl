"""
$(TYPEDFIELDS)

### AGV:

- ID number: Known at algo start
- Initial position: ``TCoord`` Known at algo start
- Current position: ``TCoord``.
- Final position: ``TCoord``.
- Final time stamp: ``TTime`` [CHECK: Eventually needed?]
- State:

- ``forkHeight``: how high the fork currently is (in shelf simulation units!) since movements up or down can be interrupted at any time for replanning.
- ``isLoaded``: ``Bool``
- ``isFreeToGo``:: ``Bool`` - is the AGV facing a shelf but otherwise ready to go (about to load or after loading, but no idea where to go).

- List of tasks as list of tuples allocated to that AGV: Initialised empty

- [TODO: More TBD]
- Task ID

- time ``TTime`` in simulation units from previous step to reach task. The list is updated at each iteration using the release time calculated by A*. ``t = 0`` at the start.

- Allocated parking . Full structure for the moment. (Maybe ``Parking_{ID}`` later?).
"""
@with_kw struct TAGV
    ID::String = ""
    loc::TCoord = TCoord()
    dir::TDirection = Right

    time::TTime = TTime()

    forkHeight::THeight = THeight
    isLoaded::Bool = false
    isFreeToGo::Bool = false

    listTasks::AbstractVector{TTask} = TTask[]
    park::TLocation = TLocation()

end


"""
$(TYPEDSIGNATURES)

"""
as_rc(a::TAGV)::Trc = Trc(a.loc.s[1], a.loc.s[2])
as_rcd(a::TAGV)::Trcd = Trcd(a.loc.s[1], a.loc.s[2], Int64(a.dir))
as_rcdt(a::TAGV, t::Int64)::Trcdt = Trcdt(a.loc.s[1], a.loc.s[2], Int64(a.dir), t)


"""
$(TYPEDSIGNATURES)

"""
function AGV2Task(agv::TAGV)::TTask
    TTask(
        "AGV_" * string(agv.ID) * "_START",
        TLocation(agv.ID, agv.loc, agv.forkHeight, agv.dir, true, agv.isLoaded),
        TLocation(agv.ID, agv.loc, agv.forkHeight, agv.dir, true, agv.isLoaded),
    )
end


"""
$(TYPEDSIGNATURES)

paletting_time(h::THeight)::Int32 = Int32(STEPS_LEVEL * h.simh + STEPS_INOUT)
"""
paletting_time(h::THeight)::Int64 = STEPS_LEVEL + STEPS_INOUT
paletting_time(p::TLocation)::Int64 = paletting_time(p.height)
