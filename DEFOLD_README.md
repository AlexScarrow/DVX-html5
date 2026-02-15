# DERPLES VS XENOS - Defold Implementation

## Project Overview

This is a turn-based tactical game where players control 4 derple characters escaping from an alien-infested base. The game uses a grid-based tile system with pathfinding, resource management, and strategic gameplay.

## Project Structure

```
/
├── game.project              # Main project configuration
├── input/
│   └── game.input_binding    # Input mappings (touch, click, zoom)
├── main/
│   ├── main.collection       # Main scene with game script and camera
│   ├── game.script          # Core game logic (THIS IS THE HEART OF THE SYSTEM)
│   └── cell.go              # Cell prototype game object
└── assets/
    ├── cells.atlas          # Debug cell sprites
    ├── tiles.atlas          # Tile artwork sprites
    └── images/              # Actual image files (you need to create these)
```

## Core Systems Implemented

### 1. **Cell System**
- Each cell is 250x150 pixels
- Contains properties: light, move cost, cover, access permissions, objects, power status
- Cells are numbered sequentially starting from 1 (bottom-left)

### 2. **Tile System**
- Tiles are 3x3 grids of cells (750x450 pixels)
- Pre-defined tile library (corridor, canteen, armoury, etc.)
- Each tile defines the properties for its 9 cells

### 3. **WorldGrid**
- 15x15 grid = 225 cells total
- Stored as a flat sequential array (not 2D)
- Cell numbering: bottom-left is 1, incrementing right then up
- Simple arithmetic for adjacent cells:
  - Right: +1
  - Left: -1
  - Up: +15
  - Down: -15

### 4. **Level Design & Baking**
- Level designs specify tile placements
- "Baking down" copies tile data into worldGrid cells
- Cells not part of any tile are marked as VOID (impassable)

### 5. **Pathfinding**
- A* algorithm implementation
- Respects movement costs, walls, and VOID cells
- Can limit paths by action points

### 6. **Input Handling**
- Click/touch to select cells
- Converts screen coordinates to world grid coordinates
- Mouse wheel for zoom in/out
- Reports clicked cell ID and properties to console

## Key Functions in game.script

### Cell & Grid Management
- `create_cell_prototype(id, x, y)` - Creates a single cell
- `create_world_grid()` - Initializes the 15x15 grid
- `coords_to_id(x, y)` - Convert coordinates to cell ID
- `id_to_coords(id)` - Convert cell ID to coordinates
- `coords_to_world_pos(x, y)` - Convert grid coords to pixel position

### Tile System
- `create_tile_prototype(name)` - Creates a 3x3 tile template
- `create_tile_library()` - Define all available tiles
- `create_level_library()` - Define level layouts

### Level Building
- `bake_level_to_world_grid(grid, level, tiles)` - Apply level design to grid

### Pathfinding
- `get_neighbors(cell_id, grid)` - Find accessible adjacent cells
- `find_path(grid, start, end, max_ap)` - A* pathfinding with action points
- `get_adjacent_cell(id, direction)` - Simple adjacency with bounds checking

### Input
- `handle_cell_click(action, camera_pos, zoom)` - Convert click to cell ID
- `screen_to_world(x, y, camera, zoom)` - Screen to world space conversion

## What You Need to Add

### 1. **Sprite Assets**
You need to create placeholder images in `/assets/images/`:

**Debug Cell Sprites** (250x150 pixels each):
- `cell_open.png` - No borders (open on all sides)
- `cell_right_wall.png` - White border on right edge
- `cell_down_wall.png` - White border on bottom edge
- `cell_right_down_wall.png` - White borders on right and bottom
- `cell_void.png` - Solid black (impassable area)

**Tile Sprites** (750x450 pixels each):
- `tile_corridor.png` - Corridor artwork
- `tile_canteen.png` - Canteen artwork
- `tile_armoury.png` - Armoury artwork

### 2. **Expanding the Tile Library**
In `game.script`, find `create_tile_library()` and add more tiles:

```lua
-- Example: Add a "medbay" tile
local medbay = create_tile_prototype("medbay")
for i = 1, 9 do
    medbay.cells[i].lightValue = 5
    medbay.cells[i].moveValue = 1
    medbay.cells[i].coverValue = 1
end
-- Add medical machine to center cell
medbay.cells[5].object1 = {
    name = hash("machine_medical"),
    isFixed = false,
    isDependentOn = {}
}
library["medbay"] = medbay
```

### 3. **Customizing Tiles**
Each tile cell (1-9) can have custom values:

```lua
-- Cell layout in a tile:
-- 7  8  9
-- 4  5  6
-- 1  2  3

-- Example: Block right wall of center cell
my_tile.cells[5].accessRight = false

-- Example: Make cell 6 have high move cost
my_tile.cells[6].moveValue = 3

-- Example: Add a door object
my_tile.cells[8].object1 = {
    name = hash("door"),
    isFixed = true,
    isDependentOn = {}
}
```

### 4. **Creating New Levels**
In `create_level_library()`:

```lua
levels[3] = {
    { x = 5, y = 5, tile = "corridor" },
    { x = 8, y = 5, tile = "canteen" },
    { x = 11, y = 5, tile = "corridor" },
    { x = 8, y = 8, tile = "armoury" },
}
```

## Testing the Current Implementation

1. **Open in Defold Editor**
   - Open the project folder in Defold
   - The editor will parse all `.collection`, `.go`, and `.script` files

2. **Check Console Output**
   - Run the project (Project > Build)
   - Console will show initialization messages:
     - WorldGrid creation
     - Tile library loaded
     - Level baked down

3. **Test Cell Clicking**
   - Click anywhere on screen
   - Console will show:
     - Clicked Cell ID
     - Grid coordinates (x, y)
     - World position
     - Cell properties (tileID, light, move cost, etc.)

4. **Test Zoom**
   - Mouse wheel up/down to zoom
   - Zoom range: 0.5x to 2.0x

## Next Steps

### Immediate Priorities:
1. **Create placeholder sprites** - Even simple colored rectangles will work for testing
2. **Test pathfinding** - Add code to select two cells and show path between them
3. **Visual cell factory** - Complete the `create_cell_visuals()` function with actual factory
4. **Camera scrolling** - Add pan/drag support for exploring the full grid

### Gameplay Features to Add:
1. **Character system** - Derples (Sarge, Medic, Gunner, Techie)
2. **Alien system** - Different alien types with AI
3. **Turn management** - Player turns vs alien turns
4. **Action point system** - Movement and action costs
5. **Combat system** - Line of sight, cover, damage
6. **Object interactions** - Machines, doors, vents, turrets
7. **Power system** - PowerNodes and dependencies
8. **Resource management** - Salvage, ammo, meds

## Important Notes

### Grid Numbering
- **Cells start at 1, not 0** (as per spec requirement)
- Bottom-left is cell 1 (coordinates 1,1)
- Bottom-right is cell 15 (coordinates 15,1)
- Top-left is cell 211 (coordinates 1,15)
- Top-right is cell 225 (coordinates 15,15)

### Coordinate System
- **World space**: Pixel coordinates (0,0) at origin
- **Grid space**: Cell coordinates (1-15, 1-15)
- **Cell IDs**: Sequential numbers (1-225)

### Access Booleans
- Each cell owns its **RIGHT wall** and **BOTTOM floor**
- `accessRight = true` means you can move through the right border
- `accessDown = true` means you can move through the bottom border
- To move UP into a cell, check that cell's `accessDown`
- To move RIGHT into a cell, check current cell's `accessRight`

## Troubleshooting

**Q: Cells aren't showing up**
- Check that sprite images exist in `/assets/images/`
- Verify atlas files are correctly configured
- Implement the factory system for cell creation

**Q: Click detection not working**
- Verify input bindings in `game.input_binding`
- Check console for "Clicked Cell ID" messages
- Ensure camera position is set correctly

**Q: Pathfinding fails**
- Check that start and end cells are not VOID
- Verify `accessRight`/`accessDown` permissions create valid paths
- Ensure tiles are placed adjacent with matching access permissions

## Code Quality

The code includes:
- **Heavy commenting** - Every section and function is documented
- **Readable variable names** - Clear indication of what each variable represents
- **Modular structure** - Easy to find and modify specific systems
- **Extensible design** - Room for additional properties and features

## Contact & Support

This implementation follows the specification document exactly. If you need to modify behavior or add features, all systems are clearly separated and documented in `game.script`.
