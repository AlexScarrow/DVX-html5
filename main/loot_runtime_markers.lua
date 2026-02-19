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
            if cell.hasLoot and cell.tileID ~= hash("empty") then
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local marker_id = factory.create("/ui_factory#ui_factory", vmath.vector3(x, y, ctx.LOOT_UI.marker_z))
                if marker_id then
                    go.set_scale(vmath.vector3(ctx.LOOT_UI.marker_size, ctx.LOOT_UI.marker_size, 1), marker_id)
                    go.set(msg.url(nil, marker_id, "sprite"), "tint", vmath.vector4(1, 1, 1, 1))
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
            if runtime.cell_has_component_machine(cell) and cell.tileID ~= hash("empty") then
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local marker_id = factory.create("/ui_factory#ui_factory", vmath.vector3(x, y + 10, 0.045))
                if marker_id then
                    go.set_scale(vmath.vector3(ctx.COMPONENT_UI.machine_marker_size, ctx.COMPONENT_UI.machine_marker_size, 1), marker_id)
                    go.set(msg.url(nil, marker_id, "sprite"), "tint", ctx.COMPONENT_UI.machine_marker_color)
                    machine_objects[cell_id] = marker_id
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
            if #fixables > 0 and cell.tileID ~= hash("empty") then
                local unresolved = runtime.cell_has_fixable_object(cell)
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local marker_id = factory.create("/ui_factory#ui_factory", vmath.vector3(x - 18, y + 12, 0.046))
                if marker_id then
                    go.set_scale(vmath.vector3(ctx.COMPONENT_UI.fix_marker_size, ctx.COMPONENT_UI.fix_marker_size, 1), marker_id)
                    local color = unresolved and ctx.COMPONENT_UI.fix_marker_color or ctx.COMPONENT_UI.fix_marker_fixed_color
                    go.set(msg.url(nil, marker_id, "sprite"), "tint", color)
                    self.fix_objects[cell_id] = marker_id
                end
            end
        end
    end

    runtime.refresh_power_node_markers = function(self)
        self.power_node_objects = self.power_node_objects or {}
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
            if runtime.cell_has_power_node(cell) and cell.tileID ~= hash("empty") then
                local x, y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                local marker_id = factory.create("/ui_factory#ui_factory", vmath.vector3(x, y + 10, 0.046))
                if marker_id then
                    go.set_scale(vmath.vector3(ctx.LOOT_UI.power_node_marker_size, ctx.LOOT_UI.power_node_marker_size, 1), marker_id)
                    local marker_color = cell.isPowered and ctx.LOOT_UI.power_node_marker_powered_color or ctx.LOOT_UI.power_node_marker_color
                    go.set(msg.url(nil, marker_id, "sprite"), "tint", marker_color)
                    power_node_objects[cell_id] = marker_id
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
