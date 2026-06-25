local M = {}

local IDENTITY = {
    mode = "identity",
    a = 1.0,
    b = 0.0,
    c = 0.0,
    d = 0.0,
    e = 1.0,
    f = 0.0
}

local MAC_AFFINE = {
    mode = "affine",
    a = 1.402957,
    b = 0.012509,
    c = -260.542776,
    d = -0.003697,
    e = 1.554141,
    f = -200.530050
}

local WINDOWS_1080_CANDIDATE = {
    mode = "affine",
    a = 1.483548,
    b = 0.015011,
    c = -312.651332,
    d = -0.002958,
    e = 1.443313,
    f = -160.424040
}

local WINDOWS_1440_CANDIDATE = {
    mode = "affine",
    a = 1.463401,
    b = 0.014385,
    c = -299.624192,
    d = -0.003032,
    e = 1.454396,
    f = -164.434641
}

local PROFILES = {
    {
        id = "mac_windowed_identity",
        platform = "Darwin",
        min_window_scale = 0.0,
        max_window_scale = 2.299,
        preset = IDENTITY,
        hud = {
            expanded_min_window_scale = 2.3,
            portrait_dx = 0,
            left_cluster_dx = 0,
            left_cluster_dy = 0,
            right_cluster_dx = 0,
            right_cluster_dy = 0,
            human_ui_dx = 0,
            human_ui_dy = 0,
            exit_dx = 0,
            exit_dy = 0,
            score_dx = 0,
            score_dy = 0,
            build_version_dx = 0,
            build_version_dy = 0
        }
    },
    {
        id = "mac_maximized_affine",
        platform = "Darwin",
        min_window_scale = 2.3,
        preset = MAC_AFFINE,
        hud = {
            expanded_min_window_scale = 2.3,
            portrait_dx = 0,
            left_cluster_dx = 0,
            left_cluster_dy = 0,
            right_cluster_dx = 0,
            right_cluster_dy = 0,
            human_ui_dx = 0,
            human_ui_dy = 0,
            exit_dx = 0,
            exit_dy = 0,
            score_dx = 0,
            score_dy = 0,
            build_version_dx = 0,
            build_version_dy = 0
        }
    },
    {
        id = "windows_1920x1080_candidate_v1",
        platform = "Windows",
        min_width = 1800,
        max_width = 2048,
        min_height = 1000,
        max_height = 1200,
        min_window_scale = 1.0,
        preset = WINDOWS_1080_CANDIDATE,
        hud = {
            expanded_min_window_scale = 1.0,
            portrait_dx = 0,
            left_cluster_dx = 0,
            left_cluster_dy = 0,
            right_cluster_dx = 0,
            right_cluster_dy = 0,
            human_ui_dx = 0,
            human_ui_dy = 0,
            exit_dx = 0,
            exit_dy = 0,
            score_dx = 0,
            score_dy = 0,
            build_version_dx = 0,
            build_version_dy = 0
        }
    },
    {
        id = "windows_2560x1440_candidate_v1",
        platform = "Windows",
        min_width = 2400,
        max_width = 2700,
        min_height = 1320,
        max_height = 1520,
        min_window_scale = 1.0,
        preset = WINDOWS_1440_CANDIDATE,
        hud = {
            expanded_min_window_scale = 1.0,
            portrait_dx = 0
        }
    },
    {
        id = "windows_3840x2160_candidate_v1",
        platform = "Windows",
        min_width = 3600,
        max_width = 4200,
        min_height = 2000,
        max_height = 2300,
        min_window_scale = 1.0,
        preset = WINDOWS_1080_CANDIDATE,
        hud = {
            expanded_min_window_scale = 1.0,
            portrait_dx = 0
        }
    },
    {
        id = "windows_3440x1440_ultrawide_identity_v1",
        platform = "Windows",
        min_width = 3200,
        max_width = 3599,
        min_height = 1300,
        max_height = 1500,
        min_window_scale = 1.0,
        preset = WINDOWS_1440_CANDIDATE,
        hud = {
            expanded_min_window_scale = 1.0,
            portrait_dx = 0,
            human_ui_dx = 350,
            left_cluster_dx = 350,
            exit_dx = 350
        }
    },
    {
        id = "windows_fallback_identity",
        platform = "Windows",
        min_window_scale = 0.0,
        preset = IDENTITY
    },
    {
        id = "native_fallback_identity",
        platform = "*",
        min_window_scale = 0.0,
        preset = IDENTITY
    }
}

local function matches(profile, platform, win_w, win_h, window_scale)
    if profile.platform ~= "*" and profile.platform ~= platform then
        return false
    end
    if profile.min_width and win_w < profile.min_width then
        return false
    end
    if profile.max_width and win_w > profile.max_width then
        return false
    end
    if profile.min_height and win_h < profile.min_height then
        return false
    end
    if profile.max_height and win_h > profile.max_height then
        return false
    end
    if profile.min_window_scale and window_scale < profile.min_window_scale then
        return false
    end
    if profile.max_window_scale and window_scale > profile.max_window_scale then
        return false
    end
    return true
end

function M.resolve(platform, win_w, win_h, window_scale)
    local p = tostring(platform or "")
    local w = tonumber(win_w or 0) or 0
    local h = tonumber(win_h or 0) or 0
    local s = tonumber(window_scale or 0) or 0
    for _, profile in ipairs(PROFILES) do
        if matches(profile, p, w, h, s) then
            local preset = profile.preset or IDENTITY
            return {
                id = profile.id,
                min_window_scale = profile.min_window_scale or 0.0,
                mode = preset.mode or "identity",
                a = preset.a,
                b = preset.b,
                c = preset.c,
                d = preset.d,
                e = preset.e,
                f = preset.f,
                hud = profile.hud
            }
        end
    end
    return nil
end

return M
