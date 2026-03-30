local M = {}

function M.extend(runtime, ctx)
    local WELD_OVERLAY_OFFSET_X = -0.5
    local WELD_OVERLAY_OFFSET_Y = -0.5
    local WELD_OVERLAY_Z = 0.54
    local BARRICADE_HP_MAX = 10
    local BARRICADE_HP_BAR_ART_W = 197
    local BARRICADE_HP_FILL_ART_W = 197
    local BARRICADE_HP_BAR_BG_SCALE_X = 0.32
    local BARRICADE_HP_BAR_BG_SCALE_Y = 0.32
    local BARRICADE_HP_BAR_BG_FULL_W = BARRICADE_HP_BAR_ART_W * BARRICADE_HP_BAR_BG_SCALE_X
    local BARRICADE_HP_BAR_OFFSET_Y = -100
    local BARRICADE_HP_BAR_Z = 0.81
    local BARRICADE_HP_BAR_BG_ANIM = hash("healthBar_backdrop")
    local BARRICADE_HP_BAR_FILL_ANIM = hash("healthBar_fillAmount")
    local DOOR_HP_DEFAULT = 3
    local DOOR_HP_MAX = 3
    local HAZARD_FX_Y_OFFSET = -35
    local HAZARD_FX_Z = 0.69

    local function boardgame_shadows_enabled(self)
        return self and self.aesthetic_mode == "boardgame"
    end

    local function spawn_world_shadow(x, y, z, sx, sy, alpha)
        local shadow_id = factory.create("/ui_factory#ui_factory", vmath.vector3(x, y, z))
        if shadow_id then
            go.set_scale(vmath.vector3(sx, sy, 1), shadow_id)
            go.set(msg.url(nil, shadow_id, "sprite"), "tint", vmath.vector4(0, 0, 0, alpha or 0.32))
        end
        return shadow_id
    end

    runtime.clear_loot_marker = function(self, cell_id)
        local loot_objects = ctx.get_loot_objects()
        local marker = loot_objects[cell_id]
        if marker then
            go.delete(marker)
            loot_objects[cell_id] = nil
        end
        if self and self.loot_shadow_objects then
            local shadow = self.loot_shadow_objects[cell_id]
            if shadow then
                go.delete(shadow)
                self.loot_shadow_objects[cell_id] = nil
            end
        end
    end

    runtime.refresh_loot_markers = function(self)
        local loot_objects = ctx.get_loot_objects()
        self.loot_shadow_objects = self.loot_shadow_objects or {}
        for cell_id, marker in pairs(self.loot_shadow_objects) do
            if marker then
                go.delete(marker)
            end
            self.loot_shadow_objects[cell_id] = nil
        end
        for cell_id, marker in pairs(loot_objects) do
            if marker then
                go.delete(marker)
            end
            loot_objects[cell_id] = nil
        end

        if not self.world_grid then
            return
        end

        for cell_id, cell in ipairs(self.world_grid) do
            if runtime.cell_has_loot_available(cell) and cell.tileID ~= hash("empty") and cell.isPowered then
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local crate_obj = runtime.get_loot_crate_object(cell)
                local marker_x = x + ((crate_obj and crate_obj.offsetX) or cell.lootOffsetX or 0)
                local marker_y = y + ((crate_obj and crate_obj.offsetY) or cell.lootOffsetY or 0)
                if boardgame_shadows_enabled(self) then
                    self.loot_shadow_objects[cell_id] = spawn_world_shadow(marker_x + 5, marker_y - 7, 0.5, 0.6, 0.22, 0.34)
                end
                local marker_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(marker_x, marker_y, ctx.LOOT_UI.marker_z))
                if marker_id then
                    go.set_scale(vmath.vector3(ctx.LOOT_UI.marker_size, ctx.LOOT_UI.marker_size, 1), marker_id)
                    loot_objects[cell_id] = marker_id
                end
            end
        end
    end

    runtime.refresh_hazard_fx = function(self)
        self.hazard_fx_objects = self.hazard_fx_objects or {}
        for _, fx_entry in ipairs(self.hazard_fx_objects) do
            if fx_entry then
                if fx_entry.fire_id then
                    go.delete(fx_entry.fire_id)
                end
                if fx_entry.gas_id then
                    go.delete(fx_entry.gas_id)
                end
            end
        end
        self.hazard_fx_objects = {}

        if not self.world_grid then
            return
        end

        local function get_hazard_flags(cell)
            if not cell then
                return false, false
            end
            local fire = false
            local gas = false
            local t = cell.hazard_type or cell.hazardType or cell.hazard
            if type(t) == "string" then
                local hazard = string.lower(t)
                fire = (hazard == "fire") or (hazard == "fire_gas") or (hazard == "gas_fire")
                gas = (hazard == "gas") or (hazard == "fire_gas") or (hazard == "gas_fire") or (hazard == "poison")
            end
            fire = fire or cell.isFireHazard == true or cell.has_fire_hazard == true or cell.hasFireHazard == true
            gas = gas or cell.isGasHazard == true or cell.has_gas_hazard == true or cell.hasGasHazard == true
            return fire, gas
        end

        for cell_id, cell in ipairs(self.world_grid) do
            if cell and cell.tileID ~= hash("empty") then
                local has_fire, has_gas = get_hazard_flags(cell)
                if has_fire or has_gas then
                    local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                    local fx_y = y + HAZARD_FX_Y_OFFSET
                    local entry = {
                        cell_id = cell_id,
                        fire_id = nil,
                        gas_id = nil,
                        fire_active = false,
                        gas_active = false
                    }
                    if has_fire then
                        local fire_id = factory.create("/fire_fx_factory#fire_fx_factory", vmath.vector3(x, fx_y, HAZARD_FX_Z))
                        if fire_id then
                            entry.fire_id = fire_id
                        end
                    end
                    if has_gas then
                        local gas_id = factory.create("/gas_fx_factory#gas_fx_factory", vmath.vector3(x, fx_y, HAZARD_FX_Z))
                        if gas_id then
                            entry.gas_id = gas_id
                        end
                    end
                    if entry.fire_id or entry.gas_id then
                        table.insert(self.hazard_fx_objects, entry)
                    end
                end
            end
        end
        if runtime.update_hazard_fx_visibility then
            runtime.update_hazard_fx_visibility(self)
        end
    end

    runtime.update_hazard_fx_visibility = function(self)
        if not (self and self.world_grid and self.hazard_fx_objects) then
            return
        end
        local occupied_tile_instances = {}
        if self.squad_units then
            for _, unit in pairs(self.squad_units) do
                if unit and (unit.current_health or 0) > 0 and unit.cell_id and self.world_grid[unit.cell_id] then
                    local tile_id = tonumber(self.world_grid[unit.cell_id].tileInstanceId or 0) or 0
                    if tile_id > 0 then
                        occupied_tile_instances[tile_id] = true
                    end
                end
            end
        end
        for _, civilian in ipairs(self.civilians or {}) do
            if civilian and civilian.is_dead ~= true and (civilian.current_health or 0) > 0 and civilian.cell_id and self.world_grid[civilian.cell_id] then
                local tile_id = tonumber(self.world_grid[civilian.cell_id].tileInstanceId or 0) or 0
                if tile_id > 0 then
                    occupied_tile_instances[tile_id] = true
                end
            end
        end
        for _, entry in ipairs(self.hazard_fx_objects) do
            local cell = entry and entry.cell_id and self.world_grid[entry.cell_id] or nil
            local tile_instance_id = tonumber(cell and cell.tileInstanceId or 0) or 0
            local show_fx = cell and ((cell.isPowered == true) or (tile_instance_id > 0 and occupied_tile_instances[tile_instance_id] == true)) or false
            if entry.fire_id then
                if show_fx and entry.fire_active ~= true then
                    pcall(particlefx.play, msg.url(nil, entry.fire_id, "particlefx"))
                    entry.fire_active = true
                elseif (not show_fx) and entry.fire_active == true then
                    pcall(particlefx.stop, msg.url(nil, entry.fire_id, "particlefx"))
                    entry.fire_active = false
                end
            end
            if entry.gas_id then
                if show_fx and entry.gas_active ~= true then
                    pcall(particlefx.play, msg.url(nil, entry.gas_id, "particlefx"))
                    entry.gas_active = true
                elseif (not show_fx) and entry.gas_active == true then
                    pcall(particlefx.stop, msg.url(nil, entry.gas_id, "particlefx"))
                    entry.gas_active = false
                end
            end
        end
    end

    runtime.refresh_machine_markers = function(self)
        local machine_objects = ctx.get_machine_objects()
        self.machine_shadow_objects = self.machine_shadow_objects or {}
        for cell_id, marker in pairs(self.machine_shadow_objects) do
            if marker then
                go.delete(marker)
            end
            self.machine_shadow_objects[cell_id] = nil
        end
        for cell_id, marker in pairs(machine_objects) do
            if marker then
                go.delete(marker)
            end
            machine_objects[cell_id] = nil
        end

        if not self.world_grid then
            return
        end

        for cell_id, cell in ipairs(self.world_grid) do
            local machine = runtime.get_vending_machine_on_cell(cell)
            if machine and cell.tileID ~= hash("empty") and cell.isPowered then
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local mx = x + (machine.offsetX or 0)
                local my = y + (machine.offsetY or 0)
                if boardgame_shadows_enabled(self) then
                    self.machine_shadow_objects[cell_id] = spawn_world_shadow(mx + 5, my - 7, 0.5, 0.62, 0.24, 0.34)
                end
                local marker_id = factory.create("/tile_factory#tile_factory", vmath.vector3(mx, my, 0.62))
                if marker_id then
                    local anim = hash("wiregap_straight_off")
                    if machine.name == hash("ammo_vending_machine") then
                        local functional = (cell.isPowered == true)
                            and (machine.isFixed == true)
                            and runtime.is_object_dependency_met(self.world_grid, machine)
                        anim = functional and hash("ammo_vend_machine_on") or hash("ammo_vend_machine_off")
                        print(string.format(
                            "DEBUG: ammo machine cell=%d powered=%s fixed=%s dep=%s anim=%s",
                            cell_id,
                            tostring(cell.isPowered == true),
                            tostring(machine.isFixed == true),
                            tostring(runtime.is_object_dependency_met(self.world_grid, machine)),
                            functional and "ammo_vend_machine_on" or "ammo_vend_machine_off"
                        ))
                    elseif machine.name == hash("med_vending_machine") then
                        local functional = (cell.isPowered == true)
                            and (machine.isFixed == true)
                            and runtime.is_object_dependency_met(self.world_grid, machine)
                        anim = functional and hash("med_vend_machine_on") or hash("med_vend_machine_off")
                    elseif machine.name == hash("machine") then
                        anim = hash("wiregap_straight_on")
                    end
                    msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = anim })
                    go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                    machine_objects[cell_id] = marker_id
                end
            end
        end
    end

    runtime.refresh_turret_markers = function(self)
        local turret_tripod_objects = ctx.get_turret_tripod_objects(self)
        local turret_gun_objects = ctx.get_turret_gun_objects(self)
        self.turret_shadow_objects = self.turret_shadow_objects or {}
        for cell_id, marker in pairs(self.turret_shadow_objects) do
            if marker then
                go.delete(marker)
            end
            self.turret_shadow_objects[cell_id] = nil
        end
        for cell_id, marker in pairs(turret_tripod_objects) do
            if marker then
                go.delete(marker)
            end
            turret_tripod_objects[cell_id] = nil
        end
        for cell_id, marker in pairs(turret_gun_objects) do
            if marker then
                go.delete(marker)
            end
            turret_gun_objects[cell_id] = nil
        end

        if not self.world_grid then
            return
        end

        for cell_id, cell in ipairs(self.world_grid) do
            if cell.tileID ~= hash("empty") then
                local objects = { cell.object1, cell.object2, cell.object3 }
                for _, obj in ipairs(objects) do
                    if obj and obj.name == hash("gun_turret") then
                        local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                        local tx = x + (obj.offsetX or 0)
                        local ty = y + (obj.offsetY or 0)
                        local turret_tint = (cell.isPowered == true)
                            and vmath.vector4(1, 1, 1, 1)
                            or vmath.vector4(0.14, 0.14, 0.14, 1)
                        if boardgame_shadows_enabled(self) then
                            self.turret_shadow_objects[cell_id] = spawn_world_shadow(tx + 7, ty - 10, 0.5, 0.74, 0.3, 0.36)
                        end
                        local tripod_id = factory.create("/tile_factory#tile_factory", vmath.vector3(tx, ty, 0.56))
                        local gun_id = factory.create("/tile_factory#tile_factory", vmath.vector3(tx, ty, 0.561))
                        if tripod_id then
                            msg.post(msg.url(nil, tripod_id, "sprite"), "play_animation", { id = hash("gun_turret_tripod") })
                            go.set(msg.url(nil, tripod_id, "sprite"), "tint", turret_tint)
                            go.set_scale(vmath.vector3(1, 1, 1), tripod_id)
                            turret_tripod_objects[cell_id] = tripod_id
                        end
                        if gun_id then
                            msg.post(msg.url(nil, gun_id, "sprite"), "play_animation", { id = hash("gun_turret") })
                            go.set(msg.url(nil, gun_id, "sprite"), "tint", turret_tint)
                            go.set_scale(vmath.vector3(1, 1, 1), gun_id)
                            -- Rotation hook: update this z-angle when turret acquires/fires at target.
                            go.set_rotation(vmath.quat_rotation_z(0), gun_id)
                            turret_gun_objects[cell_id] = gun_id
                        end
                    end
                end
            end
        end
    end

    runtime.refresh_fix_markers = function(self)
        self.fix_objects = self.fix_objects or {}
        self.exit_requirement_markers = self.exit_requirement_markers or {}
        self.obstacle_debug_objects = self.obstacle_debug_objects or {}
        for cell_id, marker in pairs(self.fix_objects) do
            if marker then
                go.delete(marker)
            end
            self.fix_objects[cell_id] = nil
        end
        for i, marker in ipairs(self.obstacle_debug_objects) do
            if marker then
                go.delete(marker)
            end
            self.obstacle_debug_objects[i] = nil
        end
        for i, marker in ipairs(self.exit_requirement_markers) do
            if marker then
                go.delete(marker)
            end
            self.exit_requirement_markers[i] = nil
        end

        if not self.world_grid then
            return
        end

        for cell_id, cell in ipairs(self.world_grid) do
            local fixables = runtime.get_fixable_objects_in_cell(cell)
            if #fixables > 0 and cell.tileID ~= hash("empty") and cell.isPowered then
                local unresolved = false
                local blocked = false
                local has_dependency = false
                for _, obj in ipairs(fixables) do
                    if obj and (obj.dependsOn or 0) > 0 then
                        has_dependency = true
                    end
                    if obj and obj.isFixed ~= true then
                        unresolved = true
                    elseif obj and obj.isFixed == true and not runtime.is_object_dependency_met(self.world_grid, obj) then
                        blocked = true
                    end
                end
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local marker_id = factory.create("/ui_factory#ui_factory", vmath.vector3(x - 18, y + 12, 0.046))
                if marker_id then
                    local marker_size = has_dependency and ctx.COMPONENT_UI.fix_marker_dependency_size or ctx.COMPONENT_UI.fix_marker_size
                    go.set_scale(vmath.vector3(marker_size, marker_size, 1), marker_id)
                    local color = unresolved and ctx.COMPONENT_UI.fix_marker_color
                        or (blocked and ctx.COMPONENT_UI.fix_marker_blocked_color)
                        or ctx.COMPONENT_UI.fix_marker_fixed_color
                    go.set(msg.url(nil, marker_id, "sprite"), "tint", color)
                    self.fix_objects[cell_id] = marker_id
                end
            end
            if cell and cell.tileID ~= hash("empty") then
                local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local barricade_hp = cell.barricade_hp or 0
                if (cell.has_barricade == true) and barricade_hp > 0 then
                    local shudder_dx = 0
                    local barricade_brightness = math.max(0.25, math.min(1.0, cell.barricade_brightness or 1.0))
                    local barricade_scale = math.max(0.82, math.min(1.12, 0.975 + (cell.barricade_scale_pulse or 0)))
                    local barricade_anchor_x = cell.barricade_anchor_x
                    local barricade_anchor_y = cell.barricade_anchor_y
                    if barricade_anchor_x == nil or barricade_anchor_y == nil then
                        local slot_index = cell.barricade_slot_index or 2
                        if slot_index == 1 then
                            barricade_anchor_x = -70
                        elseif slot_index == 3 then
                            barricade_anchor_x = 70
                        else
                            barricade_anchor_x = 0
                        end
                        barricade_anchor_y = 0
                    end
                    if (cell.obstacleShudderTimer or 0) > 0 then
                        local phase = (cell.obstacleShudderPhase or 0)
                        shudder_dx = math.sin(phase) * 4.4
                    end
                    local marker_id = factory.create(
                        "/loot_marker_factory#loot_marker_factory",
                        vmath.vector3(cx + barricade_anchor_x + shudder_dx, cy + barricade_anchor_y + 7, 0.56)
                    )
                    if marker_id then
                        msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = hash("barricade") })
                        go.set_scale(vmath.vector3(barricade_scale * 0.75, barricade_scale, 1), marker_id)
                        go.set(msg.url(nil, marker_id, "sprite"), "tint", vmath.vector4(barricade_brightness, barricade_brightness, barricade_brightness, 1))
                        table.insert(self.obstacle_debug_objects, marker_id)
                    end
                    local hp_ratio = math.max(0, math.min(1, barricade_hp / BARRICADE_HP_MAX))
                    local hp_bar_x = cx + barricade_anchor_x + shudder_dx
                    local hp_bar_y = cy + barricade_anchor_y + BARRICADE_HP_BAR_OFFSET_Y
                    local bar_left = hp_bar_x - (BARRICADE_HP_BAR_BG_FULL_W * 0.5)
                    local bg_id = factory.create("/tile_factory#tile_factory", vmath.vector3(hp_bar_x, hp_bar_y, BARRICADE_HP_BAR_Z))
                    if bg_id then
                        msg.post(msg.url(nil, bg_id, "sprite"), "play_animation", { id = BARRICADE_HP_BAR_BG_ANIM })
                        pcall(go.set, msg.url(nil, bg_id, "sprite"), "blend_mode", hash("alpha"))
                        go.set_scale(vmath.vector3(BARRICADE_HP_BAR_BG_SCALE_X, BARRICADE_HP_BAR_BG_SCALE_Y, 1), bg_id)
                        go.set(msg.url(nil, bg_id, "sprite"), "tint", vmath.vector4(1, 1, 1, 1))
                        table.insert(self.obstacle_debug_objects, bg_id)
                    end
                    if hp_ratio > 0 then
                        local hp_count = math.max(0, math.min(BARRICADE_HP_MAX, barricade_hp or 0))
                        -- Left-anchored fill growth: 0.1 width step per HP from the bar's left edge.
                        local fill_scale_x = BARRICADE_HP_BAR_BG_SCALE_X * hp_count
                        local fill_full_w = BARRICADE_HP_FILL_ART_W * fill_scale_x
                        local fill_x = bar_left + (fill_full_w * 0.5)
                        local fill_color = vmath.vector4(0.28, 1.0, 0.38, 1.0)
                        if hp_ratio <= 0.3 then
                            fill_color = vmath.vector4(1.0, 0.36, 0.3, 1.0)
                        elseif hp_ratio <= 0.6 then
                            fill_color = vmath.vector4(1.0, 0.9, 0.3, 1.0)
                        end
                        local fill_id = factory.create("/tile_factory#tile_factory", vmath.vector3(fill_x, hp_bar_y, BARRICADE_HP_BAR_Z + 0.0001))
                        if fill_id then
                            msg.post(msg.url(nil, fill_id, "sprite"), "play_animation", { id = BARRICADE_HP_BAR_FILL_ANIM })
                            pcall(go.set, msg.url(nil, fill_id, "sprite"), "blend_mode", hash("alpha"))
                            go.set_scale(vmath.vector3(fill_scale_x, BARRICADE_HP_BAR_BG_SCALE_Y, 1), fill_id)
                            go.set(msg.url(nil, fill_id, "sprite"), "tint", fill_color)
                            table.insert(self.obstacle_debug_objects, fill_id)
                        end
                    end
                elseif cell.isPowered then
                local slots = { cell.object1, cell.object2, cell.object3 }
                local obstacle_draw_index = 0
                for _, obj in ipairs(slots) do
                    if obj and obj.name == hash("obstacle") then
                        local count = obj.stackCount or obj.obstacleCount or 1
                        if count < 1 then
                            count = 1
                        end
                        local base_x = cx + (obj.offsetX or 0)
                        local base_y = cy + (obj.offsetY or 0)
                        local current_by_index = cell.obstacleNudgeCurrentByIndex
                        for i = 1, count do
                            obstacle_draw_index = obstacle_draw_index + 1
                            local shudder_dx = 0
                            local shudder_dy = 0
                            local per_obstacle_dx = (current_by_index and current_by_index[obstacle_draw_index]) or 0
                            local marker_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(base_x + ((i - 1) * 16) + per_obstacle_dx + shudder_dx, base_y + shudder_dy, 0.555))
                            if marker_id then
                                local variant_idx = (((obj.objectId or 0) + i) % 3) + 1
                                local obstacle_anim = hash("obstacle1")
                                if variant_idx == 2 then
                                    obstacle_anim = hash("obstacle2")
                                elseif variant_idx == 3 then
                                    obstacle_anim = hash("obstacle3")
                                end
                                msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = obstacle_anim })
                                go.set_scale(vmath.vector3(0.9, 0.9, 1), marker_id)
                                go.set(msg.url(nil, marker_id, "sprite"), "tint", vmath.vector4(1, 1, 1, 1))
                                table.insert(self.obstacle_debug_objects, marker_id)
                            end
                        end
                    end
                end
                end
            end
            local nav_obj = runtime.get_nav_computer_object and runtime.get_nav_computer_object(cell) or nil
            if nav_obj and cell.isPowered == true then
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local wx = x + (nav_obj.offsetX or 0)
                local wy = y + (nav_obj.offsetY or 0)
                local marker_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(wx, wy + 14, 0.57))
                if marker_id then
                    msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = hash("nav_data") })
                    go.set_scale(vmath.vector3(0.62, 0.62, 1), marker_id)
                    local tint = (nav_obj.isFixed == true)
                        and vmath.vector4(0.3, 1, 0.45, 0.85)
                        or vmath.vector4(0.35, 0.85, 1, 0.95)
                    go.set(msg.url(nil, marker_id, "sprite"), "tint", tint)
                    table.insert(self.exit_requirement_markers, marker_id)
                end
            end
            local supply_obj = runtime.get_supply_loader_object and runtime.get_supply_loader_object(cell) or nil
            if supply_obj and cell.isPowered == true then
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local wx = x + (supply_obj.offsetX or 0)
                local wy = y + (supply_obj.offsetY or 0)
                local marker_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(wx, wy + 14, 0.57))
                if marker_id then
                    msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = hash("food_supplies") })
                    go.set_scale(vmath.vector3(0.7, 0.7, 1), marker_id)
                    local tint = (supply_obj.isFixed == true)
                        and vmath.vector4(0.3, 1, 0.45, 0.85)
                        or vmath.vector4(1, 0.86, 0.35, 0.95)
                    go.set(msg.url(nil, marker_id, "sprite"), "tint", tint)
                    table.insert(self.exit_requirement_markers, marker_id)
                end
            end
        end
    end

    -- Hook for future barricade impact FX integration.
    runtime.play_barricade_hit_fx = function(self, cell_id, destroyed)
        return false
    end

    runtime.refresh_power_node_markers = function(self)
        self.power_node_objects = self.power_node_objects or {}
        self.power_node_shadow_objects = self.power_node_shadow_objects or {}
        self.power_node_power_state = self.power_node_power_state or {}
        self.power_node_flicker_state = self.power_node_flicker_state or {}
        self.escape_pod_power_slot_markers = self.escape_pod_power_slot_markers or {}
        local power_node_objects = self.power_node_objects
        for i, marker in ipairs(self.escape_pod_power_slot_markers) do
            if marker then
                go.delete(marker)
            end
            self.escape_pod_power_slot_markers[i] = nil
        end
        for cell_id, marker in pairs(self.power_node_shadow_objects) do
            if marker then
                go.delete(marker)
            end
            self.power_node_shadow_objects[cell_id] = nil
        end
        for cell_id, marker in pairs(power_node_objects) do
            if marker then
                go.delete(marker)
            end
            power_node_objects[cell_id] = nil
        end

        if not self.world_grid then
            return
        end

        for cell_id, cell in ipairs(self.world_grid) do
            local power_node = runtime.get_power_node_object(cell)
            if power_node and cell.tileID ~= hash("empty") then
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local marker_x = x + (power_node.offsetX or 0)
                local marker_y = y + (power_node.offsetY or 0)
                if boardgame_shadows_enabled(self) then
                    local shadow_alpha = (cell.isPowered == true) and 0.33 or 0
                    self.power_node_shadow_objects[cell_id] = spawn_world_shadow(marker_x + 4, marker_y - 7, 0.5, 0.56, 0.22, shadow_alpha)
                end
                local marker_id = factory.create("/power_node_marker_factory#power_node_marker_factory", vmath.vector3(marker_x, marker_y, ctx.LOOT_UI.power_node_marker_z or 0.55))
                if marker_id then
                    local was_powered = self.power_node_power_state[cell_id]
                    if cell.isPowered and was_powered == false then
                        -- Match tile-light behavior: quick OFF/ON pulses before stable ON.
                        self.power_node_flicker_state[cell_id] = {
                            active = true,
                            timer = 0.06,
                            step = 1,
                            go_id = marker_id
                        }
                        msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = hash("powerNode_off") })
                    else
                        self.power_node_flicker_state[cell_id] = nil
                        local anim = cell.isPowered and hash("powerNode_on") or hash("powerNode_off")
                        msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = anim })
                    end
                    if cell.isPowered ~= true then
                        go.set(msg.url(nil, marker_id, "sprite"), "tint", vmath.vector4(0, 0, 0, 0))
                    end
                    self.power_node_power_state[cell_id] = cell.isPowered
                    go.set_scale(vmath.vector3(ctx.LOOT_UI.power_node_marker_size, ctx.LOOT_UI.power_node_marker_size, 1), marker_id)
                    power_node_objects[cell_id] = marker_id
                end
            end
            local socket = runtime.get_escape_pod_power_socket_object and runtime.get_escape_pod_power_socket_object(cell) or nil
            if socket and cell.tileID ~= hash("empty") and cell.isPowered == true then
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local cx = x + (socket.offsetX or 0)
                local cy = y + (socket.offsetY or 0)
                local loaded = math.max(0, socket.powerLoaded or 0)
                local required = math.max(1, socket.powerRequired or 9)
                local spacing = 18
                local index = 0
                for row = 1, 3 do
                    for col = 1, 3 do
                        index = index + 1
                        local ox = (col - 2) * spacing
                        local oy = (2 - row) * spacing
                        local marker_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(cx + ox, cy + oy, 0.552))
                        if marker_id then
                            msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = hash("power_unit") })
                            go.set_scale(vmath.vector3(0.55, 0.55, 1), marker_id)
                            local lit = index <= math.min(required, loaded)
                            local tint = lit and vmath.vector4(0.95, 0.95, 1, 0.95) or vmath.vector4(0.2, 0.2, 0.24, 0.35)
                            go.set(msg.url(nil, marker_id, "sprite"), "tint", tint)
                            table.insert(self.escape_pod_power_slot_markers, marker_id)
                        end
                    end
                end
            end
        end
    end

    runtime.refresh_wiregap_markers = function(self)
        self.wiregap_objects = self.wiregap_objects or {}
        self.wiregap_shadow_objects = self.wiregap_shadow_objects or {}
        self.wiregap_fx_objects = self.wiregap_fx_objects or {}
        for _, marker in ipairs(self.wiregap_shadow_objects) do
            if marker then
                go.delete(marker)
            end
        end
        for _, marker in ipairs(self.wiregap_objects) do
            if marker then
                go.delete(marker)
            end
        end
        for _, fx_id in ipairs(self.wiregap_fx_objects) do
            if fx_id then
                go.delete(fx_id)
            end
        end
        self.wiregap_shadow_objects = {}
        self.wiregap_objects = {}
        self.wiregap_fx_objects = {}

        if not self.world_grid then
            return
        end

        local function get_wiregap_anim(obj)
            if not obj or not obj.name then
                return nil
            end
            local key = nil
            if obj.name == hash("wiregap_straight") or obj.name == hash("wireGap_straight") then
                key = "straight"
            elseif obj.name == hash("wiregap_corner") or obj.name == hash("wireGap_corner") then
                key = "corner"
            elseif obj.name == hash("wiregap") or obj.name == hash("wireGap") then
                if obj.requiredComponent == ctx.COMPONENT_UI.component_wiring_corner then
                    key = "corner"
                else
                    key = "straight"
                end
            end
            if not key then
                return nil
            end
            local state = (obj.isFixed == true) and "on" or "off"
            return hash("wiregap_" .. key .. "_" .. state)
        end

        for _, cell in ipairs(self.world_grid) do
            if cell.tileID ~= hash("empty") and cell.isPowered then
                local objects = { cell.object1, cell.object2, cell.object3 }
                for _, obj in ipairs(objects) do
                    local anim = get_wiregap_anim(obj)
                    if anim then
                        local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                        local wx = x + (obj.offsetX or 0)
                        local wy = y + (obj.offsetY or 0)
                        if boardgame_shadows_enabled(self) then
                            local shadow_id = spawn_world_shadow(wx + 4, wy - 6, 0.5, 0.48, 0.19, 0.32)
                            if shadow_id then
                                table.insert(self.wiregap_shadow_objects, shadow_id)
                            end
                        end
                        local marker_id = factory.create("/tile_factory#tile_factory", vmath.vector3(wx, wy, 0.554))
                        if marker_id then
                            msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = anim })
                            go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                            table.insert(self.wiregap_objects, marker_id)
                        end
                        if obj.isFixed ~= true and obj.fxFactory then
                            local fx_x = wx + (obj.fxOffsetX or 0)
                            local fx_y = wy + (obj.fxOffsetY or 0)
                            local fx_id = factory.create(obj.fxFactory, vmath.vector3(fx_x, fx_y, 0.57))
                            if fx_id then
                                go.set_rotation(vmath.quat_rotation_z(math.rad(obj.fxRotation or 0)), fx_id)
                                particlefx.play(msg.url(nil, fx_id, "particlefx"))
                                table.insert(self.wiregap_fx_objects, fx_id)
                            end
                        end
                    end
                end
            end
        end
    end

    runtime.refresh_vent_markers = function(self)
        self.vent_objects = self.vent_objects or {}
        self.vent_shadow_objects = self.vent_shadow_objects or {}
        for cell_id, marker in pairs(self.vent_shadow_objects) do
            if marker then
                go.delete(marker)
            end
            self.vent_shadow_objects[cell_id] = nil
        end
        for cell_id, marker in pairs(self.vent_objects) do
            if marker then
                go.delete(marker)
            end
            self.vent_objects[cell_id] = nil
        end

        if not self.world_grid then
            return
        end

        for cell_id, cell in ipairs(self.world_grid) do
            local vent = runtime.get_vent_object(cell)
            if vent and cell.tileID ~= hash("empty") and cell.isPowered then
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local vent_x = x + (vent.offsetX or 0)
                local vent_y = y + (vent.offsetY or 0)
                local fx_active = self.vent_weld_fx_cells and self.vent_weld_fx_cells[cell_id]
                local marker_x = fx_active and (x + WELD_OVERLAY_OFFSET_X) or vent_x
                local marker_y = fx_active and (y + WELD_OVERLAY_OFFSET_Y) or vent_y
                if boardgame_shadows_enabled(self) then
                    self.vent_shadow_objects[cell_id] = spawn_world_shadow(vent_x + 4, vent_y - 6, 0.5, 0.45, 0.18, 0.32)
                end
                local marker_z = fx_active and WELD_OVERLAY_Z or 0.48
                local marker_factory = fx_active and "/weld_overlay_factory#weld_overlay_factory" or "/alien_blip_factory#alien_blip_factory"
                local marker_id = factory.create(marker_factory, vmath.vector3(marker_x, marker_y, marker_z))
                if marker_id then
                    local anim = fx_active and hash("weld_overlay") or (vent.isWelded == true and hash("vent_welded") or hash("vent_unwelded"))
                    msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = anim })
                    if fx_active then
                        local sprite_url = msg.url(nil, marker_id, "sprite")
                        local dim_tint = vmath.vector4(0, 0, 0, 1)
                        local bright_tint = vmath.vector4(0, 1, 1, 1)
                        local pulse_speed = 0.03 + (math.random() * 0.11)
                        go.set(sprite_url, "tint", dim_tint)
                        go.animate(sprite_url, "tint", go.PLAYBACK_LOOP_PINGPONG, bright_tint, go.EASING_INOUTSINE, pulse_speed)
                        go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                    else
                        go.set_scale(vmath.vector3(0.6, 0.6, 1), marker_id)
                    end
                    self.vent_objects[cell_id] = marker_id
                end
            end
        end
    end

    runtime.refresh_door_markers = function(self)
        self.door_objects = self.door_objects or {}
        self.door_shadow_objects = self.door_shadow_objects or {}
        self.door_visual_state = self.door_visual_state or {}
        self.door_hp_bar_bg_objects = self.door_hp_bar_bg_objects or {}
        self.door_hp_bar_fill_objects = self.door_hp_bar_fill_objects or {}

        if not self.world_grid then
            return
        end

        local function get_door_obj(cell)
            local objs = { cell.object1, cell.object2, cell.object3 }
            for _, obj in ipairs(objs) do
                if obj and obj.name == hash("door") then
                    return obj
                end
            end
            return nil
        end

        local function dependency_met(world_grid, obj)
            if not obj then
                return false
            end
            local dep = obj.dependsOn or 0
            if dep <= 0 then
                return true
            end
            for _, cell in ipairs(world_grid or {}) do
                local scan = { cell.object1, cell.object2, cell.object3 }
                for _, other in ipairs(scan) do
                    if other and other.objectId == dep then
                        return other.isFixed == true
                    end
                end
            end
            return false
        end

        local seen = {}
        local function clear_door_hp_bar(cell_id)
            local bg = self.door_hp_bar_bg_objects[cell_id]
            if bg then
                go.delete(bg)
                self.door_hp_bar_bg_objects[cell_id] = nil
            end
            local fill = self.door_hp_bar_fill_objects[cell_id]
            if fill then
                go.delete(fill)
                self.door_hp_bar_fill_objects[cell_id] = nil
            end
        end
        for cell_id, cell in ipairs(self.world_grid) do
            if cell.tileID ~= hash("empty") and cell.isPowered == true then
                local door = get_door_obj(cell)
                if door then
                    seen[cell_id] = true
                    local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                    local shudder_dx = 0
                    if (door.door_shudder_timer or 0) > 0 then
                        local phase = (door.door_shudder_phase or 0)
                        shudder_dx = math.sin(phase) * 4.4
                    end
                    local dx = x + (door.offsetX or 0) + shudder_dx
                    local dy = y + (door.offsetY or 0)
                    local powered = cell.isPowered == true
                    local fixed = door.isFixed == true
                    local deps_met = dependency_met(self.world_grid, door)
                    local functional = powered and fixed and deps_met
                    local closed = functional and (door.isOpen ~= true)
                    local door_tint_mul = math.max(0.25, math.min(1.0, door.door_damage_tint or 1.0))
                    local closed_tint = vmath.vector4(door_tint_mul, door_tint_mul, door_tint_mul, 1)
                    local open_tint = vmath.vector4(0.5 * door_tint_mul, 0.5 * door_tint_mul, 0.5 * door_tint_mul, 1)
                    local visual_state = "open"
                    local anim = hash("door_open")
                    local z = 0.555
                    if closed then
                        visual_state = powered and "closed_on" or "closed_off"
                        anim = (visual_state == "closed_on") and hash("door_closed_on") or hash("door_closed_off")
                        z = 0.565
                    end
                    local marker_id = self.door_objects[cell_id]
                    local shadow_id = self.door_shadow_objects[cell_id]
                    if not marker_id then
                        marker_id = factory.create("/tile_factory#tile_factory", vmath.vector3(dx, dy, z))
                        if marker_id then
                            self.door_objects[cell_id] = marker_id
                            msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = anim })
                            go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                        end
                    end
                    if boardgame_shadows_enabled(self) then
                        if not shadow_id then
                            shadow_id = spawn_world_shadow(dx + 7, dy - 10, 0.5, 0.72, 0.27, 0.35)
                            self.door_shadow_objects[cell_id] = shadow_id
                        elseif shadow_id then
                            go.set_position(vmath.vector3(dx + 7, dy - 10, 0.5), shadow_id)
                        end
                    elseif shadow_id then
                        go.delete(shadow_id)
                        self.door_shadow_objects[cell_id] = nil
                    end
                    if marker_id then
                        go.set_position(vmath.vector3(dx, dy, z), marker_id)
                        local prev_state = self.door_visual_state[cell_id]
                        local sprite_url = msg.url(nil, marker_id, "sprite")
                        if prev_state ~= visual_state and prev_state ~= "closing" then
                            go.cancel_animations(marker_id, "scale")
                            go.cancel_animations(sprite_url, "tint")
                            if visual_state == "open" then
                                msg.post(sprite_url, "play_animation", { id = hash("door_open") })
                                go.set(sprite_url, "tint", closed_tint)
                                go.set_scale(vmath.vector3(0.08, 1, 1), marker_id)
                                go.animate(marker_id, "scale", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(1, 1, 1), go.EASING_INOUTSINE, 0.56)
                                go.animate(sprite_url, "tint", go.PLAYBACK_ONCE_FORWARD, open_tint, go.EASING_INOUTSINE, 0.56)
                                self.door_visual_state[cell_id] = visual_state
                            elseif prev_state == "open" then
                                -- Closing is reverse of opening: shrink open panel back down.
                                msg.post(sprite_url, "play_animation", { id = hash("door_open") })
                                go.set(sprite_url, "tint", open_tint)
                                go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                                go.animate(marker_id, "scale", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(0.08, 1, 1), go.EASING_INOUTSINE, 0.56)
                                go.animate(sprite_url, "tint", go.PLAYBACK_ONCE_FORWARD, closed_tint, go.EASING_INOUTSINE, 0.56)
                                self.door_visual_state[cell_id] = "closing"
                                timer.delay(0.56, false, function()
                                    if self.door_objects and self.door_objects[cell_id] == marker_id then
                                        go.cancel_animations(marker_id, "scale")
                                        go.cancel_animations(sprite_url, "tint")
                                        msg.post(sprite_url, "play_animation", { id = anim })
                                        go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                                        go.set(sprite_url, "tint", closed and closed_tint or open_tint)
                                        self.door_visual_state[cell_id] = visual_state
                                    end
                                end)
                            else
                                msg.post(sprite_url, "play_animation", { id = anim })
                                go.set(sprite_url, "tint", closed and closed_tint or open_tint)
                                go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                                self.door_visual_state[cell_id] = visual_state
                            end
                        elseif prev_state == "closing" then
                            -- Let close transition finish before forcing steady-state transforms.
                        elseif visual_state == "open" then
                            go.set(sprite_url, "tint", open_tint)
                        else
                            -- Closed door sprites must never remain scaled.
                            go.cancel_animations(marker_id, "scale")
                            go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                            go.set(sprite_url, "tint", closed_tint)
                        end
                    end
                    local show_hp_bar = closed
                    if show_hp_bar then
                        local hp_count = math.max(0, math.min(DOOR_HP_MAX, door.door_hp or DOOR_HP_DEFAULT))
                        local hp_step = hp_count * 0.1
                        local hp_bar_x = dx
                        local hp_bar_y = dy + BARRICADE_HP_BAR_OFFSET_Y
                        local bar_left = hp_bar_x - (BARRICADE_HP_BAR_BG_FULL_W * 0.5)
                        local bg_id = self.door_hp_bar_bg_objects[cell_id]
                        if not bg_id then
                            bg_id = factory.create("/tile_factory#tile_factory", vmath.vector3(hp_bar_x, hp_bar_y, BARRICADE_HP_BAR_Z))
                            if bg_id then
                                self.door_hp_bar_bg_objects[cell_id] = bg_id
                                msg.post(msg.url(nil, bg_id, "sprite"), "play_animation", { id = BARRICADE_HP_BAR_BG_ANIM })
                                pcall(go.set, msg.url(nil, bg_id, "sprite"), "blend_mode", hash("alpha"))
                                go.set_scale(vmath.vector3(BARRICADE_HP_BAR_BG_SCALE_X, BARRICADE_HP_BAR_BG_SCALE_Y, 1), bg_id)
                                go.set(msg.url(nil, bg_id, "sprite"), "tint", vmath.vector4(1, 1, 1, 1))
                            end
                        else
                            go.set_position(vmath.vector3(hp_bar_x, hp_bar_y, BARRICADE_HP_BAR_Z), bg_id)
                        end
                        local fill_id = self.door_hp_bar_fill_objects[cell_id]
                        if hp_step > 0 then
                            local fill_scale_x = BARRICADE_HP_BAR_BG_SCALE_X * hp_count
                            local fill_full_w = BARRICADE_HP_FILL_ART_W * fill_scale_x
                            local fill_x = bar_left + (fill_full_w * 0.5)
                            local fill_color = vmath.vector4(0.28, 1.0, 0.38, 1.0)
                            if hp_step <= 0.1 then
                                fill_color = vmath.vector4(1.0, 0.36, 0.3, 1.0)
                            elseif hp_step <= 0.2 then
                                fill_color = vmath.vector4(1.0, 0.9, 0.3, 1.0)
                            end
                            if not fill_id then
                                fill_id = factory.create("/tile_factory#tile_factory", vmath.vector3(fill_x, hp_bar_y, BARRICADE_HP_BAR_Z + 0.0001))
                                if fill_id then
                                    self.door_hp_bar_fill_objects[cell_id] = fill_id
                                    msg.post(msg.url(nil, fill_id, "sprite"), "play_animation", { id = BARRICADE_HP_BAR_FILL_ANIM })
                                    pcall(go.set, msg.url(nil, fill_id, "sprite"), "blend_mode", hash("alpha"))
                                end
                            end
                            if fill_id then
                                go.set_position(vmath.vector3(fill_x, hp_bar_y, BARRICADE_HP_BAR_Z + 0.0001), fill_id)
                                go.set_scale(vmath.vector3(fill_scale_x, BARRICADE_HP_BAR_BG_SCALE_Y, 1), fill_id)
                                go.set(msg.url(nil, fill_id, "sprite"), "tint", fill_color)
                            end
                        else
                            if fill_id then
                                go.delete(fill_id)
                                self.door_hp_bar_fill_objects[cell_id] = nil
                            end
                        end
                    else
                        clear_door_hp_bar(cell_id)
                    end
                end
            end
        end

        for cell_id, marker in pairs(self.door_objects) do
            if not seen[cell_id] then
                if marker then
                    go.delete(marker)
                end
                self.door_objects[cell_id] = nil
                self.door_visual_state[cell_id] = nil
                local shadow_id = self.door_shadow_objects[cell_id]
                if shadow_id then
                    go.delete(shadow_id)
                end
                self.door_shadow_objects[cell_id] = nil
                clear_door_hp_bar(cell_id)
            end
        end
    end

    runtime.update_power_node_flicker = function(self, dt)
        if not self.power_node_flicker_state then
            return
        end
        for cell_id, flicker in pairs(self.power_node_flicker_state) do
            if flicker and flicker.active then
                local marker_id = self.power_node_objects and self.power_node_objects[cell_id]
                if not marker_id or marker_id ~= flicker.go_id then
                    self.power_node_flicker_state[cell_id] = nil
                else
                    flicker.timer = flicker.timer - dt
                    if flicker.timer <= 0 then
                        if flicker.step == 1 then
                            msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = hash("powerNode_on") })
                            flicker.timer = 0.05
                        elseif flicker.step == 2 then
                            msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = hash("powerNode_off") })
                            flicker.timer = 0.06
                        elseif flicker.step == 3 then
                            msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = hash("powerNode_on") })
                            flicker.timer = 0.05
                        elseif flicker.step == 4 then
                            msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = hash("powerNode_off") })
                            flicker.timer = 0.04
                        else
                            msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = hash("powerNode_on") })
                            flicker.active = false
                            flicker.timer = 0
                        end
                        flicker.step = flicker.step + 1
                    end
                end
            end
        end
    end

    runtime.refresh_light_value_markers = function(self)
        self.light_value_objects = self.light_value_objects or {}
        local light_value_objects = self.light_value_objects
        for _, marker in ipairs(light_value_objects) do
            if marker then
                go.delete(marker)
            end
        end
        self.light_value_objects = {}

        if not self.world_grid then
            return
        end

        for _, cell in ipairs(self.world_grid) do
            if cell.tileID ~= hash("empty") and cell.isPowered then
                local pip_count = math.max(0, math.min(3, cell.lightValue or 0))
                if pip_count > 0 then
                    local center_x, center_y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                    local top_left_x = center_x - (ctx.CELL_WIDTH * 0.5) + ctx.LOOT_UI.light_pip_top_left_offset_x
                    local top_left_y = center_y + (ctx.CELL_HEIGHT * 0.5) - ctx.LOOT_UI.light_pip_top_left_offset_y
                    for i = 1, pip_count do
                        local pip_x = top_left_x + ((i - 1) * (ctx.LOOT_UI.light_pip_size + ctx.LOOT_UI.light_pip_gap))
                        local marker_id = factory.create("/ui_factory#ui_factory", vmath.vector3(pip_x, top_left_y, 0.047))
                        if marker_id then
                            go.set_scale(vmath.vector3(ctx.LOOT_UI.light_pip_size, ctx.LOOT_UI.light_pip_size, 1), marker_id)
                            go.set(msg.url(nil, marker_id, "sprite"), "tint", ctx.LOOT_UI.light_pip_color)
                            table.insert(self.light_value_objects, marker_id)
                        end
                    end
                end
            end
        end
    end

    runtime.spawn_loot_pickup_blip = function(self, from_cell_id, to_slot_index, item_type, from_world_x, from_world_y)
        local from_x, from_y = from_world_x, from_world_y
        if not from_x or not from_y then
            if not self.world_grid or not self.world_grid[from_cell_id] then
                return
            end
            local from_cell = self.world_grid[from_cell_id]
            from_x, from_y = ctx.coords_to_world_pos(from_cell.xCell, from_cell.yCell)
        end

        local slot_x, slot_y = runtime.get_backpack_slot_screen_pos(to_slot_index)
        local to_x, to_y = ctx.screen_to_world(slot_x, slot_y, self.camera_pos, self.camera_zoom)

        local blip_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(from_x, from_y, 0.83))
        if not blip_id then
            return
        end
        local shadow_id = nil
        local icon_anim = runtime.get_item_visual_animation and runtime.get_item_visual_animation(item_type) or nil
        if icon_anim then
            msg.post(msg.url(nil, blip_id, "sprite"), "play_animation", { id = icon_anim })
            go.set(msg.url(nil, blip_id, "sprite"), "tint", vmath.vector4(1, 1, 1, 1))
        else
            local color = runtime.get_backpack_item_color(item_type)
            go.set(msg.url(nil, blip_id, "sprite"), "tint", color)
        end
        go.set_scale(vmath.vector3(0.85, 0.85, 1), blip_id)

        table.insert(self.loot_pickup_blips, {
            go_id = blip_id,
            shadow_id = shadow_id,
            from = vmath.vector3(from_x, from_y, 0.83),
            to = vmath.vector3(to_x, to_y, 0.83),
            t = 0
        })
    end

    runtime.update_loot_pickup_blips = function(self, dt)
        if not self.loot_pickup_blips then
            return
        end

        for i = #self.loot_pickup_blips, 1, -1 do
            local blip = self.loot_pickup_blips[i]
            if not blip.go_id then
                if blip.shadow_id then
                    go.delete(blip.shadow_id)
                end
                table.remove(self.loot_pickup_blips, i)
            else
                local dx = blip.to.x - blip.from.x
                local dy = blip.to.y - blip.from.y
                local dist = math.sqrt(dx * dx + dy * dy)
                local travel_time = math.max(0.05, dist / ctx.LOOT_UI.pickup_blip_speed)
                blip.t = math.min(1, blip.t + (dt / travel_time))
                local px = blip.from.x + (dx * blip.t)
                local py = blip.from.y + (dy * blip.t)
                go.set_position(vmath.vector3(px, py, 0.83), blip.go_id)
                if blip.t >= 1 then
                    go.delete(blip.go_id)
                    if blip.shadow_id then
                        go.delete(blip.shadow_id)
                    end
                    table.remove(self.loot_pickup_blips, i)
                end
            end
        end
    end

    return runtime
end

return M
