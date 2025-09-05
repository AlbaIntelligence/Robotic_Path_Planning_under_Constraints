
include("AGV_markup.jl")

myPlan = Int64.([
    0 0 0 0 0 0 0 0 0 0 0 ;
    0 1 0 1 0 1 0 1 0 1 0 ;
    0 1 0 1 0 1 0 1 0 1 0 ;
    0 1 0 1 0 1 0 1 0 1 0 ;
    1 1 0 1 0 1 0 1 0 1 0 ;
    0 1 0 1 0 1 0 1 0 1 0 ;
    0 1 0 1 0 1 0 1 0 1 1 ;
    0 1 0 1 0 1 0 1 0 1 0 ;
    0 1 0 1 0 1 0 1 0 1 0 ;
    0 1 0 1 0 1 0 1 0 1 0 ;
    0 1 0 1 0 1 0 1 0 0 0 ;
    0 1 0 1 0 1 0 1 0 1 0 ;
    0 1 0 1 0 1 0 1 0 1 0 ;
    0 1 0 1 0 1 0 1 1 1 0 ;
    0 0 0 0 0 0 1 0 0 0 0 ])

myFloorInfo = FloorInfo(myPlan)
myG = floorplan_to_2Dgraph(myFloorInfo)


#######################################################################
#
# Check generate_moves_2D
#
generate_moves_2D(CartesianIndex(1, 1), Right, myFloorInfo)

# Path
g, p, t = path_a_b(CartesianIndex(1, 1), Right, CartesianIndex(15, 11), Right, myFloorInfo)

v2c(p[3], true, myFloorInfo)

function path2graphic(path, myFloorInfo)
    printPath = Matrix{Char}(undef, size(myFloorInfo.plan)) .= '.'

    for o ∈ cFloorPlanObstacles(myFloorInfo)
        printPath[o] = '█'
    end

    for e ∈ path
        # @show v2c(e, true, myFloorInfo)
        c = v2c(e, true, myFloorInfo)[1]
        v::TDirection = v2c(e, true, myFloorInfo)[2]
        if v == Down
            printPath[c] = 'D'
        elseif v == Up
            printPath[c] = 'U'
        elseif v == Right
            printPath[c] = 'R'
        else v == Left
            printPath[c] = 'L'
        end
    end

    return printPath
end


printPath = path2graphic(p, myFloorInfo)
for row in 1:myFloorInfo.nRow
    for col in 1:myFloorInfo.nCol
        print(printPath[row, col])
    end
    println()
end
