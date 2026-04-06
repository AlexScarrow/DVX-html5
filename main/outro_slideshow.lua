local M = {}

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

local function ease_value(kind, t)
    local x = clamp01(t)
    if kind == "in_out_sine" then
        return 0.5 - (0.5 * math.cos(math.pi * x))
    elseif kind == "in_quad" then
        return x * x
    elseif kind == "out_quad" then
        local y = 1 - x
        return 1 - (y * y)
    end
    return x
end

local function get_or(default_value, maybe_value)
    if maybe_value == nil then
        return default_value
    end
    return maybe_value
end

local function build_pose(defaults, pose)
    pose = pose or {}
    local base_scale = get_or(defaults.scale, pose.scale)
    local sx = get_or(get_or(defaults.scale_x, base_scale), pose.scale_x)
    local sy = get_or(get_or(defaults.scale_y, base_scale), pose.scale_y)
    return {
        x = get_or(defaults.x, pose.x),
        y = get_or(defaults.y, pose.y),
        z = get_or(defaults.z, pose.z),
        rotation_deg = get_or(defaults.rotation_deg, pose.rotation_deg),
        scale = base_scale,
        scale_x = sx,
        scale_y = sy,
        alpha = get_or(defaults.alpha, pose.alpha)
    }
end

local function normalize_layer(layer, fallback_defaults)
    local defaults = fallback_defaults or { x = 0, y = 0, z = 0, rotation_deg = 0, scale = 1, scale_x = 1, scale_y = 1, alpha = 1 }
    local from_pose = build_pose(defaults, layer and layer.from)
    local to_pose = build_pose(from_pose, layer and layer["to"])
    local tint = layer and layer.tint or nil
    local tint_r = 1
    local tint_g = 1
    local tint_b = 1
    if type(tint) == "table" then
        tint_r = tonumber(tint[1] or tint.r or 1) or 1
        tint_g = tonumber(tint[2] or tint.g or 1) or 1
        tint_b = tonumber(tint[3] or tint.b or 1) or 1
    end
    return {
        id = tostring(layer and layer.id or ""),
        anim = layer and layer.anim or nil,
        ease = tostring(layer and layer.ease or "linear"),
        from = from_pose,
        ["to"] = to_pose,
        rotation_ping_pong = layer and layer.rotation_ping_pong == true or false,
        rotation_freq_hz = tonumber(layer and layer.rotation_freq_hz or 1) or 1,
        draw_w = tonumber(layer and layer.draw_w or 0) or 0,
        draw_h = tonumber(layer and layer.draw_h or 0) or 0,
        tint_r = tint_r,
        tint_g = tint_g,
        tint_b = tint_b
    }
end

local function normalize_shot(shot)
    local duration = tonumber(shot and shot.duration or 0) or 0
    if duration <= 0 then
        duration = 0.1
    end
    local defaults = { x = 0, y = 0, z = 0, rotation_deg = 0, scale = 1, scale_x = 1, scale_y = 1, alpha = 1 }
    local from_pose = build_pose(defaults, shot and shot.from)
    local to_pose = build_pose(from_pose, shot and shot["to"])
    local layers = {}
    if type(shot and shot.layers) == "table" and #(shot.layers) > 0 then
        for _, layer in ipairs(shot.layers) do
            table.insert(layers, normalize_layer(layer, defaults))
        end
    else
        table.insert(layers, normalize_layer({
            id = tostring(shot and shot.id or ""),
            anim = shot and shot.anim or nil,
            ease = tostring(shot and shot.ease or "linear"),
            from = from_pose,
            ["to"] = to_pose,
            rotation_ping_pong = shot and shot.rotation_ping_pong == true or false,
            rotation_freq_hz = tonumber(shot and shot.rotation_freq_hz or 1) or 1,
            z = tonumber(shot and shot.z or 0) or 0
        }, defaults))
    end
    local shake_cfg = shot and shot.shake or nil
    local shake = {
        amp_x = tonumber(shake_cfg and shake_cfg.amp_x or 0) or 0,
        amp_y = tonumber(shake_cfg and shake_cfg.amp_y or 0) or 0,
        freq_hz = tonumber(shake_cfg and shake_cfg.freq_hz or 0) or 0,
        start_at = tonumber(shake_cfg and shake_cfg.start_at or 0) or 0,
        end_at = tonumber(shake_cfg and shake_cfg.end_at or duration) or duration,
        decay = shake_cfg and shake_cfg.decay == true or false,
        phase_x = math.random() * math.pi * 2,
        phase_y = math.random() * math.pi * 2
    }
    return {
        id = tostring(shot and shot.id or ""),
        start_at = tonumber(shot and shot.start_at or 0) or 0,
        duration = duration,
        ease = tostring(shot and shot.ease or "linear"),
        layers = layers,
        shake = shake,
        fx_cues = shot and shot.fx_cues or {},
        sfx_cues = shot and shot.sfx_cues or {}
    }
end

local function build_timeline(sequence)
    local out = {}
    local cursor = 0
    for i, raw_shot in ipairs(sequence and sequence.shots or {}) do
        local shot = normalize_shot(raw_shot)
        local explicit_start = tonumber(raw_shot and raw_shot.start_at or nil)
        if explicit_start ~= nil then
            shot.start_at = math.max(0, explicit_start)
        else
            shot.start_at = cursor
        end
        shot.end_at = shot.start_at + shot.duration
        shot.key = tostring(i)
        cursor = math.max(cursor, shot.end_at)
        table.insert(out, shot)
    end
    return out, cursor
end

local function stop_fx_handles_all(state)
    local hooks = state.hooks or {}
    local stop_fx = hooks.stop_fx
    if type(stop_fx) ~= "function" then
        state.active_fx_handles = {}
        return
    end
    for _, entry in ipairs(state.active_fx_handles or {}) do
        pcall(stop_fx, entry.handle, entry.cue, state)
    end
    state.active_fx_handles = {}
end

local function stop_fx_handles_for_shot(state, shot_key)
    local hooks = state.hooks or {}
    local stop_fx = hooks.stop_fx
    if type(stop_fx) ~= "function" then
        return
    end
    local kept = {}
    for _, entry in ipairs(state.active_fx_handles or {}) do
        local matches_shot = tostring(entry.shot_key or "") == tostring(shot_key or "")
        if matches_shot and entry.stop_on_shot_end == true then
            pcall(stop_fx, entry.handle, entry.cue, state)
        else
            table.insert(kept, entry)
        end
    end
    state.active_fx_handles = kept
end

local function run_shot_enter(state, shot, shot_index)
    local hooks = state.hooks or {}
    if type(hooks.on_shot_enter) == "function" then
        pcall(hooks.on_shot_enter, shot, shot_index, state)
    end
end

local function run_shot_exit(state, shot, shot_index)
    local hooks = state.hooks or {}
    if type(hooks.on_shot_exit) == "function" then
        pcall(hooks.on_shot_exit, shot, shot_index, state)
    end
end

local function trigger_cues_at_time(state, shot, cue_list, elapsed, key_prefix, trigger_fn)
    if type(trigger_fn) ~= "function" then
        return
    end
    for idx, cue in ipairs(cue_list or {}) do
        local at_t = tonumber(cue and cue.at or 0) or 0
        local key = key_prefix .. ":" .. tostring(shot.key or "") .. ":" .. tostring(idx)
        if elapsed >= at_t and not state.triggered[key] then
            state.triggered[key] = true
            trigger_fn(cue)
        end
    end
end

local function resolve_cue_motion(cue, shot_elapsed, shot_duration)
    local has_path = type(cue and cue.from) == "table" or type(cue and cue["to"]) == "table"
    if not has_path then
        return nil
    end
    local at_t = tonumber(cue and cue.at or 0) or 0
    local base_x = tonumber((cue and (cue.x or cue.offset_x)) or 0) or 0
    local base_y = tonumber((cue and (cue.y or cue.offset_y)) or 0) or 0
    local base_z = tonumber(cue and cue.z or 0) or 0
    local from_t = cue and cue.from or {}
    local to_t = cue and cue["to"] or {}
    local from_x = tonumber(from_t.x or base_x) or base_x
    local from_y = tonumber(from_t.y or base_y) or base_y
    local from_z = tonumber(from_t.z or base_z) or base_z
    local to_x = tonumber(to_t.x or from_x) or from_x
    local to_y = tonumber(to_t.y or from_y) or from_y
    local to_z = tonumber(to_t.z or from_z) or from_z
    local move_duration = tonumber(cue and (cue.move_duration or cue.duration) or nil)
    if move_duration == nil then
        move_duration = (tonumber(shot_duration or 0) or 0) - at_t
    end
    if move_duration <= 0 then
        move_duration = 0.0001
    end
    local p = clamp01(((tonumber(shot_elapsed or 0) or 0) - at_t) / move_duration)
    local e = ease_value(tostring(cue and cue.ease or "linear"), p)
    return {
        x = lerp(from_x, to_x, e),
        y = lerp(from_y, to_y, e),
        z = lerp(from_z, to_z, e),
        progress = p
    }
end

local function start_soundtrack_if_needed(state)
    if state.soundtrack_started == true then
        return
    end
    local hooks = state.hooks or {}
    local start_music = hooks.start_music
    local soundtrack = state.sequence and state.sequence.soundtrack or nil
    if type(start_music) ~= "function" or type(soundtrack) ~= "table" then
        return
    end
    local cue_name = tostring(soundtrack.cue or "")
    if cue_name == "" then
        return
    end
    state.soundtrack_started = true
    pcall(start_music, soundtrack, state)
end

local function stop_soundtrack_if_needed(state, force_stop)
    local hooks = state.hooks or {}
    local stop_music = hooks.stop_music
    if type(stop_music) ~= "function" then
        state.soundtrack_started = false
        return
    end
    local soundtrack = state.sequence and state.sequence.soundtrack or nil
    if type(soundtrack) ~= "table" then
        state.soundtrack_started = false
        return
    end
    local should_stop = force_stop == true or soundtrack.stop_on_end ~= false
    if should_stop and state.soundtrack_started == true then
        pcall(stop_music, soundtrack, state)
    end
    state.soundtrack_started = false
end

local function finish_sequence(state, reason)
    if state.done == true then
        return
    end
    state.done = true
    for i, shot in ipairs(state.shots or {}) do
        local key = tostring(shot.key or "")
        if state.active_shot_keys and state.active_shot_keys[key] then
            run_shot_exit(state, shot, i)
        end
    end
    stop_fx_handles_all(state)
    stop_soundtrack_if_needed(state, false)
    local hooks = state.hooks or {}
    if type(hooks.on_complete) == "function" then
        pcall(hooks.on_complete, reason or "complete", state)
    end
end

function M.start(sequence, hooks)
    if type(sequence) ~= "table" or type(sequence.shots) ~= "table" or #sequence.shots == 0 then
        return nil
    end
    local shots, sequence_duration = build_timeline(sequence)
    if #shots == 0 then
        return nil
    end
    local state = {
        sequence = sequence,
        hooks = hooks or {},
        shots = shots,
        sequence_duration = sequence_duration,
        shot_index = 1,
        shot_elapsed = 0,
        total_elapsed = 0,
        done = false,
        triggered = {},
        active_fx_handles = {},
        active_shot_keys = {},
        soundtrack_started = false,
        current_shot = shots[1]
    }
    start_soundtrack_if_needed(state)
    return state
end

function M.stop(state, reason)
    if not state then
        return
    end
    stop_soundtrack_if_needed(state, true)
    finish_sequence(state, reason or "stopped")
end

function M.skip(state)
    M.stop(state, "skipped")
end

function M.is_done(state)
    return (not state) or state.done == true
end

function M.update(state, dt)
    if not state or state.done then
        return nil
    end
    local step = tonumber(dt or 0) or 0
    if step < 0 then
        step = 0
    end
    state.total_elapsed = state.total_elapsed + step
    local total_t = state.total_elapsed or 0
    local hooks = state.hooks or {}
    local active_list = {}
    local active_lookup = {}
    for i, shot in ipairs(state.shots or {}) do
        local local_elapsed = total_t - (shot.start_at or 0)
        local is_active = local_elapsed >= 0 and local_elapsed <= (shot.duration or 0)
        local shot_key = tostring(shot.key or i)
        local was_active = state.active_shot_keys[shot_key] == true
        if is_active then
            active_lookup[shot_key] = true
            table.insert(active_list, { shot = shot, shot_index = i, shot_key = shot_key, local_elapsed = local_elapsed })
            if not was_active then
                run_shot_enter(state, shot, i)
            end
        elseif was_active then
            run_shot_exit(state, shot, i)
            stop_fx_handles_for_shot(state, shot_key)
        end
    end
    state.active_shot_keys = active_lookup
    table.sort(active_list, function(a, b)
        if a.shot.start_at == b.shot.start_at then
            return a.shot_index < b.shot_index
        end
        return (a.shot.start_at or 0) < (b.shot.start_at or 0)
    end)
    local shake_x = 0
    local shake_y = 0
    local layer_poses = {}
    for _, active in ipairs(active_list) do
        local shot = active.shot
        local local_elapsed = active.local_elapsed
        trigger_cues_at_time(state, shot, shot.fx_cues, local_elapsed, "fx", function(cue)
            if type(hooks.spawn_fx) ~= "function" then
                return
            end
            local handle = nil
            local ok, value = pcall(hooks.spawn_fx, cue, state)
            if ok then
                handle = value
            end
            if handle ~= nil and (cue.stop_on_shot_end ~= false) then
                table.insert(state.active_fx_handles, {
                    handle = handle,
                    cue = cue,
                    shot_key = active.shot_key,
                    shot_start_at = shot.start_at or 0,
                    shot_duration = shot.duration or 0,
                    stop_on_shot_end = true
                })
            elseif handle ~= nil and cue.stop_on_sequence_end == true then
                table.insert(state.active_fx_handles, {
                    handle = handle,
                    cue = cue,
                    shot_key = active.shot_key,
                    shot_start_at = shot.start_at or 0,
                    shot_duration = shot.duration or 0,
                    stop_on_shot_end = false
                })
            end
        end)
        trigger_cues_at_time(state, shot, shot.sfx_cues, local_elapsed, "sfx", function(cue)
            if type(hooks.play_sfx) == "function" then
                pcall(hooks.play_sfx, cue, state)
            end
        end)
        local p = clamp01(local_elapsed / (shot.duration or 0.0001))
        local shake = shot.shake or nil
        if shake and (shake.freq_hz or 0) > 0 then
            local active_start = tonumber(shake.start_at or 0) or 0
            local active_end = tonumber(shake.end_at or shot.duration) or shot.duration
            if local_elapsed >= active_start and local_elapsed <= active_end then
                local envelope = 1
                if shake.decay == true and active_end > active_start then
                    envelope = clamp01(1 - ((local_elapsed - active_start) / (active_end - active_start)))
                end
                local omega = (tonumber(shake.freq_hz or 0) or 0) * math.pi * 2
                shake_x = shake_x + (math.sin((total_t * omega) + (shake.phase_x or 0)) * (tonumber(shake.amp_x or 0) or 0) * envelope)
                shake_y = shake_y + (math.cos((total_t * omega) + (shake.phase_y or 0)) * (tonumber(shake.amp_y or 0) or 0) * envelope)
            end
        end
        for _, layer in ipairs(shot.layers or {}) do
            local eased = ease_value(layer.ease, p)
            local rotation_deg = lerp(layer.from.rotation_deg, layer["to"].rotation_deg, eased)
            if layer.rotation_ping_pong == true then
                local hz = tonumber(layer.rotation_freq_hz or 1) or 1
                local swing_t = 0.5 - (0.5 * math.cos((local_elapsed or 0) * hz * math.pi * 2))
                rotation_deg = lerp(layer.from.rotation_deg, layer["to"].rotation_deg, swing_t)
            end
            table.insert(layer_poses, {
                id = layer.id,
                anim = layer.anim,
                x = lerp(layer.from.x, layer["to"].x, eased),
                y = lerp(layer.from.y, layer["to"].y, eased),
                scale = lerp(layer.from.scale, layer["to"].scale, eased),
                scale_x = lerp(layer.from.scale_x, layer["to"].scale_x, eased),
                scale_y = lerp(layer.from.scale_y, layer["to"].scale_y, eased),
                alpha = lerp(layer.from.alpha, layer["to"].alpha, eased),
                z = lerp(layer.from.z, layer["to"].z, eased),
                rotation_deg = rotation_deg,
                draw_w = layer.draw_w or 0,
                draw_h = layer.draw_h or 0,
                tint_r = layer.tint_r or 1,
                tint_g = layer.tint_g or 1,
                tint_b = layer.tint_b or 1,
                shot_id = shot.id,
                shot_index = active.shot_index,
                shot_progress = p
            })
        end
    end
    if type(hooks.update_fx) == "function" then
        for _, entry in ipairs(state.active_fx_handles or {}) do
            local cue = entry.cue
            local fx_pose = resolve_cue_motion(cue, total_t - (entry.shot_start_at or 0), entry.shot_duration or 0)
            if fx_pose ~= nil then
                pcall(hooks.update_fx, entry.handle, cue, fx_pose, state)
            end
        end
    end
    local first_layer = layer_poses[1] or { x = 0, y = 0, scale = 1, scale_x = 1, scale_y = 1, alpha = 1, rotation_deg = 0, anim = nil }
    local primary = active_list[#active_list]
    local pose = {
        x = first_layer.x,
        y = first_layer.y,
        scale = first_layer.scale,
        scale_x = first_layer.scale_x,
        scale_y = first_layer.scale_y,
        alpha = first_layer.alpha,
        rotation_deg = first_layer.rotation_deg,
        anim = first_layer.anim,
        layers = layer_poses,
        camera_shake_x = shake_x,
        camera_shake_y = shake_y,
        shot_id = primary and primary.shot.id or "",
        shot_index = primary and primary.shot_index or #state.shots,
        progress = primary and clamp01(primary.local_elapsed / (primary.shot.duration or 0.0001)) or 1,
        total_elapsed = state.total_elapsed
    }
    state.current_shot = primary and primary.shot or state.shots[#state.shots]
    state.shot_index = primary and primary.shot_index or #state.shots
    state.shot_elapsed = primary and primary.local_elapsed or (state.sequence_duration or 0)

    if type(hooks.on_frame) == "function" then
        pcall(hooks.on_frame, pose, state)
    end

    if total_t >= (state.sequence_duration or 0) and #active_list == 0 then
        finish_sequence(state, "complete")
    end

    return pose
end

return M
