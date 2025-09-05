"""
$(TYPEDSIGNATURES)

Return a formatted string of the current timer value.
"""
function stimer()::String
    p = 0.0
    try
        p = peektimer()
    catch
    end

    return @sprintf("% 16.6f", p)
end



"""
$(TYPEDSIGNATURES)

Reciprocal conversions between simulation coordinates and node numbers.
Coordinates are expressed in ``Trc``. Nodes are vertices expessed as ``Int64``
Conversions in 2 dimensions
"""
@inline function c2v_rc(p::Trc, ctx::TContext)::Int64
    nRow = ctx.nRow

    r, c = unpack(p)
    r = r - 1
    c = c - 1
    c *= nRow

    # Beware of 0 vs. 1 indexing
    return r + c + 1
end
c2v_rc(l::TCoord, ctx::TContext)::Int64 = c2v_rc(TCoord.s, ctx)
c2v_rc(p::TLocation, ctx::TContext)::Int64 = c2v_rc(p.loc, ctx)


"""
$(TYPEDSIGNATURES)

"""
@inline function v2c_rc(v::Integer, ctx::TContext)::Trc
    nRow = ctx.nRow

    v0 = v - 1

    # Beware of 0 vs. 1 indexing
    c = div(v0, nRow)
    r = rem(v0, nRow)
    return Trc(r + 1, c + 1)
end


"""
$(TYPEDSIGNATURES)

# Given a list of vertices, return the coodinates of the path steps
"""
v2c_rc(path::TPath_rc, ctx::TContext) = [v2c_rc(v, ctx) for v in path]


"""
$(TYPEDSIGNATURES)

Conversions in 2 dimensions plus direction

(Beware of 0 vs. 1 indexing)
"""
@inline function c2v_rcd(p::Trcd, ctx::TContext)::Int64
    nRow = ctx.nRow
    nCol = ctx.nCol

    r, c, d = unpack(p)
    r = r - 1
    c = c - 1
    c = c * nRow
    d = d - 1
    d = d * nRow * nCol

    return r + c + d + 1
end
@inline function c2v_rcd(p::Trc, dir::TDirection, ctx::TContext)::Int64
    r, c = unpack(p)
    d = Int64(dir)

    return c2v_rcd(Trcd(r, c, d), ctx)
end
@inline function c2v_rcd(l::TCoord, dir::TDirection, ctx::TContext)::Int64
    r, c = l.s
    d = Int64(dir)
    return c2v_rcd(Trcd(r, c, d), ctx)
end
@inline function v2c_rcd(v::Integer, ctx::TContext)::Trcd

    nRow = ctx.nRow
    nCol = ctx.nCol

    # Beware of 0 vs. 1 indexing
    v0 = v - 1

    d = div(v0, nRow * nCol)
    dm = rem(v0, nRow * nCol)
    c = div(dm, nRow)
    r = rem(dm, nRow)

    return Trcd(r + 1, c + 1, d + 1)
end
@inline c2v_rcd(p::TLocation, dir::TDirection, ctx::TContext)::Int64 =
    c2v_rcd(p.loc, dir, ctx)
@inline c2v_rcd(v1::Any, v2::Any, calctx::AbstractCalculationContext) =
    c2v_rcd(v1, v2, calctx.ctx)


"""
$(TYPEDSIGNATURES)

Given a list of vertices, return the coodinates of the path steps
"""
v2c_rcd(path::TPath_rcd, ctx::TContext) = [v2c_rcd(v, ctx) for v in path]


"""
$(TYPEDSIGNATURES)

3 dimensions is the 2 (x, y) plus time. Beware of 0 vs. 1 indexing
"""
@inline function c2v_rct(p::Trct, ctx::TContext)::Int64
    nRow = ctx.nRow
    nCol = ctx.nCol

    r, c, t = unpack(p)

    r = r - 1
    c = c - 1
    c *= nRow
    t = t - 1
    t *= nCol * nRow

    return r + c + t + 1
end


"""
$(TYPEDSIGNATURES)

"""
@inline function c2v_rct(l::TCoord, time::TTime, ctx::TContext)::Int64
    x, y = l.s
    return c2v_rct(Trct(x, y, time.simt), ctx)
end
c2v_rct(p::TLocation, time::TTime, ctx::TContext)::Int64 = c2v_rct(p.loc, time, ctx)


"""
$(TYPEDSIGNATURES)

"""
@inline function v2c_rct(v::Integer, ctx::TContext)::Trct
    nRow = context.nRow
    nCol = context.nCol

    # Beware of 0 vs. 1 indexing
    v0 = v - 1

    t = div(v0, nCol * nRow)
    tm = rem(v0, nCol * nRow)
    c = div(tm, nRow)
    r = rem(tm, nRow)

    return Trct(r + 1, c + 1, t + 1)
end

"""
$(TYPEDSIGNATURES)

# Given a list of vertices, return the coodinates of the path steps
"""
v2c_rct(path::TPath_rct, ctx::TContext) = [v2c_rct(v, ctx) for v in path]


"""
$(TYPEDSIGNATURES)

Conversions in 4 dimensions

4 dimensions is the 2 (x, y) plus direction plus time

Beware of 0 vs. 1 indexing
"""
@inline function c2v_rcdt(p::Trcdt, ctx::TContext)::Int64
    nRow = ctx.nRow
    nCol = ctx.nCol
    nDir = nDirection
    nSteps = ctx.nSteps
    slice_size = ctx.slice_size

    r, c, d, t = unpack(p)

    r = r - 1
    c = c - 1
    c *= nRow
    d = d - 1
    d *= nCol * nRow
    t = t - 1
    t *= slice_size

    v = r + c + d + t + 1

    @assert v ≤ slice_size * nSteps "r, c, d, t, v = " * string(p) * " " * string(v)
    return v
end


"""
$(TYPEDSIGNATURES)

"""
@inline function c2v_rcdt(p::Trc, dir::TDirection, time::Int64, ctx::TContext)::Int64
    r, c = unpack(p)
    d = Int64(dir)

    return c2v_rcdt(Trcdt(r, c, d, time), ctx)
end


"""
$(TYPEDSIGNATURES)

"""
@inline function c2v_rcdt(l::TCoord, dir::TDirection, time::TTime, ctx::TContext)::Int64
    r, c = l.s
    d = Int64(dir)

    return c2v_rcdt(Trcdt(r, c, d, time.simt), ctx)
end
c2v_rcdt(p::TLocation, dir::TDirection, time::TTime, ctx::TContext)::Int64 =
    c2v_rcdt(p.loc, dir, time, ctx)
c2v_rcdt(r::Int64, c::Int64, d::Int64, t::Int64, ctx::TContext)::Int64 =
    c2v_rcdt(as_rcdt(r, c, d, t), ctx)


"""
$(TYPEDSIGNATURES)

"""
@inline function v2c_rcdt(v::Integer, ctx::TContext)::Trcdt
    nRow = ctx.nRow
    nCol = ctx.nCol
    nDir = nDirection
    slice_size = ctx.slice_size

    # Beware of 0 vs. 1 indexing
    v0 = v - 1

    t = div(v0, slice_size)
    tm = rem(v0, slice_size)
    d = div(tm, nCol * nRow)
    dm = rem(tm, nCol * nRow)
    c = div(dm, nRow)
    r = rem(dm, nRow)

    return Trcdt(r + 1, c + 1, d + 1, t + 1)
end


"""
$(TYPEDSIGNATURES)

# Given a list of vertices, return the coodinates of the path steps
"""
v2c_rcdt(path::AbstractVector{}, ctx::TContext) = [v2c_rcdt(v, ctx) for v in path]


"""
$(TYPEDSIGNATURES)

Create list of obstacles in Cartesian and vertex coordinates
"""
@inline function cFloorPlanObstacles(ctx::TContext)
    return [
        Trc(i, j) for i in 1:ctx.nRow, j in 1:ctx.nCol if !can_be_occupied(ctx.plan[i, j])
    ]
end


"""
$(TYPEDSIGNATURES)

"""
@inline function vFloorPlanObstacles(ctx::TContext)
    return [
        c2v_rc(Trc(i, j), ctx) for
        i in 1:ctx.nRow, j in 1:ctx.nCol if !can_be_occupied(ctx.plan[i, j])
    ]
end



"""
$(TYPEDSIGNATURES)

"""
pre_computed_3DMatrix(M::AbstractArray{Int64,2}, nSlices::Int64)::AbstractArray{Int64,3} =
    repeat(M, nSlices)


#######################################################################
#
#
"""
$(TYPEDSIGNATURES)

Creates a new copy of the TContext, without copying what will not
change
"""
function copy_context(ctx::TContext)::TContext

    # Shallow copy
    c = ctx

    c.nRow = ctx.nRow
    c.nCol = ctx.nCol
    c.nSteps = ctx.nSteps

    c.M3D = fill(LOC_EMPTY, size(ctx.M3D))
    c.M3D[:, :, end] .= LOC_BUSY

    c.G2DT = deepcopy(ctx.G2DT)
    c.G3DT = deepcopy(ctx.G3DT)

    c.UG3D = ctx.UG3D
    c.D = ctx.D
    c.jumpover_knockoff_vertices = ctx.jumpover_knockoff_vertices

    return c
end


"""
$(TYPEDSIGNATURES)

Remove all duplicates as the end of the path.
"""
function clean_end_path(path_c)

    if length(path_c) > 0
        clean_path = path_c

        dst_r, dst_c, dst_d = unpack(path_c[end])

        final_position = Trcd(dst_r, dst_c, dst_d)
        for i ∈ length(path_c)-1:-1:1
            src_r, src_c, src_d = unpack(path_c[i])
            if Trcd(src_r, src_c, src_d) != final_position
                clean_path = path_c[1:i+1]
                return clean_path
            end
        end
    end

    return []
end



"""
$(TYPEDSIGNATURES)

Returns a list of paths formatted as Cartesian indices and vertices and transition times.
"""
function format_path(path_v, path_w, time_shift, ctx)

    if path_v == []
        return [], [], []

    else
        path_rcdt = [v2c_rcdt(v, ctx) for v ∈ path_v]

        # Shift back into the future
        for i ∈ 1:length(path_rcdt)
            r, c, d, t = unpack(path_rcdt[i])
            path_rcdt[i] = Trcdt(r, c, d, t + time_shift)
        end

        # Create time stamps from transit cost
        path_times = append!([0], ceil.(cumsum(path_w) ./ STEP_TO_COST_MULTIPLIER))
        path_times = path_times .+ time_shift

        # Adjust times on the actual path
        path_rcdt =
            [as_rcdt(as_rcd(path_rcdt[i]), path_times[i]) for i ∈ 1:length(path_rcdt)]

        path_rcdt = clean_end_path(path_rcdt)
        l = length(path_rcdt)

        return path_rcdt, [], []
        # return path_rcdt, path_v[1:l], path_w[1:l-1]
    end
end



"""
$(TYPEDFIELDS)

Nicely formatted logger
Simplistic logger for logging all messages with level greater than or equal to
`min_level` to `stream`.
Methods are fully qualified because they are _used_ and not _imported_ in the module. Inspired by
the Julia `SimpleLogger` definition (see `[https://github.com/JuliaLang/julia/blob/master/base/logging.jl]()`)
"""
struct AGVLogger <: AbstractLogger
    stream::IO
    min_level::LogLevel

    # Instance variable.
    # Will store the number of remaining logs available until `:maxlog`
    message_limits::Dict{Any,Int}
end


"""
$(TYPEDSIGNATURES)

"""
AGVLogger(stream::IO = stderr, level = Logging.Error) =
    AGVLogger(stream, level, Dict{Any,Int}())


"""
$(TYPEDSIGNATURES)

"""
Logging.shouldlog(logger::AGVLogger, level, _module, group, id) =
    get(logger.message_limits, id, 1) > 0


"""
$(TYPEDSIGNATURES)

"""
Logging.min_enabled_level(logger::AGVLogger) = logger.min_level


"""
$(TYPEDSIGNATURES)

"""
Logging.catch_exceptions(logger::AGVLogger) = false


"""
$(TYPEDSIGNATURES)

"""
function Logging.handle_message(
    logger::AGVLogger,
    level::LogLevel,
    message,
    _module,
    group,
    id,
    filepath,
    line;
    kwargs...,
)

    @nospecialize

    maxlog = get(kwargs, :maxlog, nothing)

    if maxlog isa Core.BuiltinInts
        remaining = get!(logger.message_limits, id, Int(maxlog)::Int)
        logger.message_limits[id] = remaining - 1
        remaining > 0 || return
    end

    io_buffer = IOBuffer()
    io_context = IOContext(io_buffer, logger.stream)

    msglines = split(chomp(string(message)::String), '\n')

    # println(iob, "┌ ", levelstr, ": ", msglines[1])
    println(io_context, @sprintf("%8s: %s", string(level), msglines[1]))

    for i = 2:length(msglines)
        println(io_context, "        │ ", msglines[i])
    end

    for (key, val) in kwargs
        key === :maxlog && continue
        println(io_context, "        │   ", key, " = ", val)
    end

    # println(iob, "└ @ ", _module, " ", filepath, ":", line)

    write(logger.stream, take!(io_buffer))
    flush(logger.stream)
    nothing
end


"""
$(TYPEDSIGNATURES)

Check that every stop on the path is strictly posterior to the previous one.
"""
path_rcdt_is_stricly_increasing(path_rcdt::TPath_rcdt) =
    all([path_rcdt[i][4] < path_rcdt[i+1][4] for i = 1:length(path_rcdt)-1])
