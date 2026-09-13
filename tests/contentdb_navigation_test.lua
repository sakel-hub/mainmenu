-- ContentDB Navigation & Package Resolution Unit Tests
-- Tests resolve_contentdb_package and open_package_details in dispatcher.lua

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

print("Starting ContentDB Package Resolution & Navigation Tests...")

-- Mock environment
_G.core = {
	settings = {
		get = function() return nil end,
		get_bool = function() return false end,
		set = function() end,
		write = function() end,
	},
	formspec_escape = function(s) return s end,
	url_encode = function(s) return s end,
	handle_async = function() end,
	sound_play = function() end,
	log = function() end,
}
_G.gamedata = {}
_G.serverlistmgr = {}
_G.state = {
	get = function() return nil end,
	set = function() end,
}
_G.ui = {
	update = function() end,
}
_G.mainmenu = {
	ui_element = {
		hide = function() end,
		show = function() end,
	},
}

-- Sample ContentDB packages
local sample_packages = {
	{
		id = "tenplus1/mobs_animal",
		author = "tenplus1",
		name = "mobs_animal",
		title = "Animal Mobs",
		type = "mod",
		url_part = "tenplus1/mobs_animal",
		release = 10,
	},
	{
		id = "stu/3d_armor",
		author = "stu",
		name = "3d_armor",
		title = "3D Armor",
		type = "mod",
		url_part = "stu/3d_armor",
		release = 5,
	},
	{
		id = "Wuzzy/mineclonia",
		author = "Wuzzy",
		name = "mineclonia",
		title = "Mineclonia",
		type = "game",
		url_part = "Wuzzy/mineclonia",
		release = 22,
	},
}

local pkg_by_id = {}
for _, p in ipairs(sample_packages) do
	pkg_by_id[p.id] = p
	pkg_by_id[p.id:lower()] = p
end

_G.contentdb = {
	load_ok = true,
	loading = false,
	packages_full = sample_packages,
	packages = sample_packages,
	package_by_id = pkg_by_id,
	aliases = {
		["mobs"] = "tenplus1/mobs_animal",
	},
	get_package_by_id = function(id)
		return pkg_by_id[id] or pkg_by_id[id:lower()]
	end,
	get_package_by_info = function(author, name)
		return pkg_by_id[author:lower() .. "/" .. name:lower()]
	end,
}

_G.pkgmgr = {
	get_contentdb_id = function(pkg)
		if pkg.author and pkg.name then
			return pkg.author .. "/" .. pkg.name
		end
		return nil
	end,
	normalize_game_id = function(id)
		return (id:gsub("^mineclone2$", "voxe_libere"):gsub("^mineclonia$", "mineclonia"))
	end,
}

-- Load dispatcher.lua
local dispatcher = dofile("dispatcher.lua")

test("resolve_contentdb_package returns direct ContentDB package objects", function()
	local pkg = sample_packages[1]
	local res = dispatcher.resolve_contentdb_package(pkg)
	assert_eq(pkg, res, "Must return target if already ContentDB package object")
end)

test("resolve_contentdb_package resolves via pkgmgr.get_contentdb_id", function()
	local local_mod = { author = "stu", name = "3d_armor", title = "3D Armor", type = "mod" }
	local res = dispatcher.resolve_contentdb_package(local_mod)
	assert_not_nil(res, "Must resolve local mod with author/name")
	assert_eq("stu/3d_armor", res.id, "Resolved package id must match")
end)

test("resolve_contentdb_package resolves string mod name from packages_full", function()
	local res = dispatcher.resolve_contentdb_package("3d_armor", "mod")
	assert_not_nil(res, "Must resolve string mod name")
	assert_eq("3d_armor", res.name)
	assert_eq("stu", res.author)
end)

test("resolve_contentdb_package resolves via ContentDB aliases", function()
	local res = dispatcher.resolve_contentdb_package("mobs", "mod")
	assert_not_nil(res, "Must resolve alias 'mobs'")
	assert_eq("tenplus1/mobs_animal", res.id)
end)

test("resolve_contentdb_package resolves game via normalized id", function()
	local local_game = { name = "mineclonia", type = "game", title = "Mineclonia Game" }
	local res = dispatcher.resolve_contentdb_package(local_game, "game")
	assert_not_nil(res, "Must resolve game by normalized id")
	assert_eq("Wuzzy/mineclonia", res.id)
end)

test("resolve_contentdb_package resolves by title fallback", function()
	local local_mod = { title = "Animal Mobs", type = "mod" }
	local res = dispatcher.resolve_contentdb_package(local_mod, "mod")
	assert_not_nil(res, "Must resolve package by title")
	assert_eq("tenplus1/mobs_animal", res.id)
end)

test("resolve_contentdb_package returns nil for non-existent package", function()
	local res = dispatcher.resolve_contentdb_package("completely_unknown_custom_mod_123")
	assert_eq(nil, res, "Must return nil when package is not in ContentDB")
end)

test("open_package_details opens package dialog directly when resolved", function()
	local opened_pkg = nil
	local dialog_shown = false

	_G.create_package_dialog = function(cdb_pkg)
		opened_pkg = cdb_pkg
		return {
			set_parent = function() end,
			show = function() dialog_shown = true end,
		}
	end

	dispatcher.open_package_details("3d_armor", "mod")
	assert_not_nil(opened_pkg, "create_package_dialog must be called")
	assert_eq("stu/3d_armor", opened_pkg.id)
	assert_eq(true, dialog_shown, "Dialog show() must be called")
end)

test("open_package_details falls back to search dialog for unknown packages", function()
	local search_opened = false
	local search_term_passed = nil

	_G.create_contentdb_dlg = function(type_filter, search_tag, search_term)
		search_opened = true
		search_term_passed = search_term
		return {
			set_parent = function() end,
			show = function() end,
		}
	end

	dispatcher.open_package_details("my_private_mod", "mod")
	assert_eq(true, search_opened, "create_contentdb_dlg must be called as fallback")
	assert_eq("my_private_mod", search_term_passed, "Search term must match package name")
end)

test("open_package_details triggers fetch_pkgs when not loaded, then opens dialog", function()
	local orig_load_ok = _G.contentdb.load_ok
	local orig_packages = _G.contentdb.packages_full
	_G.contentdb.load_ok = false
	_G.contentdb.packages_full = {}
	_G.contentdb.package_by_id = {}

	local fetch_called = false
	_G.contentdb.fetch_pkgs = function(cb)
		fetch_called = true
		-- Simulate async fetch finishing and populating packages
		_G.contentdb.load_ok = true
		_G.contentdb.packages_full = sample_packages
		_G.contentdb.package_by_id = pkg_by_id
		cb(true)
	end

	local opened_pkg = nil
	_G.create_package_dialog = function(cdb_pkg)
		opened_pkg = cdb_pkg
		return {
			set_parent = function() end,
			show = function() end,
		}
	end

	dispatcher.open_package_details("3d_armor", "mod")
	assert_eq(true, fetch_called, "contentdb.fetch_pkgs must be triggered")
	assert_not_nil(opened_pkg, "Package dialog must be opened once fetch completes")
	assert_eq("stu/3d_armor", opened_pkg.id)

	-- Restore
	_G.contentdb.load_ok = orig_load_ok
	_G.contentdb.packages_full = orig_packages
	_G.contentdb.package_by_id = pkg_by_id
end)

test("resolve_contentdb_package resolves when target has pre-attached cdb_package", function()
	local dummy_cdb = { id = "author/mod", url_part = "author/mod", name = "mod", release = 1 }
	local local_target = { name = "different_name", cdb_package = dummy_cdb }
	local resolved = dispatcher.resolve_contentdb_package(local_target)
	assert_eq(dummy_cdb, resolved, "Pre-attached cdb_package must be returned directly")
end)

test("resolve_contentdb_package resolves modpack with _modpack suffix", function()
	local target = { name = "mobs_animal_modpack", type = "modpack" }
	local resolved = dispatcher.resolve_contentdb_package(target)
	assert_not_nil(resolved, "Must resolve mobs_animal from mobs_animal_modpack")
	assert_eq("tenplus1/mobs_animal", resolved.id)
end)

test("resolve_contentdb_package cleans author email in target", function()
	local target = { name = "mobs_animal", author = "tenplus1 <tenplus1@email.com>", type = "mod" }
	local resolved = dispatcher.resolve_contentdb_package(target)
	assert_not_nil(resolved, "Must resolve mobs_animal with email in author field")
	assert_eq("tenplus1/mobs_animal", resolved.id)
end)

print(string.format("\nTest Summary: %d passed, %d failed", passed, failed))
if failed > 0 then
	os.exit(1)
end
