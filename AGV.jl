
Tmax = 5 * 60

struct TLocation
    x::Float32
    y::Float32
    simx::Int32
    simy::Int32
end

struct TTime
    t::Float32
    simt::Int32
end

@enum TDirection begin
    Up
    Down
    Left
    Right
end


struct TParking
    ID::String
    loc::TLocation
end

struct TPalette
    loc::TLocation
    onRack::Bool
    level::Int16
end
  
struct TTask
    ID::String
    start::TPalette
    target::TPalette
end

struct TAGV
    ID::String
    start::TLocation
    current::TLocation
    target::TLocation

    time::TTime

    direction::TDirection
    isLoaded::Bool
    isSideways::Bool

    listTasks::Vector{TTask}
    park::TParking
end



@. Int32(ceil( (1.0/50) * [ 1.2 2.2 ; 4.3 5.9]))

