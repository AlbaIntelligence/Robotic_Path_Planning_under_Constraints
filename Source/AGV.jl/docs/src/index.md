# _gits/AGV.jl

Documentation for _gits/AGV.jl


## [TODO]

- For the moment, provision for backward movements in the move generators (need to think about cost impact and propagation of AGV state over time). Might be as easy as decomposing complex tasks in sub-tasks, and just copy and paste pushing across time in 3D.

- Delete simTime constants once tests finished.

- Refactor path planning algo (`path_a_b_3D` and `SIPP` as subtypes of `AbstractPathPlanning`). Modify `CalculationContext` accordingly.

## [IN PROGRESS]

- Consider variants to A* - Anytime*

## [DONE]

- CHANGE ALL TO CartesianCoordinates

## NOTES

- Single planning (next task allocation): matrix 2D because only sorting by distance (cost = time) without considering collisions.

- Multiple planning: 3D

- ``T_{Max}`` is currently fixed at 300s. It could just be a minimum to be dynamically increased if A* search is unsuccessful.

- There is a time padding of +/- 3 steps around each occupancy for safety. Specified in `fill_obtacles()`



