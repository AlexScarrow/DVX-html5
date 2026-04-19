local M = {}

local ok_json, json = pcall(require, "json")

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

function M.create(opts)
    local state = {
        mode = (opts and opts.mode) or "loopback",
        on_command = opts and opts.on_command or nil,
        on_event = opts and opts.on_event or nil,
        on_status = opts and opts.on_status or nil,
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
        ws_status = "idle"
    }

    local transport = {}

    local function dispatch_status(status, detail)
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

    local function dispatch_events(events)
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
        dispatch_events(events)
    end

    function transport.shutdown()
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

    function transport.update(dt)
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

    transport.connect = websocket_connect_if_needed

    return transport
end

return M
