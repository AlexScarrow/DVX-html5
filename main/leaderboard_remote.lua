local M = {}

local ok_json, json = pcall(require, "json")

M.BOARD_SOLO = "solo"
M.BOARD_MP = "mp"

local SAVE_KEY_QUEUE = "dvx_leaderboard_remote_queue_v1"
local SAVE_KEY_CACHE_SOLO = "dvx_leaderboard_remote_cache_solo_v1"
local SAVE_KEY_CACHE_MP = "dvx_leaderboard_remote_cache_mp_v1"
local SAVE_KEY_BADGES = "dvx_leaderboard_winner_badges_v1"
local MAX_CACHE_ROWS = 200
local DEFAULT_READ_LIMIT = 100

local function to_string(value)
    return tostring(value or "")
end

local function to_score(value)
    return math.max(0, math.floor((tonumber(value or 0) or 0) + 0.5))
end

local function is_local_fallback_steam_id(steam_id)
    local id = to_string(steam_id)
    return id == "" or string.sub(id, 1, 6) == "local_"
end

local function shallow_clone_array(src)
    local out = {}
    if type(src) ~= "table" then
        return out
    end
    for i = 1, #src do
        out[i] = src[i]
    end
    return out
end

local function clone_badge_map(src)
    local out = {}
    if type(src) ~= "table" then
        return out
    end
    for k, v in pairs(src) do
        local key = tostring(k)
        if type(v) == "table" then
            out[key] = {
                solo_count = tonumber(v.solo_count or v.solo or 0) or 0,
                coop_count = tonumber(v.coop_count or v.mp_count or v.coop or v.mp or 0) or 0
            }
        else
            out[key] = tostring(v or "")
        end
    end
    return out
end

local function normalize_units(units)
    local out = {}
    if type(units) ~= "table" then
        return out
    end
    for i = 1, #units do
        local unit_id = to_string(units[i])
        if unit_id ~= "" then
            out[#out + 1] = unit_id
        end
    end
    return out
end

local function normalize_player(player)
    player = type(player) == "table" and player or {}
    return {
        steam_id = to_string(player.steam_id),
        display_name = to_string(player.display_name),
        units_played = normalize_units(player.units_played)
    }
end

local function cache_key_for_board(board)
    if board == M.BOARD_MP then
        return SAVE_KEY_CACHE_MP
    end
    return SAVE_KEY_CACHE_SOLO
end

local function sort_entries(entries)
    table.sort(entries, function(a, b)
        local a_score = to_score(a and a.score_total)
        local b_score = to_score(b and b.score_total)
        if a_score ~= b_score then
            return a_score > b_score
        end
        return (tonumber(a and a.created_at_ms or 0) or 0) > (tonumber(b and b.created_at_ms or 0) or 0)
    end)
end

local function load_table(key, fallback)
    if not sys or not sys.load then
        return fallback
    end
    local ok, data = pcall(sys.load, key)
    if ok and type(data) == "table" then
        return data
    end
    return fallback
end

local function save_table(key, data)
    if not sys or not sys.save then
        return false
    end
    return pcall(sys.save, key, data) == true
end

local function trim_trailing_slash(value)
    value = to_string(value)
    while string.sub(value, -1) == "/" do
        value = string.sub(value, 1, -2)
    end
    return value
end

local function is_configured(cfg)
    return type(cfg) == "table" and cfg.enabled == true and cfg.url ~= "" and cfg.anon_key ~= ""
end

local function decode_json_array(raw)
    if not (ok_json and json and json.decode) then
        return nil, "json_unavailable"
    end
    local ok, decoded = pcall(json.decode, raw or "")
    if not ok or type(decoded) ~= "table" then
        return nil, "json_decode_failed"
    end
    return decoded, nil
end

local function request_json(cfg, path, callback)
    if not is_configured(cfg) then
        callback(false, "supabase_disabled")
        return false, "supabase_disabled"
    end
    if not (http and http.request) then
        callback(false, "http_unavailable")
        return false, "http_unavailable"
    end
    local url = trim_trailing_slash(cfg.url) .. path
    local headers = {
        ["apikey"] = cfg.anon_key,
        ["Authorization"] = "Bearer " .. cfg.anon_key,
        ["Accept"] = "application/json"
    }
    http.request(url, "GET", function(_, _, response)
        local status = tonumber(response and response.status or 0) or 0
        if status < 200 or status >= 300 then
            callback(false, "http_" .. tostring(status), nil)
            return
        end
        local decoded, reason = decode_json_array(response.response or "")
        if not decoded then
            callback(false, reason or "json_decode_failed", nil)
            return
        end
        callback(true, "ok", decoded)
    end, headers)
    return true, "requested"
end

local function post_json(cfg, path, payload, callback)
    callback = type(callback) == "function" and callback or function() end
    if not is_configured(cfg) then
        callback(false, "supabase_disabled")
        return false, "supabase_disabled"
    end
    if not (http and http.request) then
        callback(false, "http_unavailable")
        return false, "http_unavailable"
    end
    if not (ok_json and json and json.encode) then
        callback(false, "json_unavailable")
        return false, "json_unavailable"
    end
    local encoded = json.encode(payload)
    local url = trim_trailing_slash(cfg.url) .. path
    local headers = {
        ["apikey"] = cfg.anon_key,
        ["Authorization"] = "Bearer " .. cfg.anon_key,
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json"
    }
    http.request(url, "POST", function(_, _, response)
        local status = tonumber(response and response.status or 0) or 0
        if status < 200 or status >= 300 then
            callback(false, "http_" .. tostring(status))
            return
        end
        callback(true, "ok")
    end, headers, encoded)
    return true, "requested"
end

local function normalize_remote_solo_entries(rows)
    local entries = {}
    if type(rows) ~= "table" then
        return entries
    end
    for i = 1, #rows do
        local row = type(rows[i]) == "table" and rows[i] or {}
        local steam_id = to_string(row.steam_id)
        if not is_local_fallback_steam_id(steam_id) then
            local display_name = to_string(row.display_name)
            entries[#entries + 1] = {
                match_id = "solo_total_" .. steam_id,
                score_total = to_score(row.score),
                team_display_names = display_name ~= "" and { display_name } or {},
                players = {
                    {
                        steam_id = steam_id,
                        display_name = display_name,
                        units_played = {}
                    }
                },
                winner_badges_by_steam_id = {},
                created_at_ms = 0
            }
        end
    end
    return entries
end

local function normalize_remote_mp_entries(rows)
    local entries = {}
    if type(rows) ~= "table" then
        return entries
    end
    for i = 1, #rows do
        local row = type(rows[i]) == "table" and rows[i] or {}
        local players = type(row.players) == "table" and row.players or {}
        local names = {}
        local player_details = {}
        local badge_map = {}
        for pi = 1, #players do
            local player = normalize_player(players[pi])
            if player.display_name ~= "" then
                names[#names + 1] = player.display_name
            end
            player_details[#player_details + 1] = player
            if player.steam_id ~= "" then
                badge_map[player.steam_id] = {
                    solo_count = tonumber(players[pi].solo_count or 0) or 0,
                    coop_count = tonumber(players[pi].coop_count or 0) or 0
                }
            end
        end
        entries[#entries + 1] = {
            match_id = to_string(row.team_entry_id),
            score_total = to_score(row.score),
            team_display_names = names,
            players = player_details,
            winner_badges_by_steam_id = badge_map,
            created_at_ms = 0
        }
    end
    return entries
end

local function normalize_remote_badges(rows)
    local badges = {}
    if type(rows) ~= "table" then
        return badges
    end
    for i = 1, #rows do
        local row = type(rows[i]) == "table" and rows[i] or {}
        local steam_id = to_string(row.steam_id)
        if steam_id ~= "" then
            badges[steam_id] = {
                solo_count = tonumber(row.solo_count or 0) or 0,
                coop_count = tonumber(row.coop_count or 0) or 0
            }
        end
    end
    return badges
end

function M.is_enabled()
    local enabled = tostring((sys.get_config and sys.get_config("leaderboard.supabase_enabled")) or "0")
    return enabled == "1" or enabled == "true" or enabled == "on"
end

function M.get_config()
    local read_limit = math.max(1, math.min(500, tonumber(sys.get_config and sys.get_config("leaderboard.supabase_read_limit") or DEFAULT_READ_LIMIT) or DEFAULT_READ_LIMIT))
    return {
        enabled = M.is_enabled(),
        url = to_string(sys.get_config and sys.get_config("leaderboard.supabase_url") or ""),
        anon_key = to_string(sys.get_config and sys.get_config("leaderboard.supabase_anon_key") or ""),
        submit_function = to_string(sys.get_config and sys.get_config("leaderboard.supabase_submit_function") or "submit-leaderboard-score"),
        read_limit = read_limit
    }
end

function M.load_queue()
    local data = load_table(SAVE_KEY_QUEUE, { entries = {} })
    return type(data.entries) == "table" and data.entries or {}
end

function M.save_queue(entries)
    return save_table(SAVE_KEY_QUEUE, { entries = type(entries) == "table" and entries or {} })
end

function M.enqueue(payload, reason)
    local entries = M.load_queue()
    local reason_text = to_string(reason)
    if reason_text == "" then
        reason_text = "queued"
    end
    entries[#entries + 1] = {
        payload = payload,
        reason = reason_text,
        created_at_ms = os and os.time and (os.time() * 1000) or 0,
        retry_count = 0
    }
    M.save_queue(entries)
    return #entries
end

function M.load_cache(board)
    local data = load_table(cache_key_for_board(board), { entries = {} })
    local entries = type(data.entries) == "table" and data.entries or {}
    sort_entries(entries)
    return entries
end

function M.save_cache(board, entries)
    entries = type(entries) == "table" and entries or {}
    sort_entries(entries)
    while #entries > MAX_CACHE_ROWS do
        table.remove(entries)
    end
    return save_table(cache_key_for_board(board), { entries = entries })
end

function M.cache_entry(board, entry)
    if type(entry) ~= "table" then
        return M.load_cache(board)
    end
    local entries = M.load_cache(board)
    entries[#entries + 1] = entry
    M.save_cache(board, entries)
    return entries
end

function M.load_badges()
    local data = load_table(SAVE_KEY_BADGES, { badges_by_steam_id = {} })
    return type(data.badges_by_steam_id) == "table" and data.badges_by_steam_id or {}
end

function M.save_badges(badges_by_steam_id)
    return save_table(SAVE_KEY_BADGES, { badges_by_steam_id = type(badges_by_steam_id) == "table" and badges_by_steam_id or {} })
end

function M.normalize_solo_payload(payload)
    payload = type(payload) == "table" and payload or {}
    return {
        board = M.BOARD_SOLO,
        steam_id = to_string(payload.steam_id),
        display_name = to_string(payload.display_name),
        level_id = math.max(1, math.floor(tonumber(payload.level_id or 1) or 1)),
        score = to_score(payload.score),
        result = to_string(payload.result == "win" and "win" or "loss")
    }
end

function M.normalize_mp_payload(payload)
    payload = type(payload) == "table" and payload or {}
    local players = {}
    if type(payload.players) == "table" then
        for i = 1, #payload.players do
            players[#players + 1] = normalize_player(payload.players[i])
        end
    end
    return {
        board = M.BOARD_MP,
        team_entry_id = to_string(payload.team_entry_id or payload.match_id),
        score = to_score(payload.score),
        players = players
    }
end

function M.to_local_entry(payload)
    payload = type(payload) == "table" and payload or {}
    local names = {}
    local player_details = {}
    if type(payload.players) == "table" then
        for i = 1, #payload.players do
            local player = normalize_player(payload.players[i])
            if player.display_name ~= "" then
                names[#names + 1] = player.display_name
            end
            player_details[#player_details + 1] = player
        end
    elseif to_string(payload.display_name) ~= "" then
        names[1] = to_string(payload.display_name)
    end
    return {
        match_id = to_string(payload.team_entry_id or payload.match_id),
        score_total = to_score(payload.score or payload.score_total),
        team_display_names = names,
        players = player_details,
        winner_badges_by_steam_id = clone_badge_map(payload.winner_badges_by_steam_id),
        created_at_ms = tonumber(payload.created_at_ms or 0) or 0
    }
end

function M.submit(payload, callback)
    callback = type(callback) == "function" and callback or nil
    local cfg = M.get_config()
    if not cfg.enabled then
        M.enqueue(payload, "supabase_disabled")
        if callback then
            callback(false, "supabase_disabled")
        end
        return false, "supabase_disabled"
    end
    if not (ok_json and json and json.encode) then
        M.enqueue(payload, "json_unavailable")
        if callback then
            callback(false, "json_unavailable")
        end
        return false, "json_unavailable"
    end
    local requested, reason = post_json(cfg, "/functions/v1/" .. cfg.submit_function, payload, function(ok, submit_reason)
        if ok then
            M.cache_entry(payload.board, M.to_local_entry(payload))
        else
            M.enqueue(payload, submit_reason or "submit_failed")
        end
        if callback then
            callback(ok == true, submit_reason or (ok and "ok" or "submit_failed"))
        end
    end)
    if not requested then
        M.enqueue(payload, reason or "submit_request_failed")
        if callback then
            callback(false, reason or "submit_request_failed")
        end
        return false, reason or "submit_request_failed"
    end
    return true, "requested"
end

function M.fetch(board)
    local cfg = M.get_config()
    if not cfg.enabled then
        return false, "supabase_disabled", M.load_cache(board)
    end
    return false, "network_not_wired", M.load_cache(board)
end

function M.fetch_async(board, callback)
    callback = type(callback) == "function" and callback or function() end
    local cfg = M.get_config()
    if not is_configured(cfg) then
        callback(false, "supabase_disabled", M.load_cache(board))
        return false, "supabase_disabled"
    end
    local path = nil
    if board == M.BOARD_MP then
        path = "/rest/v1/mp_leaderboard_top?select=team_entry_id,score,created_at,players&order=score.desc,created_at.desc&limit=" .. tostring(cfg.read_limit)
    else
        path = "/rest/v1/solo_leaderboard_totals?select=steam_id,display_name,score&order=score.desc,display_name.asc&limit=" .. tostring(cfg.read_limit)
    end
    return request_json(cfg, path, function(ok, reason, rows)
        if not ok then
            callback(false, reason, M.load_cache(board))
            return
        end
        local entries = (board == M.BOARD_MP) and normalize_remote_mp_entries(rows) or normalize_remote_solo_entries(rows)
        M.save_cache(board, entries)
        callback(true, "ok", entries)
    end)
end

function M.fetch_badges_async(callback)
    callback = type(callback) == "function" and callback or function() end
    local cfg = M.get_config()
    if not is_configured(cfg) then
        callback(false, "supabase_disabled", M.load_badges())
        return false, "supabase_disabled"
    end
    return request_json(cfg, "/rest/v1/winner_badges_public?select=steam_id,solo_count,coop_count", function(ok, reason, rows)
        if not ok then
            callback(false, reason, M.load_badges())
            return
        end
        local badges = normalize_remote_badges(rows)
        M.save_badges(badges)
        callback(true, "ok", badges)
    end)
end

return M
