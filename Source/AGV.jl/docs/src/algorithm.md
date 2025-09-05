# Algorithm

## Expected inputs

All inputs are in Standardised dimensions.

- ``F``: _Required_ Floor plan matrix
- ``ListAGV``: _Required_. Check list length >= 1
- ``ListTasks = []``: _Required_. List length can be 0. Must include the list of tasks that are already allocated at the start of the simulation.
- ``ListOfParking = create\_list\_of\_parkings(length(ListAGV))``: _Optional_ List of parking slots. Created if missing.
- Speeds: _Required_ forward, backward, turn


## Wrapping

First call point is ``optimise\_standardised\_units()``.

### Timing and Sizing parameters 

Estimate adequate time step ``t_{step}`` to scaled matrix to ``M``. [CHECK: Default to 200ms]

Max simulation time ``T_{Max}``: This time will be used when planning a path. It has to be long enough so that, given any configuration, A* will find a path from any current position, to achieve any task and go to any parking position. Currently 300s (converted to simulation time using ``t_{step}`` in ``{Step}_{Max}``). Track A* failures to check if long enough. 

``{Step}_{Max} = T_{Max} / t_{step}`` is the depth of the 3D planning matrix.

``GridSize``: 

- size of each simulation square. AGV dimensions = +/- 1/2 width, +/- 1/2 length.

- Ensures never jumps over even max speed.


### Scale everything to Simulation dimensions

Rescale all relevant values from Standardised to Simulation: 

- Matrix of the full floor plan: ``M = Rescale(F)``

- Same for ``ListOfParkings = [Parking_i]``, ``\alpha_i``, ``s_j``, ``g_j`` to be appropriately scaled given ``t_{step}``.

### Call main algo in simulation units

Call ``optimise\_simulation\_units()``


### Scale everything back to standardise units

Rescale all relevant values from Simulation to Standardised


### Return

Results are returned in Standardised units.


# Algorithm 2

``UnAllocatedTasks = ListTasks`` (That is the initial list of tasks)


__REPEAT__ ------------------------------------------------------------------------------


### Optimal time for the best AGV/Task pair

Planning time starts at time `t::Int64=1`.


#### Assuming some tasks are not allocated yet

`ListTimePairings = []` will contain the list of times: time(AGV ``\alpha_i``, unallocated task ``\tau_j``)


- For each Task ``\tau_j`` in ``UnAllocatedTasks != []`` (if ``UnAllocatedTasks[]`` is not empty):

  - For each ``\alpha_i``:
  
    - Take the time of where the AGV is: get the final position ``current_i`` of ``\alpha_i``, where ``position_i`` is its initial position for the first iteration (if no task), or the position of its final release location ``g_j`` given its list of tasks.

    - Take the time to complete the new tasks: ``offset_i = time\_2D(\mathbb{G}, \alpha_i, g_i)`` when the list of tasks is empty, ``offset_i = \tau_{i, j}`` for ``i`` being the last task in ``\alpha_i``. 

    - Calculate ``time(\alpha_i, g_j) = current_i + offset_i``
    
    - Push the result (with all relevant information) into `ListTimePairings`


#### Sort

``ListTimePairings`` contains all the current ``\alpha_i`` with each of them has been allocated a single new task. ``ListTimePairings`` may be ``[]``.

- Sort all times in ``ListTimePairings`` in increasing order and find the shortest. This is the only pair AGV / Task (if any) that will be added to the planning..

- Add the task to that AGV with a time which is the one stored in ``ListTimePairings``. Take the previous ``PlanningList`` and replace the ``\alpha_i`` which has a new task.

- Reorder all the AGVs in decreasing order of total (including updated) release time. Store into  ``PlanningList``.

  - By construction, that list will contain all the tasks which were previously allocated + only one additional task.

  - The list should only contain entries where there is a new task added to already existing ``\alpha_i``. In other words, choosing an entry will always guarantee that only a single new task is added to the Planning List.

  - We now have a new list of ``\alpha_i=[\alpha_{i, 0}, \tau_{i, 1}, , \tau_{i, 2}, ...]`` where AT MOST ONE of them has an additional task. This is the list to be sorted in decreasing order of total time (total release time + time to achieve new task). ONLY ONE if a task was available or NOTHING if the list of tasks was empty to start with.

- Remove the newly allocated task from ``UnAllocatedTasks[]``.


### Planning Loop

``ListAllocationParking = []``: To store all parking allocation as it happens one by one.

``PlanningListWithParkings``: To store all the ``\alpha_i`` with their respective parking before planning.


#### Allocate parking locations

Given the list of tasks and the parking position already allocated in ``ListAllocationParking``, create list of remaining parking positions accounting. 

Looping on the AGVs, allocate to each ``\alpha_i`` the closest parking ``Parking_i`` from its last ``\tau_{i, j}`` in its list of tasks. Push each into ``PlanningListWithParkings``.

Sort ``PlanningListWithParkings`` in decreasing time order.


#### Start planning loop

``ListFullPath = []``: To store all paths one by one.


__FOR__ ------------

For each ``\alpha_i \in PlanningList``:

- ``M_i = M_{i-1}`` (Note that ``M_0`` is precalculated)

- Add slices to ``M_i`` so that at least ``T_{Max}`` slices of buffer.

__Create detailed plan for ``Path_i``__

- Reset the clock of the AGV: ``t_i = 0``

- Plan ``PlanningListWithParkings[i]`` on ``M_i``. The planning must record the times of the final realease time at which all tasks for that ``\alpha_i`` are completed [CHECK: Is the time of parking to be recorded as well]. The result is ``FullPath``. If not solution, raise error to increase ``T_{Max}``.
  
- Push ``FullPath`` into ``ListFullPath``

- Push found path ``FullPath`` into ``M_i`` (i.e. obstruct that path). 

-  __NEXT__

__UNTIL __ All tasks have been planned



``optimise\_simulation\_units``: Return list of ``\alpha_i=[\alpha_{i, 0}, \tau_{i, 1}, , \tau_{i, 2}, ...]``, and ``ListFullPath``

