-- Luanti Main Menu Redesign
-- Game Chooser View Component (Formspec Version 7)

local view_games = {}

local function get_world_count_for_game(gameid)
	if not menudata.worldlist or not gameid then return 0 end
	local norm_target = pkgmgr.normalize_game_id(gameid)
	local count = 0
	local list = (menudata.worldlist.get_raw_list and menudata.worldlist:get_raw_list()) or menudata.worldlist:get_list() or {}
	for _, w in ipairs(list) do
		if w.gameid and pkgmgr.normalize_game_id(w.gameid) == norm_target then
			count = count + 1
		end
	end
	return count
end

local function get_game_description(game)
	if not game then return "" end
	if game._cached_desc then
		return game._cached_desc
	end
	if game.description and game.description ~= "" then
		game._cached_desc = game.description
		return game.description
	end
	if game.desc and game.desc ~= "" then
		game._cached_desc = game.desc
		return game.desc
	end
	if game.path then
		local conf = Settings(game.path .. "/game.conf")
		local d = conf and conf:get("description")
		if d and d ~= "" then
			game._cached_desc = d
			return d
		end
	end
	local def = fgettext("No description provided for this game.")
	game._cached_desc = def
	return def
end

local function get_quick_connect_icon(session_type, s_addr, s_port, rw_game)
	local menupath = custom_menupath or (core and core.get_mainmenu_path and core.get_mainmenu_path()) or "."
	local sep = (menupath:sub(-1) == "/" or menupath:sub(-1) == "\\") and "" or (DIR_DELIM or "/")
	local tex_dir = menupath .. sep .. "textures" .. (DIR_DELIM or "/")

	if session_type == "server" and s_addr and s_addr ~= "" then
		local clean_addr = s_addr:lower():gsub("%s+", "")
		-- 1. Localhost / Loopback
		if clean_addr == "127.0.0.1" or clean_addr == "localhost" or clean_addr == "::1" or clean_addr == "0.0.0.0" or clean_addr:find("^127%.") then
			return tex_dir .. "icon_localhost.png"
		end
		-- 2. LAN / Private Subnets (192.168.x, 10.x, 172.16-31.x, .local)
		if clean_addr:find("^192%.168%.") or clean_addr:find("^10%.") or clean_addr:match("%.local$") then
			return tex_dir .. "icon_lan_server.png"
		end
		local oct1, oct2 = clean_addr:match("^(%d+)%.(%d+)%.")
		if oct1 == "172" then
			local o2 = tonumber(oct2)
			if o2 and o2 >= 16 and o2 <= 31 then
				return tex_dir .. "icon_lan_server.png"
			end
		end
		-- 3. Favorite Server
		if serverlistmgr and serverlistmgr.get_favorites then
			local favs = serverlistmgr.get_favorites() or {}
			for _, f in ipairs(favs) do
				local f_addr = (f.address or ""):lower():gsub("%s+", "")
				if f_addr == clean_addr and (not s_port or not f.port or tonumber(f.port) == tonumber(s_port)) then
					return tex_dir .. "icon_favorite_server.png"
				end
			end
		end
		-- 4. Default Remote Server
		return tex_dir .. "icon_remote_server.png"
	end

	-- Local singleplayer game / world
	if rw_game and (rw_game.menuicon_path or "") ~= "" then
		local f = io.open(rw_game.menuicon_path, "r")
		if f then
			f:close()
			return rw_game.menuicon_path
		end
	end
	return tex_dir .. "icon_local_game.png"
end
view_games.get_quick_connect_icon = get_quick_connect_icon

function view_games.render(st, th)
	if not pkgmgr.games then
		pkgmgr.load_all()
	end

	local fs = {}
	table.insert(fs, "container[3.3,0]")

	-- Main content background (Width: 18.3, Height: 12.0)
	table.insert(fs, string.format("box[0,0;18.3,12.0;%s]", th.colors.backdrop))

	----------------------------------------------------------------------------
	-- Top Row: Host Game | Join Game | Quick-Resume Hero Card
	----------------------------------------------------------------------------
	table.insert(fs, th.voxel_box(0.35, 0.25, 17.65, 1.35, th.colors.card_bg))

	table.insert(fs, th.button_secondary(0.6, 0.45, 3.6, 0.92, "btn_chooser_host", fgettext("Host Game"), fgettext("Host a multiplayer game or server")))
	table.insert(fs, th.button_secondary(4.4, 0.45, 3.6, 0.92, "btn_chooser_join", fgettext("Join Online"), fgettext("Play online and join public servers")))

	-- Find recent session for 1-click Resume Adventure
	local session_type = core.settings:get("mainmenu_last_session_type")
	if not session_type then
		local s_addr = core.settings:get("mainmenu_last_server_address") or core.settings:get("address")
		if s_addr and s_addr ~= "" then
			session_type = "server"
		else
			session_type = "local"
		end
	end

	local has_resume = false

	if session_type == "server" then
		local s_addr = core.settings:get("mainmenu_last_server_address") or core.settings:get("address")
		local s_port = tonumber(core.settings:get("mainmenu_last_server_port") or core.settings:get("remote_port")) or 30000
		local s_name = core.settings:get("mainmenu_last_server_name")
		if s_addr and s_addr ~= "" then
			if not s_name or s_name == "" or s_name == s_addr then
				if s_addr == "127.0.0.1" or s_addr:lower() == "localhost" or s_addr == "::1" then
					s_name = "Localhost Server"
				else
					if serverlistmgr and serverlistmgr.servers then
						for _, s in ipairs(serverlistmgr.servers) do
							if s.address == s_addr and s.port == s_port and s.name and s.name ~= "" then
								s_name = s.name
								break
							end
						end
					end
					if (not s_name or s_name == "") and serverlistmgr and serverlistmgr.get_favorites then
						for _, s in ipairs(serverlistmgr.get_favorites()) do
							if s.address == s_addr and s.port == s_port and s.name and s.name ~= "" then
								s_name = s.name
								break
							end
						end
					end
				end
			end

			local display_name = (s_name and s_name ~= "") and s_name or s_addr
			if display_name == "127.0.0.1" or display_name:lower() == "localhost" or display_name == "::1" then
				display_name = "Localhost Server"
			end
			local player_name = core.settings:get("name") or (st and st.player_name) or "Player"
			local s_icon = get_quick_connect_icon("server", s_addr, s_port, nil)

			table.insert(fs, th.voxel_box(8.3, 0.35, 9.45, 1.15, th.colors.card_inner_bg, th.colors.brand_cyan, th.colors.card_border_dark))
			table.insert(fs, string.format("image[8.45,0.45;0.95,0.95;%s]", core.formspec_escape(s_icon)))
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), th.colors.brand_cyan))
			table.insert(fs, string.format("label[9.55,0.58;%s: %s]", core.formspec_escape(fgettext("Resume")), core.formspec_escape(display_name:sub(1, 20))))
			local sub_text = player_name .. " @ " .. s_addr .. ":" .. tostring(s_port)
			if #sub_text > 40 then
				sub_text = sub_text:sub(1, 39) .. "…"
			end
			table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
			table.insert(fs, string.format("label[9.55,1.02;%s]", core.formspec_escape(sub_text)))

			table.insert(fs, th.button_primary(14.65, 0.45, 2.95, 0.95, "btn_resume_adventure", fgettext("▶ RESUME"), fgettext("Connect and resume playing on '$1'", display_name)))
			has_resume = true
		end
	end

	if not has_resume then
		local recent_world = nil
		if menudata.worldlist then
			local last_raw = tonumber(core.settings:get("mainmenu_last_selected_world"))
			if last_raw and last_raw > 0 and menudata.worldlist.get_raw_element and menudata.worldlist:get_raw_element(last_raw) then
				recent_world = menudata.worldlist:get_raw_element(last_raw)
			else
				local wlist = (menudata.worldlist.get_raw_list and menudata.worldlist:get_raw_list()) or menudata.worldlist:get_list()
				if wlist and #wlist > 0 then
					recent_world = wlist[1]
				end
			end
		end

		if recent_world then
			local rw_game = pkgmgr.find_by_gameid(recent_world.gameid)
			local rw_gtitle = (rw_game and rw_game.title) or recent_world.gameid
			local rw_icon = get_quick_connect_icon("local", nil, nil, rw_game)

			table.insert(fs, th.voxel_box(8.3, 0.35, 9.45, 1.15, th.colors.card_active_bg, th.colors.brand_green, th.colors.brand_green_dark))
			table.insert(fs, string.format("image[8.45,0.45;0.95,0.95;%s]", core.formspec_escape(rw_icon)))
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), th.colors.brand_green_hover))
			table.insert(fs, string.format("label[9.55,0.58;%s: %s]", core.formspec_escape(fgettext("Resume")), core.formspec_escape(recent_world.name:sub(1, 20))))
			table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
			table.insert(fs, string.format("label[9.55,1.02;%s]", core.formspec_escape(rw_gtitle:sub(1, 24))))

			table.insert(fs, th.button_primary(14.65, 0.45, 2.95, 0.95, "btn_resume_adventure", fgettext("▶ RESUME"), fgettext("Continue playing your most recent world immediately")))
			has_resume = true
		end
	end

	if not has_resume then
		table.insert(fs, th.button_secondary(8.3, 0.45, 9.45, 0.92, "open_settings", fgettext("Settings & Preferences"), fgettext("Configure engine, graphics, and controls")))
	end

	----------------------------------------------------------------------------
	-- Section Header
	----------------------------------------------------------------------------
	table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("title"), th.colors.brand_green_hover))
	table.insert(fs, string.format("label[0.45,1.85;%s]", th.escape_once(fgettext("CHOOSE A GAME"))))
	table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("body"), th.colors.text_muted))
	table.insert(fs, string.format("label[0.45,2.25;%s]", th.escape_once(fgettext("Choose an installed game to play singleplayer, or discover new games from ContentDB"))))

	----------------------------------------------------------------------------
	-- Center Grid: Installed Games + ContentDB Card (4 Columns, Scrollable)
	----------------------------------------------------------------------------
	local current_game_id = (st.get and st.get("selected_game_id")) or st.selected_game_id or core.settings:get("menu_last_game")
	local active_game_obj = nil
	if current_game_id and pkgmgr and pkgmgr.find_by_gameid then
		active_game_obj = pkgmgr.find_by_gameid(current_game_id)
	end

	-- Maintain a stable grid order during the current menu session so clicking doesn't jump cards
	if not view_games._session_games_list or #view_games._session_games_list ~= #(pkgmgr.games or {}) then
		view_games._session_games_list = (pkgmgr.get_games_by_last_played and pkgmgr.get_games_by_last_played()) or (pkgmgr.games or {})
	end
	local games_list = view_games._session_games_list
	local games_scroll = (st.get and st.get("games_scroll")) or st.games_scroll or 0

	local total_items = #games_list -- Installed games only (ContentDB moved to bottom action bar)
	local total_rows = math.ceil(math.max(1, total_items) / 4)
	local needs_scroll = (total_rows > 2)

	local card_w = needs_scroll and 4.05 or 4.15
	local card_h = 3.35
	local start_x = 0.00
	local start_y = 0.05
	local gap_x = 0.35
	local gap_y = 0.25

	local sc_x = 0.35
	local sc_y = 2.60
	local sc_w = needs_scroll and 17.25 or 17.65
	local sc_h = 7.45

	local current_game_obj = nil
	local detailed_game_obj = nil

	-- Begin Scroll Container for games grid
	table.insert(fs, string.format("scroll_container[%.2f,%.2f;%.2f,%.2f;games_scroll;vertical;0.1;0.25]", sc_x, sc_y, sc_w, sc_h))

	for idx, game in ipairs(games_list) do
		local col = ((idx - 1) % 4) + 1
		local row = math.floor((idx - 1) / 4) + 1
		local cx = start_x + (col - 1) * (card_w + gap_x)
		local cy = start_y + (row - 1) * (card_h + gap_y)

		local is_active = false
		if active_game_obj and active_game_obj.id == game.id then
			is_active = true
		elseif game.id == current_game_id then
			is_active = true
		elseif pkgmgr and pkgmgr.normalize_game_id and current_game_id then
			is_active = (pkgmgr.normalize_game_id(game.id) == pkgmgr.normalize_game_id(current_game_id))
		end

		if is_active then
			current_game_obj = game
		end
		local viewing_details_id = st.get and st.get("viewing_game_details") or st.viewing_game_details
		if viewing_details_id == game.id then
			detailed_game_obj = game
		end

		local btn_name = "btn_choose_game_" .. game.id
		local btn_info_name = "btn_game_info_" .. game.id
		local select_btn_name = "game_select_" .. game.id
		local title = game.title or game.id
		local icon = defaulttexturedir .. "logo.png"
		if (game.menuicon_path or "") ~= "" then
			icon = game.menuicon_path
		elseif (game.icon_path or "") ~= "" then
			icon = game.icon_path
		end

		if is_active then
			-- Active green highlight card (rich glowing emerald glass)
			local active_card_bg = "#123d24aa"
			table.insert(fs, string.format("box[%f,%f;%f,%f;%s]", cx, cy, card_w, card_h, active_card_bg))
			-- Prominent voxel emerald borders on all 4 edges
			table.insert(fs, string.format("box[%f,%f;%f,0.055;%s]", cx, cy, card_w, th.colors.brand_green_hover))
			table.insert(fs, string.format("box[%f,%f;0.055,%f;%s]", cx, cy, card_h, th.colors.brand_green_hover))
			table.insert(fs, string.format("box[%f,%f;%f,0.055;%s]", cx, cy + card_h - 0.055, card_w, th.colors.brand_green_dark))
			table.insert(fs, string.format("box[%f,%f;0.055,%f;%s]", cx + card_w - 0.055, cy, card_h, th.colors.brand_green))
			-- Luminous top accent bar
			table.insert(fs, string.format("box[%f,%f;%f,0.08;%s]", cx, cy, card_w, th.colors.brand_green_light))
		else
			table.insert(fs, th.voxel_box(cx, cy, card_w, card_h, th.colors.card_bg, th.colors.card_border_light, th.colors.card_border_dark))
		end

		-- Whole-card clickable button overlay (covers upper interactive area, leaving bottom buttons accessible)
		table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000]", select_btn_name))
		table.insert(fs, string.format("style[%s:hovered;border=false;bgcolor=#3e6c9c22]", select_btn_name))
		table.insert(fs, string.format("style[%s:pressed;border=false;bgcolor=#1d365044]", select_btn_name))
		table.insert(fs, string.format("button[%f,%f;%f,2.70;%s;]", cx, cy, card_w, select_btn_name))
		table.insert(fs, th.tooltip(select_btn_name, is_active and fgettext("'$1' is currently active", title) or fgettext("Click to activate '$1'", title)))

		-- Game Icon (Horizontally Centered in Card)
		local icon_x = cx + (card_w - 1.4) / 2
		table.insert(fs, string.format("image[%f,%f;1.4,1.4;%s]", icon_x, cy + 0.45, core.formspec_escape(icon)))

		-- Game Title & Subtitle
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), (is_active and th.colors.brand_green_hover or th.colors.text_primary)))
		table.insert(fs, string.format("label[%f,%f;%s]", cx + 0.3, cy + 2.05, core.formspec_escape(title:sub(1, 20))))

		table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), (is_active and th.colors.brand_green_light or th.colors.text_muted)))
		local subtitle = (game.author and ("by " .. game.author:sub(1, 18))) or game.id
		table.insert(fs, string.format("label[%f,%f;%s]", cx + 0.3, cy + 2.42, core.formspec_escape(subtitle)))

		-- Dual Action Buttons: ACTIVATE/CURRENT + More Info
		local btn_label = is_active and ("✓ " .. fgettext("CURRENT")) or fgettext("ACTIVATE")
		local btn_act_w = needs_scroll and 2.55 or 2.65
		local btn_info_w = needs_scroll and 0.95 or 1.00
		local info_x = cx + 0.25 + btn_act_w + 0.05
		local tip_txt = is_active and fgettext("'$1' is currently active", title)
			or fgettext("Activate '$1' as your current game", title)

		table.insert(fs, th.button_tab(cx + 0.25, cy + 2.78, btn_act_w, 0.44, btn_name, btn_label, is_active, tip_txt, nil, th.font_size("caption")))
		table.insert(fs, th.button_secondary(info_x, cy + 2.78, btn_info_w, 0.44, btn_info_name, "ℹ Info", fgettext("View description and details for '$1'", title), false, th.font_size("caption")))
	end

	if #games_list == 0 then
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), th.colors.text_muted))
		table.insert(fs, string.format("label[4.50,4.50;%s]", core.formspec_escape(fgettext("No games installed yet."))))
		table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("body"), th.colors.text_dim))
		table.insert(fs, string.format("label[4.50,5.00;%s]", core.formspec_escape(fgettext("Use 'Get More Games' below or browse ContentDB to install your first game."))))
	end

	-- Close Scroll Container
	table.insert(fs, "scroll_container_end[]")

	-- Scrollbar alongside the grid when content exceeds visible viewport
	local total_content_h = start_y + total_rows * card_h + (total_rows - 1) * gap_y + 0.10
	if needs_scroll then
		local scroll_factor = 0.1
		local max_scroll_dist = math.max(0, total_content_h - sc_h)
		local scroll_max = math.max(10, math.ceil(max_scroll_dist / scroll_factor))
		local thumb_size = math.max(10, math.floor(sc_h / scroll_factor))
		local clamped_scroll = math.min(math.max(0, games_scroll), scroll_max)

		table.insert(fs, string.format("scrollbaroptions[min=0;max=%d;smallstep=5;largestep=25;thumbsize=%d]", scroll_max, thumb_size))
		table.insert(fs, string.format("scrollbar[17.70,%.2f;0.30,%.2f;vertical;games_scroll;%d]", sc_y, sc_h, clamped_scroll))
	end

	----------------------------------------------------------------------------
	-- Bottom Action Row: Active Game Card & Inherited ContentDB Card
	----------------------------------------------------------------------------
	-- Resolve active game object if not matched in loop
	if not current_game_obj and current_game_id and pkgmgr.find_by_gameid then
		current_game_obj = pkgmgr.find_by_gameid(current_game_id)
	end

	local active_game_title = (current_game_obj and current_game_obj.title) or (current_game_id or "Luanti")
	local active_world_count = get_world_count_for_game(current_game_id)
	local active_game_icon = defaulttexturedir .. "logo.png"
	if current_game_obj then
		if (current_game_obj.menuicon_path or "") ~= "" then
			active_game_icon = current_game_obj.menuicon_path
		elseif (current_game_obj.icon_path or "") ~= "" then
			active_game_icon = current_game_obj.icon_path
		end
	end

	local display_title = active_game_title
	if #display_title > 22 then
		display_title = display_title:sub(1, 21) .. "…"
	end

	local world_copy
	if active_world_count == 0 then
		world_copy = fgettext("No saved worlds yet • Ready to play")
	elseif active_world_count == 1 then
		world_copy = fgettext("1 saved world • Ready to play")
	else
		world_copy = fgettext("$1 saved worlds • Ready to play", tostring(active_world_count))
	end

	-- Card 1 (Left): Active Game & Singleplayer Launch
	table.insert(fs, th.voxel_box(0.35, 10.25, 10.25, 1.35, th.colors.card_bg))
	table.insert(fs, string.format("image[0.55,10.42;1.00,1.00;%s]", core.formspec_escape(active_game_icon)))

	table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.brand_green_hover))
	table.insert(fs, string.format("label[1.70,10.48;%s]", core.formspec_escape(fgettext("ACTIVE GAME"))))

	table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), th.colors.text_primary))
	table.insert(fs, string.format("label[1.70,10.78;%s]", core.formspec_escape(display_title)))

	table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
	table.insert(fs, string.format("label[1.70,11.16;%s]", core.formspec_escape(world_copy)))
	table.insert(fs, th.button_primary(6.75, 10.45, 3.65, 0.95, "btn_chooser_singleplayer", "  " .. fgettext("SINGLEPLAYER  ▶"), fgettext("Start singleplayer with the active game and view saved worlds")))

	-- Card 2 (Right): Inherited Get More Games / Browse ContentDB Tile
	table.insert(fs, th.voxel_box(10.80, 10.25, 7.20, 1.35, th.colors.card_inner_bg, th.colors.brand_cyan, th.colors.card_border_dark))
	table.insert(fs, string.format("image[11.00,10.45;0.95,0.95;%s]", core.formspec_escape(defaulttexturedir .. "plus.png")))

	table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), th.colors.brand_cyan))
	table.insert(fs, string.format("label[12.15,10.58;%s]", core.formspec_escape(fgettext("GET MORE GAMES"))))

	table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
	table.insert(fs, string.format("label[12.15,11.00;%s]", core.formspec_escape(fgettext("Browse ContentDB online"))))

	table.insert(fs, th.button_secondary(15.15, 10.45, 2.65, 0.95, "btn_chooser_cdb", fgettext("BROWSE"), fgettext("Browse and install community games from ContentDB"), false, th.font_size("caption")))

	----------------------------------------------------------------------------
	-- Expandable Game Details Modal Overlay (if open)
	----------------------------------------------------------------------------
	if detailed_game_obj then
		table.insert(fs, "box[0,0;18.3,12.0;#07121bcc]") -- backdrop overlay
		table.insert(fs, th.voxel_box(3.15, 1.5, 12.0, 9.0, th.colors.card_bg, th.colors.brand_green, th.colors.brand_green_dark))
		table.insert(fs, string.format("box[3.15,1.5;12.0,0.06;%s]", th.colors.brand_green_hover))

		local d_title = detailed_game_obj.title or detailed_game_obj.id
		local d_author = detailed_game_obj.author or fgettext("Unknown")
		local d_desc = get_game_description(detailed_game_obj)
		local d_icon = defaulttexturedir .. "logo.png"
		if (detailed_game_obj.menuicon_path or "") ~= "" then
			d_icon = detailed_game_obj.menuicon_path
		elseif (detailed_game_obj.icon_path or "") ~= "" then
			d_icon = detailed_game_obj.icon_path
		end

		table.insert(fs, string.format("image[3.55,1.85;1.8,1.8;%s]", core.formspec_escape(d_icon)))
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("title"), th.colors.brand_green_hover))
		table.insert(fs, string.format("label[5.65,2.10;%s]", core.formspec_escape(d_title)))
		table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("body"), th.colors.text_muted))
		table.insert(fs, string.format("label[5.65,2.60;%s: %s | %s: %s]",
			core.formspec_escape(fgettext("Author")), core.formspec_escape(d_author),
			core.formspec_escape(fgettext("Game ID")), core.formspec_escape(detailed_game_obj.id)))

		-- Description Textarea
		table.insert(fs, th.voxel_box(3.55, 3.90, 11.2, 5.2, th.colors.card_inner_bg))
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_primary))
		table.insert(fs, string.format("label[3.75,4.15;%s]", core.formspec_escape(fgettext("Game Description & Information:"))))
		table.insert(fs, string.format("textarea[3.75,4.60;10.8,4.3;;;%s]", core.formspec_escape(d_desc)))

		local is_d_active = (active_game_obj and active_game_obj.id == detailed_game_obj.id)
			or (detailed_game_obj.id == current_game_id)
			or (pkgmgr and pkgmgr.normalize_game_id and current_game_id and pkgmgr.normalize_game_id(detailed_game_obj.id) == pkgmgr.normalize_game_id(current_game_id))
		if not is_d_active then
			local sel_name = "btn_choose_game_" .. detailed_game_obj.id
			table.insert(fs, th.button_primary(3.55, 9.40, 6.8, 0.85, sel_name, fgettext("ACTIVATE GAME")))
		end
		local close_x = is_d_active and 3.55 or 10.65
		local close_w = is_d_active and 11.2 or 4.10
		table.insert(fs, th.button_secondary(close_x, 9.40, close_w, 0.85, "btn_close_game_details", fgettext("✕ Close")))
	end

	table.insert(fs, "container_end[]")
	return table.concat(fs, "")
end

return view_games
