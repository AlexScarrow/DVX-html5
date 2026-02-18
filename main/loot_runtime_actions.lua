local M = {}

function M.extend(runtime, ctx)
    runtime.try_scavenge_selected_unit = function(self, screen_x, screen_y)
        if not runtime.is_point_in_loot_button(screen_x, screen_y) then
            return false
        end

        local unit = ctx.get_selected_unit(self)
        if not unit or not unit.cell_id then
            return true
        end

        local cell = self.world_grid and self.world_grid[unit.cell_id]
        if not cell or not cell.hasLoot then
            print("No loot available here.")
            return true
        end

        if unit.current_ap < ctx.LOOT_UI.ap_cost then
            print("Unable to scavenge: no AP")
            return true
        end

        unit.current_ap = unit.current_ap - ctx.LOOT_UI.ap_cost

        local roll_count = math.random(1, 3)
        local capacity = unit.backpack_slots or (ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS)
        unit.backpack_items = unit.backpack_items or {}
        local added = 0
        local dropped = 0

        for _ = 1, roll_count do
            local loot_roll = math.random(1, 3)
            local item_type = (loot_roll == 1 and "ammo") or (loot_roll == 2 and "meds") or "material"
            if #unit.backpack_items < capacity then
                table.insert(unit.backpack_items, item_type)
                unit.backpack_used = #unit.backpack_items
                runtime.spawn_loot_pickup_blip(self, unit.cell_id, #unit.backpack_items, item_type)
                added = added + 1
            else
                dropped = dropped + 1
            end
        end

        cell.hasLoot = false
        runtime.clear_loot_marker(unit.cell_id)

        print(string.format(
            "%s scavenged loot: rolled=%d added=%d dropped=%d (AP -%d)",
            unit.display_name, roll_count, added, dropped, ctx.LOOT_UI.ap_cost
        ))

        ctx.update_human_visual_state(self)
        return true
    end

    runtime.try_use_component_vending = function(self, screen_x, screen_y)
        if not runtime.is_point_in_component_button(screen_x, screen_y) then
            return false
        end

        local unit = ctx.get_selected_unit(self)
        if not unit or not unit.cell_id then
            return true
        end

        local cell = self.world_grid and self.world_grid[unit.cell_id]
        if not runtime.cell_has_component_machine(cell) then
            print("No component vending machine here.")
            return true
        end

        unit.backpack_items = unit.backpack_items or {}
        local material_slot = nil
        for i, item in ipairs(unit.backpack_items) do
            if item == "material" then
                material_slot = i
                break
            end
        end

        if not material_slot then
            print("Need 1 material to produce a component.")
            return true
        end

        table.remove(unit.backpack_items, material_slot)
        local component_pool = { ctx.COMPONENT_UI.item_type_blue }
        local produced_component = component_pool[math.random(1, #component_pool)]
        table.insert(unit.backpack_items, produced_component)
        unit.backpack_used = #unit.backpack_items

        local machine_x, machine_y = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
        runtime.spawn_loot_pickup_blip(
            self,
            unit.cell_id,
            #unit.backpack_items,
            produced_component,
            machine_x,
            machine_y + 18
        )
        print(string.format("%s used 1 material and produced 1 component.", unit.display_name))
        return true
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
            unit.current_ammo = math.min(unit.max_ammo, unit.current_ammo + 1)
            return true
        end

        if bar_target == "meds" then
            if unit.current_health >= unit.max_health then
                print("Health already full.")
                return false
            end
            unit.current_health = math.min(unit.max_health, unit.current_health + 1)
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
            if unit.id ~= exclude_unit_id and unit.go_path then
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

    runtime.end_resource_drag = function(self, screen_x, screen_y)
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

        local consumed = false
        if drag.drag_type == "command" then
            local world_x, world_y = ctx.screen_to_world(screen_x, screen_y, self.camera_pos, self.camera_zoom)
            local target_unit = runtime.find_human_drop_target(self, world_x, world_y, source_unit.id)
            if target_unit then
                if runtime.can_transfer_between_units(source_unit, target_unit) then
                    if (source_unit.command_points or 0) > 0 then
                        source_unit.command_points = source_unit.command_points - 1
                        target_unit.current_ap = target_unit.current_ap + 1 -- intentionally uncapped by design
                        consumed = true
                        print(string.format("%s granted +1 AP to %s.", source_unit.display_name, target_unit.display_name))
                    else
                        print("No command points available.")
                    end
                else
                    print("too far away")
                end
            end
        else
            local bar_target = runtime.get_bar_drop_target(screen_x, screen_y)
            if bar_target then
                consumed = runtime.try_apply_to_own_bar(source_unit, source_item, bar_target)
                if consumed then
                    table.remove(source_unit.backpack_items, drag.source_slot_index)
                    source_unit.backpack_used = #source_unit.backpack_items
                    print(string.format("%s used 1 %s on own %s bar.", source_unit.display_name, source_item, bar_target))
                end
            else
                local world_x, world_y = ctx.screen_to_world(screen_x, screen_y, self.camera_pos, self.camera_zoom)
                local target_unit = runtime.find_human_drop_target(self, world_x, world_y, source_unit.id)
                if target_unit then
                    if runtime.can_transfer_between_units(source_unit, target_unit) then
                        if source_unit.class_id == ctx.UNIT_CLASS_MEDIC and source_item == "meds" then
                            if target_unit.current_health >= target_unit.max_health then
                                print(target_unit.display_name .. " already has full HP.")
                            else
                                table.remove(source_unit.backpack_items, drag.source_slot_index)
                                source_unit.backpack_used = #source_unit.backpack_items
                                target_unit.current_health = target_unit.max_health
                                consumed = true
                                print(string.format("%s used 1 meds on %s (full heal).", source_unit.display_name, target_unit.display_name))
                                -- FUTURE HOOK: play heal particle effect on target_unit.
                            end
                        else
                            target_unit.backpack_items = target_unit.backpack_items or {}
                            local target_cap = target_unit.backpack_slots or (ctx.UI_BACKPACK_COLS * ctx.UI_BACKPACK_ROWS)
                            if #target_unit.backpack_items < target_cap then
                                table.remove(source_unit.backpack_items, drag.source_slot_index)
                                source_unit.backpack_used = #source_unit.backpack_items
                                table.insert(target_unit.backpack_items, source_item)
                                target_unit.backpack_used = #target_unit.backpack_items
                                consumed = true
                                print(string.format("%s gave 1 %s to %s.", source_unit.display_name, source_item, target_unit.display_name))
                            else
                                print(target_unit.display_name .. " backpack is full.")
                            end
                        end
                    else
                        print("too far away")
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
            ctx.set_ui_square_transform(self, self.ui.drag_pip, -9999, -9999, 0.9, vmath.vector4(0, 0, 0, 0), ctx.LOOT_UI.drag_pip_size, ctx.LOOT_UI.drag_pip_size)
            return
        end

        local color = (drag.drag_type == "command") and ctx.COMMAND_UI.drag_color or runtime.get_backpack_item_color(drag.item_type)
        ctx.set_ui_square_transform(self, self.ui.drag_pip, drag.screen_x, drag.screen_y, 0.9, color, ctx.LOOT_UI.drag_pip_size, ctx.LOOT_UI.drag_pip_size)
    end

    return runtime
end

return M
