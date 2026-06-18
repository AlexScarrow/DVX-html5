local M = {}

local ok_json, json = pcall(require, "json")
local STEAM_GATEB = require("main.steam_transport_gateb")

local function clone_table(t)
    if type(t) ~= "table" then
        return t
    end
    local out = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            out[k] = clone_table(v)
        else
            out[k] = v
        end
    end
    return out
end

local function normalize_for_json(value)
    if type(value) ~= "table" then
        return value
    end
    local has_non_numeric_key = false
    local numeric_keys = {}
    for k, _ in pairs(value) do
        if type(k) == "number" and k >= 1 and math.floor(k) == k then
            table.insert(numeric_keys, k)
        else
            has_non_numeric_key = true
        end
    end
    if not has_non_numeric_key and #numeric_keys > 0 then
        table.sort(numeric_keys)
        local out = {}
        for _, k in ipairs(numeric_keys) do
            out[#out + 1] = normalize_for_json(value[k])
        end
        return out
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = normalize_for_json(v)
    end
    return out
end

local function encode_json(value)
    if ok_json and json and json.encode then
        return json.encode(normalize_for_json(value))
    end
    return nil
end

local function decode_json(raw)
    if ok_json and json and json.decode then
        local ok, decoded = pcall(json.decode, raw)
        if ok then
            return decoded
        end
    end
    return nil
end

local function steam_debug_log(state, message)
    local line = tostring(message or "")
    if state.steam_log then
        pcall(state.steam_log, line)
    end
    print(line)
end

function M.create(opts)
    local state = {
        mode = (opts and opts.mode) or "loopback",
        on_command = opts and opts.on_command or nil,
        on_event = opts and opts.on_event or nil,
        on_status = opts and opts.on_status or nil,
        on_discovery_offer = opts and opts.on_discovery_offer or nil,
        on_discovery_offer_cleared = opts and opts.on_discovery_offer_cleared or nil,
        message_seq = 0,
        ws_url = opts and opts.ws_url or "",
        ws_room_id = opts and opts.ws_room_id or "default_room",
        ws_player_id = opts and opts.ws_player_id or "p1",
        ws_adapter = opts and opts.ws_adapter or nil,
        ws_client = nil,
        ws_connected = false,
        ws_queue = {},
        warned_ws_unavailable = false,
        ws_reconnect_attempt = 0,
        ws_reconnect_timer = 0,
        ws_reconnect_pending = false,
        ws_reconnect_base_seconds = 1.0,
        ws_reconnect_max_seconds = 8.0,
        ws_status = "idle",
        steam_probe = opts and opts.steam_probe or nil,
        steam_log = opts and opts.steam_log or nil,
        steam_connected = false,
        steam_gateb = nil,
        steam_wire_queue = {},
        steam_peer_by_wire_id = {},
        steam_response_peer_id = "",
        steam_gatec = {
            command_sent = false,
            command_recv = false,
            events_sent = false,
            events_recv = false,
            wire_ok = false
        },
        steam_pairing_mode = tostring(opts and opts.steam_pairing_mode or opts and opts.pairing_mode or "host"),
        net_protocol_version = tonumber(opts and opts.net_protocol_version) or 1
    }

    local transport = {}

    local dispatch_status
    local dispatch_events

    local function maybe_mark_gatec_ok()
        local gatec = state.steam_gatec or {}
        local host_ready = gatec.command_recv == true and gatec.events_sent == true
        local guest_ready = gatec.command_sent == true and gatec.events_recv == true
        local ready = false
        if state.steam_gateb and state.steam_gateb.is_host and state.steam_gateb.is_host() then
            ready = host_ready
        else
            ready = guest_ready
        end
        if ready and gatec.wire_ok ~= true then
            gatec.wire_ok = true
            local role = (state.steam_gateb and state.steam_gateb.is_host and state.steam_gateb.is_host()) and "host" or "guest"
            steam_debug_log(state, string.format("MP STEAM GATEC | wire_ok role=%s", role))
            dispatch_status("gatec_ok", { role = role })
        end
    end

    local function log_gatec_once(flag_name, message)
        local gatec = state.steam_gatec
        if gatec[flag_name] == true then
            return
        end
        gatec[flag_name] = true
        steam_debug_log(state, message)
        maybe_mark_gatec_ok()
    end

    local function steam_is_host()
        return state.steam_gateb
            and state.steam_gateb.is_host
            and state.steam_gateb.is_host() == true
    end

    local function steam_guest_peer_ids()
        if state.steam_gateb and state.steam_gateb.get_lobby_guest_steam_ids then
            local guests = state.steam_gateb.get_lobby_guest_steam_ids()
            if type(guests) == "table" then
                return guests
            end
        end
        local single = ""
        if state.steam_gateb and state.steam_gateb.get_peer_steam_id then
            single = tostring(state.steam_gateb.get_peer_steam_id() or "")
        end
        if single ~= "" then
            return { single }
        end
        return {}
    end

    local function steam_host_wire_send_ready()
        return state.steam_gateb
            and state.steam_gateb.is_passed
            and state.steam_gateb.is_passed() == true
    end

    local function steam_queue_wire(peer_id, raw_text, reason_detail)
        table.insert(state.steam_wire_queue, {
            peer_id = tostring(peer_id or ""),
            raw = raw_text,
            detail = tostring(reason_detail or "")
        })
    end

    local function steam_send_wire_to_peer(peer_id, raw_text)
        if not (state.steam_gateb and state.steam_gateb.send_wire_to_peer) then
            return false, "wire_not_ready"
        end
        peer_id = tostring(peer_id or "")
        if peer_id == "" then
            if state.steam_gateb.get_peer_steam_id then
                peer_id = tostring(state.steam_gateb.get_peer_steam_id() or "")
            end
        end
        if peer_id == "" then
            return false, "invalid_peer"
        end
        if steam_is_host() then
            if steam_host_wire_send_ready() ~= true then
                return false, "wire_not_ready"
            end
        elseif state.steam_gateb.is_wire_ready() ~= true then
            return false, "wire_not_ready"
        end
        local ok_send, send_result = state.steam_gateb.send_wire_to_peer(peer_id, raw_text)
        return ok_send == true, send_result
    end

    local function steam_send_wire(raw_text)
        local default_peer = ""
        if state.steam_gateb and state.steam_gateb.get_peer_steam_id then
            default_peer = tostring(state.steam_gateb.get_peer_steam_id() or "")
        end
        return steam_send_wire_to_peer(default_peer, raw_text)
    end

    local function steam_peer_for_wire_player_id(wire_player_id)
        wire_player_id = tostring(wire_player_id or "")
        if wire_player_id == "" then
            return ""
        end
        local mapped = state.steam_peer_by_wire_id and state.steam_peer_by_wire_id[wire_player_id] or nil
        return tostring(mapped or "")
    end

    local function steam_resolve_event_peer_ids(evt, default_peer_id)
        local peer_ids = {}
        local seen = {}
        local function add_peer(peer_id)
            peer_id = tostring(peer_id or "")
            if peer_id == "" or seen[peer_id] == true then
                return
            end
            seen[peer_id] = true
            peer_ids[#peer_ids + 1] = peer_id
        end
        default_peer_id = tostring(default_peer_id or "")
        local evt_type = tostring(evt and evt.type or "")
        if default_peer_id ~= ""
            and (evt_type == "command_rejected" or evt_type == "lobby_offer_join_reject")
        then
            add_peer(default_peer_id)
            return peer_ids
        end
        local target_peer = steam_peer_for_wire_player_id(evt and evt.payload and evt.payload.target_player_id or "")
        if target_peer ~= "" then
            add_peer(target_peer)
            return peer_ids
        end
        if steam_is_host() then
            local guests = steam_guest_peer_ids()
            for i = 1, #guests do
                add_peer(guests[i])
            end
            if state.steam_peer_by_wire_id then
                for _, steam_id in pairs(state.steam_peer_by_wire_id) do
                    add_peer(steam_id)
                end
            end
            if #peer_ids > 0 then
                return peer_ids
            end
        end
        add_peer(default_peer_id)
        if #peer_ids > 0 then
            return peer_ids
        end
        if not steam_is_host() then
            add_peer(state.steam_gateb and state.steam_gateb.get_peer_steam_id and state.steam_gateb.get_peer_steam_id() or "")
        end
        return peer_ids
    end

    local function steam_record_command_peer(packet, peer_id)
        if type(packet) ~= "table" or type(packet.payload) ~= "table" then
            return
        end
        local steam_peer = tostring(peer_id or "")
        if steam_peer == "" then
            return
        end
        state.steam_response_peer_id = steam_peer
        if steam_is_host() then
            return
        end
        local sender = tostring(packet.payload.sender_player_id or "")
        if sender ~= "" then
            state.steam_peer_by_wire_id = state.steam_peer_by_wire_id or {}
            state.steam_peer_by_wire_id[sender] = steam_peer
        end
    end

    local function response_event_priority(evt)
        local evt_type = tostring(evt and evt.type or "")
        if evt_type == "match_started" then
            return 0
        end
        if evt_type == "lobby_join_accepted" then
            return 1
        end
        if evt_type == "lobby_offer_join_accept" then
            return 2
        end
        if evt_type == "setup_state_updated" then
            return 3
        end
        if evt_type == "lobby_offer_upsert" then
            return 4
        end
        return 5
    end

    local function steam_send_events_individually(events, source_label, default_peer_id)
        if type(events) ~= "table" or #events == 0 then
            return
        end
        local sorted_events = {}
        for i = 1, #events do
            sorted_events[i] = events[i]
        end
        table.sort(sorted_events, function(a, b)
            return response_event_priority(a) < response_event_priority(b)
        end)
        local label = tostring(source_label or "")
        default_peer_id = tostring(default_peer_id or state.steam_response_peer_id or "")
        for _, evt in ipairs(sorted_events) do
            local events_wire = encode_json({
                version = 1,
                type = "events",
                payload = { evt }
            })
            if not events_wire then
                steam_debug_log(state, string.format(
                    "MP STEAM GATEC | event_dropped type=%s src=%s reason=encode_failed",
                    tostring(evt and evt.type or ""),
                    label
                ))
            else
                local peer_ids = steam_resolve_event_peer_ids(evt, default_peer_id)
                if #peer_ids == 0 then
                    steam_queue_wire("", events_wire, "no_peer")
                    steam_debug_log(state, string.format(
                        "MP STEAM GATEC | event_queued type=%s src=%s reason=no_peer bytes=%d",
                        tostring(evt and evt.type or ""),
                        label,
                        #events_wire
                    ))
                else
                    for _, peer_id in ipairs(peer_ids) do
                        local ok_send, send_result = steam_send_wire_to_peer(peer_id, events_wire)
                        if ok_send then
                            log_gatec_once("events_sent", string.format(
                                "MP STEAM GATEC | events_sent count=1 peer=%s",
                                tostring(peer_id)
                            ))
                            steam_debug_log(state, string.format(
                                "MP STEAM GATEC | event_sent type=%s src=%s peer=%s bytes=%d",
                                tostring(evt and evt.type or ""),
                                label,
                                tostring(peer_id),
                                #events_wire
                            ))
                        else
                            steam_queue_wire(peer_id, events_wire, send_result)
                            steam_debug_log(state, string.format(
                                "MP STEAM GATEC | event_queued type=%s src=%s peer=%s reason=%s bytes=%d",
                                tostring(evt and evt.type or ""),
                                label,
                                tostring(peer_id),
                                tostring(send_result or "wire_not_ready"),
                                #events_wire
                            ))
                        end
                    end
                end
            end
        end
    end

    local function steam_send_response_events(events, cmd_type, response_peer_id)
        steam_send_events_individually(events, tostring(cmd_type or "command_response"), response_peer_id)
    end

    local function steam_flush_wire_queue()
        if steam_is_host() then
            if steam_host_wire_send_ready() ~= true then
                return
            end
        elseif state.steam_gateb and state.steam_gateb.is_wire_ready() ~= true then
            return
        end
        local pending = state.steam_wire_queue or {}
        state.steam_wire_queue = {}
        local failed = {}
        for _, entry in ipairs(pending) do
            local raw_text = type(entry) == "table" and entry.raw or entry
            local peer_id = type(entry) == "table" and entry.peer_id or ""
            if type(raw_text) ~= "string" or raw_text == "" then
            else
                local ok_send, send_result = steam_send_wire_to_peer(peer_id, raw_text)
                if ok_send then
                    local packet = decode_json(raw_text)
                    if packet and packet.type == "command" and type(packet.payload) == "table" then
                        local cmd_type = tostring(packet.payload.type or packet.payload.command_type or "")
                        log_gatec_once("command_sent", string.format(
                            "MP STEAM GATEC | command_sent type=%s peer=%s queued=true",
                            cmd_type,
                            tostring(peer_id or state.steam_gateb.get_peer_steam_id() or "")
                        ))
                    elseif packet and packet.type == "events" and type(packet.payload) == "table" then
                        log_gatec_once("events_sent", string.format(
                            "MP STEAM GATEC | events_sent count=%d peer=%s queued=true",
                            #packet.payload,
                            tostring(peer_id or state.steam_gateb.get_peer_steam_id() or "")
                        ))
                    end
                else
                    failed[#failed + 1] = type(entry) == "table" and entry or {
                        peer_id = peer_id,
                        raw = raw_text,
                        detail = tostring(send_result or "wire_not_ready")
                    }
                    local packet = decode_json(raw_text)
                    local detail = tostring(send_result or "wire_not_ready")
                    if packet and packet.type == "events" and type(packet.payload) == "table" and packet.payload[1] then
                        detail = detail .. " event=" .. tostring(packet.payload[1].type or "")
                    elseif packet and packet.type == "command" and type(packet.payload) == "table" then
                        detail = detail .. " cmd=" .. tostring(packet.payload.type or packet.payload.command_type or "")
                    end
                    steam_debug_log(state, string.format(
                        "MP STEAM GATEC | wire_send_failed peer=%s bytes=%d detail=%s",
                        tostring(peer_id or ""),
                        #raw_text,
                        detail
                    ))
                end
            end
        end
        for _, entry in ipairs(failed) do
            table.insert(state.steam_wire_queue, entry)
        end
    end

    local function handle_steam_wire_packet(raw_text, peer_id)
        local packet = decode_json(raw_text)
        if not packet then
            steam_debug_log(state, "MP STEAM GATEC | wire_ignored reason=non_json")
            return
        end
        if packet.type == "events" and type(packet.payload) == "table" then
            log_gatec_once("events_recv", string.format(
                "MP STEAM GATEC | events_recv count=%d from=%s",
                #packet.payload,
                tostring(peer_id or "")
            ))
            dispatch_events(packet.payload)
            return
        end
        if packet.type == "command" and type(packet.payload) == "table" then
            local command = packet.payload
            command.guest_steam_id = tostring(peer_id or "")
            local cmd_type = tostring(command.type or command.command_type or "")
            steam_record_command_peer(packet, peer_id)
            log_gatec_once("command_recv", string.format(
                "MP STEAM GATEC | command_recv type=%s from=%s",
                cmd_type,
                tostring(peer_id or "")
            ))
            local events = nil
            if state.on_command then
                local ok_cmd, cmd_or_err = pcall(state.on_command, packet.payload)
                if ok_cmd then
                    events = cmd_or_err
                else
                    print("MP TRANSPORT | on_command callback failed (steam): " .. tostring(cmd_or_err))
                end
            end
            if type(events) == "table" and #events > 0 then
                local local_events = events
                if steam_is_host() then
                    local_events = {}
                    for _, evt in ipairs(events) do
                        if tostring(evt and evt.type or "") ~= "command_rejected" then
                            local_events[#local_events + 1] = evt
                        end
                    end
                end
                if #local_events > 0 then
                    dispatch_events(local_events)
                end
                steam_debug_log(state, string.format(
                    "MP STEAM GATEG | command_apply_local type=%s event_count=%d",
                    cmd_type,
                    #events
                ))
                steam_send_response_events(events, cmd_type, state.steam_response_peer_id)
            end
            return
        end
        if packet.type == "hello"
            or packet.type == "joined_room"
            or packet.type == "player_joined"
            or packet.type == "player_left"
            or packet.type == "error"
            or packet.type == "pong" then
            dispatch_events({ packet })
            return
        end
        steam_debug_log(state, string.format("MP STEAM GATEC | wire_ignored type=%s", tostring(packet.type or "")))
    end

    dispatch_status = function(status, detail)
        state.ws_status = status or state.ws_status
        if state.on_status then
            local ok_status, err_status = pcall(state.on_status, status, detail or {})
            if not ok_status then
                print("MP TRANSPORT | on_status callback failed: " .. tostring(err_status))
            end
        end
    end

    local function schedule_reconnect(reason)
        if state.mode ~= "websocket" then
            return
        end
        state.ws_connected = false
        state.ws_client = nil
        local attempt = state.ws_reconnect_attempt or 0
        local delay = state.ws_reconnect_base_seconds * (2 ^ attempt)
        if delay > state.ws_reconnect_max_seconds then
            delay = state.ws_reconnect_max_seconds
        end
        state.ws_reconnect_attempt = attempt + 1
        state.ws_reconnect_timer = delay
        state.ws_reconnect_pending = true
        dispatch_status("reconnecting", {
            reason = reason or "unknown",
            attempt = state.ws_reconnect_attempt,
            retry_in_seconds = delay
        })
    end

    dispatch_events = function(events)
        if state.on_event and type(events) == "table" then
            for _, event in ipairs(events) do
                local ok_evt, err_evt = pcall(state.on_event, event)
                if not ok_evt then
                    print("MP TRANSPORT | on_event callback failed: " .. tostring(err_evt))
                end
            end
        end
    end

    local function dispatch_loopback(envelope)
        local events = nil
        if state.on_command then
            local ok_cmd, cmd_or_err = pcall(state.on_command, envelope)
            if ok_cmd then
                events = cmd_or_err
            else
                print("MP TRANSPORT | on_command callback failed: " .. tostring(cmd_or_err))
            end
        end
        dispatch_events(events)
    end

    local function websocket_send_text(raw_text)
        if not (state.ws_adapter and state.ws_client and state.ws_connected) then
            return false
        end
        if state.ws_adapter.send_text then
            state.ws_adapter.send_text(state.ws_client, raw_text)
            return true
        end
        return false
    end

    local function websocket_flush_queue()
        if not (state.ws_connected and state.ws_adapter and state.ws_client) then
            return
        end
        for _, raw_text in ipairs(state.ws_queue) do
            websocket_send_text(raw_text)
        end
        state.ws_queue = {}
    end

    local function websocket_connect_if_needed()
        if state.mode ~= "websocket" then
            return
        end
        if state.ws_client ~= nil then
            return
        end
        if not (state.ws_adapter and state.ws_adapter.connect and state.ws_url ~= "") then
            if state.warned_ws_unavailable ~= true then
                print("MP TRANSPORT | websocket adapter unavailable; falling back to loopback.")
                state.warned_ws_unavailable = true
            end
            state.mode = "loopback"
            dispatch_status("fallback_loopback", {
                reason = "adapter_unavailable"
            })
            return
        end
        dispatch_status("connecting", {
            url = state.ws_url,
            room_id = state.ws_room_id
        })
        state.ws_client = state.ws_adapter.connect(state.ws_url, {
            room_id = state.ws_room_id,
            player_id = state.ws_player_id
        }, {
            on_open = function()
                print("MP TRANSPORT | websocket connected.")
                state.ws_connected = true
                state.ws_reconnect_attempt = 0
                state.ws_reconnect_timer = 0
                state.ws_reconnect_pending = false
                dispatch_status("connected", {
                    room_id = state.ws_room_id
                })
                websocket_flush_queue()
            end,
            on_message = function(raw_text)
                local packet = decode_json(raw_text)
                if not packet then
                    print("MP TRANSPORT | websocket non-json payload ignored.")
                    return
                end
                if packet.type == "events" and type(packet.payload) == "table" then
                    dispatch_events(packet.payload)
                    return
                end
                if packet.type == "command" and type(packet.payload) == "table" then
                    local events = nil
                    if state.on_command then
                        local ok_cmd, cmd_or_err = pcall(state.on_command, packet.payload)
                        if ok_cmd then
                            events = cmd_or_err
                        else
                            print("MP TRANSPORT | on_command callback failed (ws): " .. tostring(cmd_or_err))
                        end
                    end
                    if type(events) == "table" and #events > 0 then
                        local events_wire = encode_json({
                            version = 1,
                            type = "events",
                            payload = events
                        })
                        if events_wire then
                            websocket_send_text(events_wire)
                        end
                    end
                    return
                end
                if packet.type == "hello"
                    or packet.type == "joined_room"
                    or packet.type == "player_joined"
                    or packet.type == "player_left"
                    or packet.type == "error"
                    or packet.type == "pong" then
                    dispatch_events({ packet })
                    return
                end
                print("MP TRANSPORT | websocket packet ignored: " .. tostring(packet.type))
            end,
            on_error = function(err)
                print("MP TRANSPORT | websocket error: " .. tostring(err))
                schedule_reconnect("error")
            end,
            on_close = function()
                schedule_reconnect("closed")
            end
        })
        if state.ws_client == nil then
            print("MP TRANSPORT | websocket connect returned nil; scheduling reconnect.")
            schedule_reconnect("connect_nil")
        end
    end

    function transport.send_command(command)
        if type(command) ~= "table" then
            return
        end
        state.message_seq = state.message_seq + 1
        local envelope = clone_table(command)
        envelope.message_id = envelope.message_id or ("cmd_" .. tostring(state.message_seq))

        if state.mode == "loopback" then
            dispatch_loopback(envelope)
            return
        end

        if state.mode == "websocket" then
            websocket_connect_if_needed()
            if state.mode == "loopback" then
                dispatch_loopback(envelope)
                return
            end
            local wire_packet = {
                version = 1,
                type = "command",
                payload = envelope
            }
            local raw_text = encode_json(wire_packet)
            if not raw_text then
                print("MP TRANSPORT | json unavailable; command dropped in websocket mode.")
                return
            end
            if not websocket_send_text(raw_text) then
                table.insert(state.ws_queue, raw_text)
            end
            return
        end

        if state.mode == "steam" then
            if state.steam_connected ~= true then
                dispatch_status("error", {
                    mode = "steam",
                    reason = "steam_not_connected"
                })
                return
            end
            local wire_packet = {
                version = 1,
                type = "command",
                payload = envelope
            }
            local raw_text = encode_json(wire_packet)
            if not raw_text then
                steam_debug_log(state, "MP STEAM GATEC | command_dropped reason=json_unavailable")
                return
            end
            local cmd_type = tostring(envelope.type or envelope.command_type or "")
            local ok_send, send_result = steam_send_wire(raw_text)
            if ok_send ~= true then
                local peer_id = state.steam_gateb and state.steam_gateb.get_peer_steam_id and state.steam_gateb.get_peer_steam_id() or ""
                steam_queue_wire(peer_id, raw_text, send_result)
            else
                log_gatec_once("command_sent", string.format(
                    "MP STEAM GATEC | command_sent type=%s peer=%s",
                    cmd_type,
                    tostring(state.steam_gateb and state.steam_gateb.get_peer_steam_id and state.steam_gateb.get_peer_steam_id() or "")
                ))
            end
            return
        end

        dispatch_loopback(envelope)
    end

    function transport.send_events(events)
        if type(events) ~= "table" then
            return
        end
        if state.mode == "loopback" then
            dispatch_events(events)
            return
        end
        if state.mode == "websocket" then
            websocket_connect_if_needed()
            if state.mode == "loopback" then
                dispatch_events(events)
                return
            end
            local raw_text = encode_json({
                version = 1,
                type = "events",
                payload = events
            })
            if not raw_text then
                return
            end
            if not websocket_send_text(raw_text) then
                table.insert(state.ws_queue, raw_text)
            end
            return
        end
        if state.mode == "steam" then
            if state.steam_connected ~= true then
                dispatch_status("error", {
                    mode = "steam",
                    reason = "steam_not_connected"
                })
                return
            end
            steam_send_events_individually(events, "send_events")
            return
        end
        dispatch_events(events)
    end

    function transport.shutdown()
        if state.steam_gateb and state.steam_gateb.shutdown then
            pcall(state.steam_gateb.shutdown)
        end
        if STEAM_GATEB and STEAM_GATEB.reset_listener_state then
            STEAM_GATEB.reset_listener_state()
        end
        state.steam_gateb = nil
        state.steam_connected = false
        state.steam_wire_queue = {}
        state.steam_peer_by_wire_id = {}
        state.steam_response_peer_id = ""
        state.steam_gatec = {
            command_sent = false,
            command_recv = false,
            events_sent = false,
            events_recv = false,
            wire_ok = false
        }
        if state.ws_adapter and state.ws_client and state.ws_adapter.close then
            state.ws_adapter.close(state.ws_client)
        end
        state.ws_client = nil
        state.ws_connected = false
        state.ws_reconnect_pending = false
        state.ws_reconnect_timer = 0
        dispatch_status("shutdown", {})
        state.on_command = nil
        state.on_event = nil
    end

    function transport.set_local_player_id(player_id)
        local next_id = tostring(player_id or "")
        if next_id == "" then
            return
        end
        state.ws_player_id = next_id
    end

    function transport.steam_publish_session(session)
        if state.steam_gateb and state.steam_gateb.publish_session then
            return state.steam_gateb.publish_session(session) == true
        end
        return false
    end

    function transport.steam_clear_session()
        if state.steam_gateb and state.steam_gateb.clear_session then
            return state.steam_gateb.clear_session() == true
        end
        return false
    end

    function transport.steam_is_host()
        if state.steam_gateb and state.steam_gateb.is_host then
            return state.steam_gateb.is_host() == true
        end
        return false
    end

    function transport.steam_get_local_steam_id()
        if state.steam_gateb and state.steam_gateb.get_local_steam_id then
            return tostring(state.steam_gateb.get_local_steam_id() or "")
        end
        return ""
    end

    function transport.set_steam_pairing_mode(mode)
        state.steam_pairing_mode = tostring(mode or "host")
        if state.steam_gateb and state.steam_gateb.set_pairing_mode then
            state.steam_gateb.set_pairing_mode(state.steam_pairing_mode)
        end
    end

    function transport.get_steam_pairing_mode()
        if state.steam_gateb and state.steam_gateb.get_pairing_mode then
            return tostring(state.steam_gateb.get_pairing_mode() or state.steam_pairing_mode or "host")
        end
        return tostring(state.steam_pairing_mode or "host")
    end

    function transport.steam_get_lobby_id()
        if state.steam_gateb and state.steam_gateb.get_lobby_id then
            return tostring(state.steam_gateb.get_lobby_id() or "")
        end
        return ""
    end

    function transport.steam_get_lobby_guest_steam_ids()
        return steam_guest_peer_ids()
    end

    function transport.steam_join_lobby(lobby_id)
        if state.steam_gateb and state.steam_gateb.join_lobby then
            return state.steam_gateb.join_lobby(lobby_id) == true
        end
        return false
    end

    function transport.steam_request_create_lobby()
        if state.steam_gateb and state.steam_gateb.request_create_lobby then
            return state.steam_gateb.request_create_lobby() == true
        end
        return false
    end

    function transport.steam_is_wire_ready()
        if state.steam_gateb and state.steam_gateb.is_wire_ready then
            return state.steam_gateb.is_wire_ready() == true
        end
        return false
    end

    function transport.steam_sync_peer_map(steam_id_by_wire_id)
        if type(steam_id_by_wire_id) ~= "table" then
            return
        end
        state.steam_peer_by_wire_id = {}
        for wire_id, steam_id in pairs(steam_id_by_wire_id) do
            local wire_key = tostring(wire_id or "")
            local steam_key = tostring(steam_id or "")
            if wire_key ~= "" and steam_key ~= "" then
                state.steam_peer_by_wire_id[wire_key] = steam_key
            end
        end
    end

    local function reset_steam_gatec()
        state.steam_gatec = {
            command_sent = false,
            command_recv = false,
            events_sent = false,
            events_recv = false,
            wire_ok = false
        }
    end

    function transport.steam_leave_lobby()
        reset_steam_gatec()
        if state.steam_gateb and state.steam_gateb.leave_lobby then
            return state.steam_gateb.leave_lobby() == true
        end
        return false
    end

    function transport.steam_rejoin_lobby(lobby_id)
        reset_steam_gatec()
        if state.steam_gateb and state.steam_gateb.rejoin_lobby then
            return state.steam_gateb.rejoin_lobby(lobby_id) == true
        end
        return false
    end

    function transport.steam_reset_gateb_handshake()
        reset_steam_gatec()
        if state.steam_gateb and state.steam_gateb.reset_handshake then
            return state.steam_gateb.reset_handshake() == true
        end
        return false
    end

    function transport.flush_wire_queue()
        steam_flush_wire_queue()
    end

    function transport.update(dt)
        if state.mode == "steam" then
            if state.steam_gateb and state.steam_gateb.update then
                state.steam_gateb.update(dt)
            end
            steam_flush_wire_queue()
            return
        end
        if state.mode ~= "websocket" then
            return
        end
        if state.ws_connected then
            return
        end
        if state.ws_reconnect_pending then
            state.ws_reconnect_timer = math.max(0, (state.ws_reconnect_timer or 0) - (dt or 0))
            if state.ws_reconnect_timer <= 0 then
                state.ws_reconnect_pending = false
                websocket_connect_if_needed()
            end
            return
        end
        if state.ws_client == nil then
            websocket_connect_if_needed()
        end
    end

    local function steam_connect_if_needed()
        if state.mode ~= "steam" then
            return
        end
        local probe = state.steam_probe or {}
        local available = probe.available == true
        local has_send = probe.has_send_message_to_user == true
        local has_receive = probe.has_receive_messages_on_channel == true
        local has_accept = probe.has_accept_session_with_user == true
        if available and has_send and has_receive and has_accept then
            state.steam_connected = true
            steam_debug_log(state, string.format(
                "MP STEAM GATEA | probe_connect_ok backend=%s",
                tostring(probe.backend_source or "unknown")
            ))
            dispatch_status("connected", {
                mode = "steam",
                backend = tostring(probe.backend_source or "unknown")
            })
            if STEAM_GATEB and STEAM_GATEB.create then
                state.steam_gateb = STEAM_GATEB.create({
                    on_log = state.steam_log,
                    on_wire_recv = handle_steam_wire_packet,
                    on_discovery_offer = state.on_discovery_offer,
                    on_discovery_offer_cleared = state.on_discovery_offer_cleared,
                    net_protocol_version = state.net_protocol_version,
                    pairing_mode = state.steam_pairing_mode,
                    on_status = function(status, detail)
                        dispatch_status(status, detail or {})
                        if status == "gateb_ok" then
                            steam_flush_wire_queue()
                        end
                    end
                })
                if state.steam_gateb and state.steam_gateb.start then
                    steam_debug_log(state, "MP STEAM GATEB | bootstrap start_called")
                    state.steam_gateb.start()
                else
                    steam_debug_log(state, "MP STEAM GATEB | bootstrap start_missing")
                end
            else
                steam_debug_log(state, "MP STEAM GATEB | bootstrap module_missing")
            end
            return
        end
        state.steam_connected = false
        dispatch_status("error", {
            mode = "steam",
            reason = "steam_probe_failed",
            available = available,
            has_send_message_to_user = has_send,
            has_receive_messages_on_channel = has_receive,
            has_accept_session_with_user = has_accept
        })
    end

    transport.connect = function()
        if state.mode == "steam" then
            steam_connect_if_needed()
            return
        end
        websocket_connect_if_needed()
    end

    return transport
end

return M
