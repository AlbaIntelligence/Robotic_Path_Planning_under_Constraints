# AGV Multi-Agent Flow Optimization System

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Julia](https://img.shields.io/badge/Julia-1.8%2B-purple.svg)](https://julialang.org/)
[![Status](https://img.shields.io/badge/Status-Research%20Project-orange.svg)](https://github.com/your-repo)

A sophisticated **Automated Guided Vehicle (AGV) Multi-Agent Flow Optimization System** developed for warehouse automation and logistics optimization. This system implements advanced pathfinding algorithms including A*, Theta A*, (interruptable A* with approximation bounds) and SIPP (Safe Interval Path Planning) to coordinate multiple AGVs in dynamic warehouse environments under uncertain order queue.

## 🚀 Features

### Core Algorithms

- **A* Pathfinding**: Optimal path planning in 2D and 3D space-time environments
- **SIPP (Safe Interval Path Planning)**: Dynamic path planning with collision avoidance
- **3D Planning**: Time-aware pathfinding incorporating temporal constraints
- **Multi-Agent Coordination**: Simultaneous optimization of multiple AGV paths
- **Task Allocation**: Intelligent assignment of tasks to available AGVs

### System Capabilities

- **Warehouse Simulation**: Complete warehouse floor plan modeling with obstacles
- **Real-time Planning**: Dynamic replanning as new tasks arrive
- **Collision Avoidance**: Guaranteed collision-free path execution
- **Performance Optimization**: Minimization of total completion time
- **Visualization**: Real-time rendering of AGV movements and warehouse state

## 📋 Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [System Architecture](#system-architecture)
- [Algorithms](#algorithms)
- [Configuration](#configuration)
- [Examples](#examples)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [License](#license)
- [Citation](#citation)

## 🛠 Installation

### Prerequisites

- **Julia 1.8+**: Download from [julialang.org](https://julialang.org/downloads/)
- **Git**: For cloning the repository

### Installation Steps

1. **Clone the repository**:

   ```bash
   git clone https://github.com/your-username/AGV-Robotic_Path_Planning_under_Constraints.git
   cd AGV-Robotic_Path_Planning_under_Constraints
   ```

2. **Start Julia and activate the project**:

   ```julia
   julia --project=.
   ```

3. **Install dependencies**:

   ```julia
   using Pkg
   Pkg.instantiate()
   ```

4. **Verify installation**:

   ```julia
   include("AGV.jl")
   ```

### Dependencies

The system requires the following Julia packages:

- `LightGraphs.jl` - Graph algorithms and data structures
- `SimpleWeightedGraphs.jl` - Weighted graph implementations
- `Weave.jl` - Documentation generation
- `Luxor.jl` - 2D graphics and visualization

## 🚀 Quick Start

### Basic Usage

```julia
using AGV

# Load a warehouse floor plan
floor_plan = load_floor_plan("data/warehouse.txt")

# Create AGV fleet
agvs = [
    TAGV("AGV1", start_location, current_location, target_location, ...),
    TAGV("AGV2", start_location, current_location, target_location, ...)
]

# Define tasks
tasks = [
    TTask("Task1", start_palette, target_palette),
    TTask("Task2", start_palette, target_palette)
]

# Run optimization
result = optimize_agv_flow(floor_plan, agvs, tasks)

# Visualize results
render_simulation(result)
```

### Example: Simple Warehouse

```julia
# Create a simple 10x10 warehouse
floor_plan = create_simple_warehouse(10, 10)

# Add one AGV at position (1,1)
agv = create_agv("AGV1", (1, 1), Up)

# Create a task from (2,2) to (8,8)
task = create_task("Task1", (2, 2), (8, 8))

# Plan the path
path = plan_path(floor_plan, agv, task)

# Execute and visualize
execute_plan([agv], [task], floor_plan)
```

## 🏗 System Architecture

### Core Components

```
AGV System
├── Path Planning
│   ├── A* Algorithm (2D/3D)
│   ├── SIPP Algorithm
│   └── Collision Detection
├── Task Management
│   ├── Task Allocation
│   ├── Priority Scheduling
│   └── Resource Management
├── Simulation Engine
│   ├── Time Management
│   ├── State Tracking
│   └── Event Processing
└── Visualization
    ├── Real-time Rendering
    ├── Path Visualization
    └── Performance Metrics
```

### Data Structures

#### Core Types

- `TLocation`: Position in 2D space (x, y coordinates)
- `TTime`: Temporal information with simulation and standard units
- `TDirection`: AGV orientation (Up, Down, Left, Right)
- `TAGV`: AGV state including position, direction, and task list
- `TTask`: Task definition with start and target locations
- `TPaletteLocation`: Palette/pickup point with height and orientation

#### Planning Structures

- `FloorInfo`: Warehouse layout with obstacle information
- `SIPPState`: Safe interval path planning state
- `AStarContext`: A* algorithm context and heuristics

## 🧮 Algorithms

### A* Pathfinding

The system implements A* in both 2D and 3D environments:

- **2D A***: For static pathfinding without temporal constraints
- **3D A***: For time-aware pathfinding with collision avoidance
- **Heuristics**: Manhattan distance and custom warehouse-specific heuristics

```julia
# 2D A* example
path_2d = astar_2d(floor_plan, start_pos, goal_pos)

# 3D A* with time constraints
path_3d = astar_3d(floor_plan, start_state, goal_state, time_limit)
```

### SIPP (Safe Interval Path Planning)

SIPP enables dynamic path planning in environments with moving obstacles:

- **Safe Intervals**: Time windows when locations are collision-free
- **Dynamic Replanning**: Adaptation to changing warehouse conditions
- **Anytime Algorithm**: Provides solutions with bounded optimality

```julia
# SIPP planning
sipp_result = sipp_plan(floor_plan, agv, task, obstacles)
```

### Multi-Agent Coordination

The system coordinates multiple AGVs through:

1. **Task Allocation**: Optimal assignment of tasks to AGVs
2. **Path Coordination**: Ensuring collision-free simultaneous execution
3. **Priority Management**: Handling task priorities and deadlines

## ⚙️ Configuration

### System Parameters

```julia
# Timing parameters
const Tmax = 5 * 60  # Maximum simulation time (5 minutes)
const TStep = 0.50   # Time step size (0.5 seconds)

# AGV specifications
const AGVLength = 4.0  # AGV length in meters
const AGVWidth = 3.0   # AGV width in meters

# Movement costs
const simTimeFwd = 1   # Forward movement cost
const simTimeBck = 4   # Backward movement cost
const simTimeTrn = 10  # Turn cost
```

### Warehouse Configuration

```julia
# Floor plan encoding
const LOCATION_EMPTY = 0  # Free space
const LOCATION_BUSY = 1   # Obstacle/occupied

# Create custom warehouse
warehouse = [
    0 0 0 1 0 0 0;
    0 1 0 1 0 1 0;
    0 0 0 0 0 0 0;
    1 1 0 0 0 1 1;
    0 0 0 0 0 0 0
]
```

## 📊 Examples

### Example 1: Single AGV Path Planning

```julia
# Create warehouse with obstacles
floor_plan = create_warehouse_with_obstacles(20, 20)

# Single AGV task
agv = TAGV("AGV1", TLocation(1, 1), TLocation(1, 1), TLocation(20, 20), ...)
task = TTask("Pickup", TPaletteLocation(5, 5), TPaletteLocation(15, 15))

# Plan and execute
result = plan_single_agv(floor_plan, agv, task)
visualize_path(result)
```

### Example 2: Multi-AGV Coordination

```julia
# Multiple AGVs and tasks
agvs = [create_agv("AGV$i", start_positions[i]) for i in 1:3]
tasks = [create_task("Task$i", start_locs[i], goal_locs[i]) for i in 1:5]

# Coordinate planning
coordinated_plan = coordinate_multi_agv(floor_plan, agvs, tasks)

# Execute with collision avoidance
execute_coordinated_plan(coordinated_plan)
```

### Example 3: Dynamic Task Assignment

```julia
# Simulate dynamic task arrival
simulator = AGVSimulator(floor_plan, agvs)

# Add tasks dynamically
add_task!(simulator, new_task)
add_task!(simulator, urgent_task, priority=HIGH)

# Run simulation
run_simulation!(simulator, duration=300)
```

## 📚 API Reference

### Core Functions

#### Path Planning

- `astar_2d(floor, start, goal)` - 2D A* pathfinding
- `astar_3d(floor, start, goal, time_limit)` - 3D A* pathfinding
- `sipp_plan(floor, agv, task, obstacles)` - SIPP planning
- `plan_path(floor, agv, task)` - High-level path planning

#### Task Management

- `allocate_tasks(agvs, tasks)` - Optimal task allocation
- `create_task(id, start, target)` - Create new task
- `update_task_priority(task, priority)` - Update task priority

#### Simulation

- `run_simulation(floor, agvs, tasks)` - Run complete simulation
- `step_simulation(state)` - Single simulation step
- `get_simulation_metrics(result)` - Extract performance metrics

#### Visualization

- `render_warehouse(floor)` - Render warehouse layout
- `visualize_paths(paths)` - Visualize AGV paths
- `animate_simulation(result)` - Create simulation animation

### Data Types

#### AGV State

```julia
struct TAGV
    ID::String
    start::TLocation
    current::TLocation
    target::TLocation
    time::TTime
    direction::TDirection
    forkHeight::THeight
    isLoaded::Bool
    isSideways::Bool
    listTasks::AbstractVector{TTask}
    park::TParking
    simSpeedFwd::Int64
    simSpeedBck::Int64
    simSpeedTrn::Int64
end
```

#### Task Definition

```julia
struct TTask
    ID::String
    start::TPaletteLocation
    target::TPaletteLocation
end
```

## 🤝 Contributing

We welcome contributions to the AGV system! Please follow these guidelines:

### Development Setup

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** with appropriate tests
4. **Run tests**: `julia --project=. test/runtests.jl`
5. **Submit a pull request**

### Code Style

- Follow Julia style guidelines
- Add documentation for new functions
- Include unit tests for new features
- Update README for significant changes

### Areas for Contribution

- **Algorithm Improvements**: Enhanced heuristics, new pathfinding algorithms
- **Performance Optimization**: Faster execution, memory efficiency
- **Visualization**: Better rendering, interactive interfaces
- **Testing**: More comprehensive test coverage
- **Documentation**: Examples, tutorials, API documentation

...or anything aothe way for you to enjoy this project.

## 📄 License

This project is licensed under the **GNU General Public License v2.0** - see the [LICENSE](LICENSE) file for details.

### Key Points

- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Distribution allowed
- ✅ Patent use allowed
- ❌ Private use only
- ❌ Liability limited
- ❌ Warranty disclaimed

## 📖 Citation

If you use this AGV system in your research, please cite:

```bibtex
@software{agv_Robotic_Path_Planning_under_Constraints_2024,
  title={AGV Multi-Agent Flow Optimization System},
  author={Rialland, Emmanuel},
  organization={ALBA Intelligence Hong Kong},
  year={2024},
  url={https://github.com/your-username/AGV-Robotic_Path_Planning_under_Constraints},
  license={GPL-2.0}
}
```

## 🔗 Related Work (the literature is extensive)

- **Multi-Agent Path Finding (MAPF)**: [Standley, 2010]
- **Safe Interval Path Planning**: [Phillips & Likhachev, 2011]
- **Warehouse Automation**: [Boysen et al., 2017]
- **A* Algorithm**: [Hart et al., 1968]

## 📞 Contact

- **Author**: Emmanuel Rialland
- **Organization**: ALBA Intelligence Hong Kong
- **Email**: [alba.intelligence@gmail.com]
- **Project Link**: [https://github.com/your-username/AGV-Robotic_Path_Planning_under_Constraints](https://github.com/your-username/AGV-Robotic_Path_Planning_under_Constraints)

## 🙏 Acknowledgments

- Julia community for excellent tooling and packages
- Contributors to LightGraphs.jl and related packages
- Research community in multi-agent systems and pathfinding
- ALBA Intelligence Hong Kong for project support

---

**Note**: This is a research project in semi-active development. Features and APIs may change between versions. Please check the documentation for the latest information.
