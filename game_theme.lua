-- Luanti
-- Copyright (C) 2013 sapier
-- SPDX-License-Identifier: LGPL-2.1-or-later

mm_game_theme = {}

local COLORS = {
	dark  = { clouds = "#1c2a47", sky = "#090b1a" },
	light = { clouds = "#f0f0ff", sky = "#8cbafa" },
}

-- 24-hour calibrated astronomical & aesthetic keyframes for real-time sky & clouds
mm_game_theme.time_keyframes = {
	{ hour = 0.0,   sky = "#080b1e", clouds = "#18243b" }, -- Deep Starlight Night
	{ hour = 4.5,   sky = "#0b112c", clouds = "#1a2640" }, -- Astronomical twilight
	{ hour = 5.75,  sky = "#3d2b56", clouds = "#6b4c6e" }, -- Civil dawn
	{ hour = 6.5,   sky = "#8c3e2d", clouds = "#c46d52" }, -- Golden dawn
	{ hour = 7.0,   sky = "#d96b27", clouds = "#ffd299" }, -- 7 AM Sunrise peak
	{ hour = 8.5,   sky = "#6ba4f8", clouds = "#f2f6ff" }, -- Morning blue
	{ hour = 12.0,  sky = "#4a90e2", clouds = "#f0f4f8" }, -- 12 PM Noon daylight
	{ hour = 16.5,  sky = "#5499e0", clouds = "#fbf5e6" }, -- Late afternoon
	{ hour = 18.0,  sky = "#b86530", clouds = "#f0a85d" }, -- Golden hour
	{ hour = 19.0,  sky = "#cf5219", clouds = "#fca34d" }, -- 7 PM Orange sunset peak
	{ hour = 19.75, sky = "#6b2d5c", clouds = "#824d6d" }, -- Dusk afterglow
	{ hour = 20.75, sky = "#1c183a", clouds = "#292548" }, -- Late twilight
	{ hour = 22.0,  sky = "#080b1e", clouds = "#18243b" }, -- Deep starlight night
	{ hour = 24.0,  sky = "#080b1e", clouds = "#18243b" }, -- Wraparound
}

local function hex_to_rgb(hex)
	hex = hex:gsub("#", "")
	return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function rgb_to_hex(r, g, b)
	return string.format("#%02x%02x%02x",
		math.min(255, math.max(0, math.floor(r + 0.5))),
		math.min(255, math.max(0, math.floor(g + 0.5))),
		math.min(255, math.max(0, math.floor(b + 0.5))))
end

local function lerp_gamma(c1, c2, t)
	local r1, g1, b1 = hex_to_rgb(c1)
	local r2, g2, b2 = hex_to_rgb(c2)
	-- Smoothstep easing for continuous derivative across keyframes
	local st = t * t * (3 - 2 * t)
	-- Gamma-corrected squared space blending avoids muddy/grey desaturation
	local r = math.sqrt((1 - st) * (r1 * r1) + st * (r2 * r2))
	local g = math.sqrt((1 - st) * (g1 * g1) + st * (g2 * g2))
	local b = math.sqrt((1 - st) * (b1 * b1) + st * (b2 * b2))
	return rgb_to_hex(r, g, b)
end

function mm_game_theme.get_realtime_colors(maybe_decimal_hour)
	local hour
	if maybe_decimal_hour ~= nil then
		hour = tonumber(maybe_decimal_hour) or 12.0
	else
		local now = os.date("*t")
		hour = now.hour + (now.min / 60) + (now.sec / 3600)
	end

	hour = hour % 24.0
	local keyframes = mm_game_theme.time_keyframes
	for i = 1, #keyframes - 1 do
		local k1 = keyframes[i]
		local k2 = keyframes[i + 1]
		if hour >= k1.hour and hour <= k2.hour then
			local range = k2.hour - k1.hour
			local t = range > 0 and ((hour - k1.hour) / range) or 0
			return {
				sky = lerp_gamma(k1.sky, k2.sky, t),
				clouds = lerp_gamma(k1.clouds, k2.clouds, t),
			}
		end
	end

	return { sky = keyframes[1].sky, clouds = keyframes[1].clouds }
end

function mm_game_theme.resolve_colors()
	local theme = core.settings:get("menu_theme")
	if not theme or theme == "" or theme == "realtime" or theme == "auto" or theme == "time_of_day" then
		return mm_game_theme.get_realtime_colors()
	end
	local preset = COLORS[theme]
	if preset then
		return preset
	end
	core.log("warning", "Unrecognized menu theme: " .. tostring(theme) .. ", defaulting to realtime")
	return mm_game_theme.get_realtime_colors()
end

--------------------------------------------------------------------------------
function mm_game_theme.init()
	mm_game_theme.texturepack = core.settings:get("texture_path")

	mm_game_theme.gameid = nil

	mm_game_theme.music_handle = nil
end

--------------------------------------------------------------------------------
function mm_game_theme.set_engine(hide_decorations)
	mm_game_theme.gameid = nil
	mm_game_theme.stop_music()

	core.set_topleft_text("")

	local have_bg = false
	local have_overlay = mm_game_theme.set_engine_single("overlay")

	if not have_overlay then
		have_bg = mm_game_theme.set_engine_single("background")
	end

	mm_game_theme.clear_single("header")
	mm_game_theme.clear_single("footer")
	core.set_clouds(false)

	if not hide_decorations then
		mm_game_theme.set_engine_single("header")
		mm_game_theme.set_engine_single("footer")
	end

	local c = mm_game_theme.resolve_colors()
	core.set_clouds_color(c.clouds)
	core.set_sky_color(c.sky)

	if not have_bg then
		core.set_clouds(core.settings:get_bool("menu_clouds"))
	end
end

--------------------------------------------------------------------------------
function mm_game_theme.set_game(gamedetails, force)
	assert(gamedetails ~= nil)

	if not force and mm_game_theme.gameid == gamedetails.id then
		return
	end
	mm_game_theme.gameid = gamedetails.id
	mm_game_theme.set_music(gamedetails)

	core.set_topleft_text("")

	local have_bg = false
	local have_overlay = mm_game_theme.set_game_single("overlay", gamedetails)

	if not have_overlay then
		have_bg = mm_game_theme.set_game_single("background", gamedetails)
	end

	mm_game_theme.clear_single("header")
	mm_game_theme.clear_single("footer")
	core.set_clouds(false)

	mm_game_theme.set_game_single("header", gamedetails)
	mm_game_theme.set_game_single("footer", gamedetails)

	local c = mm_game_theme.resolve_colors()
	core.set_clouds_color(c.clouds)
	core.set_sky_color(c.sky)

	if not have_bg then
		core.set_clouds(core.settings:get_bool("menu_clouds"))
	end
end

--------------------------------------------------------------------------------
function mm_game_theme.clear_single(identifier)
	core.set_background(identifier, "")
end

--------------------------------------------------------------------------------
local valid_image_extensions = {
	".png",
	".jpg",
	".jpeg",
}

function mm_game_theme.set_engine_single(identifier)
	--try texture pack first
	if mm_game_theme.texturepack ~= nil then
		for _, extension in pairs(valid_image_extensions) do
			local path = mm_game_theme.texturepack .. DIR_DELIM .. "menu_" .. identifier .. extension
			if core.set_background(identifier, path) then
				return true
			end
		end
	end

	local path = defaulttexturedir .. DIR_DELIM .. "menu_" .. identifier .. ".png"
	if core.set_background(identifier, path) then
		return true
	end

	return false
end

--------------------------------------------------------------------------------
function mm_game_theme.set_game_single(identifier, gamedetails)
	local extensions_randomised = table.copy(valid_image_extensions)
	table.shuffle(extensions_randomised)
	for _, extension in pairs(extensions_randomised) do
		assert(gamedetails ~= nil)

		if mm_game_theme.texturepack ~= nil then
			local path = mm_game_theme.texturepack .. DIR_DELIM .. gamedetails.id .. "_menu_" .. identifier .. extension
			if core.set_background(identifier, path) then
				return true
			end
		end

		-- Find out how many randomized textures the game provides
		local n = 0
		local filename
		local menu_files = core.get_dir_list(gamedetails.path .. DIR_DELIM .. "menu", false)
		for i = 1, #menu_files do
			filename = identifier .. "." .. i .. extension
			if table.indexof(menu_files, filename) == -1 then
				n = i - 1
				break
			end
		end
		-- Select random texture, 0 means standard texture
		n = math.random(0, n)
		if n == 0 then
			filename = identifier .. extension
		else
			filename = identifier .. "." .. n .. extension
		end

		local path = gamedetails.path .. DIR_DELIM .. "menu" .. DIR_DELIM .. filename
		if core.set_background(identifier, path) then
			return true
		end

	end
	return false
end

--------------------------------------------------------------------------------
function mm_game_theme.stop_music()
	if mm_game_theme.music_handle ~= nil then
		core.sound_stop(mm_game_theme.music_handle)
	end
end

--------------------------------------------------------------------------------
function mm_game_theme.set_music(gamedetails)
	mm_game_theme.stop_music()

	assert(gamedetails ~= nil)

	local music_path = gamedetails.path .. DIR_DELIM .. "menu" .. DIR_DELIM .. "theme"
	mm_game_theme.music_handle = core.sound_play(music_path, true)
end
