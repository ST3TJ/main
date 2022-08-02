local Logger = {
    ["Log"] = function (text)
        local Time = globalvars.get_time()
        return file.append("C:\\tornado\\debug.log", string.format("[%s]%s", Time, text))
    end,
    ["Create_Dir"] = function (path)
        return file.create_dir(path)
    end
}

function paint(fn) return cheat.RegisterCallback("on_paint", fn) end
function createmove(fn) return cheat.RegisterCallback("on_createmove", fn) end
function framenet(fn) return cheat.RegisterCallback("on_frame_net", fn) end
function afterpred(fn) return cheat.RegisterCallback("after_prediction", fn) end
function shot(fn) return cheat.RegisterCallback("on_shot", fn) end
function ui.add_tab(text)
    return ui.add_label(text .. "\n ")
end
function ui.add_subtab(text)
    return ui.add_label(">" .. text)
end
function ui.add_boxcolor(text)
    return ui.add_checkbox(text),ui.add_colorpicker(text .. " color")
end
local Color = {}
function Color:Unpack(color)
    return color:r(), color:g(), color:b(), color:a()
end
local Antiaim = {}
function Antiaim:IsManual()
    if ui.get_keybind_state(keybinds.manual_right) or ui.get_keybind_state(keybinds.manual_left) then
        return true
    end
    return false
end
function player:GetState()
    local LocalPlayer = entitylist.get_local_player()
    local m_fFlags = LocalPlayer:get_prop_int("CBasePlayer", "m_fFlags")

    if m_fFlags == 256 then
        return "flying"
    elseif m_fFlags == 263 then
        return "crouching"
    elseif m_fFlags == 262 then
        return "crouches in flight"
    end
    
    if LocalPlayer:get_velocity():length_2d() > 5 and not ui.get_keybind_state(keybinds.slowwalk) then
        return "running"
    end
    if ui.get_keybind_state(keybinds.slowwalk) then
        return "slow walking"
    end

    return "standing"
end

Logger.Create_Dir("C:\\tornado")
Logger.Log("script loaded")

local Font = {
    ["Indicator"] = {
        ["14"] = render.setup_font("C:/Windows/Fonts/smallest_pixel-7.ttf", 14),
    },
    ["Misc"] = {
        ["14"] = render.setup_font("Tahoma", 14, fontflags.bold)
    },
    ["Holopanel"] = {
        ["12"] = render.setup_font("Verdana", 12, fontflags.bold)
    },
    ["Pets"] = render.setup_font("Verdana", 14, fontflags.bold)

}
--[[
local resModeToString = {
    [0] = "PREVIOUS_GFY",
    [1] = "ZERO",
    [2] = "FIRST",
    [3] = "SECOND",
    [4] = "LOW_FIRST",
    [5] = "LOW_SECOND"
}
]]
local Ragebot = {}
function CursorInBounds(x, y, w, h)
    local Cursor = {
        x = engine.get_cursor_position().x,
        y = engine.get_cursor_position().y
    }

    if Cursor.x >= x and Cursor.y >= y and Cursor.x <= w and Cursor.y <= h then
        return true
    end

    return false
end
local Pet = {
    Mai = render.setup_texture("C:/tornado/assets/mai.png"),
}
local Animation = {
    menu = 0,
    indicators = 0
}
ui.add_label("[!] Function on testing")
ui.add_tab("Ragebot")
--ui.add_combobox("Resolver type", resModeToString)
--[[
ui.add_subtab("Doubletap")
ui.add_checkbox("[!] Defensive")
ui.add_sliderint("-->Predict ticks", 6, 16) -- 10
ui.add_sliderint("-->Charge delay", 10, 200) -- 66
]]
ui.add_subtab("Main")
ui.add_checkbox("[!] Hp < ? then")
ui.add_sliderint("-->Hp value", 0, 100) -- 50
ui.add_combobox("-->Then force", {"Safepoint", "Baim"})
ui.add_tab("Anti-aim")
ui.add_combobox("Preset:", {"None", "Deathmatch Slayer", "Static High"})
ui.add_combobox("Yaw base", {"Backwards", "At Targets"})
ui.add_tab("Visuals")
ui.add_subtab("In-game")
ui.add_boxcolor("Indicators")
ui.add_checkbox("State panel")
ui.add_checkbox("Holopanel")
ui.add_checkbox("Pet")
ui.add_subtab("Other")
ui.add_checkbox("Party mode")
--ui.add_checkbox("Console filter")
ui.add_tab("Miscallenous")
ui.add_checkbox("Hitsound")
ui.add_sliderfloat("-->Volume", 0.1, 1.0)
function Ragebot:IsPeeking()
    local Player = entitylist.get_local_player()
    local Weapon = entitylist.get_weapon_by_player(Player)
    local IsNonAim = Weapon:is_non_aim()
    local IsPeek = antiaim.is_peeking()

    if not IsNonAim and IsPeek then

        return true
    end

    return false
end
function player:IsScoped()
    local Weapon = entitylist.get_weapon_by_player(self)
    local IsNonAim = Weapon:is_non_aim()
    local IsScoped = not IsNonAim and self:is_scoped()
    if IsScoped then
        return true
    end

    return false
end
local Visuals = {}
local Misc = {}
function Visuals:PartyMode()
    local On = ui.get_bool("Party mode")
    console.set_int("sv_party_mode",On and 1 or 0)
end
--[[
function Visuals:ConsoleFilter()
    local On = ui.get_bool("Console filter")
    console.set_int("con_filter_enable",On and 1 or 0)
    console.set_string("con_filter_text",On and "tornadoluabest" or "")
    console.set_string("con_filter_text_out", On and "tornadoluabested" or "")
end
]]

function Visuals:Indicators()
    local On = ui.get_bool("Indicators")
    local LocalPlayer = entitylist.get_local_player()

    if not On then
        return
    end

    if not LocalPlayer:is_alive() then
        return
    end
    
    local Screen = {
        x = engine.get_screen_width(),
        y = engine.get_screen_height()
    }
    local Active = {
        Doubletap = ui.get_keybind_state(keybinds.double_tap),
        Hideshots = ui.get_keybind_state(keybinds.hide_shots),
        Mindmg = ui.get_keybind_state(keybinds.damage_override),
        Body = ui.get_keybind_state(keybinds.body_aim),
        Safepoints = ui.get_keybind_state(keybinds.safe_points),
        Flipdesync = ui.get_keybind_state(keybinds.flip_desync),
        Peek = ui.get_keybind_state(keybinds.automatic_peek),
    }
    local Offset = 30
    Animation.indicators = animate.lerp(Animation.indicators, LocalPlayer:IsScoped() and 35 or 0, 0.05)

    if not Antiaim:IsManual() then
        render.text(Font.Indicator["14"], Screen.x/2 + render.get_text_width(Font.Indicator["14"], "tor")/2 - render.get_text_width(Font.Indicator["14"], "nado")/2 + Animation.indicators, Screen.y/2 + Offset, color.new(255, 255, 255, 255), not Active.Flipdesync and "nado", false, true)
        render.text(Font.Indicator["14"], Screen.x/2 - render.get_text_width(Font.Indicator["14"], "nado")/2 - render.get_text_width(Font.Indicator["14"], "tor")/2 + Animation.indicators, Screen.y/2 + Offset, color.new(Color:Unpack(ui.get_color("Indicators color"))), not Active.Flipdesync and "tor", false, true)
        render.text(Font.Indicator["14"], Screen.x/2 + render.get_text_width(Font.Indicator["14"], "tor")/2 - render.get_text_width(Font.Indicator["14"], "nado")/2 + Animation.indicators, Screen.y/2 + Offset, color.new(Color:Unpack(ui.get_color("Indicators color"))), Active.Flipdesync and "nado", false, true)
        render.text(Font.Indicator["14"], Screen.x/2 - render.get_text_width(Font.Indicator["14"], "nado")/2 - render.get_text_width(Font.Indicator["14"], "tor")/2 + Animation.indicators, Screen.y/2 + Offset, color.new(255, 255, 255, 255), Active.Flipdesync and "tor", false, true)
        Offset = Offset + 10
    else
        render.text(Font.Indicator["14"], Screen.x/2 - render.get_text_width(Font.Indicator["14"], "manual aa")/2 + Animation.indicators, Screen.y/2+Offset, color.new(Color:Unpack(ui.get_color("Indicators color"))), "manual aa", false, true)
        Offset = Offset + 10
    end
    render.text(Font.Indicator["14"], Screen.x/2 - render.get_text_width(Font.Indicator["14"], "doubletap")/2 + Animation.indicators, Screen.y/2+Offset, color.new(101, 255, 73, 255), Active.Doubletap and "doubletap", false, true)
    Offset = Active.Doubletap and Offset + 10 or Offset
    render.text(Font.Indicator["14"], Screen.x/2 - render.get_text_width(Font.Indicator["14"], "hideshots")/2 + Animation.indicators, Screen.y/2+Offset, color.new(101, 255, 73, 255), Active.Hideshots and "hideshots", false, true)
    Offset = Active.Hideshots and Offset + 10 or Offset
    render.text(Font.Indicator["14"], Screen.x/2 - render.get_text_width(Font.Indicator["14"], "damage")/2 + Animation.indicators, Screen.y/2+Offset, color.new(255, 255, 255, 255), Active.Mindmg and "damage", false, true)
    Offset = Active.Mindmg and Offset + 10 or Offset
    render.text(Font.Indicator["14"], Screen.x/2 - render.get_text_width(Font.Indicator["14"], "body")/2 + Animation.indicators, Screen.y/2+Offset, color.new(255, 255, 255, 255), Active.Body and "body", false, true)
    Offset = Active.Body and Offset + 10 or Offset
end
function Antiaim:Set(tab, range, inverted_range, subtab, pitch, modifier)
    if tab == "General" then
        ui.set_int("0Antiaim.pitch", pitch)
        ui.set_int("0Antiaim.yaw", modifier)
        ui.set_int("Antiaim.yaw_offset", range)
        ui.set_int("0Antiaim.range", inverted_range)
    end
    if tab == "Desync" then
        ui.set_int("0Antiaim.desync", subtab)
        ui.set_int("0Antiaim.desync_range", range)
        ui.set_int("0Antiaim.inverted_desync_range", inverted_range)
    end
    if tab == "Lean" then
        ui.set_int("0Antiaim.body_lean", range)
        ui.set_int("0Antiaim.inverted_body_lean", inverted_range)
    end
end
function Antiaim:Preset()
    local CurrentPreset = ui.get_int("Preset:")
    local YawBase = ui.get_int("Yaw base")

    if CurrentPreset == 0 then
        return
    else
        ui.set_bool("Antiaim.enable", true)
        ui.set_int("0Antiaim.base_angle", YawBase)
    end

    if CurrentPreset == 1 then
        Antiaim:Set("General", -1, 0, nil, 1, 0)
        Antiaim:Set("Desync", 57, 59, 1, nil, nil)
        Antiaim:Set("Lean", 58, 73, nil, nil, nil)
    end
end
function Visuals:StatePanel()
    local LocalPlayer = entitylist.get_local_player()
    local On = ui.get_bool("State panel")

    if not LocalPlayer:is_alive() then
        return
    end

    if not On then
        return
    end
    local Screen = {
        x = engine.get_screen_width(),
        y = engine.get_screen_height()
    }
    local Offset = 80
    local User = globalvars.get_winuser()
    local Desync = antiaim.get_body_yaw()
    local FlipState = ui.get_keybind_state(keybinds.flip_desync) and "R" or "L"
    render.blur(Screen.x / 50 - 10, Screen.y / 2 + 70, 180, 70, 80)
    render.rect_filled_rounded(Screen.x / 50 - 10, Screen.y / 2 + 70, 180, 70, 40, 5, color.new(0, 0, 0, 80))
    render.rect_rounded(Screen.x /  50 - 10, Screen.y / 2 + 70, 180, 70, color.new(Color:Unpack(ui.get_color("Indicators color"))), 5)
    render.text(Font.Misc["14"], Screen.x / 50 , Screen.y / 2 + Offset, color.new(255, 255, 255, 255), "tornado.lua [alpha]", true, false)
    Offset = Offset + 12
    render.text(Font.Misc["14"], Screen.x / 50 , Screen.y / 2 + Offset, color.new(255, 255, 255, 255), "user: " .. User, true, false)
    Offset = Offset + 12
    render.text(Font.Misc["14"], Screen.x / 50, Screen.y / 2 + Offset, color.new(255, 255, 255, 255), "state: " .. player:GetState(), true, false)
    Offset = Offset + 12
    render.text(Font.Misc["14"], Screen.x / 50, Screen.y / 2 + Offset, color.new(255, 255, 255, 255), string.format("desync angle: %s° / %s", Desync, FlipState), true, false)
    
end
--[[
function Ragebot:Defensive()
    local On = ui.get_bool("[!] Defensive")

    local Player = entitylist.get_local_player()
    local Weapon = entitylist.get_weapon_by_player(Player)
    local IsNonAim = Weapon:is_non_aim()
    local IsPeek = antiaim.is_peeking()

    if not On then
        return
    end


    if not ui.get_keybind_state(keybinds.double_tap) then
        return
    end
    if not ui.get_keybind_state(keybinds.automatic_peek) then
        return 
    end

    if not IsNonAim and IsPeek then
        cmd.set_send_packet(true)
        console.set_int("sv_maxusrcmdprocessticks", 18)
        console.set_int("cl_smooth", ui.get_int("-->Predict ticks"))
        console.set_int("cl_interpolate", ui.get_int("-->Charge delay") / 100)

    end

end
]]
function Ragebot:Hpthen()
    local On = ui.get_bool("[!] Hp < ? then")
    local Type = ui.get_int("-->Then force")
    local Value = ui.get_int("-->Hp value")

    if not On then 
        return 
    end

    local Enemy = entitylist.get_players(true)

    for i = 1, #Enemy do
        local Enemies = Enemy[i]

        if Enemies:get_health() < Value then
            if Type == 0 then
                ui.set_keybind_state(keybinds.safe_points, true)
            elseif Type == 1 then
                ui.set_keybind_state(keybinds.body_aim, true)
            end
        else
            ui.set_keybind_state(keybinds.safe_points, false)
            ui.set_keybind_state(keybinds.body_aim, false)
        end
    end
end
function Visuals:Holopanel()
    local On = ui.get_bool("Holopanel")
    if not On then return end
    local Player = entitylist.get_local_player()
    if not Player:is_alive() then return end
    local Weapon = entitylist.get_weapon_by_player(Player)
    local IsNonAim = weapon.is_non_aim(Weapon)
    local BodyYaw = antiaim.get_body_yaw()
    local Desync = BodyYaw
    local Side = ui.get_keybind_state(keybinds.flip_desync) and "RIGHT" or "LEFT"
    local Exploit = "None"

    if BodyYaw < 0 then
        Desync = BodyYaw * -6
    else
        Desync = BodyYaw * 6
    end
    if ui.get_keybind_state(keybinds.double_tap) then
        Exploit = "Double Tap"
    elseif ui.get_keybind_state(keybinds.hide_shots) then
        Exploit = "Hide Shots"
    else
        Exploit = Exploit
    end

    local MuzzlePos = Player:get_muzzle_pos()
    local Screen = {
        x = engine.get_screen_width(),
        y = engine.get_screen_height()
    }

    local ScreenMuzzle = render.world_to_screen(MuzzlePos)
    
    if IsNonAim then return end

    local Text = {
        Main = "ANTI-AIMBOT DEBUG",
        Desync = string.format("DESYNC: %s°", BodyYaw),
        Side = string.format("SIDE: %s", Side),
        Exploit = string.format("EXPLOIT: %s", Exploit)
    }
    local Offset
    if not ui.get_keybind_state(keybinds.thirdperson) then
        render.circle_filled(ScreenMuzzle.x, ScreenMuzzle.y, 180, 5, color.new(255, 255, 255, 255))
        render.line(ScreenMuzzle.x, ScreenMuzzle.y, ScreenMuzzle.x - 65, ScreenMuzzle.y - 71, color.new(255, 255, 255, 255))
        render.rect_filled_rounded(ScreenMuzzle.x - 70, ScreenMuzzle.y - 170, 200, 100, 10, 5, color.new(0, 0, 0, 120))
        render.text(Font.Holopanel["12"], ScreenMuzzle.x - 30, ScreenMuzzle.y - 170, color.new(255, 255, 255, 255), Text.Main, true, false)
        render.text(Font.Holopanel["12"], ScreenMuzzle.x - 60, ScreenMuzzle.y - 150, color.new(255, 255, 255, 255), Text.Desync, true, false)
        render.arc(ScreenMuzzle.x + 45, ScreenMuzzle.y - 143, 3, 5, -90, Desync, color.new(Color:Unpack(ui.get_color("Indicators color"))))
        render.text(Font.Holopanel["12"], ScreenMuzzle.x - 60, ScreenMuzzle.y - 130, color.new(255, 255, 255, 255), Text.Side, true, false)
        render.text(Font.Holopanel["12"], ScreenMuzzle.x - 60, ScreenMuzzle.y - 110, color.new(0, 255, 0, 255), Text.Exploit, true, false)
    end
end
function Visuals:Pet()
    local On = ui.get_bool("Pet")
    if not On then return end

    local Player = entitylist.get_local_player()
    if not Player:is_alive() then return end

    local BodyPos = entitylist.get_local_player():get_player_hitbox_pos(7)
    local ScreenBodyPos = render.world_to_screen(BodyPos)

    local Menu = {
        IsOpen = function ()
            return globalvars.is_open_menu()
        end,
        x = globalvars.get_menu().x,
        y = globalvars.get_menu().y,
        w = globalvars.get_menu().w,
        h = globalvars.get_menu().h,
    }
    if Menu.IsOpen() then
        Animation.menu = animate.lerp(Animation.menu, 110, 0.05)
    else
        Animation.menu = animate.lerp(Animation.menu, 0, 0.12)
    end
    if ui.get_keybind_state(keybinds.thirdperson) and not Menu.IsOpen() then 
        render.text(Font.Pets, ScreenBodyPos.x + 525, ScreenBodyPos.y, color.new(255, 255, 255, 255), "Mai", true, false)
        render.image(Pet.Mai, ScreenBodyPos.x + 450, ScreenBodyPos.y + 50, 180, 250)
    end
    if Menu.IsOpen() then
        render.text(Font.Pets, Menu.x - Animation.menu , Menu.y , color.new(255, 255, 255, 255), "Mai", true, false)
        render.image(Pet.Mai, Menu.x - Animation.menu - 70, Menu.y + 40, 180, 250)
    end
end
createmove(function()
    Visuals:PartyMode()
    Ragebot:Hpthen()
end)
paint(function()
    Visuals:Indicators()
    Visuals:StatePanel()
    Visuals:Holopanel()
    Visuals:Pet()
end)
shot(function(shot_info)
    if not ui.get_bool("Hitsound") then
        return
    end
    if shot_info.result == "Hit" then
        console.execute_client_cmd(string.format("playvol rust_headshot %s", ui.get_float("-->Volume")))
    end
end)

afterpred(function()
    --Ragebot:Defensive()
end)


