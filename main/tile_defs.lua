local M = {}

-- =============================================================================
-- TILE PROTOTYPE STRUCTURE
-- =============================================================================
local function create_tile_prototype(tile_id)
    local tile = {
        tileID = hash(tile_id),
        visualTile = tile_id,
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
    end
    entry.cells[3].moveValue = 3
    entry.cells[6].moveValue = 3

    entry.cells[1].accessDown = false
    entry.cells[2].accessDown = false
    entry.cells[3].accessRight = false
    entry.cells[3].accessDown = false
    entry.cells[4].accessDown = false
    entry.cells[5].accessDown = false
    entry.cells[5].accessRight = false
    entry.cells[6].accessRight = false

    entry.cells[9].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
        offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    
    library["entry"] = entry

-- =====================================================================
-- COMS (acquire Nav data)
-- =====================================================================
    local coms = create_tile_prototype("coms")
    coms.visualTile = "coms_off"
    coms.powerLightOffAnim = "tile_coms_off"
    coms.powerLightOnAnim = "tile_coms_on"
   
    for i = 1, 9 do
        coms.cells[i].lightValue = 2
        coms.cells[i].moveValue = 1
        coms.cells[i].coverValue = 1
    end
    coms.cells[3].moveValue = 3
    coms.cells[6].moveValue = 3

    coms.cells[1].accessDown = false
    coms.cells[1].accessRight = false
    coms.cells[2].accessRight = false
    coms.cells[3].accessRight = false
    coms.cells[3].accessDown = false
    coms.cells[4].accessDown = false
    coms.cells[5].accessRight = false
    coms.cells[6].accessRight = false
    coms.cells[8].accessDown = false
    coms.cells[9].accessDown = false
    coms.cells[9].accessRight = false

--     coms.cells[4].object1 = {
--         name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
--         offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
--     }
-- 
coms.cells[7].object1 = {
    name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
    offsetX = -100, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
    lootItems = { "ammo", "ammo", "meds", "material","power","wiring_straight", COMPONENT_UI.component_fuse }
}
coms.cells[2].object1 = {
    name = hash("power_node"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 201,
    offsetX = -90, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 64, requiredComponent = nil,
    powerLoaded = 0, powerRequired = 9
}

coms.cells[4].object2 = {
    name = hash("gun_turret"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 902,
    offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
}

coms.cells[5].object1 = {
    name = hash("wiregap"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 501,
    offsetX = 80, offsetY = -5, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = "/sparks_small_fx_factory#sparks_small_fx_factory", hitW = 32, hitH = 32, requiredComponent = COMPONENT_UI.component_wiring_straight
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
    canteen.cells[i].lightValue = 2
    canteen.cells[i].moveValue = 1
    canteen.cells[i].coverValue = 1
end
canteen.cells[3].moveValue = 3
canteen.cells[6].moveValue = 3

canteen.cells[1].accessDown = false
--canteen.cells[1].accessRight = false
--canteen.cells[2].accessRight = false
--canteen.cells[3].accessRight = false
canteen.cells[3].accessDown = false
--canteen.cells[4].accessDown = false
canteen.cells[4].accessRight = false
--canteen.cells[4].accessDown = false
canteen.cells[5].accessRight = false
canteen.cells[5].accessDown = false
canteen.cells[6].accessRight = false
canteen.cells[6].accessDown = false
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
    offsetX = 110, offsetY = 5, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
}
canteen.cells[4].object1 = {
    name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
    offsetX = -100, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
    lootItems = { "ammo", "ammo", "meds", "material","power","wiring_straight", COMPONENT_UI.component_fuse }
}
canteen.cells[2].object1 = {
    name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 551,
    offsetX = -90, offsetY = -30, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
    stackCount = 1, obstacleCount = 1
}
canteen.cells[2].object2 = {
    name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 552,
    offsetX = 0, offsetY = -30, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
    stackCount = 2, obstacleCount = 2
}
canteen.cells[2].object3 = {
    name = hash("obstacle"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 553,
    offsetX = 32, offsetY = -30, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 36, hitH = 36, requiredComponent = nil,
    stackCount = 1, obstacleCount = 1
}
canteen.cells[1].object1 = {
    name = hash("power_node"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 101,
    offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 64, requiredComponent = nil,
    powerLoaded = 0, powerRequired = 9
}
canteen.cells[8].object1 = {
    name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 201,
    offsetX = 110, offsetY = 5, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
}

canteen.cells[9].object1 = {
    name = hash("wiregap"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 901,
    offsetX = 85, offsetY = -15, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = "/sparks_small_fx_factory#sparks_small_fx_factory", hitW = 32, hitH = 32, requiredComponent = COMPONENT_UI.component_wiring_straight
}

-- canteen.cells[4].object1 = {
--     name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
--     offsetX = -50, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
-- }

canteen.cells[9].object2 = {
    name = hash("supply_loader"), isFixed = true, hasFood = true, contributesToExitObjective = false,
    isWelded = false, isOpen = false, dependsOn = 901, isDependentOn = {}, objectId = 902,
    offsetX = 70, offsetY = 3, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 56, hitH = 56, requiredComponent = COMPONENT_UI.component_food_supplies
}
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
    exit.cells[2].accessDown = false
    exit.cells[3].accessDown = false
    exit.cells[3].accessRight = false
    exit.cells[4].accessDown = false
    exit.cells[6].accessDown = false
    exit.cells[6].accessRight = false
    exit.cells[7].accessRight = false
    exit.cells[8].accessRight = false
    exit.cells[9].accessRight = false
    exit.cells[9].accessDown = false
    
    exit.cells[3].object1 = {
        name = hash("escape_pod_power_socket"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 2301,
        offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 64, hitH = 64, requiredComponent = nil,
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
        offsetX = -52, offsetY = 14, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 56, hitH = 56, requiredComponent = COMPONENT_UI.component_nav_data
    }
    exit.cells[8].object2 = {
        name = hash("supply_loader"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 2802,
        offsetX = 56, offsetY = -6, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 64, hitH = 56, requiredComponent = COMPONENT_UI.component_food_supplies
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
        lootItems = { "ammo", "ammo", "meds", "material","power","plate", COMPONENT_UI.component_fuse }
    }
    -- armoury.cells[2].object1 = {
    --     name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 201,
    --     offsetX = -100, offsetY = 35, hitW = 32, hitH = 32, requiredComponent = nil
    -- }
    armoury.cells[2].object2 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 202,
        offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
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
        lootItems = { "ammo", "ammo", "meds", "material","plate" ,COMPONENT_UI.component_fuse }
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
        offsetX = 98, offsetY = 5, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
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
        offsetX = 110, offsetY = 5, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    armoury.cells[9].object2 = {
        name = hash("gun_turret"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 902,
        offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    armoury.cells[9].object3 = {
        name = hash("blip_spawn"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 903,
        offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 16, hitH = 16, requiredComponent = nil
    }
    assign_random_loot_cell(armoury)
    library["armoury"] = armoury

-- =====================================================================
-- MEDBAY
-- =====================================================================
     local medbay = create_tile_prototype("medbay")
     medbay.visualTile = "medbay_off"
     medbay.powerLightOffAnim = "tile_medbay_off"
     medbay.powerLightOnAnim = "tile_medbay_on"
    
     for i = 1, 9 do
         medbay.cells[i].lightValue = 4
         medbay.cells[i].moveValue = 1
         medbay.cells[i].coverValue = 2
     end
    
     -- Example access pattern edits:
    medbay.cells[2].accessDown = false
    medbay.cells[3].accessDown = false
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
        offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    medbay.cells[4].object1 = {
        name = hash("loot_crate"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
        offsetX = 0, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil,
        lootItems = { "ammo", "ammo", "material", "plate" ,"meds", "material", COMPONENT_UI.component_fuse, COMPONENT_UI.component_wiring_straight}
    }
     medbay.cells[5].object1 = {
         name = hash("power_node"), isFixed = true, dependsOn = 0, isDependentOn = {}, objectId = 501,
         offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil
    }
    medbay.cells[5].object2 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 502,
        offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }
    medbay.cells[5].object3 = {
        name = hash("wiregap"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 503,
        offsetX = -10, offsetY = 50, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = "/sparks_small_fx_factory#sparks_small_fx_factory", hitW = 32, hitH = 32, requiredComponent = COMPONENT_UI.component_wiring_straight
    }
    medbay.cells[6].object1 = {
        name = hash("vent"), isFixed = true, isWelded = false, dependsOn = 0, isDependentOn = {}, objectId = 601,
        offsetX = -100, offsetY = -35, hitW = 32, hitH = 32, requiredComponent = nil
    }
    medbay.cells[6].object1 = {
        name = hash("door"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 503, isDependentOn = {}, objectId = 601,
        offsetX = 115, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 42, hitH = 72, requiredComponent = COMPONENT_UI.component_plate
    }

    medbay.cells[9].object1 = {
        name = hash("med_vending_machine"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 503, isDependentOn = {}, objectId = 901,
        offsetX = 80, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 64, hitH = 124, requiredComponent = COMPONENT_UI.component_fuse
    }
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
-- PASSAGE 1 (vertical on right hand side)
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

    passage1.cells[4].lightValue = 1
    passage1.cells[4].moveValue = 1
    passage1.cells[3].moveValue = 3
    passage1.cells[6].moveValue = 3
    passage1.cells[9].moveValue = 3

    -- Internal connectivity:
    -- - Vertical shaft only on right column: 3 <-> 6 <-> 9
    -- - Single isolated accessible cell: 4
    -- - Cell 4 remains enterable from left neighbor tile via edge rules.
    passage1.cells[2].accessRight = false   -- blocks 2 <-> 3
    passage1.cells[3].accessRight = false   -- blocks right boundary from 3
    passage1.cells[4].accessRight = false   -- blocks 4 <-> 5
    passage1.cells[4].accessDown = false    -- blocks 4 <-> 1
    passage1.cells[5].accessRight = false   -- blocks 5 <-> 6
    passage1.cells[6].accessRight = false   -- blocks right boundary from 6
    passage1.cells[6].accessDown = true     -- allows 6 <-> 3
    passage1.cells[7].accessRight = false   -- blocks 7 <-> 8
    passage1.cells[7].accessDown = false    -- blocks 7 <-> 4
    passage1.cells[8].accessRight = false   -- blocks 8 <-> 9
    passage1.cells[9].accessRight = false   -- blocks right boundary from 9
    passage1.cells[9].accessDown = true     -- allows 9 <-> 6


passage1.cells[6].object1 = {
    name = hash("power_node"), isFixed = true, dependsOn = 0, isDependentOn = {}, objectId = 601,
    offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil
}

    library["passage1"] = passage1

-- =====================================================================
-- FACTORY
-- =====================================================================
    local factory = create_tile_prototype("factory")
    factory.visualTile = "factory_off"
    factory.powerLightOffAnim = "tile_factory_off"
    factory.powerLightOnAnim = "tile_factory_on"

    for i = 1, 9 do
        factory.cells[i].lightValue = 2
        factory.cells[i].moveValue = 1
        factory.cells[i].coverValue = 1
        factory.cells[i].accessRight = false
        factory.cells[i].accessDown = false
    end

    -- Requested internal connectivity:
    -- 2: right, 4: right, 5: right, 6: right + down
    factory.cells[2].accessRight = true
    factory.cells[4].accessRight = true
    factory.cells[5].accessRight = true
    factory.cells[6].accessRight = true
    factory.cells[6].accessDown = true

    -- Power node lane (cell 4)
    factory.cells[4].object1 = {
        name = hash("power_node"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 401,
        offsetX = -90, offsetY = 10, fxOffsetX = 0, fxOffsetY = 0, fxRotation = -90, hitW = 64, hitH = 124, requiredComponent = nil,
        powerLoaded = 0, powerRequired = 9
    }

    -- Wiring dependency lane (cell 6)
    factory.cells[6].object1 = {
        name = hash("wiregap"), isFixed = false, isWelded = false, isOpen = false, dependsOn = 0, isDependentOn = {}, objectId = 601,
        offsetX = 78, offsetY = -8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, fxFactory = "/sparks_small_fx_factory#sparks_small_fx_factory", hitW = 32, hitH = 32, requiredComponent = COMPONENT_UI.component_wiring_straight
    }

    -- Factory machinery anchors (cells 5 and 8). These are fixed but only functional
    -- when their dependency chain is satisfied.
    factory.cells[5].object1 = {
        name = hash("factory_machine"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 601, isDependentOn = {}, objectId = 501,
        offsetX = 0, offsetY = 0, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 84, hitH = 84, requiredComponent = nil
    }
    factory.cells[8].object1 = {
        name = hash("factory_machine"), isFixed = true, isWelded = false, isOpen = false, dependsOn = 601, isDependentOn = {}, objectId = 801,
        offsetX = 0, offsetY = 8, fxOffsetX = 0, fxOffsetY = 0, fxRotation = 0, hitW = 84, hitH = 84, requiredComponent = nil
    }

    library["factory"] = factory

    
    return library
end

return M
