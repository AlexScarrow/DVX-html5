local M = {}

function M.create(ctx)
    local runtime = {}

    runtime.get_backpack_item_color = function(item_type)
        if item_type == "ammo" then
            return ctx.LOOT_UI.ammo_color
        elseif item_type == "meds" then
            return ctx.LOOT_UI.meds_color
        elseif item_type == "material" then
            return ctx.LOOT_UI.material_color
        elseif item_type == ctx.COMPONENT_UI.item_type_blue then
            return ctx.COMPONENT_UI.component_color
        end
        return ctx.UI_COLOR_SLOT
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

    runtime.cell_has_component_machine = function(cell)
        if not cell then
            return false
        end
        return (cell.object1 and cell.object1.name == hash("machine"))
            or (cell.object2 and cell.object2.name == hash("machine"))
            or (cell.object3 and cell.object3.name == hash("machine"))
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

    runtime.can_transfer_between_units = function(source_unit, target_unit)
        if not source_unit or not target_unit or not source_unit.cell_id or not target_unit.cell_id then
            return false
        end
        local sx, sy = ctx.id_to_coords(source_unit.cell_id)
        local tx, ty = ctx.id_to_coords(target_unit.cell_id)
        local manhattan = math.abs(sx - tx) + math.abs(sy - ty)
        return manhattan <= 1
    end

    return runtime
end

return M
