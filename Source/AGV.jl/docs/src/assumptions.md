
# Assumptions

- Everything in SI.

- Time-step short enough to never have jump-overs even at full speed.

- AGV dimensions approximated in multiple of twice the grid so that all dimensions / tests can be done as centre location +/- value in integers.

- AGV dimensions include palettes.

- Should include security perimeter monitored by AGV?

- All standardised dimensions in floating point. All simulation dimensions in integers. Type mistakes are easier to pick up.

- Dimensions of the floor plan is in units of the gridsize.

- Once a palette is taken off a shelf, it cannot be put back (putting back might mess up warehouse software and really not obvious is a lot of time would actually be saved).

- Basically, any movement up or dowm to do anything will not be cancelled or replanned half-way through.

- The logic to track if any TPaletteLocation is occupied or not is ignored. We rely on the warehousing software to track that for us.

- Transition time on target location $TTransitCostOnTarget$ = 0.001 = 1ms since nil weight on a graph means no edge.


