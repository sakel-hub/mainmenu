-- World Selection & Input Styling Unit Tests
-- Validates that selecting a world opens mod config for the exact selected world
-- and verifies input fields render with inset borders (dark top/left, light bottom/right).

local passed = 0
local failed = 0

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		print("  [PASS] " .. name)
		passed = passed + 1
	else
		print("  [FAIL] " .. name .. ": " .. tostring(err))
		failed = failed + 1
	end
end

local function assert_eq(expected, actual, msg)
	if expected ~= actual then
		error((msg or "Assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function assert_not_nil(val, msg)
	if val == nil then
		error(msg or "Expected value to be non-nil", 2)
	end
end

print("Starting World Selection & Input Styling Tests...")

-- Mock environment
_G.DIR_DELIM = "/"
_G.fgettext = function(s) return s end
_G.fgettext_ne = function(s) return s end

local dummy_settings = {}
_G.core = {
	settings = {
		get = function(_, k) return dummy_settings[k] end,
		get_bool = function(_, k) return dummy_settings[k] == "true" or dummy_settings[k] == true end,
		set = function(_, k, v) dummy_settings[k] = tostring(v) end,
		set_bool = function(_, k, v) dummy_settings[k] = v and "true" or "false" end,
		write = function() end,
	},
	formspec_escape = function(s) return s end,
	log = function() end,
	open_dir = function() end,
	get_user_path = function() return "/dummy/user" end,
	get_worlds = function()
		return {
			{ name = "World_Alpha", path = "/worlds/alpha", gameid = "game_a" },
			{ name = "World_Beta",  path = "/worlds/beta",  gameid = "game_b" },
			{ name = "World_Gamma", path = "/worlds/gamma", gameid = "game_b" },
			{ name = "World_Delta", path = "/worlds/delta", gameid = "game_a" },
		}
	end,
	get_mainmenu_path = function() return "." end,
	get_builtin_path = function() return "." end,
	get_texturepath_share = function() return "." end,
	is_debug_build = function() return false end,
	explode_scrollbar_event = function() return {} end,
	start = function() end,
}

_G.gamedata = {}

_G.pkgmgr = {
	get_worldconfig = function(path)
		return { id = "valid_config", path = path }
	end,
	normalize_game_id = function(id) return id end,
	find_by_gameid = function(id)
		return { id = id, title = id, aliases = {} }
	end,
}

_G.Settings = function()
	return {
		set = function() end,
		write = function() return true end,
		to_table = function() return {} end,
		remove = function() end,
	}
end

_G.dialog_create = function(name, _get_formspec, _handle_buttons)
	return {
		name = name,
		data = {},
		show = function() end,
		hide = function() end,
		set_parent = function() end,
		delete = function() end,
	}
end

-- Load Theme
local theme = dofile("theme.lua")

test("theme.input_box renders inset borders (dark top/left, light bottom/right)", function()
	local x, y, w, h = 1.0, 2.0, 5.0, 0.8
	local fs = theme.input_box(x, y, w, h, false)

	local b_light = theme.colors.card_border_light
	local b_dark = theme.colors.card_border_dark
	local t = 0.035

	-- Top shadow (inset): y, height t, color b_dark
	local top_pattern = string.format("box[%f,%f;%f,%f;%s]", x, y, w, t, b_dark)
	-- Left shadow (inset): x, width t, color b_dark
	local left_pattern = string.format("box[%f,%f;%f,%f;%s]", x, y, t, h, b_dark)
	-- Bottom highlight (inset): y + h - t, height t, color b_light
	local bottom_pattern = string.format("box[%f,%f;%f,%f;%s]", x, y + h - t, w, t, b_light)
	-- Right highlight (inset): x + w - t, width t, color b_light
	local right_pattern = string.format("box[%f,%f;%f,%f;%s]", x + w - t, y, t, h, b_light)

	assert_not_nil(fs:find(top_pattern, 1, true), "Top border must be dark (inset)")
	assert_not_nil(fs:find(left_pattern, 1, true), "Left border must be dark (inset)")
	assert_not_nil(fs:find(bottom_pattern, 1, true), "Bottom border must be light (inset)")
	assert_not_nil(fs:find(right_pattern, 1, true), "Right border must be light (inset)")
end)

-- Load dlg_config_world
dofile("dlg_config_world.lua")

test("create_configure_world_dlg accepts raw index and loads correct worldspec", function()
	local dlg = create_configure_world_dlg(4)
	assert_not_nil(dlg, "Dialog should be created")
	assert_eq("/worlds/delta", dlg.data.worldspec.path, "Must point to World_Delta")
	assert_eq("World_Delta", dlg.data.worldspec.name, "Must match World_Delta name")
end)

test("create_configure_world_dlg accepts worldspec table directly", function()
	local custom_spec = { name = "World_Delta", path = "/worlds/delta", gameid = "game_a" }
	local dlg = create_configure_world_dlg(custom_spec)
	assert_not_nil(dlg, "Dialog should be created")
	assert_eq("/worlds/delta", dlg.data.worldspec.path, "Must point to custom spec path")
end)

test("create_configure_world_dlg accepts world path string", function()
	local dlg = create_configure_world_dlg("/worlds/beta")
	assert_not_nil(dlg, "Dialog should be created")
	assert_eq("/worlds/beta", dlg.data.worldspec.path, "Must point to /worlds/beta")
	assert_eq("World_Beta", dlg.data.worldspec.name, "Must match World_Beta name")
end)

-- Setup Filterlist mock for Game A
-- In core.get_worlds():
-- 1: World_Alpha (game_a)
-- 2: World_Beta (game_b)
-- 3: World_Gamma (game_b)
-- 4: World_Delta (game_a)
-- For Game A:
-- Filtered list index 1 = World_Alpha (raw index 1)
-- Filtered list index 2 = World_Delta (raw index 4)
_G.menudata = {
	worldlist = {
		get_list = function()
			return {
				{ name = "World_Alpha", path = "/worlds/alpha", gameid = "game_a" },
				{ name = "World_Delta", path = "/worlds/delta", gameid = "game_a" },
			}
		end,
		get_raw_index = function(_, listidx)
			if listidx == 1 then return 1 end
			if listidx == 2 then return 4 end
			return 0
		end,
		get_current_index = function(_, rawidx)
			if rawidx == 1 then return 1 end
			if rawidx == 4 then return 2 end
			return 0
		end,
	},
}

_G.mainmenu = {
	theme = theme,
	state = dofile("state.lua"),
	ui_element = {
		hide = function() end,
		show = function() end,
	},
}

local dispatcher = dofile("dispatcher.lua")
local st = _G.mainmenu.state

test("dispatcher opens mods for selected world when list_index != raw_index", function()
	-- User selects World_Delta (list index 2 in Game A, but raw index 4 in core.get_worlds())
	st.set("selected_world_index", 2)
	st.set("selected_world_path", "/worlds/delta")

	-- Spy on create_configure_world_dlg
	local configured_arg = nil
	local orig_create_configure = _G.create_configure_world_dlg
	_G.create_configure_world_dlg = function(arg)
		configured_arg = arg
		return orig_create_configure(arg)
	end

	dispatcher.dispatch(st, { world_configure = true })

	assert_eq(4, configured_arg, "create_configure_world_dlg must receive raw_index 4, not list_index 2")

	_G.create_configure_world_dlg = orig_create_configure
end)

test("dispatcher launches selected world with correct raw_index", function()
	st.set("selected_world_index", 2)
	st.set("selected_world_path", "/worlds/delta")

	dispatcher.dispatch(st, { play_world = true })

	assert_eq(4, _G.gamedata.selected_world, "gamedata.selected_world must be set to raw_index 4")
	assert_eq("4", dummy_settings["mainmenu_last_selected_world"], "mainmenu_last_selected_world setting must be 4")
end)

test("state.save_persistent correctly converts list_index to raw_index", function()
	st.set("selected_world_index", 2)
	st.set("selected_world_path", "/worlds/delta")
	st.save_persistent()

	assert_eq("4", dummy_settings["mainmenu_last_selected_world"], "Persisted setting must be raw index 4")
end)

test("state.init maps saved raw_index to filtered list_index", function()
	dummy_settings["mainmenu_last_selected_world"] = "4"
	st.init()

	assert_eq(2, st.selected_world_index, "st.selected_world_index must resolve to list index 2")
	assert_eq("/worlds/delta", st.selected_world_path, "st.selected_world_path must be initialized to /worlds/delta")
end)

print(string.format("\nTest Summary: %d passed, %d failed", passed, failed))
if failed > 0 then
	os.exit(1)
end
