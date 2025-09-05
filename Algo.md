# Overview of the algo

## 1.1 Create parking positions

Sort rest position where:

- least needed in proportion of most used.
- all different
- at least one per AGV. Split according to proportions?
- Necessary to guarantee that searches will always find solution, i.e. parking positions do not prevent any traffic.

## 1.1 Main Loop 

### 1.1.1 Parking position

Create list of parking positions accounting for:

- Most used (prepared by 1.1)
- Currently staffed
  - Used currently actually staffed?
  - Used currently time-to-be-staffed (who is allocated and how far away?)

### 1.1.1 List of AGV/task couples

#### 1.1.1.1 Allocated AGV

For each already allocated AGV_i:

- Get $j$: Already allocated to $\tau_j = (s_j, g_j)$
- Calculate time($\alpha_i$, $g_j$) with A* [TODO: CHECK ALTERNATIVES TO A*]

#### 1.1.1.1 Free AGV

For each couple AGV $(\alpha_i, \tau_j)$:

- Already allocated to $\tau_j = (s_j, g_j)$
- Calculate time($\alpha_i$, $g_j$) = time($\alpha_i$, $s_j$) + time($\alpha_i$, $g_j$) 

#### 1.1.1.1 Sort

Sort all times in decreasing order: 

$L_1 = [ (\alpha_i, point_1, point_2, point_3, ...) ]$

#### 1.1.1.1 Planning Loop

For each $Path_i \in L-1$