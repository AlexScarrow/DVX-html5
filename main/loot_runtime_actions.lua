local M = {}

function M.extend(runtime, ctx)
    local WORLD_ITEM_FLOOR_OFFSET_FROM_CELL_BOTTOM = 34
    local TURRET_PACKED_ITEM = "turret_packed"
    local OBSTACLE_ITEM = "obstacle"
    local OBSTACLE_STACK_CAP = 4
    local OBSTACLE_DROP_FLOOR_Y_OFFSET = -30
    local OBSTACLE_SLOT_X_BY_INDEX = { -70, 0, 70 }
    local TURRET_ARMING_TURNS_ON_DEPLOY = 2
    local WELD_SPARKS_Z = 0.62
    local RECEIVE_PULSE_DURATION = 0.24
    local SHUTTLE_HIDE_POS = vmath.vector3(-9999, -9999, 0.5)
    local FACTORY_TILE_ID = hash("factory")
    local FACTORY_MACHINE_NAME = hash("factory_machine")
    local FACTORY_MAX_STOCK = 9
    local FACTORY_UNDERLAY_Z = 0.018
    local FACTORY_CONVEYOR_TOKEN_Z = 0.56
    local FACTORY_BELT_PAN_RATE = 0.3375
    local FACTORY_STEAM_FX_Z = 0.57
    local FACTORY_STEAM_OFFSET_X = -100
    local FACTORY_STEAM_OFFSET_Y = 20
    local FACTORY_STEAM_ROTATION_DEG = -115
    local FACTORY_STEAM_LIFETIME_SECONDS = 1.2
    local FACTORY_STACK_SLOT_OFFSETS = {
        vmath.vector3(-94, -35, 0), vmath.vector3(-94, -1, 0), vmath.vector3(-94, 33, 0),
        vmath.vector3(-46, -35, 0), vmath.vector3(-46, -1, 0), vmath.vector3(-46, 33, 0),
        vmath.vector3(2, -35, 0),   vmath.vector3(2, -1, 0),   vmath.vector3(2, 33, 0)
    }
    local WORKSHOP_TILE_ID = hash("workshop")
    local WORKSHOP_MACHINE_NAME = hash("workshop_machine")
    local WORKSHOP_MENU_NAME = hash("workshop_menu")
    local WORKSHOP_OUTPUT_MAX_STOCK = 9
    local WORKSHOP_PRODUCTION_DURATION = 10.0
    local WORKSHOP_CONVEYOR_TOKEN_Z = 0.56
    local WORKSHOP_CONVEYOR_TRAVEL_SECONDS = 2.67
    local WORKSHOP_PRINTER_Z = 0.74
    local WORKSHOP_EMITTER_Z = 0.69
    local WORKSHOP_SLOT_GRID_W = 3
    local WORKSHOP_SLOT_GRID_H = 3
    local WORKSHOP_MENU_HALF_W = 85
    local WORKSHOP_MENU_HALF_H = 59
    local WORKSHOP_MENU_SLOT_W = (WORKSHOP_MENU_HALF_W * 2) / WORKSHOP_SLOT_GRID_W
    local WORKSHOP_MENU_SLOT_H = (WORKSHOP_MENU_HALF_H * 2) / WORKSHOP_SLOT_GRID_H
    local WORKSHOP_PAY_HOTSPOT_OFFSET_X = -6
    local WORKSHOP_PAY_HOTSPOT_OFFSET_Y = -22
    local WORKSHOP_PAY_HOTSPOT_HALF_SIZE = 17
    local WORKSHOP_PRODUCT_BY_SLOT = {
        [1] = { item_type = ctx.COMPONENT_UI.component_wiring_straight, price = 1, label = "wiring" },
        [2] = { item_type = ctx.COMPONENT_UI.component_fuse, price = 1, label = "fuse" },
        [3] = { item_type = "obstacle1", price = 2, label = "obstacle1" },
        [4] = { item_type = "obstacle2", price = 2, label = "obstacle2" },
        [5] = { item_type = "obstacle3", price = 2, label = "obstacle3" },
        [6] = { item_type = "obstacle4", price = 2, label = "obstacle4" },
        [7] = { item_type = "obstacle5", price = 2, label = "obstacle5" },
        [8] = { item_type = "power", price = 5, label = "power" }
    }
    local DERPLE_FEEDBACK_EVENT_DEFS = {
        RECEIVE_ITEM = { anim = hash("derples_comms_itemRecieved"), duration = 0.95, cooldown = 0.55, scale = 0.54, x_offset = 50, y_offset = 74 },
        LOW_HP = { anim = hash("derples_comms_lowHealth"), duration = 1.15, cooldown = 3.0, scale = 0.54, x_offset = 50, y_offset = 74 },
        SPOT_ALIEN = { anim = hash("derples_comms_alienSpotted"), duration = 1.05, cooldown = 1.9, scale = 0.54, x_offset = 50, y_offset = 74 },
        NOT_ENOUGH_AP = { anim = hash("derples_comms_notEnough_AP"), duration = 1.05, cooldown = 0.4, scale = 0.54, x_offset = 50, y_offset = 74 },
        TURRET_BACKPACK_NOT_EMPTY = { anim = hash("derples_comms_turret_fullPack"), duration = 1.05, cooldown = 0.5, scale = 0.54, x_offset = 50, y_offset = 74 }
    }

    local function get_drag_ap_cost()
        return (ctx.LOOT_UI and ctx.LOOT_UI.drag_ap_cost) or 1
    end

    local function flash_invalid_drag_units(source_unit, target_unit)
        if source_unit then
            source_unit.hit_flash_timer = math.max(source_unit.hit_flash_timer or 0, 0.25)
        end
        if target_unit then
            target_unit.hit_flash_timer = math.max(target_unit.hit_flash_timer or 0, 0.25)
        end
    end

    local function trigger_receive_pulse(target_unit)
        if not target_unit then
            return
        end
        target_unit.receive_pulse_timer = RECEIVE_PULSE_DURATION
    end

    local function is_food_supplies_item(item_type)
        return item_type == ctx.COMPONENT_UI.component_food_supplies
    end

    local function is_nav_data_item(item_type)
        return item_type == ctx.COMPONENT_UI.component_nav_data
    end

    local function get_backpack_item_slot(unit, item_type)
        if not unit or not unit.backpack_items then
            return nil
        end
        for i, item in ipairs(unit.backpack_items) do
            if item == item_type then
                return i
            end
        end
        return nil
    end

    local function emit_receive_item_feedback(self, unit)
        if runtime.emit_derple_feedback and unit and unit.id then
            runtime.emit_derple_feedback(self, unit.id, "RECEIVE_ITEM")
        end
    end

    local function try_consume_drag_ap(source_unit, target_unit)
        if not source_unit then
            return false
        end
        local ap_cost = get_drag_ap_cost()
        if (source_unit.current_ap or 0) < ap_cost then
            print(string.format("Unable action: no AP (need %d).", ap_cost))
            flash_invalid_drag_units(source_unit, target_unit)
            return false
        end
        source_unit.current_ap = source_unit.current_ap - ap_cost
        return true
    end

    local function get_world_item_animation(item_type)
        if item_type == "material" then
            return hash("material_unit")
        elseif item_type == "meds" then
            return hash("med_unit")
        elseif item_type == "ammo" then
            return hash("ammo_unit")
        elseif item_type == "power" then
            return hash("power_unit")
        elseif item_type == TURRET_PACKED_ITEM then
            return hash("gun_turret")
        elseif item_type == OBSTACLE_ITEM then
            return hash("obstacle_icon")
        elseif item_type == "obstacle1" then
            return hash("obstacle1")
        elseif item_type == "obstacle2" then
            return hash("obstacle2")
        elseif item_type == "obstacle3" then
            return hash("obstacle3")
        elseif item_type == "obstacle4" then
            return hash("obstacle2")
        elseif item_type == "obstacle5" then
            return hash("obstacle3")
        elseif is_nav_data_item(item_type) then
            return hash("nav_data")
        elseif is_food_supplies_item(item_type) then
            return hash("food_supplies")
        end
        return nil
    end

    local function is_obstacle_backpack_item(item_type)
        return item_type == OBSTACLE_ITEM
            or item_type == "obstacle1"
            or item_type == "obstacle2"
            or item_type == "obstacle3"
            or item_type == "obstacle4"
            or item_type == "obstacle5"
    end

    local function get_turret_object_on_cell(cell)
        if not cell then
            return nil
        end
        local slots = { cell.object1, cell.object2, cell.object3 }
        for _, obj in ipairs(slots) do
            if obj and obj.name == hash("gun_turret") then
                return obj
            end
        end
        return nil
    end

    local function allocate_runtime_object_id(world_grid)
        local max_id = 0
        for _, cell in ipairs(world_grid or {}) do
            local objs = { cell.object1, cell.object2, cell.object3 }
            for _, obj in ipairs(objs) do
                local id = (obj and obj.objectId) or 0
                if id > max_id then
                    max_id = id
                end
            end
        end
        return max_id + 1
    end

    local function get_center_obstacle_slot(cell)
        if not cell then
            return nil
        end
        return cell.object2
    end

    local function get_cell_object_slot_index(cell, slot)
        if not cell or not slot then
            return nil
        end
        if slot == cell.object1 then
            return 1
        end
        if slot == cell.object2 then
            return 2
        end
        if slot == cell.object3 then
            return 3
        end
        return nil
    end

    local function get_obstacle_slot_anchor_offset(cell, slot)
        if not slot then
            return 0, 0
        end
        local slot_index = get_cell_object_slot_index(cell, slot) or 2
        local anchor_x = slot.obstacleAnchorX
        if anchor_x == nil then
            anchor_x = OBSTACLE_SLOT_X_BY_INDEX[slot_index] or 0
        end
        local anchor_y = slot.obstacleAnchorY
        if anchor_y == nil then
            anchor_y = 0
        end
        return anchor_x, anchor_y
    end

    local function get_barricade_anchor_offset(cell)
        if not cell then
            return 0, 0
        end
        if cell.barricade_anchor_x ~= nil or cell.barricade_anchor_y ~= nil then
            return cell.barricade_anchor_x or 0, cell.barricade_anchor_y or 0
        end
        local slot_index = cell.barricade_slot_index
        if slot_index == 1 then
            return OBSTACLE_SLOT_X_BY_INDEX[1], 0
        elseif slot_index == 2 then
            return OBSTACLE_SLOT_X_BY_INDEX[2], 0
        elseif slot_index == 3 then
            return OBSTACLE_SLOT_X_BY_INDEX[3], 0
        end
        return 0, 0
    end

    local function is_point_in_barricade_hitbox(cell, world_x, world_y)
        if not cell or cell.tileID == hash("empty") then
            return false
        end
        if (cell.has_barricade ~= true) or ((cell.barricade_hp or 0) <= 0) then
            return false
        end
        local bx, by = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
        local anchor_x, anchor_y = get_barricade_anchor_offset(cell)
        bx = bx + anchor_x
        by = by + anchor_y + 7
        local half_w = 62
        local half_h = 50
        return world_x >= (bx - half_w)
            and world_x <= (bx + half_w)
            and world_y >= (by - half_h)
            and world_y <= (by + half_h)
    end

    local function apply_obstacle_slot_floor_alignment(cell, slot, anchor_x, anchor_y)
        if not slot then
            return
        end
        local resolved_anchor_x = anchor_x
        local resolved_anchor_y = anchor_y
        if resolved_anchor_x == nil or resolved_anchor_y == nil then
            resolved_anchor_x, resolved_anchor_y = get_obstacle_slot_anchor_offset(cell, slot)
        end
        slot.obstacleAnchorX = resolved_anchor_x
        slot.obstacleAnchorY = resolved_anchor_y
        slot.offsetX = resolved_anchor_x
        slot.offsetY = resolved_anchor_y + OBSTACLE_DROP_FLOOR_Y_OFFSET
    end

    local function reset_object_slot_to_empty(slot)
        if not slot then
            return
        end
        slot.name = hash("empty")
        slot.isFixed = false
        slot.isWelded = false
        slot.isOpen = false
        slot.dependsOn = 0
        slot.isDependentOn = {}
        slot.objectId = 0
        slot.offsetX = 0
        slot.offsetY = 0
        slot.fxOffsetX = 0
        slot.fxOffsetY = 0
        slot.fxRotation = 0
        slot.fxFactory = nil
        slot.hitW = 32
        slot.hitH = 32
        slot.requiredComponent = nil
        slot.stackCount = nil
        slot.obstacleCount = nil
        slot.obstacleAnchorX = nil
        slot.obstacleAnchorY = nil
    end

    local function init_obstacle_slot(cell, slot, world_grid, anchor_x, anchor_y)
        if not slot then
            return
        end
        slot.name = hash("obstacle")
        slot.isFixed = true
        slot.isWelded = false
        slot.isOpen = false
        slot.dependsOn = 0
        slot.isDependentOn = {}
        slot.objectId = allocate_runtime_object_id(world_grid)
        apply_obstacle_slot_floor_alignment(cell, slot, anchor_x, anchor_y)
        slot.fxOffsetX = 0
        slot.fxOffsetY = 0
        slot.fxRotation = 0
        slot.fxFactory = nil
        slot.hitW = 24
        slot.hitH = 24
        slot.requiredComponent = nil
        slot.stackCount = 1
        slot.obstacleCount = 1
    end

    local function get_obstacle_count(slot)
        if not slot or slot.name ~= hash("obstacle") then
            return 0
        end
        local count = slot.stackCount or slot.obstacleCount or 1
        if count < 1 then
            count = 1
        end
        return count
    end

    local function set_obstacle_count(slot, count)
        if not slot then
            return
        end
        local clamped = math.max(0, math.min(OBSTACLE_STACK_CAP, count or 0))
        if clamped <= 0 then
            reset_object_slot_to_empty(slot)
            return
        end
        slot.name = hash("obstacle")
        slot.stackCount = clamped
        slot.obstacleCount = clamped
        slot.hitW = slot.hitW or 24
        slot.hitH = slot.hitH or 24
        slot.offsetX = slot.offsetX or 0
        slot.offsetY = slot.offsetY or 0
    end

    local function find_clicked_obstacle_slot(cell, world_x, world_y)
        if not cell then
            return nil
        end
        local slots = { cell.object1, cell.object2, cell.object3 }
        local best_slot = nil
        local best_dist = math.huge
        for _, slot in ipairs(slots) do
            if slot and slot.name == hash("obstacle") then
                local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local ox = slot.offsetX or 0
                local oy = slot.offsetY or 0
                local sx = cx + ox
                local sy = cy + oy
                local half_w = ((slot.hitW or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
                local half_h = ((slot.hitH or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
                local inside = world_x >= (sx - half_w)
                    and world_x <= (sx + half_w)
                    and world_y >= (sy - half_h)
                    and world_y <= (sy + half_h)
                if inside then
                    local dx = sx - world_x
                    local dy = sy - world_y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < best_dist then
                        best_slot = slot
                        best_dist = dist
                    end
                end
            end
        end
        return best_slot
    end

    local function find_any_obstacle_slot(cell)
        if not cell then
            return nil
        end
        local slots = { cell.object1, cell.object2, cell.object3 }
        local best_slot = nil
        local best_count = 0
        for _, slot in ipairs(slots) do
            if slot and slot.name == hash("obstacle") then
                local count = get_obstacle_count(slot)
                if count > best_count then
                    best_count = count
                    best_slot = slot
                end
            end
        end
        return best_slot
    end

    local function find_clicked_drop_slot(cell, world_x, world_y)
        if not cell then
            return nil
        end
        local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
        local slots = { cell.object1, cell.object2, cell.object3 }
        local best_slot = nil
        local best_dist = math.huge
        for _, slot in ipairs(slots) do
            if slot then
                local anchor_x, anchor_y = get_obstacle_slot_anchor_offset(cell, slot)
                local sx = cx + anchor_x
                local sy = cy + anchor_y + OBSTACLE_DROP_FLOOR_Y_OFFSET
                local dx = sx - world_x
                local dy = sy - world_y
                local dist = math.sqrt((dx * dx) + (dy * dy))
                if dist < best_dist then
                    best_dist = dist
                    best_slot = slot
                end
            end
        end
        return best_slot
    end

    local function get_empty_object_slot(cell)
        if not cell then
            return nil
        end
        if cell.object1 and cell.object1.name == hash("empty") then
            return cell.object1
        end
        if cell.object2 and cell.object2.name == hash("empty") then
            return cell.object2
        end
        if cell.object3 and cell.object3.name == hash("empty") then
            return cell.object3
        end
        -- Allow deploy to replace non-interactive spawn markers when no empty slot exists.
        if cell.object1 and (cell.object1.name == hash("blip_spawn") or cell.object1.name == hash("blip")) then
            return cell.object1
        end
        if cell.object2 and (cell.object2.name == hash("blip_spawn") or cell.object2.name == hash("blip")) then
            return cell.object2
        end
        if cell.object3 and (cell.object3.name == hash("blip_spawn") or cell.object3.name == hash("blip")) then
            return cell.object3
        end
        return nil
    end

    local function fill_backpack_with_packed_turret(unit, cap)
        unit.backpack_items = {}
        for _ = 1, cap do
            table.insert(unit.backpack_items, TURRET_PACKED_ITEM)
        end
        unit.backpack_used = #unit.backpack_items
    end

    local function clear_packed_turret_from_backpack(unit)
        if not unit or not unit.backpack_items then
            return
        end
        local keep = {}
        for _, item in ipairs(unit.backpack_items) do
            if item ~= TURRET_PACKED_ITEM then
                table.insert(keep, item)
            end
        end
        unit.backpack_items = keep
        unit.backpack_used = #unit.backpack_items
    end

    local function find_turret_pickup_target(self, world_x, world_y, required_cell_id)
        if not self.world_grid then
            return nil, nil
        end
        local best_cell = nil
        local best_obj = nil
        local best_dist = math.huge
        for _, cell in ipairs(self.world_grid) do
            if cell and cell.tileID ~= hash("empty") and (not required_cell_id or required_cell_id == cell.idNumber) then
                local turret = get_turret_object_on_cell(cell)
                if turret then
                    local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                    local tx = cx + (turret.offsetX or 0)
                    local ty = cy + (turret.offsetY or 0)
                    local hit_w = math.max(turret.hitW or 42, 84)
                    local hit_h = math.max(turret.hitH or 72, 84)
                    local half_w = hit_w * 0.5
                    local half_h = hit_h * 0.5
                    local inside = world_x >= (tx - half_w)
                        and world_x <= (tx + half_w)
                        and world_y >= (ty - half_h)
                        and world_y <= (ty + half_h)
                    if inside then
                        local dx = tx - world_x
                        local dy = ty - world_y
                        local dist = math.sqrt(dx * dx + dy * dy)
                        if dist < best_dist then
                            best_dist = dist
                            best_cell = cell
                            best_obj = turret
                        end
                    end
                end
            end
        end
        return best_cell, best_obj
    end

    runtime.ensure_item_runtime_state = function(self)
        self.world_item_instances = self.world_item_instances or {}
        self.world_item_visuals = self.world_item_visuals or {}
        self.world_item_shadow_visuals = self.world_item_shadow_visuals or {}
        self.next_world_item_id = self.next_world_item_id or 0
        self.factory_underlay_visuals = self.factory_underlay_visuals or {}
        self.factory_conveyor_tokens = self.factory_conveyor_tokens or {}
        self.factory_underlay_clock = self.factory_underlay_clock or 0
        self.factory_debug_cell_markers = self.factory_debug_cell_markers or {}
        self.workshop_underlay_visuals = self.workshop_underlay_visuals or {}
        self.workshop_conveyor_tokens = self.workshop_conveyor_tokens or {}
        self.workshop_states = self.workshop_states or {}
        self.derple_feedback_entries = self.derple_feedback_entries or {}
        self.derple_feedback_by_unit_id = self.derple_feedback_by_unit_id or {}
        self.derple_feedback_cooldowns = self.derple_feedback_cooldowns or {}
        self.derple_feedback_clock = self.derple_feedback_clock or 0
    end

    local function get_factory_instances(self)
        local instances = {}
        if not self or not self.world_grid then
            return instances
        end
        for _, cell in ipairs(self.world_grid) do
            local slots = cell and { cell.object1, cell.object2, cell.object3 } or nil
            local has_factory_machine = false
            if slots then
                for _, obj in ipairs(slots) do
                    if obj and obj.name == FACTORY_MACHINE_NAME then
                        has_factory_machine = true
                        break
                    end
                end
            end
            if cell and (cell.tileID == FACTORY_TILE_ID or has_factory_machine) then
                local tile_instance_id = cell.tileInstanceId or 0
                if tile_instance_id > 0 then
                    local instance = instances[tile_instance_id]
                    if not instance then
                        instance = {
                            tile_instance_id = tile_instance_id,
                            cells = {},
                            min_x = cell.xCell,
                            min_y = cell.yCell,
                            max_x = cell.xCell,
                            max_y = cell.yCell,
                            powered = false,
                            machine_objects = {}
                        }
                        instances[tile_instance_id] = instance
                    end
                    table.insert(instance.cells, cell)
                    if cell.xCell < instance.min_x then instance.min_x = cell.xCell end
                    if cell.xCell > instance.max_x then instance.max_x = cell.xCell end
                    if cell.yCell < instance.min_y then instance.min_y = cell.yCell end
                    if cell.yCell > instance.max_y then instance.max_y = cell.yCell end
                    if cell.isPowered == true then
                        instance.powered = true
                    end
                    for _, obj in ipairs(slots) do
                        if obj and obj.name == FACTORY_MACHINE_NAME then
                            table.insert(instance.machine_objects, obj)
                        end
                    end
                end
            end
        end
        for _, instance in pairs(instances) do
            instance.cell_by_local = {}
            for _, cell in ipairs(instance.cells) do
                local local_x = (cell.xCell - instance.min_x)
                local local_y = (cell.yCell - instance.min_y)
                local local_idx = (local_y * 3) + local_x + 1
                if local_idx >= 1 and local_idx <= 9 then
                    instance.cell_by_local[local_idx] = cell
                end
            end
            local deps_ok = (#instance.machine_objects > 0)
            if deps_ok then
                for _, machine in ipairs(instance.machine_objects) do
                    if machine.isFixed ~= true or not runtime.is_object_dependency_met(self.world_grid, machine) then
                        deps_ok = false
                        break
                    end
                end
            end
            instance.functional = (instance.powered == true) and deps_ok
        end
        return instances
    end

    local function get_workshop_instances(self)
        local instances = {}
        if not self or not self.world_grid then
            return instances
        end
        for _, cell in ipairs(self.world_grid) do
            if cell and cell.tileID == WORKSHOP_TILE_ID then
                local tile_instance_id = cell.tileInstanceId or 0
                if tile_instance_id > 0 then
                    local instance = instances[tile_instance_id]
                    if not instance then
                        instance = {
                            tile_instance_id = tile_instance_id,
                            cells = {},
                            min_x = cell.xCell,
                            min_y = cell.yCell,
                            max_x = cell.xCell,
                            max_y = cell.yCell,
                            powered = false,
                            machine_obj = nil,
                            menu_obj = nil
                        }
                        instances[tile_instance_id] = instance
                    end
                    table.insert(instance.cells, cell)
                    if cell.xCell < instance.min_x then instance.min_x = cell.xCell end
                    if cell.xCell > instance.max_x then instance.max_x = cell.xCell end
                    if cell.yCell < instance.min_y then instance.min_y = cell.yCell end
                    if cell.yCell > instance.max_y then instance.max_y = cell.yCell end
                    if cell.isPowered == true then
                        instance.powered = true
                    end
                end
            end
        end
        for _, instance in pairs(instances) do
            instance.cell_by_local = {}
            for _, cell in ipairs(instance.cells) do
                local local_x = (cell.xCell - instance.min_x)
                local local_y = (cell.yCell - instance.min_y)
                local local_idx = (local_y * 3) + local_x + 1
                if local_idx >= 1 and local_idx <= 9 then
                    instance.cell_by_local[local_idx] = cell
                end
                local slots = { cell.object1, cell.object2, cell.object3 }
                for _, obj in ipairs(slots) do
                    if obj and obj.name == WORKSHOP_MACHINE_NAME then
                        instance.machine_obj = obj
                    elseif obj and obj.name == WORKSHOP_MENU_NAME then
                        instance.menu_obj = obj
                    end
                end
            end
            local machine_ok = instance.machine_obj and instance.machine_obj.isFixed == true
            local deps_ok = machine_ok and runtime.is_object_dependency_met(self.world_grid, instance.machine_obj)
            instance.functional = (instance.powered == true) and deps_ok
        end
        return instances
    end

    local function get_workshop_state(self, tile_instance_id)
        runtime.ensure_item_runtime_state(self)
        self.workshop_states[tile_instance_id] = self.workshop_states[tile_instance_id] or {
            selected_slot = nil,
            paid_units = 0,
            payment_locked = false,
            production_time_left = 0
        }
        return self.workshop_states[tile_instance_id]
    end

    local function get_workshop_product_for_slot(slot_idx)
        if not slot_idx then
            return nil
        end
        return WORKSHOP_PRODUCT_BY_SLOT[slot_idx]
    end

    local function get_workshop_used_slots(self, tile_instance_id)
        local used = {}
        for _, item in ipairs(self.world_item_instances or {}) do
            local meta = item and item.meta or nil
            if item
                and meta
                and meta.workshop_stock == true
                and meta.workshop_tile_instance_id == tile_instance_id
            then
                local slot_order = tonumber(meta.workshop_slot_order or 0) or 0
                if slot_order >= 1 and slot_order <= WORKSHOP_OUTPUT_MAX_STOCK then
                    used[slot_order] = true
                end
            end
        end
        return used
    end

    local function get_next_workshop_free_slot(self, tile_instance_id)
        local used = get_workshop_used_slots(self, tile_instance_id)
        for i = 1, WORKSHOP_OUTPUT_MAX_STOCK do
            if not used[i] then
                return i
            end
        end
        return nil
    end

    local function count_workshop_pending_tokens(self, tile_instance_id)
        local total = 0
        for _, token in ipairs(self.workshop_conveyor_tokens or {}) do
            if token and token.tile_instance_id == tile_instance_id then
                total = total + 1
            end
        end
        return total
    end

    local function get_workshop_menu_slot_by_world_point(cell, obj, world_x, world_y)
        if not cell or not obj then
            return nil
        end
        local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
        local mx = cx + (obj.offsetX or 0)
        local my = cy + (obj.offsetY or 0)
        local local_x = world_x - mx
        local local_y = world_y - my
        if local_x < -WORKSHOP_MENU_HALF_W or local_x > WORKSHOP_MENU_HALF_W then
            return nil
        end
        if local_y < -WORKSHOP_MENU_HALF_H or local_y > WORKSHOP_MENU_HALF_H then
            return nil
        end
        local col = math.floor((local_x + WORKSHOP_MENU_HALF_W) / WORKSHOP_MENU_SLOT_W) + 1
        local row_from_top = math.floor((WORKSHOP_MENU_HALF_H - local_y) / WORKSHOP_MENU_SLOT_H) + 1
        if col < 1 then col = 1 end
        if col > WORKSHOP_SLOT_GRID_W then col = WORKSHOP_SLOT_GRID_W end
        if row_from_top < 1 then row_from_top = 1 end
        if row_from_top > WORKSHOP_SLOT_GRID_H then row_from_top = WORKSHOP_SLOT_GRID_H end
        local slot_idx = ((row_from_top - 1) * WORKSHOP_SLOT_GRID_W) + col
        if slot_idx < 1 or slot_idx > 9 then
            return nil
        end
        return slot_idx
    end

    local function is_workshop_payment_hotspot(cell, obj, world_x, world_y)
        if not cell or not obj then
            return false
        end
        local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
        local mx = cx + (obj.offsetX or 0)
        local my = cy + (obj.offsetY or 0)
        local hx = mx + WORKSHOP_PAY_HOTSPOT_OFFSET_X
        local hy = my + WORKSHOP_PAY_HOTSPOT_OFFSET_Y
        local half = WORKSHOP_PAY_HOTSPOT_HALF_SIZE
        return world_x >= (hx - half)
            and world_x <= (hx + half)
            and world_y >= (hy - half)
            and world_y <= (hy + half)
    end

    local function count_factory_stock(self, tile_instance_id)
        local total = 0
        for _, item in ipairs(self.world_item_instances or {}) do
            local meta = item and item.meta or nil
            if item
                and item.item_type == "material"
                and meta
                and meta.factory_stock == true
                and meta.factory_tile_instance_id == tile_instance_id
            then
                total = total + 1
            end
        end
        return total
    end

    local function count_factory_pending_tokens(self, tile_instance_id)
        local total = 0
        for _, token in ipairs(self.factory_conveyor_tokens or {}) do
            if token and token.tile_instance_id == tile_instance_id then
                total = total + 1
            end
        end
        return total
    end

    local function count_material_items_on_cell(self, cell_id)
        if not cell_id then
            return 0
        end
        local total = 0
        for _, item in ipairs(self.world_item_instances or {}) do
            if item and item.item_type == "material" and item.cell_id == cell_id then
                total = total + 1
            end
        end
        return total
    end

    local function get_factory_used_slots(self, tile_instance_id)
        local used = {}
        for _, item in ipairs(self.world_item_instances or {}) do
            local meta = item and item.meta or nil
            if item
                and item.item_type == "material"
                and meta
                and meta.factory_stock == true
                and meta.factory_tile_instance_id == tile_instance_id
            then
                local slot_order = tonumber(meta.factory_slot_order or 0) or 0
                if slot_order >= 1 and slot_order <= FACTORY_MAX_STOCK then
                    used[slot_order] = true
                end
            end
        end
        return used
    end

    local function get_next_factory_free_slot(self, tile_instance_id)
        local used = get_factory_used_slots(self, tile_instance_id)
        for i = 1, FACTORY_MAX_STOCK do
            if not used[i] then
                return i
            end
        end
        return nil
    end

    local function spawn_factory_steam_fx(self, world_x, world_y)
        local fx_id = factory.create(
            "/factory_steam_fx_factory#factory_steam_fx_factory",
            vmath.vector3(world_x + FACTORY_STEAM_OFFSET_X, world_y + FACTORY_STEAM_OFFSET_Y, FACTORY_STEAM_FX_Z)
        )
        if not fx_id then
            return
        end
        pcall(go.set_rotation, vmath.quat_rotation_z(math.rad(FACTORY_STEAM_ROTATION_DEG)), fx_id)
        pcall(particlefx.play, msg.url(nil, fx_id, "particlefx"))
        timer.delay(FACTORY_STEAM_LIFETIME_SECONDS, false, function()
            pcall(go.delete, fx_id)
        end)
    end

    local function set_factory_underlay_tint(entry, tint)
        if not entry then
            return
        end
        if entry.cog_a_id then
            pcall(go.set, msg.url(nil, entry.cog_a_id, "sprite"), "tint", tint)
        end
        if entry.cog_b_id then
            pcall(go.set, msg.url(nil, entry.cog_b_id, "sprite"), "tint", tint)
        end
        if entry.belt_id then
            pcall(go.set, msg.url(nil, entry.belt_id, "sprite"), "tint", tint)
        end
    end

    runtime.refresh_factory_underlay_visuals = function(self)
        runtime.ensure_item_runtime_state(self)
        for _, entry in pairs(self.factory_underlay_visuals or {}) do
            if entry and entry.cog_a_id then pcall(go.delete, entry.cog_a_id) end
            if entry and entry.cog_b_id then pcall(go.delete, entry.cog_b_id) end
            if entry and entry.belt_id then pcall(go.delete, entry.belt_id) end
        end
        for _, marker_id in pairs(self.factory_debug_cell_markers or {}) do
            if marker_id then
                pcall(go.delete, marker_id)
            end
        end
        self.factory_debug_cell_markers = {}
        self.factory_underlay_visuals = {}
        local instances = get_factory_instances(self)
        for tile_instance_id, instance in pairs(instances) do
            local cell2 = instance.cell_by_local[2]
            local cell5 = instance.cell_by_local[5]
            local cell8 = instance.cell_by_local[8]
            if cell2 and cell5 and cell8 then
                local c2x, c2y = ctx.coords_to_world_pos(cell2.xCell, cell2.yCell)
                local c5x, c5y = ctx.coords_to_world_pos(cell5.xCell, cell5.yCell)
                local c8x, c8y = ctx.coords_to_world_pos(cell8.xCell, cell8.yCell)
                local belt_id = factory.create("/tile_factory#tile_factory", vmath.vector3(c2x, c2y - 47, FACTORY_UNDERLAY_Z))
                if belt_id then
                    msg.post(msg.url(nil, belt_id, "sprite"), "play_animation", { id = hash("tile_factory_belt") })
                    go.set_scale(vmath.vector3(2.34, 0.62, 1), belt_id)
                end
                local cog_a_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(c5x - 36, c5y + 66, FACTORY_UNDERLAY_Z + 0.0002))
                if cog_a_id then
                    msg.post(msg.url(nil, cog_a_id, "sprite"), "play_animation", { id = hash("tile_factory_piston") })
                    go.set_scale(vmath.vector3(1.5, 1.875, 1), cog_a_id)
                end
                local cog_b_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(c8x - 2, c8y - 10, FACTORY_UNDERLAY_Z + 0.0002))
                if cog_b_id then
                    msg.post(msg.url(nil, cog_b_id, "sprite"), "play_animation", { id = hash("tile_factory_cog") })
                    go.set_scale(vmath.vector3(1.5, 1.5, 1), cog_b_id)
                end
                local entry = {
                    tile_instance_id = tile_instance_id,
                    belt_id = belt_id,
                    cog_a_id = cog_a_id,
                    cog_b_id = cog_b_id,
                    belt_base_x = c2x,
                    belt_base_y = c2y - 47,
                    cog_a_base_x = c5x - 36,
                    cog_a_base_y = c5y + 66,
                    cog_a_angle = 0,
                    cog_b_angle = 0,
                    cog_a_piston_phase = math.random(),
                    belt_phase = math.random() * math.pi * 2
                }
                self.factory_underlay_visuals[tile_instance_id] = entry
                if instance.functional then
                    set_factory_underlay_tint(entry, vmath.vector4(1, 1, 1, 0.92))
                else
                    set_factory_underlay_tint(entry, vmath.vector4(0.34, 0.34, 0.34, 0.85))
                end

                -- Debug cell markers intentionally disabled.
            end
        end
        if runtime.refresh_workshop_underlay_visuals then
            runtime.refresh_workshop_underlay_visuals(self)
        end
    end

    local function set_workshop_underlay_tint(entry, tint)
        if not entry then
            return
        end
        if entry.printer_id then
            pcall(go.set, msg.url(nil, entry.printer_id, "sprite"), "tint", tint)
        end
        if entry.emitter_id then
            pcall(go.set, msg.url(nil, entry.emitter_id, "sprite"), "tint", tint)
        end
        if entry.belt_id then
            pcall(go.set, msg.url(nil, entry.belt_id, "sprite"), "tint", tint)
        end
    end

    runtime.refresh_workshop_underlay_visuals = function(self)
        runtime.ensure_item_runtime_state(self)
        for _, entry in pairs(self.workshop_underlay_visuals or {}) do
            if entry and entry.printer_id then pcall(go.delete, entry.printer_id) end
            if entry and entry.emitter_id then pcall(go.delete, entry.emitter_id) end
            if entry and entry.belt_id then pcall(go.delete, entry.belt_id) end
        end
        self.workshop_underlay_visuals = {}
        local instances = get_workshop_instances(self)
        for tile_instance_id, instance in pairs(instances) do
            local cell1 = instance.cell_by_local[1]
            local cell4 = instance.cell_by_local[4]
            if cell1 and cell4 then
                local c1x, c1y = ctx.coords_to_world_pos(cell1.xCell, cell1.yCell)
                local c4x, c4y = ctx.coords_to_world_pos(cell4.xCell, cell4.yCell)
                local printer_base_x = c4x
                local printer_base_y = c4y + ((ctx.CELL_HEIGHT or 150) * 0.5) - 30
                local printer_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(printer_base_x, printer_base_y, WORKSHOP_PRINTER_Z))
                if printer_id then
                    msg.post(msg.url(nil, printer_id, "sprite"), "play_animation", { id = hash("tile_workshop_printerOff") })
                    go.set_scale(vmath.vector3(0.9, 0.9, 1), printer_id)
                    pcall(go.set, msg.url(nil, printer_id, "sprite"), "blend_mode", hash("add"))
                end
                local emitter_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(printer_base_x, printer_base_y - 100, WORKSHOP_EMITTER_Z))
                if emitter_id then
                    msg.post(msg.url(nil, emitter_id, "sprite"), "play_animation", { id = hash("tile_workshop_printerGlow") })
                    go.set_scale(vmath.vector3(0.95, 0.95, 1), emitter_id)
                    pcall(go.set, msg.url(nil, emitter_id, "sprite"), "blend_mode", hash("add"))
                end
                local belt_base_y = c1y - 47
                local belt_id = factory.create("/tile_factory#tile_factory", vmath.vector3(c1x, belt_base_y, FACTORY_UNDERLAY_Z))
                if belt_id then
                    msg.post(msg.url(nil, belt_id, "sprite"), "play_animation", { id = hash("tile_factory_belt") })
                    go.set_scale(vmath.vector3(2.34, 0.62, 1), belt_id)
                end
                self.workshop_underlay_visuals[tile_instance_id] = {
                    tile_instance_id = tile_instance_id,
                    printer_id = printer_id,
                    emitter_id = emitter_id,
                    belt_id = belt_id,
                    printer_base_x = printer_base_x,
                    printer_base_y = printer_base_y,
                    belt_base_x = c1x,
                    belt_base_y = belt_base_y,
                    printer_current_x = 0,
                    printer_target_x = 0,
                    printer_change_timer = 0,
                    belt_phase = math.random(),
                    flicker_timer = 0,
                    flicker_value = 1,
                    printer_anim_mode = "off",
                    phase = math.random() * math.pi * 2
                }
            end
        end
    end

    runtime.update_workshop_underlay_animations = function(self, dt)
        runtime.ensure_item_runtime_state(self)
        local instances = get_workshop_instances(self)
        for tile_instance_id, entry in pairs(self.workshop_underlay_visuals or {}) do
            local instance = instances[tile_instance_id]
            local functional = instance and instance.functional == true
            local speed = functional and 1.0 or 0.22
            local state = get_workshop_state(self, tile_instance_id)
            local is_producing = (state.production_time_left or 0) > 0
            local workshop_anim_speed_scale = 0.5
            local scaled_dt = (dt or 0) * workshop_anim_speed_scale
            entry.phase = (entry.phase or 0) + ((dt or 0) * speed * 8.0)
            local desired_mode = (functional and is_producing) and "on" or "off"
            if entry.printer_id and entry.printer_anim_mode ~= desired_mode then
                local anim_id = (desired_mode == "on") and hash("tile_workshop_printer") or hash("tile_workshop_printerOff")
                msg.post(msg.url(nil, entry.printer_id, "sprite"), "play_animation", { id = anim_id })
                entry.printer_anim_mode = desired_mode
            end
            if functional and is_producing then
                entry.flicker_timer = (entry.flicker_timer or 0) - scaled_dt
                if (entry.flicker_timer or 0) <= 0 then
                    entry.flicker_timer = 0.03 + (math.random() * 0.07)
                    local r = math.random()
                    entry.flicker_value = r * r
                end
            else
                entry.flicker_timer = 0
                entry.flicker_value = functional and 0.72 or 0.34
            end
            local flicker = entry.flicker_value or 1
            local printer_tint = functional and vmath.vector4(flicker, flicker, flicker, 0.98) or vmath.vector4(0.34, 0.34, 0.34, 0.85)
            local emitter_alpha = (functional and is_producing) and flicker or 0
            local emitter_tint = vmath.vector4(1, 1, 1, emitter_alpha)
            local belt_tint = functional and vmath.vector4(1, 1, 1, 0.9) or vmath.vector4(0.34, 0.34, 0.34, 0.85)
            if entry.printer_id then
                pcall(go.set, msg.url(nil, entry.printer_id, "sprite"), "tint", printer_tint)
            end
            if entry.emitter_id then
                pcall(go.set, msg.url(nil, entry.emitter_id, "sprite"), "tint", emitter_tint)
            end
            if entry.belt_id then
                pcall(go.set, msg.url(nil, entry.belt_id, "sprite"), "tint", belt_tint)
            end
            if is_producing and functional then
                entry.printer_change_timer = (entry.printer_change_timer or 0) - scaled_dt
                if (entry.printer_change_timer or 0) <= 0 then
                    entry.printer_target_x = -60 + (math.random() * 120)
                    entry.printer_change_timer = 0.05 + (math.random() * 0.09)
                end
                local move_blend = math.min(1, scaled_dt * 16)
                entry.printer_current_x = (entry.printer_current_x or 0) + (((entry.printer_target_x or 0) - (entry.printer_current_x or 0)) * move_blend)
            else
                entry.printer_target_x = 0
                entry.printer_change_timer = 0
                local idle_blend = math.min(1, (dt or 0) * 5)
                entry.printer_current_x = (entry.printer_current_x or 0) + ((0 - (entry.printer_current_x or 0)) * idle_blend)
            end
            local px = (entry.printer_base_x or 0) + (entry.printer_current_x or 0)
            local py = entry.printer_base_y or 0
            if entry.printer_id then
                pcall(go.set_position, vmath.vector3(px, py, WORKSHOP_PRINTER_Z), entry.printer_id)
            end
            if entry.emitter_id then
                pcall(go.set_position, vmath.vector3(px, py - 100, WORKSHOP_EMITTER_Z), entry.emitter_id)
            end
            if entry.belt_id then
                local half_w = ((ctx.CELL_WIDTH or 250) * 0.5)
                entry.belt_phase = ((entry.belt_phase or 0) + ((dt or 0) * FACTORY_BELT_PAN_RATE * speed)) % 1
                local pan = -half_w + ((entry.belt_phase or 0) * (half_w * 2))
                local bx = (entry.belt_base_x or 0) + pan
                local by = entry.belt_base_y or 0
                pcall(go.set_position, vmath.vector3(bx, by, FACTORY_UNDERLAY_Z), entry.belt_id)
            end
        end
    end

    runtime.process_factory_turn = function(self)
        runtime.ensure_item_runtime_state(self)
        local instances = get_factory_instances(self)
        self.factory_instance_cache = instances
        for tile_instance_id, instance in pairs(instances) do
            local pending = count_factory_pending_tokens(self, tile_instance_id)
            local conveyor_cell = instance.cell_by_local[2]
            local output_cell = instance.cell_by_local[3]
            local stored_total = output_cell and count_material_items_on_cell(self, output_cell.idNumber) or 0
            if instance.functional and (stored_total + pending) < FACTORY_MAX_STOCK then
                if conveyor_cell and output_cell then
                    local cx, cy = ctx.coords_to_world_pos(conveyor_cell.xCell, conveyor_cell.yCell)
                    local token_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(cx - 75, cy - 45, FACTORY_CONVEYOR_TOKEN_Z))
                    if token_id then
                        msg.post(msg.url(nil, token_id, "sprite"), "play_animation", { id = hash("material_unit") })
                        go.set_scale(vmath.vector3(0.85, 0.85, 1), token_id)
                        go.set(msg.url(nil, token_id, "sprite"), "tint", vmath.vector4(1, 1, 1, 0.96))
                        spawn_factory_steam_fx(self, cx, cy)
                        table.insert(self.factory_conveyor_tokens, {
                            go_id = token_id,
                            tile_instance_id = tile_instance_id,
                            output_cell_id = output_cell.idNumber,
                            start_x = cx - ((ctx.CELL_WIDTH or 250) * 0.5) + 25,
                            start_y = cy - 30,
                            end_x = cx + ((ctx.CELL_WIDTH or 250) * 0.5),
                            end_y = cy - 30,
                            t = 0,
                            duration = 1 / FACTORY_BELT_PAN_RATE
                        })
                    end
                end
            end
        end
    end

    runtime.update_factory_underlay_animations = function(self, dt)
        runtime.ensure_item_runtime_state(self)
        if not self.factory_underlay_visuals then
            return
        end
        local instances = get_factory_instances(self)
        self.factory_underlay_clock = (self.factory_underlay_clock or 0) + dt
        for tile_instance_id, entry in pairs(self.factory_underlay_visuals) do
            local instance = instances[tile_instance_id]
            local functional = instance and instance.functional == true
            local speed_mul = functional and 1.0 or 0.22
            local tint = functional and vmath.vector4(1, 1, 1, 0.92) or vmath.vector4(0.34, 0.34, 0.34, 0.85)
            set_factory_underlay_tint(entry, tint)
            if entry.belt_id then
                local half_w = ((ctx.CELL_WIDTH or 250) * 0.5)
                entry.belt_phase = ((entry.belt_phase or 0) + (dt * FACTORY_BELT_PAN_RATE * speed_mul)) % 1
                local pan = -half_w + ((entry.belt_phase or 0) * (half_w * 2))
                local x = (entry.belt_base_x or 0) + pan
                local y = entry.belt_base_y or 0
                pcall(go.set_position, vmath.vector3(x, y, FACTORY_UNDERLAY_Z), entry.belt_id)
            end
            if entry.cog_a_id then
                -- Cell-5 machinery: piston-like vertical motion.
                -- Down stroke is slower; up stroke is faster.
                local phase = (entry.cog_a_piston_phase or 0) + (dt * 0.58 * speed_mul)
                phase = phase % 1
                entry.cog_a_piston_phase = phase
                local down_portion = 0.75
                local travel = 95
                local y_offset = 0
                if phase < down_portion then
                    y_offset = -travel * (phase / down_portion)
                else
                    local up_t = (phase - down_portion) / (1 - down_portion)
                    y_offset = -travel + (travel * up_t)
                end
                pcall(
                    go.set_position,
                    vmath.vector3(entry.cog_a_base_x or 0, (entry.cog_a_base_y or 0) + y_offset, FACTORY_UNDERLAY_Z + 0.0002),
                    entry.cog_a_id
                )
                pcall(go.set_rotation, vmath.quat_rotation_z(0), entry.cog_a_id)
            end
            if entry.cog_b_id then
                entry.cog_b_angle = (entry.cog_b_angle or 0) - (dt * 3.5 * speed_mul)
                pcall(go.set_rotation, vmath.quat_rotation_z(entry.cog_b_angle), entry.cog_b_id)
            end
        end
        if runtime.update_workshop_underlay_animations then
            runtime.update_workshop_underlay_animations(self, dt)
        end
        runtime.update_workshop_production(self, dt)
    end

    runtime.update_factory_conveyor_tokens = function(self, dt)
        runtime.ensure_item_runtime_state(self)
        if not self.factory_conveyor_tokens then
            return
        end
        local needs_world_item_refresh = false
        for i = #self.factory_conveyor_tokens, 1, -1 do
            local token = self.factory_conveyor_tokens[i]
            if not token or not token.go_id then
                table.remove(self.factory_conveyor_tokens, i)
            else
                token.t = math.min(1, (token.t or 0) + (dt / math.max(0.01, token.duration or 0.9)))
                local px = token.start_x + ((token.end_x - token.start_x) * token.t)
                local py = token.start_y + ((token.end_y - token.start_y) * token.t) + (math.sin(token.t * math.pi) * 5)
                pcall(go.set_position, vmath.vector3(px, py, FACTORY_CONVEYOR_TOKEN_Z), token.go_id)
                if token.t >= 1 then
                    pcall(go.delete, token.go_id)
                    local instances = self.factory_instance_cache or get_factory_instances(self)
                    local instance = instances[token.tile_instance_id]
                    if instance then
                        local output_cell = instance.cell_by_local[3]
                        local pending = count_factory_pending_tokens(self, token.tile_instance_id)
                        local stored_total = output_cell and count_material_items_on_cell(self, output_cell.idNumber) or 0
                        local slot_order = get_next_factory_free_slot(self, token.tile_instance_id)
                        if instance.functional
                            and (stored_total + math.max(0, pending - 1)) < FACTORY_MAX_STOCK
                            and slot_order
                            and output_cell
                        then
                            runtime.create_world_item_instance(self, "material", output_cell.idNumber, nil, {
                                factory_stock = true,
                                factory_tile_instance_id = token.tile_instance_id,
                                factory_slot_order = slot_order
                            })
                            needs_world_item_refresh = true
                        end
                    end
                    table.remove(self.factory_conveyor_tokens, i)
                end
            end
        end
        if needs_world_item_refresh then
            runtime.refresh_world_item_visuals(self)
        end
        if runtime.update_workshop_conveyor_tokens then
            runtime.update_workshop_conveyor_tokens(self, dt)
        end
    end

    runtime.update_workshop_production = function(self, dt)
        runtime.ensure_item_runtime_state(self)
        local instances = get_workshop_instances(self)
        for tile_instance_id, instance in pairs(instances) do
            local state = get_workshop_state(self, tile_instance_id)
            if (state.production_time_left or 0) > 0 then
                if instance.functional then
                    state.production_time_left = math.max(0, (state.production_time_left or 0) - (dt or 0))
                end
                if state.production_time_left <= 0 then
                    local selected = get_workshop_product_for_slot(state.selected_slot)
                    local source_cell = instance.cell_by_local[1]
                    local output_cell = instance.cell_by_local[2]
                    local pending = count_workshop_pending_tokens(self, tile_instance_id)
                    if selected and source_cell and output_cell then
                        local all_items = runtime.get_world_items_on_cell(self, output_cell.idNumber)
                        if (#all_items + pending) >= WORKSHOP_OUTPUT_MAX_STOCK then
                            print("Workshop output cell is full.")
                        else
                            local c1x, c1y = ctx.coords_to_world_pos(source_cell.xCell, source_cell.yCell)
                            local c2x, c2y = ctx.coords_to_world_pos(output_cell.xCell, output_cell.yCell)
                            local token_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(c1x - 98, c1y - 36, WORKSHOP_CONVEYOR_TOKEN_Z))
                            if token_id then
                                local anim = get_world_item_animation(selected.item_type)
                                if anim then
                                    msg.post(msg.url(nil, token_id, "sprite"), "play_animation", { id = anim })
                                end
                                go.set_scale(vmath.vector3(0.85, 0.85, 1), token_id)
                                go.set(msg.url(nil, token_id, "sprite"), "tint", vmath.vector4(1, 1, 1, 0.98))
                                table.insert(self.workshop_conveyor_tokens, {
                                    go_id = token_id,
                                    tile_instance_id = tile_instance_id,
                                    output_cell_id = output_cell.idNumber,
                                    item_type = selected.item_type,
                                    label = selected.label,
                                    start_x = c1x - 98,
                                    start_y = c1y - 26,
                                    end_x = c2x - 90,
                                    end_y = c2y - 26,
                                    t = 0,
                                    duration = WORKSHOP_CONVEYOR_TRAVEL_SECONDS
                                })
                                print(string.format("Workshop moving %s to output lane.", selected.label))
                            end
                        end
                    end
                end
            end
        end
    end

    runtime.update_workshop_conveyor_tokens = function(self, dt)
        runtime.ensure_item_runtime_state(self)
        if not self.workshop_conveyor_tokens then
            return
        end
        local needs_world_item_refresh = false
        for i = #self.workshop_conveyor_tokens, 1, -1 do
            local token = self.workshop_conveyor_tokens[i]
            if not token or not token.go_id then
                table.remove(self.workshop_conveyor_tokens, i)
            else
                token.t = math.min(1, (token.t or 0) + ((dt or 0) / math.max(0.01, token.duration or 0.9)))
                local px = token.start_x + ((token.end_x - token.start_x) * token.t)
                local py = token.start_y + ((token.end_y - token.start_y) * token.t)
                pcall(go.set_position, vmath.vector3(px, py, WORKSHOP_CONVEYOR_TOKEN_Z), token.go_id)
                if token.t >= 1 then
                    pcall(go.delete, token.go_id)
                    local slot_order = get_next_workshop_free_slot(self, token.tile_instance_id)
                    local output_cell_id = token.output_cell_id
                    if slot_order and output_cell_id then
                        runtime.create_world_item_instance(self, token.item_type, output_cell_id, nil, {
                            workshop_stock = true,
                            workshop_tile_instance_id = token.tile_instance_id,
                            workshop_slot_order = slot_order
                        })
                        needs_world_item_refresh = true
                        print(string.format("Workshop dispensed %s.", tostring(token.label or token.item_type)))
                    end
                    table.remove(self.workshop_conveyor_tokens, i)
                end
            end
        end
        if needs_world_item_refresh then
            runtime.refresh_world_item_visuals(self)
        end
    end

    runtime.emit_derple_feedback = function(self, unit_id, event_type)
        runtime.ensure_item_runtime_state(self)
        if not self.squad_units or not unit_id then
            return false
        end
        local def = DERPLE_FEEDBACK_EVENT_DEFS[event_type]
        local unit = self.squad_units[unit_id]
        if not def or not unit or not unit.go_path or (unit.current_health or 0) <= 0 then
            return false
        end
        local now = self.derple_feedback_clock or 0
        self.derple_feedback_cooldowns[unit_id] = self.derple_feedback_cooldowns[unit_id] or {}
        local cooldown_until = self.derple_feedback_cooldowns[unit_id][event_type] or 0
        if now < cooldown_until then
            return false
        end
        self.derple_feedback_cooldowns[unit_id][event_type] = now + (def.cooldown or 0.8)

        local existing_index = self.derple_feedback_by_unit_id[unit_id]
        if existing_index then
            local existing = self.derple_feedback_entries[existing_index]
            if existing and existing.go_id then
                go.delete(existing.go_id)
            end
            self.derple_feedback_entries[existing_index] = nil
            self.derple_feedback_by_unit_id[unit_id] = nil
        end

        local pos = go.get_position(unit.go_path)
        local marker_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(pos.x + (def.x_offset or 0), pos.y + (def.y_offset or 70), 0.84))
        if not marker_id then
            return false
        end
        msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = def.anim })
        go.set(msg.url(nil, marker_id, "sprite"), "tint", vmath.vector4(1, 1, 1, 1))
        local scale = def.scale or 0.72
        go.set_scale(vmath.vector3(scale, scale, 1), marker_id)

        local entry = {
            go_id = marker_id,
            unit_id = unit_id,
            event_type = event_type,
            ttl = def.duration or 1.0,
            x_offset = def.x_offset or 0,
            y_offset = def.y_offset or 70
        }
        table.insert(self.derple_feedback_entries, entry)
        self.derple_feedback_by_unit_id[unit_id] = #self.derple_feedback_entries
        return true
    end

    runtime.update_derple_feedback_bubbles = function(self, dt)
        runtime.ensure_item_runtime_state(self)
        self.derple_feedback_clock = (self.derple_feedback_clock or 0) + dt
        for i = #self.derple_feedback_entries, 1, -1 do
            local entry = self.derple_feedback_entries[i]
            local keep = false
            if entry and entry.go_id and self.squad_units and entry.unit_id then
                local unit = self.squad_units[entry.unit_id]
                if unit and unit.go_path and (unit.current_health or 0) > 0 then
                    entry.ttl = (entry.ttl or 0) - dt
                    if entry.ttl > 0 then
                        local pos = go.get_position(unit.go_path)
                        go.set_position(vmath.vector3(pos.x + (entry.x_offset or 0), pos.y + (entry.y_offset or 70), 0.84), entry.go_id)
                        keep = true
                    end
                end
            end
            if not keep then
                if entry and entry.go_id then
                    go.delete(entry.go_id)
                end
                self.derple_feedback_entries[i] = nil
                if entry and entry.unit_id then
                    self.derple_feedback_by_unit_id[entry.unit_id] = nil
                end
            end
        end
    end

    runtime.create_world_item_instance = function(self, item_type, cell_id, owner_unit_id, meta)
        runtime.ensure_item_runtime_state(self)
        self.next_world_item_id = self.next_world_item_id + 1
        local item = {
            id = self.next_world_item_id,
            item_type = item_type,
            cell_id = cell_id,
            owner_unit_id = owner_unit_id,
            meta = meta or {}
        }
        table.insert(self.world_item_instances, item)
        return item
    end

    runtime.remove_world_item_instance = function(self, world_item_id)
        runtime.ensure_item_runtime_state(self)
        for i = #self.world_item_instances, 1, -1 do
            local item = self.world_item_instances[i]
            if item and item.id == world_item_id then
                table.remove(self.world_item_instances, i)
                break
            end
        end
        local visual = self.world_item_visuals[world_item_id]
        if visual then
            go.delete(visual)
            self.world_item_visuals[world_item_id] = nil
        end
        local shadow_visual = self.world_item_shadow_visuals[world_item_id]
        if shadow_visual then
            go.delete(shadow_visual)
            self.world_item_shadow_visuals[world_item_id] = nil
        end
    end

    runtime.get_world_items_on_cell = function(self, cell_id)
        runtime.ensure_item_runtime_state(self)
        local out = {}
        for _, item in ipairs(self.world_item_instances) do
            if item and item.cell_id == cell_id then
                table.insert(out, item)
            end
        end
        table.sort(out, function(a, b)
            local a_order = (a.meta and a.meta.slot_order) or 0
            local b_order = (b.meta and b.meta.slot_order) or 0
            if a_order == b_order then
                return (a.id or 0) < (b.id or 0)
            end
            return a_order < b_order
        end)
        return out
    end

    local function get_dead_human_by_id(self, unit_id)
        if not self.squad_units or not unit_id then
            return nil
        end
        local unit = self.squad_units[unit_id]
        if unit and (unit.current_health or 0) <= 0 then
            return unit
        end
        return nil
    end

    runtime.find_cell_id_at_world_point = function(self, world_x, world_y)
        if not self.world_grid then
            return nil
        end
        local half_w = ((ctx.CELL_WIDTH or 250) * 0.5)
        local half_h = ((ctx.CELL_HEIGHT or 150) * 0.5)
        for _, cell in ipairs(self.world_grid) do
            if cell and cell.tileID ~= hash("empty") then
                local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                if world_x >= (cx - half_w)
                    and world_x <= (cx + half_w)
                    and world_y >= (cy - half_h)
                    and world_y <= (cy + half_h) then
                    return cell.idNumber
                end
            end
        end
        return nil
    end

    runtime.get_world_item_offset_for_slot = function(slot_index, total_items)
        local cols = 4
        local spacing_x = 16
        local spacing_y = 14
        local row = math.floor((slot_index - 1) / cols)
        local col = (slot_index - 1) % cols
        local row_count = math.min(cols, math.max(1, total_items - (row * cols)))
        local start_x = -((row_count - 1) * spacing_x * 0.5)
        local ox = start_x + (col * spacing_x)
        local floor_from_center = -((ctx.CELL_HEIGHT or 150) * 0.5) + WORLD_ITEM_FLOOR_OFFSET_FROM_CELL_BOTTOM
        local oy = floor_from_center - (row * spacing_y)
        return ox, oy
    end

    local function get_world_item_render_offset(item, slot_index, total_items)
        local meta = item and item.meta or nil
        if meta and meta.factory_stock == true then
            local slot_order = tonumber(meta.factory_slot_order or 0) or 0
            if slot_order >= 1 and slot_order <= #FACTORY_STACK_SLOT_OFFSETS then
                local v = FACTORY_STACK_SLOT_OFFSETS[slot_order]
                return v.x, v.y
            end
        end
        if meta and meta.workshop_stock == true then
            local slot_order = tonumber(meta.workshop_slot_order or 0) or 0
            if slot_order >= 1 and slot_order <= #FACTORY_STACK_SLOT_OFFSETS then
                local v = FACTORY_STACK_SLOT_OFFSETS[slot_order]
                return v.x, v.y
            end
        end
        return runtime.get_world_item_offset_for_slot(slot_index, total_items)
    end

    runtime.refresh_world_item_visuals = function(self)
        runtime.ensure_item_runtime_state(self)
        for item_id, go_id in pairs(self.world_item_visuals) do
            if go_id then
                go.delete(go_id)
            end
            self.world_item_visuals[item_id] = nil
        end
        for item_id, go_id in pairs(self.world_item_shadow_visuals) do
            if go_id then
                go.delete(go_id)
            end
            self.world_item_shadow_visuals[item_id] = nil
        end
        if not self.world_item_instances or not self.world_grid then
            return
        end
        local world_shadows_enabled = (self.aesthetic_mode == "boardgame")
        for _, cell in ipairs(self.world_grid) do
            if cell and cell.tileID ~= hash("empty") then
                local items = runtime.get_world_items_on_cell(self, cell.idNumber)
                local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                for i, item in ipairs(items) do
                    local ox, oy = get_world_item_render_offset(item, i, #items)
                    local wx = cx + ox
                    local wy = cy + oy
                    local marker_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(wx, wy, 0.56))
                    if marker_id then
                        local anim = get_world_item_animation(item.item_type)
                        if world_shadows_enabled then
                            local shadow_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(wx + 6, wy - 8, 0.5))
                            if shadow_id then
                                if anim then
                                    msg.post(msg.url(nil, shadow_id, "sprite"), "play_animation", { id = anim })
                                end
                                go.set(msg.url(nil, shadow_id, "sprite"), "tint", vmath.vector4(0, 0, 0, 0.45))
                                go.set_scale(vmath.vector3(0.85, 0.85, 1), shadow_id)
                                self.world_item_shadow_visuals[item.id] = shadow_id
                            end
                        end
                        if anim then
                            msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = anim })
                            go.set(msg.url(nil, marker_id, "sprite"), "tint", vmath.vector4(1, 1, 1, 1))
                        else
                            local color = runtime.get_backpack_item_color(item.item_type)
                            go.set(msg.url(nil, marker_id, "sprite"), "tint", color)
                        end
                        go.set_scale(vmath.vector3(0.85, 0.85, 1), marker_id)
                        self.world_item_visuals[item.id] = marker_id
                        print(string.format(
                            "WORLD ITEM VISUAL | id=%d type=%s cell=%d slot=%d/%d pos=(%.1f, %.1f)",
                            item.id or 0,
                            tostring(item.item_type),
                            cell.idNumber or 0,
                            i,
                            #items,
                            wx,
                            wy
                        ))
                    end
                end
            end
        end
    end

    runtime.find_world_item_at_screen_point = function(self, screen_x, screen_y)
        runtime.ensure_item_runtime_state(self)
        local world_x, world_y = ctx.screen_to_world(screen_x, screen_y, self.camera_pos, self.camera_zoom)
        local cell_id = runtime.find_cell_id_at_world_point(self, world_x, world_y)
        if not cell_id then
            return nil, nil
        end
        local cell = self.world_grid and self.world_grid[cell_id]
        if not cell then
            return nil, nil
        end
        local items = runtime.get_world_items_on_cell(self, cell_id)
        if #items == 0 then
            return nil, nil
        end
        local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
        local best_item = nil
        local best_dist = math.huge
        local hit_radius = (ctx.LOOT_UI and ctx.LOOT_UI.world_item_hit_radius) or 22
        for i = #items, 1, -1 do
            local item = items[i]
            local ox, oy = get_world_item_render_offset(item, i, #items)
            local ix = cx + ox
            local iy = cy + oy
            local dx = ix - world_x
            local dy = iy - world_y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist <= hit_radius and dist < best_dist then
                best_item = item
                best_dist = dist
            end
        end
        return best_item, cell_id
    end

    runtime.find_dead_human_at_screen_point = function(self, screen_x, screen_y)
        if not self.squad_units then
            return nil
        end
        local world_x, world_y = ctx.screen_to_world(screen_x, screen_y, self.camera_pos, self.camera_zoom)
        local best = nil
        local best_dist = math.huge
        local max_dist = (ctx.LOOT_UI and ctx.LOOT_UI.human_drop_radius) or 80
        for _, unit in pairs(self.squad_units) do
            if unit and (unit.current_health or 0) <= 0 and unit.cell_id and unit.go_path then
                local pos = go.get_position(unit.go_path)
                local dx = pos.x - world_x
                local dy = pos.y - world_y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist <= max_dist and dist < best_dist then
                    best = unit
                    best_dist = dist
                end
            end
        end
        return best
    end

    runtime.try_store_dead_human_corpse_selected_unit = function(self, screen_x, screen_y)
        local unit = ctx.get_selected_unit(self)
        if not unit or not unit.cell_id then
            return false
        end
        local dead_unit = runtime.find_dead_human_at_screen_point(self, screen_x, screen_y)
        if not dead_unit then
            return false
        end
        if dead_unit.id == unit.id then
            return true
        end
        if dead_unit.cell_id ~= unit.cell_id then
            return false
        end
        unit.backpack_items = unit.backpack_items or {}
        if #unit.backpack_items > 0 then
            print("Backpack must be emptied before carrying a corpse.")
            flash_invalid_drag_units(unit, dead_unit)
            return true
        end
        if not try_consume_drag_ap(unit, dead_unit) then
            return true
        end
        local cap = unit.backpack_slots or (ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS)
        unit.backpack_items = {}
        for _ = 1, cap do
            table.insert(unit.backpack_items, "corpse")
        end
        unit.backpack_used = #unit.backpack_items
        unit.carrying_corpse_id = dead_unit.id
        dead_unit.cell_id = nil
        dead_unit.is_corpse_stowed = true
        if dead_unit.go_path then
            go.set_position(vmath.vector3(-9999, -9999, 0.5), dead_unit.go_path)
        end
        print(string.format("%s moved %s corpse into backpack. (AP -%d)", unit.display_name, dead_unit.display_name, get_drag_ap_cost()))
        return true
    end

    runtime.find_fix_object_drop_target = function(self, world_x, world_y, cell_id, required_component)
        if not self.world_grid or not cell_id then
            return nil
        end
        local cell = self.world_grid[cell_id]
        if not cell then
            return nil
        end
        local best = nil
        local best_dist = math.huge
        local objects = { cell.object1, cell.object2, cell.object3 }
        for _, obj in ipairs(objects) do
            if obj
                and obj.name
                and obj.name ~= hash("empty")
                and obj.name ~= hash("machine")
                and obj.name ~= hash("factory_machine")
                and obj.name ~= hash("workshop_menu")
                and obj.name ~= hash("workshop_machine_top")
                and obj.name ~= hash("gun_turret")
                and obj.name ~= hash("power_node")
                and obj.isFixed ~= true then
                local requires = obj.requiredComponent or ctx.COMPONENT_UI.item_type_blue
                if not required_component or required_component == requires then
                    local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                    local ox = obj.offsetX or 0
                    local oy = obj.offsetY or 0
                    local half_w = ((obj.hitW or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
                    local half_h = ((obj.hitH or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
                    local x = cx + ox
                    local y = cy + oy
                    local inside = world_x >= (x - half_w)
                        and world_x <= (x + half_w)
                        and world_y >= (y - half_h)
                        and world_y <= (y + half_h)
                    if inside then
                        local dx = x - world_x
                        local dy = y - world_y
                        local dist = math.sqrt(dx * dx + dy * dy)
                        if dist < best_dist then
                            best = obj
                            best_dist = dist
                        end
                    end
                end
            end
        end
        return best
    end

    runtime.find_vent_weld_drop_target = function(self, world_x, world_y, cell_id)
        if not self.world_grid or not cell_id then
            return nil
        end
        local cell = self.world_grid[cell_id]
        if not cell then
            return nil
        end
        local vent = runtime.get_vent_object(cell)
        if not vent or vent.isWelded == true then
            return nil
        end
        local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
        local x = cx + (vent.offsetX or 0)
        local y = cy + (vent.offsetY or 0)
        local half_w = ((vent.hitW or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
        local half_h = ((vent.hitH or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
        local inside = world_x >= (x - half_w)
            and world_x <= (x + half_w)
            and world_y >= (y - half_h)
            and world_y <= (y + half_h)
        if inside then
            return vent
        end
        return nil
    end

    runtime.play_power_node_activation_sound = function(self, cell, power_node)
        -- FUTURE HOOK: trigger power-node activation SFX when audio assets are ready.
    end

    runtime.stop_power_node_fx_for_cell = function(self, cell_id)
        if not self.power_node_loop_fx or not cell_id then
            return
        end
        local fx_id = self.power_node_loop_fx[cell_id]
        if fx_id then
            go.delete(fx_id)
            self.power_node_loop_fx[cell_id] = nil
        end
    end

    runtime.spawn_vent_weld_fx = function(self, cell, vent_obj)
        if not self or not cell or not cell.idNumber then
            return
        end
        local weld_fx_duration = 1.5
        local vent = vent_obj or runtime.get_vent_object(cell)
        self.vent_weld_fx_cells = self.vent_weld_fx_cells or {}
        self.vent_weld_fx_cells[cell.idNumber] = true
        print(string.format("WELD FX FLAG: cell %d active", cell.idNumber))
        if vent then
            self.vent_weld_sparks_fx = self.vent_weld_sparks_fx or {}
            local existing_fx = self.vent_weld_sparks_fx[cell.idNumber]
            if existing_fx then
                go.delete(existing_fx)
                self.vent_weld_sparks_fx[cell.idNumber] = nil
            end
            local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
            local fx_x = cx + (vent.offsetX or 0)
            local fx_y = cy + (vent.offsetY or 0)
            local fx_id = factory.create("/weld_sparks_fx_factory#weld_sparks_fx_factory", vmath.vector3(fx_x, fx_y, WELD_SPARKS_Z))
            if fx_id then
                self.vent_weld_sparks_fx[cell.idNumber] = fx_id
                particlefx.play(msg.url(nil, fx_id, "particlefx"))
            end
        end
        runtime.refresh_vent_markers(self)
        timer.delay(weld_fx_duration, false, function()
            if self and self.vent_weld_fx_cells then
                self.vent_weld_fx_cells[cell.idNumber] = nil
            end
            if self and self.vent_weld_sparks_fx then
                local fx_id = self.vent_weld_sparks_fx[cell.idNumber]
                if fx_id then
                    go.delete(fx_id)
                    self.vent_weld_sparks_fx[cell.idNumber] = nil
                end
            end
            runtime.refresh_vent_markers(self)
        end)
    end

    runtime.spawn_power_node_activation_fx = function(self, cell, power_node)
        if not cell or not power_node then
            return
        end
        self.power_node_loop_fx = self.power_node_loop_fx or {}
        local cell_id = cell.idNumber or 0
        if cell_id > 0 and self.power_node_loop_fx[cell_id] then
            return
        end
        local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
        local px = cx + (power_node.offsetX or 0) + (power_node.fxOffsetX or 0)
        local py = cy + (power_node.offsetY or 0) + (power_node.fxOffsetY or 0)
        local pz = 0.39
        local fx_id = factory.create("/power_node_steam_fx_factory#power_node_steam_fx_factory", vmath.vector3(px, py, pz))
        if not fx_id then
            return
        end
        local rotation_deg = power_node.fxRotation or 0
        go.set_rotation(vmath.quat_rotation_z(math.rad(rotation_deg)), fx_id)
        particlefx.play(msg.url(nil, fx_id, "particlefx"))
        if cell_id > 0 then
            self.power_node_loop_fx[cell_id] = fx_id
        end
    end

    runtime.find_power_node_drop_target = function(self, world_x, world_y)
        if not self.world_grid then
            return nil
        end

        local best_cell = nil
        local best_dist = math.huge
        for _, cell in ipairs(self.world_grid) do
            local power_node = runtime.get_power_node_object(cell)
            if power_node and cell.tileID ~= hash("empty") then
                local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local node_x = cx + (power_node.offsetX or 0)
                local node_y = cy + (power_node.offsetY or 0)
                local half_w = ((power_node.hitW or 64) * 0.5)
                local half_h = ((power_node.hitH or 124) * 0.5)
                local inside = world_x >= (node_x - half_w)
                    and world_x <= (node_x + half_w)
                    and world_y >= (node_y - half_h)
                    and world_y <= (node_y + half_h)
                if inside then
                    local dx = node_x - world_x
                    local dy = node_y - world_y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    best_cell = cell
                    best_dist = dist
                end
            end
        end
        return best_cell
    end

    runtime.find_escape_pod_power_socket_drop_target = function(self, world_x, world_y)
        if not self.world_grid then
            return nil, nil
        end
        local best_cell = nil
        local best_obj = nil
        local best_dist = math.huge
        for _, cell in ipairs(self.world_grid) do
            local socket = runtime.get_escape_pod_power_socket_object and runtime.get_escape_pod_power_socket_object(cell) or nil
            if socket and cell.tileID ~= hash("empty") then
                local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local sx = cx + (socket.offsetX or 0)
                local sy = cy + (socket.offsetY or 0)
                local half_w = ((socket.hitW or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
                local half_h = ((socket.hitH or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
                local inside = world_x >= (sx - half_w)
                    and world_x <= (sx + half_w)
                    and world_y >= (sy - half_h)
                    and world_y <= (sy + half_h)
                if inside then
                    local dx = sx - world_x
                    local dy = sy - world_y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < best_dist then
                        best_dist = dist
                        best_cell = cell
                        best_obj = socket
                    end
                end
            end
        end
        return best_cell, best_obj
    end

    runtime.refresh_exit_objective_state = function(self)
        self.exit_objective_state = self.exit_objective_state or {}
        local state = self.exit_objective_state
        state.seated_humans = 0
        state.power_loaded = 0
        state.nav_ready = false
        state.supplies_ready = false
        state.exit_tile_powered = false
        if self.squad_units then
            for _, unit in pairs(self.squad_units) do
                if unit and unit.in_shuttle == true and (unit.current_health or 0) > 0 then
                    state.seated_humans = state.seated_humans + 1
                end
            end
        end
        if self.world_grid then
            for _, cell in ipairs(self.world_grid) do
                local socket = runtime.get_escape_pod_power_socket_object and runtime.get_escape_pod_power_socket_object(cell) or nil
                if socket then
                    state.power_loaded = state.power_loaded + math.max(0, socket.powerLoaded or 0)
                    if cell.isPowered == true then
                        state.exit_tile_powered = true
                    end
                end
                local nav = runtime.get_nav_computer_object and runtime.get_nav_computer_object(cell) or nil
                if nav then
                    local nav_has_data = (nav.hasNavData == true) or (nav.hasNavData == nil and nav.isFixed == true)
                    nav.hasNavData = nav_has_data
                    nav.isFixed = nav_has_data
                    local contributes_to_exit = (nav.contributesToExitObjective ~= false)
                    local nav_dependency_met = runtime.is_object_dependency_met(self.world_grid, nav)
                    if contributes_to_exit and nav_has_data and nav_dependency_met then
                        state.nav_ready = true
                        if cell.isPowered == true then
                            state.exit_tile_powered = true
                        end
                    end
                end
                local loader = runtime.get_supply_loader_object and runtime.get_supply_loader_object(cell) or nil
                if loader then
                    local loader_has_food = (loader.hasFood == true) or (loader.hasFood == nil and loader.isFixed == true)
                    loader.hasFood = loader_has_food
                    loader.isFixed = loader_has_food
                    local contributes_to_exit = (loader.contributesToExitObjective ~= false)
                    local loader_dependency_met = runtime.is_object_dependency_met(self.world_grid, loader)
                    if contributes_to_exit and loader_has_food and loader_dependency_met then
                        state.supplies_ready = true
                        if cell.isPowered == true then
                            state.exit_tile_powered = true
                        end
                    end
                end
            end
        end
        return state
    end

    runtime.get_launch_status = function(self)
        local state = runtime.refresh_exit_objective_state(self)
        return {
            can_launch = state.seated_humans >= 1
                and state.power_loaded >= 9
                and state.nav_ready == true
                and state.supplies_ready == true
                and state.exit_tile_powered == true,
            seated_humans = state.seated_humans,
            power_loaded = state.power_loaded,
            nav_ready = state.nav_ready,
            supplies_ready = state.supplies_ready,
            exit_tile_powered = state.exit_tile_powered
        }
    end

    runtime.try_launch_escape_pod = function(self)
        local status = runtime.get_launch_status(self)
        if not status.can_launch then
            print(string.format(
                "Launch blocked | seated=%d (need >=1) power=%d/9 nav=%s supplies=%s",
                status.seated_humans,
                status.power_loaded,
                status.nav_ready and "ready" or "missing",
                status.supplies_ready and "ready" or "missing"
            ))
            if status.exit_tile_powered ~= true then
                print("Launch blocked | exit tile power is OFF.")
            end
            return false
        end
        self.game_won = true
        self.launch_fx_timer = 1.2
        print("LAUNCH SUCCESS | Escape pod departed.")
        return true
    end

    runtime.update_exit_boarding = function(self)
        if not self.squad_units or not self.world_grid then
            return
        end
        local boarded_any = false
        local seated_alive_count = 0
        for _, unit in pairs(self.squad_units) do
            if unit and unit.in_shuttle == true and (unit.current_health or 0) > 0 then
                seated_alive_count = seated_alive_count + 1
            end
        end
        for _, unit in pairs(self.squad_units) do
            if unit
                and (unit.current_health or 0) > 0
                and unit.in_shuttle ~= true
                and unit.cell_id
                and seated_alive_count < 4
            then
                local cell = self.world_grid[unit.cell_id]
                local seat_obj = runtime.get_escape_pod_seat_object and runtime.get_escape_pod_seat_object(cell) or nil
                if seat_obj then
                    local old_cell = unit.cell_id
                    if self.cell_slot_assignments and self.cell_slot_assignments[old_cell] then
                        self.cell_slot_assignments[old_cell][unit.id] = nil
                    end
                    unit.in_shuttle = true
                    unit.is_selected = false
                    unit.is_moving = false
                    unit.move_path = nil
                    unit.move_path_index = 0
                    unit.cell_id = nil
                    if unit.go_path then
                        go.set_position(SHUTTLE_HIDE_POS, unit.go_path)
                    end
                    if unit.shadow_path then
                        go.set_position(SHUTTLE_HIDE_POS, unit.shadow_path)
                    end
                    if self.controlled_unit_id == unit.id then
                        self.controlled_unit_id = nil
                    end
                    seated_alive_count = seated_alive_count + 1
                    boarded_any = true
                    print(string.format("%s entered the escape pod.", unit.display_name))
                end
            end
        end
        if boarded_any and self.squad_units then
            if not self.controlled_unit_id then
                for _, scan in pairs(self.squad_units) do
                    if scan and (scan.current_health or 0) > 0 and scan.in_shuttle ~= true then
                        self.controlled_unit_id = scan.id
                        scan.is_selected = true
                        break
                    end
                end
            end
            ctx.update_human_visual_state(self)
        end
        runtime.refresh_exit_objective_state(self)
    end

    runtime.try_scavenge_selected_unit_on_cell = function(self, unit, cell)
        if not unit or not unit.cell_id then
            return true
        end
        local crate_obj = cell and runtime.get_loot_crate_object(cell) or nil
        local has_loot_here = cell and runtime.cell_has_loot_available(cell)
        if not cell or not has_loot_here then
            print("No loot available here.")
            return true
        end
        if not cell.isPowered then
            print("Loot crate is hidden (tile has no power).")
            return true
        end
        if unit.current_ap < ctx.LOOT_UI.ap_cost then
            print("Unable to scavenge: no AP")
            return true
        end

        unit.current_ap = unit.current_ap - ctx.LOOT_UI.ap_cost

        local capacity = unit.backpack_slots or (ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS)
        unit.backpack_items = unit.backpack_items or {}
        local added = 0
        local dropped = 0

        local loot_results = {}
        local used_authored_loot = false
        if crate_obj and type(crate_obj.lootItems) == "table" and #crate_obj.lootItems > 0 then
            used_authored_loot = true
            for _, item_type in ipairs(crate_obj.lootItems) do
                table.insert(loot_results, item_type)
            end
        else
            local roll_count = math.random(4, 9)
            loot_results = {
                ctx.COMPONENT_UI.component_wiring_straight,
                ctx.COMPONENT_UI.component_plate,
                ctx.COMPONENT_UI.component_sensor,
                ctx.COMPONENT_UI.component_fuse,
                ctx.COMPONENT_UI.component_fuse
            }
            for _ = 2, roll_count do
                -- Temporary test weighting for combat loop:
                -- make ammo the most common pickup.
                local loot_roll = math.random(1, 12)
                local item_type = (loot_roll <= 7 and "ammo")
                    or (loot_roll <= 9 and "material")
                    or (loot_roll == 10 and "power")
                    or "meds"
                table.insert(loot_results, item_type)
            end
        end

        for _, item_type in ipairs(loot_results) do
            if #unit.backpack_items < capacity then
                table.insert(unit.backpack_items, item_type)
                unit.backpack_used = #unit.backpack_items
                runtime.spawn_loot_pickup_blip(self, unit.cell_id, #unit.backpack_items, item_type)
                added = added + 1
            else
                dropped = dropped + 1
            end
        end

        if crate_obj then
            crate_obj.name = hash("empty")
            crate_obj.isFixed = false
            crate_obj.isWelded = false
            crate_obj.isOpen = false
            crate_obj.dependsOn = 0
            crate_obj.isDependentOn = {}
            crate_obj.objectId = 0
            crate_obj.offsetX = 0
            crate_obj.offsetY = 0
            crate_obj.fxOffsetX = 0
            crate_obj.fxOffsetY = 0
            crate_obj.fxRotation = 0
            crate_obj.fxFactory = nil
            crate_obj.hitW = 32
            crate_obj.hitH = 32
            crate_obj.requiredComponent = nil
            crate_obj.lootItems = nil
        end
        cell.hasLoot = false
        runtime.clear_loot_marker(self, unit.cell_id)

        print(string.format(
            "%s scavenged loot: mode=%s rolled=%d added=%d dropped=%d (AP -%d)",
            unit.display_name,
            used_authored_loot and "authored" or "random",
            #loot_results,
            added,
            dropped,
            ctx.LOOT_UI.ap_cost
        ))
        ctx.update_human_visual_state(self)
        return true
    end

    runtime.try_scavenge_selected_unit = function(self, screen_x, screen_y)
        -- Deprecated button path: scavenging is now driven by direct crate clicks.
        return false
    end

    runtime.try_use_component_vending = function(self, screen_x, screen_y)
        -- Deprecated button path: vending is now driven by direct drag-to-machine interactions.
        return false
    end

    runtime.try_fix_selected_unit = function(self, screen_x, screen_y)
        if not runtime.is_point_in_fix_button(screen_x, screen_y) then
            return false
        end

        local unit = ctx.get_selected_unit(self)
        if not unit or not unit.cell_id then
            return true
        end

        if unit.class_id ~= ctx.UNIT_CLASS_TECHIE then
            print("Only the Techie can fix objects.")
            return true
        end

        local cell = self.world_grid and self.world_grid[unit.cell_id]
        if not cell then
            print("No cell selected for fixing.")
            return true
        end
        if not cell.isPowered then
            print("Cannot fix here: tile has no power.")
            return true
        end

        local fixables = runtime.get_fixable_objects_in_cell(cell)
        local fixable = nil
        local required_component = nil
        local component_slot = nil
        local missing_required_component = nil
        unit.backpack_items = unit.backpack_items or {}
        for _, candidate in ipairs(fixables) do
            if candidate and candidate.isFixed ~= true then
                local needed = runtime.get_required_component_for_object(candidate)
                local slot = nil
                for i, item in ipairs(unit.backpack_items) do
                    if item == needed then
                        slot = i
                        break
                    end
                end
                if slot then
                    fixable = candidate
                    required_component = needed
                    component_slot = slot
                    break
                elseif not missing_required_component then
                    missing_required_component = needed
                end
            end
        end
        if not fixable then
            if missing_required_component then
                print("Need 1 " .. tostring(missing_required_component) .. " to fix.")
            else
                print("No fixable object here.")
            end
            return true
        end

        local dependency_id = fixable.dependsOn or 0
        local dependency_met_pre_fix = runtime.is_object_dependency_met(self.world_grid, fixable)

        if unit.current_ap < ctx.COMPONENT_UI.fix_ap_cost then
            print("Unable to fix: no AP")
            return true
        end

        if not component_slot then
            print("Need 1 " .. tostring(required_component) .. " to fix.")
            return true
        end

        table.remove(unit.backpack_items, component_slot)
        unit.backpack_used = #unit.backpack_items
        unit.current_ap = unit.current_ap - ctx.COMPONENT_UI.fix_ap_cost
        fixable.isFixed = true
        if dependency_id > 0 then
            if dependency_met_pre_fix then
                print(string.format(
                    "%s fixed object #%d. Dependency #%d already satisfied, object is now functional.",
                    unit.display_name,
                    fixable.objectId or 0,
                    dependency_id
                ))
            else
                print(string.format(
                    "%s fixed object #%d. Waiting for dependency #%d before functionality.",
                    unit.display_name,
                    fixable.objectId or 0,
                    dependency_id
                ))
            end
        else
            print(string.format("%s fixed object #%d and it is functional.", unit.display_name, fixable.objectId or 0))
        end

        local unlocked_functional_count = 0
        for _, scan_cell in ipairs(self.world_grid or {}) do
            local scan_objects = { scan_cell.object1, scan_cell.object2, scan_cell.object3 }
            for _, scan_obj in ipairs(scan_objects) do
                if scan_obj
                    and (scan_obj.dependsOn or 0) == (fixable.objectId or -1)
                    and scan_obj.isFixed == true
                    and runtime.is_object_dependency_met(self.world_grid, scan_obj) then
                    unlocked_functional_count = unlocked_functional_count + 1
                end
            end
        end
        if unlocked_functional_count > 0 then
            print(string.format(
                "Fixing object #%d enabled %d already-fixed dependent object(s) to become functional.",
                fixable.objectId or 0,
                unlocked_functional_count
            ))
        end
        -- FUTURE HOOK: trigger object-fix effects (fx/sound/gameplay event chain).
        runtime.refresh_fix_markers(self)
        runtime.refresh_machine_markers(self)
        runtime.refresh_turret_markers(self)
        runtime.refresh_door_markers(self)
        runtime.refresh_wiregap_markers(self)
        runtime.refresh_factory_underlay_visuals(self)
        ctx.update_human_visual_state(self)
        return true
    end

    runtime.try_retrieve_power_selected_unit_on_cell = function(self, unit, cell)
        if not unit or not unit.cell_id then
            return true
        end
        if not cell then
            print("No cell selected for power retrieval.")
            return true
        end
        if not cell.isPowered then
            print("No active power to retrieve here.")
            return true
        end

        local power_node = runtime.get_power_node_object(cell)
        if not power_node then
            print("No power node here.")
            return true
        end

        if unit.current_ap < (ctx.LOOT_UI.retrieve_ap_cost or 1) then
            print("Unable to retrieve power: no AP")
            return true
        end

        unit.backpack_items = unit.backpack_items or {}
        local capacity = unit.backpack_slots or (ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS)
        if #unit.backpack_items >= capacity then
            print("Backpack full. Cannot retrieve power.")
            return true
        end

        unit.current_ap = unit.current_ap - (ctx.LOOT_UI.retrieve_ap_cost or 1)
        table.insert(unit.backpack_items, "power")
        unit.backpack_used = #unit.backpack_items

        local target_tile_instance = cell.tileInstanceId or 0
        if target_tile_instance > 0 then
            for _, scan_cell in ipairs(self.world_grid) do
                if scan_cell.tileInstanceId == target_tile_instance then
                    scan_cell.isPowered = false
                    runtime.stop_power_node_fx_for_cell(self, scan_cell.idNumber)
                end
            end
        else
            cell.isPowered = false
            runtime.stop_power_node_fx_for_cell(self, cell.idNumber)
        end

        print(string.format("%s retrieved a power unit from the node. Tile is now unpowered.", unit.display_name))
        runtime.refresh_loot_markers(self)
        runtime.refresh_machine_markers(self)
        runtime.refresh_turret_markers(self)
        runtime.refresh_fix_markers(self)
        runtime.refresh_power_node_markers(self)
        runtime.refresh_door_markers(self)
        runtime.refresh_wiregap_markers(self)
        runtime.refresh_vent_markers(self)
        runtime.refresh_light_value_markers(self)
        runtime.refresh_factory_underlay_visuals(self)
        ctx.update_human_visual_state(self)
        return true
    end

    runtime.try_retrieve_power_selected_unit = function(self, screen_x, screen_y)
        -- Deprecated button path: retrieval is now driven by direct power-node clicks.
        return false
    end

    runtime.begin_command_drag = function(self, screen_x, screen_y)
        local unit = ctx.get_selected_unit(self)
        if not unit then
            return false
        end

        local pip_index = runtime.get_command_pip_index_at(unit, screen_x, screen_y)
        if not pip_index then
            return false
        end

        self.drag_resource = {
            active = true,
            drag_type = "command",
            source_unit_id = unit.id,
            source_slot_index = pip_index,
            item_type = "command",
            screen_x = screen_x,
            screen_y = screen_y
        }
        return true
    end

    runtime.begin_resource_drag = function(self, screen_x, screen_y)
        local unit = ctx.get_selected_unit(self)
        if not unit or not unit.backpack_items then
            return false
        end

        local slot_index = runtime.get_backpack_slot_index_at(screen_x, screen_y)
        if not slot_index then
            return false
        end

        local item_type = unit.backpack_items[slot_index]
        if not item_type then
            return false
        end

        self.drag_resource = {
            active = true,
            drag_type = "backpack",
            source_unit_id = unit.id,
            source_slot_index = slot_index,
            item_type = item_type,
            start_screen_x = screen_x,
            start_screen_y = screen_y,
            screen_x = screen_x,
            screen_y = screen_y
        }
        return true
    end

    runtime.update_resource_drag = function(self, screen_x, screen_y)
        if not self.drag_resource or not self.drag_resource.active then
            return
        end
        self.drag_resource.screen_x = screen_x
        self.drag_resource.screen_y = screen_y
    end

    runtime.try_apply_to_own_bar = function(unit, item_type, bar_target)
        if not unit or not bar_target then
            return false
        end
        if item_type ~= bar_target then
            return false
        end

        if bar_target == "ammo" then
            if unit.current_ammo >= unit.max_ammo then
                print("Ammo already full.")
                return false
            end
            unit.current_ammo = math.min(unit.max_ammo, unit.current_ammo + 5)
            return true
        end

        if bar_target == "meds" then
            if (unit.current_health or 0) <= 0 then
                print("Dead units cannot be healed with meds.")
                return false
            end
            if unit.current_health >= unit.max_health then
                print("Health already full.")
                return false
            end
            if unit.class_id == ctx.UNIT_CLASS_MEDIC then
                unit.current_health = unit.max_health
            else
                unit.current_health = math.min(unit.max_health, unit.current_health + 1)
            end
            return true
        end

        return false
    end

    runtime.find_human_drop_target = function(self, world_x, world_y, exclude_unit_id)
        if not self.squad_units then
            return nil
        end

        local best = nil
        local best_dist = math.huge
        for _, unit in pairs(self.squad_units) do
            if unit.id ~= exclude_unit_id and unit.go_path and (unit.current_health or 0) > 0 then
                local pos = go.get_position(unit.go_path)
                local dx = pos.x - world_x
                local dy = pos.y - world_y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < best_dist and dist <= ctx.LOOT_UI.human_drop_radius then
                    best = unit
                    best_dist = dist
                end
            end
        end
        return best
    end

    runtime.try_pickup_world_item_selected_unit = function(self, screen_x, screen_y)
        runtime.ensure_item_runtime_state(self)
        local unit = ctx.get_selected_unit(self)
        if not unit or not unit.cell_id then
            return false
        end
        local item, item_cell_id = runtime.find_world_item_at_screen_point(self, screen_x, screen_y)
        if not item then
            return false
        end
        if item_cell_id ~= unit.cell_id then
            return false
        end
        unit.backpack_items = unit.backpack_items or {}
        local cap = unit.backpack_slots or (ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS)
        if #unit.backpack_items >= cap then
            print("Backpack full.")
            flash_invalid_drag_units(unit, nil)
            return true
        end
        if not try_consume_drag_ap(unit, nil) then
            return true
        end
        if item.item_type == "corpse" then
            if #unit.backpack_items > 0 then
                print("Backpack must be emptied before carrying a corpse.")
                flash_invalid_drag_units(unit, nil)
                return true
            end
            for _ = 1, cap do
                table.insert(unit.backpack_items, "corpse")
            end
            unit.carrying_corpse_id = item.meta and item.meta.corpse_unit_id or nil
            local corpse_unit = get_dead_human_by_id(self, unit.carrying_corpse_id)
            if corpse_unit then
                corpse_unit.cell_id = nil
                corpse_unit.is_corpse_stowed = true
                if corpse_unit.go_path then
                    go.set_position(vmath.vector3(-9999, -9999, 0.5), corpse_unit.go_path)
                end
            end
        else
            table.insert(unit.backpack_items, item.item_type)
        end
        unit.backpack_used = #unit.backpack_items
        if item.meta and item.meta.installed_on_object_id then
            local obj = runtime.find_object_by_id(self.world_grid, item.meta.installed_on_object_id)
            if obj then
                obj.isFixed = false
            end
            runtime.refresh_fix_markers(self)
        end
        runtime.remove_world_item_instance(self, item.id)
        runtime.refresh_world_item_visuals(self)
        print(string.format("%s picked up 1 %s from world. (AP -%d)", unit.display_name, item.item_type, get_drag_ap_cost()))
        return true
    end

    runtime.try_pickup_world_turret_selected_unit = function(self, screen_x, screen_y, clicked_cell_id)
        local unit = ctx.get_selected_unit(self)
        if not unit or not unit.cell_id then
            return false
        end
        if clicked_cell_id and unit.cell_id ~= clicked_cell_id then
            -- Do not consume clicks on other cells; allow normal movement/selection flow.
            return false
        end
        local world_x, world_y = ctx.screen_to_world(screen_x, screen_y, self.camera_pos, self.camera_zoom)
        local human_click_priority_radius = ctx.UNIT_CLICK_SELECT_RADIUS or 45
        if clicked_cell_id and self.squad_units then
            local nearest_human_dist = math.huge
            for _, squad_unit in pairs(self.squad_units) do
                if squad_unit and squad_unit.cell_id == clicked_cell_id and (squad_unit.current_health or 0) > 0 and squad_unit.go_path then
                    local pos = go.get_position(squad_unit.go_path)
                    local dx = pos.x - world_x
                    local dy = pos.y - world_y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < nearest_human_dist then
                        nearest_human_dist = dist
                    end
                end
            end
            if nearest_human_dist <= human_click_priority_radius then
                -- Let main human selection flow handle this click first.
                return false
            end
        end
        local cell, turret_obj = find_turret_pickup_target(self, world_x, world_y, unit.cell_id)
        if not cell or not turret_obj then
            return false
        end
        if cell.idNumber ~= unit.cell_id then
            print("too far away")
            flash_invalid_drag_units(unit, nil)
            return true
        end
        unit.backpack_items = unit.backpack_items or {}
        local cap = unit.backpack_slots or (ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS)
        if #unit.backpack_items > 0 then
            print("Backpack must be emptied before carrying a turret.")
            runtime.emit_derple_feedback(self, unit.id, "TURRET_BACKPACK_NOT_EMPTY")
            flash_invalid_drag_units(unit, nil)
            return true
        end
        if not try_consume_drag_ap(unit, nil) then
            return true
        end
        -- Disable immediately on pickup action, then store as packed turret.
        turret_obj.name = hash("empty")
        turret_obj.isFixed = false
        turret_obj.isWelded = false
        turret_obj.isOpen = false
        turret_obj.dependsOn = 0
        turret_obj.isDependentOn = {}
        turret_obj.objectId = 0
        turret_obj.offsetX = 0
        turret_obj.offsetY = 0
        turret_obj.fxOffsetX = 0
        turret_obj.fxOffsetY = 0
        turret_obj.fxRotation = 0
        turret_obj.fxFactory = nil
        turret_obj.hitW = 32
        turret_obj.hitH = 32
        turret_obj.requiredComponent = nil
        turret_obj.turretArmingTurns = nil
        fill_backpack_with_packed_turret(unit, cap)
        runtime.refresh_turret_markers(self)
        runtime.refresh_fix_markers(self)
        runtime.refresh_world_item_visuals(self)
        print(string.format("%s packed a turret into backpack. (AP -%d)", unit.display_name, get_drag_ap_cost()))
        return true
    end

    runtime.try_pickup_obstacle_selected_unit = function(self, screen_x, screen_y, clicked_cell_id)
        local unit = ctx.get_selected_unit(self)
        if not unit or not unit.cell_id or not clicked_cell_id then
            return false
        end
        local world_x, world_y = ctx.screen_to_world(screen_x, screen_y, self.camera_pos, self.camera_zoom)
        local human_click_priority_radius = ctx.UNIT_CLICK_SELECT_RADIUS or 45
        if self.squad_units then
            local nearest_human_dist = math.huge
            for _, squad_unit in pairs(self.squad_units) do
                if squad_unit and squad_unit.cell_id == clicked_cell_id and (squad_unit.current_health or 0) > 0 and squad_unit.go_path then
                    local pos = go.get_position(squad_unit.go_path)
                    local dx = pos.x - world_x
                    local dy = pos.y - world_y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < nearest_human_dist then
                        nearest_human_dist = dist
                    end
                end
            end
            if nearest_human_dist <= human_click_priority_radius then
                -- Let main human selection flow handle this click first.
                return false
            end
        end
        local ux, uy = ctx.id_to_coords(unit.cell_id)
        local tx, ty = ctx.id_to_coords(clicked_cell_id)
        if ux ~= tx or uy ~= ty then
            print("too far away")
            flash_invalid_drag_units(unit, nil)
            return false
        end
        local cell = self.world_grid and self.world_grid[clicked_cell_id]
        if not cell or cell.tileID == hash("empty") then
            return false
        end
        if (cell.has_barricade == true) and ((cell.barricade_hp or 0) > 0) then
            -- Barricades are non-clickable; allow other click handlers (doors, selection, etc.).
            return false
        end
        local obstacle_slot = find_clicked_obstacle_slot(cell, world_x, world_y)
        if not obstacle_slot then
            obstacle_slot = find_any_obstacle_slot(cell)
            if not obstacle_slot then
                return false
            end
        end

        unit.backpack_items = unit.backpack_items or {}
        local cap = unit.backpack_slots or (ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS)
        if #unit.backpack_items >= cap then
            print("Backpack full.")
            flash_invalid_drag_units(unit, nil)
            return true
        end
        if not try_consume_drag_ap(unit, nil) then
            return true
        end

        local current_count = get_obstacle_count(obstacle_slot)
        if current_count <= 1 then
            reset_object_slot_to_empty(obstacle_slot)
        else
            set_obstacle_count(obstacle_slot, current_count - 1)
        end
        table.insert(unit.backpack_items, OBSTACLE_ITEM)
        unit.backpack_used = #unit.backpack_items
        runtime.refresh_fix_markers(self)
        runtime.refresh_world_item_visuals(self)
        print(string.format("%s retrieved 1 obstacle. (AP -%d)", unit.display_name, get_drag_ap_cost()))
        return true
    end

    local function is_point_in_object_hitbox(cell, obj, world_x, world_y)
        if not cell or not obj then
            return false
        end
        local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
        local x = cx + (obj.offsetX or 0)
        local y = cy + (obj.offsetY or 0)
        local half_w = ((obj.hitW or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
        local half_h = ((obj.hitH or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
        return world_x >= (x - half_w)
            and world_x <= (x + half_w)
            and world_y >= (y - half_h)
            and world_y <= (y + half_h)
    end

    runtime.try_interact_nav_computer_selected_unit_on_cell = function(self, unit, cell, nav_obj)
        if not unit or not cell or not nav_obj then
            return false
        end
        unit.backpack_items = unit.backpack_items or {}
        local cap = unit.backpack_slots or (ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS)
        if not runtime.is_object_dependency_met(self.world_grid, nav_obj) then
            print("Nav computer dependency is not met.")
            flash_invalid_drag_units(unit, nil)
            return true
        end
        local machine_has_nav = (nav_obj.hasNavData == true) or (nav_obj.hasNavData == nil and nav_obj.isFixed == true)
        nav_obj.hasNavData = machine_has_nav
        nav_obj.isFixed = machine_has_nav

        if machine_has_nav then
            if #unit.backpack_items >= cap then
                print("Backpack full.")
                flash_invalid_drag_units(unit, nil)
                return true
            end
            table.insert(unit.backpack_items, ctx.COMPONENT_UI.component_nav_data)
            unit.backpack_used = #unit.backpack_items
            nav_obj.hasNavData = false
            nav_obj.isFixed = false
            runtime.refresh_exit_objective_state(self)
            runtime.refresh_fix_markers(self)
            runtime.refresh_world_item_visuals(self)
            print(string.format("%s retrieved nav-data from machine.", unit.display_name))
            return true
        end

        local nav_slot = get_backpack_item_slot(unit, ctx.COMPONENT_UI.component_nav_data)
        if not nav_slot then
            print("Need 1 nav-data in backpack.")
            flash_invalid_drag_units(unit, nil)
            return true
        end

        table.remove(unit.backpack_items, nav_slot)
        unit.backpack_used = #unit.backpack_items
        nav_obj.hasNavData = true
        nav_obj.isFixed = true
        runtime.refresh_exit_objective_state(self)
        runtime.refresh_fix_markers(self)
        runtime.refresh_world_item_visuals(self)
        print(string.format("%s inserted nav-data into machine.", unit.display_name))
        return true
    end

    runtime.try_interact_supply_loader_selected_unit_on_cell = function(self, unit, cell, loader_obj)
        if not unit or not cell or not loader_obj then
            return false
        end
        unit.backpack_items = unit.backpack_items or {}
        local cap = unit.backpack_slots or (ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS)
        if not runtime.is_object_dependency_met(self.world_grid, loader_obj) then
            print("Supply loader dependency is not met.")
            flash_invalid_drag_units(unit, nil)
            return true
        end
        local machine_has_food = (loader_obj.hasFood == true) or (loader_obj.hasFood == nil and loader_obj.isFixed == true)
        loader_obj.hasFood = machine_has_food
        loader_obj.isFixed = machine_has_food

        if machine_has_food then
            if #unit.backpack_items >= cap then
                print("Backpack full.")
                flash_invalid_drag_units(unit, nil)
                return true
            end
            table.insert(unit.backpack_items, ctx.COMPONENT_UI.component_food_supplies)
            unit.backpack_used = #unit.backpack_items
            loader_obj.hasFood = false
            loader_obj.isFixed = false
            runtime.refresh_exit_objective_state(self)
            runtime.refresh_fix_markers(self)
            runtime.refresh_world_item_visuals(self)
            print(string.format("%s retrieved food supplies from machine.", unit.display_name))
            return true
        end

        local food_slot = get_backpack_item_slot(unit, ctx.COMPONENT_UI.component_food_supplies)
        if not food_slot then
            print("Need 1 food supplies in backpack.")
            flash_invalid_drag_units(unit, nil)
            return true
        end

        table.remove(unit.backpack_items, food_slot)
        unit.backpack_used = #unit.backpack_items
        loader_obj.hasFood = true
        loader_obj.isFixed = true
        runtime.refresh_exit_objective_state(self)
        runtime.refresh_fix_markers(self)
        runtime.refresh_world_item_visuals(self)
        print(string.format("%s inserted food supplies into machine.", unit.display_name))
        return true
    end

    runtime.get_clicked_interactive_object = function(self, world_x, world_y, clicked_cell_id)
        if not self.world_grid or not clicked_cell_id then
            return nil, nil, nil
        end
        local cell = self.world_grid[clicked_cell_id]
        if not cell then
            return nil, nil, nil
        end
        local crate = runtime.get_loot_crate_object(cell)
        if crate and is_point_in_object_hitbox(cell, crate, world_x, world_y) then
            return "crate", cell, crate
        end
        local power_node = runtime.get_power_node_object(cell)
        if power_node and is_point_in_object_hitbox(cell, power_node, world_x, world_y) then
            return "power_node", cell, power_node
        end
        local nav_computer = runtime.get_nav_computer_object(cell)
        if nav_computer and is_point_in_object_hitbox(cell, nav_computer, world_x, world_y) then
            return "nav_computer", cell, nav_computer
        end
        local supply_loader = runtime.get_supply_loader_object(cell)
        if supply_loader and is_point_in_object_hitbox(cell, supply_loader, world_x, world_y) then
            return "supply_loader", cell, supply_loader
        end
        local workshop_menu = runtime.get_workshop_menu_object and runtime.get_workshop_menu_object(cell) or nil
        if workshop_menu and is_point_in_object_hitbox(cell, workshop_menu, world_x, world_y) then
            return "workshop_menu", cell, workshop_menu
        end
        return nil, nil, nil
    end

    runtime.try_interact_workshop_menu_selected_unit_on_cell = function(self, unit, cell, workshop_menu_obj, world_x, world_y)
        if not unit or not cell or not workshop_menu_obj or not cell.tileInstanceId then
            return false
        end
        if unit.cell_id ~= cell.idNumber then
            print("too far away")
            flash_invalid_drag_units(unit, nil)
            return true
        end
        local instances = get_workshop_instances(self)
        local instance = instances[cell.tileInstanceId]
        if not instance then
            return true
        end
        if not instance.functional then
            print("Workshop is offline or not yet repaired.")
            return true
        end
        local slot_idx = get_workshop_menu_slot_by_world_point(cell, workshop_menu_obj, world_x, world_y)
        if not slot_idx then
            return true
        end
        if slot_idx == 9 then
            return true
        end
        local product = get_workshop_product_for_slot(slot_idx)
        if not product then
            return true
        end
        local state = get_workshop_state(self, cell.tileInstanceId)
        if (state.production_time_left or 0) > 0 then
            print("Workshop is currently producing. Wait for output.")
            return true
        end
        state.selected_slot = slot_idx
        state.paid_units = 0
        state.payment_locked = false
        print(string.format("Workshop selection: %s (%d material).", product.label, product.price))
        return true
    end

    runtime.handle_world_click_selected_unit = function(self, screen_x, screen_y, clicked_cell_id)
        local unit = ctx.get_selected_unit(self)
        if not unit or not unit.cell_id then
            return false
        end
        local world_x, world_y = ctx.screen_to_world(screen_x, screen_y, self.camera_pos, self.camera_zoom)
        local object_kind, clicked_cell, clicked_obj = runtime.get_clicked_interactive_object(self, world_x, world_y, clicked_cell_id)
        if object_kind then
            if clicked_cell.isPowered ~= true or clicked_cell_id ~= unit.cell_id then
                return false
            end
            if object_kind == "crate" then
                return runtime.try_scavenge_selected_unit_on_cell(self, unit, clicked_cell)
            end
            if object_kind == "power_node" then
                return runtime.try_retrieve_power_selected_unit_on_cell(self, unit, clicked_cell)
            end
            if object_kind == "nav_computer" then
                local nav_obj = runtime.get_nav_computer_object(clicked_cell)
                if nav_obj then
                    return runtime.try_interact_nav_computer_selected_unit_on_cell(self, unit, clicked_cell, nav_obj)
                end
            end
            if object_kind == "supply_loader" then
                local loader_obj = runtime.get_supply_loader_object(clicked_cell)
                if loader_obj then
                    return runtime.try_interact_supply_loader_selected_unit_on_cell(self, unit, clicked_cell, loader_obj)
                end
            end
            if object_kind == "workshop_menu" then
                return runtime.try_interact_workshop_menu_selected_unit_on_cell(self, unit, clicked_cell, clicked_obj, world_x, world_y)
            end
            return true
        end
        -- Deterministic click order for crowded cells:
        -- 1) corpse interaction, 2) deployed turret pickup, 3) deployed world item pickup.
        if runtime.try_store_dead_human_corpse_selected_unit(self, screen_x, screen_y) then
            return true
        end
        if runtime.try_pickup_world_turret_selected_unit(self, screen_x, screen_y, clicked_cell_id) then
            return true
        end
        if runtime.try_pickup_obstacle_selected_unit(self, screen_x, screen_y, clicked_cell_id) then
            return true
        end
        if runtime.try_pickup_world_item_selected_unit(self, screen_x, screen_y) then
            return true
        end
        return false
    end

    runtime.end_resource_drag = function(self, screen_x, screen_y)
        runtime.ensure_item_runtime_state(self)
        local drag = self.drag_resource
        if not drag or not drag.active then
            return false
        end

        local source_unit = self.squad_units and self.squad_units[drag.source_unit_id]
        if not source_unit or not source_unit.backpack_items then
            self.drag_resource = { active = false }
            return true
        end

        local source_item = source_unit.backpack_items[drag.source_slot_index]
        if drag.drag_type ~= "command" and not source_item then
            self.drag_resource = { active = false }
            return true
        end
        if drag.drag_type ~= "command" and source_item == TURRET_PACKED_ITEM then
            local start_x = drag.start_screen_x or drag.screen_x or screen_x
            local start_y = drag.start_screen_y or drag.screen_y or screen_y
            local drag_dx = (screen_x or start_x) - start_x
            local drag_dy = (screen_y or start_y) - start_y
            local drag_dist = math.sqrt((drag_dx * drag_dx) + (drag_dy * drag_dy))
            if drag_dist < 12 then
                -- Packed turret requires an intentional drag; simple click should not deploy/drop it.
                self.drag_resource = { active = false }
                return true
            end
        end

        local consumed = false
        local suppress_generic_world_drop = false
        if drag.drag_type == "command" then
            local world_x, world_y = ctx.screen_to_world(screen_x, screen_y, self.camera_pos, self.camera_zoom)
            local target_unit = runtime.find_human_drop_target(self, world_x, world_y, source_unit.id)
            if target_unit then
                if runtime.can_transfer_between_units(self, source_unit, target_unit) then
                    if (source_unit.command_points or 0) > 0 then
                        source_unit.command_points = source_unit.command_points - 1
                        target_unit.current_ap = target_unit.current_ap + 1 -- intentionally uncapped by design
                        trigger_receive_pulse(target_unit)
                        consumed = true
                        print(string.format("%s granted +1 AP to %s.", source_unit.display_name, target_unit.display_name))
                    else
                        print("No command points available.")
                        flash_invalid_drag_units(source_unit, target_unit)
                    end
                else
                    print("too far away")
                    flash_invalid_drag_units(source_unit, target_unit)
                end
            end
        else
            local bar_target = runtime.get_bar_drop_target(screen_x, screen_y)
            if bar_target then
                consumed = runtime.try_apply_to_own_bar(source_unit, source_item, bar_target)
                if consumed then
                    if not try_consume_drag_ap(source_unit, nil) then
                        consumed = false
                        self.drag_resource = { active = false }
                        return true
                    end
                    table.remove(source_unit.backpack_items, drag.source_slot_index)
                    source_unit.backpack_used = #source_unit.backpack_items
                    print(string.format(
                        "%s used 1 %s on own %s bar. (AP -%d)",
                        source_unit.display_name,
                        source_item,
                        bar_target,
                        get_drag_ap_cost()
                    ))
                end
            else
                local world_x, world_y = ctx.screen_to_world(screen_x, screen_y, self.camera_pos, self.camera_zoom)
                local drop_cell_id = runtime.find_cell_id_at_world_point(self, world_x, world_y)
                local vending_attempted = false
                local force_barricade_drop = false
                if is_obstacle_backpack_item(source_item) and drop_cell_id then
                    -- Prioritize reinforcing the selected unit's own barricade even near cell borders.
                    -- This prevents side-slot barricade drops from resolving to a neighboring cell.
                    local source_cell = self.world_grid and self.world_grid[source_unit.cell_id]
                    if source_cell and is_point_in_barricade_hitbox(source_cell, world_x, world_y) then
                        force_barricade_drop = true
                        drop_cell_id = source_unit.cell_id
                    end
                    local drop_cell = self.world_grid and self.world_grid[drop_cell_id]
                    if drop_cell
                        and drop_cell.tileID ~= hash("empty")
                        and (drop_cell.has_barricade == true)
                        and ((drop_cell.barricade_hp or 0) > 0)
                    then
                        local bx, by = ctx.coords_to_world_pos(drop_cell.xCell, drop_cell.yCell)
                        local barricade_anchor_x, barricade_anchor_y = get_barricade_anchor_offset(drop_cell)
                        bx = bx + barricade_anchor_x
                        by = by + barricade_anchor_y
                        by = by + 7
                        local half_w = 62
                        local half_h = 50
                        if world_x >= (bx - half_w)
                            and world_x <= (bx + half_w)
                            and world_y >= (by - half_h)
                            and world_y <= (by + half_h)
                        then
                            force_barricade_drop = true
                        end
                    end
                end
                local target_unit = nil
                if not force_barricade_drop then
                    target_unit = runtime.find_human_drop_target(self, world_x, world_y, source_unit.id)
                end
                if source_item == TURRET_PACKED_ITEM then
                    -- Packed turret deployment is cell-targeted, not human-targeted.
                    target_unit = nil
                end
                if source_unit.class_id == ctx.UNIT_CLASS_MEDIC and source_item == "meds" then
                    -- Prioritize self-heal when the drop lands on/near the medic sprite.
                    -- This avoids nearby allies stealing the target in crowded cells.
                    local self_pos = source_unit.go_path and go.get_position(source_unit.go_path) or nil
                    local self_drop_radius = ctx.LOOT_UI.human_drop_radius or 48
                    if self_pos then
                        local sdx = self_pos.x - world_x
                        local sdy = self_pos.y - world_y
                        local self_dist = math.sqrt(sdx * sdx + sdy * sdy)
                        if self_dist <= self_drop_radius then
                            target_unit = source_unit
                        elseif not target_unit then
                            target_unit = source_unit
                        end
                    elseif not target_unit then
                        target_unit = source_unit
                    end
                end
                if target_unit then
                    if source_item == TURRET_PACKED_ITEM then
                        print("Packed turret cannot be handed to another unit. Drop on your current cell to deploy.")
                        flash_invalid_drag_units(source_unit, target_unit)
                    else
                    if runtime.can_transfer_between_units(self, source_unit, target_unit) then
                        if source_unit.class_id == ctx.UNIT_CLASS_MEDIC and source_item == "meds" then
                            if (target_unit.current_health or 0) <= 0 then
                                print(target_unit.display_name .. " is dead and cannot be healed with meds.")
                                flash_invalid_drag_units(source_unit, target_unit)
                            elseif target_unit.current_health >= target_unit.max_health then
                                print(target_unit.display_name .. " already has full HP.")
                                flash_invalid_drag_units(source_unit, target_unit)
                            else
                                if not try_consume_drag_ap(source_unit, target_unit) then
                                    self.drag_resource = { active = false }
                                    return true
                                end
                                table.remove(source_unit.backpack_items, drag.source_slot_index)
                                source_unit.backpack_used = #source_unit.backpack_items
                                target_unit.current_health = target_unit.max_health
                                trigger_receive_pulse(target_unit)
                                consumed = true
                                print(string.format(
                                    "%s used 1 meds on %s (full heal). (AP -%d)",
                                    source_unit.display_name,
                                    target_unit.display_name,
                                    get_drag_ap_cost()
                                ))
                                -- FUTURE HOOK: play heal particle effect on target_unit.
                            end
                        else
                            target_unit.backpack_items = target_unit.backpack_items or {}
                            local target_cap = target_unit.backpack_slots or (ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS)
                            if #target_unit.backpack_items < target_cap then
                                if not try_consume_drag_ap(source_unit, target_unit) then
                                    self.drag_resource = { active = false }
                                    return true
                                end
                                table.remove(source_unit.backpack_items, drag.source_slot_index)
                                source_unit.backpack_used = #source_unit.backpack_items
                                table.insert(target_unit.backpack_items, source_item)
                                target_unit.backpack_used = #target_unit.backpack_items
                                emit_receive_item_feedback(self, target_unit)
                                trigger_receive_pulse(target_unit)
                                consumed = true
                                print(string.format(
                                    "%s gave 1 %s to %s. (AP -%d)",
                                    source_unit.display_name,
                                    source_item,
                                    target_unit.display_name,
                                    get_drag_ap_cost()
                                ))
                            else
                                print(target_unit.display_name .. " backpack is full.")
                                flash_invalid_drag_units(source_unit, target_unit)
                            end
                        end
                    else
                        print("too far away")
                        flash_invalid_drag_units(source_unit, target_unit)
                    end
                    end
                else
                    if source_item == TURRET_PACKED_ITEM then
                        suppress_generic_world_drop = true
                    end
                    if source_item == "material" and drop_cell_id and source_unit.cell_id then
                        local drop_cell = self.world_grid and self.world_grid[drop_cell_id]
                        local workshop_menu = drop_cell and runtime.get_workshop_menu_object and runtime.get_workshop_menu_object(drop_cell) or nil
                        if workshop_menu then
                            local instances = get_workshop_instances(self)
                            local tile_instance_id = drop_cell.tileInstanceId or 0
                            local instance = instances[tile_instance_id]
                            local inside_menu_panel = is_point_in_object_hitbox(drop_cell, workshop_menu, world_x, world_y)
                            local pay_slot_idx = get_workshop_menu_slot_by_world_point(drop_cell, workshop_menu, world_x, world_y)
                            local is_pay_hotspot = (pay_slot_idx == 9)
                                or is_workshop_payment_hotspot(drop_cell, workshop_menu, world_x, world_y)
                                or inside_menu_panel
                            if is_pay_hotspot then
                                vending_attempted = true
                                local sx, sy = ctx.id_to_coords(source_unit.cell_id)
                                local tx, ty = ctx.id_to_coords(drop_cell_id)
                                local manhattan = math.abs(sx - tx) + math.abs(sy - ty)
                                if manhattan ~= 0 then
                                    print("too far away")
                                    flash_invalid_drag_units(source_unit, nil)
                                elseif not instance or instance.functional ~= true then
                                    print("Workshop is offline or not yet repaired.")
                                else
                                    local state = get_workshop_state(self, tile_instance_id)
                                    local selected = get_workshop_product_for_slot(state.selected_slot)
                                    if not selected then
                                        print("Select an item in the workshop menu first.")
                                        flash_invalid_drag_units(source_unit, nil)
                                    elseif (state.production_time_left or 0) > 0 then
                                        print("Workshop is currently producing. Wait for output.")
                                    elseif state.payment_locked == true then
                                        print("Workshop payment is locked. Select an item again to start a new order.")
                                    else
                                        if not try_consume_drag_ap(source_unit, nil) then
                                            self.drag_resource = { active = false }
                                            return true
                                        end
                                        table.remove(source_unit.backpack_items, drag.source_slot_index)
                                        source_unit.backpack_used = #source_unit.backpack_items
                                        state.paid_units = (state.paid_units or 0) + 1
                                        print(string.format(
                                            "%s paid 1 material to workshop: %d/%d.",
                                            source_unit.display_name,
                                            state.paid_units,
                                            selected.price
                                        ))
                                        if state.paid_units >= selected.price then
                                            state.payment_locked = true
                                            state.production_time_left = WORKSHOP_PRODUCTION_DURATION
                                            print(string.format("Workshop production started for %s.", selected.label))
                                        end
                                        consumed = true
                                    end
                                end
                            end
                        end
                        local vending_machine = drop_cell and runtime.get_vending_machine_on_cell(drop_cell) or nil
                        if vending_machine and not consumed then
                            local cx, cy = ctx.coords_to_world_pos(drop_cell.xCell, drop_cell.yCell)
                            local vx = cx + (vending_machine.offsetX or 0)
                            local vy = cy + (vending_machine.offsetY or 0)
                            local half_w = ((vending_machine.hitW or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
                            local half_h = ((vending_machine.hitH or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
                            local inside_machine = world_x >= (vx - half_w)
                                and world_x <= (vx + half_w)
                                and world_y >= (vy - half_h)
                                and world_y <= (vy + half_h)
                            if inside_machine then
                                vending_attempted = true
                                local sx, sy = ctx.id_to_coords(source_unit.cell_id)
                                local tx, ty = ctx.id_to_coords(drop_cell_id)
                                local manhattan = math.abs(sx - tx) + math.abs(sy - ty)
                                if manhattan ~= 0 then
                                    print("too far away")
                                    flash_invalid_drag_units(source_unit, nil)
                                elseif drop_cell.isPowered ~= true then
                                    print("Vending machine is offline (tile has no power).")
                                elseif vending_machine.isFixed ~= true then
                                    print("Vending machine is broken and must be fixed first.")
                                elseif not runtime.is_object_dependency_met(self.world_grid, vending_machine) then
                                    print("Vending machine dependency is not met.")
                                else
                                    if not try_consume_drag_ap(source_unit, nil) then
                                        self.drag_resource = { active = false }
                                        return true
                                    end
                                    table.remove(source_unit.backpack_items, drag.source_slot_index)
                                    source_unit.backpack_used = #source_unit.backpack_items
                                    local produced_item = ctx.COMPONENT_UI.item_type_blue
                                    local produced_label = "component"
                                    if vending_machine.name == hash("ammo_vending_machine") then
                                        produced_item = "ammo"
                                        produced_label = "ammo unit"
                                    elseif vending_machine.name == hash("med_vending_machine") then
                                        produced_item = "meds"
                                        produced_label = "med unit"
                                    end
                                    table.insert(source_unit.backpack_items, produced_item)
                                    source_unit.backpack_used = #source_unit.backpack_items
                                    runtime.spawn_loot_pickup_blip(
                                        self,
                                        source_unit.cell_id,
                                        #source_unit.backpack_items,
                                        produced_item,
                                        vx,
                                        vy + 18
                                    )
                                    consumed = true
                                    runtime.refresh_machine_markers(self)
                                    print(string.format(
                                        "%s used 1 material and produced 1 %s. (AP -%d)",
                                        source_unit.display_name,
                                        produced_label,
                                        get_drag_ap_cost()
                                    ))
                                end
                            end
                        end
                    end
                    local target_power_cell = runtime.find_power_node_drop_target(self, world_x, world_y)
                    local target_socket_cell, target_socket_obj = runtime.find_escape_pod_power_socket_drop_target(self, world_x, world_y)
                    if target_socket_cell and target_socket_obj and source_item == "power" then
                        if not source_unit.cell_id then
                            print("Unable to load escape-pod power: source unit has no cell.")
                            self.drag_resource = { active = false }
                            return true
                        end
                        local sx, sy = ctx.id_to_coords(source_unit.cell_id)
                        local tx, ty = target_socket_cell.xCell, target_socket_cell.yCell
                        local manhattan = math.abs(sx - tx) + math.abs(sy - ty)
                        if manhattan == 0 then
                            local required = math.max(1, target_socket_obj.powerRequired or 9)
                            local loaded = math.max(0, target_socket_obj.powerLoaded or 0)
                            if loaded >= required then
                                print("Escape pod power socket already full.")
                                flash_invalid_drag_units(source_unit, nil)
                            else
                                if not try_consume_drag_ap(source_unit, nil) then
                                    self.drag_resource = { active = false }
                                    return true
                                end
                                table.remove(source_unit.backpack_items, drag.source_slot_index)
                                source_unit.backpack_used = #source_unit.backpack_items
                                target_socket_obj.powerLoaded = math.min(required, loaded + 1)
                                consumed = true
                                runtime.refresh_power_node_markers(self)
                                runtime.refresh_exit_objective_state(self)
                                print(string.format(
                                    "%s loaded escape-pod power: %d/%d. (AP -%d)",
                                    source_unit.display_name,
                                    target_socket_obj.powerLoaded,
                                    required,
                                    get_drag_ap_cost()
                                ))
                            end
                        else
                            print("too far away")
                            flash_invalid_drag_units(source_unit, nil)
                        end
                    end
                    if target_power_cell and source_item == "power" then
                        if not source_unit.cell_id then
                            print("Unable to activate power node: source unit has no cell.")
                            self.drag_resource = { active = false }
                            return true
                        end
                        local sx, sy = ctx.id_to_coords(source_unit.cell_id)
                        local tx, ty = target_power_cell.xCell, target_power_cell.yCell
                        local manhattan = math.abs(sx - tx) + math.abs(sy - ty)
                        if manhattan == 0 then
                            if target_power_cell.isPowered then
                                print("Power node already active.")
                            else
                                if not try_consume_drag_ap(source_unit, nil) then
                                    self.drag_resource = { active = false }
                                    return true
                                end
                                table.remove(source_unit.backpack_items, drag.source_slot_index)
                                source_unit.backpack_used = #source_unit.backpack_items
                                consumed = true

                                local power_node = runtime.get_power_node_object(target_power_cell)
                                if power_node then
                                    power_node.isFixed = true
                                end

                                local target_tile_instance = target_power_cell.tileInstanceId or 0
                                if target_tile_instance > 0 then
                                    for _, cell in ipairs(self.world_grid) do
                                        if cell.tileInstanceId == target_tile_instance then
                                            cell.isPowered = true
                                        end
                                    end
                                end
                                print(string.format(
                                    "%s activated a power node. (AP -%d)",
                                    source_unit.display_name,
                                    get_drag_ap_cost()
                                ))
                                runtime.play_power_node_activation_sound(self, target_power_cell, power_node)
                                runtime.spawn_power_node_activation_fx(self, target_power_cell, power_node)
                                runtime.refresh_loot_markers(self)
                                runtime.refresh_machine_markers(self)
                                runtime.refresh_turret_markers(self)
                                runtime.refresh_fix_markers(self)
                                runtime.refresh_power_node_markers(self)
                                runtime.refresh_door_markers(self)
                                runtime.refresh_wiregap_markers(self)
                                runtime.refresh_vent_markers(self)
                                runtime.refresh_light_value_markers(self)
                                runtime.refresh_factory_underlay_visuals(self)
                            end
                        else
                            print("too far away")
                            flash_invalid_drag_units(source_unit, nil)
                        end
                    end
                    if not consumed then
                        if source_item == TURRET_PACKED_ITEM then
                            if drop_cell_id then
                                local drop_cell = self.world_grid and self.world_grid[drop_cell_id]
                                if not drop_cell or drop_cell.tileID == hash("empty") then
                                    print("Invalid turret deploy cell.")
                                    flash_invalid_drag_units(source_unit, nil)
                                else
                                    local turret_on_cell = get_turret_object_on_cell(drop_cell)
                                    if turret_on_cell then
                                        print("A turret is already deployed on this cell.")
                                        flash_invalid_drag_units(source_unit, nil)
                                    else
                                        local slot = get_empty_object_slot(drop_cell)
                                        if not slot then
                                            print("No object slot available on this cell for turret deploy.")
                                            flash_invalid_drag_units(source_unit, nil)
                                        else
                                            if not try_consume_drag_ap(source_unit, nil) then
                                                self.drag_resource = { active = false }
                                                return true
                                            end
                                            clear_packed_turret_from_backpack(source_unit)
                                            local replacing_spawn_marker = slot.name == hash("blip_spawn") or slot.name == hash("blip")
                                            if replacing_spawn_marker then
                                                -- Preserve spawn capability even if its marker slot is reused.
                                                drop_cell.blipSpawnEnabled = true
                                            end
                                            slot.name = hash("gun_turret")
                                            slot.isFixed = true
                                            slot.isWelded = false
                                            slot.isOpen = false
                                            slot.dependsOn = 0
                                            slot.isDependentOn = {}
                                            slot.objectId = allocate_runtime_object_id(self.world_grid)
                                            slot.offsetX = 0
                                            slot.offsetY = 0
                                            slot.fxOffsetX = 0
                                            slot.fxOffsetY = 0
                                            slot.fxRotation = 0
                                            slot.fxFactory = nil
                                            slot.hitW = 48
                                            slot.hitH = 48
                                            slot.requiredComponent = nil
                                            slot.turretArmingTurns = TURRET_ARMING_TURNS_ON_DEPLOY
                                            runtime.refresh_turret_markers(self)
                                            runtime.refresh_fix_markers(self)
                                            runtime.refresh_world_item_visuals(self)
                                            consumed = true
                                            print(string.format(
                                                "%s deployed a turret (arming %d turns). (AP -%d)",
                                                source_unit.display_name,
                                                TURRET_ARMING_TURNS_ON_DEPLOY,
                                                get_drag_ap_cost()
                                            ))
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if not consumed then
                        if is_obstacle_backpack_item(source_item) and drop_cell_id and source_unit.cell_id then
                            local sx, sy = ctx.id_to_coords(source_unit.cell_id)
                            local tx, ty = ctx.id_to_coords(drop_cell_id)
                            local manhattan = math.abs(sx - tx) + math.abs(sy - ty)
                            if manhattan == 0 then
                                local drop_cell = self.world_grid and self.world_grid[drop_cell_id]
                                if not drop_cell or drop_cell.tileID == hash("empty") then
                                    print("Invalid obstacle drop cell.")
                                    flash_invalid_drag_units(source_unit, nil)
                                else
                                    if (drop_cell.has_barricade == true) and ((drop_cell.barricade_hp or 0) > 0) then
                                        if not try_consume_drag_ap(source_unit, nil) then
                                            self.drag_resource = { active = false }
                                            return true
                                        end
                                        table.remove(source_unit.backpack_items, drag.source_slot_index)
                                        source_unit.backpack_used = #source_unit.backpack_items
                                        drop_cell.barricade_hp = math.min(10, (drop_cell.barricade_hp or 0) + 1)
                                        drop_cell.barricade_brightness = math.max(0.25, math.min(1.0, (drop_cell.barricade_brightness or 1.0) * 1.33))
                                        drop_cell.barricade_scale_pulse = 0.1
                                        drop_cell.barricade_scale_pulse_timer = 0.22
                                        consumed = true
                                        runtime.refresh_fix_markers(self)
                                        runtime.refresh_world_item_visuals(self)
                                        print(string.format(
                                            "%s reinforced barricade (hp %d/10). (AP -%d)",
                                            source_unit.display_name,
                                            drop_cell.barricade_hp,
                                            get_drag_ap_cost()
                                        ))
                                    else
                                        local target_slot = find_clicked_drop_slot(drop_cell, world_x, world_y)
                                        if not target_slot then
                                            print("No slot available for obstacle.")
                                            flash_invalid_drag_units(source_unit, nil)
                                        elseif target_slot.name ~= hash("empty") and target_slot.name ~= hash("obstacle") then
                                            print("Clicked obstacle slot is occupied by another object.")
                                            flash_invalid_drag_units(source_unit, nil)
                                        else
                                            local current_count = get_obstacle_count(target_slot)
                                            if current_count >= OBSTACLE_STACK_CAP then
                                                print(string.format("Obstacle stack cap reached (%d).", OBSTACLE_STACK_CAP))
                                                flash_invalid_drag_units(source_unit, nil)
                                            else
                                                if not try_consume_drag_ap(source_unit, nil) then
                                                    self.drag_resource = { active = false }
                                                    return true
                                                end
                                                table.remove(source_unit.backpack_items, drag.source_slot_index)
                                                source_unit.backpack_used = #source_unit.backpack_items
                                                local anchor_x, anchor_y = get_obstacle_slot_anchor_offset(drop_cell, target_slot)
                                                if target_slot.name ~= hash("obstacle") then
                                                    init_obstacle_slot(drop_cell, target_slot, self.world_grid, anchor_x, anchor_y)
                                                else
                                                    apply_obstacle_slot_floor_alignment(drop_cell, target_slot, anchor_x, anchor_y)
                                                end
                                                current_count = get_obstacle_count(target_slot)
                                                set_obstacle_count(target_slot, current_count + 1)
                                                local new_stack = get_obstacle_count(target_slot)
                                                if new_stack >= 3 then
                                                    local slots = { drop_cell.object1, drop_cell.object2, drop_cell.object3 }
                                                    local total_obstacles = 0
                                                    for _, slot in ipairs(slots) do
                                                        if slot and slot.name == hash("obstacle") then
                                                            total_obstacles = total_obstacles + get_obstacle_count(slot)
                                                            reset_object_slot_to_empty(slot)
                                                        end
                                                    end
                                                    drop_cell.has_barricade = true
                                                    drop_cell.barricade_hp = math.max(3, math.min(10, total_obstacles))
                                                    drop_cell.barricade_brightness = 1.0
                                                    drop_cell.barricade_scale_pulse = nil
                                                    drop_cell.barricade_scale_pulse_timer = nil
                                                    drop_cell.barricade_slot_index = get_cell_object_slot_index(drop_cell, target_slot) or 2
                                                    drop_cell.barricade_anchor_x = anchor_x or 0
                                                    drop_cell.barricade_anchor_y = anchor_y or 0
                                                    print(string.format(
                                                        "%s built a barricade (hp %d/10). (AP -%d)",
                                                        source_unit.display_name,
                                                        drop_cell.barricade_hp,
                                                        get_drag_ap_cost()
                                                    ))
                                                else
                                                    print(string.format(
                                                        "%s placed 1 obstacle (stack %d/%d). (AP -%d)",
                                                        source_unit.display_name,
                                                        new_stack,
                                                        OBSTACLE_STACK_CAP,
                                                        get_drag_ap_cost()
                                                    ))
                                                end
                                                consumed = true
                                                runtime.refresh_fix_markers(self)
                                                runtime.refresh_world_item_visuals(self)
                                            end
                                        end
                                    end
                                end
                            else
                                print("too far away")
                                flash_invalid_drag_units(source_unit, nil)
                            end
                        end
                    end
                    if not consumed then
                        local vent_target = nil
                        local component_target = nil
                        local is_component_item = source_item == ctx.COMPONENT_UI.item_type_blue
                            or source_item == ctx.COMPONENT_UI.component_wiring_straight
                            or source_item == ctx.COMPONENT_UI.component_wiring_corner
                            or source_item == ctx.COMPONENT_UI.component_plate
                            or source_item == ctx.COMPONENT_UI.component_fuse
                            or source_item == ctx.COMPONENT_UI.component_sensor
                            or source_item == ctx.COMPONENT_UI.component_nav_data
                            or source_item == ctx.COMPONENT_UI.component_food_supplies
                        if drop_cell_id and source_unit.cell_id and source_item == ctx.COMPONENT_UI.component_plate then
                            vent_target = runtime.find_vent_weld_drop_target(self, world_x, world_y, drop_cell_id)
                            if vent_target then
                                if source_unit.class_id ~= ctx.UNIT_CLASS_TECHIE then
                                    print("Only the Techie can fix objects.")
                                    flash_invalid_drag_units(source_unit, nil)
                                    self.drag_resource = { active = false }
                                    return true
                                end
                                local sx, sy = ctx.id_to_coords(source_unit.cell_id)
                                local tx, ty = ctx.id_to_coords(drop_cell_id)
                                local manhattan = math.abs(sx - tx) + math.abs(sy - ty)
                                if manhattan == 0 then
                                    if not try_consume_drag_ap(source_unit, nil) then
                                        self.drag_resource = { active = false }
                                        return true
                                    end
                                    table.remove(source_unit.backpack_items, drag.source_slot_index)
                                    source_unit.backpack_used = #source_unit.backpack_items
                                    vent_target.isWelded = true
                                    consumed = true
                                    runtime.refresh_fix_markers(self)
                                    runtime.refresh_door_markers(self)
                                    runtime.refresh_wiregap_markers(self)
                                    runtime.refresh_vent_markers(self)
                                    runtime.refresh_factory_underlay_visuals(self)
                                    runtime.refresh_world_item_visuals(self)
                                    local weld_cell = self.world_grid and self.world_grid[drop_cell_id] or nil
                                    print(string.format("WELD FX CALLSITE: triggering overlay on cell %d", drop_cell_id or 0))
                                    runtime.spawn_vent_weld_fx(self, weld_cell, vent_target)
                                    print(string.format(
                                        "%s welded vent object #%d using 1 %s. (AP -%d)",
                                        source_unit.display_name,
                                        vent_target.objectId or 0,
                                        source_item,
                                        get_drag_ap_cost()
                                    ))
                                else
                                    print("too far away")
                                    flash_invalid_drag_units(source_unit, nil)
                                end
                            end
                        end
                        if drop_cell_id and source_unit.cell_id and is_component_item and not consumed then
                            component_target = runtime.find_fix_object_drop_target(self, world_x, world_y, drop_cell_id, source_item)
                            if not component_target and source_item == ctx.COMPONENT_UI.component_sensor then
                                local drop_cell = self.world_grid and self.world_grid[drop_cell_id]
                                if drop_cell then
                                    local scan = { drop_cell.object1, drop_cell.object2, drop_cell.object3 }
                                    local best = nil
                                    local best_dist = math.huge
                                    for _, obj in ipairs(scan) do
                                        if obj and obj.name == hash("gun_turret") and obj.isFixed ~= true then
                                            local cx, cy = ctx.coords_to_world_pos(drop_cell.xCell, drop_cell.yCell)
                                            local ox = obj.offsetX or 0
                                            local oy = obj.offsetY or 0
                                            local half_w = ((obj.hitW or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
                                            local half_h = ((obj.hitH or ctx.COMPONENT_UI.object_default_hit_size) * 0.5)
                                            local x = cx + ox
                                            local y = cy + oy
                                            local inside = world_x >= (x - half_w)
                                                and world_x <= (x + half_w)
                                                and world_y >= (y - half_h)
                                                and world_y <= (y + half_h)
                                            if inside then
                                                local dx = x - world_x
                                                local dy = y - world_y
                                                local dist = math.sqrt(dx * dx + dy * dy)
                                                if dist < best_dist then
                                                    best = obj
                                                    best_dist = dist
                                                end
                                            end
                                        end
                                    end
                                    component_target = best
                                end
                            end
                            if component_target then
                                local is_class_agnostic_machine_target = component_target.name == hash("supply_loader")
                                    or component_target.name == hash("nav_computer")
                                if source_unit.class_id ~= ctx.UNIT_CLASS_TECHIE and not is_class_agnostic_machine_target then
                                    print("Only the Techie can fix objects.")
                                    flash_invalid_drag_units(source_unit, nil)
                                    self.drag_resource = { active = false }
                                    return true
                                end
                                if component_target.name == hash("nav_computer")
                                    and not runtime.is_object_dependency_met(self.world_grid, component_target) then
                                    print("Nav computer dependency is not met.")
                                    flash_invalid_drag_units(source_unit, nil)
                                    self.drag_resource = { active = false }
                                    return true
                                end
                                local sx, sy = ctx.id_to_coords(source_unit.cell_id)
                                local tx, ty = ctx.id_to_coords(drop_cell_id)
                                local manhattan = math.abs(sx - tx) + math.abs(sy - ty)
                                if manhattan == 0 then
                                    if not try_consume_drag_ap(source_unit, nil) then
                                        self.drag_resource = { active = false }
                                        return true
                                    end
                                    table.remove(source_unit.backpack_items, drag.source_slot_index)
                                    source_unit.backpack_used = #source_unit.backpack_items
                                    component_target.isFixed = true
                                    if component_target.name == hash("nav_computer")
                                        and source_item == ctx.COMPONENT_UI.component_nav_data then
                                        component_target.hasNavData = true
                                    end
                                    if component_target.name == hash("supply_loader")
                                        and source_item == ctx.COMPONENT_UI.component_food_supplies then
                                        component_target.hasFood = true
                                    end
                                    consumed = true
                                    runtime.refresh_fix_markers(self)
                                    runtime.refresh_machine_markers(self)
                                    runtime.refresh_door_markers(self)
                                    runtime.refresh_wiregap_markers(self)
                                    runtime.refresh_turret_markers(self)
                                    runtime.refresh_factory_underlay_visuals(self)
                                    runtime.refresh_exit_objective_state(self)
                                    runtime.refresh_world_item_visuals(self)
                                    print(string.format(
                                        "%s installed 1 %s on object #%d. (AP -%d)",
                                        source_unit.display_name,
                                        source_item,
                                        component_target.objectId or 0,
                                        get_drag_ap_cost()
                                    ))
                                else
                                    print("too far away")
                                    flash_invalid_drag_units(source_unit, nil)
                                end
                            end
                        end
                        if (not consumed) and (not suppress_generic_world_drop) and (not vending_attempted) and drop_cell_id and source_unit.cell_id then
                            local sx, sy = ctx.id_to_coords(source_unit.cell_id)
                            local tx, ty = ctx.id_to_coords(drop_cell_id)
                            local manhattan = math.abs(sx - tx) + math.abs(sy - ty)
                            if manhattan == 0 then
                                if not try_consume_drag_ap(source_unit, nil) then
                                    self.drag_resource = { active = false }
                                    return true
                                end
                                if source_item == "corpse" then
                                    source_unit.backpack_items = {}
                                    source_unit.backpack_used = 0
                                    local corpse_id = source_unit.carrying_corpse_id
                                    source_unit.carrying_corpse_id = nil
                                    local corpse_unit = get_dead_human_by_id(self, corpse_id)
                                    if corpse_unit then
                                        corpse_unit.cell_id = drop_cell_id
                                        corpse_unit.is_corpse_stowed = false
                                        local drop_cell = self.world_grid and self.world_grid[drop_cell_id]
                                        if drop_cell and corpse_unit.go_path then
                                            local wx, wy = ctx.coords_to_world_pos(drop_cell.xCell, drop_cell.yCell)
                                            local hy = (ctx.HUMAN_FLOOR_OFFSET_FROM_CELL_BOTTOM or 58)
                                            wy = wy - ((ctx.CELL_HEIGHT or 150) * 0.5) + hy
                                            go.set_position(vmath.vector3(wx + ((ctx.CELL_WIDTH or 250) * 0.25), wy, 0.5), corpse_unit.go_path)
                                        end
                                    else
                                        runtime.create_world_item_instance(self, "corpse", drop_cell_id, source_unit.id, { corpse_unit_id = corpse_id })
                                        runtime.refresh_world_item_visuals(self)
                                    end
                                    consumed = true
                                    print(string.format("%s dropped a corpse from backpack. (AP -%d)", source_unit.display_name, get_drag_ap_cost()))
                                else
                                    table.remove(source_unit.backpack_items, drag.source_slot_index)
                                    source_unit.backpack_used = #source_unit.backpack_items
                                    runtime.create_world_item_instance(self, source_item, drop_cell_id, source_unit.id, {})
                                    runtime.refresh_world_item_visuals(self)
                                    consumed = true
                                    print(string.format(
                                        "%s dropped 1 %s into world. (AP -%d)",
                                        source_unit.display_name,
                                        source_item,
                                        get_drag_ap_cost()
                                    ))
                                end
                            else
                                print("too far away")
                                flash_invalid_drag_units(source_unit, nil)
                            end
                        end
                    end
                end
            end
        end

        if not consumed then
            print("Resource returned to backpack slot.")
        end

        self.drag_resource = { active = false }
        return true
    end

    runtime.update_drag_visual = function(self)
        if not self.ui or not self.ui.drag_pip then
            return
        end

        local drag = self.drag_resource
        if not drag or not drag.active then
            if self.ui.drag_command_pip then
                ctx.set_ui_square_transform(self, self.ui.drag_command_pip, -9999, -9999, 0.9, vmath.vector4(0, 0, 0, 0), ctx.LOOT_UI.drag_pip_size, ctx.LOOT_UI.drag_pip_size)
            end
            ctx.set_ui_square_transform(self, self.ui.drag_pip, -9999, -9999, 0.9, vmath.vector4(0, 0, 0, 0), ctx.LOOT_UI.drag_pip_size, ctx.LOOT_UI.drag_pip_size)
            return
        end

        local sprite_url = msg.url(nil, self.ui.drag_pip, "sprite")
        local item_ui_scale = ((ctx.UI_BACKPACK_SLOT_SIZE or 58) * 0.021)
        local command_ui_scale = item_ui_scale * 0.75
        if drag.drag_type == "command" then
            if self.ui.drag_command_pip then
                ctx.set_ui_square_transform(self, self.ui.drag_command_pip, -9999, -9999, 0.9, vmath.vector4(0, 0, 0, 0), ctx.LOOT_UI.drag_pip_size, ctx.LOOT_UI.drag_pip_size)
            end
            msg.post(sprite_url, "play_animation", { id = hash("command_star") })
            go.set(sprite_url, "tint", ctx.COMMAND_UI.drag_color or vmath.vector4(1, 1, 1, 1))
        else
            if self.ui.drag_command_pip then
                ctx.set_ui_square_transform(self, self.ui.drag_command_pip, -9999, -9999, 0.9, vmath.vector4(0, 0, 0, 0), ctx.LOOT_UI.drag_pip_size, ctx.LOOT_UI.drag_pip_size)
            end
            local icon_anim = runtime.get_item_visual_animation and runtime.get_item_visual_animation(drag.item_type) or nil
            if icon_anim then
                msg.post(sprite_url, "play_animation", { id = icon_anim })
                go.set(sprite_url, "tint", vmath.vector4(1, 1, 1, 1))
            else
                go.set(sprite_url, "tint", runtime.get_backpack_item_color(drag.item_type))
            end
        end
        local final_scale = (drag.drag_type == "command") and command_ui_scale or item_ui_scale
        ctx.set_ui_square_transform(self, self.ui.drag_pip, drag.screen_x, drag.screen_y, 0.9, vmath.vector4(1, 1, 1, 1), final_scale, final_scale)
    end

    return runtime
end

return M
