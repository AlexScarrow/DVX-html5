local M = {}

local active_gateb_state = nil
local steam_listener_installed = false

    local ok_json_gate, json_gate = pcall(require, "json")

    local function gate_encode_json(value)
        if ok_json_gate and json_gate and json_gate.encode then
            return json_gate.encode(value)
        end
        return nil
    end

    local function gate_decode_json(raw)
        if ok_json_gate and json_gate and json_gate.decode then
            local ok, decoded = pcall(json_gate.decode, raw)
            if ok then
                return decoded
            end
        end
        return nil
    end

    local GATE_KEY = "dvx_gate"
    local GATE_MARKER = "d"
    local PROTO_KEY = "dvx_proto"
    local CHANNEL = 7
    local WIRE_CHANNEL = 8
    local LOBBY_RETRY_SECONDS = 2.0
    local LOBBY_MAX_MEMBERS = 4
    local LOBBY_CREATE_EMPTY_THRESHOLD = 2

    local function log(state, message)
        local line = tostring(message or "")
        if state.on_log then
            pcall(state.on_log, line)
        end
        print(line)
    end

    local function is_valid_steam_id(steam_id)
        local id = tostring(steam_id or "")
        return id ~= "" and id ~= "0"
    end

    local function encode_packet(packet_type, seq)
        return string.format('{"gate":"b","type":"%s","seq":%d}', tostring(packet_type or ""), tonumber(seq) or 0)
    end

    local function parse_packet(raw)
        if type(raw) ~= "string" or raw == "" then
            return nil
        end
        local gate = raw:match('"gate"%s*:%s*"(.-)"')
        local packet_type = raw:match('"type"%s*:%s*"(.-)"')
        local seq = tonumber(raw:match('"seq"%s*:%s*(%d+)'))
        if gate ~= "b" or packet_type == nil or seq == nil then
            return nil
        end
        return { gate = gate, type = packet_type, seq = seq }
    end





    local function get_local_steam_id(backend)
        if type(backend.user_get_steam_id) == "function" then
            local ok, steam_id = pcall(backend.user_get_steam_id)
            if ok and is_valid_steam_id(steam_id) then
                return tostring(steam_id)
            end
        end
        return ""
    end

    local function send_flags_for(backend)
        if type(backend) == "table" and backend.SteamNetworkingSend_Reliable ~= nil then
            return backend.SteamNetworkingSend_Reliable
        end
        return 8
    end

    local function send_packet(state, peer_id, packet_type, seq)
        if not is_valid_steam_id(peer_id) then
            return false, "invalid_peer"
        end
        local payload = encode_packet(packet_type, seq)
        local ok_send, result = pcall(state.backend.networking_send_message_to_user, peer_id, payload, send_flags_for(state.backend), CHANNEL)
        if not ok_send then
            return false, tostring(result)
        end
        return true, tostring(result or "")
    end

    local function accept_peer(state, peer_id)
        if not is_valid_steam_id(peer_id) or state.accepted_peers[peer_id] == true then
            return state.accepted_peers[peer_id] == true
        end
        local ok_accept, accepted = pcall(state.backend.networking_accept_session_with_user, peer_id)
        if ok_accept and accepted == true then
            state.accepted_peers[peer_id] = true
            log(state, string.format("MP STEAM GATEB | session_accept peer=%s", tostring(peer_id)))
            return true
        end
        return false
    end

    local function resolve_peer_from_lobby(state)
        if not is_valid_steam_id(state.lobby_id) then
            return nil
        end
        local ok_count, member_count = pcall(state.backend.matchmaking_get_num_lobby_members, state.lobby_id)
        member_count = tonumber(ok_count and member_count or 0) or 0
        if member_count < 2 then
            return nil
        end
        for index = 0, member_count - 1 do
            local ok_member, member_id = pcall(state.backend.matchmaking_get_lobby_member_by_index, state.lobby_id, index)
            if ok_member and is_valid_steam_id(member_id) and tostring(member_id) ~= state.local_steam_id then
                return tostring(member_id)
            end
        end
        return nil
    end

    local function mark_pass(state, detail)
        if state.passed == true then
            return
        end
        state.passed = true
        state.phase = "passed"
        log(state, string.format(
            "MP STEAM GATEB | roundtrip_ok seq=%d peer=%s detail=%s",
            tonumber(state.pass_seq or 1) or 1,
            tostring(state.peer_steam_id or ""),
            tostring(detail or "")
        ))
        if state.on_status then
            pcall(state.on_status, "gateb_ok", { peer_steam_id = state.peer_steam_id, seq = state.pass_seq })
        end
    end


    local function lobby_distance_filter_worldwide(backend)
        if type(backend.matchmaking_add_request_lobby_list_distance_filter) ~= "function" then
            return
        end
        local worldwide = backend.ELobbyDistanceFilterWorldwide
        if worldwide == nil then
            worldwide = 3
        end
        pcall(backend.matchmaking_add_request_lobby_list_distance_filter, worldwide)
    end

    local function add_gate_lobby_list_filters(state)
        local backend = state.backend
        if type(backend.matchmaking_add_request_lobby_list_string_filter) == "function" then
            pcall(backend.matchmaking_add_request_lobby_list_string_filter, GATE_KEY, GATE_MARKER, backend.ELobbyComparisonEqual or 0)
        end
        if type(backend.matchmaking_add_request_lobby_list_numerical_filter) == "function" then
            pcall(backend.matchmaking_add_request_lobby_list_numerical_filter, PROTO_KEY, tonumber(state.net_protocol_version) or 1, backend.ELobbyComparisonEqual or 0)
        end
        if type(backend.matchmaking_add_request_lobby_list_filter_slots_available) == "function" then
            pcall(backend.matchmaking_add_request_lobby_list_filter_slots_available, 1)
        end
        lobby_distance_filter_worldwide(backend)
    end
    local function request_lobby_list(state)
        local backend = state.backend
        add_gate_lobby_list_filters(state)
        if pcall(backend.matchmaking_request_lobby_list) then
            state.phase = "searching"
            state.lobby_search_pending = true
            state.lobby_search_wait = 8.0
            log(state, "MP STEAM GATEB | lobby_search_requested")
        else
            log(state, "MP STEAM GATEB | lobby_search_failed")
        end
    end



    local function leave_gate_lobby(state)
        if not is_valid_steam_id(state.lobby_id) then
            return
        end
        if type(state.backend.matchmaking_leave_lobby) == "function" then
            pcall(state.backend.matchmaking_leave_lobby, state.lobby_id)
            log(state, string.format("MP STEAM GATEB | lobby_leave id=%s", tostring(state.lobby_id)))
        end
        state.lobby_id = nil
        state.is_host = false
        state.ping_sent = false
        state.peer_steam_id = nil
        state.peer_resolve_logged = false
    end

    local function create_gate_lobby(state)
        if state.phase == "creating" or state.create_pending == true then
            log(state, "MP STEAM GATEB | lobby_create_skipped already_pending")
            return
        end
        state.create_pending = true
        local backend = state.backend
        if pcall(backend.matchmaking_create_lobby, backend.ELobbyTypePublic or 2, LOBBY_MAX_MEMBERS) then
            state.phase = "creating"
            log(state, "MP STEAM GATEB | lobby_create_requested")
        else
            state.create_pending = false
            log(state, "MP STEAM GATEB | lobby_create_failed")
            state.phase = "failed"
        end
    end

    local function join_gate_lobby(state, lobby_id)
        if not is_valid_steam_id(lobby_id) then
            return
        end
        if tostring(state.lobby_id or "") == tostring(lobby_id) then
            state.phase = "in_lobby"
            return
        end
        if is_valid_steam_id(state.lobby_id) then
            leave_gate_lobby(state)
        end
        if pcall(state.backend.matchmaking_join_lobby, lobby_id) then
            state.phase = "joining"
            log(state, string.format("MP STEAM GATEB | lobby_join_requested id=%s", tostring(lobby_id)))
        else
            log(state, string.format("MP STEAM GATEB | lobby_join_failed id=%s", tostring(lobby_id)))
        end
    end

    local function configure_gate_lobby(state, lobby_id)
        if not is_valid_steam_id(lobby_id) then
            return
        end
        local backend = state.backend
        pcall(backend.matchmaking_set_lobby_data, lobby_id, GATE_KEY, GATE_MARKER)
        pcall(backend.matchmaking_set_lobby_data, lobby_id, PROTO_KEY, tostring(state.net_protocol_version or 1))
        if type(backend.matchmaking_set_lobby_joinable) == "function" then
            pcall(backend.matchmaking_set_lobby_joinable, lobby_id, true)
        end
        log(state, string.format("MP STEAM GATEB | lobby_configured id=%s", tostring(lobby_id)))
    end

    local function try_send_ping(state)
        if state.ping_sent == true or state.is_host ~= true or not is_valid_steam_id(state.peer_steam_id) then
            return
        end
        accept_peer(state, state.peer_steam_id)
        local ok_send, send_result = send_packet(state, state.peer_steam_id, "ping", 1)
        if ok_send then
            state.ping_sent = true
            state.pass_seq = 1
            log(state, string.format("MP STEAM GATEB | ping_sent seq=1 peer=%s result=%s", tostring(state.peer_steam_id), tostring(send_result)))
        else
            log(state, string.format("MP STEAM GATEB | ping_send_failed peer=%s err=%s", tostring(state.peer_steam_id), tostring(send_result)))
        end
    end

    local function handle_message(state, message)
        if type(message) ~= "table" then
            return false
        end
        local channel = tonumber(message.m_nChannel or message.m_channel or CHANNEL) or CHANNEL
        local peer_id = tostring(message.m_identityPeer or "")
        local raw = tostring(message.m_pData or "")
        if channel == WIRE_CHANNEL then
            return false
        end
        if channel ~= CHANNEL then
            return false
        end
        local packet = parse_packet(raw)
        if not packet then
            return false
        end
        accept_peer(state, peer_id)
        if packet.type == "ping" then
            log(state, string.format("MP STEAM GATEB | ping_recv seq=%d from=%s", packet.seq, peer_id))
            state.peer_steam_id = state.peer_steam_id or peer_id
            local ok_send, send_result = send_packet(state, peer_id, "pong", packet.seq)
            if ok_send then
                log(state, string.format("MP STEAM GATEB | pong_sent seq=%d peer=%s result=%s", packet.seq, peer_id, tostring(send_result)))
                if state.is_host ~= true then
                    mark_pass(state, "guest_pong_reply")
                end
            else
                log(state, string.format("MP STEAM GATEB | pong_send_failed seq=%d peer=%s err=%s", packet.seq, peer_id, tostring(send_result)))
            end
            return
        end
        if packet.type == "pong" then
            log(state, string.format("MP STEAM GATEB | pong_recv seq=%d from=%s", packet.seq, peer_id))
            state.peer_steam_id = state.peer_steam_id or peer_id
            if state.is_host == true and state.ping_sent == true and packet.seq == (state.pass_seq or 1) then
                mark_pass(state, "host_pong")
            end
        end
        return true
    end

    local function poll_messages(state)
        if type(state.backend.networking_receive_messages_on_channel) ~= "function" then
            return
        end
        for _, channel in ipairs({ CHANNEL }) do
            while true do
                local ok_msg, message = pcall(state.backend.networking_receive_messages_on_channel, channel)
                if not ok_msg or type(message) ~= "table" then
                    break
                end
                handle_message(state, message)
            end
        end
    end

    local function on_lobby_match_list(state, data)
        state.lobby_search_pending = false
        local total = tonumber(data and data.m_nLobbiesMatching or 0) or 0
        log(state, string.format("MP STEAM GATEB | lobby_match_list count=%d", total))
        if state.phase == "passed" then
            return
        end
        local foreign_lobby_id = nil
        if total > 0 and type(state.backend.matchmaking_get_lobby_by_index) == "function" then
            for index = 0, total - 1 do
                local ok_lobby, lobby_id = pcall(state.backend.matchmaking_get_lobby_by_index, index)
                if ok_lobby and is_valid_steam_id(lobby_id) then
                    local owner_id = ""
                    if type(state.backend.matchmaking_get_lobby_owner) == "function" then
                        local ok_owner, owner = pcall(state.backend.matchmaking_get_lobby_owner, lobby_id)
                        if ok_owner then
                            owner_id = tostring(owner or "")
                        end
                    end
                    log(state, string.format(
                        "MP STEAM GATEB | lobby_match_entry index=%d id=%s owner=%s local=%s",
                        index,
                        tostring(lobby_id),
                        owner_id,
                        tostring(state.local_steam_id or "")
                    ))
                    if owner_id ~= state.local_steam_id then
                        foreign_lobby_id = tostring(lobby_id)
                        break
                    end
                end
            end
        end
        if foreign_lobby_id ~= nil then
            state.empty_search_count = 0
            join_gate_lobby(state, foreign_lobby_id)
            return
        end
        if total <= 0 then
            state.empty_search_count = (tonumber(state.empty_search_count or 0) or 0) + 1
        else
            state.empty_search_count = 0
        end
        if state.lobby_id == nil and state.phase ~= "creating" and state.phase ~= "joining" then
            if (tonumber(state.empty_search_count or 0) or 0) < LOBBY_CREATE_EMPTY_THRESHOLD then
                log(state, string.format(
                    "MP STEAM GATEB | lobby_create_wait empty=%d need=%d",
                    tonumber(state.empty_search_count or 0) or 0,
                    LOBBY_CREATE_EMPTY_THRESHOLD
                ))
            else
                create_gate_lobby(state)
            end
        elseif is_valid_steam_id(state.lobby_id) then
            state.phase = "in_lobby"
        end
    end

    local function on_lobby_created(state, data)
        local lobby_id = tostring(data and data.m_ulSteamIDLobby or "")
        local result = tonumber(data and data.m_eResult or 0) or 0
        state.create_pending = false
        if result ~= 1 or not is_valid_steam_id(lobby_id) then
            log(state, string.format("MP STEAM GATEB | lobby_create_failed result=%d id=%s", result, lobby_id))
            state.phase = "failed"
            return
        end
        if tostring(state.lobby_id or "") == lobby_id and state.phase == "in_lobby" then
            log(state, string.format("MP STEAM GATEB | lobby_created_skipped duplicate id=%s", lobby_id))
            return
        end
        state.lobby_id = lobby_id
        state.is_host = true
        configure_gate_lobby(state, lobby_id)
        log(state, string.format("MP STEAM GATEB | lobby_created id=%s", lobby_id))
        state.phase = "in_lobby"
    end

    local function on_lobby_enter(state, data)
        local lobby_id = tostring(data and data.m_ulSteamIDLobby or "")
        local response = tonumber(data and data.m_EChatRoomEnterResponse or 0) or 0
        if not is_valid_steam_id(lobby_id) or response ~= 1 then
            if is_valid_steam_id(lobby_id) then
                log(state, string.format("MP STEAM GATEB | lobby_enter_failed id=%s response=%d", lobby_id, response))
            end
            return
        end
        state.lobby_id = lobby_id
        if state.is_host ~= true and type(state.backend.matchmaking_get_lobby_owner) == "function" then
            local ok_owner, owner = pcall(state.backend.matchmaking_get_lobby_owner, lobby_id)
            state.is_host = ok_owner and tostring(owner or "") == state.local_steam_id
        end
        log(state, string.format("MP STEAM GATEB | lobby_enter id=%s host=%s", lobby_id, tostring(state.is_host == true)))
        state.phase = "in_lobby"
    end

    local function on_session_request(state, data)
        local peer_id = tostring(data and data.m_identityRemote or "")
        if is_valid_steam_id(peer_id) then
            accept_peer(state, peer_id)
            state.peer_steam_id = state.peer_steam_id or peer_id
            log(state, string.format("MP STEAM GATEB | session_request peer=%s", peer_id))
        end
    end

    local function on_steam_event(state, event_name, data)
        if event_name == "LobbyMatchList_t" then
            on_lobby_match_list(state, data)
        elseif event_name == "LobbyCreated_t" then
            on_lobby_created(state, data)
        elseif event_name == "LobbyEnter_t" then
            on_lobby_enter(state, data)
        elseif event_name == "SteamNetworkingMessagesSessionRequest_t" then
            on_session_request(state, data)
        end
    end


    local function install_steam_listener(state)
        active_gateb_state = state
        local backend = state.backend
        if type(backend.set_listener) ~= "function" then
            return
        end
        pcall(backend.set_listener, function(_, event_name, data)
            if active_gateb_state then
                on_steam_event(active_gateb_state, tostring(event_name or ""), data or {})
            end
        end)
        if steam_listener_installed ~= true then
            steam_listener_installed = true
            log(state, "MP STEAM GATEB | listener_installed")
        else
            log(state, "MP STEAM GATEB | listener_rebound")
        end
    end

function M.create(opts)
        local backend = rawget(_G, "steam")
        local state = {
            backend = backend,
            on_log = opts and opts.on_log or nil,
            on_status = opts and opts.on_status or nil,
            net_protocol_version = tonumber(opts and opts.net_protocol_version) or 1,
            phase = "idle",
            local_steam_id = "",
            peer_steam_id = nil,
            lobby_id = nil,
            is_host = false,
            accepted_peers = {},
            ping_sent = false,
            pass_seq = 1,
            passed = false,
            started = false,
            lobby_search_pending = false,
            lobby_search_timer = 0,
            lobby_search_wait = 0,
            tick_timer = 5.0,
            peer_resolve_logged = false,
            empty_search_count = 0,
            create_pending = false
        }
        active_gateb_state = state
        local gateb = {}

        function gateb.restart()
            state.phase = "idle"
            state.peer_steam_id = nil
            state.lobby_id = nil
            state.is_host = false
            state.accepted_peers = {}
            state.ping_sent = false
            state.pass_seq = 1
            state.passed = false
            state.lobby_search_pending = false
            state.lobby_search_timer = 0
            state.lobby_search_wait = 0
            state.empty_search_count = 0
            state.create_pending = false
            state.peer_resolve_logged = false
            active_gateb_state = state
            log(state, "MP STEAM GATEB | restart")
            request_lobby_list(state)
        end

        function gateb.start()
            if state.started == true then
                log(state, "MP STEAM GATEB | start_skipped already_started restart")
                gateb.restart()
                return
            end
            state.started = true
            log(state, "MP STEAM GATEB | start_begin")
            if type(backend) ~= "table" then
                log(state, "MP STEAM GATEB | start_failed reason=no_backend")
                state.phase = "failed"
                return
            end
            if type(backend.init) == "function" then
                local ok_init, init_ok, init_err = pcall(backend.init)
                if not ok_init or init_ok ~= true then
                    log(state, string.format("MP STEAM GATEB | init_failed err=%s", tostring(init_err)))
                    state.phase = "failed"
                    return
                end
                log(state, "MP STEAM GATEB | init_ok")
            end
            install_steam_listener(state)
            state.local_steam_id = get_local_steam_id(backend)
            log(state, string.format("MP STEAM GATEB | local_steam_id=%s", tostring(state.local_steam_id)))
            request_lobby_list(state)
        end

        function gateb.update(dt)
            if state.phase == "failed" then
                return
            end
            if type(state.backend.update) == "function" then
                pcall(state.backend.update)
            end
            if state.lobby_search_pending == true then
                state.lobby_search_wait = (state.lobby_search_wait or 0) - (dt or 0)
                if state.lobby_search_wait <= 0 then
                    state.lobby_search_pending = false
                    log(state, "MP STEAM GATEB | lobby_search_timeout retry")
                end
            end
            state.tick_timer = (state.tick_timer or 0) - (dt or 0)
            if state.phase ~= "passed" and state.tick_timer <= 0 then
                state.tick_timer = 5.0
                log(state, string.format(
                    "MP STEAM GATEB | tick phase=%s pending=%s peer=%s",
                    tostring(state.phase or ""),
                    tostring(state.lobby_search_pending == true),
                    tostring(state.peer_steam_id or "")
                ))
            end
            if state.phase ~= "passed" and state.lobby_search_pending ~= true and (state.phase == "searching" or (state.phase == "in_lobby" and state.peer_steam_id == nil)) then
                state.lobby_search_timer = (state.lobby_search_timer or 0) - (dt or 0)
                if state.lobby_search_timer <= 0 then
                    state.lobby_search_timer = LOBBY_RETRY_SECONDS
                    request_lobby_list(state)
                end
            end
            if state.phase == "in_lobby" then
                local peer_id = resolve_peer_from_lobby(state)
                if is_valid_steam_id(peer_id) and state.peer_steam_id ~= peer_id then
                    state.peer_steam_id = peer_id
                    state.peer_resolve_logged = false
                end
                if is_valid_steam_id(state.peer_steam_id) and state.peer_resolve_logged ~= true then
                    state.peer_resolve_logged = true
                    log(state, string.format("MP STEAM GATEB | peer_resolved id=%s host=%s", tostring(state.peer_steam_id), tostring(state.is_host == true)))
                end
                try_send_ping(state)
            end
            poll_messages(state)
        end

        function gateb.is_host()
            return state.is_host == true
        end

        function gateb.get_peer_steam_id()
            return tostring(state.peer_steam_id or "")
        end

        function gateb.is_passed()
            return state.passed == true
        end

        function gateb.shutdown()
            leave_gate_lobby(state)
            active_gateb_state = nil
        end

        return gateb
    end

function M.reset_listener_state()
    active_gateb_state = nil
    steam_listener_installed = false
end

function M.clear_active_state()
    active_gateb_state = nil
end

return M