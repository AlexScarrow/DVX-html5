local M = {}

function M.extend(runtime, ctx)
    runtime.clear_loot_marker = function(cell_id)
        local loot_objects = ctx.get_loot_objects()
        local marker = loot_objects[cell_id]
        if marker then
            go.delete(marker)
            loot_objects[cell_id] = nil
        end
    end

    runtime.refresh_loot_markers = function(self)
        local loot_objects = ctx.get_loot_objects()
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
            if cell.hasLoot and cell.tileID ~= hash("empty") and cell.isPowered then
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local marker_x = x + (cell.lootOffsetX or 0)
                local marker_y = y + (cell.lootOffsetY or 0)
                local marker_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(marker_x, marker_y, ctx.LOOT_UI.marker_z))
                if marker_id then
                    go.set_scale(vmath.vector3(ctx.LOOT_UI.marker_size, ctx.LOOT_UI.marker_size, 1), marker_id)
                    loot_objects[cell_id] = marker_id
                end
            end
        end
    end

    runtime.refresh_machine_markers = function(self)
        local machine_objects = ctx.get_machine_objects()
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
                local marker_id = factory.create("/tile_factory#tile_factory", vmath.vector3(mx, my, 0.56))
                if marker_id then
                    local anim = hash("wiregap_straight_off")
                    if machine.name == hash("ammo_vending_machine") then
                        anim = hash("ammo_vend_machine")
                    elseif machine.name == hash("med_vending_machine") then
                        anim = hash("med_vend_machine")
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
            if cell.tileID ~= hash("empty") and cell.isPowered then
                local objects = { cell.object1, cell.object2, cell.object3 }
                for _, obj in ipairs(objects) do
                    if obj and obj.name == hash("gun_turret") then
                        local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                        local tx = x + (obj.offsetX or 0)
                        local ty = y + (obj.offsetY or 0)
                        local tripod_id = factory.create("/tile_factory#tile_factory", vmath.vector3(tx, ty, 0.56))
                        local gun_id = factory.create("/tile_factory#tile_factory", vmath.vector3(tx, ty, 0.561))
                        if tripod_id then
                            msg.post(msg.url(nil, tripod_id, "sprite"), "play_animation", { id = hash("gun_turret_tripod") })
                            go.set_scale(vmath.vector3(1, 1, 1), tripod_id)
                            turret_tripod_objects[cell_id] = tripod_id
                        end
                        if gun_id then
                            msg.post(msg.url(nil, gun_id, "sprite"), "play_animation", { id = hash("gun_turret") })
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
        for cell_id, marker in pairs(self.fix_objects) do
            if marker then
                go.delete(marker)
            end
            self.fix_objects[cell_id] = nil
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
        end
    end

    runtime.refresh_power_node_markers = function(self)
        self.power_node_objects = self.power_node_objects or {}
        self.power_node_power_state = self.power_node_power_state or {}
        self.power_node_flicker_state = self.power_node_flicker_state or {}
        local power_node_objects = self.power_node_objects
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
                    self.power_node_power_state[cell_id] = cell.isPowered
                    go.set_scale(vmath.vector3(ctx.LOOT_UI.power_node_marker_size, ctx.LOOT_UI.power_node_marker_size, 1), marker_id)
                    power_node_objects[cell_id] = marker_id
                end
            end
        end
    end

    runtime.refresh_wiregap_markers = function(self)
        self.wiregap_objects = self.wiregap_objects or {}
        for _, marker in ipairs(self.wiregap_objects) do
            if marker then
                go.delete(marker)
            end
        end
        self.wiregap_objects = {}

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
                        local marker_id = factory.create("/tile_factory#tile_factory", vmath.vector3(wx, wy, 0.56))
                        if marker_id then
                            msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = anim })
                            go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                            table.insert(self.wiregap_objects, marker_id)
                        end
                    end
                end
            end
        end
    end

    runtime.refresh_vent_markers = function(self)
        self.vent_objects = self.vent_objects or {}
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
                local marker_id = factory.create("/alien_blip_factory#alien_blip_factory", vmath.vector3(vent_x, vent_y, 0.48))
                if marker_id then
                    local anim = vent.isWelded == true and hash("vent_welded") or hash("vent_unwelded")
                    msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = anim })
                    go.set_scale(vmath.vector3(0.6, 0.6, 1), marker_id)
                    self.vent_objects[cell_id] = marker_id
                end
            end
        end
    end

    runtime.refresh_door_markers = function(self)
        self.door_objects = self.door_objects or {}
        self.door_visual_state = self.door_visual_state or {}

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
        for cell_id, cell in ipairs(self.world_grid) do
            if cell.tileID ~= hash("empty") and cell.isPowered == true then
                local door = get_door_obj(cell)
                if door then
                    seen[cell_id] = true
                    local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                    local dx = x + (door.offsetX or 0)
                    local dy = y + (door.offsetY or 0)
                    local powered = cell.isPowered == true
                    local fixed = door.isFixed == true
                    local deps_met = dependency_met(self.world_grid, door)
                    local functional = powered and fixed and deps_met
                    local closed = functional and (door.isOpen ~= true)
                    local visual_state = "open"
                    local anim = hash("door_open")
                    local z = 0.555
                    if closed then
                        visual_state = powered and "closed_on" or "closed_off"
                        anim = (visual_state == "closed_on") and hash("door_closed_on") or hash("door_closed_off")
                        z = 0.565
                    end
                    local marker_id = self.door_objects[cell_id]
                    if not marker_id then
                        marker_id = factory.create("/tile_factory#tile_factory", vmath.vector3(dx, dy, z))
                        if marker_id then
                            self.door_objects[cell_id] = marker_id
                            msg.post(msg.url(nil, marker_id, "sprite"), "play_animation", { id = anim })
                            go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                        end
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
                                go.set(sprite_url, "tint", vmath.vector4(1, 1, 1, 1))
                                go.set_scale(vmath.vector3(0.08, 1, 1), marker_id)
                                go.animate(marker_id, "scale", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(1, 1, 1), go.EASING_INOUTSINE, 0.56)
                                go.animate(sprite_url, "tint", go.PLAYBACK_ONCE_FORWARD, vmath.vector4(0.5, 0.5, 0.5, 1), go.EASING_INOUTSINE, 0.56)
                                self.door_visual_state[cell_id] = visual_state
                            elseif prev_state == "open" then
                                -- Closing is reverse of opening: shrink open panel back down.
                                msg.post(sprite_url, "play_animation", { id = hash("door_open") })
                                go.set(sprite_url, "tint", vmath.vector4(0.5, 0.5, 0.5, 1))
                                go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                                go.animate(marker_id, "scale", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(0.08, 1, 1), go.EASING_INOUTSINE, 0.56)
                                go.animate(sprite_url, "tint", go.PLAYBACK_ONCE_FORWARD, vmath.vector4(1, 1, 1, 1), go.EASING_INOUTSINE, 0.56)
                                self.door_visual_state[cell_id] = "closing"
                                timer.delay(0.56, false, function()
                                    if self.door_objects and self.door_objects[cell_id] == marker_id then
                                        go.cancel_animations(marker_id, "scale")
                                        go.cancel_animations(sprite_url, "tint")
                                        msg.post(sprite_url, "play_animation", { id = anim })
                                        go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                                        go.set(sprite_url, "tint", vmath.vector4(1, 1, 1, 1))
                                        self.door_visual_state[cell_id] = visual_state
                                    end
                                end)
                            else
                                msg.post(sprite_url, "play_animation", { id = anim })
                                go.set(sprite_url, "tint", vmath.vector4(1, 1, 1, 1))
                                go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                                self.door_visual_state[cell_id] = visual_state
                            end
                        elseif prev_state == "closing" then
                            -- Let close transition finish before forcing steady-state transforms.
                        elseif visual_state == "open" then
                            go.set(sprite_url, "tint", vmath.vector4(0.5, 0.5, 0.5, 1))
                        else
                            -- Closed door sprites must never remain scaled.
                            go.cancel_animations(marker_id, "scale")
                            go.set_scale(vmath.vector3(1, 1, 1), marker_id)
                            go.set(sprite_url, "tint", vmath.vector4(1, 1, 1, 1))
                        end
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

        local blip_id = factory.create("/ui_factory#ui_factory", vmath.vector3(from_x, from_y, 0.83))
        if not blip_id then
            return
        end

        local color = runtime.get_backpack_item_color(item_type)
        go.set_scale(vmath.vector3(ctx.LOOT_UI.pickup_blip_size, ctx.LOOT_UI.pickup_blip_size, 1), blip_id)
        go.set(msg.url(nil, blip_id, "sprite"), "tint", color)

        table.insert(self.loot_pickup_blips, {
            go_id = blip_id,
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
                    table.remove(self.loot_pickup_blips, i)
                end
            end
        end
    end

    return runtime
end

return M
