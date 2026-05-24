local M = {}

-- =============================================================================
-- TILE PROTOTYPE STRUCTURE
-- =============================================================================
local function create_tile_prototype(tile_id)
    local tile = {
        tileID = hash(tile_id),
        visualTile = tile_id,
        alphaOverlayMode = "generic",
        alphaOverlay = "generic_alpha_layer",
        alphaOverlayAlwaysVisible = false,
        cells = {}
    }

    -- Layout: 7 8 9
    --         4 5 6
    --         1 2 3
    for i = 1, 9 do
        tile.cells[i] = {
            lightValue = 3,
            moveValue = 1,
            coverValue = 1,
            isOutside = false,
            hazard_type = "none",
            accessRight = true,
            accessDown = true,
            isPowered = false,
            tileInstanceId = 0,
            isOccupied = hash("empty"),
            hasLoot = false,
            lootOffsetX = -32,
            lootOffsetY = -32,
            object1 = { name = hash("empty"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 0, offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = nil, hitW = 32, hitH = 32, requiredComponent = nil },
            object2 = { name = hash("empty"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 0, offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = nil, hitW = 32, hitH = 32, requiredComponent = nil },
            object3 = { name = hash("empty"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 0, offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = nil, hitW = 32, hitH = 32, requiredComponent = nil }
        }
    end

    return tile
end

-- =============================================================================
-- TILE LIBRARY
-- =============================================================================
function M.create_tile_library(COMPONENT_UI)
    local library = {}

    local function assign_random_loot_cell(tile)
        for i = 1, 9 do
            tile.cells[i].hasLoot = false
        end
        local idx = math.random(1, 9)
        tile.cells[idx].hasLoot = true
    end

    local function assign_fixed_loot_cell(tile, cell_index)
        for i = 1, 9 do
            tile.cells[i].hasLoot = (i == cell_index)
        end
    end

    

   

-- =====================================================================
-- ENTRY (start of level)
-- =====================================================================
    local entry = create_tile_prototype("entry")
    entry.visualTile = "entry_computerGame"
    entry.visualTileComputer = "entry_computerGame"
    entry.visualTileBoardgame = "entry_boardGame"
    for i = 1, 9 do
        entry.cells[i].lightValue = 2
        entry.cells[i].moveValue = 1
        entry.cells[i].coverValue = 1
        entry.cells[i].isOutside = false
    end
    entry.cells[1].hazard_type = "outside"
    entry.cells[2].hazard_type = "outside"
    entry.cells[3].hazard_type = "outside"
    entry.cells[4].hazard_type = "outside"
    entry.cells[5].hazard_type = "outside"
    entry.cells[6].hazard_type = "outside"
    entry.cells[7].hazard_type = "outside"
    entry.cells[8].hazard_type = "outside"
    entry.cells[9].hazard_type = "outside"
    entry.cells[3].moveValue = 3
    entry.cells[6].moveValue = 3

    entry.cells[1].accessDown = false
    entry.cells[2].accessDown = false
    entry.cells[3].accessRight = false
    entry.cells[3].accessDown = false
    entry.cells[4].accessRight = false
    entry.cells[4].accessDown = false
    entry.cells[5].accessRight = false
    entry.cells[5].accessDown = false
    entry.cells[5].accessRight = false
    entry.cells[6].accessRight = false
    entry.cells[7].accessRight = false
    entry.cells[7].accessDown = false
    entry.cells[8].accessRight = false
    entry.cells[8].accessDown = false

    entry.cells[9].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    
    library["entry"] = entry

-- =====================================================================
-- RESCUE_ENTRY (start of rescue level)
-- =====================================================================

    local rescue_entry = create_tile_prototype("rescue_entry")
    rescue_entry.visualTile = "rescue_entry_computerGame"
    rescue_entry.visualTileComputer = "rescue_entry_computerGame"
    rescue_entry.visualTileBoardgame = "rescue_entry_boardGame"

    rescue_entry.alphaOverlayMode = "specified"
    rescue_entry.alphaOverlay = "tile_rescue_entry_overlay"
    rescue_entry.alphaOverlayAlwaysVisible = true
    
    for i = 1, 9 do
        rescue_entry.cells[i].lightValue = 2
        rescue_entry.cells[i].moveValue = 1
        rescue_entry.cells[i].coverValue = 1
        rescue_entry.cells[i].isOutside = true
    end

    rescue_entry.cells[1].hazard_type = "outside"
    rescue_entry.cells[2].hazard_type = "outside"
    rescue_entry.cells[3].hazard_type = "outside"
    --rescue_entry.cells[4].hazard_type = "outside"
    --rescue_entry.cells[5].hazard_type = "outside"
    rescue_entry.cells[6].hazard_type = "outside"
    rescue_entry.cells[7].hazard_type = "outside"
    rescue_entry.cells[8].hazard_type = "outside"
    rescue_entry.cells[9].hazard_type = "outside"



    
    rescue_entry.cells[3].moveValue = 3
    rescue_entry.cells[6].moveValue = 3



    
    rescue_entry.cells[1].accessDown = false
    rescue_entry.cells[2].accessDown = false
    rescue_entry.cells[3].accessRight = false
    rescue_entry.cells[3].accessDown = false
    rescue_entry.cells[4].accessRight = false
    rescue_entry.cells[4].accessDown = false
    rescue_entry.cells[5].accessDown = false
    rescue_entry.cells[7].accessDown = false
    rescue_entry.cells[8].accessDown = false
    rescue_entry.cells[8].accessRight = false
    --rescue_entry.cells[5].accessRight = false
    rescue_entry.cells[6].accessRight = false
    rescue_entry.cells[9].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 203,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    library["rescue_entry"] = rescue_entry

    -- =====================================================================
    -- EXRERIOR1 TILE (some outside space)
    -- =====================================================================

    local exterior1 = create_tile_prototype("exterior1")
    exterior1.visualTile = "exterior1_computerGame"
    exterior1.visualTileComputer = "exterior1_computerGame"
    exterior1.visualTileBoardgame = "exterior1_boardGame"
    for i = 1, 9 do
        exterior1.cells[i].lightValue = 0
        exterior1.cells[i].moveValue = 1
        exterior1.cells[i].coverValue = 1
        exterior1.cells[i].isOutside = true
    end
    exterior1.cells[3].moveValue = 3
    exterior1.cells[6].moveValue = 3

    exterior1.cells[1].hazard_type = "outside"
    exterior1.cells[2].hazard_type = "outside"
    exterior1.cells[3].hazard_type = "outside"
    exterior1.cells[4].hazard_type = "outside"
    exterior1.cells[5].hazard_type = "outside"
    exterior1.cells[6].hazard_type = "outside"
    exterior1.cells[7].hazard_type = "outside"
    exterior1.cells[8].hazard_type = "outside"
    exterior1.cells[9].hazard_type = "outside"

    
    
    exterior1.cells[1].accessDown = true
    exterior1.cells[1].accessRight = true
    exterior1.cells[2].accessDown = false
    exterior1.cells[2].accessRight = true
    exterior1.cells[3].accessRight = false
    exterior1.cells[3].accessDown = false
    exterior1.cells[4].accessRight = false
    exterior1.cells[4].accessDown = true
    exterior1.cells[5].accessDown = false
    exterior1.cells[5].accessRight = true
    exterior1.cells[6].accessDown = true
    exterior1.cells[6].accessRight = false
    exterior1.cells[7].accessDown = true
    exterior1.cells[7].accessRight = false
    exterior1.cells[8].accessDown = false
    exterior1.cells[8].accessRight = true
    --exterior1.cells[9].accessDown = false
    exterior1.cells[9].accessRight = true
    exterior1.cells[9].accessDown = true


    
   -- exterior1.cells[8].accessDown = false
    --rescue_entry.cells[5].accessRight = false
    --exterior1.cells[6].accessRight = false
    exterior1.cells[9].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 203,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    library["exterior1"] = exterior1

    -- =====================================================================
    -- EXRERIOR2 TILE (some outside space)
    -- =====================================================================

    local exterior2 = create_tile_prototype("exterior2")
    exterior2.visualTile = "exterior2_computerGame"
    exterior2.visualTileComputer = "exterior2_computerGame"
    exterior2.visualTileBoardgame = "exterior2_boardGame"
    for i = 1, 9 do
        exterior2.cells[i].lightValue = 0
        exterior2.cells[i].moveValue = 1
        exterior2.cells[i].coverValue = 1
        exterior2.cells[i].isOutside = true
    end
    exterior2.cells[3].moveValue = 3
    exterior2.cells[6].moveValue = 3

    exterior2.cells[1].hazard_type = "outside"
    exterior2.cells[2].hazard_type = "outside"
    exterior2.cells[3].hazard_type = "outside"
    exterior2.cells[4].hazard_type = "outside"
    exterior2.cells[5].hazard_type = "outside"
    exterior2.cells[6].hazard_type = "outside"
    exterior2.cells[7].hazard_type = "outside"
    exterior2.cells[8].hazard_type = "outside"
    exterior2.cells[9].hazard_type = "outside"



    exterior2.cells[1].accessDown = true
    exterior2.cells[1].accessRight = true
    exterior2.cells[2].accessDown = true
    exterior2.cells[2].accessRight = true
    exterior2.cells[3].accessRight = true
    exterior2.cells[3].accessDown = false
    exterior2.cells[4].accessRight = false
    exterior2.cells[4].accessDown = true
    exterior2.cells[5].accessDown = true
    exterior2.cells[5].accessRight = false
    exterior2.cells[6].accessDown = false
    exterior2.cells[6].accessRight = false
    exterior2.cells[7].accessDown = true
    exterior2.cells[7].accessRight = false
    exterior2.cells[8].accessDown = false
    exterior2.cells[8].accessRight = false
    --exterior2.cells[9].accessDown = false
    exterior2.cells[9].accessRight = false
    exterior2.cells[9].accessDown = false



    -- exterior2.cells[8].accessDown = false
    --rescue_entry.cells[5].accessRight = false
    --exterior2.cells[6].accessRight = false
    -- exterior2.cells[9].object1 = {
    --     name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 203,
    --     offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    -- }
    library["exterior2"] = exterior2

-- =====================================================================
-- COMS (acquire Nav data)
-- =====================================================================
    local coms = create_tile_prototype("coms")
    coms.visualTile = "coms_off"
    coms.powerLightOffAnim = "tile_coms_off"
    coms.powerLightOnAnim = "tile_coms_on"
   
    for i = 1, 9 do
        coms.cells[i].lightValue = 3
        coms.cells[i].moveValue = 1
        coms.cells[i].coverValue = 1
    end
    coms.cells[1].lightValue = 0
    coms.cells[2].lightValue = 1
    coms.cells[3].lightValue = 0
    coms.cells[4].lightValue = 2
    coms.cells[5].lightValue = 2
    
    coms.cells[3].moveValue = 3
    coms.cells[6].moveValue = 3

    coms.cells[1].accessDown = false
    coms.cells[1].accessRight = false
    coms.cells[2].accessDown = true
    coms.cells[2].accessRight = false
    coms.cells[3].accessRight = false
    coms.cells[3].accessDown = false
    coms.cells[4].accessDown = false
    coms.cells[4].accessRight = true
    coms.cells[5].accessDown = true
    coms.cells[5].accessRight = false
    coms.cells[6].accessDown = false
    coms.cells[6].accessRight = false
    coms.cells[7].accessDown = true
    coms.cells[7].accessRight = true
    coms.cells[8].accessDown = false
    coms.cells[8].accessRight = true
    coms.cells[9].accessDown = false
    coms.cells[9].accessRight = true

--     coms.cells[4].object1 = {
--         name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
--         offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
--     }
-- 
coms.cells[7].object1 = {
    name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
    offsetX = -100, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
    lootItems = { "power", "wiring_straight", "meds", "material", COMPONENT_UI.component_fuse }
}
coms.cells[2].object1 = {
    name = hash("power_node"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 201,
    offsetX = -90, offsetY = 5, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 64, requiredComponent = nil,
    powerLoaded = 0, powerRequired = 9
}

coms.cells[4].object2 = {
    name = hash("gun_turret"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 902,
    offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
}

coms.cells[5].object1 = {
    name = hash("wiregap"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 501,
    offsetX = 80, offsetY = -10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = "/sparks_small_fx_factory#sparks_small_fx_factory", hitW = 32, hitH = 32, requiredComponent = COMPONENT_UI.component_wiring_straight
}

coms.cells[5].object2 = {
    name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 502,
    offsetX = -90, offsetY = -27, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
    stackCount = 1, obstacleCount = 1
}



coms.cells[4].object1 = {
    name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
    offsetX = -50, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
}

coms.cells[9].object1 = {
    name = hash("nav_computer"), isFixed = true, hasNavData = true, contributesToExitObjective = false,
    isWelded = false, isOpen = false, dependsOn = 501, isDependentOn = {}, objectId = 901,
    offsetX = 70, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 56, hitH = 56, requiredComponent = COMPONENT_UI.component_nav_data
}

coms.cells[9].object2 = {
    name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 902,
    offsetX = 45, offsetY = -27, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
    stackCount = 1, obstacleCount = 1
}

coms.cells[8].object1 = {
    name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 801,
    offsetX = -90, offsetY = -27, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
    stackCount = 1, obstacleCount = 1
}
coms.cells[8].object2 = {
    name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 802,
    offsetX = 0, offsetY = -27, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
    stackCount = 1, obstacleCount = 1
}
-- 
library["coms"] = coms

-- =====================================================================
-- CANTEEN (acquire food supplies)
-- =====================================================================
local canteen = create_tile_prototype("canteen")
canteen.visualTile = "canteen_off"
canteen.powerLightOffAnim = "tile_canteen_off"
canteen.powerLightOnAnim = "tile_canteen_on"

for i = 1, 9 do
    canteen.cells[i].lightValue = 3
    canteen.cells[i].moveValue = 1
    canteen.cells[i].coverValue = 1
end
canteen.cells[5].lightValue = 0
canteen.cells[6].lightValue = 0

canteen.cells[3].moveValue = 3
canteen.cells[6].moveValue = 3

canteen.cells[1].accessDown = true--false
--canteen.cells[1].accessRight = false
--canteen.cells[2].accessRight = false
--canteen.cells[3].accessRight = false
canteen.cells[3].accessDown = false
--canteen.cells[4].accessDown = false
canteen.cells[4].accessRight = false
--canteen.cells[4].accessDown = false
canteen.cells[5].accessRight = true
canteen.cells[5].accessDown = false
canteen.cells[6].accessRight = false
canteen.cells[6].accessDown = true
canteen.cells[8].accessDown = false
canteen.cells[9].accessDown = false
canteen.cells[9].accessRight = false

--     coms.cells[4].object1 = {
--         name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
--         offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
--     }
-- 

canteen.cells[3].object1 = {
    name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
    offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
}
canteen.cells[1].object1 = {
    name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
    offsetX = -100, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
    lootItems = { "power", "plate", "material", "ammo","material","ammo", COMPONENT_UI.component_fuse }
}


--canteen.cells[3].hazard_type = "gas"
canteen.cells[4].object1 = {
    name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
    offsetX = -90, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
    lootItems = {
        "power",
        "wiring_straight",
        "plate",
        "ammo",
        "meds",
        --"material"
        -- "buff_armour",
        -- "buff_hazmat",
        -- "buff_oxygen_mask",
        -- "buff_speed_stims",
        "buff_night_vision",
        -- "buff_melee_left",
        -- "buff_melee_right"
    }
}
canteen.cells[4].object2 = {
    name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
    offsetX = 0, offsetY = 40, hitW = 32, hitH = 32, requiredComponent = nil
}
canteen.cells[6].object1 = {
    name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 601,
    offsetX = 40, offsetY = 0, hitW = 32, hitH = 32, requiredComponent = nil
}
canteen.cells[5].object1 = {
    name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 501,
    offsetX = -90, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
    lootItems = {
        "power",
        "wiring_straight",
        "plate",
        "ammo",
        "meds",
        --"material"
        -- "buff_armour",
        -- "buff_hazmat",
        -- "buff_oxygen_mask",
        -- "buff_speed_stims",
        --"buff_night_vision",
        "buff_melee_left",
        -- "buff_melee_right"
    }
}
canteen.cells[2].object1 = {
    name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 201,
    offsetX = -90, offsetY = -27, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
    stackCount = 1, obstacleCount = 1
}
canteen.cells[2].object2 = {
    name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
    offsetX = 0, offsetY = -27, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
    stackCount = 1, obstacleCount = 1
}
canteen.cells[2].object3 = {
    name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 203,
    offsetX = 32, offsetY = -27, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
    stackCount = 1, obstacleCount = 1
}
--canteen.cells[2].hazard_type = "gas"
canteen.cells[1].object1 = {
    name = hash("power_node"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
    offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 64, requiredComponent = nil,
    powerLoaded = 0, powerRequired = 9
}
--canteen.cells[1].hazard_type = "gas"
canteen.cells[8].object1 = {
    name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 801,
    offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
}

canteen.cells[9].object1 = {
    name = hash("wiregap"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 901,
    offsetX = 75, offsetY = -20, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = "/sparks_small_fx_factory#sparks_small_fx_factory", hitW = 32, hitH = 32, requiredComponent = COMPONENT_UI.component_wiring_straight
}

-- canteen.cells[4].object1 = {
--     name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
--     offsetX = -50, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
-- }
-- canteen.cells[8].object2 = {
--     name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 802,
--     offsetX = -90, offsetY = -27, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
--     stackCount = 1, obstacleCount = 1
-- }
-- canteen.cells[8].object3 = {
--     name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 803,
--     offsetX = 0, offsetY = -27, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
--     stackCount = 1, obstacleCount = 1
-- }
-- canteen.cells[8].object4 = {
--     name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 804,
--     offsetX = 32, offsetY = -27, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
--     stackCount = 1, obstacleCount = 1
-- }
--canteen.cells[8].hazard_type = "fire"

canteen.cells[9].object2 = {
    name = hash("supply_loader"), isFixed = true, hasFood = true, contributesToExitObjective = false,
    isWelded = false, isOpen = false, dependsOn = 901, isDependentOn = {}, objectId = 902,
    offsetX = 70, offsetY = 3, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 56, hitH = 56, requiredComponent = COMPONENT_UI.component_food_supplies
}
-- canteen.cells[9].object3 = {
--     name = hash("civilian_spawn"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 903,
--     offsetX = -40, offsetY = -4, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 40, hitH = 60, requiredComponent = nil
-- }
-- canteen.cells[7].object1 = {
--     name = hash("civilian_spawn"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 701,
--     offsetX = -40, offsetY = -4, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 40, hitH = 60, requiredComponent = nil
-- }
--canteen.cells[7].hazard_type = "fire"
-- 
-- 
library["canteen"] = canteen

-- =====================================================================
-- EXIT (escape pod)
-- =====================================================================

    -- exit / escape pod (art hook: tile_exit)
    local exit = create_tile_prototype("exit")
    exit.visualTile = "exit_off"
    exit.powerLightOffAnim = "tile_exit_off"
    exit.powerLightOnAnim = "tile_exit_on"
    for i = 1, 9 do
        exit.cells[i].lightValue = 2
        exit.cells[i].moveValue = 1
        exit.cells[i].coverValue = 1
    end

    exit.cells[1].accessDown = false
    exit.cells[1].accessRight = false
    --exit.cells[2].accessDown = false
    exit.cells[3].accessDown = false
    exit.cells[3].accessRight = false
    exit.cells[4].accessDown = false
    exit.cells[6].accessDown = false
    exit.cells[6].accessRight = false
    exit.cells[7].accessRight = false
    exit.cells[8].accessRight = false
    exit.cells[9].accessRight = false
    exit.cells[9].accessDown = false

    exit.cells[2].object1 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 201,
        offsetX = -100, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = {
            "power",
            "power",
            "power",
            "ammo",
            "ammo",
            "ammo",
            "ammo",
            "ammo"
            -- "buff_hazmat",
            -- "buff_oxygen_mask",
            -- "buff_speed_stims",
            -- "buff_night_vision",
            -- "buff_melee_left",
            -- "buff_melee_right"
        }
    }

    exit.cells[2].object2 = {
        name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
        offsetX = -50, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    }
    
    exit.cells[3].object1 = {
        name = hash("escape_pod_power_socket"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 2301,
        -- Slot grid center matches updated tile art at (x=616, y=373) in 750x450 tile space.
        -- Cell 3 center is (625, 375), so the socket anchor offset is (-9, -2).
        offsetX = -9, offsetY = -2, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 170, hitH = 170, requiredComponent = nil,
        powerLoaded = 0, powerRequired = 9
    }

    exit.cells[4].object1 = {
        name = hash("power_node"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
        offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 64, requiredComponent = nil,
        powerLoaded = 0, powerRequired = 9
    }
    
    exit.cells[6].object1 = {
        name = hash("escape_pod_seatbay"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 2601,
        offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 132, hitH = 86, requiredComponent = nil,
        seatCapacity = 4
    }
    exit.cells[8].object1 = {
        name = hash("nav_computer"), isFixed = false, hasNavData = false, contributesToExitObjective = true,
        isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 2801,
        offsetX = -90, offsetY = 14, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 56, hitH = 56, requiredComponent = COMPONENT_UI.component_nav_data
    }
    exit.cells[8].object2 = {
        name = hash("supply_loader"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 2802,
        offsetX = 0, offsetY = -6, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 64, hitH = 56, requiredComponent = COMPONENT_UI.component_food_supplies
    }
    library["exit"] = exit

-- =====================================================================
-- ARMOURY
-- =====================================================================
    local armoury = create_tile_prototype("armoury")
    armoury.visualTile = "armoury_off"
    armoury.powerLightOffAnim = "tile_armoury_off"
    armoury.powerLightOnAnim = "tile_armoury_on"
    for i = 1, 9 do
        armoury.cells[i].moveValue = 1
        armoury.cells[i].coverValue = 1
    end
    armoury.cells[1].lightValue = 3
    armoury.cells[2].lightValue = 3
    armoury.cells[3].lightValue = 2
    armoury.cells[4].lightValue = 3
    armoury.cells[5].lightValue = 3
    armoury.cells[6].lightValue = 1
    armoury.cells[7].lightValue = 3
    armoury.cells[8].lightValue = 3
    armoury.cells[9].lightValue = 2

    --armoury.cells[1].accessDown = false
    armoury.cells[2].accessDown = false
    armoury.cells[3].accessDown = false
    armoury.cells[3].accessRight = false
    armoury.cells[4].accessRight = false
    armoury.cells[5].accessRight = false
    armoury.cells[5].accessDown = false
    armoury.cells[6].accessRight = false
    armoury.cells[6].accessDown = false
    --armoury.cells[7].accessRight = false
    armoury.cells[8].accessDown = false
    armoury.cells[9].accessDown = false

    armoury.cells[1].object1 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
        offsetX = -100, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = { "power", "plate", "material", "material","ammo","material","meds", COMPONENT_UI.component_fuse }
    }
    armoury.cells[2].object1 = {
        name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 201,
        offsetX = -100, offsetY = 35, hitW = 32, hitH = 32, requiredComponent = nil
    }
    armoury.cells[2].object2 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    -- armoury.cells[2].object3 = {
    --     name = hash("blip_spawn"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 203,
    --     offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 16, hitH = 16, requiredComponent = nil
    -- }
    armoury.cells[3].object1 = {
        name = hash("power_node"), isFixed = true, dependsOn = 0, isDependentOn = {}, objectId = 301,
        offsetX = 90, offsetY = 10, fxOffsetX = 20, fxOffsetY = -20, fxRotation = 90, hitW = 64, hitH = 124, requiredComponent = nil
    }
    armoury.cells[4].object1 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
        offsetX = 0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = { "power", "plate", "material","material", "material","ammo","meds" ,COMPONENT_UI.component_fuse }
    }
    armoury.cells[7].object1 = {
        name = hash("ammo_vending_machine"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 701,
        offsetX = -90, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 64, hitH = 124, requiredComponent = COMPONENT_UI.component_fuse
    }
    armoury.cells[7].object2 = {
        name = hash("relay"), isFixed = false, dependsOn = 6101, isDependentOn = {}, objectId = 702,
        offsetX = 10, offsetY = 8, hitW = 32, hitH = 32, requiredComponent = COMPONENT_UI.item_type_blue
    }
    armoury.cells[8].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 801,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    -- armoury.cells[8].object2 = {
    --     name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 802,
    --     offsetX = -100, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    -- }
    -- armoury.cells[8].object3 = {
    --     name = hash("blip_spawn"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 803,
    --     offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 16, hitH = 16, requiredComponent = nil
    -- }
    armoury.cells[9].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 901,
        offsetX = 110, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    armoury.cells[9].object2 = {
        name = hash("gun_turret"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 902,
        offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    -- armoury.cells[9].object3 = {
    --     name = hash("blip_spawn"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 903,
    --     offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 16, hitH = 16, requiredComponent = nil
    -- }
    assign_random_loot_cell(armoury)
    library["armoury"] = armoury

-- =====================================================================
-- MEDBAY
-- =====================================================================
     local medbay = create_tile_prototype("medbay")
     medbay.visualTile = "medbay_off"
     medbay.powerLightOffAnim = "tile_medbay_off"
    medbay.powerLightOnAnim = "tile_medbay_on"

    medbay.alphaOverlayMode = "specified"
    --medbay.alphaOverlay = "tile_medbay_overlay"
    
     for i = 1, 9 do
         medbay.cells[i].lightValue = 1
         medbay.cells[i].moveValue = 1
         medbay.cells[i].coverValue = 2
    end

    medbay.cells[1].lightValue = 3
    medbay.cells[2].lightValue = 3
    medbay.cells[4].lightValue = 3
    medbay.cells[7].lightValue = 3
    medbay.cells[8].lightValue = 2
    medbay.cells[9].lightValue = 2
    
     -- Example access pattern edits:
    medbay.cells[2].accessDown = false
    medbay.cells[3].accessDown = true
    medbay.cells[3].accessRight = false
    medbay.cells[4].accessRight = false
    medbay.cells[5].accessDown = false
    medbay.cells[8].accessDown = false
    medbay.cells[9].accessDown = false
    medbay.cells[9].accessRight = false
     -- medbay.cells[9].accessRight = false
    
    -- Example authored objects:
    medbay.cells[1].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
        offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    medbay.cells[2].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 201,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    medbay.cells[4].object1 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
        offsetX = 0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = { "ammo", "ammo", "material", "plate" ,"wiring_straight", "material", COMPONENT_UI.component_fuse, COMPONENT_UI.component_wiring_straight}
    }
     medbay.cells[5].object1 = {
         name = hash("power_node"), isFixed = true, dependsOn = 0, isDependentOn = {}, objectId = 501,
         offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil
    }
    medbay.cells[5].object2 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 502,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    medbay.cells[5].object3 = {
        name = hash("wiregap"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 503,
        offsetX = -5, offsetY = 45, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = "/sparks_small_fx_factory#sparks_small_fx_factory", hitW = 32, hitH = 32, requiredComponent = COMPONENT_UI.component_wiring_straight
    }

    medbay.cells[6].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 503, isDependentOn = {}, objectId = 601,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }

    medbay.cells[8].object1 = {
        name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
        offsetX = -110, offsetY = 15, hitW = 32, hitH = 32, requiredComponent = nil
    }
    medbay.cells[8].object2 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 601,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }

    medbay.cells[9].object1 = {
        name = hash("med_vending_machine"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 503, isDependentOn = {}, objectId = 901,
        offsetX = -80, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 64, hitH = 124, requiredComponent = COMPONENT_UI.component_fuse
    }
    medbay.cells[9].object2 = {
        name = hash("medbay_reviver"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 902,
        offsetX = 80, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 1, hitH = 1, requiredComponent = nil
    }

    -- medbay.cells[9].object3 = {
    --     name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 601,
    --     offsetX = 20, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    -- }
     -- medbay.cells[8].object2 = {
     --     name = hash("blip_spawn"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 5802,
     --     offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 16, hitH = 16, requiredComponent = nil
     -- }
    
     -- Choose deterministic or random loot behavior:
     -- assign_fixed_loot_cell(medbay, 5)
     -- assign_random_loot_cell(medbay)
    
     -- Enable when ready:
     library["medbay"] = medbay


-- =====================================================================
-- PASSAGE 1 (vertical only in middle)
-- =====================================================================
    local passage1 = create_tile_prototype("passage1")
    passage1.visualTile = "passage1_off"
    passage1.powerLightOffAnim = "tile_passage1_off"
    passage1.powerLightOnAnim = "tile_passage1_on"

    for i = 1, 9 do
        passage1.cells[i].lightValue = 0
        passage1.cells[i].moveValue = 0
        passage1.cells[i].coverValue = 0
    end

    passage1.cells[5].lightValue = 2
    passage1.cells[4].moveValue = 1
    passage1.cells[3].moveValue = 3
    passage1.cells[6].moveValue = 3
    passage1.cells[9].moveValue = 3

    -- Internal connectivity:
    -- - Vertical shaft only on right column: 3 <-> 6 <-> 9
    -- - Single isolated accessible cell: 4
    -- - Cell 4 remains enterable from left neighbor tile via edge rules.
    passage1.cells[1].accessDown = false   -- blocks 2 <-> 3
    passage1.cells[1].accessRight = false   -- blocks 2 <-> 3
    passage1.cells[2].accessDown = true   -- blocks 2 <-> 3
    passage1.cells[2].accessRight = false   -- blocks 2 <-> 3
    passage1.cells[3].accessRight = false   -- blocks right boundary from 3
    passage1.cells[3].accessDown = false
    passage1.cells[4].accessRight = false   -- blocks 4 <-> 5
    passage1.cells[4].accessDown = false    -- blocks 4 <-> 1
    passage1.cells[5].accessDown = true
    passage1.cells[5].accessRight = false   -- blocks 5 <-> 6
    passage1.cells[6].accessRight = false   -- blocks right boundary from 6
    passage1.cells[6].accessDown = false     -- allows 6 <-> 3
    passage1.cells[7].accessRight = false   -- blocks 7 <-> 8
    passage1.cells[7].accessDown = false    -- blocks 7 <-> 4
    passage1.cells[8].accessDown = true
    passage1.cells[8].accessRight = false   -- blocks 8 <-> 9
    passage1.cells[9].accessRight = false   -- blocks right boundary from 9
    passage1.cells[9].accessDown = false     -- allows 9 <-> 6


passage1.cells[5].object1 = {
    name = hash("power_node"), isFixed = true, dependsOn = 0, isDependentOn = {}, objectId = 601,
    offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil
}

library["passage1"] = passage1

-- =====================================================================
-- CORRIDOR 1 (horizontal middle row)
-- =====================================================================
local corridor1 = create_tile_prototype("corridor1")
corridor1.visualTile = "corridor1_off"
corridor1.powerLightOffAnim = "tile_corridor1_off"
corridor1.powerLightOnAnim = "tile_corridor1_on"

for i = 1, 9 do
    corridor1.cells[i].lightValue = 0
    corridor1.cells[i].moveValue = 1
    corridor1.cells[i].coverValue = 1
end

corridor1.cells[4].lightValue = 1
corridor1.cells[5].lightValue = 3
corridor1.cells[6].lightValue = 1

-- passage1.cells[4].lightValue = 1
-- passage1.cells[4].moveValue = 1
-- passage1.cells[3].moveValue = 3
-- passage1.cells[6].moveValue = 3
-- passage1.cells[9].moveValue = 3

-- Internal connectivity:
-- - Vertical shaft only on right column: 3 <-> 6 <-> 9
-- - Single isolated accessible cell: 4
-- - Cell 4 remains enterable from left neighbor tile via edge rules.
corridor1.cells[1].accessDown = false   -- blocks 2 <-> 3
corridor1.cells[1].accessRight = true   -- blocks 2 <-> 3
corridor1.cells[2].accessDown = true   -- blocks 2 <-> 3
corridor1.cells[2].accessRight = false   -- blocks 2 <-> 3
corridor1.cells[3].accessRight = false   -- blocks right boundary from 3
corridor1.cells[3].accessDown = false
corridor1.cells[4].accessRight = true   -- blocks 4 <-> 5
corridor1.cells[4].accessDown = false    -- blocks 4 <-> 1
corridor1.cells[5].accessDown = true
corridor1.cells[5].accessRight = true   -- blocks 5 <-> 6
corridor1.cells[6].accessRight = true   -- blocks right boundary from 6
corridor1.cells[6].accessDown = false     -- allows 6 <-> 3
corridor1.cells[7].accessRight = true   -- blocks 7 <-> 8
corridor1.cells[7].accessDown = false    -- blocks 7 <-> 4
corridor1.cells[8].accessDown = true
corridor1.cells[8].accessRight = true   -- blocks 8 <-> 9
corridor1.cells[9].accessRight = false   -- blocks right boundary from 9
corridor1.cells[9].accessDown = false     -- allows 9 <-> 6


corridor1.cells[5].object1 = {
    name = hash("power_node"), isFixed = true, dependsOn = 0, isDependentOn = {}, objectId = 601,
    offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil
}

library["corridor1"] = corridor1

-- =====================================================================
-- LAB (horizontal middle row)
-- =====================================================================
local lab = create_tile_prototype("lab")
lab.visualTile = "lab_off"
lab.powerLightOffAnim = "tile_lab_off"
lab.powerLightOnAnim = "tile_lab_on"

lab.alphaOverlayMode = "specified"
lab.alphaOverlay = "tile_lab_overlay"

for i = 1, 9 do
    lab.cells[i].lightValue = 3
    lab.cells[i].moveValue = 0
    lab.cells[i].coverValue = 0
end

--lab.cells[1].lightValue = 3
--lab.cells[2].lightValue = 3

-- lab.cells[4].moveValue = 1
-- lab.cells[3].moveValue = 3
-- lab.cells[6].moveValue = 3
-- lab.cells[9].moveValue = 3

-- Internal connectivity:
-- - Vertical shaft only on right column: 3 <-> 6 <-> 9
-- - Single isolated accessible cell: 4
-- - Cell 4 remains enterable from left neighbor tile via edge rules.
lab.cells[1].accessDown = false   -- blocks 2 <-> 3
lab.cells[1].accessRight = true   -- blocks 2 <-> 3
lab.cells[2].accessDown = false   -- blocks 2 <-> 3
lab.cells[2].accessRight = true   -- blocks 2 <-> 3
lab.cells[3].accessRight = false   -- blocks right boundary from 3
lab.cells[3].accessDown = true
lab.cells[4].accessRight = true   -- blocks 4 <-> 5
lab.cells[4].accessDown = true    -- blocks 4 <-> 1
lab.cells[5].accessDown = false
lab.cells[5].accessRight = true   -- blocks 5 <-> 6
lab.cells[6].accessRight = true   -- blocks right boundary from 6
lab.cells[6].accessDown = false     -- allows 6 <-> 3
lab.cells[7].accessRight = false   -- blocks 7 <-> 8
lab.cells[7].accessDown = false    -- blocks 7 <-> 4
lab.cells[8].accessDown = false
lab.cells[8].accessRight = false   -- blocks 8 <-> 9
lab.cells[9].accessRight = false   -- blocks right boundary from 9
lab.cells[9].accessDown = false     -- allows 9 <-> 6

lab.cells[4].object1 = {
    name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
    offsetX = -50, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
}

lab.cells[4].object2 = {
    name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 402,
    offsetX = 110, offsetY = 5, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate,
    isSecureAlienProof = true
}
lab.cells[6].object2 = {
    name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 402,
    offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate,
    isSecureAlienProof = true
}

lab.cells[3].object2 = {
    name = hash("power_node"), isFixed = true, dependsOn = 0, isDependentOn = {}, objectId = 601,
    offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil
}

library["lab"] = lab

-- =====================================================================
-- FACTORY
-- =====================================================================
    local factory = create_tile_prototype("factory")
    factory.visualTile = "factory_off"
    factory.powerLightOffAnim = "tile_factory_off"
    factory.powerLightOnAnim = "tile_factory_on"

    for i = 1, 9 do
        factory.cells[i].lightValue = 3
        factory.cells[i].moveValue = 1
        factory.cells[i].coverValue = 1
        factory.cells[i].accessRight = false
        factory.cells[i].accessDown = false
    end

    factory.cells[2].lightValue = 1
    factory.cells[3].lightValue = 1
    -- Requested internal connectivity:
    -- 2: right, 4: right, 5: right, 6: right + down
    factory.cells[2].accessRight = true
    factory.cells[2].accessDown = true
    factory.cells[4].accessRight = true
    factory.cells[5].accessRight = true
    factory.cells[6].accessRight = true
    factory.cells[6].accessDown = true
    factory.cells[8].accessDown = true

    -- Power node lane (cell 4)
    factory.cells[4].object1 = {
        name = hash("power_node"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
        offsetX = 90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 90, hitW = 64, hitH = 124, requiredComponent = nil,
        powerLoaded = 0, powerRequired = 9
    }

    -- Wiring dependency lane (cell 6)
    -- factory.cells[6].object1 = {
    --     name = hash("wiregap"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 601,
    --     offsetX = 78, offsetY = -8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = "/sparks_small_fx_factory#sparks_small_fx_factory", hitW = 32, hitH = 32, requiredComponent = COMPONENT_UI.component_wiring_straight
    -- }

    factory.cells[6].object2 = {
        name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 602,
        offsetX = -90, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    }
    factory.cells[6].object3 = {
        name = hash("ammo_vending_machine"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 603,
        offsetX = 0, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 64, hitH = 124, requiredComponent = COMPONENT_UI.component_fuse
    }

    -- Factory machinery anchors (cells 5 and 8). These are fixed but only functional
    -- when their dependency chain is satisfied.
    factory.cells[5].object1 = {
        name = hash("factory_machine"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 501,
        offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 84, hitH = 84, requiredComponent = nil
    }
    factory.cells[8].object1 = {
        name = hash("factory_machine"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 801,
        offsetX = 0, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 84, hitH = 84, requiredComponent = nil
    }

    library["factory"] = factory

-- =====================================================================
-- WORKSHOP
-- =====================================================================
    local workshop = create_tile_prototype("workshop")
    workshop.visualTile = "workshop_off"
    workshop.powerLightOffAnim = "tile_workshop_off"
    workshop.powerLightOnAnim = "tile_workshop_on"

    workshop.alphaOverlayMode = "specified"
    workshop.alphaOverlay = "tile_workshop_overlay"

    for i = 1, 9 do
        workshop.cells[i].lightValue = 2
        workshop.cells[i].moveValue = 1
        workshop.cells[i].coverValue = 1
        workshop.cells[i].accessRight = false
        workshop.cells[i].accessDown = false
    end

    -- Internal connectivity:
    -- - Ladder lane in center column (2 <-> 5 <-> 8)
    -- - Cell 7 menu is reachable from cell 8
    -- - Cell 2 output lane can reach power-node lane (cell 3)
    -- - Cell 9 remains blocked
    workshop.cells[2].accessRight = true
    workshop.cells[2].accessDown = true
    workshop.cells[5].accessDown = true
    workshop.cells[5].accessRight = true
    workshop.cells[6].accessRight = true
    workshop.cells[7].accessRight = true
    workshop.cells[8].accessDown = true

    -- Power node lane (cell 3)
    workshop.cells[3].object1 = {
        name = hash("power_node"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
        offsetX = 80, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 90, hitW = 64, hitH = 124, requiredComponent = nil,
        powerLoaded = 0, powerRequired = 9
    }
    workshop.cells[3].object2 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 302,
        offsetX = -0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = { "material", "wiring_straight","material","material","material","material","fuse", COMPONENT_UI.component_fuse }
    }


    -- Wiring dependency lane (cell 6)
    workshop.cells[6].object1 = {
        name = hash("wiregap"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 601,
        offsetX = 84, offsetY = 34, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = "/sparks_small_fx_factory#sparks_small_fx_factory", hitW = 32, hitH = 32, requiredComponent = COMPONENT_UI.component_wiring_straight
    }
    workshop.cells[6].object2 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 602,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }

    -- Machine base (cell 4) is the fixable workshop machine.
    workshop.cells[4].object1 = {
        name = hash("workshop_machine"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 601, isDependentOn = {}, objectId = 401,
        offsetX = -56, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 132, hitH = 124, requiredComponent = COMPONENT_UI.component_fuse
    }

   

    -- Machine top visual anchor (cell 1). Non-fixable.
    workshop.cells[1].object1 = {
        name = hash("workshop_machine_top"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 401, isDependentOn = {}, objectId = 101,
        offsetX = -56, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 132, hitH = 116, requiredComponent = nil
    }

    -- Workshop order menu + payment hotspot lane (cell 7).
    workshop.cells[7].object1 = {
        name = hash("workshop_menu"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 401, isDependentOn = {}, objectId = 701,
        offsetX = -56, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 170, hitH = 118, requiredComponent = nil
    }

    workshop.cells[8].object1 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 302,
        offsetX = -0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = { "wiring_straight","fuse","wiring_straight", COMPONENT_UI.component_fuse }
    }

    library["workshop"] = workshop


-- =====================================================================
-- PORTAL (alien spawn point to be destoryed)
-- =====================================================================
    local portal = create_tile_prototype("portal")
    portal.visualTile = "portal_off"
    portal.powerLightOffAnim = "tile_portal_off"
    portal.powerLightOnAnim = "tile_portal_on"
    
    for i = 1, 9 do
        portal.cells[i].lightValue = 2
        portal.cells[i].moveValue = 1
        portal.cells[i].coverValue = 1
    end
    portal.cells[3].moveValue = 3
    portal.cells[6].moveValue = 3

    --portal.cells[1].accessDown = false
    portal.cells[2].accessDown = false
    portal.cells[3].accessDown = false
    portal.cells[3].accessRight = false
    portal.cells[4].accessRight = false
    portal.cells[6].accessDown = false
    --portal.cells[6].accessRight = false
    portal.cells[7].accessRight = false
    portal.cells[9].accessDown = false
    portal.cells[9].accessRight = false
       

    portal.cells[4].object1 = {
        name = hash("power_node"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
        offsetX = -80, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil,
        powerLoaded = 0, powerRequired = 9
    }

    portal.cells[6].object1 = {
        name = hash("blip_spawn"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 903,
        offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 16, hitH = 16, requiredComponent = nil
    }

    portal.cells[5].object1 = {
        name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 601,
        offsetX = -100, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    }
    -- portal.cells[9].object1 = {
    --     name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
    --     offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    -- }

    library["portal"] = portal


    -- =====================================================================
    -- BUNKROOM (where civs slepy, vertical passage acces up/down in the middle)
    -- =====================================================================
    local bunkroom = create_tile_prototype("bunkroom")
    bunkroom.visualTile = "bunkroom_off"
    bunkroom.powerLightOffAnim = "tile_bunkroom_off"
    bunkroom.powerLightOnAnim = "tile_bunkroom_on"

    for i = 1, 9 do
        bunkroom.cells[i].lightValue = 3
        bunkroom.cells[i].moveValue = 1
        bunkroom.cells[i].coverValue = 1
    end
    bunkroom.cells[3].moveValue = 3
    bunkroom.cells[6].moveValue = 3

    bunkroom.cells[2].lightValue = 1
    bunkroom.cells[5].lightValue = 1
    bunkroom.cells[8].lightValue = 1

    --portal.cells[1].accessDown = false
    bunkroom.cells[2].accessDown = true
    bunkroom.cells[5].accessDown = true
    bunkroom.cells[7].accessDown = true
    
    bunkroom.cells[1].accessRight = true
    bunkroom.cells[2].accessRight = true
    bunkroom.cells[3].accessRight = false
    bunkroom.cells[4].accessRight = true
    bunkroom.cells[5].accessRight = true
    bunkroom.cells[6].accessRight = false
    bunkroom.cells[7].accessRight = true
    bunkroom.cells[8].accessRight = true
    bunkroom.cells[9].accessRight = false
    

    
    -- bunkroom.cells[6].accessDown = false
    -- --portal.cells[6].accessRight = false
    -- bunkroom.cells[7].accessRight = false
    -- bunkroom.cells[9].accessDown = false
    -- bunkroom.cells[9].accessRight = false

    bunkroom.cells[1].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    bunkroom.cells[2].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 201,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    bunkroom.cells[4].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    bunkroom.cells[5].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 501,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    bunkroom.cells[7].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 701,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    bunkroom.cells[8].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 801,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }

    bunkroom.cells[1].object2 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 102,
        offsetX = -70, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = { "plate","plate","buff_armour", "meds", COMPONENT_UI.component_fuse }
    }

    bunkroom.cells[3].object1 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
        offsetX = -70, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = { "ammo","power","buff_melee_right", "meds", COMPONENT_UI.component_fuse }
    }

    bunkroom.cells[6].object1 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 502,
        offsetX = -70, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = { "plate","buff_melee_left","ammo", "meds", COMPONENT_UI.component_fuse }
    }

    bunkroom.cells[2].object2 = {
        name = hash("power_node"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
        offsetX = -80, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil,
        powerLoaded = 0, powerRequired = 9
    }
    bunkroom.cells[2].object3 = {
        name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 203,
        offsetX = 20, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    }
    bunkroom.cells[8].object2 = {
        name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 802,
        offsetX = 20, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    }
    bunkroom.cells[5].object2 = {
        name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 502,
        offsetX = 20, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    }

--     bunkroom.cells[6].object1 = {
--         name = hash("blip_spawn"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 903,
--         offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 16, hitH = 16, requiredComponent = nil
--     }
-- 
    -- bunkroom.cells[5].object1 = {
    --     name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 601,
    --     offsetX = -100, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    -- }
    -- bunkroom.cells[9].object1 = {
    --     name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
    --     offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    -- }

    library["bunkroom"] = bunkroom

    -- =====================================================================
    -- JUNGLE (plants/hydroponics, access down 2/2, accesright = 9)
    -- =====================================================================
    local jungle = create_tile_prototype("jungle")
    jungle.visualTile = "jungle_off"
    jungle.powerLightOffAnim = "tile_jungle_off"
    jungle.powerLightOnAnim = "tile_jungle_on"

    for i = 1, 9 do
        jungle.cells[i].lightValue = 3
        jungle.cells[i].moveValue = 1
        jungle.cells[i].coverValue = 1
    end
    --jungle.cells[3].moveValue = 3
    --jungle.cells[6].moveValue = 3

    --portal.cells[1].accessDown = false
    jungle.cells[1].accessDown = true
    jungle.cells[2].accessDown = true
    jungle.cells[5].accessDown = false
    jungle.cells[6].accessDown = true
    jungle.cells[8].accessDown = false
    jungle.cells[9].accessDown = true
    

    jungle.cells[1].accessRight = true
    jungle.cells[2].accessRight = true
    jungle.cells[3].accessRight = false
    jungle.cells[4].accessRight = false
    jungle.cells[5].accessRight = false
    jungle.cells[6].accessRight = false
    jungle.cells[7].accessRight = false
    jungle.cells[8].accessRight = false
    jungle.cells[9].accessRight = true



    -- bunkroom.cells[6].accessDown = false
    -- --portal.cells[6].accessRight = false
    -- bunkroom.cells[7].accessRight = false
    -- bunkroom.cells[9].accessDown = false
    -- bunkroom.cells[9].accessRight = false


    jungle.cells[3].object1 = {
        name = hash("power_node"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 601,
        offsetX = -90, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 90, hitW = 64, hitH = 124, requiredComponent = nil,
        powerLoaded = 0, powerRequired = 9
    }

    jungle.cells[1].hazard_type = "gas"
    jungle.cells[2].hazard_type = "gas"
    jungle.cells[3].hazard_type = "gas"
    jungle.cells[4].hazard_type = "gas"
    jungle.cells[6].hazard_type = "gas"
    
    --     bunkroom.cells[6].object1 = {
    --         name = hash("blip_spawn"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 903,
    --         offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 16, hitH = 16, requiredComponent = nil
    --     }
    -- 
    -- jungle.cells[6].object2 = {
    --     name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 602,
    --     offsetX = 20, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    -- }
    jungle.cells[4].object1 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
        offsetX = -90, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = { "wiring_straight","plate", "buff_hazmat","buff_oxygen_mask", "buff_oxygen_mask",COMPONENT_UI.component_fuse }
    }
    jungle.cells[9].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }

    library["jungle"] = jungle

    -- =====================================================================
    -- SHOWERS (vertical only in middle)
    -- =====================================================================
    local showers = create_tile_prototype("showers")
    showers.visualTile = "showers_off"
    showers.powerLightOffAnim = "tile_showers_off"
    showers.powerLightOnAnim = "tile_showers_on"

    for i = 1, 9 do
        showers.cells[i].lightValue = 0
        showers.cells[i].moveValue = 1
        showers.cells[i].coverValue = 0
    end

    showers.cells[1].lightValue = 3
    showers.cells[2].lightValue = 3
    showers.cells[3].lightValue = 0
    showers.cells[4].lightValue = 3
    showers.cells[5].lightValue = 3
    showers.cells[6].lightValue = 1
    showers.cells[7].lightValue = 1
    showers.cells[8].lightValue = 1
    showers.cells[9].lightValue = 3
    -- showers.cells[4].moveValue = 1
    -- showers.cells[3].moveValue = 3
    -- showers.cells[6].moveValue = 3
    -- showers.cells[9].moveValue = 3

    -- Internal connectivity:
    -- - Vertical shaft only on right column: 3 <-> 6 <-> 9
    -- - Single isolated accessible cell: 4
    -- - Cell 4 remains enterable from left neighbor tile via edge rules.
    showers.cells[1].accessDown = false   -- blocks 2 <-> 3
    showers.cells[2].accessDown = true
    showers.cells[3].accessDown = true
    showers.cells[4].accessDown = false
    showers.cells[5].accessDown = true
    showers.cells[6].accessDown = true
    showers.cells[7].accessDown = true
    showers.cells[8].accessDown = true
    showers.cells[9].accessDown = false

    showers.cells[1].accessRight = true
    showers.cells[2].accessRight = false
    showers.cells[3].accessRight = false
    showers.cells[4].accessRight = true
    showers.cells[5].accessRight = false
    showers.cells[6].accessRight = true
    showers.cells[7].accessRight = false
    showers.cells[8].accessRight = true
    showers.cells[9].accessRight = false

    showers.cells[1].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }

    showers.cells[3].object1 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
        offsetX = -100, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = { "ammo", "ammo", "meds", "material","meds", "wiring_straight", COMPONENT_UI.component_fuse }
    }

    showers.cells[3].object2 = {
        name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 302,
        offsetX = 0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    }


    showers.cells[4].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }



    showers.cells[6].object1 = {
        name = hash("ammo_vending_machine"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 602, isDependentOn = {}, objectId = 601,
        offsetX = -90, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 64, hitH = 124, requiredComponent = COMPONENT_UI.component_fuse
    }

    showers.cells[6].object2 = {
        name = hash("wiregap"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 602,
        offsetX = 10, offsetY = 50, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = "/sparks_small_fx_factory#sparks_small_fx_factory", hitW = 32, hitH = 32, requiredComponent = COMPONENT_UI.component_wiring_straight
    }

    showers.cells[6].object3 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = true, dependsOn = 0, isDependentOn = {}, objectId = 603,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }

    showers.cells[8].object1 = {
        name = hash("power_node"), isFixed = true, dependsOn = 0, isDependentOn = {}, objectId = 801,
        offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil
    }

    showers.cells[8].object2 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = true, dependsOn = 0, isDependentOn = {}, objectId = 802,
        offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }

    showers.cells[9].object1 = {
        name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
        offsetX = -70, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    }

    library["showers"] = showers

    -- =====================================================================
    -- CAVERN (vertical only in middle)
    -- =====================================================================
    local cavern = create_tile_prototype("cavern")
    cavern.visualTile = "cavern_off"
    cavern.powerLightOffAnim = "tile_cavern_off"
    cavern.powerLightOnAnim = "tile_cavern_on"

    for i = 1, 9 do
        cavern.cells[i].lightValue = 0
        cavern.cells[i].moveValue = 1
        cavern.cells[i].coverValue = 0
    end

    cavern.cells[1].lightValue = 0
    cavern.cells[2].lightValue = 0
    cavern.cells[3].lightValue = 0
    cavern.cells[4].lightValue = 2
    cavern.cells[5].lightValue = 2
    cavern.cells[6].lightValue = 0
    cavern.cells[7].lightValue = 2
    cavern.cells[8].lightValue = 2
    cavern.cells[9].lightValue = 0

    cavern.cells[1].accessDown = false   -- blocks 2 <-> 3
    cavern.cells[2].accessDown = false
    cavern.cells[3].accessDown = false
    cavern.cells[4].accessDown = false
    cavern.cells[5].accessDown = true
    cavern.cells[6].accessDown = false
    cavern.cells[7].accessDown = true
    cavern.cells[8].accessDown = true
    cavern.cells[9].accessDown = false

    cavern.cells[1].accessRight = true
    cavern.cells[2].accessRight = true
    cavern.cells[3].accessRight = true
    cavern.cells[4].accessRight = false
    cavern.cells[5].accessRight = false
    cavern.cells[6].accessRight = false
    cavern.cells[7].accessRight = true
    cavern.cells[8].accessRight = false
    cavern.cells[9].accessRight = false

    cavern.cells[1].hazard_type = "gas"
    cavern.cells[2].hazard_type = "gas"
    cavern.cells[3].hazard_type = "gas"
   
cavern.cells[1].object1 = {
    name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
    offsetX = -0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
    lootItems = { "material", "material", "material", "material","material", "material" }
}

cavern.cells[2].object1 = {
    name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
    offsetX = -0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
    lootItems = { "material", "material", "material", "material","material", "material" }
}

cavern.cells[3].object1 = {
    name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
    offsetX = -0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
    lootItems = { "material", "material", "material", "material","material", "material" }
}

        cavern.cells[1].object2 = {
        name = hash("power_node"), isFixed = true, dependsOn = 0, isDependentOn = {}, objectId = 801,
        offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil
        }


library["cavern"] = cavern

        -- =====================================================================
        -- FURNACE (vertical only in middle)
        -- =====================================================================
        local furnace = create_tile_prototype("furnace")
        furnace.visualTile = "furnace_off"
        furnace.powerLightOffAnim = "tile_furnace_off"
        furnace.powerLightOnAnim = "tile_furnace_on"

        for i = 1, 9 do
            furnace.cells[i].lightValue = 0
            furnace.cells[i].moveValue = 1
            furnace.cells[i].coverValue = 0
        end

        furnace.cells[1].lightValue = 0
        furnace.cells[2].lightValue = 0
        furnace.cells[3].lightValue = 0
        furnace.cells[4].lightValue = 2
        furnace.cells[5].lightValue = 2
        furnace.cells[6].lightValue = 0
        furnace.cells[7].lightValue = 2
        furnace.cells[8].lightValue = 2
        furnace.cells[9].lightValue = 0

        furnace.cells[1].accessDown = false   -- blocks 2 <-> 3
        furnace.cells[2].accessDown = true
        furnace.cells[3].accessDown = false
        furnace.cells[4].accessDown = true
        furnace.cells[5].accessDown = false
        furnace.cells[6].accessDown = true
        furnace.cells[7].accessDown = false
        furnace.cells[8].accessDown = true
        furnace.cells[9].accessDown = true

        furnace.cells[1].accessRight = true
        furnace.cells[2].accessRight = true
        furnace.cells[3].accessRight = false
        furnace.cells[4].accessRight = true
        furnace.cells[5].accessRight = false
        furnace.cells[6].accessRight = true
        furnace.cells[7].accessRight = true
        furnace.cells[8].accessRight = false
        furnace.cells[9].accessRight = false

        -- furnace.cells[1].hazard_type = "gas"
        -- furnace.cells[2].hazard_type = "gas"
        -- furnace.cells[3].hazard_type = "gas"

--         furnace.cells[1].object1 = {
--             name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
--             offsetX = -0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
--             lootItems = { "material", "material", "material", "material","material", "material" }
--         }
-- 
--         furnace.cells[2].object1 = {
--             name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
--             offsetX = -0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
--             lootItems = { "material", "material", "material", "material","material", "material" }
--         }
-- 
--         furnace.cells[3].object1 = {
--             name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
--             offsetX = -0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
--             lootItems = { "material", "material", "material", "material","material", "material" }
--         }

        furnace.cells[1].object1 = {
            name = hash("door"), isFixed = true, isWelded = false, isOpen = true, dependsOn = 0, isDependentOn = {}, objectId = 101,
            offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
        }
        furnace.cells[6].object1 = {
            name = hash("door"), isFixed = true, isWelded = false, isOpen = true, dependsOn = 0, isDependentOn = {}, objectId = 601,
            offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
        }
        furnace.cells[7].object1 = {
            name = hash("door"), isFixed = true, isWelded = false, isOpen = true, dependsOn = 0, isDependentOn = {}, objectId = 701,
            offsetX = 115, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
        }
        furnace.cells[3].object1 = {
            name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 301,
            offsetX = -70, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
        }
        furnace.cells[6].object2 = {
            name = hash("power_node"), isFixed = true, dependsOn = 0, isDependentOn = {}, objectId = 602,
            offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil
        }

        furnace.cells[3].object2 = {
            name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
            offsetX = -90, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
            lootItems = {
                "power",
                --"wiring_straight",
                --"plate",
                --"ammo",
                --"meds",
                --"material"
                "buff_hazmat",
                "buff_hazmat",
                -- "buff_oxygen_mask",
                -- "buff_speed_stims",
                --"buff_night_vision",
                -- "buff_melee_left",
                -- "buff_melee_right"
            }
        }

        

        library["furnace"] = furnace
    
    return library
end

return M
