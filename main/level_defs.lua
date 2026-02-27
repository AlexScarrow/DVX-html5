local M = {}

-- =============================================================================
-- LEVEL DESIGN
-- =============================================================================
--[[
    Level designs specify which tiles to place where on the worldGrid
    Format: { x = xCell, y = yCell, tile = "tileName" }
    The x,y coordinate refers to the CENTER cell of the 3x3 tile
]]
function M.create_level_library()
    local levels = {}

    -- Example Level 1
    levels[1] = {
        { x = 11, y = 11, tile = "armoury" },
        { x = 8, y = 11, tile = "medbay" },
        { x = 8, y = 8, tile = "armoury" },
        { x = 11, y = 8, tile = "armoury" },
        { x = 5, y = 8, tile = "armoury" }
    }

    -- Example Level 2
    -- EXPERIMENTAL layout: temporary playtest board, intended to be easy to replace.
    levels[2] = {
        { x = 8, y = 8, tile = "lvl2_open" },
        { x = 5, y = 8, tile = "lvl2_choke" },
        { x = 11, y = 8, tile = "lvl2_choke" },
        { x = 8, y = 11, tile = "lvl2_support" },
        { x = 8, y = 5, tile = "lvl2_support" },
        { x = 5, y = 11, tile = "lvl2_support" },
        { x = 11, y = 11, tile = "lvl2_support" }
    }

    return levels
end

return M
