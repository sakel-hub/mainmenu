-- Luanti
-- Copyright (C) 2014 sapier
-- SPDX-License-Identifier: LGPL-2.1-or-later

if INIT ~= "mainmenu" then
	return
end

MAIN_TAB_W = 15.5
MAIN_TAB_H = 7.1
TABHEADER_H = 0.85
GAMEBAR_H = 1.25
GAMEBAR_OFFSET_DESKTOP = 0.375
GAMEBAR_OFFSET_TOUCH = 0.15

local menupath = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
if not menupath or menupath == "" then
	menupath = core.get_mainmenu_path()
elseif menupath:sub(-1) == DIR_DELIM or menupath:sub(-1) == "/" then
	menupath = menupath:sub(1, -2)
end
custom_menupath = menupath
core.log("action", "[MainMenu] Custom main menu successfully loaded from: " .. menupath)
local basepath = core.get_builtin_path()
defaulttexturedir = core.get_texturepath_share() .. DIR_DELIM .. "base" ..
					DIR_DELIM .. "pack" .. DIR_DELIM

dofile(basepath .. "common" .. DIR_DELIM .. "menu.lua")
dofile(basepath .. "common" .. DIR_DELIM .. "filterlist.lua")
dofile(basepath .. "fstk" .. DIR_DELIM .. "buttonbar.lua")
dofile(basepath .. "fstk" .. DIR_DELIM .. "dialog.lua")
dofile(basepath .. "fstk" .. DIR_DELIM .. "tabview.lua")
dofile(basepath .. "fstk" .. DIR_DELIM .. "ui.lua")
dofile(menupath .. DIR_DELIM .. "async_event.lua")
dofile(menupath .. DIR_DELIM .. "common.lua")
dofile(menupath .. DIR_DELIM .. "serverlistmgr.lua")
dofile(menupath .. DIR_DELIM .. "game_theme.lua")
dofile(menupath .. DIR_DELIM .. "content" .. DIR_DELIM .. "init.lua")

dofile(menupath .. DIR_DELIM .. "dlg_config_world.lua")
dofile(basepath .. "common" .. DIR_DELIM .. "settings" .. DIR_DELIM .. "init.lua")

-- Non-destructive in-memory hook to inject "realtime" into the menu_theme enum setting dropdown
if settingtypes and settingtypes.parse_config_file then
	local orig_parse_config_file = settingtypes.parse_config_file
	settingtypes.parse_config_file = function(read_all, parse_mods)
		local settings = orig_parse_config_file(read_all, parse_mods)
		for _, setting in ipairs(settings) do
			if setting.name == "menu_theme" then
				setting.default = "realtime"
				setting.values = { "realtime", "light", "dark" }
				setting.option_labels = {
					realtime = "Real-time (Time of Day)",
					light = "Light",
					dark = "Dark",
				}
				break
			end
		end
		return settings
	end
end

if core.register_on_formspec_input then
	core.register_on_formspec_input(function(formname, fields)
		if formname == "__builtin:settings" and fields then
			if fields.menu_theme or fields.back or fields.quit then
				local c = mm_game_theme.resolve_colors()
				if c then
					core.set_clouds_color(c.clouds)
					core.set_sky_color(c.sky)
				end
			end
		end
	end)
end
dofile(menupath .. DIR_DELIM .. "dlg_confirm_exit.lua")
dofile(menupath .. DIR_DELIM .. "dlg_create_world.lua")
dofile(menupath .. DIR_DELIM .. "dlg_delete_content.lua")
dofile(menupath .. DIR_DELIM .. "dlg_delete_world.lua")
dofile(menupath .. DIR_DELIM .. "dlg_register.lua")
dofile(menupath .. DIR_DELIM .. "dlg_rename_modpack.lua")
dofile(menupath .. DIR_DELIM .. "dlg_version_info.lua")
dofile(menupath .. DIR_DELIM .. "dlg_reinstall_mtg.lua")
dofile(menupath .. DIR_DELIM .. "dlg_rebind_keys.lua")
dofile(menupath .. DIR_DELIM .. "dlg_clients_list.lua")
dofile(menupath .. DIR_DELIM .. "dlg_server_list_mods.lua")
dofile(menupath .. DIR_DELIM .. "dlg_direct_connect.lua")
dofile(menupath .. DIR_DELIM .. "dlg_resume_server.lua")

dofile(menupath .. DIR_DELIM .. "tab_local.lua")
dofile(menupath .. DIR_DELIM .. "api.lua")

local function init_globals()
	-- Permanent warning if on an unoptimized debug build
	if core.is_debug_build() then
		local set_topleft_text = core.set_topleft_text
		core.set_topleft_text = function(s)
			s = (s or "") .. "\n"
			s = s .. core.colorize("#f22", core.gettext("Debug build, expect worse performance"))
			set_topleft_text(s)
		end
	end

	-- Init gamedata
	gamedata.worldindex = 0

	menudata.worldlist = filterlist.create(
		core.get_worlds,
		compare_worlds,
		-- Unique id comparison function
		function(element, uid)
			return element.name == uid
		end,
		-- Filter function
		function(element, gameid)
			-- Keep in sync with the logic in pkgmgr.find_by_gameid
			local el_gameid = pkgmgr.normalize_game_id(element.gameid)
			if el_gameid == gameid then
				return true
			end
			local game = pkgmgr.find_by_gameid(el_gameid)
			if (not game or game.id ~= el_gameid)
					and pkgmgr.find_by_gameid(gameid).aliases[el_gameid] then
				return true
			end
			return false
		end
	)

	menudata.worldlist:add_sort_mechanism("alphabetic", sort_worlds_alphabetic)
	menudata.worldlist:set_sortmode("alphabetic")

	local cg_fn = rawget(_G, "current_game")
	local initial_game = (cg_fn and cg_fn())
		or (pkgmgr and pkgmgr.games and pkgmgr.games[1])
	if initial_game and menudata.worldlist.set_filtercriteria then
		menudata.worldlist:set_filtercriteria(initial_game.id)
	end

	mm_game_theme.init()
	mm_game_theme.set_engine() -- This is just a fallback.

	-- Initialize modern Formspec 7 main menu
	mainmenu.init()
	mainmenu.show()
	ui.update()

	-- Synchronous startup checks with parent chaining
	local parent = mainmenu.ui_element
	parent = migrate_keybindings(parent)
	check_reinstall_mtg(parent)

	-- Asynchronous new version check
	check_new_version()
end

assert(os.execute == nil)
init_globals()

