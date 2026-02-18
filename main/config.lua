local M = {}

function M.create_ui_config(ui_panel_x, ui_panel_y, ui_panel_w, ui_panel_h)
    local loot_ui = {
        button_color = vmath.vector4(0.55, 0.36, 0.18, 1),
        ammo_color = vmath.vector4(0.65, 0.65, 0.65, 1),
        meds_color = vmath.vector4(0.95, 0.25, 0.25, 1),
        material_color = vmath.vector4(0.55, 0.36, 0.18, 1),
        button_size = 44,
        button_x = ui_panel_x + (ui_panel_w * 0.5) - 34,
        button_y = ui_panel_y - (ui_panel_h * 0.5) + 34,
        marker_size = 12,
        marker_z = 0.04,
        pickup_blip_size = 20,
        pickup_blip_speed = 950,
        ap_cost = 1,
        drag_pip_size = 24,
        human_drop_radius = 42,
        bar_hit_padding = 10
    }

    local command_ui = {
        cols = 5,
        rows = 2,
        max_pips = 10,
        pip_size = 16,
        pip_gap = 4,
        start_x = 196,
        start_y = 282,
        active_color = vmath.vector4(1, 0.85, 0.25, 1),
        inactive_color = vmath.vector4(1, 0.85, 0.25, 0.2),
        drag_color = vmath.vector4(1, 0.85, 0.25, 1)
    }

    local component_ui = {
        item_type_blue = "component_blue",
        component_color = vmath.vector4(0.35, 0.65, 1, 1),
        machine_marker_color = vmath.vector4(0.2, 0.75, 1, 1),
        machine_marker_size = 14,
        button_color = vmath.vector4(0.25, 0.5, 0.9, 1),
        button_size = 44,
        button_x = ui_panel_x + (ui_panel_w * 0.5) - 86,
        button_y = ui_panel_y - (ui_panel_h * 0.5) + 34
    }

    return {
        LOOT_UI = loot_ui,
        COMMAND_UI = command_ui,
        COMPONENT_UI = component_ui
    }
end

M.CLASS_ROLE_HOOKS = {
    sarge = { can_donate_ap = true, can_fix = false, can_heal = false, heavy_weapon = false, ranged_hit_bonus = 0 },
    techie = { can_donate_ap = false, can_fix = true, can_heal = false, heavy_weapon = false, ranged_hit_bonus = 0 },
    medic = { can_donate_ap = false, can_fix = false, can_heal = true, heavy_weapon = false, ranged_hit_bonus = 0 },
    -- Hook for detailed combat modeling: Gunner gets higher ranged effectiveness.
    gunner = { can_donate_ap = false, can_fix = false, can_heal = false, heavy_weapon = true, ranged_hit_bonus = 5 }
}

return M
