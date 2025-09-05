"""
$(TYPEDFIELDS)

- Enum: [Up, Right, Down, Left]

!!! WARNING
    - Numbering is important to match 1-indexing using Cartesian indices
    - The direction have to rotate by 90 deg clockwise. Critical assumption when generating moves.
"""
@enum TDirection begin
    Up = 1
    Right = 2
    Down = 3
    Left = 4

end
const nDirection = 4


"""
$(TYPEDSIGNATURES)

"""
function TDirection(; d::Integer = 1)::TDirection
    @assert 1 ≤ d ≤ 4

    if d === 1
        return Up
    elseif d === 2
        return Right
    elseif d === 3
        return Down
    elseif d === 4
        return Left
    end
end


"""
$(TYPEDSIGNATURES)

"""
Base.print(io::IO, ::Type{TDirection}) = print(io, "")
Base.print(io::IO, d::TDirection) = print(io, ["↑", "→", "↓", "←"][Int64(d)])


"""
$(TYPEDSIGNATURES)

"""
function turn90(d::TDirection)::TDirection
    if d === Up
        return Right
    elseif d === Right
        return Down
    elseif d === Down
        return Left
    elseif d === Left
        return Up
    end
end
turn90(d::Int64)::Int64 = Int64(turn90(TDirection(d)))


"""
$(TYPEDSIGNATURES)

"""
function turn180(d::TDirection)::TDirection
    if d === Up
        return Down
    elseif d === Right
        return Left
    elseif d === Down
        return Up
    elseif d === Left
        return Right
    end
end
turn180(d::Int64)::Int64 = Int64(turn180(TDirection(d)))


"""
$(TYPEDSIGNATURES)

"""
function turn270(d::TDirection)::TDirection
    if d === Up
        return Left
    elseif d === Left
        return Down
    elseif d === Down
        return Right
    elseif d === Right
        return Up
    end
end
turn270(d::Int64)::Int64 = Int64(turn270(TDirection(d)))


"""
$(TYPEDFIELDS)

Path and coordinates in RCDT dims
"""
Trc = CartesianIndex{2}
Trcd = CartesianIndex{3}
Trct = CartesianIndex{3}
Trcdt = CartesianIndex{4}

TPath_rc = Vector{Trc}
TPath_rcd = Vector{Trcd}
TPath_rct = Vector{Trct}
TPath_rcdt = Vector{Trcdt}
TPathList_rcdt = Vector{Tuple{Trcdt,Int64}}


"""
$(TYPEDSIGNATURES)

"""
as_rc(r::Int64, c::Int64)::Trc = Trc(r, c)
as_rc(rcd::Trcd)::Trc = Trc(rcd[1], rcd[2])
as_rc(rcdt::Trcdt)::Trc = Trc(rcdt[1], rcdt[2])


"""
$(TYPEDSIGNATURES)

"""
as_rcd(r::Int64, c::Int64, d::TDirection)::Trcd = Trcd(r, c, Int64(d))
as_rcd(rc::Trc, d::TDirection)::Trcd = Trcd(rc[1], rc[2], Int64(d))


"""
$(TYPEDSIGNATURES)

"""
function as_rcd(rcdt::Trcdt)::Trcd
    r, c, d, _ = unpack(rcdt)
    return Trcd(r, c, d)
end


"""
$(TYPEDSIGNATURES)

"""
as_rcdt(rcdt::CartesianIndex{4})::Trcdt = Trcdt(rcdt[1], rcdt[2], rcdt[3], rcdt[4])
as_rcdt(r::Int64, c::Int64, d::Int64, t::Int64)::Trcdt = Trcdt(r, c, d, t)
as_rcdt(r::Int64, c::Int64, d::TDirection, t::Int64)::Trcdt = Trcdt(r, c, Int64(d), t)
as_rcdt(rc::Trc, d::TDirection, t::Int64)::Trcdt = Trcdt(rc[1], rc[2], Int64(d), t)

"""
$(TYPEDSIGNATURES)

"""
function as_rcdt(rcd::Trcd, t::Int64)::Trcdt
    r, c, d = unpack(rcd)
    return as_rcdt(r, c, d, t)
end


"""
$(TYPEDSIGNATURES)

"""
function as_rct(rcdt::Trcdt)::Trct
    r, c, _, t = unpack(rcdt)
    return Trct(r, c, t)
end


"""
$(TYPEDSIGNATURES)

"""
unpack(v::Trc) = v[1], v[2]
unpack(v::Trcd) = v[1], v[2], v[3]
unpack(v::Trct) = v[1], v[2], v[3]
unpack(v::Trcdt) = v[1], v[2], v[3], v[4]


"""
$(TYPEDSIGNATURES)

"""
function is_identical_locations(src::Trc, dst::Trc)::Bool
    src_r, src_c = unpack(src)
    dst_r, dst_c = unpack(dst)

    return src_r == dst_r && src_c == dst_c
end

"""
$(TYPEDSIGNATURES)

"""
function is_identical_locations(src::Trcd, dst::Trcd)::Bool
    src_r, src_c, src_d = unpack(src)
    dst_r, dst_c, dst_d = unpack(dst)

    return src_r == dst_r && src_c == dst_c && src_d == dst_d
end

"""
$(TYPEDSIGNATURES)

"""
function is_identical_locations(src::Trcdt, dst::Trcdt)::Bool
    src_r, src_c, src_d, _ = unpack(src)
    dst_r, dst_c, dst_d, _ = unpack(dst)

    return src_r == dst_r && src_c == dst_c && src_d == dst_d
end



"""
$(TYPEDFIELDS)

Structure to represent a move
"""
@with_kw struct TMove
    from::Trcdt = as_rcdt(1, 1, Right, 0)
    dest::Trcdt = as_rcdt(1, 1, Right, 0)
    steps::Int64 = 0
    cost::Int64 = 0
end


"""
$(TYPEDFIELDS)

Coding of locations within floorplan matrices
"""
@enum TLOCATION_FILL begin
    LOC_EMPTY = 0
    LOC_WALL = 1
    LOC_PALETTE = 2
    LOC_CONVEYOR = 3

    LOC_PARKING_UP = 4
    LOC_PARKING_RIGHT = 5
    LOC_PARKING_DOWN = 6
    LOC_PARKING_LEFT = 7

    LOC_RESERVED = 8
    LOC_BUSY = 9
end

const LOCATIONS_INFO = [
    # Location Name     Enum    Rendering   can be occupied?
    LOC_EMPTY 0 ' ' true
    LOC_WALL 1 '■' false
    LOC_PALETTE 2 '=' false
    LOC_CONVEYOR 3 'X' false
    LOC_PARKING_UP 4 '⮝' true
    LOC_PARKING_RIGHT 5 '⮞' true
    LOC_PARKING_DOWN 6 '⮟' true
    LOC_PARKING_LEFT 7 '⮜' true
    LOC_RESERVED 8 ' ' false
    LOC_BUSY 9 '○' false
]


const LOC_RENDERING_SYMBOLS = [LOCATIONS_INFO[i, 3] for i ∈ 1:size(LOCATIONS_INFO)[1]]

"""
$(TYPEDSIGNATURES)

"""
Base.string(io::IO, l::TLOCATION_FILL) = LOC_RENDERING_SYMBOLS[1+Int64(l)]
Base.print(io::IO, ::Type{TLOCATION_FILL}) = print(io, "")
Base.print(io::IO, l::TLOCATION_FILL) = print(io, LOC_RENDERING_SYMBOLS[1+Int64(l)])

const LOC_CAN_BE_OCCUPIED =
    [LOCATIONS_INFO[i, 1] for i ∈ 1:size(LOCATIONS_INFO)[1] if LOCATIONS_INFO[i, 4]]

# TODO: Refactor is_location_empty and can_be_occupied into a single underlying function???
"""
$(TYPEDSIGNATURES)

"""
@inline can_be_occupied(l::TLOCATION_FILL)::Bool = (l ∈ LOC_CAN_BE_OCCUPIED)


"""
$(TYPEDSIGNATURES)

When generating turns, there is generally no point to turn and face a wall. Currently, there are 2 exceptions:

- If the AGV is blocked and can only get out by doing a U-turn
- If the AGV needs to turn to face and access a Palette.
"""
function can_face_after_turning(l::TLOCATION_FILL)::Bool
    return l ∉ [LOC_WALL, LOC_BUSY]
end


"""
$(TYPEDFIELDS)

- ``x, y:: Float64`` for standardised units
- ``s = Trc(simx, simx::Int64)`` for simulation units

"""


"""
$(TYPEDFIELDS)

"""
abstract type AbstractLocation end


"""
$(TYPEDFIELDS)

"""@with_kw struct TCoord <: AbstractLocation
    x::Float64 = 1.0
    y::Float64 = 1.0
    s::Trc = as_rc(1, 1)
end


"""
$(TYPEDSIGNATURES)

"""
TCoord(rc::Trc)::TCoord = TCoord(Float64(rc[1]), Float64(rc[2]), rc)
TCoord(r::Int64, c::Int64)::TCoord = TCoord(Trc(r, c))


"""
$(TYPEDSIGNATURES)

"""
as_rc(coord::TCoord)::Trc = Trc(coord.s[1], coord.s[2])
as_rcd(l::TCoord, d::TDirection)::Trcd = Trcd(l.s[1], l.s[2], Int64(d))


"""
$(TYPEDSIGNATURES)

"""
Base.print(io::IO, ::Type{TCoord}) = print(io, "")
Base.string(l::TCoord) = "[($(l.x), $(l.y))/($(l.s[1]), $(l.s[2]))]"
Base.print(io::IO, l::TCoord) = print(io, Base.string(l))


"""
$(TYPEDFIELDS)

### Palette location (they do more than palettes!)

Palette locations is any spot that can have a palette.

- Conveyor or Delivery belt, Top or Bottom drop areas, Quay
- Which side of that location needs to be faced to pick up/drop. This is the face that the AGV needs to have to load/unload. If the rack is open towards the right, the AGV needs to face left and this is the direction recorded.

- ID
- Location: `TCoord`
- How high a paletter is located:.level is an Integer that wil be = 0 for ground located
- Whether the location is currently occupied. Logic for change of occupancy NOT implemented (see Assumptions)
- Whether an AGV is going up to pick it up, or down after that.

!!! check - NEED TO SEPARATE TIMES RELATED TO THE TASK PROVIDED BY THE QUEUING SYSTEM, VS. TIME CALCULATED FOR A GIVEN AGV MODEL.
"""
@with_kw struct TLocation <: AbstractLocation
    ID::String = ""

    loc::TCoord = TCoord(1, 1)
    height::THeight = THeight(0.0, 0)

    sideToFace::TDirection = Up
    isFull::Bool = false

    isOnAGV::Bool = false
end


"""
$(TYPEDSIGNATURES)

"""
function TLocation(type::String, r::Int64, c::Int64, d::TDirection)
    name = @sprintf("%s_%03d_%03d", type, r, c)
    return TLocation(name, TCoord(r, c), THeight(0.0, 0), d, false, false)
end


"""
$(TYPEDSIGNATURES)

"""
function Base.string(p::TLocation)
    "Palette(l= " *
    string(p.loc) *
    ", h=" *
    string(p.height) *
    ", d=" *
    string(p.sideToFace) *
    ")"
end

"""
$(TYPEDSIGNATURES)

"""
function Base.print(io::IO, ::Type{TLocation})
    print(io, "")
end
function Base.print(io::IO, p::TLocation)
    print(io, "Palette(l= " * p.loc * ", h=" * p.height * ", d=" * p.sideToFace * ")")
end


"""
$(TYPEDSIGNATURES)

"""
as_rc(p::TLocation)::Trc = Trc(p.loc.s[1], p.loc.s[2])

"""
$(TYPEDSIGNATURES)

"""
as_rcd(p::TLocation)::Trcd = Trcd(p.loc.s[1], p.loc.s[2], Int64(p.sideToFace))

"""
$(TYPEDSIGNATURES)

"""
as_rcdt(p::TLocation, t::Int64)::Trcdt =
    Trcdt(p.loc.s[1], p.loc.s[2], Int64(p.sideToFace), t)
