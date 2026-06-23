local M = {}

local SCREEN_W = 1280
local SCREEN_H = 720
local IMAGE_W = 1280
local IMAGE_H = 720
local DEFAULT_DURATION = 8.0
local DEFAULT_START_ZOOM = 1.22
local DEFAULT_END_ZOOM = 1.0
local DEFAULT_ZOOM_RESOLVE_FRACTION = 0.3
local DEFAULT_TINT_PULSE_SPEED = 0.9
local DEFAULT_TINT_PULSE_MIN = 0.82
local DEFAULT_TINT_PULSE_MAX = 1.28

local PLATES = {
    escape_win = {
        anim = "Outro_GraphicNovelStyle_win_escape",
        focal_x = 0.52,
        focal_y = 0.46,
        shake_amp_x = 3.0,
        shake_amp_y = 1.8
    },
    lose = {
        anim = "Outro_GraphicNovelStyle_lose",
        focal_x = 0.50,
        focal_y = 0.50,
        shake_amp_x = 2.0,
        shake_amp_y = 1.3
    },
    rescue_win = {
        anim = "Outro_GraphicNovelStyle_win_rescue_holdout",
        focal_x = 0.48,
        focal_y = 0.48,
        shake_amp_x = 2.5,
        shake_amp_y = 1.6
    },
    dna_sample_win = {
        anim = "Outro_GraphicNovelStyle_win_rescue_holdout",
        focal_x = 0.48,
        focal_y = 0.48,
        shake_amp_x = 2.5,
        shake_amp_y = 1.6
    },
    holdout_win = {
        anim = "Outro_GraphicNovelStyle_win_rescue_holdout",
        focal_x = 0.48,
        focal_y = 0.48,
        shake_amp_x = 2.5,
        shake_amp_y = 1.6
    },
    purge_win = {
        anim = "Outro_GraphicNovelStyle_win_purge_cleanse",
        focal_x = 0.50,
        focal_y = 0.46,
        shake_amp_x = 3.6,
        shake_amp_y = 2.2
    },
    cleanse_win = {
        anim = "Outro_GraphicNovelStyle_win_purge_cleanse",
        focal_x = 0.50,
        focal_y = 0.46,
        shake_amp_x = 3.6,
        shake_amp_y = 2.2
    }
}

PLATES.purge_lose = PLATES.lose
PLATES.cleanse_lose = PLATES.lose
PLATES.rescue_lose = PLATES.lose
PLATES.dna_sample_lose = PLATES.lose
PLATES.escape_lose = PLATES.lose
PLATES.holdout_lose = PLATES.lose

local function clamp01(v)
    if v < 0 then
        return 0
    end
    if v > 1 then
        return 1
    end
    return v
end

local function lerp(a, b, t)
    return a + ((b - a) * t)
end

local function ease_out_quad(t)
    local x = clamp01(t)
    local inv = 1 - x
    return 1 - (inv * inv)
end

local function resolve_plate(sequence_id)
    local key = tostring(sequence_id or "")
    return PLATES[key] or PLATES.lose
end

local function build_pose(state)
    local plate = state.plate
    local p = clamp01((state.elapsed or 0) / math.max(0.001, state.duration or DEFAULT_DURATION))
    local zoom_p = clamp01(p / math.max(0.001, tonumber(plate.zoom_resolve_fraction or DEFAULT_ZOOM_RESOLVE_FRACTION) or DEFAULT_ZOOM_RESOLVE_FRACTION))
    local eased = ease_out_quad(zoom_p)
    local cover_scale = math.max(SCREEN_W / IMAGE_W, SCREEN_H / IMAGE_H)
    local start_scale = cover_scale * (tonumber(plate.start_zoom or DEFAULT_START_ZOOM) or DEFAULT_START_ZOOM)
    local end_scale = cover_scale * (tonumber(plate.end_zoom or DEFAULT_END_ZOOM) or DEFAULT_END_ZOOM)
    local draw_scale = lerp(start_scale, end_scale, eased)
    local center_x = SCREEN_W * 0.5
    local center_y = SCREEN_H * 0.5
    local focal_x = tonumber(plate.focal_x or 0.5) or 0.5
    local focal_y = tonumber(plate.focal_y or 0.5) or 0.5
    local focus_center_x = center_x - ((focal_x - 0.5) * IMAGE_W * start_scale)
    local focus_center_y = center_y - ((focal_y - 0.5) * IMAGE_H * start_scale)
    local x = lerp(focus_center_x, center_x, eased)
    local y = lerp(focus_center_y, center_y, eased)
    local shake_decay = 1 - p
    local shake_phase = (state.elapsed or 0) * math.pi * 2 * 7.5
    local shake_x = math.sin(shake_phase + (state.phase_x or 0)) * (tonumber(plate.shake_amp_x or 0) or 0) * shake_decay
    local shake_y = math.cos((shake_phase * 0.91) + (state.phase_y or 0)) * (tonumber(plate.shake_amp_y or 0) or 0) * shake_decay
    local tint_wave = 0.5 + (0.5 * math.sin(((state.elapsed or 0) * math.pi * 2 * DEFAULT_TINT_PULSE_SPEED) + (state.tint_phase or 0)))
    local tint_mul = lerp(DEFAULT_TINT_PULSE_MIN, DEFAULT_TINT_PULSE_MAX, tint_wave)
    return {
        anim = plate.anim,
        x = x + shake_x,
        y = y + shake_y,
        draw_w = IMAGE_W,
        draw_h = IMAGE_H,
        scale_x = draw_scale,
        scale_y = draw_scale,
        alpha = 1,
        tint_mul = tint_mul,
        progress = p
    }
end

local function finish(state, reason)
    if not state or state.done == true then
        return
    end
    state.done = true
    if type(state.on_complete) == "function" then
        pcall(state.on_complete, reason or "complete", state)
    end
end

function M.start(sequence_id, hooks)
    local state = {
        sequence_id = tostring(sequence_id or ""),
        plate = resolve_plate(sequence_id),
        hooks = hooks or {},
        duration = DEFAULT_DURATION,
        elapsed = 0,
        done = false,
        phase_x = math.random() * math.pi * 2,
        phase_y = math.random() * math.pi * 2,
        tint_phase = math.random() * math.pi * 2
    }
    state.on_complete = state.hooks.on_complete
    local pose = build_pose(state)
    state.last_pose = pose
    if type(state.hooks.on_frame) == "function" then
        pcall(state.hooks.on_frame, pose, state)
    end
    return state
end

function M.stop(state, reason)
    finish(state, reason or "stopped")
end

function M.skip(state)
    finish(state, "skipped")
end

function M.is_done(state)
    return (not state) or state.done == true
end

function M.update(state, dt)
    if not state or state.done == true then
        return nil
    end
    local step = tonumber(dt or 0) or 0
    if step < 0 then
        step = 0
    end
    state.elapsed = (state.elapsed or 0) + step
    local pose = build_pose(state)
    state.last_pose = pose
    if type(state.hooks.on_frame) == "function" then
        pcall(state.hooks.on_frame, pose, state)
    end
    if (state.elapsed or 0) >= (state.duration or DEFAULT_DURATION) then
        finish(state, "complete")
    end
    return pose
end

return M
