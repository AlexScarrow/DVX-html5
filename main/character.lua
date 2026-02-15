--[[
    CHARACTER MODULE
    Manages derple and alien characters with movement, stats, and actions
]]

local M = {}

-- =============================================================================
-- CHARACTER TYPES
-- =============================================================================

M.DERPLE_TYPES = {
    SARGE = "sarge",
    MEDIC = "medic",
    GUNNER = "gunner",
    TECHIE = "techie"
}

M.ALIEN_TYPES = {
    DRONE = "drone",
    WARRIOR = "warrior",
    SPITTER = "spitter"
}

-- =============================================================================
-- CHARACTER CREATION
-- =============================================================================

function M.create_derple(character_type, cell_id)
    local stats = {
        sarge = { hp = 10, max_hp = 10, action_points = 5, damage = 2, range = 3 },
        medic = { hp = 8, max_hp = 8, action_points = 5, damage = 1, range = 2 },
        gunner = { hp = 9, max_hp = 9, action_points = 4, damage = 3, range = 5 },
        techie = { hp = 8, max_hp = 8, action_points = 6, damage = 1, range = 2 }
    }

    local char_stats = stats[character_type] or stats.sarge

    return {
        type = character_type,
        cell_id = cell_id,
        hp = char_stats.hp,
        max_hp = char_stats.max_hp,
        action_points = char_stats.action_points,
        max_action_points = char_stats.action_points,
        damage = char_stats.damage,
        range = char_stats.range,
        inventory = {
            ammo = 10,
            meds = 2,
            salvage = 0
        },
        is_alive = true,
        has_moved = false
    }
end

function M.create_alien(alien_type, cell_id)
    local stats = {
        drone = { hp = 5, action_points = 6, damage = 1, range = 1 },
        warrior = { hp = 8, action_points = 5, damage = 2, range = 1 },
        spitter = { hp = 4, action_points = 4, damage = 2, range = 4 }
    }

    local alien_stats = stats[alien_type] or stats.drone

    return {
        type = alien_type,
        cell_id = cell_id,
        hp = alien_stats.hp,
        max_hp = alien_stats.hp,
        action_points = alien_stats.action_points,
        max_action_points = alien_stats.action_points,
        damage = alien_stats.damage,
        range = alien_stats.range,
        is_alive = true,
        can_use_vents = true
    }
end

-- =============================================================================
-- CHARACTER ACTIONS
-- =============================================================================

-- Move character along a path
function M.move_character(character, path, world_grid)
    if #path < 2 then
        return false  -- No movement needed
    end

    local total_cost = 0
    for i = 2, #path do
        total_cost = total_cost + world_grid[path[i]].moveValue
    end

    if total_cost > character.action_points then
        return false  -- Not enough action points
    end

    -- Update character position
    local old_cell = character.cell_id
    local new_cell = path[#path]

    character.cell_id = new_cell
    character.action_points = character.action_points - total_cost
    character.has_moved = true

    -- Update world grid occupancy
    world_grid[old_cell].isOccupied = hash("empty")
    world_grid[new_cell].isOccupied = hash(character.type)

    print(string.format("%s moved from cell %d to %d (cost: %d AP, remaining: %d AP)",
        character.type, old_cell, new_cell, total_cost, character.action_points))

    return true
end

-- Attack another character
function M.attack(attacker, defender, world_grid)
    if attacker.action_points < 1 then
        return false, "Not enough action points"
    end

    -- Check range (simple distance check)
    local attacker_cell = world_grid[attacker.cell_id]
    local defender_cell = world_grid[defender.cell_id]
    local dx = math.abs(attacker_cell.xCell - defender_cell.xCell)
    local dy = math.abs(attacker_cell.yCell - defender_cell.yCell)
    local distance = math.max(dx, dy)

    if distance > attacker.range then
        return false, "Target out of range"
    end

    -- Apply damage (defender's cover reduces damage)
    local damage = attacker.damage
    local cover_reduction = math.floor(defender_cell.coverValue / 2)
    damage = math.max(1, damage - cover_reduction)

    defender.hp = defender.hp - damage
    attacker.action_points = attacker.action_points - 1

    print(string.format("%s attacks %s for %d damage (cover: %d)",
        attacker.type, defender.type, damage, cover_reduction))

    if defender.hp <= 0 then
        defender.is_alive = false
        world_grid[defender.cell_id].isOccupied = hash("empty")
        print(defender.type .. " has been eliminated!")
    end

    return true, damage
end

-- Use medkit
function M.use_medkit(character)
    if character.inventory.meds <= 0 then
        return false, "No medkits available"
    end

    if character.hp >= character.max_hp then
        return false, "Already at full health"
    end

    local heal_amount = math.min(5, character.max_hp - character.hp)
    character.hp = character.hp + heal_amount
    character.inventory.meds = character.inventory.meds - 1
    character.action_points = math.max(0, character.action_points - 1)

    print(string.format("%s used medkit, healed %d HP (now %d/%d)",
        character.type, heal_amount, character.hp, character.max_hp))

    return true, heal_amount
end

-- Reset character for new turn
function M.reset_turn(character)
    character.action_points = character.max_action_points
    character.has_moved = false
    print(character.type .. " ready for new turn (" .. character.action_points .. " AP)")
end

-- =============================================================================
-- CHARACTER QUERIES
-- =============================================================================

function M.can_act(character)
    return character.is_alive and character.action_points > 0
end

function M.get_characters_in_range(character, all_characters, world_grid)
    local targets = {}
    local char_cell = world_grid[character.cell_id]

    for _, other in ipairs(all_characters) do
        if other ~= character and other.is_alive then
            local other_cell = world_grid[other.cell_id]
            local dx = math.abs(char_cell.xCell - other_cell.xCell)
            local dy = math.abs(char_cell.yCell - other_cell.yCell)
            local distance = math.max(dx, dy)

            if distance <= character.range then
                table.insert(targets, {
                    character = other,
                    distance = distance
                })
            end
        end
    end

    return targets
end

return M
