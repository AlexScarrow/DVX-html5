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
    local ok_steamworks, steamworks = pcall(require, "steamworks")
    if ok_steamworks and type(steamworks) == "table" then
        return steamworks
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
        protocol_version = tostring(metadata.protocol_version or "1"),
        players = math.max(1, tonumber(metadata.players or 1) or 1),
        max_players = math.max(2, tonumber(metadata.max_players or 4) or 4),
        is_locked = tostring(metadata.is_locked or "0") == "1",
        joined_player_ids = {},
        updated_at_ms = tonumber(metadata.updated_at_ms or now_ms()) or now_ms()
    }
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
        local lobby_id = tostring(state.local_lobby_id or "")
        if lobby_id == "" then
            local created = safe_call(state.backend, "create_lobby", state.max_players, state.visibility)
                or safe_call(state.backend, "createLobby", state.max_players, state.visibility)
            if created == nil then
                return false
            end
            lobby_id = tostring(created or "")
            state.local_lobby_id = lobby_id
        end
        if lobby_id == "" then
            return false
        end
        local metadata = {
            session_id = tostring(offer.id or ""),
            steam_lobby_id = lobby_id,
            owner_player_id = tostring(offer.owner_player_id or "p1"),
            host_name = tostring(offer.host_name or "Host"),
            status = tostring(offer.status or "published_open"),
            env_name = tostring(offer.env_name or "LOCAL"),
            game_version = tostring(offer.game_version or "0"),
            protocol_version = tostring(offer.protocol_version or "1"),
            players = tostring(math.max(1, tonumber(offer.players or 1) or 1)),
            max_players = tostring(math.max(2, tonumber(offer.max_players or 4) or 4)),
            is_locked = (offer.is_locked == true) and "1" or "0",
            updated_at_ms = tostring(tonumber(offer.updated_at_ms or now_ms()) or now_ms())
        }
        for key, value in pairs(metadata) do
            safe_call(state.backend, "set_lobby_data", lobby_id, key, tostring(value))
            safe_call(state.backend, "setLobbyData", lobby_id, key, tostring(value))
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
        safe_call(state.backend, "leave_lobby", lobby_id)
        safe_call(state.backend, "leaveLobby", lobby_id)
        state.local_lobby_id = ""
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
        local joined = safe_call(state.backend, "join_lobby", lobby_id)
            or safe_call(state.backend, "joinLobby", lobby_id)
        return joined ~= nil
    end

    function bridge.tick(dt)
        if not bridge.is_available() then
            return {}
        end
        state.poll_timer_s = (tonumber(state.poll_timer_s or 0) or 0) - (tonumber(dt or 0) or 0)
        if state.poll_timer_s > 0 then
            local out = {}
            for _, offer in pairs(state.remote_by_session_id) do
                out[#out + 1] = offer
            end
            return out
        end
        state.poll_timer_s = state.poll_interval_s
        safe_call(state.backend, "request_lobby_list")
        safe_call(state.backend, "requestLobbyList")
        local lobbies = safe_call(state.backend, "get_lobby_list")
            or safe_call(state.backend, "getLobbyList")
            or {}
        if type(lobbies) ~= "table" then
            return {}
        end
        state.remote_by_session_id = {}
        for _, lobby_id in ipairs(lobbies) do
            local lid = tostring(lobby_id or "")
            if lid ~= "" and lid ~= tostring(state.local_lobby_id or "") then
                local metadata = {
                    session_id = safe_call(state.backend, "get_lobby_data", lid, "session_id")
                        or safe_call(state.backend, "getLobbyData", lid, "session_id"),
                    steam_lobby_id = lid,
                    owner_player_id = safe_call(state.backend, "get_lobby_data", lid, "owner_player_id")
                        or safe_call(state.backend, "getLobbyData", lid, "owner_player_id"),
                    host_name = safe_call(state.backend, "get_lobby_data", lid, "host_name")
                        or safe_call(state.backend, "getLobbyData", lid, "host_name"),
                    status = safe_call(state.backend, "get_lobby_data", lid, "status")
                        or safe_call(state.backend, "getLobbyData", lid, "status"),
                    env_name = safe_call(state.backend, "get_lobby_data", lid, "env_name")
                        or safe_call(state.backend, "getLobbyData", lid, "env_name"),
                    game_version = safe_call(state.backend, "get_lobby_data", lid, "game_version")
                        or safe_call(state.backend, "getLobbyData", lid, "game_version"),
                    protocol_version = safe_call(state.backend, "get_lobby_data", lid, "protocol_version")
                        or safe_call(state.backend, "getLobbyData", lid, "protocol_version"),
                    players = safe_call(state.backend, "get_lobby_data", lid, "players")
                        or safe_call(state.backend, "getLobbyData", lid, "players"),
                    max_players = safe_call(state.backend, "get_lobby_data", lid, "max_players")
                        or safe_call(state.backend, "getLobbyData", lid, "max_players"),
                    is_locked = safe_call(state.backend, "get_lobby_data", lid, "is_locked")
                        or safe_call(state.backend, "getLobbyData", lid, "is_locked"),
                    updated_at_ms = safe_call(state.backend, "get_lobby_data", lid, "updated_at_ms")
                        or safe_call(state.backend, "getLobbyData", lid, "updated_at_ms")
                }
                local offer = to_offer(metadata)
                if offer then
                    state.remote_by_session_id[offer.id] = offer
                end
            end
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
