local M = {}

local websocket = rawget(_G, "websocket")
local ok_json, json = pcall(require, "json")

local function normalize_callback_args(a, b, c)
    if type(c) == "table" and c.event ~= nil then
        return b, c
    end
    if type(b) == "table" and b.event ~= nil then
        return a, b
    end
    return b or a, c or b
end

function M.connect(url, join_payload, handlers)
    if not (websocket and websocket.connect and websocket.send and websocket.disconnect) then
        print("MP WS ADAPTER | websocket extension not bound; staying on loopback. url=" .. tostring(url))
        if handlers and handlers.on_error then
            handlers.on_error("websocket_extension_not_bound")
        end
        return nil
    end

    local conn = nil
    local params = {
        timeout = 5000
    }

    local function on_ws_message(a, b, c)
        local callback_conn, data = normalize_callback_args(a, b, c)
        if not data or type(data) ~= "table" then
            return
        end
        if data.event == websocket.EVENT_CONNECTED then
            if handlers and handlers.on_open then
                local ok_open, err_open = pcall(handlers.on_open)
                if not ok_open then
                    print("MP WS ADAPTER | on_open callback failed: " .. tostring(err_open))
                end
            end
            local join_packet = {
                version = 1,
                type = "join_room",
                payload = {
                    room_id = join_payload and join_payload.room_id or "default_room",
                    player_id = join_payload and join_payload.player_id or "p1"
                }
            }
            if ok_json and json and json.encode then
                local ok_send, err_send = pcall(websocket.send, callback_conn, json.encode(join_packet))
                if not ok_send then
                    print("MP WS ADAPTER | join send failed: " .. tostring(err_send))
                    if handlers and handlers.on_error then
                        handlers.on_error("join_send_failed")
                    end
                end
            elseif handlers and handlers.on_error then
                handlers.on_error("json_not_available")
            end
            return
        end
        if data.event == websocket.EVENT_MESSAGE then
            if handlers and handlers.on_message then
                local ok_msg, err_msg = pcall(handlers.on_message, data.message)
                if not ok_msg then
                    print("MP WS ADAPTER | on_message callback failed: " .. tostring(err_msg))
                    if handlers.on_error then
                        handlers.on_error("on_message_failed")
                    end
                end
            end
            return
        end
        if data.event == websocket.EVENT_ERROR then
            if handlers and handlers.on_error then
                local ok_err, err_err = pcall(handlers.on_error, data.message or "websocket_error")
                if not ok_err then
                    print("MP WS ADAPTER | on_error callback failed: " .. tostring(err_err))
                end
            end
            return
        end
        if data.event == websocket.EVENT_DISCONNECTED then
            if handlers and handlers.on_close then
                local ok_close, err_close = pcall(handlers.on_close, data.code)
                if not ok_close then
                    print("MP WS ADAPTER | on_close callback failed: " .. tostring(err_close))
                end
            end
        end
    end

    conn = websocket.connect(url, params, on_ws_message)
    return conn
end

function M.send_text(client, raw_text)
    if not (websocket and websocket.send and client and raw_text) then
        return false
    end
    local ok_send, err_send = pcall(websocket.send, client, raw_text)
    if not ok_send then
        print("MP WS ADAPTER | send_text failed: " .. tostring(err_send))
        return false
    end
    return true
end

function M.close(client)
    if websocket and websocket.disconnect and client then
        pcall(websocket.disconnect, client)
    end
end

return M
