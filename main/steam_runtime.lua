local M = {}

local RUNTIME = {
    backend = nil,
    initialized = false,
    events = {}
}

local function cfg_bool(value, default_value)
    local raw = tostring(value or default_value or "0")
    return raw == "1" or raw == "true" or raw == "on"
end

local function get_system_name()
    local info = sys.get_sys_info and sys.get_sys_info() or nil
    return tostring(info and info.system_name or "")
end

local function read_cfg()
    return {
        enabled = cfg_bool(sys.get_config and sys.get_config("dvx.steam_enabled"), "0"),
        appid = tostring((sys.get_config and sys.get_config("dvx.steam_appid")) or ""),
        windows_only = cfg_bool(sys.get_config and sys.get_config("dvx.steam_windows_only"), "1"),
        log_verbose = cfg_bool(sys.get_config and sys.get_config("dvx.steam_log_verbose"), "0")
    }
end

local function resolve_backend()
    local global_steam = rawget(_G, "steam")
    if type(global_steam) == "table" then
        return global_steam, "global_steam"
    end
    local ok_steam, steam_mod = pcall(require, "steam")
    if ok_steam and type(steam_mod) == "table" then
        return steam_mod, "steam"
    end
    return nil, "unavailable"
end

local function try_call(tbl, key, ...)
    if type(tbl) ~= "table" or type(tbl[key]) ~= "function" then
        return nil
    end
    local ok, a, b = pcall(tbl[key], ...)
    if ok then
        return a, b
    end
    return nil, nil
end

local function read_identity(backend)
    local steam_id = try_call(backend, "user_get_steam_id") or ""
    local display_name = try_call(backend, "friends_get_persona_name") or ""
    return tostring(steam_id or ""), tostring(display_name or "")
end

function M.get_backend()
    return RUNTIME.backend
end

function M.update()
    if RUNTIME.initialized ~= true or type(RUNTIME.backend) ~= "table" then
        return
    end
    try_call(RUNTIME.backend, "update")
end

function M.consume_events()
    local events = RUNTIME.events
    RUNTIME.events = {}
    return events
end

function M.finalize()
    if RUNTIME.initialized == true and type(RUNTIME.backend) == "table" then
        try_call(RUNTIME.backend, "final")
    end
    RUNTIME.initialized = false
    RUNTIME.backend = nil
    RUNTIME.events = {}
end

function M.init()
    local cfg = read_cfg()
    local system_name = get_system_name()
    local is_windows = (system_name == "Windows")
    local state = {
        enabled = false,
        available = false,
        initialized = false,
        init_error = "disabled_by_config",
        appid = cfg.appid,
        system_name = system_name,
        backend_name = "",
        module_present = false,
        steam_id = "",
        display_name = "",
        log_verbose = cfg.log_verbose == true
    }
    if cfg.enabled ~= true then
        return state
    end
    if cfg.windows_only == true and is_windows ~= true then
        state.init_error = "unsupported_platform"
        return state
    end
    state.enabled = true
    local backend, backend_name = resolve_backend()
    state.backend_name = backend_name
    state.module_present = type(backend) == "table"
    if type(backend) ~= "table" then
        state.init_error = "backend_unavailable"
        return state
    end
    state.available = true
    local ok_init, init_error = try_call(backend, "init")
    if ok_init ~= true then
        state.init_error = tostring(init_error or "steam_init_failed")
        return state
    end
    RUNTIME.backend = backend
    RUNTIME.initialized = true
    RUNTIME.events = {}
    try_call(backend, "set_listener", function(event, data)
        RUNTIME.events[#RUNTIME.events + 1] = { event = event, data = data or {} }
    end)
    local steam_id, display_name = read_identity(backend)
    state.steam_id = steam_id
    state.display_name = display_name
    state.initialized = true
    state.init_error = ""
    return state
end

return M
