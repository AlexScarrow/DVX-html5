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
--           from = { x = 0, y = 0, z = -10, rotation_deg = 0, scale = 1.0, scale_x = 1.0, scale_y = 1.0, alpha = 1.0 },
--           to = { x = 0, y = 0, z = -10, rotation_deg = 0, scale = 1.04, scale_x = 1.04, scale_y = 1.04, alpha = 1.0 },
--           rotation_ping_pong = false,
--           rotation_freq_hz = 1.0,
--           tint = { 1, 1, 1 }
--       }
--   }
-- - shot.fx_cues[] = {
--       at = 0.0,
--       factory = "/some_fx_factory#some_fx_factory",
--       x = 0, y = 0, z = 0.9,
--       from = { x = 0, y = -40, z = 0.9 }, -- optional animated offset start
--       to = { x = 0, y = 120, z = 0.9 },   -- optional animated offset end
--       move_duration = 2.0,                 -- optional seconds (defaults to shot remainder)
--       ease = "linear",                     -- optional easing for motion path
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

-----------------------------------------PURGE WIN--------------------------------------------

    purge_win = {
        soundtrack = {
            cue = "music_outro_purge_win",
            stop_on_end = true
        },
        shots = {
            {
                id = "purge_win_01",
                start_at = 0,
                anim = "outro_purge_win_spaceship_fadeBlack",
                duration = 2,
                ease = "linear",--"in_out_sine",
                from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "purge_win_02",
                start_at = 0,
                anim = "backdrop_computer",
                duration = 5,
                ease = "linear",
                from = { x = 0, y = 0, z=1, scale_x = 0.075, scale_y = 0.15, alpha = 1 },
                to = { x = 0, y = -50, z=1, scale_x = 0.075, scale_y = 0.15, alpha = 1 },
                --fx_cues = {},
                shake = {
                    amp_x = 2,      -- horizontal px
                    amp_y = 1,      -- vertical px
                    freq_hz = 8.0,  -- shake speed
                    start_at = 0.0, -- seconds into shot
                    end_at = 5,   -- seconds into shot
                    decay = false},    -- fades shake out toward end_at

                    --fx_cues = {},
                    --sfx_cues = {}
                    --},
                    sfx_cues = {}
            },
            {
                    id = "purge_win_03",
                    start_at = 0,
                    anim = "outro_arrive_outside_base_entry",
                    duration = 5,
                    ease = "linear",
                    from = { x = 0, y = 0, z=2, scale_x = 0.065, scale_y = 0.1, alpha = 1 },
                    to = { x = 0, y = -100, z=2, scale_x = 0.065, scale_y = 0.1, alpha = 1 },
                    --fx_cues = {},
                    sfx_cues = {}
            },
            {
                    id = "purge_win_04",
                    start_at = 0,
                    anim = "outro_purge_win_techie_spaceship",
                    duration = 5,
                    ease = "in_quad",
                    from = { x = 50, y = -100, z = 1.5, rotation_deg = -4, scale_x = 0.025, scale_y = 0.05, alpha = 1 },
                    to   = { x = 50, y =  600, z = 1.5, rotation_deg =  2, scale_x = 0.025, scale_y = 0.05, alpha = 1 },
                    rotation_ping_pong = true,
                    rotation_freq_hz = 0.5,
                    --fx_cues = {},
                    fx_cues = {
                        {
                            at = 0.0, -- seconds into this shot
                            factory = "/spaceship_launch_thruster_fx_factory#spaceship_launch_thruster_fx_factory",
                            from = { x = 50, y = -300, z = 2.5 }, -- start under ship
                            to =   { x = 50, y = 320,  z = 2.5 }, -- rise with ship
                            move_duration = 5.0,                  -- match shot movement
                            ease = "in_quad",
                            rotation_deg = 0,
                            stop_on_shot_end = true,
                        },
                    },
                    sfx_cues = {}
            },
            {
                    id = "purge_win_05",
                    start_at = 4,
                    anim = "outro_purge_win_spaceship_fadeBlack",
                    duration = 1,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                    to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
            },
            {
                    id = "purge_win_06",
                    start_at = 5,
                    anim = "outro_purge_win_spaceship_fadeBlack",
                    duration = 2,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                    to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                    --fx_cues = {},
                    sfx_cues = {}
            },  
            {
                    id = "purge_win_07",
                    start_at = 5,
                    anim = "outro_purge_win_space",
                    duration = 10,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=0, scale_x = 0.1, scale_y = 0.1, alpha = 1.0 },
                    to = { x = 0, y = 0, z=0, scale_x = 0.1, scale_y = 0.1, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
            },
            {
                    id = "purge_win_08",
                    start_at = 5,
                    anim = "outro_purge_win_planet",
                    duration = 10,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=0.5, rotation_deg = 0, scale_x = 0.05, scale_y = 0.1, alpha = 1.0 },
                    to = { x = 0, y = 0, z=0.5, rotation_deg = 0, scale_x = 0.05, scale_y = 0.1, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
            },
            {
                    id = "purge_win_09",
                    start_at = 6,
                    anim = "outro_purge_win_spaceship_passby",
                    duration = 3,
                    ease = "in_out_sine",--"in_out_sine",
                    from = { x = -350, y = 0, z=2, scale_x = 0.002, scale_y = 0.002, alpha = 1.0 },
                    to = { x = 3500, y = 300, z=2, scale_x = 0.2, scale_y = 0.4, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
            },
            {
                    id = "purge_win_10",
                    start_at = 6,
                    anim = "impactRing",
                    duration = 3,
                    ease = "in_out_sine",--"in_out_sine",
                    from = { x = -350, y = 0, z=2, scale_x = 0.002, scale_y = 0.002, alpha = 1.0 },
                    to = { x = 3500, y = 300, z=2, scale_x = 10, scale_y = 20, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
            },
            {
                id = "purge_win_11",
                start_at = 10,
                anim = "outro_mushroom_cloud",
                duration = 3,
                ease = "out_quad",--"in_out_sine",
                from = { x = -375, y = 0, z=1, rotation_deg =90, scale_x = 0.001, scale_y = 0.001, alpha = 1.0 },
                to = { x = -415, y = 0, z=1, rotation_deg =90, scale_x = 0.01, scale_y = 0.05, alpha = 0.0 },
                --fx_cues = {},
                sfx_cues = {}
            },    
            {
                id = "purge_win_12",
                start_at = 10,
                anim = "outro_mushroom_cloud_ring",
                duration = 1,
                ease = "out_quad",--"in_out_sine",
                from = { x = -375, y = 0, z=1, rotation_deg =90, scale_x = 0.001, scale_y = 0.001, alpha = 1.0 },
                to = { x = -375, y = 0, z=1, rotation_deg =90, scale_x = 0.05, scale_y = 0.05, alpha = 0.0 },
                --fx_cues = {},
                sfx_cues = {}
            },    
            {
                    id = "purge_win_13",
                    start_at = 10,
                    anim = "outro_purge_win_spaceship_fadeBlack",
                    duration = 5,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                    to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
            },
        } --END OF SHOTS       
    }, --END OF OUTRO (purge_win)

    -----------------------------------------RESCUE WIN--------------------------------------------
    rescue_win = {
        soundtrack = {
            cue = "music_outro_purge_win",
            stop_on_end = true
        },
        shots = {
            {
                id = "dna_win_01",
                start_at = 0,
                anim = "outro_purge_win_spaceship_fadeBlack",
                duration = 2,
                ease = "linear",--"in_out_sine",
                from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "dna_win_02",
                start_at = 0,
                anim = "backdrop_computer",
                duration = 5,
                ease = "linear",
                from = { x = 0, y = 0, z=1, scale_x = 0.075, scale_y = 0.15, alpha = 1 },
                to = { x = 0, y = -50, z=1, scale_x = 0.075, scale_y = 0.15, alpha = 1 },
                --fx_cues = {},
                shake = {
                    amp_x = 2,      -- horizontal px
                    amp_y = 1,      -- vertical px
                    freq_hz = 8.0,  -- shake speed
                    start_at = 0.0, -- seconds into shot
                    end_at = 5,   -- seconds into shot
                    decay = false},    -- fades shake out toward end_at

                    --fx_cues = {},
                    --sfx_cues = {}
                    --},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_03",
                    start_at = 0,
                    anim = "outro_arrive_outside_base_entry",
                    duration = 5,
                    ease = "linear",
                    from = { x = 0, y = 0, z=2, scale_x = 0.065, scale_y = 0.1, alpha = 1 },
                    to = { x = 0, y = -100, z=2, scale_x = 0.065, scale_y = 0.1, alpha = 1 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_04",
                    start_at = 0,
                    anim = "outro_purge_win_techie_spaceship",
                    duration = 5,
                    ease = "in_quad",
                    from = { x = 50, y = -100, z = 1.5, rotation_deg = -4, scale_x = 0.025, scale_y = 0.05, alpha = 1 },
                    to   = { x = 50, y =  600, z = 1.5, rotation_deg =  2, scale_x = 0.025, scale_y = 0.05, alpha = 1 },
                    rotation_ping_pong = true,
                    rotation_freq_hz = 0.5,
                    --fx_cues = {},
                    fx_cues = {
                        {
                            at = 0.0, -- seconds into this shot
                            factory = "/spaceship_launch_thruster_fx_factory#spaceship_launch_thruster_fx_factory",
                            from = { x = 50, y = -300, z = 2.5 }, -- start under ship
                            to =   { x = 50, y = 320,  z = 2.5 }, -- rise with ship
                            move_duration = 5.0,                  -- match shot movement
                            ease = "in_quad",
                            rotation_deg = 0,
                            stop_on_shot_end = true,
                        },
                    },
                    sfx_cues = {}
                },
                {
                    id = "dna_win_05",
                    start_at = 4,
                    anim = "outro_purge_win_spaceship_fadeBlack",
                    duration = 1,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                    to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_06",
                    start_at = 5,
                    anim = "outro_purge_win_spaceship_fadeBlack",
                    duration = 2,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                    to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                --   
                {
                    id = "dna_win_07",
                    start_at = 5,
                    anim = "outro_purge_win_space",
                    duration = 10,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=0, scale_x = 0.1, scale_y = 0.1, alpha = 1.0 },
                    to = { x = 0, y = 0, z=0, scale_x = 0.1, scale_y = 0.1, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_08",
                    start_at = 5,
                    anim = "outro_purge_win_planet",
                    duration = 10,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=0.5, scale_x = 0.155, scale_y = 0.3, alpha = 1.0 },
                    to = { x = 0, y = 0, z=0.5, scale_x = 0.01, scale_y = 0.02, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_09",
                    start_at = 6,
                    anim = "outro_purge_win_spaceship_passby",
                    duration = 3,
                    ease = "in_out_sine",--"in_out_sine",
                    from = { x = 0, y = 0, z=2, scale_x = 0.002, scale_y = 0.002, alpha = 1.0 },
                    to = { x = 3500, y = 300, z=2, scale_x = 0.2, scale_y = 0.4, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_10",
                    start_at = 6,
                    anim = "impactRing",
                    duration = 3,
                    ease = "in_out_sine",--"in_out_sine",
                    from = { x = 0, y = 0, z=2, scale_x = 0.002, scale_y = 0.002, alpha = 1.0 },
                    to = { x = 3500, y = 300, z=2, scale_x = 10, scale_y = 20, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_11",
                    start_at = 10,
                    anim = "outro_purge_win_spaceship_fadeBlack",
                    duration = 5,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                    to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
            } --END OF SHOTS
        }, -- END OF OUTRO (dna_sample_win)
   

    -----------------------------------------DNA_SAMPLE WIN--------------------------------------------

    dna_sample_win = {
        soundtrack = {
            cue = "music_outro_purge_win",
            stop_on_end = true
        },
        shots = {
            {
                id = "dna_win_01",
                start_at = 0,
                anim = "outro_purge_win_spaceship_fadeBlack",
                duration = 2,
                ease = "linear",--"in_out_sine",
                from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "dna_win_02",
                start_at = 0,
                anim = "backdrop_computer",
                duration = 5,
                ease = "linear",
                from = { x = 0, y = 0, z=1, scale_x = 0.075, scale_y = 0.15, alpha = 1 },
                to = { x = 0, y = -50, z=1, scale_x = 0.075, scale_y = 0.15, alpha = 1 },
                --fx_cues = {},
                shake = {
                    amp_x = 2,      -- horizontal px
                    amp_y = 1,      -- vertical px
                    freq_hz = 8.0,  -- shake speed
                    start_at = 0.0, -- seconds into shot
                    end_at = 5,   -- seconds into shot
                    decay = false},    -- fades shake out toward end_at

                    --fx_cues = {},
                    --sfx_cues = {}
                    --},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_03",
                    start_at = 0,
                    anim = "outro_arrive_outside_base_entry",
                    duration = 5,
                    ease = "linear",
                    from = { x = 0, y = 0, z=2, scale_x = 0.065, scale_y = 0.1, alpha = 1 },
                    to = { x = 0, y = -100, z=2, scale_x = 0.065, scale_y = 0.1, alpha = 1 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_04",
                    start_at = 0,
                    anim = "outro_purge_win_techie_spaceship",
                    duration = 5,
                    ease = "in_quad",
                    from = { x = 50, y = -100, z = 1.5, rotation_deg = -4, scale_x = 0.025, scale_y = 0.05, alpha = 1 },
                    to   = { x = 50, y =  600, z = 1.5, rotation_deg =  2, scale_x = 0.025, scale_y = 0.05, alpha = 1 },
                    rotation_ping_pong = true,
                    rotation_freq_hz = 0.5,
                    --fx_cues = {},
                    fx_cues = {
                        {
                            at = 0.0, -- seconds into this shot
                            factory = "/spaceship_launch_thruster_fx_factory#spaceship_launch_thruster_fx_factory",
                            from = { x = 50, y = -300, z = 2.5 }, -- start under ship
                            to =   { x = 50, y = 320,  z = 2.5 }, -- rise with ship
                            move_duration = 5.0,                  -- match shot movement
                            ease = "in_quad",
                            rotation_deg = 0,
                            stop_on_shot_end = true,
                        },
                    },
                    sfx_cues = {}
                },
                {
                    id = "dna_win_05",
                    start_at = 4,
                    anim = "outro_purge_win_spaceship_fadeBlack",
                    duration = 1,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                    to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_06",
                    start_at = 5,
                    anim = "outro_purge_win_spaceship_fadeBlack",
                    duration = 2,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                    to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                --   
                {
                    id = "dna_win_07",
                    start_at = 5,
                    anim = "outro_purge_win_space",
                    duration = 10,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=0, scale_x = 0.1, scale_y = 0.1, alpha = 1.0 },
                    to = { x = 0, y = 0, z=0, scale_x = 0.1, scale_y = 0.1, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_08",
                    start_at = 5,
                    anim = "outro_purge_win_planet",
                    duration = 10,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=0.5, scale_x = 0.155, scale_y = 0.3, alpha = 1.0 },
                    to = { x = 0, y = 0, z=0.5, scale_x = 0.01, scale_y = 0.02, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_09",
                    start_at = 6,
                    anim = "outro_purge_win_spaceship_passby",
                    duration = 3,
                    ease = "in_out_sine",--"in_out_sine",
                    from = { x = 0, y = 0, z=2, scale_x = 0.002, scale_y = 0.002, alpha = 1.0 },
                    to = { x = 3500, y = 300, z=2, scale_x = 0.2, scale_y = 0.4, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_10",
                    start_at = 6,
                    anim = "impactRing",
                    duration = 3,
                    ease = "in_out_sine",--"in_out_sine",
                    from = { x = 0, y = 0, z=2, scale_x = 0.002, scale_y = 0.002, alpha = 1.0 },
                    to = { x = 3500, y = 300, z=2, scale_x = 10, scale_y = 20, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
                {
                    id = "dna_win_11",
                    start_at = 10,
                    anim = "outro_purge_win_spaceship_fadeBlack",
                    duration = 5,
                    ease = "linear",--"in_out_sine",
                    from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                    to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                    --fx_cues = {},
                    sfx_cues = {}
                },
            } --END OF SHOTS
        }, -- END OF OUTRO (dna_sample_win)

-----------------------------------------ESCAPE WIN--------------------------------------------
escape_win = {
    soundtrack = {
        cue = "music_outro_purge_win",
        stop_on_end = true
    },
    shots = {
        {
            id = "escape_win_00",
            start_at = 0,
            anim = "outro_purge_win_spaceship_fadeBlack",
            duration = 2,
            ease = "linear",--"in_out_sine",
            from = { x = 0, y = 0, z=3.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
            to = { x = 0, y = 0, z=3.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
            --fx_cues = {},
            sfx_cues = {}
        },
        {
            id = "escape_win_01",
            start_at = 0,
            anim = "outro_rescue_win_ground_hole",
            duration = 10,
            ease = "linear",--"in_out_sine",
            from = { x = 0, y = -50, z=2.2, scale_x = 0.06, scale_y = 0.09, alpha = 1.0 },
            to = { x = 0, y = -50, z=2.2, scale_x = 0.08, scale_y = 0.14, alpha = 1.0 },

            --fx_cues = {},
            fx_cues = {
                -- {
                --     at = 2,
                --     factory = "/rocket_hole_fx_factory#rocket_hole_fx_factory",
                --     x = 0,
                --     y = 0,
                --     z = 2.2,
                --     stop_on_shot_end = true
                -- }
            },
            sfx_cues = {}
        },
        {
            id = "escape_win_02",
            start_at = 0,
            anim = "outro_rescue_win_ground_hole_hatch",
            duration = 10,
            ease = "in_out_sine",
            from = { x = 350, y =-70, z=2, scale_x = 0.1, scale_y = 0.1, alpha = 1 },
            to = { x = 800, y = -70, z=2, scale_x = 0.1, scale_y = 0.1, alpha = 1 },
            --fx_cues = {},
            sfx_cues = {}
        },
        {
            id = "escape_win_03",
            start_at = 0,
            anim = "outro_rescue_win_ground_hole_hatch",
            duration = 10,
            ease = "in_out_sine",
            from = { x = -250, y =-70, z=2, scale_x = 0.1, scale_y = 0.1, alpha = 1 },
            to = { x = -800, y = -70, z=2, scale_x = 0.1, scale_y = 0.1, alpha = 1 },
            --fx_cues = {},
            sfx_cues = {}
        },
        {
            id = "escape_win_04",
            start_at = 0,
            anim = "outro_rescue_win_ground_hole_glow",
            duration = 10,
            ease = "linear",--"in_out_sine",
            from = { x = 0, y = -50, z=1.5, scale_x = 1, scale_y = 1, alpha = 1.0 },
            to = { x = 0, y = -50, z=1.5, scale_x = 1, scale_y = 1, alpha = 1.0 },
            --fx_cues = {},
            sfx_cues = {}
        },
        -------------
        {
            id = "escape_win_05",
            start_at = 10,
            anim = "outro_rescue_win_civ_cockpit",
            duration = 8,
            ease = "linear",
            from = { x = 0, y = -1500, z=1, scale_x = 0.35, scale_y = 0.7, alpha = 1.0 },
            to = { x = 0, y = 0, z=1, scale_x = 0.00002, scale_y = 0.00003, alpha = 1.0 },

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
                id = "escape_win_06",
                start_at = 11.4,
                anim = "outro_rescue_win_civ_spaceship",
                duration = 6.6,
                ease = "linear",
                from = { x = 50, y = -800, z=2, scale_x = 0.4, scale_y = 0.8, alpha = 1 },
                to = { x = 0, y = 0, z=2, scale_x = 0.0005, scale_y = 0.001, alpha = 1 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "escape_win_07",
                start_at = 17.9,
                anim = "impactRing",
                duration = 2,
                ease = "in_out_sine",--"in_out_sine",
                from = { x = 0, y = 0, z=2, scale_x = 0.002, scale_y = 0.002, alpha = 1.0 },
                to = { x = 0, y = 0, z=1, scale_x = 15, scale_y = 30, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "escape_win_072",
                start_at = 18.5,
                anim = "outro_rescue_win_civ_spaceship",
                duration = 1,
                ease = "linear",
                from = { x = 0, y = 0, z=2, scale_x = 0.005, scale_y = 0.01, alpha = 1 },
                to = { x = 0, y = 0, z=2, scale_x = 0.4, scale_y = 0.8, alpha = 1 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "escape_win_05",
                start_at = 18.5,
                anim = "outro_rescue_win_civ_cockpit",
                duration = 1,
                ease = "linear",
                from = { x = 0, y = 0, z=1, scale_x = 0.0002, scale_y = 0.0003, alpha = 1.0 },
                to = { x = -50, y = 0, z=1, scale_x = 0.35, scale_y = 0.7, alpha = 1.0 },
                },
            {
                id = "escape_win_08",
                start_at = 11,
                anim = "outro_top_down_landscape",
                duration = 14,
                ease = "linear",--"in_out_sine",
                from = { x = 0, y = 0, z=0.5, rotation_deg = 0, scale_x = 0.8, scale_y = 1, alpha = 1.0 },
                to = { x = 0, y = 0, z=0.5, rotation_deg = -45, scale_x = 0.15, scale_y = 0.2, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "escape_win_09",
                start_at = 22,
                anim = "outro_purge_win_spaceship_fadeBlack",
                duration = 3,
                ease = "linear",--"in_out_sine",
                from = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 0.0 },
                to = { x = 0, y = 0, z=2.1, scale_x = 10, scale_y = 10, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
        },
    },

    -----------------------------------------PURGE LOSE--------------------------------------------

    lose = {
        soundtrack = {
            cue = "music_outro_purge_win",
            stop_on_end = true
        },
        shots = {
            {
                id = "lose_01",
                start_at = 0,
                anim = "outro_purge_win_spaceship_fadeBlack",
                duration = 2,
                ease = "linear",--"in_out_sine",
                from = { x = 0, y = 0, z=3, scale_x = 10, scale_y = 10, alpha = 1.0 },
                to = { x = 0, y = 0, z=3, scale_x = 10, scale_y = 10, alpha = 0.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "lose_02",
                start_at = 2,
                anim = "sweep_shadow",
                duration = 2,
                ease = "linear",
                from = { x = -1000, y = 0, z = 4, scale_x = 0.8, scale_y = 1, alpha = 0.75 },
                to = { x = 700, y = 0, z = 4, scale_x = 0.8, scale_y = 1, alpha = 0.75 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "lose_03",
                start_at = 0,
                anim = "outro_dying_derple",
                duration = 6,
                ease = "in_out_sine",
                from = { x = 0, y = -350, z = 2.2, scale_x = 0.2, scale_y = 0.350, alpha = 1.0 },
                to = { x = 0, y = 0, z = 2.2, scale_x = 0.05, scale_y = 0.087, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "lose_04",
                start_at = 0,
                anim = "outro_dying_derple_eyes",
                duration = 6,
                ease = "in_out_sine",
                from = { x = 0, y = -350, z = 1.8, scale_x = 0.2, scale_y = 0.350, alpha = 1.0 },
                to = { x = 0, y = 0, z = 1.8, scale_x = 0.05, scale_y = 0.087, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            {
                id = "lose_05",
                start_at = 0,
                anim = "outro_dying_derple_eyelids",
                duration = 6,
                ease = "in_out_sine",
                from = { x = 0, y = -250, z = 1.9, scale_x = 0.2, scale_y = 0.350, alpha = 1.0 },
                to = { x = 0, y = -50, z = 1.9, scale_x = 0.05, scale_y = 0.087, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
            -- {
            --     id = "lose_05b",
            --     start_at = 3,
            --     anim = "outro_dying_derple_eyelids",
            --     duration = 3,
            --     ease = "in_out_sine",
            --     from = { x = 0, y = -50, z = 1.9, scale_x = 0.2, scale_y = 0.350, alpha = 1.0 },
            --     to = { x = 0, y = -250, z = 1.9, scale_x = 0.05, scale_y = 0.087, alpha = 1.0 },
            --     --fx_cues = {},
            --     sfx_cues = {}
            -- },
            {
                id = "lose_06",
                start_at = 4,
                anim = "outro_purge_win_spaceship_fadeBlack",
                duration = 2,
                ease = "linear",--"in_out_sine",
                from = { x = 0, y = 0, z=3, scale_x = 10, scale_y = 10, alpha = 0.0 },
                to = { x = 0, y = 0, z=3, scale_x = 10, scale_y = 10, alpha = 1.0 },
                --fx_cues = {},
                sfx_cues = {}
            },
        } --END OF SHOTS
    }, -- END OF OUTRO (lose)

    
-----------------------------------------RESCUE LOSE--------------------------------------------         
-----------------------------------------DNA_SAMPLE LOSE--------------------------------------------
-----------------------------------------ESCAPE LOSE--------------------------------------------
-----------------------------------------TITLE--------------------------------------------

title = {
    soundtrack = {
        cue = "music_outro_purge_win",
        stop_on_end = true
    },
    shots = {
        {
            id = "title_01",
            start_at = 0,
            anim = "outro_purge_win_spaceship_fadeBlack",
            duration = 2,
            ease = "linear",--"in_out_sine",
            from = { x = 0, y = 0, z=3, scale_x = 10, scale_y = 10, alpha = 1.0 },
            to = { x = 0, y = 0, z=3, scale_x = 10, scale_y = 10, alpha = 0.0 },
            --fx_cues = {},
            sfx_cues = {}
        },
        {
            id = "title_02",
            start_at = 0,
            anim = "outro_purge_win_space",
            duration = 20,
            ease = "linear",
            from = { x = 0, y = 0, z = 1, scale_x = 1, scale_y = 1, alpha = 1 },
            to = { x = 0, y = 0, z = 1, scale_x = 1, scale_y = 1, alpha = 1 },
            --fx_cues = {},
            sfx_cues = {}
        },
        {
            id = "title_03",
            start_at = 0,
            anim = "outro_title_aliens_lines",
            duration = 6,
            ease = "in_out_sine",
            from = { x = 0, y = 0, z = 2, scale_x = 1, scale_y = 1, alpha = 1.0 },
            to = { x = 0, y = 0, z = 2, scale_x = 1, scale_y = 1, alpha = 1.0 },
            --fx_cues = {},
            sfx_cues = {}
        },
        {
            id = "title_04",
            start_at = 6,
            anim = "outro_title_xenos_word",
            duration = 12,
            ease = "in_out_sine",
            from = { x = 0, y = 0, z = 1.8, scale_x = 1, scale_y = 1, alpha = 0 },
            to = { x = 0, y = 0, z = 1.8, scale_x = 1, scale_y = 1, alpha = 1.0 },
            --fx_cues = {},
            sfx_cues = {}
        },
        -- {
        --     id = "lose_05",
        --     start_at = 0,
        --     anim = "outro_dying_derple_eyelids",
        --     duration = 6,
        --     ease = "in_out_sine",
        --     from = { x = 0, y = -250, z = 1.9, scale_x = 0.2, scale_y = 0.350, alpha = 1.0 },
        --     to = { x = 0, y = -50, z = 1.9, scale_x = 0.05, scale_y = 0.087, alpha = 1.0 },
        --     --fx_cues = {},
        --     sfx_cues = {}
        -- },
        -- {
        --     id = "lose_05b",
        --     start_at = 3,
        --     anim = "outro_dying_derple_eyelids",
        --     duration = 3,
        --     ease = "in_out_sine",
        --     from = { x = 0, y = -50, z = 1.9, scale_x = 0.2, scale_y = 0.350, alpha = 1.0 },
        --     to = { x = 0, y = -250, z = 1.9, scale_x = 0.05, scale_y = 0.087, alpha = 1.0 },
        --     --fx_cues = {},
        --     sfx_cues = {}
        -- },
        -- {
        --     id = "lose_06",
        --     start_at = 4,
        --     anim = "outro_purge_win_spaceship_fadeBlack",
        --     duration = 2,
        --     ease = "linear",--"in_out_sine",
        --     from = { x = 0, y = 0, z=3, scale_x = 10, scale_y = 10, alpha = 0.0 },
        --     to = { x = 0, y = 0, z=3, scale_x = 10, scale_y = 10, alpha = 1.0 },
        --     --fx_cues = {},
        --     sfx_cues = {}
        -- },
    } --END OF SHOTS
}, -- END OF OUTRO (lose)

    
} --END OF OUTRO SEQENCES (list of outros

-- Mission-specific lose IDs map to the shared lose sequence.
M.SEQUENCES.purge_lose = M.SEQUENCES.lose
M.SEQUENCES.rescue_lose = M.SEQUENCES.lose
M.SEQUENCES.dna_sample_lose = M.SEQUENCES.lose
M.SEQUENCES.escape_lose = M.SEQUENCES.lose

local function ensure_rotation_defaults(shot)
    if type(shot) ~= "table" then
        return
    end
    shot.from = shot.from or {}
    shot["to"] = shot["to"] or {}
    if shot.from.rotation_deg == nil then shot.from.rotation_deg = 0 end
    if shot["to"].rotation_deg == nil then shot["to"].rotation_deg = 0 end
    if shot.rotation_ping_pong == nil then shot.rotation_ping_pong = false end
    if shot.rotation_freq_hz == nil then shot.rotation_freq_hz = 1 end
    local layers = shot.layers
    if type(layers) ~= "table" then
        return
    end
    for _, layer in ipairs(layers) do
        if type(layer) == "table" then
            layer.from = layer.from or {}
            layer["to"] = layer["to"] or {}
            if layer.from.rotation_deg == nil then layer.from.rotation_deg = 0 end
            if layer["to"].rotation_deg == nil then layer["to"].rotation_deg = 0 end
            if layer.rotation_ping_pong == nil then layer.rotation_ping_pong = false end
            if layer.rotation_freq_hz == nil then layer.rotation_freq_hz = 1 end
        end
    end
end

for _, sequence in pairs(M.SEQUENCES) do
    local shots = sequence and sequence.shots or nil
    if type(shots) == "table" then
        for _, shot in ipairs(shots) do
            ensure_rotation_defaults(shot)
        end
    end
end


----------------------------------------------------------------------------------------------



----USE THIS AS PART OF RESCUE WIN
--             {
--                 id = "rescue_win_01",
--                 start_at = 5,
--                 anim = "outro_rescue_win_civ_cockpit",
--                 duration = 5.7,
--                 ease = "linear",
--                 from = { x = 0, y = -1500, z=1, scale_x = 0.5, scale_y = 1.0, alpha = 1.0 },
--                 to = { x = 0, y = 0, z=1, scale_x = 0.001, scale_y = 0.002, alpha = 1.0 },
-- 
--                 shake = {
--                     amp_x = 8,      -- horizontal px
--                     amp_y = 5,      -- vertical px
--                     freq_hz = 8.0,  -- shake speed
--                     start_at = 0.0, -- seconds into shot
--                     end_at = 8,   -- seconds into shot
--                     decay = true},    -- fades shake out toward end_at
-- 
--                     --fx_cues = {},
--                     sfx_cues = {}
--                 },
--                 {
--                     id = "rescue_win_01",
--                     start_at = 6.4,
--                     anim = "outro_rescue_win_civ_spaceship",
--                     duration = 2.5,
--                     ease = "linear",
--                     from = { x = 0, y = -800, z=2, scale_x = 0.4, scale_y = 0.8, alpha = 1 },
--                     to = { x = 0, y = 0, z=2, scale_x = 0.001, scale_y = 0.001, alpha = 1 },
--                     --fx_cues = {},
--                     sfx_cues = {}
--                 },






function M.get_sequence(sequence_id)
    return M.SEQUENCES[tostring(sequence_id or "")]
end

return M
