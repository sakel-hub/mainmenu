-- Luanti Main Menu Redesign
-- Discrete Action & Event Dispatcher

local dispatcher = {}

local function configure_selected_world(idx)
	local list = menudata.worldlist:get_list()
	if list and list[idx] then
		local worldconfig = pkgmgr.get_worldconfig(list[idx].path)
		if worldconfig then
			if worldconfig.creative_mode ~= nil then
				core.settings:set("creative_mode", worldconfig.creative_mode)
			end
			if worldconfig.enable_damage ~= nil then
				core.settings:set("enable_damage", worldconfig.enable_damage)
			end
		end
	end
end

local function launch_selected_world(st)
	local list = menudata.worldlist:get_list()
	local idx = st.selected_world_index or 1
	local world = list[idx]
	if not world then return end

	-- Check protocol / game config
	configure_selected_world(idx)

	local raw_index = menudata.worldlist:get_raw_index(idx)
	gamedata.selected_world = raw_index
	gamedata.singleplayer = not st.is_hosting

	if st.is_hosting then
		gamedata.mode = "host"
		gamedata.address = ""
		gamedata.port = tonumber(st.port) or 30000
		gamedata.playername = st.player_name
		gamedata.password = st.password
	else
		gamedata.mode = "singleplayer"
		gamedata.address = ""
		gamedata.port = 0
		gamedata.playername = st.player_name
		gamedata.password = ""
	end

	core.settings:set("mainmenu_last_session_type", "local")
	core.settings:set("mainmenu_last_selected_world", tostring(raw_index))
	core.settings:set("mainmenu_last_world_name", world.name)

	-- Update last_played timestamp in world.mt and settings
	if world.path then
		local delim = DIR_DELIM or "/"
		local conf = Settings(world.path .. delim .. "world.mt")
		conf:set("last_played", tostring(os.time()))
		conf:write()
		if mainmenu and mainmenu.view and mainmenu.view.clear_local_cache then
			mainmenu.view.clear_local_cache(world.path)
		end
	end

	if world.gameid and pkgmgr and pkgmgr.normalize_game_id then
		local norm_gid = pkgmgr.normalize_game_id(world.gameid)
		core.settings:set("game_last_played_" .. norm_gid, tostring(os.time()))
		if pkgmgr.refresh_game_last_played then
			pkgmgr.refresh_game_last_played()
		end
	end

	st.save_persistent()
	core.start()
end

local function connect_to_server(st, server)
	if not server then return end

	if not is_server_protocol_compat_or_error(server.proto_min, server.proto_max) then
		return
	end

	gamedata.mode = "join"
	gamedata.playername = st.player_name
	gamedata.password = st.password
	gamedata.address = server.address
	gamedata.port = server.port
	gamedata.selected_world = 0
	gamedata.singleplayer = false

	local enable_split = core.settings:get_bool("enable_split_login_register")
	if enable_split == nil then
		enable_split = true
	end
	gamedata.allow_login_or_register = enable_split and "login" or "any"

	if server.name and server.name ~= "" then
		gamedata.servername = server.name
		gamedata.serverdescription = server.description or ""
		serverlistmgr.add_favorite(server)
	else
		gamedata.servername = ""
		gamedata.serverdescription = ""
		serverlistmgr.add_favorite({
			address = server.address,
			port = server.port,
		})
	end

	local s_name = server.name
	if not s_name or s_name == "" or s_name == server.address then
		if server.address == "127.0.0.1" or server.address:lower() == "localhost" or server.address == "::1" then
			s_name = "Localhost Server"
		else
			s_name = server.address
		end
	end

	core.settings:set("address", server.address)
	core.settings:set("remote_port", tostring(server.port))
	core.settings:set("mainmenu_last_session_type", "server")
	core.settings:set("mainmenu_last_server_name", s_name)
	core.settings:set("mainmenu_last_server_address", server.address)
	core.settings:set("mainmenu_last_server_port", tostring(server.port))
	core.settings:set("mainmenu_last_server_desc", server.description or "")
	st.save_persistent()
	core.start()
end

local function sanitize_text(s, max_len)
	if rawget(_G, "mainmenu") and mainmenu.sanitize_input then
		return mainmenu.sanitize_input(s, max_len)
	end
	if s == nil then return "" end
	local str = tostring(s):gsub("[%z\1-\31\127]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	if max_len and #str > max_len then
		str = str:sub(1, max_len)
	end
	return str
end

local function sanitize_name(s)
	if rawget(_G, "mainmenu") and mainmenu.sanitize_player_name then
		return mainmenu.sanitize_player_name(s)
	end
	if s == nil then return "" end
	local str = tostring(s):gsub("[%z\1-\31\127%s]", ""):gsub("[^%w%_%-]", "")
	if #str > 20 then
		str = str:sub(1, 20)
	end
	return str
end

function dispatcher.dispatch(st_or_fields, maybe_fields)
	local st, fields
	if maybe_fields ~= nil then
		st, fields = st_or_fields, maybe_fields
	else
		st, fields = rawget(_G, "state"), st_or_fields
	end
	if not fields then return false end

	----------------------------------------------------------------------------
	-- 1. Sync Text & Checkbox Inputs with Sanitization
	----------------------------------------------------------------------------
	-- 1. Click-to-Focus Button Overlays
	for k in pairs(fields) do
		if k:sub(1, 10) == "btn_focus_" then
			local fname = k:sub(11)
			if fname == "name" then fname = "te_name" end
			if fname == "pwd" then fname = "te_pwd" end
			if fname == "host_name" then fname = "te_playername" end
			if fname == "host_pwd" then fname = "te_passwd" end
			st.set("focused_field", fname)
			if not fields.btn_world_clear and fields.te_world_search ~= nil then
				st.set("world_search_query", sanitize_text(fields.te_world_search, 128), true)
			end
			if not fields.btn_srv_clear and fields.te_server_search ~= nil then
				st.set("server_search_query", sanitize_text(fields.te_server_search, 128), true)
			end
			if not fields.btn_srv_mod_clear and fields.te_server_mod_search ~= nil then
				st.set("server_mod_filter", sanitize_text(fields.te_server_mod_search, 128), true)
			end
			return true
		end
	end

	-- 2. Detect Focus on Text Typing / Editing
	if fields.te_name ~= nil and fields.te_name ~= (st.get("player_name") or "") then
		st.set("focused_field", "te_name")
	elseif fields.te_pwd ~= nil and fields.te_pwd ~= (st.get("password") or "") then
		st.set("focused_field", "te_pwd")
	elseif fields.te_server_search ~= nil and fields.te_server_search ~= (st.get("server_search_query") or "") then
		st.set("focused_field", "te_server_search")
	elseif fields.te_world_search ~= nil and fields.te_world_search ~= (st.get("world_search_query") or "") then
		st.set("focused_field", "te_world_search")
	elseif fields.te_playername ~= nil and fields.te_playername ~= (st.get("player_name") or "") then
		st.set("focused_field", "te_playername")
	elseif fields.te_passwd ~= nil and fields.te_passwd ~= (st.get("password") or "") then
		st.set("focused_field", "te_passwd")
	elseif fields.te_content_search ~= nil and fields.te_content_search ~= (st.get("content_search_query") or "") then
		st.set("focused_field", "te_content_search")
	elseif fields.te_server_mod_search ~= nil and fields.te_server_mod_search ~= (st.get("server_mod_filter") or "") then
		st.set("focused_field", "te_server_mod_search")
	end

	-- 3. Enter Key & Search Button Navigation
	if fields.key_enter_field then
		if fields.key_enter_field == "te_name" then
			st.set("focused_field", "te_pwd")
		elseif fields.key_enter_field == "te_playername" then
			st.set("focused_field", "te_passwd")
		else
			st.set("focused_field", fields.key_enter_field)
		end
	elseif fields.btn_srv_search or fields.btn_srv_clear then
		st.set("focused_field", "te_server_search")
	elseif fields.btn_srv_mod_search or fields.btn_srv_mod_clear then
		st.set("focused_field", "te_server_mod_search")
	elseif fields.btn_world_search or fields.btn_world_clear then
		st.set("focused_field", "te_world_search")
	elseif fields.btn_cnt_search or fields.btn_cnt_clear or fields.btn_content_search or fields.btn_content_clear then
		st.set("focused_field", "te_content_search")
	end

	if not fields.btn_world_clear and fields.te_world_search ~= nil then
		st.set("world_search_query", sanitize_text(fields.te_world_search, 128), true)
	end
	if not fields.btn_srv_clear and fields.te_server_search ~= nil then
		st.set("server_search_query", sanitize_text(fields.te_server_search, 128), true)
	end
	if not fields.btn_srv_mod_clear and fields.te_server_mod_search ~= nil then
		st.set("server_mod_filter", sanitize_text(fields.te_server_mod_search, 128), true)
	end
	if fields.te_playername ~= nil then
		local clean_name = sanitize_name(fields.te_playername)
		st.set("player_name", clean_name, true)
		core.settings:set("name", clean_name)
	end
	if fields.te_name ~= nil then
		local clean_name = sanitize_name(fields.te_name)
		st.set("player_name", clean_name, true)
		core.settings:set("name", clean_name)
	end
	if fields.te_passwd ~= nil then
		st.set("password", sanitize_text(fields.te_passwd, 128), true)
	end
	if fields.te_pwd ~= nil then
		st.set("password", sanitize_text(fields.te_pwd, 128), true)
	end

	if fields.cb_creative_mode ~= nil then
		local cur = st.creative_mode
		if cur == nil and core.settings then cur = core.settings:get_bool("creative_mode") end
		local val
		if fields.cb_creative_mode == "" or fields.cb_creative_mode == "toggle" then
			val = not cur
		else
			val = core.is_yes(fields.cb_creative_mode)
		end
		st.set("creative_mode", val)
		core.settings:set_bool("creative_mode", val)
		return true
	end
	if fields.cb_enable_damage ~= nil then
		local cur = st.enable_damage
		if cur == nil then cur = core.settings:get_bool("enable_damage") end
		local val
		if fields.cb_enable_damage == "" or fields.cb_enable_damage == "toggle" then
			val = not cur
		else
			val = core.is_yes(fields.cb_enable_damage)
		end
		st.set("enable_damage", val)
		core.settings:set_bool("enable_damage", val)
		return true
	end
	if fields.cb_enable_server ~= nil then
		local cur = st.is_hosting
		if cur == nil then cur = core.settings:get_bool("enable_server") end
		local val
		if fields.cb_enable_server == "" or fields.cb_enable_server == "toggle" then
			val = not cur
		else
			val = core.is_yes(fields.cb_enable_server)
		end
		st.set("is_hosting", val)
		core.settings:set_bool("enable_server", val)
		return true
	end

	local function ensure_local_game_filtered()
		local gid = st.selected_game_id or core.settings:get("menu_last_game")
		local g = (gid and pkgmgr and pkgmgr.find_by_gameid and pkgmgr.find_by_gameid(gid))
			or (current_game and current_game())
			or (pkgmgr and pkgmgr.games and pkgmgr.games[1])
		if g then
			st.set("selected_game_id", g.id)
			if apply_game then
				apply_game(g)
			elseif menudata and menudata.worldlist and menudata.worldlist.set_filtercriteria then
				menudata.worldlist:set_filtercriteria(g.id)
			end
			if mainmenu and mainmenu.sync_game_theme then
				mainmenu.sync_game_theme(false)
			end
		end
	end

	local function switch_active_tab(new_tab)
		local cur_focus = (st.get and st.get("focused_field")) or st.focused_field
		local is_search = (cur_focus == "te_world_search" or cur_focus == "te_server_search" or cur_focus == "te_content_search")

		st.set("active_tab", new_tab)

		if is_search then
			local new_search_f = nil
			if new_tab == "local" then
				new_search_f = "te_world_search"
			elseif new_tab == "online" then
				new_search_f = "te_server_search"
			elseif new_tab == "content" then
				new_search_f = "te_content_search"
			end
			st.set("focused_field", new_search_f)
		else
			st.set("focused_field", nil)
		end
	end

	----------------------------------------------------------------------------
	-- 2. Sidebar Navigation Tabs
	----------------------------------------------------------------------------
	if fields.nav_games or fields.btn_nav_to_games then
		switch_active_tab("games")
		return true
	elseif fields.nav_local then
		switch_active_tab("local")
		ensure_local_game_filtered()
		return true
	elseif fields.nav_online then
		switch_active_tab("online")
		serverlistmgr.sync()
		return true
	elseif fields.nav_content then
		switch_active_tab("content")
		return true
	elseif fields.nav_about then
		switch_active_tab("about")
		return true
	end

	----------------------------------------------------------------------------
	-- 3. Game Chooser Actions (Top & Bottom Rows)
	----------------------------------------------------------------------------
	if fields.btn_chooser_host then
		st.set("is_hosting", true)
		switch_active_tab("local")
		ensure_local_game_filtered()
		core.settings:set_bool("enable_server", true)
		st.mark_chooser_seen()
		st.save_persistent()
		return true
	end

	if fields.btn_chooser_join then
		switch_active_tab("online")
		serverlistmgr.sync()
		st.mark_chooser_seen()
		st.save_persistent()
		return true
	end

	if fields.btn_chooser_singleplayer then
		st.set("is_hosting", false)
		switch_active_tab("local")
		ensure_local_game_filtered()
		core.settings:set_bool("enable_server", false)
		st.mark_chooser_seen()
		st.save_persistent()
		return true
	end

	----------------------------------------------------------------------------
	-- 4. Game Selection & Switching
	----------------------------------------------------------------------------
	for f_key, _ in pairs(fields) do
		local gid = f_key:match("^btn_choose_game_(.+)$") or f_key:match("^game_select_(.+)$")
		if gid then
			local game = nil
			if pkgmgr and pkgmgr.find_by_gameid then
				game = pkgmgr.find_by_gameid(gid)
			end
			if not game and pkgmgr and pkgmgr.games then
				for _, g in ipairs(pkgmgr.games) do
					if g.id == gid or (pkgmgr.normalize_game_id and pkgmgr.normalize_game_id(g.id) == pkgmgr.normalize_game_id(gid)) then
						game = g
						break
					end
				end
			end
			if game then
				local current_game_id = (st.get and st.get("selected_game_id")) or st.selected_game_id or core.settings:get("menu_last_game")
				local active_game_obj = nil
				if current_game_id and pkgmgr and pkgmgr.find_by_gameid then
					active_game_obj = pkgmgr.find_by_gameid(current_game_id)
				end

				local is_already_active = (active_game_obj and active_game_obj.id == game.id)
					or (game.id == current_game_id)
					or (pkgmgr and pkgmgr.normalize_game_id and current_game_id and
						pkgmgr.normalize_game_id(game.id) == pkgmgr.normalize_game_id(current_game_id))

				if is_already_active then
					-- Already active: avoid redundant apply_game, world re-filtering, and theme/music restart
					st.set("viewing_game_details", nil)
					return true
				end

				st.set("selected_game_id", game.id)
				if apply_game then
					apply_game(game)
				end
				if pkgmgr and pkgmgr.normalize_game_id then
					local norm_gid = pkgmgr.normalize_game_id(game.id)
					core.settings:set("game_last_played_" .. norm_gid, tostring(os.time()))
				end
				if mainmenu and mainmenu.sync_game_theme then
					mainmenu.sync_game_theme(true)
				end
				st.set("viewing_game_details", nil)
				st.save_persistent()
				return true
			end
		end

		local info_gid = f_key:match("^btn_game_info_(.+)$")
		if info_gid then
			local cur = st.get("viewing_game_details")
			st.set("viewing_game_details", (cur == info_gid) and nil or info_gid)
			return true
		end
	end

	if fields.btn_close_game_details then
		st.set("viewing_game_details", nil)
		return true
	end

	if fields.games_scroll then
		local ev = core.explode_scrollbar_event(fields.games_scroll)
		if ev.value then
			st.set("games_scroll", ev.value, true)
		end
	end

	if fields.game_open_cdb or fields.btn_contentdb or fields.btn_chooser_cdb then
		local dlg = create_contentdb_dlg()
		dlg:set_parent(mainmenu.ui_element)
		mainmenu.ui_element:hide()
		dlg:show()
		return true
	end

	----------------------------------------------------------------------------
	-- 5. Local World Management & Launch
	----------------------------------------------------------------------------
	if fields.btn_resume_adventure then
		local session_type = core.settings:get("mainmenu_last_session_type")
		if not session_type then
			local s_addr = core.settings:get("mainmenu_last_server_address") or core.settings:get("address")
			if s_addr and s_addr ~= "" then
				session_type = "server"
			else
				session_type = "local"
			end
		end

		if session_type == "server" then
			local addr = core.settings:get("mainmenu_last_server_address") or core.settings:get("address")
			local port = tonumber(core.settings:get("mainmenu_last_server_port") or core.settings:get("remote_port")) or 30000
			local sname = core.settings:get("mainmenu_last_server_name")
			if addr and addr ~= "" then
				local srv = nil
				for _, s in ipairs(serverlistmgr.servers or {}) do
					if s.address == addr and s.port == port then
						srv = s
						break
					end
				end
				if not srv then
					for _, s in ipairs(serverlistmgr.get_favorites() or {}) do
						if s.address == addr and s.port == port then
							srv = s
							break
						end
					end
				end
				if not srv and menudata.server_lookup then
					for _, s in pairs(menudata.server_lookup) do
						if s.address == addr and s.port == port then
							srv = s
							break
						end
					end
				end
				if not srv then
					srv = { address = addr, port = port, name = sname or addr, proto_min = 0, proto_max = 999 }
				end

				if create_resume_server_dialog then
					local dlg = create_resume_server_dialog(srv)
					if mainmenu and mainmenu.ui_element and mainmenu.ui_element.hide then
						mainmenu.ui_element:hide()
					end
					dlg:show()
					return true
				end
			end
		end

		local last_raw = tonumber(core.settings:get("mainmenu_last_selected_world"))
		local list = menudata.worldlist and menudata.worldlist:get_list()
		local target_idx = 1
		if last_raw and last_raw > 0 and list then
			for i, _ in ipairs(list) do
				if menudata.worldlist:get_raw_index(i) == last_raw then
					target_idx = i
					break
				end
			end
		end
		st.set("selected_world_index", target_idx)
		configure_selected_world(target_idx)
		launch_selected_world(st)
		return true
	end

	if fields.btn_world_clear then
		st.set("world_search_query", "")
		return true
	end

	if fields.btn_world_search or (fields.key_enter_field == "te_world_search") then
		local q = fields.te_world_search or st.get("world_search_query") or ""
		st.set("world_search_query", q)
		return true
	end

	-- World List Column Header Sorting
	local function handle_world_sort_click(col)
		local current_col = st.get("world_sort_col") or "name"
		local current_dir = st.get("world_sort_dir") or "asc"
		if current_col == col then
			st.set("world_sort_dir", current_dir == "asc" and "desc" or "asc")
		else
			st.set("world_sort_col", col)
			st.set("world_sort_dir", "asc")
		end
		return true
	end

	if fields.btn_sort_world_name or fields.btn_sort_world_name_ext then
		return handle_world_sort_click("name")
	elseif fields.btn_sort_world_game or fields.btn_sort_world_game_ext then
		return handle_world_sort_click("game")
	elseif fields.btn_sort_world_mg or fields.btn_sort_world_mg_ext then
		return handle_world_sort_click("mg")
	elseif fields.btn_sort_world_version or fields.btn_sort_world_version_ext then
		return handle_world_sort_click("version")
	elseif fields.btn_sort_world_mods or fields.btn_sort_world_mods_ext then
		return handle_world_sort_click("mods")
	elseif fields.btn_sort_world_size or fields.btn_sort_world_size_ext then
		return handle_world_sort_click("size")
	elseif fields.btn_sort_world_last_played or fields.btn_sort_world_last_played_ext then
		return handle_world_sort_click("last_played")
	end

	if fields.sp_worlds then
		local event = core.explode_table_event(fields.sp_worlds)
		if event.type == "CHG" or event.type == "DCL" then
			local w = menudata.world_lookup and menudata.world_lookup[event.row]
			if w then
				st.set("selected_world_index", w.list_index)
				configure_selected_world(w.list_index)
				core.settings:set("mainmenu_last_selected_world", tostring(w.raw_index))
				if event.type == "DCL" then
					launch_selected_world(st)
				end
				return true
			end
		end
	end

	if fields.play_world then
		launch_selected_world(st)
		return true
	end

	if fields.world_create then
		local gameid = st.selected_game_id or core.settings:get("menu_last_game")
		local dlg = create_create_world_dlg(gameid)
		dlg:set_parent(mainmenu.ui_element)
		mainmenu.ui_element:hide()
		dlg:show()
		return true
	end

	if fields.world_configure then
		local dlg = create_configure_world_dlg(st.selected_world_index or 1)
		dlg:set_parent(mainmenu.ui_element)
		mainmenu.ui_element:hide()
		dlg:show()
		return true
	end

	if fields.world_delete then
		local list = menudata.worldlist:get_list()
		local idx = st.selected_world_index or (st.get and st.get("selected_world_index")) or 1
		local cur = list and list[idx]
		if cur then
			local raw_index = menudata.worldlist:get_raw_index(idx)
			local dlg = create_delete_world_dlg(cur.name, raw_index)
			dlg:set_parent(mainmenu.ui_element)
			mainmenu.ui_element:hide()
			dlg:show()
			return true
		end
	end

	if fields.btn_open_world_folder then
		local cur = nil
		local list = menudata.worldlist and menudata.worldlist:get_list()
		local raw = menudata.worldlist and menudata.worldlist.get_raw_list and menudata.worldlist:get_raw_list()
		local idx = st.selected_world_index or (st.get and st.get("selected_world_index")) or 1
		if list and list[idx] then
			cur = list[idx]
		elseif raw and raw[idx] then
			cur = raw[idx]
		elseif list and #list > 0 then
			cur = list[1]
		elseif raw and #raw > 0 then
			cur = raw[1]
		end
		if cur and cur.path then
			core.open_dir(cur.path)
		else
			core.open_dir(core.get_user_path() .. DIR_DELIM .. "worlds")
		end
		return true
	end

	----------------------------------------------------------------------------
	-- 6. Online Server Browser Actions & Mod List Dialog
	----------------------------------------------------------------------------
	if fields.btn_filter_all then
		st.set("server_filter", "all")
		return true
	elseif fields.btn_filter_fav then
		st.set("server_filter", "fav")
		return true
	elseif fields.btn_filter_compat then
		st.set("server_filter", "compat")
		return true
	end

	if fields.btn_srv_refresh then
		serverlistmgr.sync()
		return true
	end

	if fields.btn_srv_direct_connect then
		local dlg = create_direct_connect_dialog()
		dlg:set_parent(mainmenu.ui_element)
		mainmenu.ui_element:hide()
		dlg:show()
		return true
	end

	if fields.btn_srv_clear then
		st.set("server_search_query", "")
		menudata.search_result = nil
		return true
	end

	if fields.btn_srv_search or (fields.key_enter_field == "te_server_search") then
		local q = fields.te_server_search or st.get("server_search_query") or ""
		st.set("server_search_query", q)
		menudata.search_result = nil
		return true
	end

	if fields.servers then
		local event = core.explode_table_event(fields.servers)
		if menudata.server_lookup and menudata.server_lookup[event.row] then
			local srv = menudata.server_lookup[event.row]
			core.settings:set("address", srv.address)
			core.settings:set("remote_port", tostring(srv.port))
			local p_name = st.get("player_name") or core.settings:get("name") or ""
			if not st.get("focused_field") then
				st.set("focused_field", (p_name ~= "") and "te_pwd" or "te_name")
			end
			st.set("selected_server_mod", 1)
			st.set("selected_server_player", 1)
			if event.type == "DCL" then
				connect_to_server(st, srv)
			end
			return true
		end
	end

	if fields.btn_mp_login or (fields.key_enter and fields.key_enter_field == "te_pwd") then
		local srv = nil
		local addr = core.settings:get("address")
		local port = tonumber(core.settings:get("remote_port"))
		if addr and port then
			for _, s in ipairs(serverlistmgr.servers or {}) do
				if s.address == addr and s.port == port then
					srv = s
					break
				end
			end
			if not srv then
				for _, s in ipairs(serverlistmgr.get_favorites() or {}) do
					if s.address == addr and s.port == port then
						srv = s
						break
					end
				end
			end
			if not srv and menudata.server_lookup then
				for _, s in pairs(menudata.server_lookup) do
					if s.address == addr and s.port == port then
						srv = s
						break
					end
				end
			end
			if not srv then
				srv = { address = addr, port = port, proto_min = 0, proto_max = 999 }
			end
		end
		connect_to_server(st, srv)
		return true
	end

	if fields.btn_mp_register then
		local srv = nil
		local addr = core.settings:get("address")
		local port = tonumber(core.settings:get("remote_port"))
		if addr and port then
			for _, s in ipairs(serverlistmgr.servers or {}) do
				if s.address == addr and s.port == port then
					srv = s
					break
				end
			end
			if not srv then
				for _, s in ipairs(serverlistmgr.get_favorites() or {}) do
					if s.address == addr and s.port == port then
						srv = s
						break
					end
				end
			end
			if not srv and menudata.server_lookup then
				for _, s in pairs(menudata.server_lookup) do
					if s.address == addr and s.port == port then
						srv = s
						break
					end
				end
			end
			if not srv then
				srv = { address = addr, port = port, proto_min = 0, proto_max = 999 }
			end
			if srv and not is_server_protocol_compat_or_error(srv.proto_min, srv.proto_max) then
				return true
			end
			local dlg = create_register_dialog(addr, port, srv)
			dlg:set_parent(mainmenu.ui_element)
			mainmenu.ui_element:hide()
			dlg:show()
			return true
		end
		return true
	end

	if fields.btn_add_favorite then
		local addr = core.settings:get("address")
		local port = tonumber(core.settings:get("remote_port"))
		if addr and port then
			for _, srv in ipairs(serverlistmgr.servers or {}) do
				if srv.address == addr and srv.port == port then
					if srv.is_favorite then
						serverlistmgr.delete_favorite(srv)
					else
						serverlistmgr.add_favorite(srv)
					end
					break
				end
			end
			return true
		end
	end

	if fields.btn_server_url then
		local addr = core.settings:get("address")
		local port = tonumber(core.settings:get("remote_port"))
		for _, srv in ipairs(serverlistmgr.servers or {}) do
			if srv.address == addr and srv.port == port and srv.url then
				core.open_url_dialog(srv.url)
				break
			end
		end
		return true
	end

	-- Clickable Metric Tiles for In-Place Server Information
	if fields.btn_tile_ping or fields.btn_tile_latency then
		st.set("server_info_tab", "latency")
		return true
	elseif fields.btn_tile_players then
		st.set("server_info_tab", "players")
		return true
	elseif fields.btn_tile_engine then
		st.set("server_info_tab", "engine")
		return true
	elseif fields.btn_tile_mods then
		st.set("server_info_tab", "mods")
		return true
	end

	-- Table Header Column Sorting
	local function handle_server_sort_click(col)
		local current_col = st.get("server_sort_col")
		local current_dir = st.get("server_sort_dir")
		if current_col == col then
			st.set("server_sort_dir", current_dir == "asc" and "desc" or "asc")
		else
			st.set("server_sort_col", col)
			if col == "ping" or col == "name" then
				st.set("server_sort_dir", "asc")
			else
				st.set("server_sort_dir", "desc")
			end
		end
		return true
	end

	if fields.btn_sort_ping or fields.btn_sort_ping_ext then
		return handle_server_sort_click("ping")
	elseif fields.btn_sort_players or fields.btn_sort_players_ext then
		return handle_server_sort_click("players")
	elseif fields.btn_sort_version or fields.btn_sort_version_ext then
		return handle_server_sort_click("version")
	elseif fields.btn_sort_mods or fields.btn_sort_mods_ext then
		return handle_server_sort_click("mods")
	elseif fields.btn_sort_flags or fields.btn_sort_flags_ext then
		return handle_server_sort_click("flags")
	elseif fields.btn_sort_name or fields.btn_sort_name_ext then
		return handle_server_sort_click("name")
	end

	-- Absorb and persist inspector sub-list clicks safely
	if fields.online_player_list then
		local evt = core.explode_table_event(fields.online_player_list)
		if evt and evt.row and evt.row > 0 then
			st.set("selected_server_player", evt.row)
		end
		return true
	end

	if fields.server_mods_list or fields.server_mods_textlist then
		local raw = fields.server_mods_list or fields.server_mods_textlist
		local evt = core.explode_table_event(raw)
		if evt and evt.row and evt.row > 0 then
			st.set("selected_server_mod", evt.row)
		elseif type(raw) == "string" and raw:match("^CHG:(%d+)") then
			st.set("selected_server_mod", tonumber(raw:match("^CHG:(%d+)")))
		end
		return true
	end

	if fields.btn_srv_mod_clear then
		st.set("server_mod_filter", "")
		st.set("server_mods_scroll", 0)
		return true
	end

	if fields.btn_srv_mod_search or (fields.key_enter_field == "te_server_mod_search") then
		local q = fields.te_server_mod_search or st.get("server_mod_filter") or ""
		st.set("server_mod_filter", q)
		st.set("server_mods_scroll", 0)
		return true
	end

	if fields.server_mods_scroll then
		local ev = core.explode_scrollbar_event(fields.server_mods_scroll)
		if ev.value then
			st.set("server_mods_scroll", ev.value, true)
		end
	end

	for k, _ in pairs(fields) do
		local exp_idx = k:match("^btn_mod_exp_(%d+)$")
		if exp_idx then
			local idx = tonumber(exp_idx)
			local mod_name = menudata.online_filtered_mods and menudata.online_filtered_mods[idx]
			if mod_name then
				local exp_table = st.get("online_mods_expanded") or {}
				local new_exp = {}
				for m, v in pairs(exp_table) do
					new_exp[m] = v
				end
				new_exp[mod_name] = not new_exp[mod_name]
				st.set("online_mods_expanded", new_exp)
			end
			return true
		end

		local view_idx = k:match("^btn_cdb_view_(%d+)$")
		if view_idx then
			local idx = tonumber(view_idx)
			local pkg = menudata.online_filtered_cdb and menudata.online_filtered_cdb[idx]
			if not pkg and menudata.online_filtered_mods and menudata.online_filtered_mods[idx] then
				local m_name = menudata.online_filtered_mods[idx]:lower()
				if _G.contentdb and _G.contentdb.packages_full then
					for _, p in ipairs(_G.contentdb.packages_full) do
						if p.type == "mod" and p.name and p.name:lower() == m_name then
							pkg = p
							break
						end
					end
				end
			end
			if pkg and create_package_dialog then
				local dlg = create_package_dialog(pkg)
				dlg:set_parent(mainmenu.ui_element)
				mainmenu.ui_element:hide()
				dlg:show()
			elseif create_contentdb_dlg and menudata.online_filtered_mods and menudata.online_filtered_mods[idx] then
				local dlg = create_contentdb_dlg("mod", nil, menudata.online_filtered_mods[idx])
				dlg:set_parent(mainmenu.ui_element)
				mainmenu.ui_element:hide()
				dlg:show()
			end
			return true
		end

		local search_idx = k:match("^btn_cdb_search_(%d+)$")
		if search_idx then
			local idx = tonumber(search_idx)
			local mod_name = menudata.online_filtered_mods and menudata.online_filtered_mods[idx]
			if mod_name and create_contentdb_dlg then
				local dlg = create_contentdb_dlg("mod", nil, mod_name)
				dlg:set_parent(mainmenu.ui_element)
				mainmenu.ui_element:hide()
				dlg:show()
			end
			return true
		end
	end

	----------------------------------------------------------------------------
	-- 7. ContentDB Package Management
	----------------------------------------------------------------------------
	if fields.btn_content_clear then
		st.set("content_search_query", "")
		st.set("selected_pkg", 1)
		st.set("selected_child_mod", nil)
		return true
	end

	if fields.btn_content_search or (fields.key_enter_field == "te_content_search") then
		local q = fields.te_content_search or st.get("content_search_query") or ""
		st.set("content_search_query", q)
		st.set("selected_pkg", 1)
		st.set("selected_child_mod", nil)
		return true
	end

	if fields.btn_content_filter_all then
		st.set("content_filter", "all")
		st.set("selected_pkg", 1)
		st.set("selected_child_mod", nil)
		return true
	elseif fields.btn_content_filter_mods then
		st.set("content_filter", "mod")
		st.set("selected_pkg", 1)
		st.set("selected_child_mod", nil)
		return true
	elseif fields.btn_content_filter_games then
		st.set("content_filter", "game")
		st.set("selected_pkg", 1)
		st.set("selected_child_mod", nil)
		return true
	elseif fields.btn_content_filter_txp then
		st.set("content_filter", "txp")
		st.set("selected_pkg", 1)
		st.set("selected_child_mod", nil)
		return true
	end

	if fields.btn_content_view_list then
		st.set("content_view_mode", "list")
		st.set("selected_child_mod", nil)
		return true
	elseif fields.btn_content_view_thumbs then
		st.set("content_view_mode", "thumbs")
		st.set("selected_child_mod", nil)
		return true
	end

	if fields.content_thumbs_scroll then
		local ev = core.explode_scrollbar_event(fields.content_thumbs_scroll)
		if ev.value then
			st.set("content_thumbs_scroll", ev.value, true)
		end
	end

	if fields.content_list_scroll then
		local ev = core.explode_scrollbar_event(fields.content_list_scroll)
		if ev.value then
			st.set("content_list_scroll", ev.value, true)
		end
	end

	if fields.pkglist then
		local event = core.explode_table_event(fields.pkglist)
		if event.row and event.row > 0 then
			st.set("selected_pkg", event.row)
			st.set("selected_child_mod", nil)
		end
		return true
	end

	for k, _ in pairs(fields) do
		local exp_idx = k:match("^btn_pkg_exp_(%d+)$")
		if exp_idx then
			local idx = tonumber(exp_idx)
			local pkg = menudata.pkg_list and menudata.pkg_list[idx]
			if pkg then
				local exp_table = st.get("content_list_expanded") or {}
				local new_exp = {}
				for m, v in pairs(exp_table) do
					new_exp[m] = v
				end
				local key = pkg.name or pkg.id or tostring(idx)
				new_exp[key] = not new_exp[key]
				st.set("content_list_expanded", new_exp)
				st.set("selected_pkg", idx)
				st.set("selected_child_mod", nil)
			end
			return true
		end

		local select_idx = k:match("^btn_select_pkg_(%d+)$")
		if select_idx then
			st.set("selected_pkg", tonumber(select_idx))
			st.set("selected_child_mod", nil)
			return true
		end

		local parent_str, child_str = k:match("^btn_select_child_(%d+)_(%d+)$")
		if parent_str and child_str then
			local p_idx = tonumber(parent_str)
			local c_idx = tonumber(child_str)
			st.set("selected_pkg", p_idx)
			if menudata.child_mods_lookup and menudata.child_mods_lookup[p_idx] then
				local child = menudata.child_mods_lookup[p_idx][c_idx]
				if child then
					st.set("selected_child_mod", child)
				end
			end
			return true
		end

		local mp_name = k:match("^btn_modpack_toggle_(.+)$")
		if mp_name then
			local exp = {}
			for mp, v in pairs(st.get("expanded_modpacks") or {}) do
				exp[mp] = v
			end
			exp[mp_name] = not exp[mp_name]
			st.set("expanded_modpacks", exp)
			return true
		end
	end

	if fields.btn_back_to_parent_pkg then
		st.set("selected_child_mod", nil)
		return true
	end

	if fields.btn_open_pkg_dir then
		local child = st.get("selected_child_mod")
		local idx = st.get("selected_pkg") or 1
		local pkg = child or (menudata.pkg_list and menudata.pkg_list[idx])
		if pkg and pkg.path then
			core.open_dir(pkg.path)
		else
			core.open_dir(core.get_user_path())
		end
		return true
	end

	if fields.btn_mod_mgr_delete_mod then
		local idx = st.get("selected_pkg") or 1
		local pkg = menudata.pkg_list and menudata.pkg_list[idx]
		if pkg and create_delete_content_dlg then
			local dlg_delmod = create_delete_content_dlg(pkg)
			dlg_delmod:set_parent(mainmenu.ui_element)
			mainmenu.ui_element:hide()
			dlg_delmod:show()
		end
		return true
	end

	if fields.btn_mod_mgr_rename_modpack then
		local idx = st.get("selected_pkg") or 1
		local pkg = menudata.pkg_list and menudata.pkg_list[idx]
		if pkg and create_rename_modpack_dlg then
			local dlg_renamemp = create_rename_modpack_dlg(pkg)
			dlg_renamemp:set_parent(mainmenu.ui_element)
			mainmenu.ui_element:hide()
			dlg_renamemp:show()
		end
		return true
	end

	----------------------------------------------------------------------------
	-- 8. Settings, Open Folder, and Exit
	----------------------------------------------------------------------------
	if fields.open_settings then
		local dlg = create_settings_dlg()
		dlg:set_parent(mainmenu.ui_element)
		mainmenu.ui_element:hide()
		dlg:show()
		return true
	end

	if fields.userdata then
		core.open_dir(core.get_user_path())
		return true
	end

	if fields.share_debug then
		local path = core.get_user_path() .. (DIR_DELIM or "/") .. "debug.txt"
		if core.share_file then
			core.share_file(path)
		end
		return true
	end

	if fields.btn_quit_game or fields.quit then
		if fields.quit then
			local active_tab = st.active_tab
			if active_tab == "online" then
				if st.server_info_tab and st.server_info_tab ~= "latency" then
					st.server_info_tab = "latency"
					return true
				end
				if st.server_search_query and st.server_search_query ~= "" then
					st.server_search_query = ""
					return true
				end
			elseif active_tab == "local" then
				if st.world_search_query and st.world_search_query ~= "" then
					st.world_search_query = ""
					return true
				end
			end
		end

		local dlg = create_exit_dialog()
		dlg:set_parent(mainmenu.ui_element)
		mainmenu.ui_element:hide()
		dlg:show()
		return true
	end

	return false
end

return dispatcher
