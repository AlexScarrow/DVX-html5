local M = {}

M.DEFAULT_MISSION_TYPE = "escape_pod"

-- Mission-aware scoring profiles.
-- Keep this file data-driven so tuning does not require gameplay code edits.
M.PROFILES = {
    escape_pod = {
        id = "escape_pod",
        name = "Escape",
        points = {
            alien_kill = 25,
            alien_kill_default = 25,
            alien_kill_by_type = {
                blip = 20,
                cannon_fodder = 5,
                speedy = 25,
                spitter = 50,
                brute = 200
            },
            tile_powered_first_time = 50,
            spawn_point_destroyed = 40,
            civilian_escorted = 0,
            human_escaped_alive = 250,
            win_bonus = 500,
            fail_bonus = 0
        },
        -- Positive-only efficiency reward.
        -- Faster completion earns a larger bonus, never a penalty.
        efficiency = {
            type = "tiered_turn_bonus",
            default_bonus = 50,
            tiers = {
                { max_turns = 8, bonus = 500 },
                { max_turns = 12, bonus = 350 },
                { max_turns = 16, bonus = 200 },
                { max_turns = 20, bonus = 100 }
            }
        }
    },

    escort = {
        id = "escort",
        name = "Escort Survivor",
        points = {
            alien_kill = 20,
            alien_kill_default = 20,
            alien_kill_by_type = {
                blip = 15,
                cannon_fodder = 18,
                speedy = 22,
                spitter = 25,
                brute = 40
            },
            tile_powered_first_time = 15,
            spawn_point_destroyed = 35,
            civilian_escorted = 300,
            human_escaped_alive = 200,
            win_bonus = 450,
            fail_bonus = 0
        },
        efficiency = {
            type = "tiered_turn_bonus",
            default_bonus = 40,
            tiers = {
                { max_turns = 10, bonus = 420 },
                { max_turns = 14, bonus = 280 },
                { max_turns = 18, bonus = 160 }
            }
        }
    },

    holdout = {
        id = "holdout",
        name = "Holdout",
        points = {
            alien_kill = 30,
            alien_kill_default = 30,
            alien_kill_by_type = {
                blip = 24,
                cannon_fodder = 26,
                speedy = 30,
                spitter = 36,
                brute = 60
            },
            tile_powered_first_time = 10,
            spawn_point_destroyed = 25,
            civilian_escorted = 0,
            human_escaped_alive = 0,
            win_bonus = 0,
            fail_bonus = 0
        },
        -- For holdout, surviving longer can contribute score directly.
        holdout = {
            points_per_turn_survived = 40
        },
        efficiency = {
            type = "none",
            default_bonus = 0,
            tiers = {}
        }
    },

    purge_and_power = {
        id = "purge_and_power",
        name = "Purge And Power",
        points = {
            alien_kill = 20,
            alien_kill_default = 20,
            alien_kill_by_type = {
                blip = 15,
                cannon_fodder = 18,
                speedy = 22,
                spitter = 25,
                brute = 45
            },
            tile_powered_first_time = 35,
            spawn_point_destroyed = 180,
            civilian_escorted = 0,
            human_escaped_alive = 0,
            win_bonus = 550,
            fail_bonus = 0
        },
        efficiency = {
            type = "tiered_turn_bonus",
            default_bonus = 35,
            tiers = {
                { max_turns = 12, bonus = 420 },
                { max_turns = 16, bonus = 260 },
                { max_turns = 22, bonus = 120 }
            }
        }
    }
}

function M.get_profile(mission_type)
    local key = mission_type or M.DEFAULT_MISSION_TYPE
    return M.PROFILES[key] or M.PROFILES[M.DEFAULT_MISSION_TYPE]
end

return M
