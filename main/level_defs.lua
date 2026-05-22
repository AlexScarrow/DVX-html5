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
        { x = 5, y = 11, tile = "coms" },
        { x = 8, y = 11, tile = "workshop" },
        { x = 11, y = 11, tile = "factory" },
        { x = 2, y = 8, tile = "entry" },
        { x = 5, y = 8, tile = "furnace" }, --corridor1
        { x = 8, y = 8, tile = "canteen" },
        { x = 11, y = 8, tile = "medbay" },
        { x = 14, y = 8, tile = "exterior1" },
        { x = 2, y = 5, tile = "corridor1" },
        { x = 5, y = 5, tile = "bunkroom" },
        { x = 8, y = 5, tile = "corridor1" },
        { x = 11, y = 5, tile = "corridor1" },
        { x = 14, y = 5, tile = "exit" },
        { x = 5, y = 2, tile = "showers" },
        { x = 8, y = 2, tile = "cavern" },
        { x = 11, y = 2, tile = "portal" },
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
            starting_backpack_items = { "power", "power" },
            starting_equipped_buffs = {
                top = "buff_night_vision"
            }
        },
        medic = {
            starting_backpack_items = { "meds", "meds"},
            starting_equipped_buffs = {}
        },
        gunner = {
            starting_backpack_items = { "ammo", "ammo"},
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
            starting_backpack_items = { "meds"},
            starting_equipped_buffs = {}
        },
        gunner = {
            starting_backpack_items = { "ammo"},
            starting_equipped_buffs = {}
        }
    }

--     levels[3] = {
-- 
--         { x = 8, y = 8, tile = "canteen" },
--         { x = 14, y = 11, tile = "factory" },
--         { x = 8, y = 11, tile = "workshop" },
--         { x = 5, y = 11, tile = "coms" },
--         { x = 11, y = 8, tile = "medbay" },
--         { x = 2, y = 8, tile = "rescue_entry" },
--         { x = 5, y = 8, tile = "armoury" },
--         { x = 14, y = 8, tile = "exterior1" },
--         { x = 11, y = 11, tile = "lab" },
--         { x = 14, y = 5, tile = "portal" },
--         --{ x = 14, y = 9, tile = "portal" },
--         { x = 11, y = 2, tile = "exit" },
--         { x = 10, y = 5, tile = "passage1" },
--     }
--     levels[3].mission_type = "dna_sample"
--     levels[3].spawn_tile = "rescue_entry"
--     levels[3].spawn_cell = 2
--     levels[3].unit_loadouts = {
--         sarge = {
--             starting_backpack_items = {},
--             starting_equipped_buffs = {
--                 top = "buff_night_vision"
--             }
--         },
--         techie = {
--             starting_backpack_items = { "power" },
--             starting_equipped_buffs = {}
--         },
--         medic = {
--             starting_backpack_items = {},
--             starting_equipped_buffs = {}
--         },
--         gunner = {
--             starting_backpack_items = {},
--             starting_equipped_buffs = {}
--         }
--     }
levels[3] = {
    { x = 5, y = 11, tile = "coms" },
    { x = 8, y = 11, tile = "workshop" },
    { x = 11, y = 11, tile = "factory" },
    { x = 14, y = 11, tile = "lab" },
    { x = 2, y = 8, tile = "rescue_entry" },
    { x = 5, y = 8, tile = "armoury" },
    { x = 8, y = 8, tile = "canteen" },
    { x = 11, y = 8, tile = "medbay" },
    { x = 14, y = 8, tile = "exterior1" },
    { x = 4, y = 5, tile = "passage1" },
    { x = 10, y = 5, tile = "passage1" },
    { x = 14, y = 5, tile = "portal" },
    { x = 4, y = 2, tile = "bunkroom" },
    { x = 11, y = 2, tile = "exit" },
}
levels[3].mission_type = "dna_sample"
levels[3].spawn_tile = "rescue_entry"
levels[3].spawn_cell = 2
--levels[3].unit_loadouts = levels[1].unit_loadouts
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
        starting_backpack_items = { "meds"},
        starting_equipped_buffs = {}
    },
    gunner = {
        starting_backpack_items = { "ammo"},
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
            starting_backpack_items = { "bomb" },
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
--TUTORIAL LEVEL
    levels[5] = {

        -- { x = 8, y = 8, tile = "canteen" },
        -- { x = 14, y = 11, tile = "factory" },
        -- { x = 8, y = 11, tile = "workshop" },
        -- { x = 5, y = 11, tile = "coms" },
        -- { x = 11, y = 8, tile = "medbay" },
        { x = 2, y = 8, tile = "entry" },
        { x = 5, y = 8, tile = "canteen" },
        { x = 5, y = 5, tile = "exit" },
        { x = 5, y = 11, tile = "coms" },
        { x = 11, y = 8, tile = "workshop" },
        { x = 11, y = 11, tile = "factory" },
        -- { x = 5, y = 8, tile = "armoury" },
        { x = 8, y = 8, tile = "exterior1" },
        -- { x = 11, y = 11, tile = "lab" },
        -- { x = 14, y = 5, tile = "portal" },
        { x = 5, y = 2, tile = "portal" },
        -- { x = 11, y = 2, tile = "exit" },
        -- { x = 10, y = 5, tile = "passage1" },
    }
    levels[5].mission_type = "tutorial"
    levels[5].spawn_tile = "entry"
    levels[5].spawn_cell = 2
    levels[5].unit_loadouts = {
        sarge = {
            starting_backpack_items = {"power","ammo","ammo" },
            starting_equipped_buffs = {
                top = "buff_night_vision"
            }
        },
        techie = {
            starting_backpack_items = { "power","wiring_straight","power" },
            starting_equipped_buffs = {
                top = "buff_night_vision"
            }
        },
        medic = {
            starting_backpack_items = {"power","meds","meds"},
            starting_equipped_buffs = {}
        },
        gunner = {
            starting_backpack_items = {"power","ammo","ammo","ammo"},
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

    -- level editor export | level=6 mission=dna_sample
    levels[6] = {
        { x = 8, y = 12, tile = "coms" },
        { x = 5, y = 11, tile = "coms" },
        { x = 8, y = 9, tile = "lab" },
        { x = 11, y = 9, tile = "corridor1" },
        { x = 2, y = 8, tile = "rescue_entry" },
        { x = 5, y = 8, tile = "armoury" },
        { x = 14, y = 8, tile = "jungle" },
        { x = 4, y = 5, tile = "passage1" },
        { x = 14, y = 5, tile = "passage1" },
        { x = 5, y = 2, tile = "portal" },
        { x = 15, y = 2, tile = "portal" },
    }
    levels[6].mission_type = "dna_sample"
    levels[6].spawn_tile = "rescue_entry"
    levels[6].spawn_cell = 2
    levels[6].unit_loadouts = levels[3].unit_loadouts

    levels[7] = {
        { x = 5, y = 11, tile = "coms" },
        { x = 8, y = 11, tile = "exterior1" },
        { x = 11, y = 11, tile = "factory" },
        { x = 2, y = 8, tile = "entry" },
        { x = 5, y = 8, tile = "canteen" },
        { x = 8, y = 8, tile = "exterior1" },
        { x = 11, y = 8, tile = "workshop" },
        { x = 5, y = 5, tile = "bunkroom" },
        { x = 8, y = 5, tile = "portal" },
        { x = 11, y = 5, tile = "corridor1" },
        { x = 14, y = 5, tile = "exit" },
        { x = 5, y = 2, tile = "armoury" },
    }
    levels[7].mission_type = "escape"
    levels[7].spawn_tile = "entry"
    levels[7].spawn_cell = 2
    levels[7].unit_loadouts = levels[1].unit_loadouts

    levels[8] = {
        { x = 11, y = 14, tile = "coms" },
        { x = 11, y = 11, tile = "armoury" },
        { x = 2, y = 8, tile = "jungle" },
        { x = 5, y = 8, tile = "exterior2" },
        { x = 8, y = 8, tile = "rescue_entry" },
        { x = 11, y = 8, tile = "corridor1" },
        { x = 14, y = 8, tile = "exterior1" },
        { x = 2, y = 5, tile = "portal" },
        { x = 5, y = 5, tile = "showers" },
        { x = 8, y = 5, tile = "corridor1" },
        { x = 11, y = 5, tile = "bunkroom" },
        { x = 11, y = 2, tile = "medbay" },
        { x = 14, y = 2, tile = "portal" },
    }
    levels[8].mission_type = "purge"
    levels[8].spawn_tile = "rescue_entry"
    levels[8].spawn_cell = 2
    --levels[8].unit_loadouts = levels[1].unit_loadouts
    levels[8].unit_loadouts = {
        sarge = {
            starting_backpack_items = { "bomb", "bomb" },
            starting_equipped_buffs = {
                top = "buff_night_vision"
            }
        },
        techie = {
            starting_backpack_items = { "power" },
            starting_equipped_buffs = {}
        },
        medic = {
            starting_backpack_items = { "meds"},
            starting_equipped_buffs = {}
        },
        gunner = {
            starting_backpack_items = { "ammo"},
            starting_equipped_buffs = {}
        }
    }

    levels[9] = {
        { x = 2, y = 12, tile = "coms" },
        { x = 14, y = 11, tile = "coms" },
        { x = 2, y = 9, tile = "canteen" },
        { x = 5, y = 9, tile = "lab" },
        { x = 8, y = 8, tile = "exterior2" },
        { x = 11, y = 8, tile = "rescue_entry" },
        { x = 14, y = 8, tile = "armoury" },
        { x = 2, y = 6, tile = "corridor1" },
        { x = 5, y = 5, tile = "bunkroom" },
        { x = 8, y = 5, tile = "corridor1" },
        { x = 11, y = 5, tile = "corridor1" },
        { x = 14, y = 5, tile = "workshop" },
        { x = 2, y = 3, tile = "portal" },
        { x = 11, y = 2, tile = "portal" },
        { x = 14, y = 2, tile = "factory" },
    }
    levels[9].mission_type = "rescue"
    levels[9].spawn_tile = "rescue_entry"
    levels[9].spawn_cell = 2
    levels[9].unit_loadouts = levels[1].unit_loadouts

    levels[10] = {
        { x = 8, y = 14, tile = "canteen" },
        { x = 5, y = 13, tile = "coms" },
        { x = 11, y = 13, tile = "armoury" },
        { x = 8, y = 11, tile = "corridor1" },
        { x = 11, y = 10, tile = "corridor1" },
        { x = 14, y = 9, tile = "workshop" },
        { x = 8, y = 8, tile = "bunkroom" },
        { x = 2, y = 7, tile = "rescue_entry" },
        { x = 5, y = 7, tile = "jungle" },
        { x = 14, y = 6, tile = "medbay" },
        { x = 8, y = 5, tile = "bunkroom" },
        { x = 13, y = 3, tile = "factory" },
        { x = 4, y = 2, tile = "portal" },
        { x = 7, y = 2, tile = "corridor1" },
        { x = 10, y = 2, tile = "portal" },
    }
    levels[10].mission_type = "rescue"
    levels[10].spawn_tile = "rescue_entry"
    levels[10].spawn_cell = 2
    levels[10].unit_loadouts = levels[1].unit_loadouts

    levels[11] = {
        { x = 10, y = 13, tile = "coms" },
        { x = 11, y = 10, tile = "canteen" },
        { x = 14, y = 10, tile = "jungle" },
        { x = 2, y = 8, tile = "coms" },
        { x = 5, y = 8, tile = "exterior2" },
        { x = 8, y = 8, tile = "rescue_entry" },
        { x = 11, y = 7, tile = "bunkroom" },
        { x = 14, y = 7, tile = "exterior1" },
        { x = 2, y = 5, tile = "portal" },
        { x = 5, y = 5, tile = "corridor1" },
        { x = 8, y = 5, tile = "corridor1" },
        { x = 11, y = 4, tile = "armoury" },
        { x = 14, y = 4, tile = "portal" },
    }
    levels[11].mission_type = "purge"
    levels[11].spawn_tile = "rescue_entry"
    levels[11].spawn_cell = 2
    levels[11].unit_loadouts = {
        sarge = {
            starting_backpack_items = { "bomb", "bomb" },
            starting_equipped_buffs = {
                top = "buff_night_vision"
            }
        },
        techie = {
            starting_backpack_items = { "power", "power" },
            starting_equipped_buffs = {}
        },
        medic = {
            starting_backpack_items = { "meds", "meds" },
            starting_equipped_buffs = {}
        },
        gunner = {
            starting_backpack_items = { "ammo", "ammo" },
            starting_equipped_buffs = {}
        }
    }

    levels[12] = {
        { x = 14, y = 11, tile = "coms" },
        { x = 2, y = 9, tile = "lab" },
        { x = 5, y = 8, tile = "exterior1" },
        { x = 8, y = 8, tile = "exterior2" },
        { x = 11, y = 8, tile = "rescue_entry" },
        { x = 14, y = 8, tile = "armoury" },
        { x = 2, y = 6, tile = "medbay" },
        { x = 5, y = 5, tile = "corridor1" },
        { x = 8, y = 5, tile = "jungle" },
        { x = 11, y = 5, tile = "corridor1" },
        { x = 14, y = 5, tile = "cavern" },
        { x = 2, y = 3, tile = "portal" },
        { x = 5, y = 2, tile = "portal" },
        { x = 8, y = 2, tile = "portal" },
        { x = 11, y = 2, tile = "portal" },
    }
    levels[12].mission_type = "dna_sample"
    levels[12].spawn_tile = "rescue_entry"
    levels[12].spawn_cell = 2
    levels[12].unit_loadouts = levels[1].unit_loadouts

    levels[13] = {
        { x = 2, y = 11, tile = "coms" },
        { x = 11, y = 11, tile = "canteen" },
        { x = 14, y = 10, tile = "exterior1" },
        { x = 2, y = 8, tile = "armoury" },
        { x = 5, y = 8, tile = "exterior2" },
        { x = 8, y = 8, tile = "entry" },
        { x = 11, y = 8, tile = "medbay" },
        { x = 14, y = 7, tile = "exit" },
        { x = 2, y = 5, tile = "showers" },
        { x = 5, y = 5, tile = "corridor1" },
        { x = 8, y = 5, tile = "corridor1" },
        { x = 11, y = 5, tile = "corridor1" },
        { x = 14, y = 4, tile = "workshop" },
        { x = 2, y = 2, tile = "bunkroom" },
        { x = 5, y = 2, tile = "portal" },
        { x = 8, y = 2, tile = "cavern" },
        { x = 11, y = 2, tile = "cavern" },
        { x = 14, y = 1, tile = "portal" },
    }
    levels[13].mission_type = "escape"
    levels[13].spawn_tile = "entry"
    levels[13].spawn_cell = 2
    levels[13].unit_loadouts = levels[1].unit_loadouts

    levels[14] = {
        { x = 11, y = 14, tile = "coms" },
        { x = 5, y = 11, tile = "coms" },
        { x = 8, y = 11, tile = "medbay" },
        { x = 11, y = 11, tile = "armoury" },
        { x = 2, y = 10, tile = "canteen" },
        { x = 5, y = 8, tile = "exterior1" },
        { x = 8, y = 8, tile = "jungle" },
        { x = 11, y = 8, tile = "exterior2" },
        { x = 14, y = 8, tile = "rescue_entry" },
        { x = 5, y = 5, tile = "bunkroom" },
        { x = 8, y = 5, tile = "showers" },
        { x = 11, y = 5, tile = "portal" },
        { x = 2, y = 2, tile = "portal" },
        { x = 5, y = 2, tile = "workshop" },
        { x = 8, y = 2, tile = "corridor1" },
        { x = 11, y = 2, tile = "portal" },
    }
    levels[14].mission_type = "rescue"
    levels[14].spawn_tile = "rescue_entry"
    levels[14].spawn_cell = 2
    levels[14].unit_loadouts = levels[1].unit_loadouts

    return levels
end

return M
