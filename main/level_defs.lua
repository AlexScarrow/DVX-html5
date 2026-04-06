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
    --5/14,8/14, 11/14, 14/14
    --5/11,8/11,14/11
    --5/8,8/8,11/8,14/8
    --5/5,8/5,11/5,14/5

    -- Example Level 1
    levels[1] = {
       
        { x = 8, y = 8, tile = "canteen" },
        { x = 14, y = 11, tile = "factory" },
        { x = 8, y = 11, tile = "workshop" },
        { x = 5, y = 11, tile = "coms" },
        { x = 11, y = 8, tile = "medbay" },
        { x = 2, y = 8, tile = "entry" },
        { x = 5, y = 8, tile = "armoury" },
        { x = 14, y = 8, tile = "exterior1" },
        --{ x = 11, y = 11, tile = "lab" },
        { x = 14, y = 5, tile = "portal" },
        --{ x = 14, y = 9, tile = "portal" },
        { x = 11, y = 2, tile = "exit" },
        { x = 10, y = 5, tile = "passage1" },
    }
    levels[1].mission_type = "escape"
    levels[1].spawn_tile = "entry"
    levels[1].spawn_cell = 2
    levels[1].unit_loadouts = {
        sarge = {
            starting_backpack_items = {},
            starting_equipped_buffs = {
                top = "buff_night_vision"
            }
        },
        techie = {
            starting_backpack_items = { "power" },
            starting_equipped_buffs = {}
        },
        medic = {
            starting_backpack_items = {},
            starting_equipped_buffs = {}
        },
        gunner = {
            starting_backpack_items = {},
            starting_equipped_buffs = {}
        }
    }

    levels[2] = {
        { x = 2, y = 8, tile = "rescue_entry" },
        { x = 5, y = 8, tile = "medbay" },
        { x = 8, y = 9, tile = "canteen" },
        { x = 11, y = 8, tile = "factory" },
        { x = 5, y = 11, tile = "armoury" },
        { x = 8, y = 12, tile = "coms" },
        { x = 8, y = 6, tile = "workshop" },
        { x = 4, y = 5, tile = "passage1" },
        { x = 2, y = 2, tile = "portal" },  
        { x = 5, y = 2, tile = "exit" },      
    }
    levels[2].mission_type = "rescue"
    levels[2].spawn_tile = "rescue_entry"
    levels[2].spawn_cell = 2
    levels[2].unit_loadouts = {
        sarge = {
            starting_backpack_items = {},
            starting_equipped_buffs = {
                top = "buff_night_vision"
            }
        },
        techie = {
            starting_backpack_items = { "power" },
            starting_equipped_buffs = {}
        },
        medic = {
            starting_backpack_items = {},
            starting_equipped_buffs = {}
        },
        gunner = {
            starting_backpack_items = {},
            starting_equipped_buffs = {}
        }
    }

    levels[3] = {

        { x = 8, y = 8, tile = "canteen" },
        { x = 14, y = 11, tile = "factory" },
        { x = 8, y = 11, tile = "workshop" },
        { x = 5, y = 11, tile = "coms" },
        { x = 11, y = 8, tile = "medbay" },
        { x = 2, y = 8, tile = "rescue_entry" },
        { x = 5, y = 8, tile = "armoury" },
        { x = 14, y = 8, tile = "exterior1" },
        { x = 11, y = 11, tile = "lab" },
        { x = 14, y = 5, tile = "portal" },
        --{ x = 14, y = 9, tile = "portal" },
        { x = 11, y = 2, tile = "exit" },
        { x = 10, y = 5, tile = "passage1" },
    }
    levels[3].mission_type = "dna_sample"
    levels[3].spawn_tile = "rescue_entry"
    levels[3].spawn_cell = 2
    levels[3].unit_loadouts = {
        sarge = {
            starting_backpack_items = {},
            starting_equipped_buffs = {
                top = "buff_night_vision"
            }
        },
        techie = {
            starting_backpack_items = { "power" },
            starting_equipped_buffs = {}
        },
        medic = {
            starting_backpack_items = {},
            starting_equipped_buffs = {}
        },
        gunner = {
            starting_backpack_items = {},
            starting_equipped_buffs = {}
        }
    }

    levels[4] = {

        { x = 8, y = 8, tile = "canteen" },
        { x = 14, y = 11, tile = "factory" },
        { x = 8, y = 11, tile = "workshop" },
        { x = 5, y = 11, tile = "coms" },
        { x = 11, y = 8, tile = "medbay" },
        { x = 2, y = 8, tile = "rescue_entry" },
        { x = 5, y = 8, tile = "armoury" },
        { x = 14, y = 8, tile = "exterior1" },
        { x = 11, y = 11, tile = "lab" },
        { x = 14, y = 5, tile = "portal" },
        --{ x = 14, y = 9, tile = "portal" },
        { x = 11, y = 2, tile = "exit" },
        { x = 10, y = 5, tile = "passage1" },
    }
    levels[4].mission_type = "purge"
    levels[4].spawn_tile = "rescue_entry"
    levels[4].spawn_cell = 2
    levels[4].unit_loadouts = {
        sarge = {
            starting_backpack_items = {},
            starting_equipped_buffs = {
                top = "buff_night_vision"
            }
        },
        techie = {
            starting_backpack_items = { "power" },
            starting_equipped_buffs = {}
        },
        medic = {
            starting_backpack_items = {},
            starting_equipped_buffs = {}
        },
        gunner = {
            starting_backpack_items = {},
            starting_equipped_buffs = {}
        }
    }
    
    -- Example Level 2
    -- EXPERIMENTAL layout: temporary playtest board, intended to be easy to replace.
    -- levels[2] = {
    --     -- { x = 8, y = 8, tile = "lvl2_open" },
    --     -- { x = 5, y = 8, tile = "lvl2_choke" },
    --     -- { x = 11, y = 8, tile = "lvl2_choke" },
    --     -- { x = 8, y = 11, tile = "lvl2_support" },
    --     -- { x = 8, y = 5, tile = "lvl2_support" },
    --     { x = 5, y = 11, tile = "armoury" },
    --     { x = 11, y = 11, tile = "armoury" }
    -- }
    -- levels[2].mission_type = "escape"

    return levels
end

return M
