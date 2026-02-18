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
