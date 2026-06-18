-- MP lobby lifecycle (L1): explicit states + transition logging only.
local M = {}

M.GUEST_DISCONNECTED = "DISCONNECTED"
M.GUEST_STEAM_JOINING = "STEAM_JOINING"
M.GUEST_JOIN_WIRE_PENDING = "JOIN_WIRE_PENDING"
M.GUEST_IN_ROSTER = "IN_ROSTER"
M.GUEST_SETUP_SYNCED = "SETUP_SYNCED"
M.GUEST_IN_MATCH = "IN_MATCH"

M.HOST_ALONE = "ALONE"
M.HOST_GUESTS_JOINING = "GUESTS_JOINING"
M.HOST_READY_TO_LAUNCH = "READY_TO_LAUNCH"
M.HOST_LAUNCHED = "LAUNCHED"

local function to_string(value)
    return tostring(value or "")
end

function M.ensure(lobby)
    if type(lobby) ~= "table" then
        return
    end
    if lobby.lifecycle_guest_state == nil then
        lobby.lifecycle_guest_state = M.GUEST_DISCONNECTED
    end
    if lobby.lifecycle_host_state == nil then
        lobby.lifecycle_host_state = M.HOST_ALONE
    end
end

local function log_transition(role, from_state, to_state, detail, log_fn)
    if from_state == to_state then
        return
    end
    local extra = ""
    if type(detail) == "table" then
        local parts = {}
        for key, value in pairs(detail) do
            parts[#parts + 1] = to_string(key) .. "=" .. to_string(value)
        end
        if #parts > 0 then
            extra = " " .. table.concat(parts, " ")
        end
    elseif detail ~= nil and to_string(detail) ~= "" then
        extra = " " .. to_string(detail)
    end
    local message = string.format(
        "MP LOBBY | lifecycle %s %s→%s%s",
        role,
        to_string(from_state),
        to_string(to_state),
        extra
    )
    if type(log_fn) == "function" then
        log_fn(message)
    end
end

function M.guest_transition(lobby, new_state, detail, log_fn)
    if type(lobby) ~= "table" then
        return false
    end
    M.ensure(lobby)
    new_state = to_string(new_state)
    if new_state == "" then
        return false
    end
    local prev = lobby.lifecycle_guest_state
    if prev == new_state then
        return false
    end
    lobby.lifecycle_guest_state = new_state
    log_transition("guest", prev, new_state, detail, log_fn)
    return true
end

function M.host_transition(lobby, new_state, detail, log_fn)
    if type(lobby) ~= "table" then
        return false
    end
    M.ensure(lobby)
    new_state = to_string(new_state)
    if new_state == "" then
        return false
    end
    local prev = lobby.lifecycle_host_state
    if prev == new_state then
        return false
    end
    lobby.lifecycle_host_state = new_state
    log_transition("host", prev, new_state, detail, log_fn)
    return true
end

function M.guest_state(lobby)
    if type(lobby) ~= "table" then
        return M.GUEST_DISCONNECTED
    end
    M.ensure(lobby)
    return lobby.lifecycle_guest_state
end

function M.host_state(lobby)
    if type(lobby) ~= "table" then
        return M.HOST_ALONE
    end
    M.ensure(lobby)
    return lobby.lifecycle_host_state
end

function M.refresh_host_derived(lobby, guest_count, guests_synced, log_fn)
    if type(lobby) ~= "table" then
        return
    end
    guest_count = tonumber(guest_count or 0) or 0
    local target = M.HOST_ALONE
    if guest_count > 0 then
        target = guests_synced == true and M.HOST_READY_TO_LAUNCH or M.HOST_GUESTS_JOINING
    end
    if lobby.lifecycle_host_state == M.HOST_LAUNCHED then
        return
    end
    M.host_transition(lobby, target, {
        guests = guest_count,
        synced = guests_synced == true and "yes" or "no"
    }, log_fn)
end

return M
