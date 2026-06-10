local M = {}

local function safe_call(tbl, key, ...)
    if type(tbl) ~= "table" or type(tbl[key]) ~= "function" then
        return nil
    end
    local ok, a, b, c = pcall(tbl[key], ...)
    if not ok then
        return nil
    end
    return a, b, c
end

local function now_ms()
    return math.floor(os.clock() * 1000)
end

local function pick_backend(runtime_steam)
    if type(runtime_steam) == "table" then
        return runtime_steam
    end
    local global_steam = rawget(_G, "steam")
    if type(global_steam) == "table" then
        return global_steam
    end
    local ok_steam, steam_mod = pcall(require, "steam")
    if ok_steam and type(steam_mod) == "table" then
        return steam_mod
    end
    return nil
end

local function cfg_visibility(raw)
    local value = tostring(raw or "private")
    if value == "public" or value == "friends_only" or value == "private" then
        return value
    end
    return "private"
end

local function to_offer(metadata)
    if type(metadata) ~= "table" then
        return nil
    end
    local session_id = tostring(metadata.session_id or "")
    if session_id == "" then
        return nil
    end
    return {
        id = session_id,
        steam_lobby_id = tostring(metadata.steam_lobby_id or ""),
        owner_player_id = tostring(metadata.owner_player_id or "p1"),
        host_name = tostring(metadata.host_name or "Host"),
        status = tostring(metadata.status or "published_open"),
        env_name = tostring(metadata.env_name or "LOCAL"),
        game_version = tostring(metadata.game_version or "0"),
        build_version = tostring(metadata.build_version or metadata.game_version or "0"),
        protocol_version = tostring(metadata.protocol_version or "1"),
        players = math.max(1, tonumber(metadata.players or 1) or 1),
        max_players = math.max(2, tonumber(metadata.max_players or 4) or 4),
        is_locked = tostring(metadata.is_locked or "0") == "1",
        joined_player_ids = {},
        updated_at_ms = tonumber(metadata.updated_at_ms or now_ms()) or now_ms()
    }
end

local function to_lobby_type(backend, visibility)
    local value = tostring(visibility or "private")
    if value == "public" then
        return tonumber(backend and backend.ELobbyTypePublic or 2) or 2
    end
    if value == "friends_only" then
        return tonumber(backend and backend.ELobbyTypeFriendsOnly or 1) or 1
    end
    return tonumber(backend and backend.ELobbyTypePrivate or 0) or 0
end

local function extract_lobby_id(data)
    if type(data) ~= "table" then
        return ""
    end
    local preferred = {
        "m_ulSteamIDLobby",
        "steam_lobby_id",
        "lobby_id",
        "steam_id_lobby",
        "m_steamIDLobby"
    }
    for _, key in ipairs(preferred) do
        local value = tostring(data[key] or "")
        if value ~= "" and value ~= "0" then
            return value
        end
    end
    for key, value in pairs(data) do
        local k = tostring(key or "")
        if string.find(string.lower(k), "lobby", 1, true) then
            local id = tostring(value or "")
            if id ~= "" and id ~= "0" then
                return id
            end
        end
    end
    return ""
end

local function extract_lobby_match_count(data)
    if type(data) ~= "table" then
        return 0
    end
    return tonumber(data.m_nLobbiesMatching or data.lobbies_matching or data.count or 0) or 0
end

function M.create(opts)
    local cfg = opts and opts.config or {}
    local state = {
        enabled = opts and opts.enabled == true,
        backend = pick_backend(opts and opts.runtime_steam_backend or nil),
        local_lobby_id = "",
        remote_by_session_id = {},
        poll_interval_s = 3.0,
        poll_timer_s = 0,
        list_dirty = false,
        lobby_match_count = 0,
        pending_create = false,
        local_offer = nil,
        max_players = math.max(2, math.min(4, tonumber(cfg.max_players or 4) or 4)),
        visibility = cfg_visibility(cfg.visibility)
    }
    local bridge = {}

    function bridge.is_available()
        return state.enabled == true and type(state.backend) == "table"
    end

    function bridge.get_local_lobby_id()
        return tostring(state.local_lobby_id or "")
    end

    function bridge.publish_offer(offer)
        if not bridge.is_available() or type(offer) ~= "table" then
            return false
        end
        state.local_offer = offer
        local lobby_id = tostring(state.local_lobby_id or "")
        if lobby_id == "" then
            if state.pending_create == true then
                return true
            end
            state.pending_create = true
            local lobby_type = to_lobby_type(state.backend, state.visibility)
            local callback_id = safe_call(state.backend, "matchmaking_create_lobby", lobby_type, state.max_players)
            if callback_id == nil then
                state.pending_create = false
                return false
            end
            return true
        end
        local metadata = {
            session_id = tostring(offer.id or ""),
            steam_lobby_id = lobby_id,
            owner_player_id = tostring(offer.owner_player_id or "p1"),
            host_name = tostring(offer.host_name or "Host"),
            status = tostring(offer.status or "published_open"),
            env_name = tostring(offer.env_name or "LOCAL"),
            game_version = tostring(offer.game_version or "0"),
            build_version = tostring(offer.build_version or offer.game_version or "0"),
            protocol_version = tostring(offer.protocol_version or "1"),
            players = tostring(math.max(1, tonumber(offer.players or 1) or 1)),
            max_players = tostring(math.max(2, tonumber(offer.max_players or 4) or 4)),
            is_locked = (offer.is_locked == true) and "1" or "0",
            updated_at_ms = tostring(tonumber(offer.updated_at_ms or now_ms()) or now_ms())
        }
        for key, value in pairs(metadata) do
            safe_call(state.backend, "matchmaking_set_lobby_data", lobby_id, key, tostring(value))
        end
        return true
    end

    function bridge.remove_offer()
        if not bridge.is_available() then
            return false
        end
        local lobby_id = tostring(state.local_lobby_id or "")
        if lobby_id == "" then
            return false
        end
        safe_call(state.backend, "matchmaking_leave_lobby", lobby_id)
        state.local_lobby_id = ""
        state.pending_create = false
        state.local_offer = nil
        return true
    end

    function bridge.join_lobby(steam_lobby_id)
        if not bridge.is_available() then
            return false
        end
        local lobby_id = tostring(steam_lobby_id or "")
        if lobby_id == "" then
            return false
        end
        local joined = safe_call(state.backend, "matchmaking_join_lobby", lobby_id)
        return joined ~= nil
    end

    local function refresh_remote_offers()
        state.remote_by_session_id = {}
        local count = tonumber(state.lobby_match_count or 0) or 0
        if count <= 0 then
            count = 64
        end
        for i = 0, math.max(0, count - 1) do
            local lid = tostring(safe_call(state.backend, "matchmaking_get_lobby_by_index", i) or "")
            if lid ~= "" and lid ~= tostring(state.local_lobby_id or "") then
                local metadata = {
                    session_id = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "session_id"),
                    steam_lobby_id = lid,
                    owner_player_id = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "owner_player_id"),
                    host_name = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "host_name"),
                    status = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "status"),
                    env_name = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "env_name"),
                    game_version = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "game_version"),
                    build_version = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "build_version"),
                    protocol_version = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "protocol_version"),
                    players = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "players"),
                    max_players = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "max_players"),
                    is_locked = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "is_locked"),
                    updated_at_ms = safe_call(state.backend, "matchmaking_get_lobby_data", lid, "updated_at_ms")
                }
                local offer = to_offer(metadata)
                if offer then
                    state.remote_by_session_id[offer.id] = offer
                end
            end
        end
    end

    function bridge.on_event(event_name, event_data)
        local event = tostring(event_name or "")
        if event == "" then
            return
        end
        if string.find(event, "LobbyMatchList", 1, true) then
            state.lobby_match_count = extract_lobby_match_count(event_data)
            state.list_dirty = true
            return
        end
        if string.find(event, "LobbyCreated", 1, true) then
            -- LobbyCreated event does not always include id in all wrappers;
            -- LobbyEnter will follow and is used as authoritative lobby id.
            return
        end
        if string.find(event, "LobbyEnter", 1, true) then
            local lobby_id = extract_lobby_id(event_data)
            if state.pending_create == true and lobby_id ~= "" then
                state.local_lobby_id = lobby_id
                state.pending_create = false
                if type(state.local_offer) == "table" then
                    bridge.publish_offer(state.local_offer)
                end
            end
            return
        end
        if string.find(event, "LobbyDataUpdate", 1, true) then
            state.list_dirty = true
            return
        end
    end

    function bridge.tick(dt)
        if not bridge.is_available() then
            return {}
        end
        state.poll_timer_s = (tonumber(state.poll_timer_s or 0) or 0) - (tonumber(dt or 0) or 0)
        if state.poll_timer_s <= 0 then
            state.poll_timer_s = state.poll_interval_s
            safe_call(state.backend, "matchmaking_request_lobby_list")
        end
        if state.list_dirty == true then
            state.list_dirty = false
            refresh_remote_offers()
        end
        local out = {}
        for _, offer in pairs(state.remote_by_session_id) do
            out[#out + 1] = offer
        end
        return out
    end

    return bridge
end

return M
