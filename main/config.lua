local M = {}

function M.create_ui_config(ui_panel_x, ui_panel_y, ui_panel_w, ui_panel_h)
    local loot_ui = {
        button_color = vmath.vector4(0.55, 0.36, 0.18, 1),
        ammo_color = vmath.vector4(0.65, 0.65, 0.65, 1),
        meds_color = vmath.vector4(0.95, 0.25, 0.25, 1),
        power_color = vmath.vector4(1, 0.85, 0.25, 1),
        material_color = vmath.vector4(0.55, 0.36, 0.18, 1),
        power_node_marker_color = vmath.vector4(0, 0, 0, 1),
        power_node_marker_powered_color = vmath.vector4(0.15, 0.95, 0.25, 1),
        power_node_marker_size = 1,
        power_node_marker_z = 0.48,
        power_node_drop_radius = 26,
        light_pip_color = vmath.vector4(1, 0.9, 0.2, 1),
        light_pip_size = 9,
        light_pip_gap = 3,
        light_pip_top_left_offset_x = 18,
        light_pip_top_left_offset_y = 16,
        button_size = 44,
        button_x = ui_panel_x + (ui_panel_w * 0.5) - 34,
        button_y = ui_panel_y - (ui_panel_h * 0.5) + 34,
        retrieve_button_color = vmath.vector4(0.95, 0.85, 0.2, 1),
        retrieve_button_size = 44,
        retrieve_button_x = ui_panel_x + (ui_panel_w * 0.5) - 34,
        retrieve_button_y = ui_panel_y - (ui_panel_h * 0.5) + 84,
        retrieve_ap_cost = 1,
        marker_size = 1,
        marker_z = 0.48,
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
        -- Canonical component ids for fixing/object interactions.
        component_wiring_straight = "wiring_straight",
        component_wiring_corner = "wiring_corner",
        component_plate = "plate",
        component_fuse = "fuse",
        component_sensor = "sensor",
        component_nav_data = "nav_data",
        component_food_supplies = "food_supplies",
        -- Legacy placeholder component id kept for backward compatibility.
        item_type_blue = "component_blue",
        component_color = vmath.vector4(0.35, 0.65, 1, 1),
        machine_marker_color = vmath.vector4(0.2, 0.75, 1, 1),
        machine_marker_size = 14,
        fix_marker_color = vmath.vector4(0.95, 0.6, 0.2, 1),
        fix_marker_fixed_color = vmath.vector4(0.35, 0.9, 0.45, 1),
        fix_marker_blocked_color = vmath.vector4(0.9, 0.8, 0.2, 1),
        fix_marker_size = 12,
        fix_marker_dependency_size = 18,
        button_color = vmath.vector4(0.25, 0.5, 0.9, 1),
        button_size = 44,
        button_x = ui_panel_x + (ui_panel_w * 0.5) - 86,
        button_y = ui_panel_y - (ui_panel_h * 0.5) + 34,
        fix_button_color = vmath.vector4(0.2, 0.8, 0.4, 1),
        fix_button_size = 44,
        fix_button_x = ui_panel_x + (ui_panel_w * 0.5) - 138,
        fix_button_y = ui_panel_y - (ui_panel_h * 0.5) + 34,
        fix_ap_cost = 1,
        object_default_hit_size = 32
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
    -- Hook for detailed combat modeling: Gunner gets substantially higher ranged effectiveness.
    gunner = { can_donate_ap = false, can_fix = false, can_heal = false, heavy_weapon = true, ranged_hit_bonus = 20 }
}

M.RANGED_HIT_MODEL = {
    base_hit_chance = 35,
    per_light_level_bonus = 15,
    min_hit_chance = 5,
    max_hit_chance = 100
}

M.MELEE_MODEL = {
    swipe_interval_seconds = 0.5,
    alien_base_hit_chance = 55,
    human_base_hit_chance = 60,
    min_hit_chance = 5,
    max_hit_chance = 95,
    human_hit_flash_duration = 0.18
}

-- Central AP tuning table for balance experiments.
M.AP_COSTS = {
    -- Core combat/movement
    manual_ranged_shot = 1,
    reactive_ranged_shot = 1,
    melee_attack = 1,
    -- Movement path step costs are computed elsewhere from board/path rules.
    -- Keep these keys for visibility/future tuning hooks.
    move_step_floor = 1,
    move_step_vertical = 2,

    -- Interactions
    door_toggle = 1,
    fix_object = 1,
    pickup_turret = 1,
    deploy_turret = 1,
    barricade_build = 0,
    barricade_reinforce = 0,
    nav_computer_interact = 0,
    supply_loader_interact = 0,
    workshop_pay_material = 0,
    med_heal_transfer = 0,

    -- Utility (currently free in balance test)
    drag_transfer = 0,
    scavenge_crate = 0,
    retrieve_power = 0,
    pickup_world_item = 0,
    pickup_obstacle = 0,
    medbay_corpse_store = 0,
    medbay_corpse_insert = 0
}

-- Central alien tuning table for AI pacing and spawn composition.
M.ALIEN_BALANCE = {
    REVEAL_WEIGHTS = {
        cannon_fodder = 1,
        speedy = 1,
        spitter = 1,
        brute = 1
    },
    TYPES = {
        blip = {
            ap_per_turn = 1,
            hp = 1,
            can_traverse_void = false,
            revealable = true,
            marker_tint = vmath.vector4(0.85, 0.3, 1.0, 1.0)
        },
        cannon_fodder = {
            ap_per_turn = 5,
            hp = 1,
            melee_damage = 1,
            can_traverse_void = false,
            has_ranged = false,
            marker_tint = vmath.vector4(1.0, 0.5, 0.3, 1.0)
        },
        speedy = {
            ap_per_turn = 10,
            hp = 1,
            melee_damage = 2,
            can_traverse_void = false,
            has_ranged = false,
            marker_tint = vmath.vector4(1.0, 0.2, 0.5, 1.0)
        },
        spitter = {
            ap_per_turn = 3,
            hp = 1,
            melee_damage = 1,
            can_traverse_void = false,
            has_ranged = true,
            ranged_cells = 4,
            marker_tint = vmath.vector4(0.4, 1.0, 0.4, 1.0)
        },
        brute = {
            ap_per_turn = 3,
            hp = 5,
            melee_damage = 3,
            can_traverse_void = false,
            has_ranged = false,
            marker_tint = vmath.vector4(0.8, 0.2, 0.2, 1.0)
        }
    },
    ACTION_COSTS = {
        melee_attack = 1,
        ranged_attack = 1,
        vertical_move = 2,
        vent_transit = 1
    }
}

M.BUFF_SLOT_ORDER = { "top", "center", "left", "right", "bottom" }

-- Buff hit-chance clamps intentionally avoid 0% and 100%.
M.BUFF_HIT_CHANCE_MIN = 5
M.BUFF_HIT_CHANCE_MAX = 95

-- Buff registry (Phase 0 scaffold). Item ids are backpack/world ids.
M.BUFFS = {
    armor = {
        id = "armor",
        item_type = "buff_armour",
        buff_kind = "armor",
        slot = "center",
        ui_anim = "buff_armour",
        world_anim = "buff_armour",
        info_anim = "armor_info",
        ui_pixel_w = 59,
        ui_pixel_h = 52,
        world_draw_scale = 1.0,
        backpack_draw_scale = 1.0,
        equipped_draw_scale = 1.0,
        info_pixel_w = 256,
        info_pixel_h = 256
    },
    hazmat_suit = {
        id = "hazmat_suit",
        item_type = "buff_hazmat",
        buff_kind = "hazmat_suit",
        slot = "center",
        ui_anim = "buff_hazmat",
        world_anim = "buff_hazmat",
        info_anim = "hazmat_suit_info",
        ui_pixel_w = 100,
        ui_pixel_h = 109,
        world_draw_scale = 0.75,
        backpack_draw_scale = 0.5,
        equipped_draw_scale = 0.5,
        info_pixel_w = 256,
        info_pixel_h = 256
    },
    oxygen_mask = {
        id = "oxygen_mask",
        item_type = "buff_oxygen_mask",
        buff_kind = "oxygen_mask",
        slot = "top",
        ui_anim = "buff_oxygen_mask",
        world_anim = "buff_oxygen_mask",
        info_anim = "oxygen_mask_info",
        ui_pixel_w = 34,
        ui_pixel_h = 36,
        world_draw_scale = 1.0,
        backpack_draw_scale = 1.5,
        equipped_draw_scale = 1.5,
        info_pixel_w = 256,
        info_pixel_h = 256
    },
    speed_stim = {
        id = "speed_stim",
        item_type = "buff_speed_stims",
        buff_kind = "speed_stim",
        slot = "bottom",
        ui_anim = "buff_speed_stims",
        world_anim = "buff_speed_stims",
        info_anim = "speed_stim_info",
        ui_pixel_w = 92,
        ui_pixel_h = 40,
        world_draw_scale = 0.75,
        backpack_draw_scale = 0.5,
        equipped_draw_scale = 0.5,
        info_pixel_w = 256,
        info_pixel_h = 256
    },
    nightvision_goggles = {
        id = "nightvision_goggles",
        item_type = "buff_night_vision",
        buff_kind = "nightvision_goggles",
        slot = "top",
        ui_anim = "buff_night_vision",
        world_anim = "buff_night_vision",
        info_anim = "night_vision_info",
        ui_pixel_w = 28,
        ui_pixel_h = 22,
        world_draw_scale = 1.0,
        backpack_draw_scale = 1.5,
        equipped_draw_scale = 1.5,
        info_pixel_w = 256,
        info_pixel_h = 256
    },
    melee_weapon_left = {
        id = "melee_weapon_left",
        item_type = "buff_melee_left",
        buff_kind = "melee_weapon",
        slot = "left",
        ui_anim = "buff_melee_left",
        world_anim = "buff_melee_left",
        info_anim = "melee_info",
        ui_pixel_w = 52,
        ui_pixel_h = 88,
        world_draw_scale = 0.75,
        backpack_draw_scale = 0.75,
        equipped_draw_scale = 0.75,
        info_pixel_w = 256,
        info_pixel_h = 256
    },
    melee_weapon_right = {
        id = "melee_weapon_right",
        item_type = "buff_melee_right",
        buff_kind = "melee_weapon",
        slot = "right",
        ui_anim = "buff_melee_right",
        world_anim = "buff_melee_right",
        info_anim = "melee_info",
        ui_pixel_w = 52,
        ui_pixel_h = 88,
        world_draw_scale = 0.75,
        backpack_draw_scale = 0.75,
        equipped_draw_scale = 0.75,
        info_pixel_w = 256,
        info_pixel_h = 256
    }
}

return M
