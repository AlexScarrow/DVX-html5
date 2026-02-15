# DERPLES VS XENOS - Quick Start Guide

## Prerequisites

1. **Install Defold Editor**
   - Download from: https://defold.com/download/
   - Available for Windows, macOS, and Linux
   - Free and open source

## Opening the Project

1. Launch Defold Editor
2. Select "Open Project from Disk"
3. Navigate to this folder (`/home/vibecode/workspace`)
4. Select the `game.project` file
5. The editor will load all project files

## Project Status

This is a **basic implementation** that includes:

✅ **Completed Systems:**
- Cell data structure (250x150 pixels)
- Tile system (3x3 cells, 750x450 pixels)
- WorldGrid (15x15 = 225 cells, flat array)
- Level design and "baking down" process
- A* pathfinding algorithm
- Coordinate conversion utilities
- Input handling (click/touch, zoom)
- Character module (derples and aliens)
- Edge detection and boundary checking

⚠️ **Needs Work:**
- Sprite assets (currently references only - images need to be created)
- Visual factory for spawning cell game objects
- Camera scrolling/panning
- Character visual representation
- Turn management system
- Combat visualization
- UI/HUD elements

## Running the Project

1. In Defold Editor, click **Project > Build** (or press Ctrl+B / Cmd+B)
2. The console will show initialization messages
3. Click anywhere on the game window to test cell selection
4. Check console for clicked cell information

## What You'll See

Currently, without sprite assets, you'll see a blank screen. The systems are working in the background. Console output will show:

```
=== DERPLES VS XENOS - Initializing ===
WorldGrid created: 225 cells
Tile library created
Level library created
Selected level 1 for baking
Level baked down to worldGrid
=== Initialization Complete ===
WorldGrid size: 15x15
Cell size: 250x150
Total world size: 3750x2250
```

When you click, you'll see:
```
Clicked Cell ID: 42 at (12, 3) - World: (2750.0, 300.0)
Cell Info:
  TileID: [hash value]
  Light: 3
  Move Cost: 1
  Cover: 2
  Access Right: true
  Access Down: true
```

## Next Steps to Make It Visual

### Step 1: Create Placeholder Sprites

Follow the instructions in `SPRITE_CREATION_GUIDE.md` to create simple placeholder images:
- Use any image editor (GIMP, Photoshop, Paint.NET, etc.)
- Or use the provided ImageMagick/Python scripts
- Place images in `/assets/images/` folder

### Step 2: Test with Sprites

After adding sprites:
1. In Defold Editor, right-click on `/assets/cells.atlas`
2. Select "Rebuild Atlas"
3. Do the same for `/assets/tiles.atlas`
4. Run the project again
5. You should now see the debug grid

### Step 3: Add Visual Cell Factory

In `main.collection`, add a factory for cells:
1. Right-click in the Outline panel
2. Add Component > Factory
3. Set Prototype to `/main/cell.go`
4. Give it ID "cell_factory"

Then update `game.script` to use `create_cell_visuals()` function.

### Step 4: Customize Tiles

Edit `create_tile_library()` in `game.script`:
- Add more tile types (medbay, engineering, airlocks, etc.)
- Set different properties for each tile
- Add objects (machines, doors, vents)

### Step 5: Create More Levels

Edit `create_level_library()` in `game.script`:
- Design 20 different level layouts
- Place tiles strategically
- Ensure tiles connect properly (matching access booleans)

## Testing Pathfinding

To test pathfinding, modify the `on_input` function in `game.script`:

```lua
function on_input(self, action_id, action)
    if action_id == hash("touch") then
        if action.pressed then
            local clicked_cell_id = handle_cell_click(action, self.camera_pos, self.camera_zoom)
            if clicked_cell_id then
                if not self.selected_cell then
                    -- First click - select start cell
                    self.selected_cell = clicked_cell_id
                    print("Start cell selected: " .. clicked_cell_id)
                else
                    -- Second click - find path
                    local path, cost = find_path(self.world_grid, self.selected_cell, clicked_cell_id, 20)
                    if path then
                        print("Path found! Cost: " .. cost)
                        print("Path: " .. table.concat(path, " -> "))
                    else
                        print("No path found")
                    end
                    self.selected_cell = nil
                end
            end
        end
    end
end
```

## Testing Characters

To test the character system:

1. Add some test characters in `init()` function:

```lua
function init(self)
    -- ... existing code ...

    -- Create test characters
    local char_module = require "main.character"
    self.derples = {
        char_module.create_derple("sarge", 57),
        char_module.create_derple("medic", 58)
    }
    self.aliens = {
        char_module.create_alien("drone", 170)
    }

    -- Mark cells as occupied
    for _, derple in ipairs(self.derples) do
        self.world_grid[derple.cell_id].isOccupied = hash(derple.type)
    end
end
```

## Understanding the Grid System

### Cell Numbering
```
211 212 213 ... 225  (Top row, y=15)
196 197 198 ... 210  (y=14)
...
16  17  18  ... 30   (y=2)
1   2   3   ... 15   (Bottom row, y=1)
```

### Adjacent Cell Math
- Right: `cell_id + 1` (e.g., cell 42 → cell 43)
- Left: `cell_id - 1` (e.g., cell 42 → cell 41)
- Up: `cell_id + 15` (e.g., cell 42 → cell 57)
- Down: `cell_id - 15` (e.g., cell 42 → cell 27)

### Tile Placement
A tile centered at (8, 8) covers these cells:
```
Cell 118 (7,8)   Cell 119 (8,8)   Cell 120 (9,8)
Cell 103 (7,7)   Cell 104 (8,7)   Cell 105 (9,7)
Cell 88  (7,6)   Cell 89  (8,6)   Cell 90  (9,6)
```

## Debugging Tips

### Console Commands
Add these to help debug:

```lua
-- Print entire world grid
function print_world_grid(world_grid)
    for id, cell in ipairs(world_grid) do
        if cell.tileID ~= hash("empty") then
            print(string.format("Cell %d (%d,%d): tile=%s, light=%d, move=%d",
                id, cell.xCell, cell.yCell, tostring(cell.tileID),
                cell.lightValue, cell.moveValue))
        end
    end
end

-- Visualize a path
function print_path_on_grid(path, grid_cols, grid_rows)
    local grid_vis = {}
    for y = grid_rows, 1, -1 do
        grid_vis[y] = {}
        for x = 1, grid_cols do
            grid_vis[y][x] = "."
        end
    end

    for i, cell_id in ipairs(path) do
        local x, y = id_to_coords(cell_id)
        grid_vis[y][x] = tostring(i)
    end

    for y = grid_rows, 1, -1 do
        print(table.concat(grid_vis[y], " "))
    end
end
```

## Common Issues

**Issue: Nothing renders**
- Check console for errors
- Verify sprite images exist in `/assets/images/`
- Rebuild atlases in Defold Editor

**Issue: Click detection doesn't work**
- Make sure input bindings are loaded
- Check camera position and zoom
- Verify "acquire_input_focus" is called

**Issue: Pathfinding fails**
- Check that cells are not VOID
- Verify access booleans are set correctly
- Ensure tiles are placed with proper connections

## File Reference

| File | Purpose |
|------|---------|
| `game.project` | Main project config |
| `main/main.collection` | Main scene setup |
| `main/game.script` | Core game logic (THE BRAIN) |
| `main/character.lua` | Character management module |
| `main/test_systems.script` | Example test code |
| `input/game.input_binding` | Input mappings |
| `assets/*.atlas` | Sprite atlases |
| `DEFOLD_README.md` | Complete documentation |

## Resources

- **Defold Documentation**: https://defold.com/learn/
- **Defold Forum**: https://forum.defold.com/
- **Lua Reference**: https://www.lua.org/manual/5.1/

## What's Next?

1. **Immediate**: Create placeholder sprites to see the grid
2. **Short-term**: Add character sprites and basic movement visualization
3. **Medium-term**: Implement turn management and AI
4. **Long-term**: Add all gameplay features (combat, objects, resources, win conditions)

Good luck building DERPLES VS XENOS! The foundation is solid and ready for expansion.
