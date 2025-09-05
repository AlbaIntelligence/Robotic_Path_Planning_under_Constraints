# The SIPP algorithm

Anytime A* is a variant of A* 

## A*

For reference, A* follows _states_, each of which represent the state of an agent exploring an environment.
Typically, this is a position in space and time. 

Although the search is best imagined to start from an initial position, it can also be run backwards from
the goal position in cases where the map to explore is known in advance. Searching from the goal node 
requires inverting the generation of nodes to nodes, or similarly inverting the graph describing the changes
from state to state (an expensive operation, especially if the graph is represented as a sparse matrix). 
However, this initial time/computation investment is worthy as it substantially speeds up the future
searches.

From an initial state, A* explores its succesors, that is agents in following position and the time to reach
each new position. In details:

- For each explored state, A* maintains the path that enabled reaching that particular node (normally a 
chain of parent states).

- each new state is marked `ToBeExplored` (traditionally stored in a priority queue called `OPEN` (a priority queue
is a set of items with an associated value, where items can be efficiently poped out in order of value of the items)).

- when exploring any state, A* keeps track of the actual cost of reaching that state (by adding all costs of every 
successive cost to reach that state).

- when investigating `ToBeExplored` states, A* prioritises the most promising states first. The priority is 
given to states that have, at least in first approximation, the lowest total cost to reach the goal. At this 
point, a `ToBeExplored` state is given an estimation of the total cost (of the path from start to goal going through 
this `ToBeExplored` state) is the cost of reaching that state plus an estimation reaching the goal from that 
`ToBeExplored` state.

- The cost of reaching the `ToBeExplored` state is the cost of reaching its parent state plus the cost of
transfering from the parent state to the `ToBeExplored` state. This value is kept for future use (to determine 
the final cost of the path path improvement - see below).

- The estimate of the cost to reach the goal is given by a _heuristic_ function provided by the programmer. It 
could be based of a Euclidian distance (or variant thereof with different powers).

- Afterwards, the `ToBeExplored` state is marked as `Expanded` state (traditionally stored in a set called `CLOSE`).

- When chosing the next `ToBeExplored` state, A* looks at _all_ the states in the `ToBeExplored` priority queue, 
and choses the one with the cheapest current estimated cost (hence the need for a priority queue). The chosen state
could be one of the most recently expanded ones, but could equally be states expanded a long time ago. Only the best 
current estimate matters, not recency of expansion.

- It might the case that the graphs includes cycles (different paths to reach the same state). In that case, 
the new cost of reaching that state (cost from start to that state) is compared to the cost that had
been previously calculated (following the previous path(s)). If the cost is no better, no point in changing anything.
If the cost is better, the cost of the state is amended to the new value and the `Expanded` state is move from the 
`Expanded` set to the `ToBeExplored` priority queue.

- Setting aside the situation of cycles, previous states are never re-valued. Once expanded, they are possibly 
in the final path. Therefore, once confirmed in the `Expanded` set, we are done with those states. It might the 
case that those states will not belong to the final path. This is similar to a typical exploration. A* is, in a sense, 
_only_ a way to chose which part of the tree to explore first (by expanding the most promising states first)

One way to look at the algorithm is that it targets the goal with a best estimate (using the heuristic function) and
refines the actual cost as and when it is confirmed by summing all individual costs of moving through an
actual cost. A* is a methid to prioritise the exploration of the tree of states. It will eventually explore the 
entire tree (if the goal is not found before). Whenever the goal is found, the path is provably the best and the search
can stop; there is no point in further exploration of the state tree.

A* provably yields the best path to goal. This is great, but this requires exploring all the possible paths. 
It is often the case that an approximate path is enough if we can get some comfort on how far we are 
from tha best path. This can be the case where: the estimate comes with the benefit of a substantial 
reduction in calculation time, or, it stands to reason that an optimal path would actually be not very far 
from that best solution (e.g. alternative paths would be a lot more expensive than the approximation, therefore
there is a high probability that the approximation is actually the best).


## Anytime A*

Anytime A* improves on standard A*. It uses 2 heuristic functions: one identical to A*. Another lower 
one by decreasing the cost-to-current-state. This makes the goal extremely attractive regardless of how it is reached 
while minimising the cost of getting there. The purpose is to very quickly find an initial path no matter how good. 
Afterwards, it then provides the possibility to use the provably correct heuristics of A* to converge towards the optimal path.


The concept of the algorithm is to find a path (any path!) reaching the goal and then incrementally improve on that 
path by narrowing the difference between the two heuristics. The approximate path will converge as and when the 
difference becomes minimal. Reducing the difference `squeezes` the approximation towards the (yet unknown) ideal path.
(This is reminiscent of the Lasso linear regression.)

If the process of reducing the difference is stopped before being nil, the algorithm provides guarantees with respect to 
the cost difference between the path, i.e. how far the approximation is from the unknown optimal.

The implementation of the algorithm bears similarities to A*. The actual search for a path is identical apart 
from:

- the choice of heuristic function (where the cost of reaching a state is reduced in importance).

- and pushing two states (with the two heuristics) in the `ToBeExplored` priority queue and keeping track of which
state is potentially optimal (associated with the optimal heuristic) and which state is sub-optimal (pontentially 
inconsistent in the litterature).

Separately, another part of Anytime A* describes a recommanded way to narrow the difference between the two heuristics.

Whereas A* is laser-focused (but requires running to completion to yield the optimal solution), Anytime A* 
prefers to have looser explorations which can substantially increases the number of states to be expanded, with 
the benefit of yielding a successions of paths as and when the difference between the heuristics is reduced. 
The succession of searches can be stopped when within acceptable bounds, or importantly in time-critical situations
where a searches need to provide (any) solution at specific times (e.g. a fleet of flying quad-copters avoiding collisions
requires reaction times of 10ms-100ms).

However, the basic Anytime A* explores many unnecessary states. Many improvements to the alogithm have been proposed to 
reduce that exploration space while retaining guaranties of bounded convergence. Other improvements focus on the properties
of the heuristic function.

Note that both algorithms are dedicated to a _single_ path search. In case of multiple simultaneous and conflicting path
(_Multi-Agent Path Finding_, same fleet of quad-copters), we need further harnessing.  This is typically achieved by 
prioritising sequential searches of individual paths. The priorities are worked out at each step depending on detected upcoming
conflicts.No parallel and efficient global algorithm is used unless presenting the problem in the form of 
Mixed Integer Linear Programming or Satisfiability Modulo Theories. Both are theoretically great, at the cost of often hours of calculation. 


Below, we use different notations and formalism than the typical presentation for clarity sake. The traditional 
presentation follows A* which dates from 1968. It is not the clearest when discovering the mechanics.

Because we use two heuristics, we will want to possibly explore the same state twice (once with each heuristic).
We will therefore push into the `ToBeExplored` priority queue the same state twice, but with 2 different total 
cost estimates. 
