-- Luanti Main Menu Redesign
-- Local Game / Worlds View Component (Formspec Version 7)

local view_local = {}

local ui_list = dofile(custom_menupath .. DIR_DELIM .. "components" .. DIR_DELIM .. "ui_list.lua")

local world_info_cache = {}

function view_local.clear_cache(world_path)
	if world_path then
		world_info_cache[world_path] = nil
	else
		world_info_cache = {}
	end
end

local function calculate_world_size(world_path)
	local total = 0
	local files = {"map.sqlite", "players.sqlite", "auth.sqlite", "mod_storage.sqlite", "env_meta.txt", "map_meta.txt", "world.mt"}
	for _, fname in ipairs(files) do
		local f = io.open(world_path .. DIR_DELIM .. fname, "rb")
		if f then
			total = total + (f:seek("end") or 0)
			f:close()
		end
	end
	return total
end

local function format_bytes(bytes)
	if not bytes or bytes <= 0 then return "-" end
	if bytes < 1024 then
		return bytes .. " B"
	elseif bytes < 1024 * 1024 then
		return string.format("%.1f KB", bytes / 1024)
	elseif bytes < 1024 * 1024 * 1024 then
		return string.format("%.1f MB", bytes / (1024 * 1024))
	else
		return string.format("%.2f GB", bytes / (1024 * 1024 * 1024))
	end
end

local stat_cmd_fmt = nil
local function get_stat_cmd(path)
	if not stat_cmd_fmt then
		local test_f = io.popen and io.popen("stat -f %m /dev/null 2>/dev/null")
		if test_f then
			local res = test_f:read("*a")
			test_f:close()
			if res and tonumber(res:match("%d+")) then
				stat_cmd_fmt = "stat -f %%m %q 2>/dev/null"
			else
				stat_cmd_fmt = "stat -c %%Y %q 2>/dev/null"
			end
		else
			stat_cmd_fmt = "stat -f %%m %q 2>/dev/null"
		end
	end
	return string.format(stat_cmd_fmt, path)
end

local function get_file_mtime(path)
	if not io.popen or not path or path == "" then return 0 end
	local cmd = get_stat_cmd(path)
	local f = io.popen(cmd)
	if f then
		local out = f:read("*a")
		f:close()
		local ts = tonumber(out and out:match("%d+"))
		if ts and ts > 0 then return ts end
	end
	return 0
end

local function format_last_played(ts)
	return ui_list.format_last_played(ts)
end

local function get_play_time(world_path)
	local f = io.open(world_path .. DIR_DELIM .. "env_meta.txt", "r")
	if not f then return 0 end
	local gt = 0
	for line in f:lines() do
		local val = line:match("^game_time%s*=%s*(%d+)")
		if val then
			gt = tonumber(val) or 0
			break
		end
	end
	f:close()
	return gt
end

local function format_play_time(secs)
	if not secs or secs <= 0 then return "0m" end
	if secs < 60 then
		return secs .. "s"
	elseif secs < 3600 then
		return math.floor(secs / 60) .. "m"
	else
		return string.format("%.1fh", secs / 3600)
	end
end

local function get_world_info(world)
	if not world then return nil end
	if world_info_cache[world.path] then
		return world_info_cache[world.path]
	end

	local info = {
		name = world.name,
		path = world.path,
		gameid = world.gameid,
		mg_name = "v7",
		backend = "sqlite3",
		version = "5.x",
		mods_count = 0,
		mods_str = "0",
		size_bytes = 0,
		size_str = "-",
		last_played_ts = 0,
		last_played_str = fgettext("Never"),
		last_played_full = fgettext("Never played"),
		play_time_secs = 0,
		play_time_str = "0m",
		screenshot = nil,
	}

	local worldconfig = pkgmgr.get_worldconfig(world.path)
	if worldconfig then
		if worldconfig.mg_name then
			info.mg_name = worldconfig.mg_name
		end
		if worldconfig.backend then
			info.backend = worldconfig.backend
		end
		if worldconfig.global_mods then
			local count = 0
			for _, enabled in pairs(worldconfig.global_mods) do
				if enabled then
					count = count + 1
				end
			end
			info.mods_count = count
			info.mods_str = tostring(count)
		end
		if worldconfig.minetest_version then
			info.version = worldconfig.minetest_version
		end
		if worldconfig.last_played then
			info.last_played_ts = tonumber(worldconfig.last_played) or 0
		end
	end

	-- If version wasn't in world.mt, look up game's min_minetest_version
	if info.version == "5.x" then
		local world_game = pkgmgr.find_by_gameid(world.gameid)
		if world_game then
			local gconf_path = world_game.path and (world_game.path .. DIR_DELIM .. "game.conf")
			if gconf_path then
				local gf = io.open(gconf_path, "r")
				if gf then
					for line in gf:lines() do
						local mv = line:match("^min_minetest_version%s*=%s*(%S+)")
						if mv then
							info.version = mv
							break
						end
					end
					gf:close()
				end
			end
		end
	end

	-- World size calculation
	info.size_bytes = calculate_world_size(world.path)
	info.size_str = format_bytes(info.size_bytes)

	-- Last played timestamp: if not in worldconfig, stat world.mt or env_meta.txt
	if info.last_played_ts <= 0 then
		local mt = get_file_mtime(world.path .. DIR_DELIM .. "world.mt")
		if mt <= 0 then
			mt = get_file_mtime(world.path .. DIR_DELIM .. "env_meta.txt")
		end
		info.last_played_ts = mt
	end
	info.last_played_str = format_last_played(info.last_played_ts)
	info.last_played_full = ui_list.format_timestamp_full(info.last_played_ts)

	-- In-game total play time
	info.play_time_secs = get_play_time(world.path)
	info.play_time_str = format_play_time(info.play_time_secs)

	-- Check for world screenshot
	local shot_path = world.path .. DIR_DELIM .. "screenshot.png"
	local f = io.open(shot_path, "r")
	if f then
		f:close()
		info.screenshot = shot_path
	end

	world_info_cache[world.path] = info
	return info
end

local function compare_worlds(a, b, col, dir)
	local va, vb
	if col == "game" then
		local pa = a.gameid and pkgmgr.find_by_gameid(a.gameid)
		local pb = b.gameid and pkgmgr.find_by_gameid(b.gameid)
		local ga = (pa and pa.title) or a.gameid or ""
		local gb = (pb and pb.title) or b.gameid or ""
		va = ga:lower()
		vb = gb:lower()
	elseif col == "mg" then
		local wa = get_world_info(a)
		local wb = get_world_info(b)
		va = ((wa and wa.mg_name) or ""):lower()
		vb = ((wb and wb.mg_name) or ""):lower()
	elseif col == "version" then
		local wa = get_world_info(a)
		local wb = get_world_info(b)
		va = ((wa and wa.version) or ""):lower()
		vb = ((wb and wb.version) or ""):lower()
	elseif col == "mods" then
		local wa = get_world_info(a)
		local wb = get_world_info(b)
		va = (wa and wa.mods_count) or 0
		vb = (wb and wb.mods_count) or 0
	elseif col == "size" then
		local wa = get_world_info(a)
		local wb = get_world_info(b)
		va = (wa and wa.size_bytes) or 0
		vb = (wb and wb.size_bytes) or 0
	elseif col == "last_played" then
		local wa = get_world_info(a)
		local wb = get_world_info(b)
		va = (wa and wa.last_played_ts) or 0
		vb = (wb and wb.last_played_ts) or 0
	else -- "name"
		va = (a.name or ""):lower()
		vb = (b.name or ""):lower()
	end

	if va ~= vb then
		if dir == "asc" then
			return va < vb
		else
			return va > vb
		end
	end
	return (a.name or ""):lower() < (b.name or ""):lower()
end

function view_local.render(st, th)
	local fs = {}
	table.insert(fs, "container[3.3,0]")

	-- Main content background (Width: 18.3, Height: 12.0)
	table.insert(fs, string.format("box[0,0;18.3,12.0;%s]", th.colors.backdrop))

	local raw_worldlist = (menudata and menudata.worldlist and menudata.worldlist:get_list()) or {}
	local raw_query = st.world_search_query or ""
	local query = (raw_query.trim and raw_query:trim() or raw_query:match("^%s*(.-)%s*$") or ""):lower()

	----------------------------------------------------------------------------
	-- Top Search & Game Filter Toolbar (Matches Play Online layout)
	----------------------------------------------------------------------------
	table.insert(fs, th.voxel_box(0.35, 0.25, 17.65, 0.95, th.colors.card_bg))

	-- World Search Bar with Search and Clear Action Buttons (Matches Play Online 5.60 width)
	local is_world_search_focused = (st.focused_field == "te_world_search")
	table.insert(fs, th.search_bar(0.55, 0.38, 5.60, 0.65, "te_world_search", st.world_search_query or "", is_world_search_focused, "btn_world_search", "btn_world_clear", fgettext("Search worlds by name or game")))

	local current_game_id = st.selected_game_id or core.settings:get("menu_last_game")
	local found_game_obj = nil
	if current_game_id and pkgmgr and pkgmgr.find_by_gameid then
		found_game_obj = pkgmgr.find_by_gameid(current_game_id)
	end

	-- Verify current_game_id actually matches an installed game in pkgmgr.games
	local game_installed = false
	if pkgmgr and pkgmgr.games then
		for _, g in ipairs(pkgmgr.games) do
			if (found_game_obj and g.id == found_game_obj.id) or g.id == current_game_id then
				game_installed = true
				current_game_id = g.id
				break
			end
		end
	end

	if not game_installed then
		local cg = (current_game and current_game())
		if cg then
			current_game_id = cg.id
		elseif pkgmgr and pkgmgr.games and #pkgmgr.games > 0 then
			local picked = 1
			if pkgmgr.games[1].id == "devtest" and #pkgmgr.games > 1 then
				picked = 2
			end
			current_game_id = pkgmgr.games[picked].id
		end
	end

	if current_game_id then
		if st.set then
			st.set("selected_game_id", current_game_id, true)
		else
			st.selected_game_id = current_game_id
		end
	end

	-- Ensure menudata.worldlist filter criteria is synchronized to the active game
	if menudata and menudata.worldlist and current_game_id and menudata.worldlist.set_filtercriteria then
		local cur_crit = menudata.worldlist.get_filtercriteria and menudata.worldlist:get_filtercriteria()
		if cur_crit ~= current_game_id then
			menudata.worldlist:set_filtercriteria(current_game_id)
		end
	end

	-- Select up to 2 games to display as quick-filter pills (sorted by last played, ensuring active game is shown)
	local sorted_games = (pkgmgr.get_games_by_last_played and pkgmgr.get_games_by_last_played()) or (pkgmgr.games or {})
	local active_game_obj = nil
	for _, g in ipairs(sorted_games) do
		if g.id == current_game_id then
			active_game_obj = g
			break
		end
	end

	local displayed_games = {}
	if active_game_obj then
		table.insert(displayed_games, active_game_obj)
	end
	for _, g in ipairs(sorted_games) do
		if #displayed_games >= 2 then break end
		if not active_game_obj or g.id ~= active_game_obj.id then
			table.insert(displayed_games, g)
		end
	end

	-- Sort displayed badges based on last played game
	table.sort(displayed_games, function(a, b)
		local ta = (pkgmgr.get_game_last_played and pkgmgr.get_game_last_played(a.id)) or 0
		local tb = (pkgmgr.get_game_last_played and pkgmgr.get_game_last_played(b.id)) or 0
		if ta ~= tb then
			return ta > tb
		end
		return (a.title or a.id):lower() < (b.title or b.id):lower()
	end)

	-- Filter Buttons starting at 7.85 (Matches Play Online filter tabs layout)
	local game_x = 7.85
	for _, game in ipairs(displayed_games) do
		local is_active = (game.id == current_game_id)
		local btn_name = "game_select_" .. game.id
		local title = game.title or game.id
		table.insert(fs, th.button_tab(game_x, 0.38, 1.70, 0.65, btn_name, ui_list.truncate(title, 9), is_active, title))
		game_x = game_x + 1.85
	end

	-- Change Game Grid Shortcut Button (Positioned at 11.55 when 2 games are shown)
	table.insert(fs, th.button_secondary(game_x, 0.38, 1.70, 0.65, "btn_nav_to_games", fgettext("All Games"), fgettext("Open the Game Chooser grid")))

	table.insert(fs, th.button_secondary(13.45, 0.38, 3.60, 0.65, "world_create", "+ " .. fgettext("New World"), fgettext("Create a new world")))

	-- Shortcut to ContentDB to install new games (Matches Play Online refresh button at 17.20, 0.38, 0.65, 0.65)
	table.insert(fs, th.button_icon(17.20, 0.38, 0.65, 0.65, "game_open_cdb", (defaulttexturedir or "") .. "plus.png", fgettext("Install new games from ContentDB")))

	----------------------------------------------------------------------------
	-- Main Split Area: Left = Worlds List, Right = Details & Launch
	----------------------------------------------------------------------------

	-- Filter world list based on active game and search query
	local filtered_worlds = {}
	local c_gid = nil
	local g_obj = nil
	if current_game_id and current_game_id ~= "" then
		c_gid = (pkgmgr and pkgmgr.normalize_game_id and pkgmgr.normalize_game_id(current_game_id)) or current_game_id
		g_obj = (pkgmgr and pkgmgr.find_by_gameid and pkgmgr.find_by_gameid(c_gid))
	end

	for orig_idx, w in ipairs(raw_worldlist) do
		local matches = true

		-- Ensure world belongs to selected game (or its aliases)
		if c_gid then
			local w_gid = (pkgmgr and pkgmgr.normalize_game_id and pkgmgr.normalize_game_id(w.gameid)) or (w.gameid or "")
			if w_gid ~= c_gid then
				if not (g_obj and g_obj.aliases and g_obj.aliases[w_gid]) then
					matches = false
				end
			end
		end

		if matches and query ~= "" then
			local w_name = (w.name or ""):lower()
			local w_gid = (w.gameid or ""):lower()
			for term in query:gmatch("%S+") do
				if not (w_name:find(term, 1, true) or w_gid:find(term, 1, true)) then
					matches = false
					break
				end
			end
		end
		if matches then
			local entry = {
				name = w.name,
				path = w.path,
				gameid = w.gameid,
				list_index = orig_idx,
				raw_index = (menudata and menudata.worldlist and menudata.worldlist:get_raw_index(orig_idx)) or orig_idx
			}
			table.insert(filtered_worlds, entry)
		end
	end

	-- Apply sorting
	local sort_col = (st.get and st.get("world_sort_col")) or st.world_sort_col or "name"
	local sort_dir = (st.get and st.get("world_sort_dir")) or st.world_sort_dir or "asc"
	table.sort(filtered_worlds, function(a, b)
		return compare_worlds(a, b, sort_col, sort_dir)
	end)

	-- Determine selection in filtered worlds
	local selected_filtered_row = 1
	local selected_world = nil

	if #filtered_worlds > 0 then
		local cur_path = (st.get and st.get("selected_world_path")) or st.selected_world_path
		local cur_idx = st.selected_world_index or 1

		-- Prefer matching by unique directory path if available
		if cur_path and cur_path ~= "" then
			for r_idx, w in ipairs(filtered_worlds) do
				if w.path == cur_path then
					selected_filtered_row = r_idx
					selected_world = raw_worldlist[w.list_index]
					break
				end
			end
		end

		if not selected_world then
			for r_idx, w in ipairs(filtered_worlds) do
				if w.list_index == cur_idx then
					selected_filtered_row = r_idx
					selected_world = raw_worldlist[w.list_index]
					break
				end
			end
		end

		if not selected_world then
			selected_filtered_row = 1
			selected_world = raw_worldlist[filtered_worlds[1].list_index]
			if st.set then
				st.set("selected_world_index", filtered_worlds[1].list_index, true)
			else
				st.selected_world_index = filtered_worlds[1].list_index
				if mainmenu and mainmenu.state and mainmenu.state.set then
					mainmenu.state.set("selected_world_index", filtered_worlds[1].list_index, true)
				end
			end
		end

		if selected_world and selected_world.path then
			if st.set then
				st.set("selected_world_path", selected_world.path, true)
			else
				st.selected_world_path = selected_world.path
			end
		end
		menudata.selected_world = selected_world
	end

	-- Left Panel: World List (Width: 11.9, Height: 10.45, matching Play Online)
	table.insert(fs, th.voxel_box(0.35, 1.30, 11.9, 10.45, th.colors.card_bg))

	local vp = th.get_viewport_info()
	local is_compact = vp.is_compact
	local cols = ui_list.get_columns("local", is_compact)

	-- Header Bar with clickable sort buttons
	ui_list.render_header(fs, {
		x = 0.45,
		y = 1.35,
		w = 11.60,
		h = 0.44,
		columns = cols,
		sort_col = sort_col,
		sort_dir = sort_dir,
		btn_prefix = "btn_sort_world_",
		th = th,
	})

	-- Scrollable List Container (Width: 11.25, leaving 0.35 margin for scrollbar at 11.75)
	local scroll_val = (st.get and st.get("local_worlds_scroll")) or st.local_worlds_scroll or 0
	ui_list.render_scroll_start(fs, 0.45, 1.85, 11.25, 9.75, "local_worlds_scroll", 0.1, 0.25)

	local cur_y = 0.0
	local row_w = 11.25
	local row_h = 0.48

	menudata.world_lookup = {}

	if #filtered_worlds > 0 then
		for r_idx, w in ipairs(filtered_worlds) do
			menudata.world_lookup[r_idx] = w
			local is_selected = (r_idx == selected_filtered_row)
			local winfo = get_world_info(w)
			local world_game = pkgmgr.find_by_gameid(w.gameid)
			local g_title = (world_game and world_game.title) or w.gameid
			local icon = (world_game and ((world_game.menuicon_path ~= "" and world_game.menuicon_path) or (world_game.icon_path ~= "" and world_game.icon_path))) or (defaulttexturedir .. "blank.png")

			local cells
			if is_compact then
				cells = {
					{ type = "icon", x = 0.00, w = 0.40, texture = icon, icon_w = 0.32, icon_h = 0.32, pad_x = 0.05, pad_y = 0.08, tooltip = g_title },
					{ type = "text", x = 0.40, w = 4.10, text = w.name, color = is_selected and th.colors.brand_green_hover or th.colors.text_primary, font_weight = "bold", max_chars = 26, pad_x = 0.05, tooltip = string.format("%s\n%s", w.name, winfo.path or "") },
					{ type = "text", x = 4.50, w = 2.40, text = g_title, color = th.colors.brand_green_hover, font_weight = "normal", max_chars = 15, pad_x = 0.05, tooltip = fgettext("Game: $1", g_title) },
					{ type = "text", x = 6.90, w = 1.40, text = winfo.mods_str, color = (winfo.mods_count > 0 and th.colors.brand_green_hover or th.colors.text_muted), font_weight = "bold", max_chars = 7, pad_x = 0.05, tooltip = fgettext("Enabled Mods: $1", winfo.mods_str) },
					{
						type = "text",
						x = 8.30,
						w = 2.95,
						text = winfo.last_played_str,
						color = th.colors.text_primary,
						font_weight = "normal",
						max_chars = 18,
						pad_x = 0.05,
						tooltip = (winfo.last_played_ts and winfo.last_played_ts > 0)
							and fgettext("Last Played: $1", winfo.last_played_full or ui_list.format_timestamp_full(winfo.last_played_ts))
							or fgettext("Never played"),
					},
				}
			else
				cells = {
					{ type = "icon", x = 0.00, w = 0.35, texture = icon, icon_w = 0.28, icon_h = 0.28, pad_x = 0.05, pad_y = 0.10, tooltip = g_title },
					{ type = "text", x = 0.35, w = 2.15, text = w.name, color = is_selected and th.colors.brand_green_hover or th.colors.text_primary, font_weight = "bold", max_chars = 15, pad_x = 0.05, tooltip = string.format("%s\n%s", w.name, winfo.path or "") },
					{ type = "text", x = 2.50, w = 2.00, text = g_title, color = th.colors.brand_green_hover, font_weight = "normal", max_chars = 14, pad_x = 0.05, tooltip = fgettext("Game: $1", g_title) },
					{ type = "text", x = 4.50, w = 1.35, text = winfo.mg_name, color = th.colors.text_muted, font_weight = "normal", max_chars = 10, pad_x = 0.05, tooltip = fgettext("Map Generator: $1", winfo.mg_name) },
					{ type = "text", x = 5.85, w = 0.85, text = winfo.version, color = th.colors.text_muted, font_weight = "normal", max_chars = 7, pad_x = 0.05, tooltip = fgettext("Target Engine: $1", winfo.version) },
					{ type = "text", x = 6.70, w = 0.90, text = winfo.mods_str, color = (winfo.mods_count > 0 and th.colors.brand_green_hover or th.colors.text_muted), font_weight = "bold", max_chars = 6, pad_x = 0.05, tooltip = fgettext("Enabled Mods: $1", winfo.mods_str) },
					{ type = "text", x = 7.60, w = 1.15, text = winfo.size_str, color = th.colors.text_muted, font_weight = "normal", max_chars = 8, pad_x = 0.05, tooltip = fgettext("Disk Size: $1", winfo.size_str) },
					{
						type = "text",
						x = 8.75,
						w = 2.50,
						text = winfo.last_played_str,
						color = th.colors.text_primary,
						font_weight = "normal",
						max_chars = 16,
						pad_x = 0.05,
						tooltip = (winfo.last_played_ts and winfo.last_played_ts > 0)
							and fgettext("Last Played: $1", winfo.last_played_full or ui_list.format_timestamp_full(winfo.last_played_ts))
							or fgettext("Never played"),
					},
				}
			end

			ui_list.render_row(fs, {
				y = cur_y,
				w = row_w,
				h = row_h,
				btn_name = "btn_world_row_" .. r_idx,
				is_selected = is_selected,
				is_even = (r_idx % 2 == 0),
				tooltip = string.format("%s (%s)\n%s: %s", w.name, g_title, fgettext("Last Played"), winfo.last_played_str),
				th = th,
				cells = cells,
			})

			cur_y = cur_y + row_h
		end
	else
		local empty_msg = (query ~= "") and fgettext("No worlds matching '$1'", query:sub(1, 16)) or fgettext("No worlds found")
		ui_list.render_empty(fs, 0.0, row_w, 9.75, empty_msg, (query ~= "") and "btn_world_clear", th)
		cur_y = 4.0
	end

	ui_list.render_scroll_end(fs, {
		visible_h = 9.75,
		total_h = cur_y,
		scroll_val = scroll_val,
		bar_x = 11.75,
		bar_y = 1.85,
		bar_w = 0.25,
		bar_h = 9.75,
		scroll_name = "local_worlds_scroll",
		scroll_factor = 0.1,
	})

	----------------------------------------------------------------------------
	-- Right Panel: World Details & Actions (Width: 5.60, Height: 10.45, matching Play Online)
	----------------------------------------------------------------------------
	table.insert(fs, th.voxel_box(12.40, 1.30, 5.60, 10.45, th.colors.card_bg))

	if selected_world then
		local winfo = get_world_info(selected_world)
		local world_game = pkgmgr.find_by_gameid(selected_world.gameid)
		local game_title = (world_game and world_game.title) or selected_world.gameid

		-- World Title & Game
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("title"), th.colors.brand_green_hover))
		local title_display = winfo.name
		if #title_display > 24 then
			title_display = title_display:sub(1, 23) .. "…"
		end
		table.insert(fs, string.format("label[12.60,1.52;%s]", core.formspec_escape(title_display)))
		table.insert(fs, th.tooltip_area(12.60, 1.35, 5.20, 0.40, winfo.name))
		table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("body"), th.colors.text_muted))
		table.insert(fs, string.format("label[12.60,1.86;%s: %s | %s: %s]",
			core.formspec_escape(fgettext("Game")), core.formspec_escape(game_title:sub(1, 15)),
			core.formspec_escape(fgettext("Ver")), core.formspec_escape(winfo.version)
		))
		table.insert(fs, string.format("label[12.60,2.16;%s: %s | %s: %s]",
			core.formspec_escape(fgettext("Mapgen")), core.formspec_escape(winfo.mg_name),
			core.formspec_escape(fgettext("Storage")), core.formspec_escape(winfo.backend)
		))
		table.insert(fs, string.format("label[12.60,2.46;%s: %s | %s: %s]",
			core.formspec_escape(fgettext("Mods")), core.formspec_escape(winfo.mods_str),
			core.formspec_escape(fgettext("Size")), core.formspec_escape(winfo.size_str)
		))

		-- World Preview Screenshot or Voxel Card
		table.insert(fs, th.inner_card(12.60, 2.75, 5.20, 2.65))
		if winfo.screenshot then
			table.insert(fs, string.format("image[12.60,2.75;5.20,2.65;%s]", core.formspec_escape(winfo.screenshot)))
		elseif world_game and (world_game.menuicon_path or "") ~= "" then
			table.insert(fs, string.format("image[14.20,3.05;2.0,2.0;%s]", core.formspec_escape(world_game.menuicon_path)))
		else
			table.insert(fs, string.format("image[14.20,3.05;2.0,2.0;%s]", core.formspec_escape((defaulttexturedir or "") .. "logo.png")))
		end

		-- Gameplay Options Pill Toggle Switches
		table.insert(fs, th.toggle_switch(12.60, 5.55, 5.20, 0.38, "cb_creative_mode",
			fgettext("Creative Mode"),
			st.creative_mode,
			fgettext("Play with unlimited resources, instant digging, and flying enabled")
		))

		table.insert(fs, th.toggle_switch(12.60, 6.00, 5.20, 0.38, "cb_enable_damage",
			fgettext("Enable Damage"),
			st.enable_damage,
			fgettext("Enable health reduction from monsters, falls, fire, and drowning")
		))

		table.insert(fs, th.toggle_switch(12.60, 6.45, 5.20, 0.38, "cb_enable_server",
			fgettext("Host Server (Multiplayer)"),
			st.is_hosting,
			fgettext("Host this world as a local server for other players to join")
		))

		-- Host Server specific inputs if enabled
		if st.is_hosting then
			local cur_host_focus = st.focused_field
			if not cur_host_focus then
				cur_host_focus = (st.player_name and st.player_name ~= "") and "te_passwd" or "te_playername"
			end
			local is_host_name_focused = (cur_host_focus == "te_playername")
			local is_host_pwd_focused = (cur_host_focus == "te_passwd")

			local host_inp_y = 7.40

			-- Explicit style for host inputs
			table.insert(fs, string.format("style[te_playername,te_passwd;border=false;textcolor=%s;font=normal;%s]",
				th.colors.text_primary, th.font_size("body")))
			table.insert(fs, string.format("style[te_playername:focused,te_passwd:focused;border=false;textcolor=%s;bgcolor=%s;font=normal;%s]",
				th.colors.text_primary, th.colors.input_bg_focused, th.font_size("body")))

			table.insert(fs, th.text_input(12.60, host_inp_y, 2.50, 0.60, "te_playername", "", st.player_name, is_host_name_focused, fgettext("Your multiplayer player name"), fgettext("Host Name"), "btn_focus_host_name"))
			table.insert(fs, th.password_input(15.30, host_inp_y, 2.50, 0.60, "te_passwd", "", is_host_pwd_focused, fgettext("Enter server account password"), fgettext("Password"), "btn_focus_host_pwd"))
		else
			-- World Info Badge with Open Folder button
			table.insert(fs, th.inner_card(12.60, 7.08, 5.20, 0.85))
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.brand_green_hover))
			local folder_display = winfo.name
			if #folder_display > 15 then
				folder_display = folder_display:sub(1, 14) .. "…"
			end
			table.insert(fs, string.format("label[12.75,7.50;%s: %s]", core.formspec_escape(fgettext("World Folder")), core.formspec_escape(folder_display)))
			table.insert(fs, th.tooltip_area(12.60, 7.08, 3.10, 0.85, winfo.path or winfo.name))
			table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("body"), th.colors.text_muted))

			-- Open Folder button (translucent voxel button matching theme)
			table.insert(fs, th.button_secondary(15.80, 7.25, 1.85, 0.51, "btn_open_world_folder",
				fgettext("Open Folder"),
				fgettext("Open world save folder in file manager"),
				false,
				th.font_size("caption")
			))
		end

		-- Big Prominent Launch Button
		local play_label = st.is_hosting and fgettext("HOST GAME") or fgettext("PLAY WORLD")
		table.insert(fs, th.button_primary(12.60, 8.16, 5.20, 0.90, "play_world", play_label, fgettext("Launch and enter this world")))

		-- Secondary Management Action Buttons
		local sec_y = 9.24
		table.insert(fs, th.button_secondary(12.60, sec_y, 1.65, 0.65, "world_configure", fgettext("Mods"), fgettext("Enable or disable mods for this world")))
		table.insert(fs, th.button_secondary(14.37, sec_y, 1.65, 0.65, "world_create", "+ " .. fgettext("New"), fgettext("Create a new world")))
		table.insert(fs, th.button_danger(16.15, sec_y, 1.65, 0.65, "world_delete", fgettext("Delete"), fgettext("Permanently delete this world")))

		-- Play Time and Last Played footnote
		table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
		table.insert(fs, string.format("label[12.60,10.18;%s: %s | %s: %s]",
			core.formspec_escape(fgettext("Played")), core.formspec_escape(winfo.play_time_str),
			core.formspec_escape(fgettext("Last")), core.formspec_escape(winfo.last_played_str)
		))
		table.insert(fs, th.tooltip_area(12.60, 10.05, 5.20, 0.40,
			string.format("%s: %s\n%s: %s",
				fgettext("Total In-Game Time"), winfo.play_time_str,
				fgettext("Last Played"), winfo.last_played_full or winfo.last_played_str)
		))
	else
		-- Empty State
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("title"), th.colors.text_muted))
		table.insert(fs, string.format("label[13.10,4.5;%s]", core.formspec_escape(fgettext("No world selected"))))
		table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("body"), th.colors.text_muted))
		table.insert(fs, string.format("label[13.10,5.0;%s]", core.formspec_escape(fgettext("Create a new world to get started!"))))
		table.insert(fs, th.button_primary(13.10, 5.8, 4.2, 0.9, "world_create", fgettext("Create New World"), fgettext("Create a new world")))
	end

	table.insert(fs, "container_end[]")
	return table.concat(fs, "")
end

return view_local
