-- Luanti Main Menu Redesign
-- Centralized State Store

local state = {}

local current_state = {
	active_tab              = "games",
	selected_world_index    = 1,
	selected_game_id        = nil,
	world_search_query      = "",
	world_sort_col          = "name", -- "name", "game", "mg", "version", "mods", "size", "last_played"
	world_sort_dir          = "asc",  -- "asc", "desc"

	-- Online Server Browser State
	server_search_query     = "",
	server_filter           = "all", -- "all", "fav", "compat"
	selected_server         = nil,
	server_info_tab         = "latency", -- "latency", "players", "engine", "mods"
	server_sort_col         = "players", -- "ping", "players", "version", "mods", "flags", "name"
	server_sort_dir         = "desc",    -- "asc", "desc"

	-- Host / Gameplay Settings
	is_hosting              = false,
	server_announce         = false,
	creative_mode           = false,
	enable_damage           = true,
	player_name             = "",
	password                = "",
	bind_address            = "",
	port                    = "30000",

	-- ContentDB State
	content_filter          = "all",
	content_search_query    = "",
	content_view_mode       = "list", -- "list", "thumbs"
	content_thumbs_scroll   = 0,
	content_list_scroll     = 0,
	content_list_expanded   = {},
	expanded_modpacks       = {},
	selected_pkg            = 1,
	selected_child_mod      = nil,

	-- Input focus tracking
	focused_field           = nil,

	-- Game Chooser State
	viewing_game_details    = nil,
	games_scroll            = 0,
}

function current_state.get(self_or_key, maybe_key)
	local key = maybe_key or self_or_key
	return current_state[key]
end

function current_state.set(self_or_key, key_or_val, maybe_val, maybe_silent)
	local key, val, silent
	if type(self_or_key) == "table" and (key_or_val ~= nil) then
		key, val, silent = key_or_val, maybe_val, maybe_silent
	else
		key, val, silent = self_or_key, key_or_val, maybe_val
	end
	state.set(key, val, silent)
end

local listeners = {}

function state.init()
	-- Cold launch default: ALWAYS greet the player with the "games" tab.
	-- Only if returning from an active session (e.g. disconnected from a server or exited a local world),
	-- restore the respective tab so the user lands back where they were.
	if rawget(_G, "gamedata") and (gamedata.mode == "join" or (gamedata.address and gamedata.address ~= "")) then
		current_state.active_tab = "online"
		gamedata.mode = nil
		gamedata.address = nil
	elseif rawget(_G, "gamedata") and (gamedata.mode == "singleplayer" or gamedata.mode == "host") then
		current_state.active_tab = "local"
		gamedata.mode = nil
	else
		current_state.active_tab = "games"
	end

	local dbg_tab = core.settings:get("debug_active_tab")
	if dbg_tab and dbg_tab ~= "" then
		current_state.active_tab = dbg_tab
	end

	-- Always ensure mainmenu_session_tab is cleared from settings so cold starts stay clean
	if core.settings:get("mainmenu_session_tab") and core.settings:get("mainmenu_session_tab") ~= "" then
		core.settings:set("mainmenu_session_tab", "")
	end
	core.settings:set("maintab_LAST", "games")
	core.settings:write()

	local last_world = tonumber(core.settings:get("mainmenu_last_selected_world"))
	if last_world and last_world > 0 then
		current_state.selected_world_index = last_world
	end

	current_state.selected_game_id = core.settings:get("menu_last_game")
	current_state.is_hosting = core.settings:get_bool("enable_server")
	current_state.server_announce = core.settings:get_bool("server_announce")
	current_state.creative_mode = core.settings:get_bool("creative_mode")
	current_state.enable_damage = core.settings:get_bool("enable_damage")
	current_state.player_name = core.settings:get("name") or ""
	current_state.bind_address = core.settings:get("bind_address") or ""
	current_state.port = core.settings:get("port") or "30000"
end

function state.get(key)
	return current_state[key]
end

function state.get_all()
	return current_state
end

function state.set(key, value, silent)
	if current_state[key] ~= value then
		current_state[key] = value
		if not silent then
			state.notify(key, value)
		end
	end
end

function state.update(changes, silent)
	local changed = false
	for k, v in pairs(changes) do
		if current_state[k] ~= v then
			current_state[k] = v
			changed = true
		end
	end
	if changed and not silent then
		state.notify()
	end
end

function state.subscribe(fn)
	table.insert(listeners, fn)
	return function()
		for i, listener in ipairs(listeners) do
			if listener == fn then
				table.remove(listeners, i)
				break
			end
		end
	end
end

function state.notify(key, value)
	for _, fn in ipairs(listeners) do
		fn(current_state, key, value)
	end
end

function state.mark_chooser_seen()
	core.settings:set_bool("game_chooser_seen", true)
end

function state.save_persistent()
	-- Startup default tab must strictly remain "games" on cold start
	core.settings:set("maintab_LAST", "games")
	if core.settings:get("mainmenu_session_tab") and core.settings:get("mainmenu_session_tab") ~= "" then
		core.settings:set("mainmenu_session_tab", "")
	end
	if current_state.selected_world_index then
		core.settings:set("mainmenu_last_selected_world", tostring(current_state.selected_world_index))
	end
	if current_state.selected_game_id then
		core.settings:set("menu_last_game", current_state.selected_game_id)
	end
	core.settings:set_bool("enable_server", current_state.is_hosting)
	core.settings:set_bool("server_announce", current_state.server_announce)
	core.settings:set_bool("creative_mode", current_state.creative_mode)
	core.settings:set_bool("enable_damage", current_state.enable_damage)
	if current_state.player_name and current_state.player_name ~= "" then
		core.settings:set("name", current_state.player_name)
	end
	core.settings:write()
end

setmetatable(state, {
	__index = function(_, k)
		return current_state[k]
	end,
	__newindex = function(_, k, v)
		state.set(k, v)
	end
})

return state
