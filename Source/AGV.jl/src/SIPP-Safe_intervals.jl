"""
$(TYPEDFIELDS)

"""
SIPPInterval = Tuple{Int64,Int64}


"""
$(TYPEDFIELDS)

"""
mutable struct SIPPBusyIntervals
    ordering::Vector{Int64}
    segments::Vector{SIPPInterval}
    count::Int64
    N::Int64

    SIPPBusyIntervals() = SIPPBusyIntervals(MAX_NUMBER_BUSY_INTERVALS)
    SIPPBusyIntervals(ctx::TContext) = SIPPBusyIntervals(ctx.nSteps)

    function SIPPBusyIntervals(stackdepth::Int64)
        0 < stackdepth ≤ MAX_NUMBER_BUSY_INTERVALS ||
            @error "Stack depth must be between 1 and $(MAX_NUMBER_BUSY_INTERVALS)"

        # By default everything is empty. This should never disappear.
        o = zeros(Int64, stackdepth)
        s = [(0, 0) for _ = 1:stackdepth]
        return new(o, s, 0, stackdepth)
    end
end


"""
$(TYPEDSIGNATURES)

"""
Base.length(s::SIPPBusyIntervals) = s.count

"""
$(TYPEDSIGNATURES)

"""
Base.size(s::SIPPBusyIntervals) = s.N

"""
$(TYPEDSIGNATURES)

"""
Base.isempty(s::SIPPBusyIntervals) = length(s) == 0


"""
$(TYPEDSIGNATURES)

Push a segment of steps to be blocked in the list of busy intervals.
"""
function Base.push!(stack::SIPPBusyIntervals, entry::SIPPInterval)
    # The entry must be well ordered
    0 ≤ entry[1] || @error "The start of the interval $(entry) must be positive."
    entry[1] ≤ entry[2] || error("The start of the blockage at $(entry[1]) is higher than the end at $(entry[2]).")


    # Easy cases: empty or full stack
    length(stack) < size(stack) ||
        @error "Segment stack is already full with $(stack.count) elements. Cannot push additional segments."

    if stack.count == 0
        stack.count += 1
        stack.ordering[stack.count] = 1
        stack.segments[stack.count] = entry
        return
    end

    insertindex = 1

    # Look for first place where the entry's start is below
    while (insertindex ≤ stack.count) && (entry[1] > stack.segments[insertindex][1])
        insertindex += 1
    end

    # Then, if same start, look for first place where the entry's end is below
    if entry[1] == stack.segments[insertindex][1]
        while (insertindex ≤ stack.count) &&
                  (entry[1] == stack.segments[insertindex][1]) &&
                  (entry[2] > stack.segments[insertindex][2])
            insertindex += 1
        end
    end

    # Insert at this index: make room then insert in the list of segments
    for i ∈ stack.N-1:-1:insertindex
        stack.segments[i+1] = stack.segments[i]
    end
    stack.segments[insertindex] = entry

    # Adjust the ordering
    for i = 1:stack.count
        stack.ordering[i] += stack.ordering[i] ≥ insertindex ? 1 : 0
    end
    stack.count += 1
    stack.ordering[stack.count] = insertindex
end


"""
$(TYPEDSIGNATURES)

Pops the last included interval. Return `nothing` if nothing to pop.
"""
function Base.pop!(stack::SIPPBusyIntervals)::Union{SIPPInterval,Nothing}
    stack.count == 0 && return nothing

    idx = stack.ordering[stack.count]
    seg = stack.segments[idx]

    stack.segments[idx] = (0, 0)

    # Adjust the ordering
    stack.ordering[stack.count] = 0
    stack.count -= 1
    for i = 1:stack.count
        stack.ordering[i] -= stack.ordering[i] > idx ? 1 : 0
    end
    return seg
end


"""
$(TYPEDSIGNATURES)

"""
function Base.delete!(stack::SIPPBusyIntervals, entry::SIPPInterval)::Union{SIPPInterval,Nothing}
    # Find entry is list of intervals
    interval_location = findfirst([seg == entry for seg ∈ stack.segments])
    interval_location === nothing && return nothing

    # delete interval at this index; copy over; reset last value
    for j ∈ interval_location:stack.count-1
        stack.segments[stack.ordering[j]] = stack.segments[stack.ordering[j+1]]
    end
    stack.segments[stack.ordering[stack.count]] = (0, 0)

    # Find insertion time in ordering
    insertion_time = findfirst([loc == interval_location for loc ∈ stack.ordering])
    insertion_time === nothing && return nothing

    for j ∈ insertion_time:stack.count-1
        stack.ordering[j] = stack.ordering[j+1]
    end
    stack.ordering[stack.count] = 0

    # Adjust the insertion times in ordering
    stack.count -= 1
    for j = 1:stack.count
        stack.ordering[j] -= stack.ordering[j] > j ? 1 : 0
    end

    return entry
end


"""
$(TYPEDSIGNATURES)

"""
function Base.delete!(stack::SIPPBusyIntervals, entries::Vector{SIPPInterval})::Vector{Union{Nothing,SIPPInterval}}
    return [delete!(stack, entry) for entry ∈ entries]
end


"""
$(TYPEDSIGNATURES)

The resulting list of safe intervals are NOT shifted.

`time_shift` is used to remove anything before the shift. By construction, the list is sorted first by the time of
start of the interval, then by the time of end. This order relies on the (tested) expectation that push! is also
ordered.
"""
function list_safe_intervals(stack::SIPPBusyIntervals, nSteps::Int64; time_shift::Int64 = 0)::Vector{SIPPInterval}
    # If no intervals, returns a single maximum span of free intervals
    length(stack) == 0 && return SIPPInterval[(0, nSteps)]

    result = SIPPInterval[]

    # Initial free stub
    # The loop starts from the first busy interval, having pushed any free space before it.
    # The list of times starts at 0. If stack.segments[1][1] == 1, we would push (0, 0). That's useless. Hence (1, time_shift)
    if 1 < stack.segments[1][1] && time_shift < stack.segments[1][1]
        push!(result, (max(0, time_shift), stack.segments[1][1] - 1))
    end

    interval_idx = 1
    while interval_idx < length(stack)
        # There is a free space only if the end of the current interval ends strictly before the
        # beginning of the next.
        # Relies on the construction guarantees of `push!`
        if max(stack.segments[interval_idx][2] + 1, time_shift) < stack.segments[interval_idx+1][1] - 1
            push!(result, (max(stack.segments[interval_idx][2] + 1, time_shift), stack.segments[interval_idx+1][1] - 1))
        end
        interval_idx += 1
    end

    # Check if there is a final stub.
    if max(stack.segments[length(stack)][2] + 1, time_shift) < nSteps - 1
        push!(result, (max(stack.segments[length(stack)][2] + 1, time_shift + 1), nSteps))

    end
    return result
end


"""
$(TYPEDSIGNATURES)

"""
list_safe_intervals(stack::SIPPBusyIntervals, ctx::TContext; time_shift::Int64 = 0) =
    list_safe_intervals(stack, ctx.nSteps; time_shift = time_shift)


"""
$(TYPEDSIGNATURES)

Returns the interval containing a particular time
"""
function containing_interval(list_intervals::Vector{SIPPInterval}, t::Int64)::Union{SIPPInterval,Nothing}
    for (start, final) ∈ list_intervals
        if start ≤ t < final
            return (start, final)

        end
    end
    return nothing
end
