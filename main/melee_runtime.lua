local M = {}

function M.create(ctx)
    local runtime = {}
    local HUMAN_MELEE_LURCH_DISTANCE = 28
    local HUMAN_MELEE_LURCH_OUT_TIME = 0.06
    local HUMAN_MELEE_LURCH_BACK_TIME = 0.08
    local HUMAN_MELEE_LURCH_Z_BONUS = 0.08
    local HUMAN_MELEE_TARGET_FLASH_TIME = 0.09
    local ALIEN_MELEE_LURCH_DISTANCE = 26
    local ALIEN_MELEE_LURCH_OUT_TIME = 0.05
    local ALIEN_MELEE_LURCH_BACK_TIME = 0.08
    local ALIEN_MELEE_LURCH_Z_BONUS = 0.06

    local function clamp(v, lo, hi)
        if v < lo then return lo end
        if v > hi then return hi end
        return v
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

    local function kill_alien(alien)
        alien.is_dead = true
        alien.is_moving = false
        alien.move_path = nil
        alien.move_path_index = 0
    end

    local function mark_human_hit(unit)
        unit.hit_flash_timer = ctx.MELEE_MODEL.human_hit_flash_duration
        if unit.sprite_path then
            pcall(go.set, unit.sprite_path, "tint", vmath.vector4(1, 0.15, 0.15, 1))
        end
    end

    local function spawn_alien_melee_swipe_fx(self, target)
        if not target or not target.go_path then
            return
        end
        local pos = go.get_position(target.go_path)
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

    local function spawn_human_blood_splatter_fx(target_human)
        if not target_human or not target_human.go_path then
            return
        end
        local pos = go.get_position(target_human.go_path)
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

        local step_x = (dx / len) * HUMAN_MELEE_LURCH_DISTANCE
        local step_y = (dy / len) * HUMAN_MELEE_LURCH_DISTANCE
        local origin = go.get_position(human.go_path)
        local lurch_z = math.max(origin.z, (target_pos.z or origin.z) + HUMAN_MELEE_LURCH_Z_BONUS)
        local lurch_target = vmath.vector3(origin.x + step_x, origin.y + step_y, lurch_z)
        go.cancel_animations(human.go_path, "position")
        go.animate(human.go_path, "position", go.PLAYBACK_ONCE_FORWARD, lurch_target, go.EASING_OUTQUAD, HUMAN_MELEE_LURCH_OUT_TIME, 0, function()
            go.animate(human.go_path, "position", go.PLAYBACK_ONCE_FORWARD, origin, go.EASING_INQUAD, HUMAN_MELEE_LURCH_BACK_TIME)
        end)
    end

    local function play_alien_melee_lurch(alien, target_human)
        if not alien or not alien.go_id or alien.is_moving then
            return
        end
        if not target_human or not target_human.go_path then
            return
        end
        local attacker_pos = go.get_position(alien.go_id)
        local target_pos = go.get_position(target_human.go_path)
        local dx = target_pos.x - attacker_pos.x
        local dy = target_pos.y - attacker_pos.y
        local len = math.sqrt((dx * dx) + (dy * dy))
        if len <= 0.001 then
            return
        end

        local step_x = (dx / len) * ALIEN_MELEE_LURCH_DISTANCE
        local step_y = (dy / len) * ALIEN_MELEE_LURCH_DISTANCE
        local origin = go.get_position(alien.go_id)
        local lurch_z = math.max(origin.z, (target_pos.z or origin.z) + ALIEN_MELEE_LURCH_Z_BONUS)
        local lurch_target = vmath.vector3(origin.x + step_x, origin.y + step_y, lurch_z)
        go.cancel_animations(alien.go_id, "position")
        go.animate(alien.go_id, "position", go.PLAYBACK_ONCE_FORWARD, lurch_target, go.EASING_OUTQUAD, ALIEN_MELEE_LURCH_OUT_TIME, 0, function()
            go.animate(alien.go_id, "position", go.PLAYBACK_ONCE_FORWARD, origin, go.EASING_INQUAD, ALIEN_MELEE_LURCH_BACK_TIME)
        end)
    end

    local function resolve_human_melee_strike(self, human, target_alien, source_tag)
        if not human or not target_alien then
            return
        end
        if (human.current_health or 0) <= 0 or human.current_ap <= 0 then
            return
        end
        if target_alien.is_dead or target_alien.cell_id ~= human.cell_id then
            return
        end

        play_human_melee_lurch(human, target_alien)
        play_target_red_flash(target_alien)
        human.current_ap = human.current_ap - 1
        local hit_chance = clamp(ctx.MELEE_MODEL.human_base_hit_chance, ctx.MELEE_MODEL.min_hit_chance, ctx.MELEE_MODEL.max_hit_chance)
        local roll = math.random(1, 100)
        if roll <= hit_chance then
            spawn_alien_blood_splatter_fx(target_alien)
            if target_alien.type == ctx.ALIEN_TYPE_BRUTE then
                target_alien.hp_current = math.max(0, (target_alien.hp_current or 1) - 1)
                print(string.format(
                    "%s melee %s on alien #%d (BRUTE) and HIT [chance=%d%% roll=%d hp=%d]",
                    human.display_name, source_tag, target_alien.id, hit_chance, roll, target_alien.hp_current
                ))
                if target_alien.hp_current <= 0 then
                    kill_alien(target_alien)
                    print(string.format("Alien #%d (BRUTE) is dead.", target_alien.id))
                end
            else
                print(string.format(
                    "%s melee %s on alien #%d and HIT (alien eliminated) [chance=%d%% roll=%d]",
                    human.display_name, source_tag, target_alien.id, hit_chance, roll
                ))
                kill_alien(target_alien)
            end
        else
            print(string.format(
                "%s melee %s on alien #%d and MISSED [chance=%d%% roll=%d]",
                human.display_name, source_tag, target_alien.id, hit_chance, roll
            ))
        end
    end

    local function resolve_alien_melee_strike(self, alien)
        local ap_left = self.melee_ap_left_by_alien_id and (self.melee_ap_left_by_alien_id[alien.id] or 0) or 0
        if ap_left <= 0 then
            return
        end

        local humans = get_living_humans_on_cell(self, alien.cell_id)
        if #humans == 0 then
            return
        end

        local target = humans[1] -- weakest-first
        local armor_bonus = target.melee_armor_bonus or target.equipped_armor_bonus or 0
        local hit_chance = clamp(ctx.MELEE_MODEL.alien_base_hit_chance - armor_bonus, ctx.MELEE_MODEL.min_hit_chance, ctx.MELEE_MODEL.max_hit_chance)
        local roll = math.random(1, 100)
        self.melee_ap_left_by_alien_id[alien.id] = ap_left - 1
        spawn_alien_melee_swipe_fx(self, target)
        play_alien_melee_lurch(alien, target)

        if roll <= hit_chance then
            target.current_health = math.max(0, (target.current_health or 0) - 1)
            mark_human_hit(target)
            spawn_human_blood_splatter_fx(target)
            print(string.format(
                "Alien #%d melee on %s and HIT [chance=%d%% roll=%d hp=%d armor=%d]",
                alien.id, target.display_name, hit_chance, roll, target.current_health, armor_bonus
            ))
            if target.current_health <= 0 then
                print(target.display_name .. " is dead")
            end
        else
            print(string.format(
                "Alien #%d melee on %s and MISSED [chance=%d%% roll=%d armor=%d]",
                alien.id, target.display_name, hit_chance, roll, armor_bonus
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

        local still_has_humans = #get_living_humans_on_cell(self, alien.cell_id) > 0
        local remaining = self.melee_ap_left_by_alien_id[alien.id] or 0
        if (not alien.is_dead) and remaining > 0 and still_has_humans then
            table.insert(self.melee_action_queue, { kind = "alien", alien_id = alien.id })
        end
    end

    runtime.begin_phase = function(self)
        self.pending_melee_attack_phase = true
        self.melee_attack_started = false
        self.melee_attack_timer = 0
        self.melee_action_queue = {}
        self.melee_ap_left_by_alien_id = {}
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
        spawn_human_blood_splatter_fx(human)
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
            self.melee_ap_left_by_alien_id = {}

            for _, alien in ipairs(self.aliens or {}) do
                if not alien.is_dead then
                    local ap_budget = alien.turn_ap_remaining or alien.ap_max or 0
                    self.melee_ap_left_by_alien_id[alien.id] = ap_budget
                    if ap_budget > 0 and #get_living_humans_on_cell(self, alien.cell_id) > 0 then
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
        if unit.current_ap <= 0 then
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
