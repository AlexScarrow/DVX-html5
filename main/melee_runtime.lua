local M = {}

function M.create(ctx)
    local runtime = {}
    local HUMAN_MELEE_LURCH_REACH_FACTOR = 0.9
    local HUMAN_MELEE_LURCH_OUT_TIME = 0.06
    local HUMAN_MELEE_LURCH_BACK_TIME = 0.08
    local HUMAN_MELEE_LURCH_Z_BONUS = 0.08
    local HUMAN_MELEE_TARGET_FLASH_TIME = 0.09
    local ALIEN_MELEE_LURCH_REACH_FACTOR = 0.9
    local ALIEN_MELEE_LURCH_OUT_TIME = 0.05
    local ALIEN_MELEE_LURCH_BACK_TIME = 0.08
    local ALIEN_MELEE_LURCH_Z_BONUS = 0.06
    local SPEEDY_VERTICAL_LURCH_FACTOR = 0.55
    local HUMAN_VS_SPEEDY_VERTICAL_ARC = 16
    local SPEEDY_VS_HUMAN_VERTICAL_ARC = 14

    local function clamp(v, lo, hi)
        if v < lo then return lo end
        if v > hi then return hi end
        return v
    end

    local BUFFS_BY_ITEM_TYPE = {}
    do
        local buffs = ctx and ctx.BUFFS or nil
        if type(buffs) == "table" then
            for _, buff_def in pairs(buffs) do
                if type(buff_def) == "table" and type(buff_def.item_type) == "string" then
                    BUFFS_BY_ITEM_TYPE[buff_def.item_type] = buff_def
                end
            end
        end
    end

    local function get_human_melee_weapon_count(human)
        if not human or type(human.equipment) ~= "table" then
            return 0
        end
        local count = 0
        local slot_order = ctx.BUFF_SLOT_ORDER or { "top", "center", "left", "right", "bottom" }
        for _, slot_name in ipairs(slot_order) do
            local item_type = human.equipment[slot_name]
            local buff_def = item_type and BUFFS_BY_ITEM_TYPE[item_type] or nil
            if buff_def and buff_def.buff_kind == "melee_weapon" then
                count = count + 1
            end
        end
        return count
    end

    local function get_human_melee_hit_bonus(human)
        local count = get_human_melee_weapon_count(human)
        if count <= 0 then
            return 0
        end
        local single_bonus = tonumber(ctx.BUFF_MELEE_HIT_BONUS_SINGLE or 10) or 10
        local dual_bonus = tonumber(ctx.BUFF_MELEE_HIT_BONUS_DUAL or (single_bonus * 2)) or (single_bonus * 2)
        if count >= 2 then
            return dual_bonus
        end
        return single_bonus
    end

    local function get_human_armor_hit_reduction(human)
        if not human or type(human.equipment) ~= "table" then
            return 0
        end
        local slot_order = ctx.BUFF_SLOT_ORDER or { "top", "center", "left", "right", "bottom" }
        for _, slot_name in ipairs(slot_order) do
            local item_type = human.equipment[slot_name]
            local buff_def = item_type and BUFFS_BY_ITEM_TYPE[item_type] or nil
            if buff_def and buff_def.buff_kind == "armor" then
                return math.max(0, tonumber(ctx.BUFF_ARMOR_HIT_REDUCTION or 15) or 15)
            end
        end
        return 0
    end

    local function get_melee_ap_cost()
        local costs = ctx and ctx.AP_COSTS or nil
        local value = costs and tonumber(costs.melee_attack) or nil
        if value == nil then
            value = 1
        end
        if value < 0 then
            return 0
        end
        return value
    end

    local function get_alien_melee_ap_cost()
        local costs = ctx and ctx.ALIEN_ACTION_COSTS or nil
        local value = costs and tonumber(costs.melee_attack) or nil
        if value == nil then
            value = 1
        end
        if value < 0 then
            return 0
        end
        return value
    end

    local function get_alien_melee_damage(alien_type)
        local cfg = ctx and ctx.ALIEN_TYPE_CONFIG and alien_type and ctx.ALIEN_TYPE_CONFIG[alien_type] or nil
        local value = cfg and tonumber(cfg.melee_damage) or nil
        if value == nil then
            value = 1
        end
        if value < 0 then
            return 0
        end
        return value
    end

    local function get_human_by_id(self, unit_id)
        if not self.squad_units or not unit_id then
            return nil
        end
        return self.squad_units[unit_id]
    end

    local function find_alien_by_id(self, alien_id)
        if not self.aliens then
            return nil
        end
        for _, alien in ipairs(self.aliens) do
            if alien.id == alien_id then
                return alien
            end
        end
        return nil
    end

    local function get_living_humans_on_cell(self, cell_id)
        local list = {}
        if not self.squad_units then
            return list
        end
        for _, unit in pairs(self.squad_units) do
            if unit.cell_id == cell_id and (unit.current_health or 0) > 0 then
                table.insert(list, unit)
            end
        end
        table.sort(list, function(a, b)
            if a.current_health == b.current_health then
                return tostring(a.id) < tostring(b.id)
            end
            return a.current_health < b.current_health
        end)
        return list
    end

    local function get_target_sort_key(target)
        if not target then
            return "z"
        end
        local kind = target.target_kind or "human"
        local id = tostring(target.id or 0)
        return kind .. "_" .. id
    end

    local function get_living_defender_targets_on_cell(self, cell_id)
        local list = {}
        for _, human in ipairs(get_living_humans_on_cell(self, cell_id)) do
            if human then
                human.target_kind = "human"
                table.insert(list, human)
            end
        end
        for _, civilian in ipairs(self.civilians or {}) do
            if civilian
                and civilian.cell_id == cell_id
                and (civilian.current_health or 0) > 0
                and civilian.is_dead ~= true
            then
                civilian.target_kind = "civilian"
                civilian.display_name = civilian.display_name or string.format("Civilian #%d", tonumber(civilian.id or 0) or 0)
                table.insert(list, civilian)
            end
        end
        table.sort(list, function(a, b)
            if (a.current_health or 0) == (b.current_health or 0) then
                return get_target_sort_key(a) < get_target_sort_key(b)
            end
            return (a.current_health or 0) < (b.current_health or 0)
        end)
        return list
    end

    local function get_target_go_id(self, target)
        if not target then
            return nil
        end
        if target.go_path then
            return target.go_path
        end
        if target.target_kind == "civilian" and self and self.civilian_visuals and target.id then
            return self.civilian_visuals[target.id]
        end
        return nil
    end

    local function get_target_display_name(target)
        if not target then
            return "Unknown"
        end
        if target.display_name then
            return target.display_name
        end
        if target.target_kind == "civilian" then
            return string.format("Civilian #%d", tonumber(target.id or 0) or 0)
        end
        return tostring(target.id or "Unknown")
    end

    local function get_living_aliens_on_cell(self, cell_id)
        local list = {}
        if not self.aliens then
            return list
        end
        for _, alien in ipairs(self.aliens) do
            if (not alien.is_dead) and alien.cell_id == cell_id then
                table.insert(list, alien)
            end
        end
        table.sort(list, function(a, b)
            if a.hp_current == b.hp_current then
                return a.id < b.id
            end
            return a.hp_current < b.hp_current
        end)
        return list
    end

    local function cell_has_active_barricade(self, cell_id)
        if not self or not self.world_grid or not cell_id then
            return false
        end
        local cell = self.world_grid[cell_id]
        return cell and cell.has_barricade == true and (cell.barricade_hp or 0) > 0
    end

    local function record_alien_kill(self, alien)
        if not self or not alien then
            return
        end
        if ctx and ctx.record_alien_kill then
            ctx.record_alien_kill(self, alien.type)
        end
    end

    local function kill_alien(self, alien)
        alien.is_dead = true
        alien.is_moving = false
        alien.move_path = nil
        alien.move_path_index = 0
        record_alien_kill(self, alien)
    end

    local function mark_target_hit(self, target)
        if not target then
            return
        end
        if target.target_kind == "civilian" then
            return
        end
        target.hit_flash_timer = ctx.MELEE_MODEL.human_hit_flash_duration
        if target.sprite_path then
            pcall(go.set, target.sprite_path, "tint", vmath.vector4(1, 0.15, 0.15, 1))
        end
    end

    local function spawn_alien_melee_swipe_fx(self, target)
        local go_id = get_target_go_id(self, target)
        if not go_id then
            return
        end
        local pos = go.get_position(go_id)
        local fx_id = factory.create("/tile_factory#tile_factory", vmath.vector3(pos.x, pos.y + 10, 0.9))
        if not fx_id then
            return
        end
        go.set_scale(vmath.vector3(1.5, 1.5, 1), fx_id)
        msg.post(msg.url(nil, fx_id, "sprite"), "play_animation", { id = hash("alien_meleeSwipe_1") })
        go.set(msg.url(nil, fx_id, "sprite"), "tint", vmath.vector4(1, 1, 1, 0.3))
        go.set_rotation(vmath.quat_rotation_z(0), fx_id)
        self.melee_swipe_fx = self.melee_swipe_fx or {}
        table.insert(self.melee_swipe_fx, {
            go_id = fx_id,
            elapsed = 0,
            duration = 0.35,
            spins = 1.5
        })
    end

    local function spawn_alien_blood_splatter_fx(target_alien)
        if not target_alien or not target_alien.go_id then
            return
        end
        local pos = go.get_position(target_alien.go_id)
        local fx_id = factory.create("/alien_blood_splatter1_fx_factory#alien_blood_splatter1_fx_factory", vmath.vector3(pos.x, pos.y + 6, 0.61))
        if not fx_id then
            return
        end
        particlefx.play(msg.url(nil, fx_id, "particlefx"))
        timer.delay(0.12, false, function()
            if fx_id then
                particlefx.stop(msg.url(nil, fx_id, "particlefx"), { clear = false })
            end
        end)
        timer.delay(1.0, false, function()
            if fx_id then
                go.delete(fx_id)
            end
        end)
    end

    local function spawn_human_blood_splatter_fx(self, target_human)
        local go_id = get_target_go_id(self, target_human)
        if not go_id then
            return
        end
        local pos = go.get_position(go_id)
        local fx_id = factory.create("/human_blood_splatter1_fx_factory#human_blood_splatter1_fx_factory", vmath.vector3(pos.x, pos.y + 6, 0.61))
        if not fx_id then
            return
        end
        particlefx.play(msg.url(nil, fx_id, "particlefx"))
        timer.delay(0.12, false, function()
            if fx_id then
                particlefx.stop(msg.url(nil, fx_id, "particlefx"), { clear = false })
            end
        end)
        timer.delay(1.0, false, function()
            if fx_id then
                go.delete(fx_id)
            end
        end)
    end

    local function play_target_red_flash(target_alien)
        if not target_alien or not target_alien.go_id then
            return
        end
        local sprite_url = msg.url(nil, target_alien.go_id, "sprite")
        local ok_tint, base_tint = pcall(go.get, sprite_url, "tint")
        if not ok_tint or not base_tint then
            base_tint = vmath.vector4(1, 1, 1, 1)
        end
        local flash_tint = vmath.vector4(1, 0.25, 0.25, base_tint.w or 1)
        target_alien.melee_flash_active = true
        go.cancel_animations(sprite_url, "tint")
        go.set(sprite_url, "tint", flash_tint)
        timer.delay(HUMAN_MELEE_TARGET_FLASH_TIME, false, function()
            target_alien.melee_flash_active = false
            pcall(go.set, sprite_url, "tint", base_tint)
        end)
    end

    local function play_human_melee_lurch(human, target_alien)
        if not human or not human.go_path or human.is_moving then
            return
        end
        if not target_alien or not target_alien.go_id then
            return
        end
        local attacker_pos = go.get_position(human.go_path)
        local target_pos = go.get_position(target_alien.go_id)
        local dx = target_pos.x - attacker_pos.x
        local dy = target_pos.y - attacker_pos.y
        local len = math.sqrt((dx * dx) + (dy * dy))
        if len <= 0.001 then
            return
        end

        local step_x = dx * HUMAN_MELEE_LURCH_REACH_FACTOR
        local step_y = 0
        if target_alien.type == ctx.ALIEN_TYPE_SPEEDY then
            -- Exception: human vs speedy keeps a temporary upward lurch before returning to floor anchor.
            local guided_arc = math.abs(dy) * SPEEDY_VERTICAL_LURCH_FACTOR
            step_y = math.max(HUMAN_VS_SPEEDY_VERTICAL_ARC, guided_arc)
        end
        local origin = go.get_position(human.go_path)
        local lurch_z = math.max(origin.z, (target_pos.z or origin.z) + HUMAN_MELEE_LURCH_Z_BONUS)
        local lurch_target = vmath.vector3(origin.x + step_x, origin.y + step_y, lurch_z)
        go.cancel_animations(human.go_path, "position")
        go.animate(human.go_path, "position", go.PLAYBACK_ONCE_FORWARD, lurch_target, go.EASING_OUTQUAD, HUMAN_MELEE_LURCH_OUT_TIME, 0, function()
            go.animate(human.go_path, "position", go.PLAYBACK_ONCE_FORWARD, origin, go.EASING_INQUAD, HUMAN_MELEE_LURCH_BACK_TIME)
        end)
    end

    local function play_alien_melee_lurch(self, alien, target_human)
        if not alien or not alien.go_id or alien.is_moving then
            return
        end
        local target_go_id = get_target_go_id(self, target_human)
        if not target_human or not target_go_id then
            return
        end
        local attacker_pos = go.get_position(alien.go_id)
        local target_pos = go.get_position(target_go_id)
        local dx = target_pos.x - attacker_pos.x
        local dy = target_pos.y - attacker_pos.y

        local sprite_url = msg.url(nil, alien.go_id, "sprite")
        local shadow_url = msg.url(nil, alien.go_id, "shadow")
        if alien.type == ctx.ALIEN_TYPE_BRUTE then
            alien.melee_pose_lock_timer = math.max(alien.melee_pose_lock_timer or 0, 0.42)
            local is_boardgame = self and self.aesthetic_mode == "boardgame"
            local side_anim = is_boardgame and hash("alien_brute_side_boardgame") or hash("alien_brute_side")
            pcall(msg.post, sprite_url, "play_animation", { id = side_anim })
            local facing_right = dx > 0
            pcall(sprite.set_hflip, sprite_url, facing_right)
            pcall(sprite.set_hflip, shadow_url, facing_right)
        end

        local len = math.sqrt((dx * dx) + (dy * dy))
        if len <= 0.001 then
            return
        end

        local step_x = dx * ALIEN_MELEE_LURCH_REACH_FACTOR
        local step_y = 0
        if alien.type == ctx.ALIEN_TYPE_SPEEDY then
            -- Exception: speedy vs human lunges downward then returns to ceiling-style anchor.
            local guided_arc = math.abs(dy) * SPEEDY_VERTICAL_LURCH_FACTOR
            step_y = -math.max(SPEEDY_VS_HUMAN_VERTICAL_ARC, guided_arc)
        end
        local origin = go.get_position(alien.go_id)
        local lurch_z = math.max(origin.z, (target_pos.z or origin.z) + ALIEN_MELEE_LURCH_Z_BONUS)
        local lurch_target = vmath.vector3(origin.x + step_x, origin.y + step_y, lurch_z)
        go.cancel_animations(alien.go_id, "position")
        go.animate(alien.go_id, "position", go.PLAYBACK_ONCE_FORWARD, lurch_target, go.EASING_OUTQUAD, ALIEN_MELEE_LURCH_OUT_TIME, 0, function()
            go.animate(alien.go_id, "position", go.PLAYBACK_ONCE_FORWARD, origin, go.EASING_INQUAD, ALIEN_MELEE_LURCH_BACK_TIME, 0, function()
                if alien and alien.go_id and alien.type == ctx.ALIEN_TYPE_BRUTE then
                    timer.delay(0.08, false, function()
                        if alien and alien.go_id and (not alien.is_dead) then
                            alien.melee_pose_lock_timer = 0
                            local is_boardgame = self and self.aesthetic_mode == "boardgame"
                            local front_anim = is_boardgame and hash("alien_brute_boardgame") or hash("alien_brute")
                            local end_sprite_url = msg.url(nil, alien.go_id, "sprite")
                            local end_shadow_url = msg.url(nil, alien.go_id, "shadow")
                            pcall(msg.post, end_sprite_url, "play_animation", { id = front_anim })
                            pcall(sprite.set_hflip, end_sprite_url, false)
                            pcall(sprite.set_hflip, end_shadow_url, false)
                        end
                    end)
                end
            end)
        end)
    end

    local function resolve_human_melee_strike(self, human, target_alien, source_tag)
        if not human or not target_alien then
            return
        end
        local melee_ap_cost = get_melee_ap_cost()
        if (human.current_health or 0) <= 0 or human.current_ap < melee_ap_cost then
            return
        end
        if target_alien.is_dead or target_alien.cell_id ~= human.cell_id then
            return
        end
        if cell_has_active_barricade(self, human.cell_id) then
            print(string.format("%s melee blocked by barricade on cell %d.", human.display_name, human.cell_id or -1))
            return
        end

        play_human_melee_lurch(human, target_alien)
        play_target_red_flash(target_alien)
        human.current_ap = human.current_ap - melee_ap_cost
        local melee_bonus = get_human_melee_hit_bonus(human)
        local min_hit = tonumber(ctx.BUFF_HIT_CHANCE_MIN or ctx.MELEE_MODEL.min_hit_chance) or ctx.MELEE_MODEL.min_hit_chance
        local max_hit = tonumber(ctx.BUFF_HIT_CHANCE_MAX or ctx.MELEE_MODEL.max_hit_chance) or ctx.MELEE_MODEL.max_hit_chance
        local hit_chance = clamp((ctx.MELEE_MODEL.human_base_hit_chance or 0) + melee_bonus, min_hit, max_hit)
        local roll = math.random(1, 100)
        if roll <= hit_chance then
            spawn_alien_blood_splatter_fx(target_alien)
            if target_alien.type == ctx.ALIEN_TYPE_BRUTE then
                target_alien.hp_current = math.max(0, (target_alien.hp_current or 1) - 1)
                if target_alien.hp_current > 0 then
                    target_alien.brute_damage_flash_timer = 0.24
                end
                print(string.format(
                    "%s melee %s on alien #%d (BRUTE) and HIT [chance=%d%% roll=%d hp=%d buff=%d]",
                    human.display_name, source_tag, target_alien.id, hit_chance, roll, target_alien.hp_current, melee_bonus
                ))
                if target_alien.hp_current <= 0 then
                    kill_alien(self, target_alien)
                    print(string.format("Alien #%d (BRUTE) is dead.", target_alien.id))
                end
            else
                print(string.format(
                    "%s melee %s on alien #%d and HIT (alien eliminated) [chance=%d%% roll=%d buff=%d]",
                    human.display_name, source_tag, target_alien.id, hit_chance, roll, melee_bonus
                ))
                kill_alien(self, target_alien)
            end
        else
            print(string.format(
                "%s melee %s on alien #%d and MISSED [chance=%d%% roll=%d buff=%d]",
                human.display_name, source_tag, target_alien.id, hit_chance, roll, melee_bonus
            ))
        end
    end

    local function resolve_alien_melee_strike(self, alien)
        local melee_ap_cost = get_alien_melee_ap_cost()
        local ap_left = tonumber(alien and alien.turn_ap_remaining or 0) or 0
        if ap_left < melee_ap_cost then
            return
        end

        local targets = get_living_defender_targets_on_cell(self, alien.cell_id)
        if #targets == 0 then
            return
        end
        if cell_has_active_barricade(self, alien.cell_id) then
            return
        end

        local target = targets[1] -- weakest-first across humans+civilians
        local armor_bonus = 0
        if target.target_kind ~= "civilian" then
            armor_bonus = get_human_armor_hit_reduction(target)
        end
        local hit_chance = clamp(ctx.MELEE_MODEL.alien_base_hit_chance - armor_bonus, ctx.MELEE_MODEL.min_hit_chance, ctx.MELEE_MODEL.max_hit_chance)
        local roll = math.random(1, 100)
        alien.turn_ap_remaining = math.max(0, ap_left - melee_ap_cost)
        if ctx and ctx.record_alien_melee_spend then
            ctx.record_alien_melee_spend(self, alien.id, melee_ap_cost)
        end
        spawn_alien_melee_swipe_fx(self, target)
        play_alien_melee_lurch(self, alien, target)

        if roll <= hit_chance then
            local damage = get_alien_melee_damage(alien and alien.type)
            target.current_health = math.max(0, (target.current_health or 0) - damage)
            mark_target_hit(self, target)
            spawn_human_blood_splatter_fx(self, target)
            print(string.format(
                "Alien #%d melee on %s and HIT [chance=%d%% roll=%d dmg=%d hp=%d armor=%d]",
                alien.id, get_target_display_name(target), hit_chance, roll, damage, target.current_health, armor_bonus
            ))
            if target.current_health <= 0 then
                if target.target_kind == "civilian" then
                    target.is_dead = true
                    target.current_ap = 0
                    target.is_awake = false
                    target.is_moving = false
                    target.move_path = nil
                    target.move_path_index = 0
                elseif ctx and ctx.handle_human_death_loot_drop then
                    ctx.handle_human_death_loot_drop(self, target)
                end
                print(get_target_display_name(target) .. " is dead")
            end
        else
            print(string.format(
                "Alien #%d melee on %s and MISSED [chance=%d%% roll=%d armor=%d]",
                alien.id, get_target_display_name(target), hit_chance, roll, armor_bonus
            ))
        end

        if self.reactive_combat_enabled then
            local retaliators = get_living_humans_on_cell(self, alien.cell_id)
            for _, human in ipairs(retaliators) do
                if human.current_ap > 0 then
                    table.insert(self.melee_action_queue, {
                        kind = "human_react",
                        human_id = human.id,
                        preferred_alien_id = alien.id,
                        cell_id = alien.cell_id
                    })
                end
            end
        end

        local still_has_humans = #get_living_defender_targets_on_cell(self, alien.cell_id) > 0
        local remaining = tonumber(alien.turn_ap_remaining or 0) or 0
        if (not alien.is_dead) and remaining > 0 and still_has_humans then
            table.insert(self.melee_action_queue, { kind = "alien", alien_id = alien.id })
        end
    end

    runtime.begin_phase = function(self)
        self.pending_melee_attack_phase = true
        self.melee_attack_started = false
        self.melee_attack_timer = 0
        self.melee_action_queue = {}
    end

    runtime.is_busy = function(self)
        return self.pending_melee_attack_phase == true
    end

    runtime.update_human_hit_flash = function(self, dt)
        if not self.squad_units then
            return
        end
        for _, unit in pairs(self.squad_units) do
            if unit.hit_flash_timer and unit.hit_flash_timer > 0 then
                unit.hit_flash_timer = math.max(0, unit.hit_flash_timer - dt)
            end
        end
    end

    runtime.update_swipe_fx = function(self, dt)
        if not self.melee_swipe_fx then
            return
        end
        for i = #self.melee_swipe_fx, 1, -1 do
            local fx = self.melee_swipe_fx[i]
            if not fx.go_id then
                table.remove(self.melee_swipe_fx, i)
            else
                fx.elapsed = (fx.elapsed or 0) + dt
                local t = math.min(1, fx.elapsed / (fx.duration or 0.35))
                local angle = math.rad(360 * (fx.spins or 3) * t)
                go.set_rotation(vmath.quat_rotation_z(angle), fx.go_id)
                if t >= 1 then
                    go.delete(fx.go_id)
                    table.remove(self.melee_swipe_fx, i)
                end
            end
        end
    end

    runtime.spawn_alien_blood_splatter_fx = function(self, alien)
        spawn_alien_blood_splatter_fx(alien)
    end

    runtime.spawn_human_blood_splatter_fx = function(self, human)
        spawn_human_blood_splatter_fx(self, human)
    end

    runtime.update_phase = function(self, dt)
        if not self.pending_melee_attack_phase then
            return
        end

        if not self.melee_attack_started then
            if ctx.any_alien_is_moving(self) then
                return
            end
            self.melee_attack_started = true
            self.melee_action_queue = {}

            for _, alien in ipairs(self.aliens or {}) do
                if not alien.is_dead then
                    local ap_budget = alien.turn_ap_remaining or alien.ap_max or 0
                    if ap_budget > 0 and #get_living_defender_targets_on_cell(self, alien.cell_id) > 0 then
                        table.insert(self.melee_action_queue, { kind = "alien", alien_id = alien.id })
                    end
                end
            end

            if #self.melee_action_queue == 0 then
                self.pending_melee_attack_phase = false
                return
            end
        end

        self.melee_attack_timer = self.melee_attack_timer - dt
        if self.melee_attack_timer > 0 then
            return
        end

        if #self.melee_action_queue == 0 then
            self.pending_melee_attack_phase = false
            return
        end

        local action = table.remove(self.melee_action_queue, 1)
        if not action then
            self.pending_melee_attack_phase = false
            return
        end

        if action.kind == "alien" then
            local alien = find_alien_by_id(self, action.alien_id)
            if alien and (not alien.is_dead) then
                resolve_alien_melee_strike(self, alien)
            end
        elseif action.kind == "human_react" then
            local human = get_human_by_id(self, action.human_id)
            if human and (human.current_health or 0) > 0 and human.current_ap > 0 and human.cell_id == action.cell_id then
                local target = nil
                local preferred = find_alien_by_id(self, action.preferred_alien_id)
                if preferred and (not preferred.is_dead) and preferred.cell_id == human.cell_id then
                    target = preferred
                else
                    local aliens = get_living_aliens_on_cell(self, human.cell_id)
                    target = aliens[1]
                end
                if target then
                    resolve_human_melee_strike(self, human, target, "reactive strike")
                end
            end
        end

        self.melee_attack_timer = ctx.MELEE_MODEL.swipe_interval_seconds
    end

    runtime.try_manual_human_melee = function(self, unit, alien)
        if not unit or not alien then
            return false
        end
        if unit.cell_id ~= alien.cell_id then
            return false
        end
        local melee_ap_cost = get_melee_ap_cost()
        if unit.current_ap < melee_ap_cost then
            print("Unable melee strike: no AP")
            return true
        end
        if alien.is_dead then
            return true
        end

        resolve_human_melee_strike(self, unit, alien, "manual strike")
        return true
    end

    return runtime
end

return M
