-- Luanti Main Menu Redesign
-- Central API Definition & Subsystem Bootstrap

mainmenu = {}

DIR_DELIM = DIR_DELIM or "/"
local dir_delim = DIR_DELIM
local menupath = custom_menupath
if not menupath or menupath == "" then
	local src = debug.getinfo(1, "S").source
	if src and src:sub(1, 1) == "@" then
		menupath = src:sub(2):match("(.*/)")
	end
	if not menupath and core and core.get_mainmenu_path then
		menupath = core.get_mainmenu_path()
	end
	menupath = menupath or "."
	if menupath:sub(-1) == dir_delim or menupath:sub(-1) == "/" then
		menupath = menupath:sub(1, -2)
	end
end
custom_menupath = custom_menupath or menupath

-- Load Core Subsystems
mainmenu.theme      = dofile(menupath .. dir_delim .. "theme.lua")
mainmenu.state      = dofile(menupath .. dir_delim .. "state.lua")
mainmenu.dispatcher = dofile(menupath .. dir_delim .. "dispatcher.lua")
mainmenu.view       = dofile(menupath .. dir_delim .. "view.lua")

-- UI Element instance registered with engine's ui.lua
mainmenu.ui_element = nil

--- Synchronizes and restores the active game theme and header banner
-- Ensures the selected game's header image/title is visible in the main menu at all times
-- @param force boolean Optional flag to force re-applying even if game ID matches
function mainmenu.sync_game_theme(force)
	if mainmenu.ui_element and mainmenu.ui_element.hidden then
		return
	end

	local game_id = (mainmenu.state and mainmenu.state.get and mainmenu.state.get("selected_game_id"))
		or (mainmenu.state and mainmenu.state.selected_game_id)
		or (core and core.settings and core.settings:get("menu_last_game"))

	local game = nil
	if pkgmgr and pkgmgr.find_by_gameid and game_id then
		game = pkgmgr.find_by_gameid(game_id)
	end
	if not game and pkgmgr and pkgmgr.games and #pkgmgr.games > 0 then
		local picked = 1
		if pkgmgr.games[1].id == "devtest" and #pkgmgr.games > 1 then
			picked = 2
		end
		game = pkgmgr.games[picked]
	end

	if game then
		if mainmenu.state and mainmenu.state.set then
			mainmenu.state.set("selected_game_id", game.id, true)
		end
		if menudata and menudata.worldlist and menudata.worldlist.set_filtercriteria then
			menudata.worldlist:set_filtercriteria(game.id)
		end
		if mm_game_theme and mm_game_theme.set_game then
			mm_game_theme.set_game(game, force)
		end
	end
end

--- Initializes the modern main menu system and state
function mainmenu.init()
	mainmenu.state.init()

	-- Subscribe state changes to trigger UI update
	mainmenu.state.subscribe(function()
		mainmenu.update()
	end)

	mainmenu.sync_game_theme(true)

	-- Pre-fetch public server list asynchronously
	serverlistmgr.sync()

	-- Create top-level FSTK UI element
	mainmenu.ui_element = {
		name = "maintab",
		type = "toplevel",
		hidden = false,
		data = {},

		get_formspec = function(self)
			if self.hidden then return "" end
			return mainmenu.get_formspec()
		end,

		handle_buttons = function(self, fields)
			if self.hidden then return false end
			return mainmenu.handle_buttons(fields)
		end,

		handle_events = function(self, event)
			if self.hidden then return false end
			return mainmenu.handle_events(event)
		end,

		show = function(self)
			self.hidden = false
			mainmenu.sync_game_theme(true)
			mainmenu.update()
		end,

		hide = function(self)
			self.hidden = true
		end,

		delete = function(self)
			ui.delete(self)
		end,

		set_parent = function(self, parent)
			self.parent = parent
		end
	}

	ui.add(mainmenu.ui_element)
	ui.set_default("maintab")

	-- Synchronize active game theme and header banner on startup
	mainmenu.sync_game_theme(true)
end

--- Generates the master Formspec Version 7 string
-- @return Formspec v7 string
function mainmenu.get_formspec()
	return mainmenu.view.render(mainmenu.state.get_all(), mainmenu.theme)
end

--- Handles button and field events from formspec
-- @param fields Table of formspec event fields
-- @return boolean true if event was handled
function mainmenu.handle_buttons(fields)
	local handled = mainmenu.dispatcher.dispatch(mainmenu.state, fields)
	if handled then
		mainmenu.update()
	end
	return handled
end

--- Sanitizes raw text inputs by stripping control characters and trimming whitespace.
-- @param text string The raw input string
-- @param max_len number Optional maximum string length (default: 256)
-- @param allow_newlines boolean Whether newline characters are allowed (default: false)
-- @return string Sanitized string
function mainmenu.sanitize_input(text, max_len, allow_newlines)
	if text == nil then return "" end
	local s = tostring(text)
	if allow_newlines then
		-- Strip non-printable control characters except \n and \r
		s = s:gsub("[%z\1-\9\11\12\14-\31\127]", "")
		-- Normalize \r\n to \n
		s = s:gsub("\r\n", "\n"):gsub("\r", "\n")
	else
		-- Strip all control characters including newlines
		s = s:gsub("[%z\1-\31\127]", "")
	end
	-- Trim leading and trailing whitespace
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	if max_len and max_len > 0 and #s > max_len then
		s = s:sub(1, max_len)
	end
	return s
end

--- Validates and sanitizes a player name according to Luanti engine requirements.
-- Allows [a-zA-Z0-9_-], clamped between 1 and 20 characters.
-- @param name string The raw player name
-- @return string Sanitized player name
function mainmenu.sanitize_player_name(name)
	if name == nil then return "" end
	local s = tostring(name)
	-- Strip control characters and whitespace
	s = s:gsub("[%z\1-\31\127%s]", "")
	-- Filter only allowed playername characters: alphanumeric, hyphen, underscore
	s = s:gsub("[^%w%_%-]", "")
	-- Clamp to max 20 characters (standard engine limit)
	if #s > 20 then
		s = s:sub(1, 20)
	end
	return s
end

--- Handles system events such as MenuQuit and Refresh
-- Implements hierarchical Escape navigation: steps back through sub-inspectors
-- and active search filters before prompting the quit confirmation dialog.
-- @param event Event name string
-- @return boolean true if handled
function mainmenu.handle_events(event)
	if event == "MenuQuit" then
		-- 1. Check if any child dialog is open in UI stack; if so, let dialog handler close it
		for name, elem in pairs(ui.childlist or {}) do
			if name ~= "maintab" and not elem.hidden then
				return false
			end
		end

		-- 2. Hierarchical navigation: Step back from sub-views or active filters before exit
		local active_tab = mainmenu.state.get("active_tab")

		if active_tab == "online" then
			-- If in a secondary inspector deck tab (players, engine, mods), step back to latency
			local info_tab = mainmenu.state.get("server_info_tab")
			if info_tab and info_tab ~= "latency" then
				mainmenu.state.set("server_info_tab", "latency")
				return true
			end

			-- If a server search query is active, clear the search filter
			local srv_query = mainmenu.state.get("server_search_query")
			if srv_query and srv_query ~= "" then
				mainmenu.state.set("server_search_query", "")
				return true
			end
		elseif active_tab == "local" then
			-- If a local world search query is active, clear it
			local world_query = mainmenu.state.get("world_search_query")
			if world_query and world_query ~= "" then
				mainmenu.state.set("world_search_query", "")
				return true
			end
		end

		-- 3. At clean root level: prompt with exit confirmation dialog or close
		local show_dialog = core.settings:get_bool("enable_esc_dialog", true)
		if not ui.childlist["dlg_exit"] and show_dialog then
			mainmenu.ui_element:hide()
			local dlg = create_exit_dialog()
			dlg:set_parent(mainmenu.ui_element)
			dlg:show()
		else
			core.close()
		end
		return true
	elseif event == "Refresh" then
		mainmenu.update()
		return true
	end
	return false
end

--- Refreshes the active menu formspec
function mainmenu.update()
	mainmenu.sync_game_theme()
	ui.update()
end

--- Shows the main menu UI
function mainmenu.show()
	if mainmenu.ui_element then
		mainmenu.ui_element:show()
	else
		mainmenu.sync_game_theme(true)
	end
end

--- Hides the main menu UI
function mainmenu.hide()
	if mainmenu.ui_element then
		mainmenu.ui_element:hide()
	end
end

return mainmenu
