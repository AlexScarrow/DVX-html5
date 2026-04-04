local M = {}

-- Data-driven comic outro sequence definitions.
--
-- Hook fields supported by main/outro_slideshow.lua:
-- - sequence.soundtrack = { cue = "track_id", stop_on_end = true|false, ... }
-- - shot.start_at = 4.0 (optional absolute sequence time in seconds).
--   If omitted, shots run back-to-back sequentially.
--   If provided, shots can overlap/crossfade.
-- - shot.shake = {
--       amp_x = 6, amp_y = 4, freq_hz = 7.5,
--       start_at = 0.0, end_at = 1.2, decay = true
--   }
-- - shot.layers[] = {
--       {
--           id = "bg",
--           anim = "outro_purge_win_01_bg",
--           draw_w = 1260, draw_h = 720,
--           ease = "in_out_sine",
--           from = { x = 0, y = 0, z = -10, scale = 1.0, scale_x = 1.0, scale_y = 1.0, alpha = 1.0 },
--           to = { x = 0, y = 0, z = -10, scale = 1.04, scale_x = 1.04, scale_y = 1.04, alpha = 1.0 },
--           tint = { 1, 1, 1 }
--       }
--   }
-- - shot.fx_cues[] = {
--       at = 0.0,
--       factory = "/some_fx_factory#some_fx_factory",
--       x = 0, y = 0, z = 0.9,
--       stop_on_shot_end = true|false,
--       stop_on_sequence_end = true|false
--   }
-- - shot.sfx_cues[] = {
--       at = 0.0,
--       cue = "sfx_id",
--       gain = 1.0,
--       pan = 0.0
--   }
--
-- Note: this file only defines data; playback hooks are resolved in game runtime.

M.SEQUENCES = {
    purge_win = {
        soundtrack = {
            cue = "music_outro_purge_win",
            stop_on_end = true
        },
        shots = {
            {
                id = "purge_win_01",
                anim = "outro_purge_win_techie_cockpit",
                duration = 5.7,
                ease = "linear",
                from = { x = 0, y = -1500, z=1, scale_x = 0.5, scale_y = 1.0, alpha = 1.0 },
                to = { x = 0, y = 0, z=1, scale_x = 0.001, scale_y = 0.002, alpha = 1.0 },

                shake = {
                    amp_x = 8,      -- horizontal px
                    amp_y = 5,      -- vertical px
                    freq_hz = 8.0,  -- shake speed
                    start_at = 0.0, -- seconds into shot
                    end_at = 8,   -- seconds into shot
                    decay = true},    -- fades shake out toward end_at
                
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "purge_win_01",
                start_at = 3.4,
                anim = "outro_purge_win_techie_spaceship",
                duration = 2.5,
                ease = "linear",
                from = { x = 0, y = -800, z=2, scale_x = 0.4, scale_y = 0.8, alpha = 1 },
                to = { x = 0, y = 0, z=2, scale_x = 0.001, scale_y = 0.001, alpha = 1 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "purge_win_01",
                start_at = 0,
                anim = "outro_purge_win_space",
                duration = 10,
                ease = "linear",--"in_out_sine",
                from = { x = 0, y = 0, z=0, scale_x = 0.1, scale_y = 0.1, alpha = 1.0 },
                to = { x = 0, y = 0, z=0, scale_x = 0.1, scale_y = 0.1, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "purge_win_01",
                start_at = 0,
                anim = "outro_purge_win_planet",
                duration = 10,
                ease = "linear",--"in_out_sine",
                from = { x = 0, y = 0, z=0.5, scale_x = 0.155, scale_y = 0.3, alpha = 1.0 },
                to = { x = 0, y = 0, z=0.5, scale_x = 0.01, scale_y = 0.02, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "purge_win_01",
                start_at = 7,
                anim = "outro_purge_win_spaceship_passby",
                duration = 3,
                ease = "in_out_sine",--"in_out_sine",
                from = { x = 0, y = 0, z=2, scale_x = 0.002, scale_y = 0.002, alpha = 1.0 },
                to = { x = 3500, y = 300, z=2, scale_x = 0.2, scale_y = 0.4, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "purge_win_01",
                start_at = 7,
                anim = "impactRing",
                duration = 3,
                ease = "in_out_sine",--"in_out_sine",
                from = { x = 0, y = 0, z=2, scale_x = 0.002, scale_y = 0.002, alpha = 1.0 },
                to = { x = 3500, y = 300, z=2, scale_x = 10, scale_y = 20, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "purge_win_01",
                start_at = 8,
                anim = "outro_purge_win_spaceship_fadeBlack",
                duration = 2,
                ease = "linear",--"in_out_sine",
                from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
        }
    },

    rescue_win = {
        soundtrack = {
            cue = "music_outro_purge_win",
            stop_on_end = true
        },
        shots = {
            {
                id = "rescue_win_01",
                anim = "outro_rescue_win_civ_cockpit",
                duration = 5.7,
                ease = "linear",
                from = { x = 0, y = -1500, z=1, scale_x = 0.5, scale_y = 1.0, alpha = 1.0 },
                to = { x = 0, y = 0, z=1, scale_x = 0.001, scale_y = 0.002, alpha = 1.0 },

                shake = {
                    amp_x = 8,      -- horizontal px
                    amp_y = 5,      -- vertical px
                    freq_hz = 8.0,  -- shake speed
                    start_at = 0.0, -- seconds into shot
                    end_at = 8,   -- seconds into shot
                    decay = true},    -- fades shake out toward end_at

                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "rescue_win_01",
                    start_at = 3.4,
                    anim = "outro_rescue_win_civ_spaceship",
                    duration = 2.5,
                    ease = "linear",
                    from = { x = 0, y = -800, z=2, scale_x = 0.4, scale_y = 0.8, alpha = 1 },
                    to = { x = 0, y = 0, z=2, scale_x = 0.001, scale_y = 0.001, alpha = 1 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "rescue_win_01",
                    start_at = 0,
                    anim = "outro_purge_win_space",
                    duration = 10,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=0, scale_x = 0.1, scale_y = 0.1, alpha = 1.0 },
                    to = { x = 0, y = 0, z=0, scale_x = 0.1, scale_y = 0.1, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "rescue_win_01",
                    start_at = 0,
                    anim = "outro_purge_win_planet",
                    duration = 10,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=0.5, scale_x = 0.155, scale_y = 0.3, alpha = 1.0 },
                    to = { x = 0, y = 0, z=0.5, scale_x = 0.01, scale_y = 0.02, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "rescue_win_01",
                    start_at = 7,
                    anim = "outro_rescue_win_civ_spaceship_passby",
                    duration = 3,
                    ease = "in_out_sine",--"in_out_sine",
                    from = { x = 0, y = 0, z=2, scale_x = 0.002, scale_y = 0.002, alpha = 1.0 },
                    to = { x = 3500, y = 300, z=2, scale_x = 0.2, scale_y = 0.4, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "rescue_win_01",
                    start_at = 7,
                    anim = "impactRing",
                    duration = 3,
                    ease = "in_out_sine",--"in_out_sine",
                    from = { x = 0, y = 0, z=2, scale_x = 0.002, scale_y = 0.002, alpha = 1.0 },
                    to = { x = 3500, y = 300, z=2, scale_x = 10, scale_y = 20, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "rescue_win_01",
                    start_at = 8,
                    anim = "outro_purge_win_spaceship_fadeBlack",
                    duration = 2,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                    to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
            }
        },
    -- purge_lose = {
    --     soundtrack = {
    --         cue = "music_outro_purge_lose",
    --         stop_on_end = true
    --     },
    --     shots = {
    --         {
    --             id = "purge_lose_01",
    --             anim = "outro_purge_lose_01",
    --             duration = 2.6,
    --             ease = "in_out_sine",
    --             from = { x = 0, y = 0, z = 2, scale = 1.0, alpha = 0.0 },
    --             to = { x = 0, y = 0, z=2, scale = 1.04, alpha = 1.0 },
    --             fx_cues = {},
    --             sfx_cues = {}
    --         }
    --     }
    -- }
}

function M.get_sequence(sequence_id)
    return M.SEQUENCES[tostring(sequence_id or "")]
end

return M
