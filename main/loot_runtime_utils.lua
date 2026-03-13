local M = {}

function M.create(ctx)
    local runtime = {}
    local function is_any_vending_machine_name(name_hash)
        return name_hash == hash("machine")
            or name_hash == hash("ammo_vending_machine")
            or name_hash == hash("med_vending_machine")
    end
    local function is_turret_name(name_hash)
        return name_hash == hash("gun_turret")
    end
    local function is_loot_crate_name(name_hash)
        return name_hash == hash("loot_crate")
    end
    local function is_blip_spawn_name(name_hash)
        return name_hash == hash("blip_spawn") or name_hash == hash("blip")
    end

    runtime.get_backpack_item_color = function(item_type)
        if item_type == "ammo" then
            return ctx.LOOT_UI.ammo_color
        elseif item_type == "meds" then
            return ctx.LOOT_UI.meds_color
        elseif item_type == "power" then
            return ctx.LOOT_UI.power_color
        elseif item_type == "material" then
            return ctx.LOOT_UI.material_color
        elseif item_type == "corpse" then
            return vmath.vector4(0.75, 0.12, 0.12, 1)
        elseif item_type == "turret_packed" then
            return vmath.vector4(0.55, 0.75, 0.95, 1)
        elseif item_type == "obstacle" then
            return vmath.vector4(0.7, 0.65, 0.55, 1)
        elseif item_type == ctx.COMPONENT_UI.item_type_blue
            or item_type == ctx.COMPONENT_UI.component_wiring_straight
            or item_type == ctx.COMPONENT_UI.component_wiring_corner
            or item_type == ctx.COMPONENT_UI.component_plate
            or item_type == ctx.COMPONENT_UI.component_fuse
            or item_type == ctx.COMPONENT_UI.component_sensor
            or item_type == ctx.COMPONENT_UI.component_nav_data
            or item_type == ctx.COMPONENT_UI.component_food_supplies
        then
            return ctx.COMPONENT_UI.component_color
        end
        return ctx.UI_COLOR_SLOT
    end

    runtime.get_item_visual_animation = function(item_type)
        if item_type == "material" then
            return hash("material_unit")
        elseif item_type == "meds" then
            return hash("med_unit")
        elseif item_type == "ammo" then
            return hash("ammo_unit")
        elseif item_type == "power" then
            return hash("power_unit")
        elseif item_type == ctx.COMPONENT_UI.component_wiring_straight then
            return hash("wiregap_straight_on")
        elseif item_type == ctx.COMPONENT_UI.component_wiring_corner then
            return hash("wiregap_corner_on")
        elseif item_type == ctx.COMPONENT_UI.component_fuse then
            return hash("fuse")
        elseif item_type == ctx.COMPONENT_UI.component_plate then
            return hash("plate")
        elseif item_type == ctx.COMPONENT_UI.component_sensor then
            return hash("sensor")
        elseif item_type == ctx.COMPONENT_UI.component_nav_data then
            return hash("nav_data")
        elseif item_type == ctx.COMPONENT_UI.component_food_supplies then
            return hash("food_supplies")
        elseif item_type == "turret_packed" then
            return hash("gun_turret_icon")
        elseif item_type == "obstacle" then
            return hash("obstacle_icon")
        end
        return nil
    end

    runtime.get_backpack_slot_screen_pos = function(slot_index)
        local col = (slot_index - 1) % ctx.UI_BACKPACK_COLS
        local row = math.floor((slot_index - 1) / ctx.UI_BACKPACK_COLS)
        local slot_x = ctx.UI_BACKPACK_START_X + col * (ctx.UI_BACKPACK_SLOT_SIZE + ctx.UI_BACKPACK_SLOT_GAP)
        local slot_y = ctx.UI_BACKPACK_START_Y - row * (ctx.UI_BACKPACK_SLOT_SIZE + ctx.UI_BACKPACK_SLOT_GAP)
        return slot_x, slot_y
    end

    runtime.get_command_pip_screen_pos = function(pip_index)
        local col = (pip_index - 1) % ctx.COMMAND_UI.cols
        local row = math.floor((pip_index - 1) / ctx.COMMAND_UI.cols)
        local x = ctx.COMMAND_UI.start_x + col * (ctx.COMMAND_UI.pip_size + ctx.COMMAND_UI.pip_gap)
        local y = ctx.COMMAND_UI.start_y - row * (ctx.COMMAND_UI.pip_size + ctx.COMMAND_UI.pip_gap)
        return x, y
    end

    runtime.is_point_in_loot_button = function(screen_x, screen_y)
        local half = ctx.LOOT_UI.button_size * 0.5
        return screen_x >= (ctx.LOOT_UI.button_x - half)
            and screen_x <= (ctx.LOOT_UI.button_x + half)
            and screen_y >= (ctx.LOOT_UI.button_y - half)
            and screen_y <= (ctx.LOOT_UI.button_y + half)
    end

    runtime.is_point_in_component_button = function(screen_x, screen_y)
        local half = ctx.COMPONENT_UI.button_size * 0.5
        return screen_x >= (ctx.COMPONENT_UI.button_x - half)
            and screen_x <= (ctx.COMPONENT_UI.button_x + half)
            and screen_y >= (ctx.COMPONENT_UI.button_y - half)
            and screen_y <= (ctx.COMPONENT_UI.button_y + half)
    end

    runtime.is_point_in_fix_button = function(screen_x, screen_y)
        local half = ctx.COMPONENT_UI.fix_button_size * 0.5
        return screen_x >= (ctx.COMPONENT_UI.fix_button_x - half)
            and screen_x <= (ctx.COMPONENT_UI.fix_button_x + half)
            and screen_y >= (ctx.COMPONENT_UI.fix_button_y - half)
            and screen_y <= (ctx.COMPONENT_UI.fix_button_y + half)
    end

    runtime.is_point_in_retrieve_button = function(screen_x, screen_y)
        local half = ctx.LOOT_UI.retrieve_button_size * 0.5
        return screen_x >= (ctx.LOOT_UI.retrieve_button_x - half)
            and screen_x <= (ctx.LOOT_UI.retrieve_button_x + half)
            and screen_y >= (ctx.LOOT_UI.retrieve_button_y - half)
            and screen_y <= (ctx.LOOT_UI.retrieve_button_y + half)
    end

    runtime.cell_has_component_machine = function(cell)
        if not cell then
            return false
        end
        return (cell.object1 and cell.object1.name == hash("machine"))
            or (cell.object2 and cell.object2.name == hash("machine"))
            or (cell.object3 and cell.object3.name == hash("machine"))
    end

    runtime.get_vending_machine_on_cell = function(cell)
        if not cell then
            return nil
        end
        local slots = { cell.object1, cell.object2, cell.object3 }
        for _, obj in ipairs(slots) do
            if obj and obj.name and is_any_vending_machine_name(obj.name) then
                return obj
            end
        end
        return nil
    end

    runtime.cell_has_any_vending_machine = function(cell)
        return runtime.get_vending_machine_on_cell(cell) ~= nil
    end

    runtime.get_fixable_objects_in_cell = function(cell)
        local out = {}
        if not cell then
            return out
        end
        local slots = { cell.object1, cell.object2, cell.object3 }
        for _, obj in ipairs(slots) do
            if obj and obj.name and obj.name ~= hash("empty") and (not is_any_vending_machine_name(obj.name)) and (not is_turret_name(obj.name)) and (not is_loot_crate_name(obj.name)) and (not is_blip_spawn_name(obj.name)) and obj.name ~= hash("power_node") then
                table.insert(out, obj)
            end
        end
        return out
    end

    runtime.get_loot_crate_object = function(cell)
        if not cell then
            return nil
        end
        local slots = { cell.object1, cell.object2, cell.object3 }
        for _, obj in ipairs(slots) do
            if obj and obj.name and is_loot_crate_name(obj.name) then
                return obj
            end
        end
        return nil
    end

    runtime.cell_has_loot_available = function(cell)
        if not cell then
            return false
        end
        -- Loot is now fully authored via tile object defs.
        return runtime.get_loot_crate_object(cell) ~= nil
    end

    runtime.cell_has_fixable_object = function(cell)
        local objects = runtime.get_fixable_objects_in_cell(cell)
        for _, obj in ipairs(objects) do
            if obj.isFixed ~= true then
                return true
            end
        end
        return false
    end

    runtime.find_best_fixable_object = function(cell, required_component)
        local objects = runtime.get_fixable_objects_in_cell(cell)
        local best = nil
        for _, obj in ipairs(objects) do
            local requires = runtime.get_required_component_for_object(obj)
            if obj.isFixed ~= true and (not required_component or required_component == requires) then
                if (obj.dependsOn or 0) == 0 then
                    return obj
                end
                if not best then
                    best = obj
                end
            end
        end
        return best
    end

    runtime.get_required_component_for_object = function(obj)
        if not obj then
            return ctx.COMPONENT_UI.item_type_blue
        end
        return obj.requiredComponent or ctx.COMPONENT_UI.item_type_blue
    end

    runtime.find_object_by_id = function(world_grid, object_id)
        if not world_grid or not object_id or object_id <= 0 then
            return nil
        end
        for _, cell in ipairs(world_grid) do
            local objects = { cell.object1, cell.object2, cell.object3 }
            for _, obj in ipairs(objects) do
                if obj and obj.objectId == object_id then
                    return obj
                end
            end
        end
        return nil
    end

    runtime.is_object_dependency_met = function(world_grid, obj)
        if not obj then
            return false
        end
        local dependency_id = obj.dependsOn or 0
        if dependency_id <= 0 then
            return true
        end
        local dependency_obj = runtime.find_object_by_id(world_grid, dependency_id)
        return dependency_obj ~= nil and dependency_obj.isFixed == true
    end

    runtime.get_power_node_object = function(cell)
        if not cell then
            return nil
        end
        if cell.object1 and cell.object1.name == hash("power_node") then
            return cell.object1
        end
        if cell.object2 and cell.object2.name == hash("power_node") then
            return cell.object2
        end
        if cell.object3 and cell.object3.name == hash("power_node") then
            return cell.object3
        end
        return nil
    end

    runtime.cell_has_power_node = function(cell)
        return runtime.get_power_node_object(cell) ~= nil
    end

    runtime.get_vent_object = function(cell)
        if not cell then
            return nil
        end
        if cell.object1 and cell.object1.name == hash("vent") then
            return cell.object1
        end
        if cell.object2 and cell.object2.name == hash("vent") then
            return cell.object2
        end
        if cell.object3 and cell.object3.name == hash("vent") then
            return cell.object3
        end
        return nil
    end

    runtime.get_escape_pod_seat_object = function(cell)
        if not cell then
            return nil
        end
        local slots = { cell.object1, cell.object2, cell.object3 }
        for _, obj in ipairs(slots) do
            if obj and obj.name == hash("escape_pod_seatbay") then
                return obj
            end
        end
        return nil
    end

    runtime.get_escape_pod_power_socket_object = function(cell)
        if not cell then
            return nil
        end
        local slots = { cell.object1, cell.object2, cell.object3 }
        for _, obj in ipairs(slots) do
            if obj and obj.name == hash("escape_pod_power_socket") then
                return obj
            end
        end
        return nil
    end

    runtime.get_nav_computer_object = function(cell)
        if not cell then
            return nil
        end
        local slots = { cell.object1, cell.object2, cell.object3 }
        for _, obj in ipairs(slots) do
            if obj and obj.name == hash("nav_computer") then
                return obj
            end
        end
        return nil
    end

    runtime.get_supply_loader_object = function(cell)
        if not cell then
            return nil
        end
        local slots = { cell.object1, cell.object2, cell.object3 }
        for _, obj in ipairs(slots) do
            if obj and obj.name == hash("supply_loader") then
                return obj
            end
        end
        return nil
    end

    runtime.get_backpack_slot_index_at = function(screen_x, screen_y)
        local half = ctx.UI_BACKPACK_SLOT_SIZE * 0.5
        local total_slots = ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS
        for i = 1, total_slots do
            local slot_x, slot_y = runtime.get_backpack_slot_screen_pos(i)
            if screen_x >= (slot_x - half)
                and screen_x <= (slot_x + half)
                and screen_y >= (slot_y - half)
                and screen_y <= (slot_y + half) then
                return i
            end
        end
        return nil
    end

    runtime.get_command_pip_index_at = function(unit, screen_x, screen_y)
        if not unit or unit.class_id ~= ctx.UNIT_CLASS_SARGE then
            return nil
        end
        local command_count = math.min(unit.command_points or 0, ctx.COMMAND_UI.max_pips)
        if command_count <= 0 then
            return nil
        end

        local half = ctx.COMMAND_UI.pip_size * 0.5
        for i = 1, command_count do
            local cx, cy = runtime.get_command_pip_screen_pos(i)
            if screen_x >= (cx - half)
                and screen_x <= (cx + half)
                and screen_y >= (cy - half)
                and screen_y <= (cy + half) then
                return i
            end
        end
        return nil
    end

    runtime.get_bar_drop_target = function(screen_x, screen_y)
        local min_y = ctx.UI_BAR_START_Y - ((ctx.UI_MAX_PIPS - 1) * (ctx.UI_BAR_PIP_SIZE + ctx.UI_BAR_PIP_GAP)) - ctx.LOOT_UI.bar_hit_padding
        local max_y = ctx.UI_BAR_START_Y + ctx.LOOT_UI.bar_hit_padding
        if screen_y < min_y or screen_y > max_y then
            return nil
        end

        local half_w = (ctx.UI_BAR_PIP_SIZE * 0.5) + ctx.LOOT_UI.bar_hit_padding
        if math.abs(screen_x - ctx.UI_BAR_AMMO_X) <= half_w then
            return "ammo"
        end
        if math.abs(screen_x - ctx.UI_BAR_HP_X) <= half_w then
            return "meds"
        end
        return nil
    end

    runtime.can_transfer_between_units = function(self, source_unit, target_unit)
        if not source_unit or not target_unit or not source_unit.cell_id or not target_unit.cell_id then
            return false
        end
        local sx, sy = ctx.id_to_coords(source_unit.cell_id)
        local tx, ty = ctx.id_to_coords(target_unit.cell_id)
        local manhattan = math.abs(sx - tx) + math.abs(sy - ty)
        if manhattan == 0 then
            return true
        end
        if manhattan > 1 then
            return false
        end
        if not self or not self.world_grid then
            return false
        end
        if ctx.can_human_cross_between_cells then
            return ctx.can_human_cross_between_cells(self.world_grid, source_unit.cell_id, target_unit.cell_id)
        end
        return true
    end

    return runtime
end

return M
