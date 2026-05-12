local M = {}

local OFFSCREEN = vmath.vector3(-9999, -9999, 0)

local MISSION_ORDER = {
    "escape",
    "rescue",
    "purge",
    "dna_sample"
}

local MISSION_TO_SPAWN_TILE = {
    escape = "entry",
    rescue = "rescue_entry",
    purge = "rescue_entry",
    dna_sample = "rescue_entry"
}

local TAB_Y = 684
local TAB_W = 152
local TAB_H = 46
local TAB_GAP = 16

local LEVEL_LIST_START_Y = TAB_Y - 62
local LEVEL_LIST_W = 112
local LEVEL_LIST_H = 44
local LEVEL_LIST_GAP = 14
local LEVEL_LIST_MAX = 9

local SAVE_NEW_X = 64
local SAVE_EDIT_X = 190
local SAVE_Y = 682
local ACTION_W = 124
local ACTION_H = 62

local EXIT_X = 64
local EXIT_Y = 604
local EXIT_W = 124
local EXIT_H = 62

local DELETE_BTN_X = 64
local DELETE_BTN_Y = 526
local DELETE_BTN_W = 124
local DELETE_BTN_H = 62

local STATUS_X = 250
local STATUS_Y = 36
local STATUS_W = 420
local STATUS_H = 22

local PALETTE_COLS = 1
local PALETTE_CELL_W = 126
local PALETTE_CELL_H = 70
local PALETTE_START_X = 1190
local PALETTE_START_Y = 620
local PALETTE_GAP_Y = 18
local PALETTE_GAP_X = 0

local TILE_DRAW_SCALE = 1.0
local PALETTE_TILE_SCALE = 0.25
local TILE_DRAW_Z = 0.922
local TILE_DRAG_Z = 0.96
local INVALID_TINT = vmath.vector4(1, 0.2, 0.2, 0.5)
local CELL_NUMBER_ALPHA = 0.5
local AXIS_LABEL_OFFSET_X = 56
local AXIS_LABEL_OFFSET_Y = 36

local TAB_Z = 2.92
local PANEL_Z = 2.919
local BTN_Z = 2.921
local STATUS_Z = 2.921
local GRID_Z = 2.9205
local GRID_LINE_THICKNESS = 2
local GRID_VIEW_COLS = 10
local GRID_VIEW_ROWS = 10
local GRID_CELL_W = 125
local GRID_CELL_H = 75
local GRID_VIEW_LEFT = 20
local GRID_VIEW_TOP = 710
local SHOW_EDITOR_GRID = false
local TILE_CENTER_HIT_W = 42
local TILE_CENTER_HIT_H = 28
local PALETTE_VISIBLE_ROWS = 7
local EDITOR_BG_TINT = vmath.vector4(0.1, 0.1, 0.1, 1)
local ALLOW_TILE_DUPLICATES = true
local VALIDATION_BLOCK_SAVE = false
local INVALID_MARKER_Z = 2.935
local INVALID_MARKER_W = 24
local INVALID_MARKER_H = 24

local function get_tab_center_x(screen_w, idx)
    local left = (screen_w * 0.5) - (((#MISSION_ORDER * TAB_W) + ((#MISSION_ORDER - 1) * TAB_GAP)) * 0.5) + (TAB_W * 0.5)
    return left + ((idx - 1) * (TAB_W + TAB_GAP))
end

local function get_selected_mission_idx(mission_type)
    for i, mission in ipairs(MISSION_ORDER) do
        if mission == mission_type then
            return i
        end
    end
    return 1
end

local function get_grid_cell_center(col, row)
    local x = GRID_VIEW_LEFT + ((col - 0.5) * GRID_CELL_W)
    local y = GRID_VIEW_TOP - ((row - 0.5) * GRID_CELL_H)
    return x, y
end

local function screen_to_grid_col_row(sx, sy)
    local col = math.floor((sx - GRID_VIEW_LEFT) / GRID_CELL_W) + 1
    local row = math.floor((GRID_VIEW_TOP - sy) / GRID_CELL_H) + 1
    if col < 1 or col > GRID_VIEW_COLS or row < 1 or row > GRID_VIEW_ROWS then
        return nil, nil
    end
    return col, row
end

local function create_text_markers(self, text, z)
    local markers = {}
    local chars = tostring(text or "")
    for i = 1, #chars do
        markers[i] = self.create_ui_marker_sprite(hash("letter_a"), z or (BTN_Z + 0.003))
    end
    return markers
end

local function set_text_markers(self, markers, text, center_x, center_y, scale, alpha, spacing)
    local hidden = vmath.vector4(0, 0, 0, 0)
    if type(markers) ~= "table" then
        return
    end
    local s = scale or 0.22
    local a = alpha or 1
    local step = spacing or 12
    for _, id in ipairs(markers) do
        self.set_ui_square_transform(self, id, -9999, -9999, BTN_Z + 0.003, hidden, s, s)
    end
    local chars = tostring(text or "")
    local span = (#chars - 1) * step
    local start_x = center_x - (span * 0.5)
    for i = 1, math.min(#markers, #chars) do
        local ch = string.sub(chars, i, i)
        msg.post(msg.url(nil, markers[i], "sprite"), "play_animation", { id = hash("letter_" .. ch) })
        self.set_ui_square_transform(self, markers[i], start_x + ((i - 1) * step), center_y, BTN_Z + 0.003, vmath.vector4(1, 1, 1, a), s, s)
    end
end

local function world_to_screen(self, wx, wy)
    local zoom = tonumber(self.camera_zoom or 1) or 1
    if zoom <= 0 then
        zoom = 1
    end
    local sx = ((wx - self.camera_pos.x) * zoom) + (self.SCREEN_WIDTH * 0.5)
    local sy = ((wy - self.camera_pos.y) * zoom) + (self.SCREEN_HEIGHT * 0.5)
    return sx, sy
end

local function clone_placements(source)
    local out = {}
    if type(source) ~= "table" then
        return out
    end
    for _, p in ipairs(source) do
        if type(p) == "table" and tonumber(p.x) and tonumber(p.y) and type(p.tile) == "string" then
            out[#out + 1] = { x = tonumber(p.x), y = tonumber(p.y), tile = tostring(p.tile) }
        end
    end
    return out
end

local function mission_for_level(level_def)
    if type(level_def) ~= "table" then
        return "escape"
    end
    local m = tostring(level_def.mission_type or "escape")
    if m ~= "escape" and m ~= "rescue" and m ~= "purge" and m ~= "dna_sample" then
        return "escape"
    end
    return m
end

local function get_level_indices_for_mission(level_library, mission_type)
    local indices = {}
    if type(level_library) ~= "table" then
        return indices
    end
    for i, level_def in pairs(level_library) do
        local idx = tonumber(i)
        if idx and idx > 0 and type(level_def) == "table" and mission_for_level(level_def) == mission_type then
            indices[#indices + 1] = idx
        end
    end
    -- Show newest level ids first so Save New appears immediately in the visible chip list.
    table.sort(indices, function(a, b) return a > b end)
    return indices
end

local function local_cell_to_offset(local_idx)
    if local_idx == 1 then return -1, -1 end
    if local_idx == 2 then return 0, -1 end
    if local_idx == 3 then return 1, -1 end
    if local_idx == 4 then return -1, 0 end
    if local_idx == 5 then return 0, 0 end
    if local_idx == 6 then return 1, 0 end
    if local_idx == 7 then return -1, 1 end
    if local_idx == 8 then return 0, 1 end
    if local_idx == 9 then return 1, 1 end
    return 0, 0
end

local function set_alpha_for_id(go_id, alpha)
    if not go_id then
        return
    end
    local tint = go.get(msg.url(nil, go_id, "sprite"), "tint")
    tint.w = alpha
    go.set(msg.url(nil, go_id, "sprite"), "tint", tint)
end

local function delete_go_array(arr)
    if type(arr) ~= "table" then
        return
    end
    for _, go_id in ipairs(arr) do
        if go_id then
            pcall(go.delete, go_id)
        end
    end
end

local function delete_go_map(map)
    if type(map) ~= "table" then
        return
    end
    for _, go_id in pairs(map) do
        if go_id then
            pcall(go.delete, go_id)
        end
    end
end

local function set_sprite_alpha(go_id, alpha)
    if not go_id then
        return
    end
    pcall(go.set, msg.url(nil, go_id, "sprite"), "tint", vmath.vector4(1, 1, 1, alpha))
end

local function get_powered_anim_id(self, tile_name, tile_def)
    if type(tile_def) == "table" and type(tile_def.powerLightOnAnim) == "string" then
        return hash(tile_def.powerLightOnAnim)
    end
    local visual_name = (tile_def and tile_def.visualTile) or tile_name
    if type(tile_def) == "table" then
        if self.aesthetic_mode == self.AESTHETIC_MODE_COMPUTER and tile_def.visualTileComputer then
            visual_name = tile_def.visualTileComputer
        elseif self.aesthetic_mode == self.AESTHETIC_MODE_BOARDGAME and tile_def.visualTileBoardgame then
            visual_name = tile_def.visualTileBoardgame
        end
    end
    return hash("tile_" .. tostring(visual_name))
end

local function enforce_world_visibility(self, alpha)
    local a = math.max(0, math.min(1, tonumber(alpha or 1) or 1))
    if tile_objects then
        for _, id in ipairs(tile_objects) do
            set_sprite_alpha(id, a)
        end
    end
    if cell_objects then
        for _, id in pairs(cell_objects) do
            pcall(msg.post, msg.url(nil, id, "cell_sprite1"), "set_tint", { tint = vmath.vector4(1, 1, 1, a) })
        end
    end
    if self and self.world_backdrop then
        set_sprite_alpha(self.world_backdrop, a)
    end
    if self and self.world_backdrop_tiles then
        for _, id in ipairs(self.world_backdrop_tiles) do
            set_sprite_alpha(id, a)
        end
    end
    if self and self.squad_units then
        for _, unit in pairs(self.squad_units) do
            if unit and unit.go_id then
                set_sprite_alpha(unit.go_id, a)
            end
        end
    end
    if self and self.aliens then
        for _, alien in ipairs(self.aliens) do
            if alien and alien.go_id then
                set_sprite_alpha(alien.go_id, a)
            end
        end
    end
    if self and self.civilian_visuals then
        for _, id in pairs(self.civilian_visuals) do
            set_sprite_alpha(id, a)
        end
    end
end

local function rebuild_preview_tile_visuals(self)
    local ed = self.level_editor
    ed.preview_tile_ids = ed.preview_tile_ids or {}
    for i, p in ipairs(ed.placements) do
        local tile_def = self.tile_library and self.tile_library[p.tile] or nil
        if tile_def then
            local wx, wy = self.coords_to_world_pos(p.x, p.y)
            local id = ed.preview_tile_ids[i]
            if not id then
                id = factory.create("/tile_factory#tile_factory", vmath.vector3(wx, wy, TILE_DRAW_Z))
                ed.preview_tile_ids[i] = id
            end
            if id then
                msg.post(msg.url(nil, id, "sprite"), "play_animation", { id = get_powered_anim_id(self, p.tile, tile_def) })
                go.set_position(vmath.vector3(wx, wy, TILE_DRAW_Z), id)
                go.set_scale(vmath.vector3(TILE_DRAW_SCALE, TILE_DRAW_SCALE, 1), id)
                if ed.selected_placement_index == i then
                    go.set(msg.url(nil, id, "sprite"), "tint", vmath.vector4(0.65, 1.0, 0.65, 1))
                else
                    go.set(msg.url(nil, id, "sprite"), "tint", vmath.vector4(1, 1, 1, 1))
                end
            end
        end
    end
    -- Reclaim orphaned preview instances to avoid hitting collection.max_instances.
    for i = #ed.preview_tile_ids, (#ed.placements + 1), -1 do
        local id = ed.preview_tile_ids[i]
        if id then
            pcall(go.delete, id)
        end
        ed.preview_tile_ids[i] = nil
    end
end

local function clear_invalid_tint(self)
    local ed = self.level_editor
    if not ed.invalid_cells then
        ed.invalid_cells = {}
    end
    if self.apply_cell_tint then
        for _, cell_id in ipairs(ed.invalid_cells) do
            self.apply_cell_tint(cell_id, vmath.vector4(1, 1, 1, 0))
        end
    end
    ed.invalid_cells = {}
end

local function ensure_invalid_marker_pool(self, count)
    local ed = self.level_editor
    ed.invalid_markers = ed.invalid_markers or {}
    while #ed.invalid_markers < count do
        ed.invalid_markers[#ed.invalid_markers + 1] = self.create_ui_square(
            -9999, -9999, INVALID_MARKER_Z, vmath.vector4(1, 0.15, 0.15, 0.85), INVALID_MARKER_W, INVALID_MARKER_H
        )
    end
end

local function set_invalid_markers_hidden(self)
    local ed = self.level_editor
    local hidden = vmath.vector4(0, 0, 0, 0)
    for _, id in ipairs(ed.invalid_markers or {}) do
        self.set_ui_square_transform(self, id, -9999, -9999, INVALID_MARKER_Z, hidden, INVALID_MARKER_W, INVALID_MARKER_H)
    end
end

local function update_invalid_markers(self)
    local ed = self.level_editor
    local invalid_cells = ed.invalid_cells or {}
    if #invalid_cells <= 0 then
        set_invalid_markers_hidden(self)
        return
    end
    ensure_invalid_marker_pool(self, #invalid_cells)
    local visible_count = 0
    for _, cell_id in ipairs(invalid_cells) do
        local cid = tonumber(cell_id)
        if cid and cid >= 1 then
            local x = ((cid - 1) % self.GRID_COLS) + 1
            local y = math.floor((cid - 1) / self.GRID_COLS) + 1
            if x >= 1 and x <= self.GRID_COLS and y >= 1 and y <= self.GRID_ROWS then
                local wx, wy = self.coords_to_world_pos(x, y)
                local sx, sy = world_to_screen(self, wx, wy)
                visible_count = visible_count + 1
                self.set_ui_square_transform(
                    self,
                    ed.invalid_markers[visible_count],
                    sx, sy,
                    INVALID_MARKER_Z,
                    vmath.vector4(1, 0.12, 0.12, 0.85),
                    INVALID_MARKER_W,
                    INVALID_MARKER_H
                )
            end
        end
    end
    local hidden = vmath.vector4(0, 0, 0, 0)
    for i = (visible_count + 1), #(ed.invalid_markers or {}) do
        self.set_ui_square_transform(self, ed.invalid_markers[i], -9999, -9999, INVALID_MARKER_Z, hidden, INVALID_MARKER_W, INVALID_MARKER_H)
    end
end

local function collect_placement_lookup(placements)
    local lookup = {}
    for i, p in ipairs(placements) do
        lookup[tostring(p.x) .. ":" .. tostring(p.y)] = i
    end
    return lookup
end

local function build_preview_world(self, placements)
    local world = self.create_world_grid()
    local baked = self.bake_level_to_world_grid(world, placements, self.tile_library)
    return baked
end

local function find_spawn_cells(self, world_grid, spawn_tile_name, spawn_local_cell)
    local ids = {}
    local tile_hash = hash(spawn_tile_name)
    for _, p in ipairs(self.level_editor.placements) do
        if p.tile == spawn_tile_name then
            local dx, dy = local_cell_to_offset(spawn_local_cell or 2)
            local spawn_id = self.coords_to_id(p.x + dx, p.y + dy)
            if spawn_id and world_grid[spawn_id] and world_grid[spawn_id].tileID == tile_hash then
                ids[#ids + 1] = spawn_id
            end
        end
    end
    return ids
end

local function find_exit_cells(self, world_grid)
    local ids = {}
    local exit_hash = hash("exit")
    for cell_id, cell in ipairs(world_grid) do
        if cell and cell.tileID == exit_hash then
            ids[#ids + 1] = cell_id
        end
    end
    return ids
end

local function validate_editor_map(self)
    local ed = self.level_editor
    local result = {
        ok = true,
        messages = {},
        invalid_cells = {}
    }
    local mission_type = tostring(ed.selected_mission_type or "escape")
    local spawn_tile_name = MISSION_TO_SPAWN_TILE[mission_type] or "entry"
    local spawn_local_cell = 2
    local world_grid = build_preview_world(self, ed.placements)

    local spawn_cells = find_spawn_cells(self, world_grid, spawn_tile_name, spawn_local_cell)
    local exit_cells = find_exit_cells(self, world_grid)
    if #spawn_cells == 0 then
        result.ok = false
        result.messages[#result.messages + 1] = "missing_spawn_" .. spawn_tile_name
    end
    if #exit_cells == 0 then
        result.ok = false
        result.messages[#result.messages + 1] = "missing_exit"
    end

    local reachable = {}
    local queue = {}
    local function enqueue(id)
        if id and world_grid[id] and world_grid[id].tileID ~= hash("empty") and not reachable[id] then
            reachable[id] = true
            queue[#queue + 1] = id
        end
    end

    for _, id in ipairs(spawn_cells) do
        enqueue(id)
    end
    local qi = 1
    while qi <= #queue do
        local cell_id = queue[qi]
        qi = qi + 1
        local neighbors = self.get_neighbors(cell_id, world_grid, self.MOVEMENT_PROFILE_HUMAN)
        for _, n in ipairs(neighbors) do
            enqueue(n.id)
        end
    end

    if #spawn_cells > 0 then
        local found_exit_reachable = false
        for _, exit_cell in ipairs(exit_cells) do
            if reachable[exit_cell] then
                found_exit_reachable = true
                break
            end
        end
        if not found_exit_reachable then
            result.ok = false
            result.messages[#result.messages + 1] = "exit_not_reachable"
            for _, id in ipairs(exit_cells) do
                result.invalid_cells[#result.invalid_cells + 1] = id
            end
        end
    end

    local unreachable_count = 0
    for cell_id, cell in ipairs(world_grid) do
        if cell and cell.tileID ~= hash("empty") and not reachable[cell_id] then
            unreachable_count = unreachable_count + 1
            result.invalid_cells[#result.invalid_cells + 1] = cell_id
        end
    end
    if unreachable_count > 0 then
        result.ok = false
        result.messages[#result.messages + 1] = "unreachable_cells_" .. tostring(unreachable_count)
    end

    local ladder_breaks = 0
    for cell_id, cell in ipairs(world_grid) do
        if cell and cell.tileID ~= hash("empty") then
            local up_id = self.get_adjacent_cell(cell_id, "up")
            if up_id and world_grid[up_id] and world_grid[up_id].tileID ~= hash("empty") then
                local this_down = (cell.accessDown == true)
                local up_down = (world_grid[up_id].accessDown == true)
                if this_down ~= up_down then
                    ladder_breaks = ladder_breaks + 1
                    result.invalid_cells[#result.invalid_cells + 1] = cell_id
                    result.invalid_cells[#result.invalid_cells + 1] = up_id
                end
            end
        end
    end
    if ladder_breaks > 0 then
        result.ok = false
        result.messages[#result.messages + 1] = "ladder_breaks_" .. tostring(ladder_breaks)
    end

    return result
end

local function make_lua_export_snippet(level_id, mission_type, placements, spawn_tile)
    local lines = {}
    lines[#lines + 1] = string.format("-- level editor export | level=%d mission=%s", level_id, mission_type)
    lines[#lines + 1] = string.format("levels[%d] = {", level_id)
    table.sort(placements, function(a, b)
        if a.y == b.y then
            return a.x < b.x
        end
        return a.y > b.y
    end)
    for _, p in ipairs(placements) do
        lines[#lines + 1] = string.format("    { x = %d, y = %d, tile = \"%s\" },", p.x, p.y, p.tile)
    end
    lines[#lines + 1] = "}"
    lines[#lines + 1] = string.format("levels[%d].mission_type = \"%s\"", level_id, mission_type)
    lines[#lines + 1] = string.format("levels[%d].spawn_tile = \"%s\"", level_id, spawn_tile)
    lines[#lines + 1] = string.format("levels[%d].spawn_cell = 2", level_id)
    lines[#lines + 1] = string.format("levels[%d].unit_loadouts = levels[1].unit_loadouts", level_id)
    return table.concat(lines, "\n")
end

local function write_export_payload(self, level_id, mission_type, placements)
    local spawn_tile = MISSION_TO_SPAWN_TILE[mission_type] or "entry"
    local snippet = make_lua_export_snippet(level_id, mission_type, clone_placements(placements), spawn_tile)
    local payload = {
        level_id = level_id,
        mission_type = mission_type,
        spawn_tile = spawn_tile,
        spawn_cell = 2,
        placements = clone_placements(placements),
        lua_snippet = snippet
    }
    sys.save("level_editor_pending_export", payload)
    print("LEVEL_EDITOR_EXPORT_BEGIN")
    print(snippet)
    print("LEVEL_EDITOR_EXPORT_END")
    return payload
end

local function refresh_current_mission_levels(self)
    local ed = self.level_editor
    ed.filtered_level_indices = get_level_indices_for_mission(self.level_library, ed.selected_mission_type)
end

local function ensure_selected_chip_visible(ed)
    if not ed or not ed.filtered_level_indices or not ed.selected_level_index then
        return
    end
    local selected = tonumber(ed.selected_level_index)
    if not selected then
        return
    end
    local visible_contains_selected = false
    for i = 1, math.min(LEVEL_LIST_MAX, #ed.filtered_level_indices) do
        if ed.filtered_level_indices[i] == selected then
            visible_contains_selected = true
            break
        end
    end
    if visible_contains_selected then
        return
    end
    local reordered = { selected }
    for _, idx in ipairs(ed.filtered_level_indices) do
        if idx ~= selected then
            reordered[#reordered + 1] = idx
        end
    end
    ed.filtered_level_indices = reordered
end

local function load_level_into_editor(self, level_index)
    local ed = self.level_editor
    local level_def = self.level_library and self.level_library[level_index] or nil
    if type(level_def) ~= "table" then
        return
    end
    clear_invalid_tint(self)
    ed.selected_level_index = level_index
    ed.placements = clone_placements(level_def)
    ed.selected_placement_index = nil
    rebuild_preview_tile_visuals(self)
end

local function place_or_move_tile(self, center_x, center_y)
    local ed = self.level_editor
    if center_x < 1 or center_x > self.GRID_COLS or center_y < 1 or center_y > self.GRID_ROWS then
        return false
    end
    if not ed.drag then
        return false
    end
    if ed.drag.kind == "palette" then
        -- Palette drags are additive so the same tile can be used many times.
        if not ALLOW_TILE_DUPLICATES then
            return false
        end
        ed.placements[#ed.placements + 1] = {
            x = center_x,
            y = center_y,
            tile = ed.drag.tile
        }
        ed.selected_placement_index = #ed.placements
    elseif ed.drag.kind == "map" and ed.drag.origin_index then
        local idx = ed.drag.origin_index
        if ed.placements[idx] then
            ed.placements[idx].x = center_x
            ed.placements[idx].y = center_y
            ed.selected_placement_index = idx
        end
    else
        return false
    end
    clear_invalid_tint(self)
    rebuild_preview_tile_visuals(self)
    return true
end

local function screen_point_to_tile_center(self, sx, sy)
    local col, row = screen_to_grid_col_row(sx, sy)
    if not col or not row then
        return nil, nil
    end
    local gx, gy = get_grid_cell_center(col, row)
    local wx, wy = self.screen_to_world(gx, gy, self.camera_pos, self.camera_zoom)
    local cx, cy = self.world_pos_to_coords(wx, wy)
    if not cx or not cy then
        return nil, nil
    end
    local tx = math.max(1, math.min(self.GRID_COLS, cx))
    local ty = math.max(1, math.min(self.GRID_ROWS, cy))
    return tx, ty
end

local function select_map_tile_for_drag(self, sx, sy)
    local ed = self.level_editor
    local best_idx = nil
    local best_dist = nil
    for idx, p in ipairs(ed.placements) do
        local wx, wy = self.coords_to_world_pos(p.x, p.y)
        local px, py = world_to_screen(self, wx, wy)
        local dx = math.abs((sx or 0) - px)
        local dy = math.abs((sy or 0) - py)
        if dx <= TILE_CENTER_HIT_W and dy <= TILE_CENTER_HIT_H then
            local dist = (dx * dx) + (dy * dy)
            if not best_dist or dist < best_dist then
                best_dist = dist
                best_idx = idx
            end
        end
    end
    if best_idx then
        local p = ed.placements[best_idx]
        ed.selected_placement_index = best_idx
        ed.drag = {
            active = true,
            kind = "map",
            tile = p.tile,
            origin_index = best_idx
        }
        return true
    end
    return false
end

local function start_palette_drag(self, palette_idx)
    local ed = self.level_editor
    local tile_name = ed.palette_tiles[palette_idx]
    if not tile_name then
        return false
    end
    ed.drag = {
        active = true,
        kind = "palette",
        tile = tile_name
    }
    return true
end

local function commit_save(self, is_new)
    local ed = self.level_editor
    local validation = validate_editor_map(self)
    clear_invalid_tint(self)
    if self.apply_cell_tint then
        for _, cell_id in ipairs(validation.invalid_cells) do
            self.apply_cell_tint(cell_id, INVALID_TINT)
            ed.invalid_cells[#ed.invalid_cells + 1] = cell_id
        end
    end
    ed.last_validation = validation
    if not validation.ok then
        ed.status = "invalid_map"
        local mission_type = tostring(ed.selected_mission_type or "escape")
        if VALIDATION_BLOCK_SAVE then
            print("LEVEL_EDITOR | save blocked | mission=" .. mission_type .. " | " .. table.concat(validation.messages, ","))
            return false
        end
        print("LEVEL_EDITOR | save continuing with invalid map | mission=" .. mission_type .. " | " .. table.concat(validation.messages, ","))
    end

    local level_id = ed.selected_level_index or 1
    if is_new then
        local max_id = 0
        for i, level in pairs(self.level_library or {}) do
            local idx = tonumber(i)
            if idx and idx > max_id and type(level) == "table" then
                max_id = idx
            end
        end
        level_id = max_id + 1
    end
    local mission_type = tostring(ed.selected_mission_type or "escape")
    local spawn_tile = MISSION_TO_SPAWN_TILE[mission_type] or "entry"
    local next_level = clone_placements(ed.placements)
    next_level.mission_type = mission_type
    next_level.spawn_tile = spawn_tile
    next_level.spawn_cell = 2
    local template = self.level_library and self.level_library[1] or nil
    if type(template) == "table" and type(template.unit_loadouts) == "table" then
        next_level.unit_loadouts = template.unit_loadouts
    end

    self.level_library[level_id] = next_level
    ed.selected_level_index = level_id
    refresh_current_mission_levels(self)
    ensure_selected_chip_visible(ed)
    write_export_payload(self, level_id, mission_type, ed.placements)
    ed.status = is_new and "saved_new" or "saved"
    print("LEVEL_EDITOR | save ok | level=" .. tostring(level_id) .. " | mission=" .. mission_type)
    return true
end

local function hide_ui(self)
    local ed = self.level_editor
    if not ed or not ed.ui then
        return
    end
    local hidden = vmath.vector4(0, 0, 0, 0)
    for _, id in ipairs(ed.ui.tab_buttons or {}) do
        self.set_ui_square_transform(self, id, -9999, -9999, TAB_Z, hidden, TAB_W, TAB_H)
    end
    for _, id in ipairs(ed.ui.level_buttons or {}) do
        self.set_ui_square_transform(self, id, -9999, -9999, BTN_Z, hidden, LEVEL_LIST_W, LEVEL_LIST_H)
    end
    for _, id in ipairs(ed.ui.palette_buttons or {}) do
        self.set_ui_square_transform(self, id, -9999, -9999, BTN_Z, hidden, PALETTE_CELL_W, PALETTE_CELL_H)
    end
    for _, id in ipairs(ed.palette_icons or {}) do
        self.set_ui_square_transform(self, id, -9999, -9999, BTN_Z + 0.001, hidden, PALETTE_TILE_SCALE, PALETTE_TILE_SCALE)
    end
    for _, id in ipairs(ed.palette_icons or {}) do
        self.set_ui_square_transform(self, id, -9999, -9999, BTN_Z + 0.001, hidden, PALETTE_TILE_SCALE, PALETTE_TILE_SCALE)
    end
    self.set_ui_square_transform(self, ed.ui.panel, -9999, -9999, PANEL_Z, hidden, 1160, 706)
    self.set_ui_square_transform(self, ed.ui.save_button, -9999, -9999, BTN_Z, hidden, ACTION_W, ACTION_H)
    self.set_ui_square_transform(self, ed.ui.save_new_button, -9999, -9999, BTN_Z, hidden, ACTION_W, ACTION_H)
    self.set_ui_square_transform(self, ed.ui.back_button, -9999, -9999, BTN_Z, hidden, EXIT_W, EXIT_H)
    self.set_ui_square_transform(self, ed.ui.delete_button, -9999, -9999, BTN_Z, hidden, DELETE_BTN_W, DELETE_BTN_H)
    self.set_ui_square_transform(self, ed.ui.status_strip, -9999, -9999, STATUS_Z, hidden, STATUS_W, STATUS_H)
    for _, group in ipairs(ed.level_button_digits or {}) do
        for _, id in ipairs(group) do
            self.set_ui_square_transform(self, id, -9999, -9999, BTN_Z + 0.002, hidden, 0.2, 0.2)
        end
    end
    for _, group in ipairs(ed.x_axis_labels or {}) do
        for _, id in ipairs(group) do
            self.set_ui_square_transform(self, id, -9999, -9999, BTN_Z + 0.002, hidden, 0.2, 0.2)
        end
    end
    for _, group in ipairs(ed.y_axis_labels or {}) do
        for _, id in ipairs(group) do
            self.set_ui_square_transform(self, id, -9999, -9999, BTN_Z + 0.002, hidden, 0.2, 0.2)
        end
    end
    for _, group in ipairs(ed.coord_labels or {}) do
        for _, id in ipairs(group) do
            self.set_ui_square_transform(self, id, -9999, -9999, BTN_Z + 0.003, hidden, 0.18, 0.18)
        end
    end
    for _, id in ipairs(ed.grid_lines_v or {}) do
        self.set_ui_square_transform(self, id, -9999, -9999, GRID_Z, hidden, GRID_LINE_THICKNESS, GRID_VIEW_ROWS * GRID_CELL_H)
    end
    for _, id in ipairs(ed.grid_lines_h or {}) do
        self.set_ui_square_transform(self, id, -9999, -9999, GRID_Z, hidden, GRID_VIEW_COLS * GRID_CELL_W, GRID_LINE_THICKNESS)
    end
    for _, id in ipairs(ed.invalid_markers or {}) do
        self.set_ui_square_transform(self, id, -9999, -9999, INVALID_MARKER_Z, hidden, INVALID_MARKER_W, INVALID_MARKER_H)
    end
    if ed.text then
        for _, markers in pairs(ed.text) do
            if type(markers) == "table" and markers[1] and type(markers[1]) == "userdata" then
                for _, id in ipairs(markers) do
                    self.set_ui_square_transform(self, id, -9999, -9999, BTN_Z + 0.003, hidden, 0.22, 0.22)
                end
            elseif type(markers) == "table" then
                for _, subgroup in pairs(markers) do
                    if type(subgroup) == "table" then
                        for _, id in ipairs(subgroup) do
                            self.set_ui_square_transform(self, id, -9999, -9999, BTN_Z + 0.003, hidden, 0.22, 0.22)
                        end
                    end
                end
            end
        end
    end
end

local function hide_gameplay_ui_for_editor(self)
    if not self.ui then
        return
    end
    local hidden = vmath.vector4(0, 0, 0, 0)
    local function hide(go_id, z)
        if go_id then
            self.set_ui_square_transform(self, go_id, -9999, -9999, z or BTN_Z, hidden, 1, 1)
        end
    end
    hide(self.ui.new_turn_button, BTN_Z)
    hide(self.ui.launch_button, BTN_Z)
    hide(self.ui.launch_button_art, BTN_Z)
    hide(self.ui.exit_button, BTN_Z)
    hide(self.ui.realtime_toggle_button, BTN_Z)
    hide(self.ui.objective_button, BTN_Z)
    hide(self.ui.objective_reminder, BTN_Z)
    hide(self.ui.aesthetic_toggle_button, BTN_Z)
    hide(self.ui.zoom_in_button, BTN_Z)
    hide(self.ui.zoom_out_button, BTN_Z)
    hide(self.ui.zoom_slider_track, BTN_Z)
    hide(self.ui.zoom_slider_knob, BTN_Z)
    if self.ui.ready_buttons then
        for _, id in ipairs(self.ui.ready_buttons) do
            hide(id, BTN_Z)
        end
    end
    if self.ui.mp_debug_player_buttons then
        for _, id in ipairs(self.ui.mp_debug_player_buttons) do
            hide(id, BTN_Z)
        end
    end
end

local function suppress_editor_visual_fx(self)
    if self.sheen_overlay then
        pcall(go.set, msg.url(nil, self.sheen_overlay, "sprite"), "blend_mode", (render and render.BLEND_ALPHA) or 0)
        pcall(go.set, msg.url(nil, self.sheen_overlay, "sprite"), "tint", vmath.vector4(1, 1, 1, 0))
    end
    if self.table_sweep_shadow_overlay then
        pcall(go.set, msg.url(nil, self.table_sweep_shadow_overlay, "sprite"), "blend_mode", (render and render.BLEND_ALPHA) or 0)
        pcall(go.set, msg.url(nil, self.table_sweep_shadow_overlay, "sprite"), "tint", vmath.vector4(1, 1, 1, 0))
    end
    if self.alien_turn_overlay then
        pcall(go.set, msg.url(nil, self.alien_turn_overlay, "sprite"), "blend_mode", (render and render.BLEND_ALPHA) or 0)
        pcall(go.set, msg.url(nil, self.alien_turn_overlay, "sprite"), "tint", vmath.vector4(1, 1, 1, 0))
    end
end

local function show_ui(self)
    local ed = self.level_editor
    local hidden = vmath.vector4(0, 0, 0, 0)
    self.set_ui_square_transform(self, ed.ui.panel, self.SCREEN_WIDTH * 0.5, self.SCREEN_HEIGHT * 0.5, PANEL_Z, EDITOR_BG_TINT, self.SCREEN_WIDTH, self.SCREEN_HEIGHT)
    pcall(go.set, msg.url(nil, ed.ui.panel, "sprite"), "blend_mode", (render and render.BLEND_ALPHA) or 0)
    if SHOW_EDITOR_GRID then
        for i, id in ipairs(ed.grid_lines_v or {}) do
            local x = GRID_VIEW_LEFT + ((i - 1) * GRID_CELL_W)
            local y = GRID_VIEW_TOP - ((GRID_VIEW_ROWS * GRID_CELL_H) * 0.5)
            self.set_ui_square_transform(self, id, x, y, GRID_Z, vmath.vector4(0.74, 0.74, 0.74, 0.62), GRID_LINE_THICKNESS, GRID_VIEW_ROWS * GRID_CELL_H)
        end
        for i, id in ipairs(ed.grid_lines_h or {}) do
            local x = GRID_VIEW_LEFT + ((GRID_VIEW_COLS * GRID_CELL_W) * 0.5)
            local y = GRID_VIEW_TOP - ((i - 1) * GRID_CELL_H)
            self.set_ui_square_transform(self, id, x, y, GRID_Z, vmath.vector4(0.74, 0.74, 0.74, 0.62), GRID_VIEW_COLS * GRID_CELL_W, GRID_LINE_THICKNESS)
        end
    else
        for _, id in ipairs(ed.grid_lines_v or {}) do
            self.set_ui_square_transform(self, id, -9999, -9999, GRID_Z, hidden, GRID_LINE_THICKNESS, GRID_VIEW_ROWS * GRID_CELL_H)
        end
        for _, id in ipairs(ed.grid_lines_h or {}) do
            self.set_ui_square_transform(self, id, -9999, -9999, GRID_Z, hidden, GRID_VIEW_COLS * GRID_CELL_W, GRID_LINE_THICKNESS)
        end
    end
    local selected_idx = get_selected_mission_idx(ed.selected_mission_type)
    for i, mission in ipairs(MISSION_ORDER) do
        local active = (mission == ed.selected_mission_type)
        local tint = active and vmath.vector4(0.2, 0.8, 0.35, 0.72) or vmath.vector4(0.2, 0.3, 0.5, 0.52)
        self.set_ui_square_transform(self, ed.ui.tab_buttons[i], get_tab_center_x(self.SCREEN_WIDTH, i), TAB_Y, TAB_Z, tint, TAB_W, TAB_H)
    end
    local level_x = get_tab_center_x(self.SCREEN_WIDTH, selected_idx)
    for i = 1, LEVEL_LIST_MAX do
        local level_idx = ed.filtered_level_indices[i]
        local active = (level_idx ~= nil and level_idx == ed.selected_level_index)
        local tint = active and vmath.vector4(0.85, 0.9, 0.2, 0.72) or (level_idx and vmath.vector4(0.25, 0.4, 0.65, 0.62) or hidden)
        local by = LEVEL_LIST_START_Y - ((i - 1) * (LEVEL_LIST_H + LEVEL_LIST_GAP))
        self.set_ui_square_transform(self, ed.ui.level_buttons[i], level_idx and level_x or -9999, level_idx and by or -9999, BTN_Z, tint, LEVEL_LIST_W, LEVEL_LIST_H)
        local digits = ed.level_button_digits and ed.level_button_digits[i] or nil
        if digits and level_idx then
            local padded = string.format("%03d", level_idx)
            msg.post(msg.url(nil, digits[1], "sprite"), "play_animation", { id = hash("score_" .. string.sub(padded, 1, 1)) })
            msg.post(msg.url(nil, digits[2], "sprite"), "play_animation", { id = hash("score_" .. string.sub(padded, 2, 2)) })
            msg.post(msg.url(nil, digits[3], "sprite"), "play_animation", { id = hash("score_" .. string.sub(padded, 3, 3)) })
            self.set_ui_square_transform(self, digits[1], level_x - 16, by, BTN_Z + 0.002, vmath.vector4(1, 1, 1, 0.95), 0.2, 0.2)
            self.set_ui_square_transform(self, digits[2], level_x, by, BTN_Z + 0.002, vmath.vector4(1, 1, 1, 0.95), 0.2, 0.2)
            self.set_ui_square_transform(self, digits[3], level_x + 16, by, BTN_Z + 0.002, vmath.vector4(1, 1, 1, 0.95), 0.2, 0.2)
        elseif digits then
            self.set_ui_square_transform(self, digits[1], -9999, -9999, BTN_Z + 0.002, hidden, 0.2, 0.2)
            self.set_ui_square_transform(self, digits[2], -9999, -9999, BTN_Z + 0.002, hidden, 0.2, 0.2)
            self.set_ui_square_transform(self, digits[3], -9999, -9999, BTN_Z + 0.002, hidden, 0.2, 0.2)
        end
    end
    local offset = math.max(0, tonumber(ed.palette_scroll_offset or 0) or 0)
    for i, tile_name in ipairs(ed.palette_tiles) do
        local slot = i - offset
        local col = ((slot - 1) % PALETTE_COLS)
        local row = math.floor((slot - 1) / PALETTE_COLS)
        local x = PALETTE_START_X + (col * (PALETTE_CELL_W + PALETTE_GAP_X))
        local y = PALETTE_START_Y - (row * (PALETTE_CELL_H + PALETTE_GAP_Y))
        local is_drag = (ed.drag and ed.drag.active and ed.drag.tile == tile_name and ed.drag.kind == "palette")
        local tint = is_drag and vmath.vector4(0.98, 0.9, 0.3, 0.95) or vmath.vector4(0.2, 0.25, 0.35, 0.72)
        local visible = slot >= 1 and slot <= PALETTE_VISIBLE_ROWS
        self.set_ui_square_transform(self, ed.ui.palette_buttons[i], visible and x or -9999, visible and y or -9999, BTN_Z, visible and tint or hidden, PALETTE_CELL_W, PALETTE_CELL_H)
        if ed.palette_icons and ed.palette_icons[i] then
            self.set_ui_square_transform(self, ed.palette_icons[i], visible and x or -9999, visible and y or -9999, BTN_Z + 0.001, visible and vmath.vector4(1, 1, 1, 1) or hidden, PALETTE_TILE_SCALE, PALETTE_TILE_SCALE)
        end
    end
    self.set_ui_square_transform(self, ed.ui.save_new_button, SAVE_NEW_X, SAVE_Y, BTN_Z, vmath.vector4(0.95, 0.1, 0.1, 0.9), ACTION_W, ACTION_H)
    self.set_ui_square_transform(self, ed.ui.save_button, SAVE_EDIT_X, SAVE_Y, BTN_Z, vmath.vector4(0.65, 0.05, 0.05, 0.9), ACTION_W, ACTION_H)
    self.set_ui_square_transform(self, ed.ui.back_button, EXIT_X, EXIT_Y, BTN_Z, vmath.vector4(0.1, 0.85, 0.8, 0.9), EXIT_W, EXIT_H)
    local has_selected = ed.selected_placement_index and ed.placements and ed.placements[ed.selected_placement_index]
    local delete_tint = has_selected and vmath.vector4(0.88, 0.08, 0.08, 0.95) or vmath.vector4(0.35, 0.1, 0.1, 0.7)
    self.set_ui_square_transform(self, ed.ui.delete_button, DELETE_BTN_X, DELETE_BTN_Y, BTN_Z, delete_tint, DELETE_BTN_W, DELETE_BTN_H)
    if ed.text then
        set_text_markers(self, ed.text.save_new_top, "save", SAVE_NEW_X, SAVE_Y + 11, 0.2, 1, 11)
        set_text_markers(self, ed.text.save_new_bottom, "new", SAVE_NEW_X, SAVE_Y - 11, 0.2, 1, 11)
        set_text_markers(self, ed.text.save_edit_top, "save", SAVE_EDIT_X, SAVE_Y + 11, 0.2, 1, 11)
        set_text_markers(self, ed.text.save_edit_bottom, "edit", SAVE_EDIT_X, SAVE_Y - 11, 0.2, 1, 11)
        set_text_markers(self, ed.text.exit_word, "exit", EXIT_X, EXIT_Y, 0.22, 1, 12)
        set_text_markers(self, ed.text.delete_word, "delete", DELETE_BTN_X, DELETE_BTN_Y, 0.22, has_selected and 1 or 0.75, 12)
        for i, word in ipairs(MISSION_ORDER) do
            local text_word = word == "dna_sample" and "dna" or word
            set_text_markers(self, ed.text.tabs[i], text_word, get_tab_center_x(self.SCREEN_WIDTH, i), TAB_Y, 0.22, 1, 12)
        end
    end
    local status_tint = vmath.vector4(0.15, 0.2, 0.35, 0.65)
    if ed.status == "saved" or ed.status == "saved_new" then
        status_tint = vmath.vector4(0.2, 0.62, 0.3, 0.75)
    elseif ed.status == "invalid_map" then
        status_tint = vmath.vector4(0.72, 0.2, 0.2, 0.82)
    end
    self.set_ui_square_transform(self, ed.ui.status_strip, STATUS_X, STATUS_Y, STATUS_Z, status_tint, STATUS_W, STATUS_H)
end

local function hit_palette_index(sx, sy, ed)
    local offset = math.max(0, tonumber(ed.palette_scroll_offset or 0) or 0)
    local max_count = #(ed.palette_tiles or {})
    local visible = math.min(PALETTE_VISIBLE_ROWS, math.max(0, max_count - offset))
    for slot = 1, visible do
        local col = ((slot - 1) % PALETTE_COLS)
        local row = math.floor((slot - 1) / PALETTE_COLS)
        local x = PALETTE_START_X + (col * (PALETTE_CELL_W + PALETTE_GAP_X))
        local y = PALETTE_START_Y - (row * (PALETTE_CELL_H + PALETTE_GAP_Y))
        if math.abs(sx - x) <= (PALETTE_CELL_W * 0.5) and math.abs(sy - y) <= (PALETTE_CELL_H * 0.5) then
            return offset + slot
        end
    end
    return nil
end

local function hit_tab_index(sx, sy, screen_w)
    for i = 1, #MISSION_ORDER do
        local x = get_tab_center_x(screen_w, i)
        if math.abs(sx - x) <= (TAB_W * 0.5) and math.abs(sy - TAB_Y) <= (TAB_H * 0.5) then
            return i
        end
    end
    return nil
end

local function hit_level_index(self, sx, sy)
    local ed = self.level_editor
    local selected_idx = get_selected_mission_idx(ed.selected_mission_type)
    local level_x = get_tab_center_x(self.SCREEN_WIDTH, selected_idx)
    for i = 1, LEVEL_LIST_MAX do
        local y = LEVEL_LIST_START_Y - ((i - 1) * (LEVEL_LIST_H + LEVEL_LIST_GAP))
        if math.abs(sx - level_x) <= (LEVEL_LIST_W * 0.5) and math.abs(sy - y) <= (LEVEL_LIST_H * 0.5) then
            return ed.filtered_level_indices[i]
        end
    end
    return nil
end

local function delete_selected_tile(self)
    local ed = self.level_editor
    local idx = tonumber(ed and ed.selected_placement_index or 0) or 0
    if idx <= 0 or not ed.placements or not ed.placements[idx] then
        return false
    end
    table.remove(ed.placements, idx)
    ed.selected_placement_index = nil
    clear_invalid_tint(self)
    rebuild_preview_tile_visuals(self)
    ed.status = "tile_deleted"
    return true
end

local function refresh_palette_icons(self)
    local ed = self.level_editor
    for i, id in ipairs(ed.palette_icons) do
        local tile_name = ed.palette_tiles[i]
        local tile_def = self.tile_library and self.tile_library[tile_name] or nil
        if id and tile_def then
            msg.post(msg.url(nil, id, "sprite"), "play_animation", { id = get_powered_anim_id(self, tile_name, tile_def) })
            go.set_scale(vmath.vector3(PALETTE_TILE_SCALE, PALETTE_TILE_SCALE, 1), id)
        end
    end
    rebuild_preview_tile_visuals(self)
end

function M.enter(self)
    if not self.level_editor then
        return
    end
    self.level_editor.enabled = true
    enforce_world_visibility(self, 0)
    self.level_editor.status = "ready"
    self.level_editor.drag = nil
    self.level_editor.selected_placement_index = nil
    self.level_editor.palette_scroll_offset = 0
    clear_invalid_tint(self)
    refresh_current_mission_levels(self)
    if not self.level_editor.selected_level_index then
        local first = self.level_editor.filtered_level_indices[1] or 1
        self.level_editor.selected_level_index = first
    end
    local cx, cy = self.coords_to_world_pos(math.ceil(self.GRID_COLS * 0.5), math.ceil(self.GRID_ROWS * 0.5))
    self.camera_pos = vmath.vector3(cx, cy, self.camera_pos and self.camera_pos.z or 1000)
    self.camera_zoom = 0.5
    if self.apply_camera_transform then
        self.apply_camera_transform(self)
    end
    load_level_into_editor(self, self.level_editor.selected_level_index)
    refresh_palette_icons(self)
end

function M.exit(self)
    if not self.level_editor then
        return
    end
    self.level_editor.enabled = false
    enforce_world_visibility(self, 1)
    if self.alien_turn_overlay then
        pcall(go.set, msg.url(nil, self.alien_turn_overlay, "sprite"), "blend_mode", (render and render.BLEND_ADD) or 1)
    end
    self.level_editor.drag = nil
    self.level_editor.selected_placement_index = nil
    clear_invalid_tint(self)
    hide_ui(self)
end

function M.handle_input(self, action, input_x, input_y, inside_view)
    local ed = self.level_editor
    if not ed or not ed.enabled then
        return false
    end
    if action.pressed then
        local tab_idx = hit_tab_index(input_x, input_y, self.SCREEN_WIDTH)
        if tab_idx then
            ed.selected_mission_type = MISSION_ORDER[tab_idx]
            ed.selected_level_index = nil
            ed.palette_scroll_offset = 0
            refresh_current_mission_levels(self)
            local first = ed.filtered_level_indices[1]
            if first then
                load_level_into_editor(self, first)
            else
                ed.placements = {}
                rebuild_preview_tile_visuals(self)
            end
            clear_invalid_tint(self)
            ed.status = "mission_changed"
            return true
        end
        local level_idx = hit_level_index(self, input_x, input_y)
        if level_idx then
            load_level_into_editor(self, level_idx)
            ed.status = "level_loaded"
            return true
        end
        if math.abs(input_x - SAVE_EDIT_X) <= (ACTION_W * 0.5) and math.abs(input_y - SAVE_Y) <= (ACTION_H * 0.5) then
            commit_save(self, false)
            return true
        end
        if math.abs(input_x - SAVE_NEW_X) <= (ACTION_W * 0.5) and math.abs(input_y - SAVE_Y) <= (ACTION_H * 0.5) then
            commit_save(self, true)
            return true
        end
        if math.abs(input_x - EXIT_X) <= (EXIT_W * 0.5) and math.abs(input_y - EXIT_Y) <= (EXIT_H * 0.5) then
            self.enter_flow_state(self, self.FLOW_STATE_TITLE)
            M.exit(self)
            return true
        end
        if math.abs(input_x - DELETE_BTN_X) <= (DELETE_BTN_W * 0.5) and math.abs(input_y - DELETE_BTN_Y) <= (DELETE_BTN_H * 0.5) then
            delete_selected_tile(self)
            return true
        end
        local palette_idx = hit_palette_index(input_x, input_y, ed)
        if palette_idx and ed.palette_tiles[palette_idx] then
            return start_palette_drag(self, palette_idx)
        end
        if inside_view and input_x and input_y then
            if select_map_tile_for_drag(self, input_x, input_y) then
                return true
            end
            ed.selected_placement_index = nil
            ed.pan_active = true
            ed.pan_start_input_x = input_x
            ed.pan_start_input_y = input_y
            ed.pan_start_cam_x = self.camera_pos.x
            ed.pan_start_cam_y = self.camera_pos.y
            return true
        end
        return true
    end
    if action.released then
        if ed.drag and ed.drag.active and input_x and input_y then
            local palette_idx = hit_palette_index(input_x, input_y, ed)
            if ed.drag.kind == "map" and palette_idx then
                if ed.drag.origin_index and ed.placements[ed.drag.origin_index] then
                    table.remove(ed.placements, ed.drag.origin_index)
                    ed.selected_placement_index = nil
                    clear_invalid_tint(self)
                    rebuild_preview_tile_visuals(self)
                end
            elseif inside_view then
                local tx, ty = screen_point_to_tile_center(self, input_x, input_y)
                if tx and ty then
                    place_or_move_tile(self, tx, ty)
                end
            end
        end
        ed.pan_active = false
        ed.drag = nil
        return true
    end
    if ed.pan_active and inside_view and input_x and input_y then
        local dx = input_x - (ed.pan_start_input_x or input_x)
        local dy = input_y - (ed.pan_start_input_y or input_y)
        local zoom = math.max(0.0001, self.camera_zoom or 1)
        self.camera_pos.x = (ed.pan_start_cam_x or self.camera_pos.x) - (dx / zoom)
        self.camera_pos.y = (ed.pan_start_cam_y or self.camera_pos.y) - (dy / zoom)
        if self.apply_camera_transform then
            self.apply_camera_transform(self)
        end
        return true
    end
    if ed.drag and ed.drag.active then
        return true
    end
    return true
end

function M.handle_wheel(self, delta)
    local ed = self.level_editor
    if not ed or not ed.enabled then
        return false
    end
    local dir = tonumber(delta or 0) or 0
    local max_offset = math.max(0, #(ed.palette_tiles or {}) - PALETTE_VISIBLE_ROWS)
    local next_offset = tonumber(ed.palette_scroll_offset or 0) or 0
    if dir > 0 then
        next_offset = next_offset - 1
    elseif dir < 0 then
        next_offset = next_offset + 1
    else
        return false
    end
    ed.palette_scroll_offset = math.max(0, math.min(max_offset, next_offset))
    return true
end

function M.update(self, dt)
    local ed = self.level_editor
    local hidden = vmath.vector4(0, 0, 0, 0)
    if not ed or not ed.enabled then
        hide_ui(self)
        return
    end
    enforce_world_visibility(self, 0)
    hide_gameplay_ui_for_editor(self)
    suppress_editor_visual_fx(self)
    show_ui(self)
    if ed.drag and ed.drag.active and self.level_editor.drag_visual then
        local vx = ed.last_input_x or 0
        local vy = ed.last_input_y or 0
        local id = self.level_editor.drag_visual
        if vx > 0 and vy > 0 then
            local wx, wy = self.screen_to_world(vx, vy, self.camera_pos, self.camera_zoom)
            go.set_position(vmath.vector3(wx, wy, TILE_DRAG_Z), id)
            set_alpha_for_id(id, 0.85)
            go.set_scale(vmath.vector3(TILE_DRAW_SCALE, TILE_DRAW_SCALE, 1), id)
            local tile_def = self.tile_library and self.tile_library[ed.drag.tile] or nil
            if tile_def then
                msg.post(msg.url(nil, id, "sprite"), "play_animation", { id = get_powered_anim_id(self, ed.drag.tile, tile_def) })
            end
        end
    elseif self.level_editor.drag_visual then
        go.set_position(OFFSCREEN, self.level_editor.drag_visual)
    end

    for _, label in ipairs(ed.coord_labels or {}) do
        for i = 1, 6 do
            self.set_ui_square_transform(self, label[i], -9999, -9999, BTN_Z + 0.003, hidden, 0.18, 0.18)
        end
    end
    update_invalid_markers(self)
end

function M.on_aesthetic_changed(self)
    local ed = self.level_editor
    if not ed then
        return
    end
    refresh_palette_icons(self)
end

function M.init(self, deps)
    self.level_editor = {
        enabled = false,
        selected_mission_type = "escape",
        selected_level_index = nil,
        filtered_level_indices = {},
        placements = {},
        palette_tiles = {},
        preview_tile_ids = {},
        x_axis_labels = {},
        y_axis_labels = {},
        coord_labels = {},
        grid_lines_v = {},
        grid_lines_h = {},
        invalid_cells = {},
        invalid_markers = {},
        drag = nil,
        selected_placement_index = nil,
        pan_active = false,
        pan_start_input_x = 0,
        pan_start_input_y = 0,
        pan_start_cam_x = 0,
        pan_start_cam_y = 0,
        palette_scroll_offset = 0,
        last_validation = nil,
        status = "boot",
        ui = {
            tab_buttons = {},
            level_buttons = {},
            palette_buttons = {},
            panel = nil,
            save_button = nil,
            save_new_button = nil,
            back_button = nil,
            delete_button = nil,
            status_strip = nil
        },
        palette_icons = {},
        level_button_digits = {},
        text = {
            save_new_top = {},
            save_new_bottom = {},
            save_edit_top = {},
            save_edit_bottom = {},
            exit_word = {},
            delete_word = {},
            tabs = {}
        }
    }

    self.FLOW_STATE_LEVEL_EDITOR = deps.FLOW_STATE_LEVEL_EDITOR
    self.FLOW_STATE_TITLE = deps.FLOW_STATE_TITLE
    self.AESTHETIC_MODE_COMPUTER = deps.AESTHETIC_MODE_COMPUTER
    self.AESTHETIC_MODE_BOARDGAME = deps.AESTHETIC_MODE_BOARDGAME
    self.SCREEN_WIDTH = deps.SCREEN_WIDTH
    self.SCREEN_HEIGHT = deps.SCREEN_HEIGHT
    self.GRID_COLS = deps.GRID_COLS
    self.GRID_ROWS = deps.GRID_ROWS
    self.MOVEMENT_PROFILE_HUMAN = deps.MOVEMENT_PROFILE_HUMAN
    self.coords_to_id = deps.coords_to_id
    self.coords_to_world_pos = deps.coords_to_world_pos
    self.world_pos_to_coords = deps.world_pos_to_coords
    self.screen_to_world = deps.screen_to_world
    self.create_world_grid = deps.create_world_grid
    self.bake_level_to_world_grid = deps.bake_level_to_world_grid
    self.get_neighbors = deps.get_neighbors
    self.get_adjacent_cell = deps.get_adjacent_cell
    self.set_ui_square_transform = deps.set_ui_square_transform
    self.create_ui_square = deps.create_ui_square
    self.create_ui_marker_sprite = deps.create_ui_marker_sprite
    self.apply_cell_tint = deps.apply_cell_tint
    self.enter_flow_state = deps.enter_flow_state
    self.toggle_aesthetic_mode = deps.toggle_aesthetic_mode
    self.apply_camera_transform = deps.apply_camera_transform

    local ui = self.level_editor.ui
    ui.panel = self.create_ui_square(0, 0, PANEL_Z, vmath.vector4(0, 0, 0, 0), 1160, 706)
    for i = 1, #MISSION_ORDER do
        ui.tab_buttons[i] = self.create_ui_square(0, 0, TAB_Z, vmath.vector4(0, 0, 0, 0), TAB_W, TAB_H)
    end
    self.level_editor.text.save_new_top = create_text_markers(self, "save", BTN_Z + 0.003)
    self.level_editor.text.save_new_bottom = create_text_markers(self, "new", BTN_Z + 0.003)
    self.level_editor.text.save_edit_top = create_text_markers(self, "save", BTN_Z + 0.003)
    self.level_editor.text.save_edit_bottom = create_text_markers(self, "edit", BTN_Z + 0.003)
    self.level_editor.text.exit_word = create_text_markers(self, "exit", BTN_Z + 0.003)
    self.level_editor.text.delete_word = create_text_markers(self, "delete", BTN_Z + 0.003)
    for i, word in ipairs(MISSION_ORDER) do
        local text_word = word == "dna_sample" and "dna" or word
        self.level_editor.text.tabs[i] = create_text_markers(self, text_word, BTN_Z + 0.003)
    end
    for i = 1, LEVEL_LIST_MAX do
        ui.level_buttons[i] = self.create_ui_square(0, 0, BTN_Z, vmath.vector4(0, 0, 0, 0), LEVEL_LIST_W, LEVEL_LIST_H)
        local d1 = self.create_ui_marker_sprite(hash("score_0"), BTN_Z + 0.002)
        local d2 = self.create_ui_marker_sprite(hash("score_0"), BTN_Z + 0.002)
        local d3 = self.create_ui_marker_sprite(hash("score_0"), BTN_Z + 0.002)
        self.level_editor.level_button_digits[i] = { d1, d2, d3 }
    end
    ui.save_button = self.create_ui_square(0, 0, BTN_Z, vmath.vector4(0, 0, 0, 0), ACTION_W, ACTION_H)
    ui.save_new_button = self.create_ui_square(0, 0, BTN_Z, vmath.vector4(0, 0, 0, 0), ACTION_W, ACTION_H)
    ui.back_button = self.create_ui_square(0, 0, BTN_Z, vmath.vector4(0, 0, 0, 0), EXIT_W, EXIT_H)
    ui.delete_button = self.create_ui_square(0, 0, BTN_Z, vmath.vector4(0, 0, 0, 0), DELETE_BTN_W, DELETE_BTN_H)
    ui.status_strip = self.create_ui_square(0, 0, STATUS_Z, vmath.vector4(0, 0, 0, 0), STATUS_W, STATUS_H)

    local names = {}
    for tile_name, tile_def in pairs(self.tile_library or {}) do
        if tile_name ~= "empty"
            and type(tile_def) == "table"
            and type(tile_def.visualTile) == "string"
        then
            names[#names + 1] = tile_name
        end
    end
    table.sort(names, function(a, b) return a < b end)
    self.level_editor.palette_tiles = names
    for i, _ in ipairs(names) do
        self.level_editor.ui.palette_buttons[i] = self.create_ui_square(0, 0, BTN_Z, vmath.vector4(0, 0, 0, 0), PALETTE_CELL_W, PALETTE_CELL_H)
        local col = ((i - 1) % PALETTE_COLS)
        local row = math.floor((i - 1) / PALETTE_COLS)
        local x = PALETTE_START_X + (col * (PALETTE_CELL_W + PALETTE_GAP_X))
        local y = PALETTE_START_Y - (row * (PALETTE_CELL_H + PALETTE_GAP_Y))
        local icon = factory.create("/tile_factory#tile_factory", vmath.vector3(x, y, 0.923))
        if icon then
            go.set_scale(vmath.vector3(PALETTE_TILE_SCALE, PALETTE_TILE_SCALE, 1), icon)
        end
        self.level_editor.palette_icons[i] = icon
    end

    for x = 1, GRID_VIEW_COLS do
        local lx = self.create_ui_marker_sprite(hash("letter_x"), 0.89)
        local d1 = self.create_ui_marker_sprite(hash("score_0"), 0.89)
        local d2 = self.create_ui_marker_sprite(hash("score_0"), 0.89)
        self.level_editor.x_axis_labels[x] = { lx, d1, d2 }
    end
    for y = 1, GRID_VIEW_ROWS do
        local ly = self.create_ui_marker_sprite(hash("letter_y"), 0.89)
        local d1 = self.create_ui_marker_sprite(hash("score_0"), 0.89)
        local d2 = self.create_ui_marker_sprite(hash("score_0"), 0.89)
        self.level_editor.y_axis_labels[y] = { ly, d1, d2 }
    end
    for i = 1, (GRID_VIEW_COLS * GRID_VIEW_ROWS) do
        self.level_editor.coord_labels[i] = {
            self.create_ui_marker_sprite(hash("letter_x"), BTN_Z + 0.003),
            self.create_ui_marker_sprite(hash("score_0"), BTN_Z + 0.003),
            self.create_ui_marker_sprite(hash("score_0"), BTN_Z + 0.003),
            self.create_ui_marker_sprite(hash("letter_y"), BTN_Z + 0.003),
            self.create_ui_marker_sprite(hash("score_0"), BTN_Z + 0.003),
            self.create_ui_marker_sprite(hash("score_0"), BTN_Z + 0.003)
        }
    end
    for i = 1, (GRID_VIEW_COLS + 1) do
        self.level_editor.grid_lines_v[i] = self.create_ui_square(0, 0, GRID_Z, vmath.vector4(0, 0, 0, 0), GRID_LINE_THICKNESS, GRID_VIEW_ROWS * GRID_CELL_H)
    end
    for i = 1, (GRID_VIEW_ROWS + 1) do
        self.level_editor.grid_lines_h[i] = self.create_ui_square(0, 0, GRID_Z, vmath.vector4(0, 0, 0, 0), GRID_VIEW_COLS * GRID_CELL_W, GRID_LINE_THICKNESS)
    end
    self.level_editor.drag_visual = factory.create("/tile_factory#tile_factory", OFFSCREEN)
    hide_ui(self)
    refresh_current_mission_levels(self)
end

function M.final(self)
    if not self.level_editor then
        return
    end
    delete_go_array(self.level_editor.preview_tile_ids)
    delete_go_array(self.level_editor.invalid_markers)
    delete_go_array(self.level_editor.palette_icons)
    delete_go_map(self.level_editor.ui)
    if self.level_editor.drag_visual then
        pcall(go.delete, self.level_editor.drag_visual)
    end
    if self.level_editor.x_axis_labels then
        for _, digits in ipairs(self.level_editor.x_axis_labels) do
            delete_go_array(digits)
        end
    end
    if self.level_editor.y_axis_labels then
        for _, digits in ipairs(self.level_editor.y_axis_labels) do
            delete_go_array(digits)
        end
    end
    if self.level_editor.coord_labels then
        for _, digits in ipairs(self.level_editor.coord_labels) do
            delete_go_array(digits)
        end
    end
    if self.level_editor.level_button_digits then
        for _, digits in ipairs(self.level_editor.level_button_digits) do
            delete_go_array(digits)
        end
    end
    if self.level_editor.text then
        delete_go_array(self.level_editor.text.save_new_top)
        delete_go_array(self.level_editor.text.save_new_bottom)
        delete_go_array(self.level_editor.text.save_edit_top)
        delete_go_array(self.level_editor.text.save_edit_bottom)
        delete_go_array(self.level_editor.text.exit_word)
        for _, markers in ipairs(self.level_editor.text.tabs or {}) do
            delete_go_array(markers)
        end
    end
    delete_go_array(self.level_editor.grid_lines_v)
    delete_go_array(self.level_editor.grid_lines_h)
end

return M
