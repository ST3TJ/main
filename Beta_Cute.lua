--[[#region: script info
	#Lua: Cute.lua
	#Creator: MSDTR / banan#2114
	#Version: 0.5.0 [beta]
]]

lua_started = false
cheat.popup("[Cute.lua] Info", "Starting lua")

--- #region: ui
ui.add_label("[Ragebot]")
ui.add_checkbox("Freestand on Peek")
ui.add_checkbox("LagPeek")
ui.add_sliderint("Fakelag on peek", 1,16)
ui.add_sliderint("Delay", 1,10)

ui.add_label("")
ui.add_label("[Anti-Aim]")
ui.add_combobox("AA Preset", {"None", "Tank", "FL Based", "Dynamic", "For sqwat<3"})
ui.add_combobox("Jitter", {"None", "Offset", "Centered"})
ui.add_checkbox("Fake Flick")
ui.add_checkbox("Extended Desync")
ui.add_sliderint("Jitter Lenght", 0,180) ui.add_sliderint("Flick Speed", 0, 10) ui.add_sliderint("Desync Delta", 0,60)
ui.add_checkbox("Legit AA on E")
ui.add_checkbox("Off All AA on E")
ui.add_checkbox("Leg Breaker")

ui.add_label(" ")
ui.add_label("[Visual]")
ui.add_checkbox("Inverter arrows") ui.add_colorpicker("arrows color") ui.add_sliderint("Arrow Distance", -20,100)
ui.add_checkbox("Snaplines") ui.add_colorpicker("Snapline color")
ui.add_checkbox("Nimb") ui.add_colorpicker("nimb color")
ui.add_checkbox("Viewmodel in scope")
ui.add_checkbox("Indicators") ui.add_colorpicker("ind color") ui.add_sliderint("Ind y", 0,80)
ui.add_checkbox("Holo Panel") ui.add_colorpicker("holopanel color")  ui.add_sliderint("Holo Distance", -200,500)
ui.add_checkbox("Custom Backrgound Color") ui.add_colorpicker("Background color")
ui.add_checkbox("Custom Text Color") ui.add_colorpicker("HOLOText color")

ui.add_label("  ")
ui.add_label("[Misc]")
ui.add_checkbox("Fix nightmode")
ui.add_checkbox("Clantag")
ui.add_checkbox("Kill Say")
ui.add_checkbox("Disable chat")
--- #endregion


--- #region: help functions
function screen()
	return {x = engine.get_screen_width(), y = engine.get_screen_height()}
end

function center_text(font, text, type)
	if type == "x" then return render.get_text_width(font, text) / 2 end
	if type == "y" then
		if text == nil or text == "None" then return 0 end
		return render.get_text_height(font, text) end
end

function player_alive()
	return entitylist.get_local_player():is_alive()
end

function inverter()
	return ui.get_keybind_state(keybinds.flip_desync)
end

function in_air()
	return entitylist.get_local_player():get_prop_bool('CBasePlayer', 'm_hGroundEntity')
end

function GetState()
    local LocalPlayer = entitylist.get_local_player()
    local m_fFlags = LocalPlayer:get_prop_int("CBasePlayer", "m_fFlags")

    if m_fFlags == 256 then
        return "In air"
    elseif m_fFlags == 263 then
        return "Crouching"
    elseif m_fFlags == 262 then
        return "Crouch + Air"
    end
    
    if LocalPlayer:get_velocity():length_2d() > 5 and not ui.get_keybind_state(keybinds.slowwalk) then
        return "Running"
    end
    if ui.get_keybind_state(keybinds.slowwalk) then
        return "Slowwalking"
    end

    return "Standing"
end

function GetExploit()
	local hs = ui.get_keybind_state(keybinds.hide_shots)
	local dt = ui.get_keybind_state(keybinds.double_tap)
	local fl = ui.get_bool("Antiaim.fake_lag")
	local rec = globalvars.get_dt_recharging()
	
	if hs and not rec then exploit = "Hideshot" end
	if dt and not rec then exploit = "Doubletap" end
	if not hs and not dt and fl and not rec then exploit = "Fakelag " .. ui.get_int("Antiaim.fake_lag_limit") .. "t" end
	if not hs and not dt and not fl and not rec then exploit = "None" end
	if rec then exploit = "Doubletap recharge" end
	if ui.get_keybind_state(keybinds.fakeduck) and not in_air() then exploit = "Fakeduck" end
	
	return exploit
end

function GetAAState()
	local yaw = ui.get_int("0Antiaim.yaw")
	local desync = ui.get_int("0Antiaim.desync")
	local lean = {
		def = ui.get_int("0Antiaim.body_lean"),
		inv = ui.get_int("0Antiaim.inverted_body_lean"),
	}
	
	if ui.get_bool("LagPeek") and ui.get_keybind_state(keybinds.automatic_peek) then return "LagPeek" end
	if ui.get_bool("Antiaim.freestand") and ui.get_int("0Antiaim.base_angle") == 0 then
		if ui.get_keybind_state(keybinds.damage_override) then
			if ui.get_keybind_state(keybinds.double_tap) then
				return "Ideal Peek"
			end
		end
	end
	if ui.get_bool("Freestand on Peek") and ui.get_keybind_state(keybinds.automatic_peek) then return "Freestand Peek" end
	if ui.get_bool("Antiaim.freestand") and ui.get_int("0Antiaim.base_angle") == 0 then return "Freestanding" end
	
	if ui.get_int("Jitter Lenght") > 0 then 
		if ui.get_int("Jitter") == 1 then return "Offset Jitter " .. ui.get_int("Jitter Lenght") .. "°" 
		elseif ui.get_int("Jitter") == 2 then return "Center Jitter " .. ui.get_int("Jitter Lenght") .. "°" 
		end
	end
	if ui.get_bool("Extended Desync") and ui.get_int("Desync Delta") > 0 then return "Extended Desync" end
	if ui.get_int("AA Preset") == 3 then return "Dynamic" end
	if ui.get_int("AA Preset") == 2 then return "Fakelag Based" end
	if ui.get_int("AA Preset") == 1 then return "Tank" end
	if ui.get_bool("Fake Flick") then return "Fake-Flicking" end
	
	if desync == 0 and yaw == 0 then return "Only Yaw" end
	if desync == 2 and yaw == 1 then return "Tank" end
	if desync == 2 and (lean.inv > 0 or lean.def > 0) then return "Jitter Lean " .. (lean.def+lean.inv)/2 .. "°" end
	
	if desync == 1 and lean.inv > 0 and inverter() then return "Lean " .. lean.inv .. "°" end
	if desync == 1 and lean.def > 0 and not inverter() then return "Lean " .. lean.def .. "°" end
	
	if yaw == 0 then return "Static" end
	if yaw == 1 then return "Jitter" end
	if yaw == 2 then return "Spin" end
end

set_aa = {
	lean = function(def,inv) ui.set_int("0Antiaim.body_lean", def) ui.set_int("0Antiaim.inverted_body_lean", inv) end,
	desync = function(type, def, inv) ui.set_int("0Antiaim.desync", type) if def ~= nil then ui.set_int("0Antiaim.desync_range", def) end if inv ~= nil then ui.set_int("0Antiaim.inverted_desync_range", inv) end end,
	yaw = function(type, range, speed) ui.set_int("0Antiaim.yaw", type) if range ~= nil then ui.set_int("0Antiaim.range", range) end if speed ~= nil then ui.set_int("0Antiaim.speed", speed) end end,
}
--- #endregion


--- #region: Other
verdana = render.setup_font("Verdana", 18, fontflags.bold)
small_verdana = render.setup_font("Verdana", 14, fontflags.bold)
enabled = {jitter = false, extended = false, legit = false, breaker = false, viewmodel = false, flick = false, freestandpeek = false, chatdis = false, clantag = false, presets = false, lagpeek = false}
killsay = {"1", "ez nn doggy", "Why crying?", "rqrqrqrqrq", "nt brainless", "cry))))", "Owned by Cute.lua", "Imagine losing to rawetrip", "ez?", "*DIED*"}
--- #endregion


--- #region: Snaplines

local function snapline()

	if not lua_started then
		local closest_enemy = nil
		local enemy_id = nil
	end
	
	if not ui.get_bool("Snaplines") or not engine.is_connected() or not player_alive() then return end
	
	local player_abs = entitylist.get_local_player():get_absorigin()
	local enemies = entitylist.get_players(true)
	
	if #enemies < 1 then return end
	
	local distance = {}
	
	for i = 1, #enemies do
		local enemy_dist = enemies[i]:get_absorigin():dist_to(player_abs)
		if not enemies[i]:get_dormant() and enemies[i]:is_alive() then table.insert(distance, math.ceil(enemy_dist)) end
	end
	
	table.sort(distance, function(a, b) return a < b end)
	closest_enemy = distance[1]
	
	if closest_enemy == nil or closest_enemy == 0 then return end
	
	for i = 1, #enemies do
		local cur_enemy_dist = math.ceil(enemies[i]:get_absorigin():dist_to(player_abs))
		if closest_enemy == cur_enemy_dist then
			enemy_id = i
		end
	end
	
	line = {
		start = render.world_to_screen(player_abs),
		_end = render.world_to_screen(enemies[enemy_id]:get_absorigin()),
	}
	
	if enemies[enemy_id]:is_alive() then
		if ui.get_keybind_state(keybinds.thirdperson) then
			if line._end.x > -50000 and line._end.x < 50000 then
				render.line(line.start.x, line.start.y, line._end.x, line._end.y, ui.get_color("Snapline color"))
			end
		else
			if line._end.x > -50000 and line._end.x < 50000 then
				render.line(screen().x/2, screen().y, line._end.x, line._end.y, ui.get_color("Snapline color"))
			end
		end
	end
end
--- #endregion

-- #region: nimb
local function nimb()

	if not ui.get_bool("Nimb") or not engine.is_connected() or not player_alive() then return end
	
	local head = entitylist.get_local_player():get_player_hitbox_pos( 0 )
	
	if ui.get_keybind_state(keybinds.thirdperson) and player_alive() then
		render.circle_3d(vector.new(head.x,head.y,head.z+10), 5, ui.get_color("nimb color"))
	end

end
--- #endregion


--- #region: Nightmode fix
local function nightmode_fix()

	if not lua_started then
		local last_map = nil
		local skybox_type = nil
	end

	if not ui.get_bool("Fix nightmode") then return end
	
	local tickcount = globalvars.get_tickcount() %192
	
	if tickcount == 0 then
		if (last_map ~= engine.get_level_name_short()) then
			cheat.popup("[Cute.lua] Info", "Restarting Nightmode")
			skybox_type = ui.get_int("Esp.skybox")
			ui.set_bool("Esp.nightmode", false)
			ui.set_int("Esp.skybox", 0)
		end
		
		last_map = engine.get_level_name_short()
		end
	
	if tickcount == 32 then
		if not ui.get_bool("Esp.nightmode") then ui.set_bool("Esp.nightmode", true) end
		if ui.get_int("Esp.skybox") == 0 then ui.set_int("Esp.skybox", skybox_type) end
	end
	
end
--- #endregion


--- #region: inverter arrows
local function inv_arrows()
	
	if not ui.get_bool("Inverter arrows") or not engine.is_connected() or not player_alive() then return end
	
	local dist = ui.get_int("Arrow Distance")
	local cr = ui.get_color("arrows color")
	local manual = {
		left = ui.get_keybind_state(keybinds.manual_left),
		right = ui.get_keybind_state(keybinds.manual_right),
		c_left = color.new(1,1,1,cr:a()),
		c_right = color.new(1,1,1,cr:a()),
	}
	if manual.left then manual.c_left = cr end
	if manual.right then manual.c_right = cr end
	
	render.triangle((screen().x/2)-45-dist, ((screen().y/2)+10)+3, (screen().x/2)-60-dist, (screen().y/2), (screen().x/2)-45-dist, (screen().y/2)-12, manual.c_left)
	render.triangle((screen().x/2)+45+dist, ((screen().y/2)+10)+3, (screen().x/2)+60+dist, (screen().y/2), (screen().x/2)+45+dist, (screen().y/2)-12, manual.c_right)
	if antiaim.get_body_yaw() > 0 then
		render.rect_filled((screen().x/2)-43-dist, (screen().y/2)-12, 3, 25, color.new(cr:r(),cr:g(),cr:b() ))
	else
		render.rect_filled((screen().x/2)+38+dist, (screen().y/2)-12, 3, 25, color.new(cr:r(),cr:g(),cr:b() ))
	end
	
end
--- #endregion


--- #region: legit aa on e
local function legit_aa()

	if not ui.get_bool("Legit AA on E") and enabled.legit then
		enabled.legit = false
		console.execute_client_cmd("-use")
		console.execute_client_cmd("bind e +use")
		ui.set_int("0Antiaim.base_angle", 1)
		ui.set_int("Antiaim.yaw_offset", 0)
		ui.set_int("0Antiaim.pitch", 1)
	end
	
	if not lua_started then
		local pressed_e = false
		local bool = false
	end
	
	if not ui.get_bool("Legit AA on E") or not player_alive() then return end
	
	enabled.legit = true
	
	local isDefusing = entitylist.get_local_player():get_prop_bool('CCSPlayer', 'm_bIsDefusing')
	local isGrabbing = entitylist.get_local_player():get_prop_bool('CCSPlayer', 'm_bIsGrabbingHostage')
	local manual = ui.get_keybind_state(keybinds.manual_left) or ui.get_keybind_state(keybinds.manual_right)
	
	if engine.get_active_key(0x45) and not isDefusing and not isGrabbing then
	
		pressed_e = true
		
		if ui.get_bool("Off All AA on E") then set_aa.desync(1,60,60) set_aa.lean(0,0) set_aa.yaw(0,nil,nil) end
	
		console.execute_client_cmd("unbind e")
		console.execute_client_cmd("-use")
		ui.set_int("0Antiaim.base_angle", 0)
		if manual then ui.set_int("Antiaim.yaw_offset", 0) else ui.set_int("Antiaim.yaw_offset", 180) end
		
		ui.set_int("0Antiaim.pitch", 0)
		if inverter() and not bool then ui.set_keybind_state(keybinds.flip_desync, false) bool = true elseif not bool then ui.set_keybind_state(keybinds.flip_desync, true) bool = true end
		
	elseif not engine.get_active_key(0x45) and pressed_e then
	
		console.execute_client_cmd("bind e +use")
		if inverter() then ui.set_keybind_state(keybinds.flip_desync, false) bool = false else ui.set_keybind_state(keybinds.flip_desync, true) bool = false end
		ui.set_int("0Antiaim.base_angle", 1)
		ui.set_int("Antiaim.yaw_offset", 0)
		ui.set_int("0Antiaim.pitch", 1)
		pressed_e = false
	end
	
	if isDefusing or isGrabbing and pressed_e then
		console.execute_client_cmd("+use")
		pressed_e = false
	end
	
end
--- #endregion


--- #region: extended desync
local function ext_desync()

	if not ui.get_bool("Extended Desync") and enabled.extended then 
		enabled.extended = false
		cmd.set_viewangles("z", 0)
	end
	
	if not ui.get_bool("Extended Desync") or not player_alive() or in_air() then return end
	
	enabled.extended = true
	local delta = ui.get_int("Desync Delta")
	if delta == 0 then return end
	
	if inverter() then cmd.set_viewangles("z", delta) else cmd.set_viewangles("z", -delta) end
	ext_desync_fix();
end

ext_desync_fix = function()
    if not ui.get_bool("Extended Desync") or not player_alive() then return end

    local frL, riL = vector.new(0, cmd.get_viewangles().y, 0):forward()
    local frC, riC = cmd.get_viewangles():forward()

	frL.z = 0
	riL.z = 0
	frC.z = 0
	riC.z = 0

    frL = frL / frL:length()
    riL = riL / riL:length()
    frC = frC / frC:length()
    riC = riC / riC:length()

    local Move = vector2d.new(cmd.get_forwardmove(), cmd.get_sidemove())
    local Coord = (frL * Move.x) + (riL * Move.y)

    cmd.sidemove((frC.x * Coord.y - frC.y * Coord.x) / (riC.y * frC.x - riC.x * frC.y))
    cmd.forwardmove((riC.y * Coord.x - riC.x * Coord.y) / (riC.y * frC.x - riC.x * frC.y))
end
--- #endregion


--- #region: legbreaker
local function legbreaker()

	if not ui.get_bool("Leg Breaker") and enabled.breaker then
		enabled.breaker = false
		ui.set_int("Misc.leg_movement", 0)
	end
	
	if not ui.get_bool("Leg Breaker") or not player_alive() then return end
	
	enabled.breaker = true
	
	local tickcount = globalvars.get_tickcount() %2
	
	entitylist.get_local_player():m_flposeparameter()[7] = 1
	if tickcount == 0 then ui.set_int("Misc.leg_movement", 0) else ui.set_int("Misc.leg_movement", 1) end
end
--- #endregion


--- #region: jitter
local function jitter()

	if ui.get_int("Jitter") == 0 and enabled.jitter then
		enabled.jitter = false
		ui.set_int("Antiaim.yaw_offset", 0)
		ui.set_int("0Antiaim.base_angle", 1)
	end
	
	if ui.get_int("Jitter") == 0 or not engine.is_connected() then return end
	if ui.get_bool("Legit AA on E") and engine.get_active_key(0x45) then return end
	
	enabled.jitter = true
	
	local tickcount = {def = globalvars.get_tickcount() %2, exp = globalvars.get_tickcount() %3}
	local cur_tickcount = tickcount.def
	
	if ui.get_keybind_state(keybinds.double_tap) or ui.get_keybind_state(keybinds.hide_shots) or ui.get_keybind_state(keybinds.fakeduck) then cur_tickcount = tickcount.exp end
	if ui.get_int("0Antiaim.desync") ~= 0 then cur_tickcount = tickcount.exp end
	if ui.get_int("Antiaim.fake_lag_limit")%2 ~= 0 then cur_tickcount = tickcount.exp end
	if ui.get_int("Antiaim.fake_lag_limit")%2 == 0 and ui.get_int("0Antiaim.desync") ~= 0 then 
		if not ui.get_keybind_state(keybinds.double_tap) and not ui.get_keybind_state(keybinds.hide_shots) and not ui.get_keybind_state(keybinds.fakeduck) then 
			cur_tickcount = tickcount.def 
		end
	end
	
	local L = ui.get_int("Jitter Lenght") local type = ui.get_int("Jitter")
	
	if L > 0 then
		ui.set_int("0Antiaim.base_angle", 0)
	end
	
	if type == 1 then if cur_tickcount == 0 then ui.set_int("Antiaim.yaw_offset", 0) else ui.set_int("Antiaim.yaw_offset", L) end end
	if type == 2 then if cur_tickcount == 0 then ui.set_int("Antiaim.yaw_offset", -L) else ui.set_int("Antiaim.yaw_offset", L) end end
end
--- #endregion


--- #region: veiwmodel in scope
local function viewmodel()

	if not ui.get_bool("Viewmodel in scope") and enabled.viewmodel then
		enabled.viewmodel = false
		console.set_int("fov_cs_debug", 0)
	end
	
	if not ui.get_bool("Viewmodel in scope") or not player_alive() then return end
	enabled.viewmodel = true
	console.set_int("fov_cs_debug", 90)
end
--- #endregion


--- #region: fake flick
local function fakeflick()

	if not ui.get_bool("Fake Flick") and enabled.flick then
		enabled.flick = false
		ui.set_int("Antiaim.yaw_offset", 0)
		ui.set_int("0Antiaim.base_angle", 1)
	end
	
	if not ui.get_bool("Fake Flick") or not player_alive() then return end
	
	enabled.flick = true
	local tickcount = globalvars.get_tickcount() %(30-(ui.get_int("Flick Speed")*2))
	
	if tickcount == 0 then
		ui.set_int("0Antiaim.base_angle", 0)
		if inverter() then 
			ui.set_int("Antiaim.yaw_offset", 90)
		else 
			ui.set_int("Antiaim.yaw_offset", -90)
		end 
	elseif tickcount == 2 then
		ui.set_int("0Antiaim.base_angle", 1)
		ui.set_int("Antiaim.yaw_offset", 0) 
	end
	
end
--- #endregion


--- #region: kill say
kill = function(event)
    local player = entitylist.get_local_player()
    local attacker = entitylist.get_player_by_index(engine.get_player_for_user_id(event:get_int("attacker")))
    
    if attacker ~= player then return end
	if entitylist.get_player_by_index(engine.get_player_for_user_id(event:get_int("userid"))) == player then return end
	
	if ui.get_bool("Kill Say") then
		console.execute_client_cmd("say " .. killsay[math.random(1,10)])
	end
end
--- #endregion


--- #region: indicators
local function indicators()

	if not lua_started then
		local color = nil
		local color2 = nil
		local exploit = nil
		local mindamage = nil
		local forcebody = nil
		local autopeek = nil
	end

	if not ui.get_bool("Indicators") or not engine.is_connected() or not player_alive() then return end
	
	local y = ui.get_int("Ind y")
	
	exploit = GetExploit()
	
	if ui.get_keybind_state(keybinds.damage_override) then mindamage = "Damage Override" elseif mindamage ~= nil then mindamage = nil end
	if ui.get_keybind_state(keybinds.body_aim) then forcebody = "Force Body" elseif forcebody ~= nil then forcebody = nil end
	if ui.get_keybind_state(keybinds.automatic_peek) then autopeek = "Autopeek" elseif autopeek ~= nil then autopeek = nil end
	
	if antiaim.get_body_yaw() > 0 then
		color = color.new(255, 255, 255, 255)
		color2 = ui.get_color("ind color")
	elseif antiaim.get_body_yaw() < 0 then
		color = ui.get_color("ind color")
		color2 = color.new(255, 255, 255, 255)
	end
	
	render.text(verdana, screen().x/2 + center_text(verdana, "cu", "x") - center_text(verdana, "te", "x"), screen().y/2+y, color, "te", true, false)
	render.text(verdana, screen().x/2 - center_text(verdana, "te", "x") - center_text(verdana, "cu", "x"), screen().y/2+y, color2, "cu", true, false)
	
	if exploit ~= "None" then render.text(verdana, screen().x/2 - center_text(verdana,exploit,"x"), screen().y/2+y+15, ui.get_color("ind color"), exploit, true, false) end
	render.text(verdana, screen().x/2 - center_text(verdana,mindamage,"x"), screen().y/2+y+15+center_text(verdana,exploit,"y"), ui.get_color("ind color"), mindamage, true, false)
	render.text(verdana, screen().x/2 - center_text(verdana,forcebody,"x"), screen().y/2+y+15+center_text(verdana,exploit,"y")+center_text(verdana,mindamage,"y"), ui.get_color("ind color"), forcebody, true, false)
	render.text(verdana, screen().x/2 - center_text(verdana,autopeek,"x"), screen().y/2+y+15+center_text(verdana,exploit,"y")+center_text(verdana,mindamage,"y")+center_text(verdana,forcebody,"y"), ui.get_color("ind color"), autopeek, true, false)
	
end
--- #endregion

--- #region: Hohlo panel
function holo_text(text, pos)
	local text_color = color.new(255,255,255)
	if ui.get_bool("Custom Text Color") then text_color = ui.get_color("HOLOText color") end
	render.text(small_verdana, anim_muz_x+5+ui.get_int("Holo Distance"), anim_muz_y-pos, text_color, text)
end

local function holo_panel()

	if not lua_started then
		local anim_muz_x = nil
		local anim_muz_y = nil
		local side = nil
		local background_c = nil
	end
	
	if not ui.get_bool("Holo Panel") or not player_alive() then return end
	
	local player = entitylist.get_local_player()
	local playerWeapon = entitylist.get_weapon_by_player(player)
	local IsNonAim = weapon.is_non_aim(playerWeapon)
	local dist = ui.get_int("Holo Distance")
	
	local muz_pos = {
		x = render.world_to_screen(player:get_muzzle_pos()).x,
		y = render.world_to_screen(player:get_muzzle_pos()).y,
	}
	
	if IsNonAim then
		muz_pos.x = screen().x/2
		muz_pos.y = screen().y/2
	end
	
	if ui.get_keybind_state(keybinds.thirdperson) then 
		muz_pos.x = render.world_to_screen(player:get_player_hitbox_pos( 5 ) ).x
		muz_pos.y = render.world_to_screen(player:get_player_hitbox_pos( 5 ) ).y
	end
	
	if muz_pos.x > screen().x then muz_pos.x = screen().x/2 end
	if muz_pos.y > screen().y then muz_pos.y = screen().y/2 end
	
	if muz_pos.x < 0 then muz_pos.x = screen().x/2 end
	if muz_pos.y < 0 then muz_pos.y = screen().y/2 end
	
	local view_plus = engine.get_view_angles().y/1.5
	if view_plus < 0 then view_plus = view_plus * - 1 end
	anim_muz_x = animate.lerp(anim_muz_x, muz_pos.x+50+engine.get_view_angles().x/5+view_plus, 0.025)
	anim_muz_y = animate.lerp(anim_muz_y, muz_pos.y-120+engine.get_view_angles().x/1.5, 0.025)
	
	if not inverter() then side = "Right" elseif inverter() then side = "Left" end
	if ui.get_int("0Antiaim.desync") == 2 then side = "Jitter" end
	if ui.get_int("0Antiaim.desync") == 0 then side = "None" end
	
	if ui.get_bool("Custom Backrgound Color") then background_c = ui.get_color("Background color") else background_c = color.new(10,10,10,150) end
	local speed = math.floor(player:get_velocity():length_2d())
	if GetState() == "Standing" then speed = 0 end
	local ext_fake = ui.get_int("Desync Delta")
	if inverter() then ext_fake = ext_fake * -1 end
	if not ui.get_bool("Extended Desync") then ext_fake = 0 end
	
	
	render.line(muz_pos.x, muz_pos.y, anim_muz_x+dist, anim_muz_y-2, ui.get_color("holopanel color"))
	render.rect_filled(anim_muz_x+dist, anim_muz_y-100, 200, 100, background_c)
	render.blur(anim_muz_x+dist, anim_muz_y-100, 200, 100, background_c:a())
	render.rect(anim_muz_x+dist, anim_muz_y-100, 200, 100, ui.get_color("holopanel color"))
		
	holo_text("Fake: " .. (antiaim.get_body_yaw()/2)+ext_fake/2 .. "°", 95)
	holo_text("State: " .. GetState(), 80)
	holo_text("Exploit: " .. GetExploit(), 65)
	holo_text("Side: " .. side, 50)
	holo_text("Anti-Aim: " .. GetAAState(), 35)
	holo_text("Velocity: " .. speed .. " units", 20)
end
--- #endregion


--- #region: chat disable
local function chat_disabler()
	
	if not ui.get_bool("Disable chat") and enabled.chatdis then
		enabled.chatdis = false
		console.set_int("cl_chatfilters", 63)
		cheat.popup("[Cute.lua] Info", "Chat Enabled")
	end
	
	if not ui.get_bool("Disable chat") then return end
	
	enabled.chatdis = true
	if console.get_int("cl_chatfilters") ~= 0 then cheat.popup("[Cute.lua] Info", "Chat Disabled") console.set_int("cl_chatfilters", 0) end
end
--- #endregion


--- #region: Freestand on Peek
local function FreestandPeek()

	if not lua_started then
		local Peeked = nil
	end
	
	if not ui.get_bool("Freestand on Peek") and enabled.freestandpeek then
		enabled.freestandpeek = false
		ui.set_int("0Antiaim.base_angle", 1)
		ui.set_bool("Antiaim.freestand", false)
	end
	
	if not ui.get_bool("Freestand on Peek") then return end
	
	enabled.freestandpeek = true
	local AutoPeek = ui.get_keybind_state(keybinds.automatic_peek)
	
	if AutoPeek then
		Peeked = true
		ui.set_int("0Antiaim.base_angle", 0)
		ui.set_bool("Antiaim.freestand", true)
	elseif not AutoPeek and Peeked then
		Peeked = false
		ui.set_int("0Antiaim.base_angle", 1)
		ui.set_bool("Antiaim.freestand", false)
	end
end
--- #endregion


--- #region: clantag
local labels = {
		"",
		"#",
		"#$",
		"$C",
		"$Cu",
		"%Cut",
		"%*@#*",
		"Cute",
		"Cute.l",
		"Cute.l@",
		"Cute.lu",
		"Cute.lua",
		"Cute.lua",
		"Cute.lua",
		"Cute.lua",
		"Cute.lua",
		"Cute.lua",
		"Cute.lu%",
		"Cute.l$",
		"Cute.@",
		"Cute.",
		"Cute*",
		"*@%#?",
		"Cut$",
		"Cu#",
		"C%",
		"#$",
		"#",
		"",
}
local time = {
	first = 0, second = 0
}

local function clantag()
	
	if not ui.get_bool("Clantag") and enabled.clantag then
		enabled.clantag = false
		engine.set_clantag("")
	end
	if not ui.get_bool("Clantag") or not engine.is_connected() then return end
	
	enabled.clantag = true
	local tickcount = globalvars.get_tickcount()

    if time.first < tickcount then
		time.second = time.second + 1
        if time.second > #labels + 1 then
            time.second = 0
        end

        engine.set_clantag(labels[time.second])
        time.first = tickcount + 12
    end
end
--- #endregion


--- #region: aa presets
function lean(num)
	local modifier = 0 
	if ui.get_int("Antiaim.fake_lag_limit") ~= 2 then modifier = -15 end 
	ui.set_int("0Antiaim.body_lean", num+modifier) 
	ui.set_int("0Antiaim.inverted_body_lean", num+modifier)
end

function desync(num) 
	local modifier = 0
	ui.set_int("0Antiaim.desync_range", num+modifier) 
	ui.set_int("0Antiaim.inverted_desync_range",num+modifier) 
end

local function presets()


	if ui.get_int("AA Preset") == 0 and enabled.presets then
		enabled.presets = false
		set_aa.lean(0,0)
		set_aa.desync(1,60,60)
		set_aa.yaw(0,nil,nil)
	end
	if ui.get_int("AA Preset") == 0 then return end
	if ui.get_bool("Off All AA on E") and engine.get_active_key(0x45) and not isDefusing and not isGrabbing then return end
	
	local type = ui.get_int("AA Preset")
	enabled.presets = true
	
	if type == 1 then
		set_aa.lean(60,60)
		set_aa.desync(2,60,60)
		set_aa.yaw(0,nil,nil)
	end
	
	if type == 2 then
		set_aa.lean(0,0)
		set_aa.desync(2,60,60)
		set_aa.yaw(2,75,9)
		ui.set_int("Antiaim.fake_lag_limit", math.random(9,11))
	end
	
	if type == 3 then
		local player = entitylist.get_local_player()
		local velocity = player:get_velocity()
		local speed = math.ceil(velocity:length_2d())
		local air = player:get_prop_bool('CBasePlayer', 'm_hGroundEntity')
		local weapon = entitylist.get_weapon_by_player( player )
		local slowwalking = ui.get_keybind_state(keybinds.slowwalk)
		local tickcount = globalvars.get_tickcount() %10
	
		if tickcount == 5 then ui.set_int("0Antiaim.desync", 2) end
	
		if not air then
			if weapon:get_name() ~= "KNIFE" and not slowwalking then
				if speed < 20 then lean(50) desync(60) else if tickcount == 5 then lean(math.random(30,60)) end desync(60) end
			elseif speed > 20 then desync(60) lean(100) 
				else lean(50) desync(60) end
		else desync(60) lean(30) end
		if speed < 120 and speed > 20 and player:is_scoped() then
			lean(60) desync(60)
		end
		if slowwalking then
			lean(45) desync(60)
		end
	end
	
	if type == 4 then
		set_aa.desync(0,nil,nil)
		set_aa.yaw(0,nil,nil)
		cheat.notify("Sosu sqwat'y >:)")
	end
	
end
--- #endregion


--- #region: lagpeek
peek = false
pre_fakelag = nil
local function lagpeek()

	if not ui.get_bool("LagPeek") then return end

	local IsPeek = antiaim.is_peeking()
	local peek_fl = ui.get_int("Fakelag on peek")
	
	if IsPeek then
		if ui.get_int("Antiaim.fake_lag_limit") ~= peek_fl then pre_fakelag = ui.get_int("Antiaim.fake_lag_limit") end
		ui.set_int("Antiaim.fake_lag_limit", peek_fl)
		peek = true
	end

end

var = 0
local function after_lagpeek()

	if not ui.get_bool("LagPeek") and enabled.lagpeek then 
		enabled.lagpeek = false
		ui.set_int("Antiaim.fake_lag_limit", pre_fakelag)
	end
	
	if not ui.get_bool("LagPeek") then return end
	enabled.lagpeek = true
	
	local IsPeek = antiaim.is_peeking()
	local delay = ui.get_int("Delay")

	if not IsPeek then
		if peek then
			if var >= delay*2 then
				ui.set_int("Antiaim.fake_lag_limit", pre_fakelag)
				var = 0
				peek = false
			else
				var = var + 1
			end
		end
	end
	
end
--- #endregion


--- #region: callbacks
cheat.RegisterCallback("on_paint", function()
	snapline(); nimb(); viewmodel(); clantag();
	if engine.get_active_key(0x09) then return end
	holo_panel(); indicators(); inv_arrows();
end)

cheat.RegisterCallback("on_createmove", function()
	nightmode_fix(); legit_aa(); jitter(); fakeflick(); FreestandPeek(); chat_disabler(); presets(); after_lagpeek();
end)
cheat.RegisterCallback("after_prediction", function()
	ext_desync(); ext_desync_fix(); lagpeek();
end)
cheat.RegisterCallback("on_framestage", function()
	legbreaker();
end)
events.register_event("player_death", kill)

function ul() 
	if enabled.legit then console.execute_client_cmd("bind e +use") console.execute_client_cmd("-use") end
	if enabled.extended then cmd.set_viewangles("z", 0) end
	if enabled.viewmodel then console.set_int("fov_cs_debug", 0) end
	if enabled.freestandpeek then ui.set_int("0Antiaim.base_angle", 1) ui.set_bool("Antiaim.freestand", false) end
	if enabled.chatdis then console.set_int("cl_chatfilters", 63) end
	if enabled.presets then set_aa.lean(0,0) set_aa.desync(1,60,60) set_aa.yaw(0,nil,nil) end
	if enabled.clantag then engine.set_clantag("") end
	if enabled.lagpeek then ui.set_int("Antiaim.fake_lag_limit", pre_fakelag) end
	ui.set_int("0Antiaim.base_angle", 1)
	ui.set_int("Antiaim.yaw_offset", 0)
end
cheat.RegisterCallback("on_unload", ul)
--- #endregion

--- #region: end
lua_started = true
cheat.popup("[Cute.lua] Info", "Lua Started")
--- #endregion