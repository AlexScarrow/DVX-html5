local score_profiles = require("main.score_profiles")

local M = {}

local function shallow_copy_table(src)
    local out = {}
    for k, v in pairs(src or {}) do
        out[k] = v
    end
    return out
end

local function get_efficiency_bonus(turns_elapsed, profile)
    local eff = profile and profile.efficiency or nil
    if not eff or eff.type == "none" then
        return 0
    end
    local turns = math.max(0, tonumber(turns_elapsed or 0) or 0)
    local tiers = eff.tiers or {}
    table.sort(tiers, function(a, b)
        return (a.max_turns or math.huge) < (b.max_turns or math.huge)
    end)
    for _, tier in ipairs(tiers) do
        if turns <= (tier.max_turns or math.huge) then
            return tonumber(tier.bonus or 0) or 0
        end
    end
    return tonumber(eff.default_bonus or 0) or 0
end

local function ensure_state(state)
    state = state or {}
    state.mission_type = state.mission_type or score_profiles.DEFAULT_MISSION_TYPE

    -- Raw metrics (always tracked, even if not scored in current mission).
    state.metrics = state.metrics or {}
    local m = state.metrics
    m.turns_elapsed = tonumber(m.turns_elapsed or 0) or 0
    m.aliens_killed_total = tonumber(m.aliens_killed_total or 0) or 0
    m.aliens_killed_by_type = m.aliens_killed_by_type or {}
    m.tiles_powered_first_time = tonumber(m.tiles_powered_first_time or 0) or 0
    m.spawn_points_destroyed = tonumber(m.spawn_points_destroyed or 0) or 0
    m.civilian_escorted_count = tonumber(m.civilian_escorted_count or 0) or 0
    m.humans_escaped_on_launch = tonumber(m.humans_escaped_on_launch or 0) or 0
    m.holdout_turns_survived = tonumber(m.holdout_turns_survived or 0) or 0
    m.humans_alive_at_end = tonumber(m.humans_alive_at_end or 0) or 0
    m.mission_complete = m.mission_complete == true
    m.mission_failed = m.mission_failed == true

    -- Internal de-dup trackers.
    state._scored_tiles = state._scored_tiles or {}
    state._scored_spawn_points = state._scored_spawn_points or {}
    state._scored_civilians = state._scored_civilians or {}

    -- Optional debug/history channel.
    state.events_log = state.events_log or {}

    return state
end

local function log_event(state, name, payload)
    if not state or not state.events_log then
        return
    end
    table.insert(state.events_log, {
        name = name,
        payload = payload or {}
    })
end

function M.create_state(mission_type)
    local state = {
        mission_type = mission_type or score_profiles.DEFAULT_MISSION_TYPE
    }
    return ensure_state(state)
end

function M.reset_state(state, mission_type)
    state = state or {}
    state.mission_type = mission_type or state.mission_type or score_profiles.DEFAULT_MISSION_TYPE
    state.metrics = nil
    state._scored_tiles = nil
    state._scored_spawn_points = nil
    state._scored_civilians = nil
    state.events_log = nil
    return ensure_state(state)
end

function M.set_mission_type(state, mission_type)
    state = ensure_state(state)
    if mission_type and score_profiles.PROFILES[mission_type] then
        state.mission_type = mission_type
    else
        state.mission_type = score_profiles.DEFAULT_MISSION_TYPE
    end
    return state
end

function M.record_turn_started(state, turn_number)
    state = ensure_state(state)
    if turn_number ~= nil then
        local n = tonumber(turn_number) or 0
        if n > state.metrics.turns_elapsed then
            state.metrics.turns_elapsed = n
        end
    else
        state.metrics.turns_elapsed = state.metrics.turns_elapsed + 1
    end
    log_event(state, "turn_started", { turns_elapsed = state.metrics.turns_elapsed })
    return state
end

function M.record_alien_killed(state, alien_type)
    state = ensure_state(state)
    state.metrics.aliens_killed_total = state.metrics.aliens_killed_total + 1
    if alien_type then
        local key = tostring(alien_type)
        state.metrics.aliens_killed_by_type[key] = (state.metrics.aliens_killed_by_type[key] or 0) + 1
    end
    log_event(state, "alien_killed", { alien_type = alien_type })
    return state
end

function M.record_tile_powered(state, tile_instance_id)
    state = ensure_state(state)
    local key = tonumber(tile_instance_id or 0) or 0
    if key > 0 and not state._scored_tiles[key] then
        state._scored_tiles[key] = true
        state.metrics.tiles_powered_first_time = state.metrics.tiles_powered_first_time + 1
        log_event(state, "tile_powered_first_time", { tile_instance_id = key })
    end
    return state
end

function M.record_spawn_point_destroyed(state, spawn_object_id)
    state = ensure_state(state)
    local key = tonumber(spawn_object_id or 0) or 0
    if key > 0 and not state._scored_spawn_points[key] then
        state._scored_spawn_points[key] = true
        state.metrics.spawn_points_destroyed = state.metrics.spawn_points_destroyed + 1
        log_event(state, "spawn_point_destroyed", { spawn_object_id = key })
    end
    return state
end

function M.record_civilian_escorted(state, civilian_id)
    state = ensure_state(state)
    local key = tostring(civilian_id or "")
    if key ~= "" and not state._scored_civilians[key] then
        state._scored_civilians[key] = true
        state.metrics.civilian_escorted_count = state.metrics.civilian_escorted_count + 1
        log_event(state, "civilian_escorted", { civilian_id = key })
    end
    return state
end

function M.record_holdout_turn_survived(state)
    state = ensure_state(state)
    state.metrics.holdout_turns_survived = state.metrics.holdout_turns_survived + 1
    log_event(state, "holdout_turn_survived", { turns = state.metrics.holdout_turns_survived })
    return state
end

function M.record_launch_success(state, escaped_humans_alive_count)
    state = ensure_state(state)
    local escaped = math.max(0, tonumber(escaped_humans_alive_count or 0) or 0)
    state.metrics.humans_escaped_on_launch = escaped
    log_event(state, "launch_success", { escaped_humans_alive_count = escaped })
    return state
end

function M.record_humans_alive_at_end(state, count)
    state = ensure_state(state)
    state.metrics.humans_alive_at_end = math.max(0, tonumber(count or 0) or 0)
    log_event(state, "humans_alive_at_end", { count = state.metrics.humans_alive_at_end })
    return state
end

function M.record_mission_complete(state)
    state = ensure_state(state)
    state.metrics.mission_complete = true
    state.metrics.mission_failed = false
    log_event(state, "mission_complete", {})
    return state
end

function M.record_mission_failed(state)
    state = ensure_state(state)
    state.metrics.mission_failed = true
    state.metrics.mission_complete = false
    log_event(state, "mission_failed", {})
    return state
end

function M.get_metrics(state)
    state = ensure_state(state)
    local out = shallow_copy_table(state.metrics)
    out.aliens_killed_by_type = shallow_copy_table(state.metrics.aliens_killed_by_type)
    return out
end

function M.compute_score(state, mission_type_override)
    state = ensure_state(state)
    local mission_type = mission_type_override or state.mission_type or score_profiles.DEFAULT_MISSION_TYPE
    local profile = score_profiles.get_profile(mission_type)
    local points = profile.points or {}
    local holdout = profile.holdout or {}
    local m = state.metrics

    local kill_points = 0
    local total_kills = tonumber(m.aliens_killed_total or 0) or 0
    local kills_by_type = m.aliens_killed_by_type or {}
    local kill_points_by_type = points.alien_kill_by_type
    if type(kill_points_by_type) == "table" then
        local typed_kills = 0
        for alien_type, count in pairs(kills_by_type) do
            local n = math.max(0, tonumber(count or 0) or 0)
            typed_kills = typed_kills + n
            local per_kill = tonumber(kill_points_by_type[tostring(alien_type)])
            if per_kill == nil then
                per_kill = tonumber(points.alien_kill_default or points.alien_kill or 0) or 0
            end
            kill_points = kill_points + (n * per_kill)
        end
        if total_kills > typed_kills then
            local untyped = total_kills - typed_kills
            local fallback = tonumber(points.alien_kill_default or points.alien_kill or 0) or 0
            kill_points = kill_points + (untyped * fallback)
        end
    else
        kill_points = total_kills * (tonumber(points.alien_kill or 0) or 0)
    end

    local breakdown = {}
    breakdown.aliens_killed_points = kill_points
    breakdown.tiles_powered_points = (m.tiles_powered_first_time or 0) * (points.tile_powered_first_time or 0)
    breakdown.spawn_points_points = (m.spawn_points_destroyed or 0) * (points.spawn_point_destroyed or 0)
    breakdown.civilian_escorted_points = (m.civilian_escorted_count or 0) * (points.civilian_escorted or 0)
    breakdown.humans_escaped_points = (m.humans_escaped_on_launch or 0) * (points.human_escaped_alive or 0)
    breakdown.holdout_survival_points = (m.holdout_turns_survived or 0) * (holdout.points_per_turn_survived or 0)

    breakdown.efficiency_points = 0
    if m.mission_complete == true then
        breakdown.win_bonus_points = points.win_bonus or 0
        breakdown.efficiency_points = get_efficiency_bonus(m.turns_elapsed, profile)
        breakdown.fail_bonus_points = 0
    elseif m.mission_failed == true then
        breakdown.win_bonus_points = 0
        breakdown.fail_bonus_points = points.fail_bonus or 0
    else
        breakdown.win_bonus_points = 0
        breakdown.fail_bonus_points = 0
    end

    local total = 0
    for _, v in pairs(breakdown) do
        total = total + (tonumber(v or 0) or 0)
    end

    return {
        mission_type = mission_type,
        total = math.max(0, math.floor(total + 0.5)),
        breakdown = breakdown,
        metrics = M.get_metrics(state)
    }
end

return M
