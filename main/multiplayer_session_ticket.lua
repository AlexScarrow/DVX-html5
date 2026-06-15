-- Supermarket ticket session model (lobby plane only).
-- Gate F/G gameplay wire is intentionally untouched from this module.

local M = {}

M.LOBBY_STATUS_OPEN = "open"
M.LOBBY_STATUS_LAUNCHED = "launched"
M.LOBBY_STATUS_ABORTED = "aborted"

M.PUBLISH_DRAFT = "draft"
M.PUBLISH_OPEN = "published_open"
M.PUBLISH_PRIVATE = "published_private"

M.SESSION_HOST_NETWORK_ID = "p1"
M.SAVE_KEY_NEXT_NUMBER = "dvx_mp_session_next_number"

local TERMINAL_LOBBY_STATUS = {
    [M.LOBBY_STATUS_LAUNCHED] = true,
    [M.LOBBY_STATUS_ABORTED] = true,
}

local function to_string(value)
    return tostring(value or "")
end

local function to_positive_int(value, fallback)
    local n = tonumber(value)
    if not n or n < 1 then
        return fallback
    end
    return math.floor(n)
end

function M.is_terminal_lobby_status(lobby_status)
    return TERMINAL_LOBBY_STATUS[to_string(lobby_status)] == true
end

function M.is_open_lobby_status(lobby_status)
    return to_string(lobby_status) == M.LOBBY_STATUS_OPEN
end

function M.make_session_key(host_steam_id, session_number)
    local host_id = to_string(host_steam_id)
    local number = to_positive_int(session_number, 0)
    if host_id == "" or number <= 0 then
        return ""
    end
    return host_id .. ":" .. tostring(number)
end

function M.parse_session_key(session_key)
    local key = to_string(session_key)
    if key == "" then
        return nil, nil
    end
    local host_id, number_text = string.match(key, "^(.+):(%d+)$")
    if host_id == nil or number_text == nil then
        return nil, nil
    end
    local number = to_positive_int(number_text, 0)
    if number <= 0 then
        return nil, nil
    end
    return host_id, number
end

function M.display_session_number(session_number)
    local number = to_positive_int(session_number, 0)
    if number <= 0 then
        return ""
    end
    return "#" .. tostring(number)
end

function M.ensure_host_allocator(host_runtime)
    host_runtime = host_runtime or {}
    host_runtime.next_session_number = to_positive_int(host_runtime.next_session_number, 1)
    return host_runtime
end

function M.load_host_next_session_number()
    if not sys.load then
        return 1
    end
    local ok, data = pcall(sys.load, M.SAVE_KEY_NEXT_NUMBER)
    if not ok or type(data) ~= "table" then
        return 1
    end
    return to_positive_int(data.next_session_number, 1)
end

function M.save_host_next_session_number(next_session_number)
    if not sys.save then
        return false
    end
    local number = to_positive_int(next_session_number, 1)
    return pcall(sys.save, M.SAVE_KEY_NEXT_NUMBER, {
        next_session_number = number
    }) == true
end

function M.allocate_session_number(host_runtime)
    local runtime = M.ensure_host_allocator(host_runtime)
    local number = to_positive_int(runtime.next_session_number, 1)
    runtime.next_session_number = number + 1
    M.save_host_next_session_number(runtime.next_session_number)
    return number, runtime
end

function M.create_session_record(opts)
    opts = opts or {}
    local host_steam_id = to_string(opts.host_steam_id)
    local session_number = to_positive_int(opts.session_number, 0)
    local session_key = M.make_session_key(host_steam_id, session_number)
    if session_key == "" then
        return nil
    end
    local host_display_name = to_string(opts.host_display_name or opts.host_name or "Host")
    if host_display_name == "" then
        host_display_name = "Host"
    end
    local publish_status = to_string(opts.publish_status or M.PUBLISH_DRAFT)
    local lobby_status = to_string(opts.lobby_status or M.LOBBY_STATUS_OPEN)
    local joined_network_ids = opts.joined_network_ids
    if type(joined_network_ids) ~= "table" or #joined_network_ids == 0 then
        joined_network_ids = { M.SESSION_HOST_NETWORK_ID }
    end
    return {
        session_key = session_key,
        session_number = session_number,
        host_steam_id = host_steam_id,
        host_display_name = host_display_name,
        host_name = host_display_name,
        lobby_status = lobby_status,
        publish_status = publish_status,
        host_network_id = M.SESSION_HOST_NETWORK_ID,
        owner_player_id = M.SESSION_HOST_NETWORK_ID,
        id = session_key,
        max_players = math.max(2, math.min(4, to_positive_int(opts.max_players, 4))),
        joined_network_ids = joined_network_ids,
        joined_player_ids = joined_network_ids,
        players = math.max(1, to_positive_int(opts.players, #joined_network_ids)),
        is_locked = opts.is_locked == true,
        pin = to_string(opts.pin),
        protocol_version = to_string(opts.protocol_version or "1"),
        env_name = to_string(opts.env_name),
        game_version = to_string(opts.game_version),
        steam_lobby_id = to_string(opts.steam_lobby_id),
        updated_at_ms = tonumber(opts.updated_at_ms or 0) or 0,
    }
end

function M.is_session_host(session, local_steam_id)
    if type(session) ~= "table" then
        return false
    end
    local host_id = to_string(session.host_steam_id)
    local local_id = to_string(local_steam_id)
    return host_id ~= "" and local_id ~= "" and host_id == local_id
end

function M.can_host_launch(session, local_steam_id)
    if not M.is_open_lobby_status(session and session.lobby_status) then
        return false
    end
    return M.is_session_host(session, local_steam_id)
end

function M.is_browse_visible(session)
    if type(session) ~= "table" then
        return false
    end
    if not M.is_open_lobby_status(session.lobby_status) then
        return false
    end
    local publish_status = to_string(session.publish_status)
    return publish_status == M.PUBLISH_OPEN or publish_status == M.PUBLISH_PRIVATE
end

function M.mark_launched(session)
    if type(session) ~= "table" then
        return nil
    end
    session.lobby_status = M.LOBBY_STATUS_LAUNCHED
    session.publish_status = to_string(session.publish_status or M.PUBLISH_OPEN)
    return session
end

function M.mark_aborted(session)
    if type(session) ~= "table" then
        return nil
    end
    session.lobby_status = M.LOBBY_STATUS_ABORTED
    return session
end

function M.encode_discovery_payload(session)
    if type(session) ~= "table" or not M.is_browse_visible(session) then
        return nil
    end
    return {
        n = tonumber(session.session_number or 0) or 0,
        hs = to_string(session.host_steam_id),
        st = to_string(session.publish_status),
        host = to_string(session.host_display_name or session.host_name or "Host"),
        pv = to_string(session.protocol_version or "1"),
        pl = math.max(1, tonumber(session.players or 1) or 1),
        mx = math.max(2, tonumber(session.max_players or 4) or 4),
        lk = (session.is_locked == true) and 1 or 0,
    }
end

function M.decode_discovery_payload(raw)
    if type(raw) ~= "table" then
        return nil
    end
    local session_number = to_positive_int(raw.n, 0)
    local host_steam_id = to_string(raw.hs)
    if session_number <= 0 or host_steam_id == "" then
        return nil
    end
    local publish_status = to_string(raw.st)
    if publish_status == "" or publish_status == M.PUBLISH_DRAFT then
        return nil
    end
    return M.create_session_record({
        host_steam_id = host_steam_id,
        session_number = session_number,
        host_display_name = to_string(raw.host or "Host"),
        publish_status = publish_status,
        lobby_status = M.LOBBY_STATUS_OPEN,
        protocol_version = to_string(raw.pv or "1"),
        players = to_positive_int(raw.pl, 1),
        max_players = to_positive_int(raw.mx, 4),
        is_locked = (tonumber(raw.lk or 0) or 0) == 1,
        updated_at_ms = 0,
        steam_discovery = true,
    })
end

return M
