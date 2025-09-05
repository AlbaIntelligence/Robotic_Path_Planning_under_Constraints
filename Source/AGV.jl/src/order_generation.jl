"""
1 - Poisson with mean = p/h
2 - At each blip generate random
3 - Visible list is what is available on loanding bay and all the otherwise
"""
const N_PALLETTE_PER_HOUR = 50
poisson_lambda(; n_palettes = N_PALLETTE_PER_HOUR) = 3600 / n_palettes

# All types or orders. Sum of percentages = 100%
const ORDER_TYPE_1_CONV2RACK = 1
const PCT_1_CONV2RACK = 0.46

const ORDER_TYPE_2_CONV2QUAY = 2
const PCT_2_CONV2QUAY = 0.12

const ORDER_TYPE_3_RACK2BACK = 3
const PCT_3_RACK2BACK = 0.28

const ORDER_TYPE_4_RACK2GRND = 4
const PCT_4_RACK2GRND = 0.14

order_type!() =
    rand(Categorical([PCT_1_CONV2RACK, PCT_2_CONV2QUAY, PCT_3_RACK2BACK, PCT_4_RACK2GRND]))


"""
$(TYPEDSIGNATURES)

"""
function random_special_location!(
    list_name::String,
    context::TContext;
    make_random_level = false,
)
    list_special = context.special_locations[list_name]
    sl = list_special[rand(Categorical(length(list_special)))]

    # The location is the location of the special item. It is not the location of the access
    r, c, d = unpack(as_rcd(sl))
    dir = TDirection(d)

    if dir == Up
        r = r + 1
    elseif dir == Down
        r = r - 1
    elseif dir == Right
        c = c - 1
    elseif dir == Left
        c = c + 1
    end

    level = make_random_level ? rand(Categorical(1 + MAX_RACK_LEVELS)) - 1 : 0

    TLocation(sl.ID, TCoord(r, c), THeight(Float64(level), level), dir, false, false)
end


"""
$(TYPEDSIGNATURES)

"""
function format_palette_location(type::String, r, c, d::TDirection, l)::TLocation
    name = @sprintf("%s__%03d_%03d_LVL_%03d", type, r, c, l)
    return TLocation(
        name,
        TCoord(Float64(r), Float64(c), (r, c)),
        THeight(Float64(l), l),
        d,
        true,
        false,
    )
end


"""
$(TYPEDSIGNATURES)

"""
function generate_order!(order_number, context::TContext)::TTask
    ot = order_type!()
    if ot == ORDER_TYPE_1_CONV2RACK
        task_name = @sprintf("ORDER_%05d_CONV2RACK", order_number)
        order = TTask(
            task_name,
            random_special_location!("conveyor", context),
            random_special_location!("rack", context; make_random_level = true),
        )

    elseif ot == ORDER_TYPE_2_CONV2QUAY
        task_name = @sprintf("ORDER_%05d_CONV2QUAY", order_number)
        order = TTask(
            task_name,
            random_special_location!("conveyor", context),
            random_special_location!("quay", context),
        )

    elseif ot == ORDER_TYPE_3_RACK2BACK
        task_name = @sprintf("ORDER_%05d_RACK2BACK", order_number)
        order = TTask(
            task_name,
            random_special_location!("rack", context; make_random_level = true),
            random_special_location!("back", context),
        )

    elseif ot == ORDER_TYPE_4_RACK2GRND
        task_name = @sprintf("ORDER_%05d_RACK2GRND", order_number)
        order = TTask(
            task_name,
            random_special_location!("rack", context; make_random_level = true),
            random_special_location!("ground", context),
        )

    end

    @info @sprintf("\n***ORDER*** %s\n", string(order))
    return order
end
