local M = {}

function M.extend(runtime, ctx)
    local WEED_VISUAL_Z = 0.685
    local WEED_VARIANTS = { hash("weed1"), hash("weed2"), hash("weed3") }
    local WEED_PULSE_AMPLITUDE = 0.028
    local WEED_PULSE_SPEED = 4.7
    local WEED_PULSE_SQUASH_RATIO = 0.6
    local WEED_PULSE_AMPLITUDE_MIN_MUL = 0.9
    local WEED_PULSE_AMPLITUDE_MAX_MUL = 1.15
    local WEED_PULSE_SPEED_MIN_MUL = 0.9
    local WEED_PULSE_SPEED_MAX_MUL = 1.12
    local WEED_ANIM_ENABLED = true -- TEMP PERF TEST toggle
    local WEED_BURST_ACTIVE_COUNT = 2
    local WEED_BURST_CYCLES = 3
    local WEED_BURST_COOLDOWN_S = 2.5
    local WEED_BURST_RESELECT_S = 0.45
    local WEED_BURST_DECAY_START = 1.0
    local WEED_BURST_DECAY_END = 0.35
    local WEED_TRIGGER_BURST_DURATION_S = 0.6
    local WEED_TRIGGER_FIRST_CYCLE_BOOST = 1.45
    local WEED_SPAWN_GROW_S = 5.0
    local WEED_SPAWN_START_SCALE = 0.86
    local WEED_ROCK_MAX_RAD = 0.0
    local WEED_ROCK_SPEED = 2.4
    local WEED_VISUAL_TICK_S = 0.05
    local WEED_DYING_FADE_S = 5.0
    local WEED_DYING_PULSE_SPEED_MUL = 4.0
    local WEED_DYING_PULSE_AMPLITUDE_MUL = 2.0
    local WEED_NEIGHBOR_DIRS = { "up", "left", "right", "down" }
    local FLAME_CELL_TURNS = 2
    local FLAMER_MAX_SHOTS = 10
    local FLAME_MARKER_Z = 0.74
    local FLAME_MARKER_SCALE_MUL = 0.88
    local FLAME_MARKER_OFFSET_X = -15
    local FLAME_MARKER_OFFSET_Y = 10

    local function is_cleanse_mission(self)
        if not (ctx and ctx.get_current_mission_type) then
            return false
        end
        return tostring(ctx.get_current_mission_type(self) or "") == "cleanse"
    end

    local function is_cell_void_or_invalid(self, cell_id)
        local cell = self and self.world_grid and self.world_grid[cell_id] or nil
        if not cell then
            return true
        end
        if cell.tileID == hash("empty") or cell.tileID == hash("void") then
            return true
        end
        if cell.isOutside == true then
            return true
        end
        return false
    end

    local function list_valid_non_void_cells(self)
        local out = {}
        for _, cell in ipairs(self and self.world_grid or {}) do
            if cell
                and cell.tileID ~= hash("empty")
                and cell.tileID ~= hash("void")
                and cell.isOutside ~= true
            then
                out[#out + 1] = tonumber(cell.idNumber or 0) or 0
            end
        end
        return out
    end

    local function clear_weed_visuals(state)
        for _, go_id in pairs(state.weed_visuals or {}) do
            if go_id then
                pcall(go.delete, go_id)
            end
        end
        state.weed_visuals = {}
        for _, entry in pairs(state.dying_weed_visuals or {}) do
            local go_id = entry and entry.go_id or nil
            if go_id then
                pcall(go.delete, go_id)
            end
        end
        state.dying_weed_visuals = {}
        state.weed_variant_by_cell = {}
        state.weed_spawn_s_by_cell = {}
    end

    local function clear_flame_fx(state)
        for _, go_id in pairs(state.flame_fx_objects or {}) do
            if go_id then
                pcall(go.delete, go_id)
            end
        end
        state.flame_fx_objects = {}
        for _, marker_id in pairs(state.flame_marker_objects or {}) do
            if marker_id then
                pcall(go.delete, marker_id)
            end
        end
        state.flame_marker_objects = {}
        for _, go_id in pairs(state.flamer_jet_fx_objects or {}) do
            if go_id then
                pcall(go.delete, go_id)
            end
        end
        state.flamer_jet_fx_objects = {}
    end

    local function clear_cleanse_runtime_state(self)
        self.cleanse_state = self.cleanse_state or {}
        clear_weed_visuals(self.cleanse_state)
        clear_flame_fx(self.cleanse_state)
        self.cleanse_state = {
            weed_cells = {},
            weed_visuals = {},
            dying_weed_visuals = {},
            weed_variant_by_cell = {},
            weed_spawn_s_by_cell = {},
            weed_tick_accum_s = 0,
            weed_burst_accum_s = 0,
            weed_burst_cells = {},
            weed_burst_prev_active = {},
            weed_burst_cooldown_cells = {},
            weed_trigger_cells = {},
            total_valid_cells = 0,
            flame_cells = {},
            flamer_shots_by_unit_id = {},
            flame_visual_reveal_s_by_cell = {},
            flame_fx_objects = {},
            flame_marker_objects = {},
            flamer_jet_fx_objects = {},
            flame_marker_phase = 0,
            fx_clock_s = 0,
            cleanse_visuals_dirty = true,
            mission_initialized = false,
            portal_center_cell_id = nil
        }
    end

    local function has_blocking_edge(self, from_cell_id, to_cell_id)
        if ctx.is_cell_barricaded and ctx.is_cell_barricaded(self.world_grid, to_cell_id) then
            return true
        end
        if ctx.get_edge_door_context then
            local _, _, closed = ctx.get_edge_door_context(self.world_grid, from_cell_id, to_cell_id)
            if closed then
                return true
            end
        end
        return false
    end

    local function can_grow_into_cell(self, from_cell_id, to_cell_id)
        if not to_cell_id then
            return false
        end
        if is_cell_void_or_invalid(self, to_cell_id) then
            return false
        end
        local state = self.cleanse_state or {}
        if state.weed_cells and state.weed_cells[to_cell_id] == true then
            return false
        end
        if (tonumber(state.flame_cells and state.flame_cells[to_cell_id] or 0) or 0) > 0 then
            return false
        end
        if not (ctx.can_cross_between_cells and ctx.can_cross_between_cells(self.world_grid, from_cell_id, to_cell_id)) then
            return false
        end
        if has_blocking_edge(self, from_cell_id, to_cell_id) then
            return false
        end
        return true
    end

    local function add_weed_cell(self, cell_id)
        local state = self.cleanse_state
        if not (state and cell_id and state.weed_cells[cell_id] ~= true) then
            return false
        end
        if is_cell_void_or_invalid(self, cell_id) then
            return false
        end
        state.weed_cells[cell_id] = true
        state.cleanse_visuals_dirty = true
        return true
    end

    local function get_unit_id_key(unit)
        return tostring(unit and unit.id or "")
    end

    local function get_or_init_flamer_shots(self, unit, allow_init)
        local state = self and self.cleanse_state or nil
        if not (state and unit and unit.id) then
            return 0
        end
        state.flamer_shots_by_unit_id = state.flamer_shots_by_unit_id or {}
        local key = get_unit_id_key(unit)
        if key == "" then
            return 0
        end
        if not (ctx and ctx.unit_has_equipped_buff_kind and ctx.unit_has_equipped_buff_kind(unit, "flamer")) then
            state.flamer_shots_by_unit_id[key] = nil
            return 0
        end
        local shots = tonumber(state.flamer_shots_by_unit_id[key] or -1) or -1
        if shots < 0 and allow_init == true then
            shots = FLAMER_MAX_SHOTS
            state.flamer_shots_by_unit_id[key] = shots
        end
        if shots < 0 then
            return 0
        end
        return math.max(0, math.floor(shots + 0.5))
    end

    local function consume_flamer_shot(self, unit)
        local state = self and self.cleanse_state or nil
        if not (state and unit and unit.id) then
            return false, 0
        end
        local current = get_or_init_flamer_shots(self, unit, true)
        if current <= 0 then
            return false, 0
        end
        local next_shots = current - 1
        local key = get_unit_id_key(unit)
        state.flamer_shots_by_unit_id[key] = next_shots
        if next_shots <= 0 and type(unit.equipment) == "table" then
            for slot_name, item_type in pairs(unit.equipment) do
                if item_type == "buff_flamer" then
                    unit.equipment[slot_name] = nil
                end
            end
        end
        return true, next_shots
    end

    local function get_weed_pulse_style(cell_id)
        local key = tonumber(cell_id or 0) or 0
        local amp_roll = ((key * 37) % 100) / 100
        local speed_roll = ((key * 53) % 100) / 100
        local amp_mul = WEED_PULSE_AMPLITUDE_MIN_MUL + ((WEED_PULSE_AMPLITUDE_MAX_MUL - WEED_PULSE_AMPLITUDE_MIN_MUL) * amp_roll)
        local speed_mul = WEED_PULSE_SPEED_MIN_MUL + ((WEED_PULSE_SPEED_MAX_MUL - WEED_PULSE_SPEED_MIN_MUL) * speed_roll)
        local phase_offset = ((key * 17) % 628) / 100
        return amp_mul, speed_mul, phase_offset
    end

    local function get_weed_burst_decay_mul(state, cell_id, clock_s, speed_mul)
        local end_s = tonumber(state and state.weed_burst_cells and state.weed_burst_cells[cell_id] or 0) or 0
        if end_s <= clock_s then
            return 1.0
        end
        local speed = math.max(0.001, WEED_PULSE_SPEED * (tonumber(speed_mul or 1.0) or 1.0))
        local cycle_s = (math.pi * 2.0) / speed
        local total_s = math.max(0.001, cycle_s * WEED_BURST_CYCLES)
        local start_s = end_s - total_s
        local progress = math.max(0, math.min(1, (clock_s - start_s) / total_s))
        return WEED_BURST_DECAY_START + ((WEED_BURST_DECAY_END - WEED_BURST_DECAY_START) * progress)
    end

    local function get_weed_trigger_boost_mul(state, cell_id, clock_s, speed_mul)
        local end_s = tonumber(state and state.weed_trigger_cells and state.weed_trigger_cells[cell_id] or 0) or 0
        if end_s <= clock_s then
            return 1.0
        end
        local speed = math.max(0.001, WEED_PULSE_SPEED * (tonumber(speed_mul or 1.0) or 1.0))
        local cycle_s = (math.pi * 2.0) / speed
        local start_s = end_s - WEED_TRIGGER_BURST_DURATION_S
        local cycle_progress = math.max(0, math.min(1, (clock_s - start_s) / cycle_s))
        return WEED_TRIGGER_FIRST_CYCLE_BOOST + ((1.0 - WEED_TRIGGER_FIRST_CYCLE_BOOST) * cycle_progress)
    end

    local function choose_weed_variant_idx(self, state, cell_id)
        local used_by_neighbors = {}
        for _, dir in ipairs(WEED_NEIGHBOR_DIRS) do
            local adj = ctx.get_adjacent_cell and ctx.get_adjacent_cell(cell_id, dir) or nil
            if adj then
                local adj_idx = state.weed_variant_by_cell and state.weed_variant_by_cell[adj] or nil
                if adj_idx then
                    used_by_neighbors[adj_idx] = true
                end
            end
        end
        local candidates = {}
        for idx = 1, #WEED_VARIANTS do
            if used_by_neighbors[idx] ~= true then
                candidates[#candidates + 1] = idx
            end
        end
        if #candidates <= 0 then
            local key = tonumber(cell_id or 0) or 0
            return ((key % #WEED_VARIANTS) + 1)
        end
        local pick_key = tonumber(cell_id or 0) or 0
        local pick_i = ((pick_key * 19) % #candidates) + 1
        return candidates[pick_i]
    end

    local function start_dying_weed_visual(self, cell_id, weed_go)
        local state = self.cleanse_state
        if not (state and weed_go and cell_id) then
            return
        end
        local existing = state.dying_weed_visuals and state.dying_weed_visuals[cell_id] or nil
        if existing and existing.go_id then
            pcall(go.delete, existing.go_id)
        end
        local amp_mul, speed_mul, phase_offset = get_weed_pulse_style(cell_id)
        state.dying_weed_visuals = state.dying_weed_visuals or {}
        state.dying_weed_visuals[cell_id] = {
            go_id = weed_go,
            start_s = tonumber(state.fx_clock_s or 0) or 0,
            amp_mul = amp_mul,
            speed_mul = speed_mul,
            phase_offset = phase_offset
        }
    end

    local function get_weed_tint_for_cell(self, state, cell_id, alpha)
        local a = tonumber(alpha or 1) or 1
        local flaming = (tonumber(state and state.flame_cells and state.flame_cells[cell_id] or 0) or 0) > 0
        if flaming then
            return vmath.vector4(0, 0, 0, a)
        end
        return vmath.vector4(1, 1, 1, a)
    end

    local function remove_weed_cell(self, cell_id, burned)
        local state = self.cleanse_state
        if not (state and state.weed_cells and state.weed_cells[cell_id]) then
            return false
        end
        state.weed_cells[cell_id] = nil
        if state.weed_variant_by_cell then
            state.weed_variant_by_cell[cell_id] = nil
        end
        if state.weed_spawn_s_by_cell then
            state.weed_spawn_s_by_cell[cell_id] = nil
        end
        local weed_go = state.weed_visuals and state.weed_visuals[cell_id] or nil
        if weed_go then
            state.weed_visuals[cell_id] = nil
            if burned == true then
                start_dying_weed_visual(self, cell_id, weed_go)
            else
                pcall(go.delete, weed_go)
            end
        end
        state.cleanse_visuals_dirty = true
        return true
    end

    local function refresh_weed_visuals(self)
        local state = self.cleanse_state
        if not state then
            return
        end
        state.weed_variant_by_cell = state.weed_variant_by_cell or {}
        state.dying_weed_visuals = state.dying_weed_visuals or {}
        state.weed_spawn_s_by_cell = state.weed_spawn_s_by_cell or {}
        for cell_id, go_id in pairs(state.weed_visuals or {}) do
            if state.weed_cells[cell_id] ~= true and go_id then
                pcall(go.delete, go_id)
                state.weed_visuals[cell_id] = nil
            end
            if state.weed_cells[cell_id] ~= true and state.weed_burst_cells then
                state.weed_burst_cells[cell_id] = nil
            end
            if state.weed_cells[cell_id] ~= true and state.weed_burst_cooldown_cells then
                state.weed_burst_cooldown_cells[cell_id] = nil
            end
            if state.weed_cells[cell_id] ~= true and state.weed_burst_prev_active then
                state.weed_burst_prev_active[cell_id] = nil
            end
            if state.weed_cells[cell_id] ~= true and state.weed_trigger_cells then
                state.weed_trigger_cells[cell_id] = nil
            end
            if state.weed_cells[cell_id] ~= true and state.weed_variant_by_cell then
                state.weed_variant_by_cell[cell_id] = nil
            end
            if state.weed_cells[cell_id] ~= true and state.weed_spawn_s_by_cell then
                state.weed_spawn_s_by_cell[cell_id] = nil
            end
        end
        for cell_id, present in pairs(state.weed_cells or {}) do
            if present == true and not state.weed_visuals[cell_id] then
                local cell = self.world_grid and self.world_grid[cell_id] or nil
                if cell then
                    local dying = state.dying_weed_visuals and state.dying_weed_visuals[cell_id] or nil
                    if dying and dying.go_id then
                        pcall(go.delete, dying.go_id)
                        state.dying_weed_visuals[cell_id] = nil
                    end
                    local wx, wy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                    local go_id = factory.create("/loot_marker_factory#loot_marker_factory", vmath.vector3(wx, wy, WEED_VISUAL_Z))
                    if go_id then
                        local variant_idx = choose_weed_variant_idx(self, state, cell_id)
                        msg.post(msg.url(nil, go_id, "sprite"), "play_animation", { id = WEED_VARIANTS[variant_idx] })
                        go.set(msg.url(nil, go_id, "sprite"), "tint", vmath.vector4(1, 1, 1, 1))
                        go.set_scale(vmath.vector3(1, 1, 1), go_id)
                        pcall(go.set, msg.url(nil, go_id, "sprite"), "blend_mode", hash("alpha"))
                        state.weed_visuals[cell_id] = go_id
                        state.weed_variant_by_cell[cell_id] = variant_idx
                        state.weed_spawn_s_by_cell[cell_id] = tonumber(state.fx_clock_s or 0) or 0
                    end
                end
            end
        end
    end

    local function apply_flame_kill_on_cell(self, cell_id)
        if not (ctx and ctx.furnace_kill_units_on_cell) then
            return
        end
        ctx.furnace_kill_units_on_cell(self, cell_id)
    end

    local function is_flame_visual_revealed(state, cell_id)
        local reveal_s = state and state.flame_visual_reveal_s_by_cell and state.flame_visual_reveal_s_by_cell[cell_id] or nil
        if reveal_s == nil then
            return true
        end
        local now_s = tonumber(state and state.fx_clock_s or 0) or 0
        return now_s >= (tonumber(reveal_s or 0) or 0)
    end

    local function refresh_flame_fx(self)
        local state = self.cleanse_state
        if not state then
            return
        end
        for cell_id, go_id in pairs(state.flame_fx_objects or {}) do
            local active = (tonumber(state.flame_cells[cell_id] or 0) or 0) > 0
            local revealed = is_flame_visual_revealed(state, cell_id)
            if (not active or not revealed) and go_id then
                pcall(go.delete, go_id)
                state.flame_fx_objects[cell_id] = nil
            end
            if not active and state.flame_visual_reveal_s_by_cell then
                state.flame_visual_reveal_s_by_cell[cell_id] = nil
            end
        end
        for cell_id, turns_left in pairs(state.flame_cells or {}) do
            if (tonumber(turns_left or 0) or 0) > 0
                and is_flame_visual_revealed(state, cell_id)
                and not state.flame_fx_objects[cell_id]
            then
                local cell = self.world_grid and self.world_grid[cell_id] or nil
                if cell then
                    local wx, wy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                    local fx_go = factory.create("/fire_fx_factory#fire_fx_factory", vmath.vector3(wx, wy - 35, 0.69))
                    if fx_go then
                        pcall(particlefx.play, msg.url(nil, fx_go, "particlefx"))
                        state.flame_fx_objects[cell_id] = fx_go
                    end
                end
            end
        end
    end

    local function refresh_flame_markers(self)
        local state = self.cleanse_state
        if not state then
            return
        end
        state.flame_marker_objects = state.flame_marker_objects or {}
        for cell_id, marker_id in pairs(state.flame_marker_objects) do
            local active = (tonumber(state.flame_cells[cell_id] or 0) or 0) > 0
            local revealed = is_flame_visual_revealed(state, cell_id)
            if (not active or not revealed) then
                if marker_id then
                    pcall(go.delete, marker_id)
                end
                state.flame_marker_objects[cell_id] = nil
            end
        end
        for cell_id, turns_left in pairs(state.flame_cells or {}) do
            if (tonumber(turns_left or 0) or 0) > 0
                and is_flame_visual_revealed(state, cell_id)
                and state.flame_marker_objects[cell_id] == nil
            then
                local cell = self.world_grid and self.world_grid[cell_id] or nil
                if cell then
                    local wx, wy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                    local marker_id = factory.create("/ui_alpha_factory#ui_alpha_factory", vmath.vector3(wx + FLAME_MARKER_OFFSET_X, wy + FLAME_MARKER_OFFSET_Y, FLAME_MARKER_Z))
                    if marker_id then
                        local sx = (tonumber(ctx.CELL_WIDTH or 250) or 250) * FLAME_MARKER_SCALE_MUL
                        local sy = (tonumber(ctx.CELL_HEIGHT or 150) or 150) * FLAME_MARKER_SCALE_MUL
                        go.set_scale(vmath.vector3(sx, sy, 1), marker_id)
                        go.set(msg.url(nil, marker_id, "sprite"), "tint", vmath.vector4(1.0, 0.12, 0.12, 0.65))
                        state.flame_marker_objects[cell_id] = marker_id
                    end
                end
            end
        end
    end

    local function tick_flame_markers(self, dt)
        local state = self.cleanse_state
        if not state then
            return
        end
        state.flame_marker_phase = (tonumber(state.flame_marker_phase or 0) or 0) + ((tonumber(dt or 0) or 0) * 9.0)
        local pulse = 0.5 + (0.5 * math.sin(state.flame_marker_phase))
        local alpha = 0.35 + (0.4 * pulse)
        for cell_id, marker_id in pairs(state.flame_marker_objects or {}) do
            if marker_id then
                local cell = self.world_grid and self.world_grid[cell_id] or nil
                if cell then
                    local wx, wy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                    -- Snap to whole pixels to avoid slight sub-pixel drift illusion.
                    local px = math.floor((wx + FLAME_MARKER_OFFSET_X) + 0.5)
                    local py = math.floor((wy + FLAME_MARKER_OFFSET_Y) + 0.5)
                    go.set_position(vmath.vector3(px, py, FLAME_MARKER_Z), marker_id)
                    local sx = (tonumber(ctx.CELL_WIDTH or 250) or 250) * FLAME_MARKER_SCALE_MUL
                    local sy = (tonumber(ctx.CELL_HEIGHT or 150) or 150) * FLAME_MARKER_SCALE_MUL
                    go.set_scale(vmath.vector3(sx, sy, 1), marker_id)
                end
                go.set(msg.url(nil, marker_id, "sprite"), "tint", vmath.vector4(1.0, 0.12, 0.12, alpha))
            end
        end
    end

    local function refresh_weed_burst_selection(state)
        if not state then
            return
        end
        local clock_s = tonumber(state.fx_clock_s or 0) or 0
        state.weed_burst_cells = state.weed_burst_cells or {}
        state.weed_burst_cooldown_cells = state.weed_burst_cooldown_cells or {}
        for cell_id, end_s in pairs(state.weed_burst_cells) do
            if state.weed_visuals[cell_id] == nil then
                state.weed_burst_cells[cell_id] = nil
            elseif (tonumber(end_s or 0) or 0) <= clock_s then
                state.weed_burst_cells[cell_id] = nil
                state.weed_burst_cooldown_cells[cell_id] = clock_s + WEED_BURST_COOLDOWN_S
            end
        end
        for cell_id, end_s in pairs(state.weed_burst_cooldown_cells) do
            if state.weed_visuals[cell_id] == nil or (tonumber(end_s or 0) or 0) <= clock_s then
                state.weed_burst_cooldown_cells[cell_id] = nil
            end
        end
        local active_count = 0
        for _, _ in pairs(state.weed_burst_cells) do
            active_count = active_count + 1
        end
        local slots_to_fill = math.max(0, WEED_BURST_ACTIVE_COUNT - active_count)
        if slots_to_fill <= 0 then
            return
        end
        local candidates = {}
        for cell_id, go_id in pairs(state.weed_visuals or {}) do
            if go_id
                and state.weed_cells
                and state.weed_cells[cell_id] == true
                and state.weed_burst_cells[cell_id] == nil
                and (tonumber(state.weed_burst_cooldown_cells[cell_id] or 0) or 0) <= clock_s
            then
                candidates[#candidates + 1] = cell_id
            end
        end
        for _ = 1, slots_to_fill do
            if #candidates <= 0 then
                break
            end
            local pick_i = math.random(1, #candidates)
            local picked_cell = candidates[pick_i]
            candidates[pick_i] = candidates[#candidates]
            candidates[#candidates] = nil
            local _, speed_mul = get_weed_pulse_style(picked_cell)
            local speed = math.max(0.001, WEED_PULSE_SPEED * (tonumber(speed_mul or 1.0) or 1.0))
            local cycle_s = (math.pi * 2.0) / speed
            local duration_s = cycle_s * WEED_BURST_CYCLES
            state.weed_burst_cells[picked_cell] = clock_s + duration_s
        end
    end

    local function tick_weed_pulse(self)
        local state = self.cleanse_state
        if not state then
            return
        end
        local clock_s = tonumber(state.fx_clock_s or 0) or 0
        state.weed_burst_cells = state.weed_burst_cells or {}
        state.weed_burst_prev_active = state.weed_burst_prev_active or {}
        state.weed_trigger_cells = state.weed_trigger_cells or {}
        for cell_id, weed_go in pairs(state.weed_visuals or {}) do
            if weed_go then
                local amp_mul, speed_mul, phase_offset = get_weed_pulse_style(cell_id)
                local trigger_active = (tonumber(state.weed_trigger_cells[cell_id] or 0) or 0) > clock_s
                local speed_mul_eff = speed_mul
                local phase = (clock_s * WEED_PULSE_SPEED * speed_mul_eff) + phase_offset
                local s = math.sin(phase)
                local spawn_s = tonumber(state.weed_spawn_s_by_cell and state.weed_spawn_s_by_cell[cell_id] or 0) or 0
                local spawn_progress = math.max(0, math.min(1, (clock_s - spawn_s) / WEED_SPAWN_GROW_S))
                local spawn_scale = WEED_SPAWN_START_SCALE + ((1.0 - WEED_SPAWN_START_SCALE) * spawn_progress)
                local burst_active = (tonumber(state.weed_burst_cells[cell_id] or 0) or 0) > clock_s
                local animate_this = trigger_active or burst_active
                local flame_active = (tonumber(state.flame_cells and state.flame_cells[cell_id] or 0) or 0) > 0
                if animate_this then
                    local decay_mul = trigger_active and 1.0 or get_weed_burst_decay_mul(state, cell_id, clock_s, speed_mul)
                    local trigger_boost_mul = trigger_active and get_weed_trigger_boost_mul(state, cell_id, clock_s, speed_mul) or 1.0
                    local amp = WEED_PULSE_AMPLITUDE * amp_mul * spawn_progress * decay_mul * trigger_boost_mul
                    local sx = spawn_scale + (amp * s)
                    local sy = spawn_scale - ((amp * WEED_PULSE_SQUASH_RATIO) * s)
                    go.set_scale(vmath.vector3(sx, sy, 1), weed_go)
                    local rock_phase = (clock_s * WEED_ROCK_SPEED) + phase_offset
                    local rock_angle = WEED_ROCK_MAX_RAD * math.sin(rock_phase)
                    go.set_rotation(vmath.quat_rotation_z(rock_angle), weed_go)
                    go.set(msg.url(nil, weed_go, "sprite"), "tint", get_weed_tint_for_cell(self, state, cell_id, spawn_progress))
                elseif spawn_progress < 1.0 or flame_active then
                    go.set_scale(vmath.vector3(spawn_scale, spawn_scale, 1), weed_go)
                    go.set_rotation(vmath.quat_rotation_z(0), weed_go)
                    go.set(msg.url(nil, weed_go, "sprite"), "tint", get_weed_tint_for_cell(self, state, cell_id, spawn_progress))
                end
                state.weed_burst_prev_active[cell_id] = animate_this
            end
        end
        for cell_id, entry in pairs(state.dying_weed_visuals or {}) do
            local weed_go = entry and entry.go_id or nil
            if not weed_go then
                state.dying_weed_visuals[cell_id] = nil
            else
                local elapsed = clock_s - (tonumber(entry.start_s or 0) or 0)
                if elapsed >= WEED_DYING_FADE_S then
                    pcall(go.delete, weed_go)
                    state.dying_weed_visuals[cell_id] = nil
                else
                    local progress = math.max(0, math.min(1, elapsed / WEED_DYING_FADE_S))
                    local alpha = 1.0 - progress
                    local amp_mul = tonumber(entry.amp_mul or 1.0) or 1.0
                    local speed_mul = tonumber(entry.speed_mul or 1.0) or 1.0
                    local phase_offset = tonumber(entry.phase_offset or 0) or 0
                    local phase = (clock_s * WEED_PULSE_SPEED * speed_mul * WEED_DYING_PULSE_SPEED_MUL) + phase_offset
                    local s = math.sin(phase)
                    local amp = WEED_PULSE_AMPLITUDE * amp_mul * WEED_DYING_PULSE_AMPLITUDE_MUL
                    local sx = 1.0 + (amp * s)
                    local sy = 1.0 - ((amp * WEED_PULSE_SQUASH_RATIO) * s)
                    go.set_scale(vmath.vector3(sx, sy, 1), weed_go)
                    local rock_phase = (clock_s * WEED_ROCK_SPEED) + phase_offset
                    local rock_angle = WEED_ROCK_MAX_RAD * math.sin(rock_phase)
                    go.set_rotation(vmath.quat_rotation_z(rock_angle), weed_go)
                    go.set(msg.url(nil, weed_go, "sprite"), "tint", get_weed_tint_for_cell(self, state, cell_id, alpha))
                end
            end
        end
    end

    local function count_alive_humans(self)
        local count = 0
        for _, unit in pairs(self.squad_units or {}) do
            if unit and (tonumber(unit.current_health or 0) or 0) > 0 then
                count = count + 1
            end
        end
        return count
    end

    local function cleanse_portal_is_destroyed(self)
        local lookup = (ctx and ctx.get_purge_bomb_target_lookup and ctx.get_purge_bomb_target_lookup(self)) or {}
        for _, item in ipairs(self.world_item_instances or {}) do
            if item and item.item_type == "bomb" then
                local on_target = lookup[tonumber(item.cell_id or 0) or 0] == true
                local locked = item.meta and item.meta.purge_portal_locked == true
                if on_target or locked then
                    return true
                end
            end
        end
        return false
    end

    runtime.cleanse_is_active_mission = function(self)
        return is_cleanse_mission(self)
    end

    runtime.cleanse_cell_has_weed = function(self, cell_id)
        return self and self.cleanse_state and self.cleanse_state.weed_cells and self.cleanse_state.weed_cells[cell_id] == true
    end

    runtime.cleanse_is_flame_cell_active = function(self, cell_id)
        local state = self and self.cleanse_state or nil
        if not state or not state.flame_cells then
            return false
        end
        return (tonumber(state.flame_cells[cell_id] or 0) or 0) > 0
    end

    runtime.cleanse_blocks_human_entry = function(self, to_cell_id)
        return runtime.cleanse_cell_has_weed(self, to_cell_id)
    end

    runtime.cleanse_blocks_alien_entry = function(self, alien_type, to_cell_id)
        return false
    end

    runtime.cleanse_on_alien_enter_cell = function(self, cell_id)
        if not is_cleanse_mission(self) then
            return false
        end
        local state = self.cleanse_state or nil
        if not (state and state.weed_cells and state.weed_cells[cell_id] == true) then
            return false
        end
        state.weed_trigger_cells = state.weed_trigger_cells or {}
        local now_s = tonumber(state.fx_clock_s or 0) or 0
        state.weed_trigger_cells[cell_id] = now_s + WEED_TRIGGER_BURST_DURATION_S
        return true
    end

    runtime.cleanse_on_furnace_cell_pulse = function(self, cell_id)
        if not is_cleanse_mission(self) then
            return false
        end
        local state = self.cleanse_state or nil
        if not (state and state.weed_cells and state.weed_cells[cell_id] == true) then
            return false
        end
        return remove_weed_cell(self, cell_id, true)
    end

    runtime.cleanse_initialize_for_level = function(self)
        clear_cleanse_runtime_state(self)
        if not is_cleanse_mission(self) then
            return
        end
        local state = self.cleanse_state
        local valid_cells = list_valid_non_void_cells(self)
        state.total_valid_cells = #valid_cells
        local level = self.level_library and self.level_library[self.current_level_index or 1] or nil
        local portal_center = nil
        if type(level) == "table" and ctx.coords_to_id then
            for _, placement in ipairs(level) do
                if placement and tostring(placement.tile or "") == "portal" then
                    portal_center = ctx.coords_to_id(placement.x or 0, placement.y or 0)
                    break
                end
            end
        end
        state.portal_center_cell_id = portal_center
        if portal_center then
            local down_right_first = { "down", "right", "up", "left" }
            local seeded = false
            for _, dir in ipairs(down_right_first) do
                local adj = ctx.get_adjacent_cell and ctx.get_adjacent_cell(portal_center, dir) or nil
                if can_grow_into_cell(self, portal_center, adj) then
                    seeded = add_weed_cell(self, adj)
                    if seeded then
                        break
                    end
                end
            end
            if not seeded then
                local any_dirs = { "up", "left", "right", "down" }
                for _, dir in ipairs(any_dirs) do
                    local adj = ctx.get_adjacent_cell and ctx.get_adjacent_cell(portal_center, dir) or nil
                    if can_grow_into_cell(self, portal_center, adj) then
                        seeded = add_weed_cell(self, adj)
                        if seeded then
                            break
                        end
                    end
                end
            end
        end
        state.mission_initialized = true
        state.cleanse_visuals_dirty = true
    end

    runtime.cleanse_try_grow_one_cell = function(self)
        if not is_cleanse_mission(self) then
            return false, nil
        end
        local state = self.cleanse_state
        if not (state and state.weed_cells) then
            return false, nil
        end
        local frontier = {}
        for cell_id, present in pairs(state.weed_cells) do
            if present == true then
                frontier[#frontier + 1] = cell_id
            end
        end
        if #frontier <= 0 then
            return false, nil
        end
        local start_i = math.random(1, #frontier)
        local dirs = { "up", "left", "right", "down" }
        for offset = 0, (#frontier - 1) do
            local from_id = frontier[((start_i + offset - 1) % #frontier) + 1]
            for _, dir in ipairs(dirs) do
                local to_id = ctx.get_adjacent_cell and ctx.get_adjacent_cell(from_id, dir) or nil
                if can_grow_into_cell(self, from_id, to_id) then
                    if add_weed_cell(self, to_id) then
                        return true, to_id
                    end
                end
            end
        end
        return false, nil
    end

    runtime.cleanse_on_new_turn_start = function(self)
        local cleanse_active = is_cleanse_mission(self)
        local state = self.cleanse_state or {}
        local next_flame = {}
        for cell_id, turns_left in pairs(state.flame_cells or {}) do
            local left = (tonumber(turns_left or 0) or 0) - 1
            if left > 0 then
                next_flame[cell_id] = left
            end
        end
        state.flame_cells = next_flame
        self.cleanse_state = state
        state.cleanse_visuals_dirty = true
        for cell_id, _ in pairs(self.cleanse_state.flame_cells or {}) do
            apply_flame_kill_on_cell(self, cell_id)
        end
        if not cleanse_active then
            return
        end
        local grew = runtime.cleanse_try_grow_one_cell(self)
        if grew then
            print("CLEANSE | weed grew by one cell.")
        end
        for cell_key, _ in pairs(self.furnace_active_cells or {}) do
            local cell_id = tonumber(cell_key)
            if cell_id then
                remove_weed_cell(self, cell_id, true)
            end
        end
    end

    runtime.cleanse_get_status = function(self)
        local state = self.cleanse_state or {}
        local infected = 0
        for _, present in pairs(state.weed_cells or {}) do
            if present == true then
                infected = infected + 1
            end
        end
        local total_valid = math.max(0, tonumber(state.total_valid_cells or 0) or 0)
        local all_infected = total_valid > 0 and infected >= total_valid
        local all_humans_dead = count_alive_humans(self) <= 0
        local portal_destroyed = cleanse_portal_is_destroyed(self)
        return {
            weed_count = infected,
            all_infected = all_infected,
            all_humans_dead = all_humans_dead,
            portal_destroyed = portal_destroyed,
            mission_complete = (infected <= 0 and portal_destroyed == true),
            mission_failed = all_humans_dead or all_infected
        }
    end

    runtime.cleanse_build_sync_payload = function(self)
        local state = self.cleanse_state or {}
        local weed_cells = {}
        local flame_cells = {}
        local flamer_shots = {}
        for cell_id, present in pairs(state.weed_cells or {}) do
            if present == true then
                weed_cells[#weed_cells + 1] = tonumber(cell_id or 0) or 0
            end
        end
        for cell_id, turns_left in pairs(state.flame_cells or {}) do
            local left = tonumber(turns_left or 0) or 0
            if left > 0 then
                flame_cells[#flame_cells + 1] = {
                    cell_id = tonumber(cell_id or 0) or 0,
                    turns_left = left
                }
            end
        end
        for unit_id_key, shots in pairs(state.flamer_shots_by_unit_id or {}) do
            local count = math.max(0, math.floor((tonumber(shots or 0) or 0) + 0.5))
            if count > 0 then
                flamer_shots[#flamer_shots + 1] = {
                    unit_id = tostring(unit_id_key or ""),
                    shots = count
                }
            end
        end
        return {
            weed_cells = weed_cells,
            flame_cells = flame_cells,
            flamer_shots = flamer_shots,
            total_valid_cells = tonumber(state.total_valid_cells or 0) or 0,
            portal_center_cell_id = tonumber(state.portal_center_cell_id or 0) or 0
        }
    end

    runtime.cleanse_apply_sync_payload = function(self, payload)
        if type(payload) ~= "table" then
            return false
        end
        local state = self.cleanse_state or {}
        state.weed_cells = {}
        state.flame_cells = {}
        state.flamer_shots_by_unit_id = {}
        state.flame_visual_reveal_s_by_cell = {}
        clear_weed_visuals(state)
        state.total_valid_cells = tonumber(payload.total_valid_cells or state.total_valid_cells or 0) or 0
        state.portal_center_cell_id = tonumber(payload.portal_center_cell_id or state.portal_center_cell_id or 0) or 0
        for _, cell_id in ipairs(payload.weed_cells or {}) do
            local key = tonumber(cell_id or 0) or 0
            if key > 0 then
                state.weed_cells[key] = true
            end
        end
        for _, row in ipairs(payload.flame_cells or {}) do
            local key = tonumber(row and row.cell_id or 0) or 0
            local turns_left = tonumber(row and row.turns_left or 0) or 0
            if key > 0 and turns_left > 0 then
                state.flame_cells[key] = turns_left
            end
        end
        for _, row in ipairs(payload.flamer_shots or {}) do
            local unit_id_key = tostring(row and row.unit_id or "")
            local shots = math.max(0, math.floor((tonumber(row and row.shots or 0) or 0) + 0.5))
            if unit_id_key ~= "" and shots > 0 then
                state.flamer_shots_by_unit_id[unit_id_key] = shots
            end
        end
        self.cleanse_state = state
        state.cleanse_visuals_dirty = true
        return true
    end

    runtime.cleanse_try_fire_flamer = function(self, unit, target_cell_id)
        if not (unit and target_cell_id and unit.cell_id and (tonumber(unit.current_health or 0) or 0) > 0) then
            return true, "invalid_unit"
        end
        if not (ctx.unit_has_equipped_buff_kind and ctx.unit_has_equipped_buff_kind(unit, "flamer")) then
            return false, "no_flamer"
        end
        if get_or_init_flamer_shots(self, unit, true) <= 0 then
            return false, "no_ammo"
        end
        local from_cell = self.world_grid and self.world_grid[unit.cell_id] or nil
        local to_cell = self.world_grid and self.world_grid[target_cell_id] or nil
        if not from_cell or not to_cell then
            return true, "invalid_target"
        end
        local dx = (to_cell.xCell or 0) - (from_cell.xCell or 0)
        local dy = (to_cell.yCell or 0) - (from_cell.yCell or 0)
        if dx ~= 0 and dy ~= 0 then
            return true, "diagonal"
        end
        local range = math.abs(dx) + math.abs(dy)
        if range < 1 or range > 3 then
            return true, "out_of_range"
        end
        local dir = "right"
        if dx < 0 then
            dir = "left"
        elseif dy > 0 then
            dir = "up"
        elseif dy < 0 then
            dir = "down"
        end
        if (dir == "up" or dir == "down") and unit.go_path then
            local unit_pos = go.get_position(unit.go_path)
            local from_center_x = (ctx.coords_to_world_pos(from_cell.xCell, from_cell.yCell))
            local right_threshold = (tonumber(ctx.CELL_WIDTH or 250) or 250) * 0.15
            local shooter_in_right_lane = unit_pos.x >= (from_center_x + right_threshold)
            if not shooter_in_right_lane then
                return true, "blocked"
            end
        end
        local flame_cells = {}
        local facing_by_cell = {}
        local current = unit.cell_id
        for _ = 1, 3 do
            local next_cell = ctx.get_adjacent_cell and ctx.get_adjacent_cell(current, dir) or nil
            if not next_cell or is_cell_void_or_invalid(self, next_cell) then
                break
            end
            if not (ctx.can_cross_between_cells and ctx.can_cross_between_cells(self.world_grid, current, next_cell)) then
                break
            end
            if has_blocking_edge(self, current, next_cell) then
                break
            end
            flame_cells[#flame_cells + 1] = next_cell
            facing_by_cell[next_cell] = dir
            current = next_cell
        end
        if #flame_cells <= 0 then
            return true, "blocked"
        end
        local consumed_ok = consume_flamer_shot(self, unit)
        if consumed_ok ~= true then
            return false, "no_ammo"
        end
        local state = self.cleanse_state or {}
        state.flame_cells = state.flame_cells or {}
        state.flame_visual_reveal_s_by_cell = state.flame_visual_reveal_s_by_cell or {}
        state.flamer_jet_fx_objects = state.flamer_jet_fx_objects or {}
        local base_reveal_s = tonumber(state.fx_clock_s or 0) or 0
        for i, cell_id in ipairs(flame_cells) do
            local delay_s = 0
            if i == 2 then
                delay_s = 0.5
            elseif i >= 3 then
                delay_s = 0.75
            end
            state.flame_cells[cell_id] = FLAME_CELL_TURNS
            state.flame_visual_reveal_s_by_cell[cell_id] = base_reveal_s + delay_s
            remove_weed_cell(self, cell_id, true)
            apply_flame_kill_on_cell(self, cell_id)
        end
        if #flame_cells > 0 then
            state.cleanse_visuals_dirty = true
        end
        if #flame_cells > 0 then
            local shooter_pos = unit.go_path and go.get_position(unit.go_path) or nil
            if shooter_pos then
                if ctx and ctx.play_flamer_fire_sfx then
                    ctx.play_flamer_fire_sfx(self, shooter_pos.x, shooter_pos.y)
                end
                local shot_dir = facing_by_cell[flame_cells[1]]
                local rot = 0
                local origin_x = shooter_pos.x
                local origin_y = shooter_pos.y
                local forward_offset = 24
                -- fireJet authored forward points up (+Y); map world cardinals accordingly.
                if shot_dir == "right" then
                    rot = -math.pi * 0.5
                    origin_x = origin_x + forward_offset
                elseif shot_dir == "down" then
                    rot = math.pi
                    origin_y = origin_y - forward_offset
                elseif shot_dir == "left" then
                    rot = math.pi * 0.5
                    origin_x = origin_x - forward_offset
                else
                    rot = 0
                    origin_y = origin_y + forward_offset
                end
                local jet_factory = "/fire_jet_fx_factory#fire_jet_fx_factory"
                if #flame_cells >= 3 then
                    jet_factory = "/fire_jet_long_fx_factory#fire_jet_long_fx_factory"
                elseif #flame_cells >= 2 then
                    jet_factory = "/fire_jet_med_fx_factory#fire_jet_med_fx_factory"
                end
                local jet_go = factory.create(jet_factory, vmath.vector3(origin_x, origin_y, 0.7))
                if jet_go then
                    pcall(particlefx.play, msg.url(nil, jet_go, "particlefx"))
                    go.set_rotation(vmath.quat_rotation_z(rot), jet_go)
                    go.set_scale(vmath.vector3(1.0, 1.0, 1), jet_go)
                    state.flamer_jet_fx_objects[jet_go] = jet_go
                    timer.delay(1.0, false, function()
                        if state.flamer_jet_fx_objects and state.flamer_jet_fx_objects[jet_go] then
                            pcall(go.delete, jet_go)
                            state.flamer_jet_fx_objects[jet_go] = nil
                        end
                    end)
                end
            end
        end
        self.cleanse_state = state
        return true, "fired"
    end

    runtime.cleanse_resolve_cell_entry = function(self, cell_id, reason_tag)
        if runtime.cleanse_is_flame_cell_active(self, cell_id) ~= true then
            return false
        end
        if ctx and ctx.furnace_kill_units_on_cell then
            ctx.furnace_kill_units_on_cell(self, cell_id)
        end
        print(string.format("CLEANSE FLAME | entry_kill_zone | cell=%d source=%s", tonumber(cell_id or 0) or 0, tostring(reason_tag or "unknown")))
        return true
    end

    runtime.cleanse_can_attempt_flamer = function(self, unit, target_cell_id)
        if not (ctx.unit_has_equipped_buff_kind and ctx.unit_has_equipped_buff_kind(unit, "flamer")) then
            return false
        end
        if get_or_init_flamer_shots(self, unit, true) <= 0 then
            return false
        end
        local from_cell = self.world_grid and unit and unit.cell_id and self.world_grid[unit.cell_id] or nil
        local to_cell = self.world_grid and self.world_grid[target_cell_id] or nil
        if not from_cell or not to_cell then
            return false
        end
        local dx = (to_cell.xCell or 0) - (from_cell.xCell or 0)
        local dy = (to_cell.yCell or 0) - (from_cell.yCell or 0)
        if dx ~= 0 and dy ~= 0 then
            return false
        end
        local range = math.abs(dx) + math.abs(dy)
        return range >= 1 and range <= 3
    end

    runtime.cleanse_get_flamer_shots = function(self, unit)
        return get_or_init_flamer_shots(self, unit, true)
    end

    runtime.cleanse_get_flamer_max_shots = function()
        return FLAMER_MAX_SHOTS
    end

    runtime.cleanse_get_clicked_weed_cell = function(self, world_x, world_y, hit_size_px)
        if not is_cleanse_mission(self) then
            return nil
        end
        if not (world_x and world_y) then
            return nil
        end
        local state = self.cleanse_state or {}
        local half = (tonumber(hit_size_px or 64) or 64) * 0.5
        local best_cell_id = nil
        local best_dist = math.huge
        for cell_id, present in pairs(state.weed_cells or {}) do
            if present == true then
                local cell = self.world_grid and self.world_grid[cell_id] or nil
                if cell then
                    local cx, cy = ctx.coords_to_world_pos(cell.xCell, cell.yCell)
                    if world_x >= (cx - half)
                        and world_x <= (cx + half)
                        and world_y >= (cy - half)
                        and world_y <= (cy + half)
                    then
                        local dx = cx - world_x
                        local dy = cy - world_y
                        local dist = math.sqrt((dx * dx) + (dy * dy))
                        if dist < best_dist then
                            best_dist = dist
                            best_cell_id = cell_id
                        end
                    end
                end
            end
        end
        return best_cell_id
    end

    runtime.cleanse_clear_state = function(self)
        clear_cleanse_runtime_state(self)
    end

    runtime.cleanse_update_visuals = function(self, dt)
        local cleanse_active = is_cleanse_mission(self)
        local state = self.cleanse_state or nil
        if not state then
            return
        end
        local step_dt = tonumber(dt or 0) or 0
        if step_dt > 0 then
            state.fx_clock_s = (tonumber(state.fx_clock_s or 0) or 0) + step_dt
        end
        local reveal_table = state.flame_visual_reveal_s_by_cell or nil
        if reveal_table then
            local now_s = tonumber(state.fx_clock_s or 0) or 0
            for cell_id, reveal_s in pairs(reveal_table) do
                if (tonumber(state.flame_cells[cell_id] or 0) or 0) > 0 and now_s >= (tonumber(reveal_s or 0) or 0) then
                    state.cleanse_visuals_dirty = true
                    reveal_table[cell_id] = nil
                end
            end
        end
        if state.cleanse_visuals_dirty == true then
            if cleanse_active then
                refresh_weed_visuals(self)
            end
            refresh_flame_fx(self)
            refresh_flame_markers(self)
            state.cleanse_visuals_dirty = false
        end
        if not cleanse_active then
            tick_flame_markers(self, step_dt)
            return
        end
        state.weed_burst_accum_s = (tonumber(state.weed_burst_accum_s or 0) or 0) + step_dt
        if state.weed_burst_accum_s >= WEED_BURST_RESELECT_S then
            refresh_weed_burst_selection(state)
            state.weed_burst_accum_s = state.weed_burst_accum_s % WEED_BURST_RESELECT_S
        end
        if WEED_ANIM_ENABLED == true then
            state.weed_tick_accum_s = (tonumber(state.weed_tick_accum_s or 0) or 0) + step_dt
            if state.weed_tick_accum_s >= WEED_VISUAL_TICK_S then
                tick_weed_pulse(self)
                state.weed_tick_accum_s = state.weed_tick_accum_s % WEED_VISUAL_TICK_S
            end
        end
        tick_flame_markers(self, step_dt)
    end

    return runtime
end

return M
