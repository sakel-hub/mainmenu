-- Luanti Main Menu Redesign
-- Play Online / Server Browser View Component (Formspec Version 7)

local view_online = {}

local function safe_trim(s)
	if not s then return "" end
	if type(s.trim) == "function" then
		return s:trim()
	end
	return tostring(s):match("^%s*(.-)%s*$") or ""
end

local function format_client_count(n)
	if not n or n < 0 then return "?" end
	if n > 999 then return "99+" end
	return tostring(n)
end

local function is_localhost_address(addr)
	if not addr or addr == "" then return false end
	local a = tostring(addr):lower():match("^%s*(.-)%s*$")
	return a == "127.0.0.1" or a == "localhost" or a == "::1" or a:sub(1, 4) == "127."
end

local function is_lan_address(addr)
	if not addr or addr == "" then return false end
	local a = tostring(addr):lower():match("^%s*(.-)%s*$")
	if is_localhost_address(a) then return false end
	return a:match("^192%.168%.") ~= nil
		or a:match("^10%.") ~= nil
		or a:match("^172%.1[6-9]%.") ~= nil
		or a:match("^172%.2[0-9]%.") ~= nil
		or a:match("^172%.3[0-1]%.") ~= nil
		or a:match("%.local$") ~= nil
		or a:match("%.lan$") ~= nil
end

local function get_local_server_type(srv)
	if not srv or not srv.address then return nil end
	if is_localhost_address(srv.address) then
		return "localhost"
	elseif is_lan_address(srv.address) then
		return "lan"
	end
	return nil
end

local function get_server_ping_ms(srv)
	local p = srv.ping or srv.lag
	if p then
		if p < 10 then return p * 1000 end
		return p
	end
	local ltype = get_local_server_type(srv)
	if ltype == "localhost" then
		return 0.5
	elseif ltype == "lan" then
		return 1.5
	end
	return 999999
end

local function get_server_players(srv)
	if srv.clients ~= nil then
		return srv.clients
	end
	if get_local_server_type(srv) then
		return 0
	end
	return -1
end

local function get_server_version(srv)
	if srv.version and srv.version ~= "" then
		return srv.version
	end
	if get_local_server_type(srv) then
		local v = core and core.get_version and core.get_version()
		return (v and v.string) or "Luanti"
	end
	return ""
end

local function get_server_mods_count(srv)
	if srv.mods and type(srv.mods) == "table" then
		return #srv.mods
	end
	return 0
end

local function get_server_flags_weight(srv)
	local w = 0
	if srv.creative then w = w + 1 end
	if srv.pvp then w = w + 2 end
	if srv.damage then w = w + 4 end
	return w
end

local function get_server_name(srv)
	return (srv.name or srv.address or ""):lower()
end

local function unescape_formspec_text(s)
	if not s then return "" end
	return tostring(s):gsub("\\([\\%[%];,$])", "%1")
end

local function format_raw_text(fmt, ...)
	if rawget(_G, "fgettext_ne") then
		return fgettext_ne(fmt, ...)
	end
	local s = fmt
	local args = {...}
	for i, v in ipairs(args) do
		s = s:gsub("%$" .. i, tostring(v))
	end
	return s
end

local function truncate_str(s, max_len)
	if not s then return "" end
	local str = tostring(s)
	if #str > max_len then
		return str:sub(1, max_len - 1) .. "…"
	end
	return str
end

local cdb_cache_version = nil
local cdb_mod_lookup = nil

local function get_contentdb_mod_lookup()
	if not _G.contentdb or not _G.contentdb.packages_full then
		return {}
	end
	if cdb_mod_lookup and cdb_cache_version == #_G.contentdb.packages_full then
		return cdb_mod_lookup
	end
	cdb_mod_lookup = {}
	for _, pkg in ipairs(_G.contentdb.packages_full) do
		if pkg.type == "mod" and pkg.name then
			local key = pkg.name:lower()
			if not cdb_mod_lookup[key] or (pkg.score and cdb_mod_lookup[key].score and pkg.score > cdb_mod_lookup[key].score) then
				cdb_mod_lookup[key] = pkg
			end
		end
	end
	cdb_cache_version = #_G.contentdb.packages_full
	return cdb_mod_lookup
end

local function trigger_contentdb_prefetch()
	if _G.contentdb and not _G.contentdb.load_ok and not _G.contentdb.loading and _G.contentdb.fetch_pkgs then
		_G.contentdb.fetch_pkgs(function()
			if ui and ui.update then
				ui.update()
			end
		end)
	end
end

local function compare_servers(a, b, col, dir)
	local va, vb
	if col == "ping" then
		va = get_server_ping_ms(a)
		vb = get_server_ping_ms(b)
	elseif col == "players" then
		va = get_server_players(a)
		vb = get_server_players(b)
	elseif col == "version" then
		va = get_server_version(a)
		vb = get_server_version(b)
	elseif col == "mods" then
		va = get_server_mods_count(a)
		vb = get_server_mods_count(b)
	elseif col == "flags" then
		va = get_server_flags_weight(a)
		vb = get_server_flags_weight(b)
	else -- "name"
		va = get_server_name(a)
		vb = get_server_name(b)
	end

	if va ~= vb then
		if dir == "asc" then
			return va < vb
		else
			return va > vb
		end
	end

	-- Deterministic tie-breaker
	local id_a = (a.address or "") .. ":" .. tostring(a.port or 0)
	local id_b = (b.address or "") .. ":" .. tostring(b.port or 0)
	return id_a < id_b
end

local function parse_search_query(input)
	if not input or safe_trim(input) == "" then
		return nil
	end

	local query = {
		keywords = {},
		mods = {},
		players = {},
		game = nil,
	}

	for word in input:gmatch("%S+") do
		local lower_word = word:lower()
		local mod = lower_word:match("^mod:(.*)")
		if mod and mod ~= "" then
			table.insert(query.mods, mod)
		else
			local player = lower_word:match("^player:(.*)")
			if player and player ~= "" then
				table.insert(query.players, player)
			else
				local game = lower_word:match("^game:(.*)")
				if game and game ~= "" then
					query.game = game
				else
					table.insert(query.keywords, lower_word)
				end
			end
		end
	end

	if #query.keywords == 0 and #query.mods == 0 and #query.players == 0 and not query.game then
		return nil
	end

	return query
end

local function server_matches_query(server, query)
	if not query then
		return true
	end

	local s_name = (server.name or ""):lower()
	local s_desc = (server.description or ""):lower()
	local s_addr = (server.address or ""):lower()
	local s_game = (server.gameid or ""):lower()

	-- Check explicit game filter
	if query.game and not s_game:find(query.game, 1, true) then
		return false
	end

	-- Check explicit mod filters
	if #query.mods > 0 then
		if type(server.mods) ~= "table" then
			return false
		end
		for _, target_mod in ipairs(query.mods) do
			local found = false
			for _, m in ipairs(server.mods) do
				if m:lower():find(target_mod, 1, true) then
					found = true
					break
				end
			end
			if not found then
				return false
			end
		end
	end

	-- Check explicit player filters
	if #query.players > 0 then
		if type(server.clients_list) ~= "table" then
			return false
		end
		for _, target_player in ipairs(query.players) do
			local found = false
			for _, p in ipairs(server.clients_list) do
				if p:lower():find(target_player, 1, true) then
					found = true
					break
				end
			end
			if not found then
				return false
			end
		end
	end

	-- Check general keywords (all keywords must match at least one attribute)
	for _, kw in ipairs(query.keywords) do
		local kw_match = false
		if s_name:find(kw, 1, true) or s_desc:find(kw, 1, true) or s_addr:find(kw, 1, true) or s_game:find(kw, 1, true) then
			kw_match = true
		elseif type(server.mods) == "table" then
			for _, m in ipairs(server.mods) do
				if m:lower():find(kw, 1, true) then
					kw_match = true
					break
				end
			end
		end

		if not kw_match and type(server.clients_list) == "table" then
			for _, p in ipairs(server.clients_list) do
				if p:lower():find(kw, 1, true) then
					kw_match = true
					break
				end
			end
		end

		if not kw_match then
			return false
		end
	end

	return true
end

local function get_filtered_servers(st)
	local servers = {
		fav = {},
		public = {},
		incompatible = {}
	}

	local query = parse_search_query(st.server_search_query)
	local favs = serverlistmgr.get_favorites() or {}
	local taken_favs = {}
	local result = serverlistmgr.servers or {}

	for _, server in ipairs(result) do
		server.is_favorite = false
		for index, fav in ipairs(favs) do
			if server.address == fav.address and server.port == fav.port then
				taken_favs[index] = true
				server.is_favorite = true
				break
			end
		end
		server.is_compatible = is_server_protocol_compat(server.proto_min, server.proto_max)

		local matches_filter = true
		if st.server_filter == "fav" and not server.is_favorite then
			matches_filter = false
		elseif st.server_filter == "compat" and not server.is_compatible then
			matches_filter = false
		end

		if matches_filter and server_matches_query(server, query) then
			if server.is_favorite then
				table.insert(servers.fav, server)
			elseif server.is_compatible then
				table.insert(servers.public, server)
			else
				table.insert(servers.incompatible, server)
			end
		end
	end

	if st.server_filter == "all" or st.server_filter == "fav" then
		for index, fav in ipairs(favs) do
			if not taken_favs[index] then
				fav.is_favorite = true
				fav.is_compatible = is_server_protocol_compat(fav.proto_min, fav.proto_max)
				local matches_filter = true
				if st.server_filter == "compat" and not fav.is_compatible then
					matches_filter = false
				end
				if matches_filter and server_matches_query(fav, query) then
					table.insert(servers.fav, fav)
				end
			end
		end
	end

	-- Apply active column and direction sorting to each category
	local sort_col = st.server_sort_col or "players"
	local sort_dir = st.server_sort_dir or "desc"
	local comp = function(a, b)
		return compare_servers(a, b, sort_col, sort_dir)
	end

	if #servers.fav > 1 then
		table.sort(servers.fav, comp)
	end
	if #servers.public > 1 then
		table.sort(servers.public, comp)
	end
	if #servers.incompatible > 1 then
		table.sort(servers.incompatible, comp)
	end

	return servers
end

local function find_selected_server(servers, fallback_first)
	local address = core.settings:get("address")
	local port = tonumber(core.settings:get("remote_port"))

	local all_filtered = {}
	if servers then
		for _, id in ipairs({"fav", "public", "incompatible"}) do
			for _, s in ipairs(servers[id] or {}) do
				table.insert(all_filtered, s)
			end
		end
	else
		for _, s in ipairs(serverlistmgr.get_favorites() or {}) do
			table.insert(all_filtered, s)
		end
		for _, s in ipairs(serverlistmgr.servers or {}) do
			table.insert(all_filtered, s)
		end
	end

	if address and port then
		for _, server in ipairs(all_filtered) do
			if server.address == address and server.port == port then
				return server
			end
		end
	end

	if fallback_first and #all_filtered > 0 then
		for _, s in ipairs(all_filtered) do
			if s.is_compatible and s.address and s.port then
				core.settings:set("address", s.address)
				core.settings:set("remote_port", tostring(s.port))
				return s
			end
		end
		local first = all_filtered[1]
		if first and first.address and first.port then
			core.settings:set("address", first.address)
			core.settings:set("remote_port", tostring(first.port))
			return first
		end
	end

	return nil
end

local function make_divider_row(icon, color, title)
	local details = {
		icon,                          -- 1: section image (5, 6, 7)
		"", "",                        -- 2, 3: ping color, text
		"", "",                        -- 4, 5: players color, text
		"", "",                        -- 6, 7: version color, text
		"", "",                        -- 8, 9: mods color, text
		"0",                           -- 10: creative image (blank)
		"0",                           -- 11: damage image (blank)
		color,                         -- 12: title color
		core.formspec_escape("── " .. title .. " ──"), -- 13: section title text in server name column
	}
	assert(#details == 13)
	return table.concat(details, ",")
end

local function render_enriched_serverlist_row(spec, th)
	local c = (th and th.colors) or ((mainmenu and mainmenu.theme) and mainmenu.theme.colors) or {
		grey_out = "#aaaaaa",
		status_fav = "#fde047",
		text_primary = "#ffffff",
		text_muted = "#cbd5e1",
		ping_great = "#4ade80",
		ping_good = "#a3e635",
		ping_fair = "#facc15",
		ping_poor = "#f87171",
		clients_empty = "#64748b",
		clients_low = "#cbd5e1",
		clients_med = "#4ade80",
		clients_high = "#facc15",
		clients_max = "#ef4444",
		clients_orange = "#fb923c",
		brand_cyan = "#38bdf8",
	}

	local raw_name = ""
	if spec.name then
		raw_name = safe_trim(spec.name)
	elseif spec.address then
		raw_name = safe_trim(spec.address)
		if spec.port then
			raw_name = raw_name .. ":" .. spec.port
		end
	end
	raw_name = unescape_formspec_text(raw_name)

	local display_name = raw_name
	if #display_name > 36 then
		display_name = display_name:sub(1, 35) .. "…"
	end
	local text = core.formspec_escape(display_name)

	local grey_out = not spec.is_compatible
	local name_color = (grey_out and c.grey_out) or ((spec.is_favorite and c.status_fav) or c.text_primary)

	-- 1. Ping icon & 4/5. Ping text
	local ping_img = "0"
	local ping_color = c.text_muted
	local ping_text = "-"
	local ms = nil

	if spec.ping then
		if spec.ping < 10 then
			ms = math.floor(spec.ping * 1000)
		else
			ms = math.floor(spec.ping)
		end
	elseif spec.lag then
		if spec.lag < 10 then
			ms = math.floor(spec.lag * 1000)
		else
			ms = math.floor(spec.lag)
		end
	end

	local local_type = get_local_server_type(spec)

	if ms then
		ping_text = ms .. "ms"
		if ms <= 100 then
			ping_img = "1"
			ping_color = c.ping_great
		elseif ms <= 180 then
			ping_img = "2"
			ping_color = c.ping_good
		elseif ms <= 260 then
			ping_img = "3"
			ping_color = c.ping_fair
		else
			ping_img = "4"
			ping_color = c.ping_poor
		end
	elseif local_type == "localhost" then
		ping_text = "< 1ms"
		ping_img = "1"
		ping_color = c.ping_great
	elseif local_type == "lan" then
		ping_text = "LAN"
		ping_img = "1"
		ping_color = c.ping_great
	end

	-- 6/7. Players
	local clients_color = c.text_muted
	local clients_text = "?"
	if spec.clients ~= nil and spec.clients_max ~= nil then
		local max_c = math.max(1, spec.clients_max)
		local clients_percent = 100 * spec.clients / max_c
		if grey_out then
			clients_color = c.clients_empty
		elseif spec.clients == 0 then
			clients_color = c.clients_low
		elseif clients_percent <= 60 then
			clients_color = c.clients_med
		elseif clients_percent <= 90 then
			clients_color = c.clients_high
		elseif clients_percent >= 100 then
			clients_color = c.clients_max
		else
			clients_color = c.clients_orange
		end
		clients_text = format_client_count(spec.clients) .. "/" .. format_client_count(spec.clients_max)
	elseif spec.clients ~= nil then
		clients_text = tostring(spec.clients)
	elseif local_type then
		clients_color = c.brand_cyan
		clients_text = "Direct"
	end

	-- 8/9. Version (faded white for crisp readability matching local game mapgen)
	local version_color = c.text_muted or "#cbd5e1"
	local raw_ver = spec.version
	if (not raw_ver or raw_ver == "") and local_type then
		local v = core and core.get_version and core.get_version()
		raw_ver = (v and v.string) or "Luanti"
		version_color = c.text_primary
	end
	local version_text = (raw_ver and raw_ver ~= "" and raw_ver) or "-"
	if #version_text > 8 then
		version_text = version_text:sub(1, 8)
	end

	-- 10/11. Mods count
	local mods_color = c.brand_cyan
	local mod_count = (spec.mods and type(spec.mods) == "table" and #spec.mods) or 0
	local mods_text = mod_count > 0 and tostring(mod_count) or "-"

	-- 12. Creative icon
	local creative_img = spec.creative and "1" or "0"

	-- 13. Damage / PvP icon
	local damage_img = "0"
	if spec.pvp then
		damage_img = "2"
	elseif spec.damage then
		damage_img = "1"
	end

	local details = {
		ping_img,                          -- 1: ping icon
		ping_color, ping_text,             -- 2, 3: ping color, text
		clients_color, clients_text,       -- 4, 5: players color, text
		version_color, version_text,       -- 6, 7: version color, text
		mods_color, mods_text,             -- 8, 9: mods color, text
		creative_img,                      -- 10: creative mode icon
		damage_img,                        -- 11: damage/pvp icon
		name_color, text                   -- 12, 13: server name color, text
	}
	assert(#details == 13)
	return table.concat(details, ",")
end

function view_online.render(st, th)
	trigger_contentdb_prefetch()
	local fs = {}
	table.insert(fs, "container[3.3,0]")

	-- Main content background (Width: 18.3, Height: 12.0)
	table.insert(fs, string.format("box[0,0;18.3,12.0;%s]", th.colors.backdrop))

	----------------------------------------------------------------------------
	-- Top Search & Filter Toolbar
	----------------------------------------------------------------------------
	table.insert(fs, th.voxel_box(0.35, 0.25, 17.65, 0.95, th.colors.card_bg))

	-- Search field with search and clear action buttons
	local is_search_focused = (st.focused_field == "te_server_search")
	table.insert(fs, th.search_bar(0.55, 0.38, 5.60, 0.65, "te_server_search", st.server_search_query or "", is_search_focused, "btn_srv_search", "btn_srv_clear", fgettext("Search servers by name, game, or address")))

	-- Filter Buttons: All, Favorites, Compatible
	local filter_x = 7.85
	local filters = {
		{ id = "all",    name = "btn_filter_all",    label = fgettext("All"),        tip = fgettext("Show all online servers") },
		{ id = "fav",    name = "btn_filter_fav",    label = fgettext("Favorites"),  tip = fgettext("Show only bookmarked favorite servers") },
		{ id = "compat", name = "btn_filter_compat", label = fgettext("Compatible"), tip = fgettext("Show only servers compatible with your Luanti version") },
	}

	for _, flt in ipairs(filters) do
		local is_act = (st.server_filter == flt.id)
		table.insert(fs, th.button_tab(filter_x, 0.38, 1.7, 0.65, flt.name, flt.label, is_act, flt.tip))
		filter_x = filter_x + 1.85
	end

	-- Direct Connect modal trigger button
	table.insert(fs, th.button_secondary(13.45, 0.38, 3.6, 0.65, "btn_srv_direct_connect", "+ " .. fgettext("Direct Connect"), fgettext("Connect directly to a server by IP address or hostname")))

	-- Refresh button
	table.insert(fs, th.button_icon(17.20, 0.38, 0.65, 0.65, "btn_srv_refresh", defaulttexturedir .. "refresh.png", fgettext("Refresh server list")))

	----------------------------------------------------------------------------
	-- Main Split Area: Left = Server Table, Right = Server Details & Connect
	----------------------------------------------------------------------------
	local servers = get_filtered_servers(st)
	local selected_server = find_selected_server(servers, true)

	-- Left Panel: Server Table (Width: 11.9, Height: 10.45)
	table.insert(fs, th.voxel_box(0.35, 1.30, 11.9, 10.45, th.colors.card_bg))

	-- Header Bar Background
	table.insert(fs, string.format("box[0.45,1.35;11.6,0.44;%s]", th.colors.header_bar_bg))

	-- Interactive Clickable Column Header Buttons with Direction Arrows
	local sort_col = st.server_sort_col or "players"
	local sort_dir = st.server_sort_dir or "desc"
	local arrow = (sort_dir == "asc") and " ▲" or " ▼"

	local function make_header_button(x, w, col_id, base_title, tooltip_text)
		local is_active = (sort_col == col_id)
		local title = base_title .. (is_active and arrow or "")
		local btn_name = "btn_sort_" .. col_id

		-- Hover and pressed styling on the transparent clickable header button
		table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000]", btn_name))
		table.insert(fs, string.format("style[%s:hovered;border=false;sound=ui_click;bgcolor=#3e6c9c33]", btn_name))
		table.insert(fs, string.format("style[%s:pressed;border=false;sound=ui_click;bgcolor=#1d365044]", btn_name))
		table.insert(fs, string.format("style[%s:focused;border=false;bgcolor=#00000000]", btn_name))

		table.insert(fs, string.format("button[%.2f,1.35;%.2f,0.44;%s;]", x, w, btn_name))
		table.insert(fs, th.tooltip(btn_name, tooltip_text))

		if is_active then
			table.insert(fs, string.format("box[%.2f,1.75;%.2f,0.03;%s]", x, w, th.colors.brand_green_hover))
		end

		local text_color = is_active and th.colors.brand_green_hover or th.colors.text_muted
		table.insert(fs, string.format("style_type[label;font=bold;font_size=+0;textcolor=%s]", text_color))
		table.insert(fs, string.format("label[%.2f,1.57;%s]", x + 0.05, core.formspec_escape(title)))
	end

	make_header_button(0.45, 1.05, "ping", fgettext("Ping"), fgettext("Sort by Latency (Ping)"))
	make_header_button(1.50, 1.10, "players", fgettext("Players"), fgettext("Sort by Online Players"))
	make_header_button(2.60, 1.10, "version", fgettext("Version"), fgettext("Sort by Engine Version"))
	make_header_button(3.70, 0.80, "mods", fgettext("Mods"), fgettext("Sort by Active Mods Count (- indicates 0 reported or vanilla)"))
	make_header_button(4.50, 0.90, "flags", fgettext("Flags"), fgettext("Sort by Gameplay Flags (Creative / PvP)"))
	make_header_button(5.40, 6.65, "name", fgettext("Server Name"), fgettext("Sort alphabetically by Server Name"))

	-- Modern translucent table options and styling for server table
	table.insert(fs, th.tableoptions())
	table.insert(fs, string.format("style[servers;font=normal;%s]", th.font_size("table")))

	-- Define 13 enriched table columns with fixed aligned widths matching headers
	table.insert(fs, "tablecolumns[" ..
		"image," ..
		"0=" .. core.formspec_escape(defaulttexturedir .. "blank.png") .. "," ..
		"1=" .. core.formspec_escape(defaulttexturedir .. "server_ping_4.png") .. "," ..
		"2=" .. core.formspec_escape(defaulttexturedir .. "server_ping_3.png") .. "," ..
		"3=" .. core.formspec_escape(defaulttexturedir .. "server_ping_2.png") .. "," ..
		"4=" .. core.formspec_escape(defaulttexturedir .. "server_ping_1.png") .. "," ..
		"5=" .. core.formspec_escape(defaulttexturedir .. "server_favorite.png") .. "," ..
		"6=" .. core.formspec_escape(defaulttexturedir .. "server_public.png") .. "," ..
		"7=" .. core.formspec_escape(defaulttexturedir .. "server_incompatible.png") .. "," ..
		"align=inline,padding=0.15,width=1.30;" ..
		"color,span=1;" ..
		"text,align=left,padding=0.15,width=5.00;" ..
		"color,span=1;" ..
		"text,align=left,padding=0.20,width=6.70;" ..
		"color,span=1;" ..
		"text,align=left,padding=0.20,width=6.70;" ..
		"color,span=1;" ..
		"text,align=left,padding=0.20,width=4.80;" ..
		"image," ..
		"0=" .. core.formspec_escape(defaulttexturedir .. "blank.png") .. "," ..
		"1=" .. core.formspec_escape(defaulttexturedir .. "server_flags_creative.png") .. "," ..
		"align=inline,padding=0.20,width=2.40;" ..
		"image," ..
		"0=" .. core.formspec_escape(defaulttexturedir .. "blank.png") .. "," ..
		"1=" .. core.formspec_escape(defaulttexturedir .. "server_flags_damage.png") .. "," ..
		"2=" .. core.formspec_escape(defaulttexturedir .. "server_flags_pvp.png") .. "," ..
		"align=left,padding=0.20,width=2.80;" ..
		"color,span=1;" ..
		"text,align=left,padding=0.25]")

	-- Populate Table Rows
	local rows = {}
	menudata.server_lookup = {}
	local selected_row = 1

	local sections = {
		{ id = "fav",          icon = "5", color = th.colors.warn_gold,   title = fgettext("Favorites") },
		{ id = "public",       icon = "6", color = th.colors.brand_green, title = fgettext("Public Servers") },
		{ id = "incompatible", icon = "7", color = th.colors.text_muted,  title = fgettext("Incompatible Servers") },
	}

	for _, sec in ipairs(sections) do
		local list = servers[sec.id]
		if list and #list > 0 then
			table.insert(rows, make_divider_row(sec.icon, sec.color, sec.title))
			for _, srv in ipairs(list) do
				table.insert(rows, render_enriched_serverlist_row(srv, th))
				local row_idx = #rows
				menudata.server_lookup[row_idx] = srv
				if selected_server and srv.address == selected_server.address and srv.port == selected_server.port then
					selected_row = row_idx
				end
			end
		end
	end

	local total_count = #servers.fav + #servers.public + #servers.incompatible
	if total_count == 0 then
		local q_text = safe_trim(st.server_search_query or "")
		local empty_msg
		if q_text ~= "" then
			empty_msg = fgettext("No servers matching '$1'", q_text)
		else
			empty_msg = fgettext("No servers available")
		end
		table.insert(rows, make_divider_row("0", th.colors.text_muted, empty_msg))
	end

	table.insert(fs, string.format("table[0.45,1.85;11.6,9.75;servers;%s;%d]", table.concat(rows, ","), selected_row))

	-- Column Cell Tooltips with unified modern styling matching the rest of the UI (translucent obsidian slate)
	table.insert(fs, th.tooltip_area(0.45, 1.85, 1.05, 9.75, fgettext("Ping: Connection latency indicator (lower ms is better)")))
	table.insert(fs, th.tooltip_area(1.50, 1.85, 1.10, 9.75, fgettext("Players: Active online players / Server player capacity")))
	table.insert(fs, th.tooltip_area(2.60, 1.85, 1.10, 9.75, fgettext("Engine Version: Luanti server release and protocol version")))
	table.insert(fs, th.tooltip_area(3.70, 1.85, 0.80, 9.75, fgettext("Active Mods: Count of reported mods (- indicates 0 reported or vanilla)")))
	table.insert(fs, th.tooltip_area(4.50, 1.85, 0.90, 9.75, fgettext("Gameplay Rules: Creative mode and Damage / PvP status")))
	table.insert(fs, th.tooltip_area(5.40, 1.85, 6.65, 9.75, fgettext("Server Name: Select server to view full title - description - address and details")))

	----------------------------------------------------------------------------
	-- Right Panel: Selected Server Information & Connect Deck (Width: 5.60, Height: 10.45)
	----------------------------------------------------------------------------
	table.insert(fs, th.voxel_box(12.40, 1.30, 5.60, 10.45, th.colors.card_bg))

	if selected_server then
		local srv_name = (selected_server.name and selected_server.name ~= "") and selected_server.name or selected_server.address or ""
		srv_name = unescape_formspec_text(srv_name)
		table.insert(fs, "style_type[label;font=bold;font_size=+1;textcolor=" .. th.colors.brand_green_hover .. "]")
		local title_display = srv_name
		if #title_display > 30 then
			title_display = title_display:sub(1, 29) .. "…"
		end
		table.insert(fs, string.format("label[12.6,1.60;%s]", core.formspec_escape(title_display)))
		table.insert(fs, th.tooltip_area(12.55, 1.40, 5.30, 0.45, srv_name))
		table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_muted .. "]")

		local endpoint = (selected_server.address or "") .. ":" .. tostring(selected_server.port or "")
		local sel_local_type = get_local_server_type(selected_server)
		local endpoint_badge = ""
		if sel_local_type == "localhost" then
			endpoint_badge = " [Localhost]"
		elseif sel_local_type == "lan" then
			endpoint_badge = " [LAN]"
		end
		table.insert(fs, string.format("label[12.6,1.95;%s: %s%s]",
			core.formspec_escape(fgettext("Address")),
			core.formspec_escape(endpoint),
			core.formspec_escape(endpoint_badge)))

		-- Latency Value
		local ping_val = "N/A"
		local ping_clr = th.colors.text_primary
		local raw_ping = selected_server.ping or selected_server.lag
		if raw_ping then
			if raw_ping < 10 then
				ping_val = tostring(math.floor(raw_ping * 1000)) .. " ms"
			else
				ping_val = tostring(math.floor(raw_ping)) .. " ms"
			end
		elseif sel_local_type == "localhost" then
			ping_val = "< 1 ms"
			ping_clr = th.colors.ping_great or th.colors.brand_green_hover
		elseif sel_local_type == "lan" then
			ping_val = "LAN"
			ping_clr = th.colors.ping_great or th.colors.brand_green_hover
		end

		-- Players Value
		local players_val = "?"
		local players_clr = th.colors.text_primary
		if selected_server.clients ~= nil and selected_server.clients_max ~= nil then
			players_val = string.format("%s / %s",
				format_client_count(selected_server.clients),
				format_client_count(selected_server.clients_max)
			)
		elseif selected_server.clients ~= nil then
			players_val = tostring(selected_server.clients)
		elseif sel_local_type then
			players_val = "Direct"
			players_clr = th.colors.brand_cyan
		end

		-- Version Value
		local ver_val = selected_server.version
		if (not ver_val or ver_val == "") and sel_local_type then
			local v = core and core.get_version and core.get_version()
			ver_val = (v and v.string) or "Luanti"
		end
		ver_val = (ver_val and ver_val ~= "") and ver_val or "Luanti"

		-- Mod Count Value
		local mod_count = (selected_server.mods and type(selected_server.mods) == "table" and #selected_server.mods) or 0
		local mods_val
		if mod_count > 0 then
			mods_val = string.format("%d Mods", mod_count)
		elseif sel_local_type then
			mods_val = "Direct"
		else
			mods_val = "0 Mods"
		end

		-- 4 Clickable Metric Tiles (Latency, Players, Engine, Active Mods)
		local info_tab = st.server_info_tab or "latency"

		local function render_metric_tile(tx, ty, tw, th_h, btn_name, icon_name, val_str, title_str, is_act, val_clr, tip_str)
			if th and th.metric_tile then
				table.insert(fs, th.metric_tile(tx, ty, tw, th_h, btn_name, icon_name, val_str, title_str, is_act, val_clr, tip_str))
			else
				-- Base tile card background
				if is_act then
					table.insert(fs, th.voxel_box(tx, ty, tw, th_h, th.colors.tile_active_bg, th.colors.brand_green, th.colors.brand_green_dark))
				else
					table.insert(fs, th.voxel_box(tx, ty, tw, th_h, th.colors.card_inner_bg))
				end

				-- Button layer (clean vector bgcolor hover/press states, no stretched images)
				if is_act then
					table.insert(fs, string.format("style[%s;border=true;bgcolor=%s;sound=ui_click]", btn_name, th.colors.tile_btn_active_bg))
					table.insert(fs, string.format("style[%s:hovered;border=true;bgcolor=%s]", btn_name, th.colors.tile_btn_active_hover))
					table.insert(fs, string.format("style[%s:focused;border=true;bordercolor=%s;bgcolor=%s]",
						btn_name, th.colors.tile_btn_active_focus, th.colors.tile_btn_active_bg))
					table.insert(fs, string.format("style[%s:focused+hovered;border=true;bordercolor=%s;bgcolor=%s]",
						btn_name, th.colors.tile_btn_active_focus, th.colors.tile_btn_active_hover))
					table.insert(fs, string.format("style[%s:pressed;border=true;bgcolor=%s]", btn_name, th.colors.tile_btn_active_pressed))
				else
					table.insert(fs, string.format("style[%s;border=true;bgcolor=%s;sound=ui_click]", btn_name, th.colors.tile_btn_bg))
					table.insert(fs, string.format("style[%s:hovered;border=true;bgcolor=%s]", btn_name, th.colors.tile_btn_hover))
					table.insert(fs, string.format("style[%s:focused;border=true;bordercolor=%s;bgcolor=%s]",
						btn_name, th.colors.tile_btn_focus, th.colors.tile_btn_bg))
					table.insert(fs, string.format("style[%s:focused+hovered;border=true;bordercolor=%s;bgcolor=%s]",
						btn_name, th.colors.tile_btn_focus, th.colors.tile_btn_hover))
					table.insert(fs, string.format("style[%s:pressed;border=true;bgcolor=%s]", btn_name, th.colors.tile_btn_pressed))
				end
				table.insert(fs, string.format("button[%f,%f;%f,%f;%s;]", tx, ty, tw, th_h, btn_name))
				table.insert(fs, th.tooltip(btn_name, tip_str))

				-- Active indicator accent bar
				if is_act then
					table.insert(fs, string.format("box[%f,%f;%f,0.04;%s]", tx, ty, tw, th.colors.brand_green_hover))
				end

				-- Foreground Icon (rendered on top of button; engine passes clicks through)
				table.insert(fs, string.format("image[%f,%f;0.58,0.58;%s]", tx + 0.10, ty + 0.10,
					core.formspec_escape(defaulttexturedir .. icon_name)))

				-- Foreground Metric Value (rendered on top of button, with balanced top padding)
				table.insert(fs, "style_type[label;font=bold;font_size=+0;textcolor=" ..
					(is_act and th.colors.brand_green_hover or val_clr) .. "]")
				table.insert(fs, string.format("label[%f,%f;%s]", tx + 0.80, ty + 0.25, core.formspec_escape(val_str)))

				-- Foreground Subtitle Label (rendered on top of button)
				table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" ..
					(is_act and th.colors.brand_green_light or th.colors.text_muted) .. "]")
				table.insert(fs, string.format("label[%f,%f;%s]", tx + 0.80, ty + 0.53, core.formspec_escape(title_str)))
			end
		end

		render_metric_tile(12.55, 2.30, 2.58, 0.78,
			"btn_tile_ping", "server_ping_4.png", ping_val, fgettext("Latency"),
			info_tab == "latency", ping_clr,
			fgettext("Click to view connection quality and server description"))

		render_metric_tile(15.27, 2.30, 2.58, 0.78,
			"btn_tile_players", "server_view_clients.png", players_val, fgettext("Online"),
			info_tab == "players", players_clr,
			fgettext("Click to view active online player roster"))

		render_metric_tile(12.55, 3.16, 2.58, 0.78,
			"btn_tile_engine", "settings_info.png", ver_val:sub(1, 10), fgettext("Engine"),
			info_tab == "engine", th.colors.text_secondary,
			fgettext("Click to view engine compatibility and gameplay rules"))

		local mods_tip = (mod_count > 0)
			and fgettext("Click to inspect complete list of all $1 server mods", mod_count)
			or (sel_local_type and fgettext("Local / direct connection server. Active mods load upon joining. Click for details.")
			    or fgettext("0 custom mods reported: Server runs pure vanilla or conceals mod list from announcements. Click for details."))

		render_metric_tile(15.27, 3.16, 2.58, 0.78,
			"btn_tile_mods", "server_view_mods.png", mods_val, fgettext("Active Mods"),
			info_tab == "mods", th.colors.brand_cyan,
			mods_tip)

		------------------------------------------------------------------------
		-- Dynamic In-Place Detail Inspector Deck (Height: 4.35, cleanly terminates at y = 8.40)
		------------------------------------------------------------------------
		table.insert(fs, th.voxel_box(12.55, 4.05, 5.30, 4.35, th.colors.card_inner_bg))

		if info_tab == "players" then
			-- Online Players Sub-view
			table.insert(fs, string.format("box[12.55,4.05;5.30,0.43;%s]", th.colors.inspector_header_bg))
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("title"), th.colors.brand_green_hover))
			local cur_c = format_client_count(selected_server.clients or 0)
			local max_c = selected_server.clients_max and format_client_count(selected_server.clients_max) or "?"
			table.insert(fs, string.format("label[12.75,4.27;%s]",
				core.formspec_escape(fgettext("ONLINE PLAYERS ($1 / $2)", cur_c, max_c))))
			table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")

			local plist = selected_server.clients_list
			if plist and #plist > 0 then
				local sorted_plist = {}
				for _, p in ipairs(plist) do
					table.insert(sorted_plist, p)
				end
				table.sort(sorted_plist, function(a, b) return a:lower() < b:lower() end)
				local items = {}
				for _, p in ipairs(sorted_plist) do
					items[#items + 1] = core.formspec_escape(p)
				end
				table.insert(fs, th.tableoptions())
				table.insert(fs, "tablecolumns[text]")
				table.insert(fs, string.format("style[online_player_list;font=normal;%s]", th.font_size("table")))
				local sel_p = tonumber(st.selected_server_player) or 0
				table.insert(fs, string.format("table[12.65,4.48;5.10,3.80;online_player_list;%s;%d]",
					table.concat(items, ","), sel_p))
			else
				table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_muted .. "]")
				if sel_local_type then
					table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("body"), th.colors.brand_green_hover))
					table.insert(fs, string.format("label[12.8,5.1;%s]",
						core.formspec_escape(fgettext("Direct Connection Server"))))
					table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_secondary))
					table.insert(fs, string.format("label[12.8,5.55;%s]",
						core.formspec_escape(fgettext("Connected player roster is retrieved upon joining."))))
					table.insert(fs, string.format("label[12.8,5.95;%s]",
						core.formspec_escape(fgettext("Private server not listed on public master lists."))))
				else
					table.insert(fs, string.format("label[12.8,5.2;%s]",
						core.formspec_escape(fgettext("No player names announced"))))
				end
			end

		elseif info_tab == "engine" then
			-- Engine & Compatibility Rules Sub-view
			table.insert(fs, string.format("box[12.55,4.05;5.30,0.43;%s]", th.colors.inspector_header_bg))
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("title"), th.colors.brand_green_hover))
			table.insert(fs, string.format("label[12.75,4.27;%s]",
				core.formspec_escape(fgettext("ENGINE & RULES"))))
			table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")

			-- 1. Base Game Resolution
			local raw_gameid = selected_server.gameid
			local game_title
			if raw_gameid and raw_gameid ~= "" then
				local pkg = (pkgmgr and pkgmgr.find_by_gameid and pkgmgr.find_by_gameid(raw_gameid))
				if pkg and pkg.title and pkg.title ~= "" and pkg.title:lower() ~= raw_gameid:lower() then
					game_title = string.format("%s (%s)", pkg.title, raw_gameid)
				else
					game_title = (pkg and pkg.title) or raw_gameid
				end
			elseif sel_local_type then
				game_title = fgettext("Local Server / Engine Default")
			else
				game_title = fgettext("Not announced (Vanilla / Custom)")
			end
			local disp_game_title = truncate_str(game_title, 24)

			-- 2. Engine Version Resolution
			local ver_str = selected_server.version
			if (not ver_str or ver_str == "") and sel_local_type then
				local v = core and core.get_version and core.get_version()
				ver_str = (v and v.string) or fgettext("Luanti")
			end
			ver_str = (ver_str and ver_str ~= "") and ver_str or fgettext("Luanti")
			local disp_ver = truncate_str(ver_str, 16)

			-- Top Highlight Banner: Base Game & Engine Version
			table.insert(fs, string.format("box[12.65,4.58;5.10,0.62;#1e293b77]"))
			table.insert(fs, string.format("box[12.65,4.58;0.05,0.62;%s]", th.colors.brand_green_hover))

			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
			table.insert(fs, string.format("label[12.80,4.73;%s]", core.formspec_escape(fgettext("BASE GAME"))))
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("body"), th.colors.brand_green_hover))
			table.insert(fs, string.format("label[12.80,4.98;%s]", core.formspec_escape(disp_game_title)))
			table.insert(fs, th.tooltip_area(12.65, 4.58, 2.90, 0.62, fgettext("Server Base Game: $1", game_title)))

			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
			table.insert(fs, string.format("label[15.80,4.73;%s]", core.formspec_escape(fgettext("ENGINE VERSION"))))
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("body"), th.colors.text_primary))
			table.insert(fs, string.format("label[15.80,4.98;%s]", core.formspec_escape(disp_ver)))
			table.insert(fs, th.tooltip_area(15.70, 4.58, 2.05, 0.62, fgettext("Server Engine Version: $1", ver_str)))

			-- 3. Specs & Rules Grid (2 Columns)
			table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("body"), th.colors.text_secondary))

			local proto_min = selected_server.proto_min
			local proto_max = selected_server.proto_max
			if (not proto_min or not proto_max) and sel_local_type then
				if core and core.get_min_supp_proto and core.get_max_supp_proto then
					proto_min = core.get_min_supp_proto()
					proto_max = core.get_max_supp_proto()
				end
			end
			proto_min = proto_min or "?"
			proto_max = proto_max or "?"
			local is_compat = nil
			if sel_local_type then
				is_compat = true
			elseif rawget(_G, "is_server_protocol_compat") and selected_server.proto_min and selected_server.proto_max then
				is_compat = is_server_protocol_compat(selected_server.proto_min, selected_server.proto_max)
			end

			-- Row 1: Protocol (Left) & Game Mode (Right)
			local proto_str = string.format("%s: %s - %s",
				core.formspec_escape(fgettext("Protocol")),
				core.formspec_escape(tostring(proto_min)),
				core.formspec_escape(tostring(proto_max)))
			table.insert(fs, string.format("label[12.80,5.48;%s]", proto_str))

			local is_creative = selected_server.creative
			local mode_str = is_creative and fgettext("Creative Mode") or fgettext("Survival Mode")
			table.insert(fs, string.format("label[15.35,5.48;%s: %s]",
				core.formspec_escape(fgettext("Mode")),
				core.formspec_escape(mode_str)))

			-- Row 2: Step Dt (Lag) (Left) & PvP Combat (Right)
			local lag_str = (selected_server.lag ~= nil) and string.format("%.3fs", selected_server.lag) or fgettext("N/A")
			table.insert(fs, string.format("label[12.80,5.96;%s: %s]",
				core.formspec_escape(fgettext("Step Dt")),
				core.formspec_escape(lag_str)))

			local is_pvp = selected_server.pvp
			local pvp_str = (is_pvp == nil) and "?" or (is_pvp and fgettext("Enabled") or fgettext("Disabled"))
			table.insert(fs, string.format("label[15.35,5.96;%s: %s]",
				core.formspec_escape(fgettext("PvP")),
				core.formspec_escape(pvp_str)))

			-- Row 3: Architecture (Left) & Damage (Right)
			local ded_str
			if selected_server.dedicated ~= nil then
				ded_str = selected_server.dedicated and fgettext("Dedicated") or fgettext("Listen")
			elseif sel_local_type == "localhost" then
				ded_str = fgettext("Localhost")
			elseif sel_local_type == "lan" then
				ded_str = fgettext("LAN Server")
			else
				ded_str = fgettext("Dedicated")
			end
			table.insert(fs, string.format("label[12.80,6.44;%s: %s]",
				core.formspec_escape(fgettext("Arch")),
				core.formspec_escape(ded_str)))

			local is_damage = selected_server.damage
			local dmg_str = (is_damage == nil) and "?" or (is_damage and fgettext("Enabled") or fgettext("Disabled"))
			table.insert(fs, string.format("label[15.35,6.44;%s: %s]",
				core.formspec_escape(fgettext("Damage")),
				core.formspec_escape(dmg_str)))

			-- Row 4: Uptime (Left) & Rollback (Right)
			local up_str
			if selected_server.uptime and type(selected_server.uptime) == "number" and selected_server.uptime > 0 then
				local u = selected_server.uptime
				if u >= 86400 then
					up_str = string.format("%dd %dh", math.floor(u / 86400), math.floor((u % 86400) / 3600))
				elseif u >= 3600 then
					up_str = string.format("%dh %dm", math.floor(u / 3600), math.floor((u % 3600) / 60))
				elseif u >= 60 then
					up_str = string.format("%dm", math.floor(u / 60))
				else
					up_str = "< 1m"
				end
			else
				up_str = fgettext("N/A")
			end
			table.insert(fs, string.format("label[12.80,6.92;%s: %s]",
				core.formspec_escape(fgettext("Uptime")),
				core.formspec_escape(up_str)))

			local rollback_str = selected_server.rollback and fgettext("Yes") or fgettext("No")
			table.insert(fs, string.format("label[15.35,6.92;%s: %s]",
				core.formspec_escape(fgettext("Rollback")),
				core.formspec_escape(rollback_str)))

			-- Row 5: Peak Players (Left) & Password / Auth (Right)
			local peak_str = (selected_server.clients_top and selected_server.clients_top > 0)
				and string.format("%d %s", selected_server.clients_top, fgettext("players"))
				or ((selected_server.clients_max and tostring(selected_server.clients_max) .. " " .. fgettext("slots")) or fgettext("N/A"))
			table.insert(fs, string.format("label[12.80,7.40;%s: %s]",
				core.formspec_escape(fgettext("Peak")),
				core.formspec_escape(peak_str)))

			local pwd_str
			if selected_server.password ~= nil then
				pwd_str = selected_server.password and fgettext("Required") or fgettext("None")
			else
				pwd_str = fgettext("Open")
			end
			table.insert(fs, string.format("label[15.35,7.40;%s: %s]",
				core.formspec_escape(fgettext("Password")),
				core.formspec_escape(pwd_str)))

			-- 4. Footer: Client Protocol Compatibility Badge
			local compat_msg, compat_col
			if is_compat == false then
				compat_msg = fgettext("⚠ Protocol mismatch: client may be incompatible")
				compat_col = th.colors.warn_gold
			elseif sel_local_type then
				compat_msg = fgettext("✓ Protocol compatible (Local client & engine)")
				compat_col = th.colors.brand_green_hover
			else
				compat_msg = fgettext("✓ Protocol compatible with this client")
				compat_col = th.colors.brand_green_hover
			end
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), compat_col))
			table.insert(fs, string.format("label[12.80,7.96;%s]", core.formspec_escape(compat_msg)))
			table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")

		elseif info_tab == "mods" then
			-- Server Mods Sub-view
			table.insert(fs, string.format("box[12.55,4.05;5.30,0.43;%s]", th.colors.inspector_header_bg))
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("title"), th.colors.brand_green_hover))
			table.insert(fs, string.format("label[12.75,4.27;%s]",
				core.formspec_escape(fgettext("SERVER MODS ($1)", mod_count))))
			table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")

			local mlist = selected_server.mods
			if mlist and type(mlist) == "table" and #mlist > 0 then
				local sorted_mods = {}
				for _, m in ipairs(mlist) do
					table.insert(sorted_mods, m)
				end
				table.sort(sorted_mods, function(a, b) return a:lower() < b:lower() end)

				local has_cdb = _G.contentdb and (_G.contentdb.load_ok or (#(_G.contentdb.packages_full or {}) > 0))
				if has_cdb then
					local cdb_lookup = get_contentdb_mod_lookup()
					local mod_filter = (st.get and st.get("server_mod_filter")) or st.server_mod_filter or ""
					local query = mod_filter:lower():match("^%s*(.-)%s*$") or ""
					local is_mod_search_focused = (st.focused_field == "te_server_mod_search")

					-- Compact search bar for server mods (symmetric 0.08 padding above & below)
					table.insert(fs, th.search_bar(12.65, 4.56, 4.15, 0.40, "te_server_mod_search", mod_filter, is_mod_search_focused, "btn_srv_mod_search", "btn_srv_mod_clear", fgettext("Filter active server mods")))

					local filtered_mods = {}
					for _, m in ipairs(sorted_mods) do
						if query == "" then
							table.insert(filtered_mods, m)
						else
							local pkg = cdb_lookup[m:lower()]
							local match = m:lower():find(query, 1, true)
							if not match and pkg then
								if (pkg.title and pkg.title:lower():find(query, 1, true)) or
								   (pkg.author and pkg.author:lower():find(query, 1, true)) then
									match = true
								end
							end
							if match then
								table.insert(filtered_mods, m)
							end
						end
					end

					if not menudata then menudata = {} end
					menudata.online_filtered_mods = {}
					menudata.online_filtered_cdb = {}
					for i, m in ipairs(filtered_mods) do
						menudata.online_filtered_mods[i] = m
						menudata.online_filtered_cdb[i] = cdb_lookup[m:lower()]
					end

					local expanded_table = (st.get and st.get("online_mods_expanded")) or st.online_mods_expanded or {}
					local s_scroll = (st.get and st.get("server_mods_scroll")) or st.server_mods_scroll or 0

					table.insert(fs, string.format("scroll_container[12.65,5.04;4.85,3.26;server_mods_scroll;vertical;0.1;0.25]"))

					local cur_y = 0.0
					local row_w = 4.75

					if #filtered_mods == 0 then
						table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.warn_gold))
						table.insert(fs, string.format("label[0.3,0.8;%s]",
							core.formspec_escape(fgettext("No mods match '$1'", mod_filter))))
						table.insert(fs, string.format("style[btn_srv_mod_clear;border=false;bgcolor=%s;textcolor=%s;font=normal;%s]",
							th.colors.btn_secondary_bg, th.colors.text_primary, th.font_size("caption")))
						table.insert(fs, string.format("button[0.9,1.4;3.0,0.40;btn_srv_mod_clear;%s]",
							core.formspec_escape(fgettext("Clear Search"))))
						cur_y = 2.0
					else
						for i, mod_name in ipairs(filtered_mods) do
							local pkg = cdb_lookup[mod_name:lower()]
							local is_expanded = expanded_table[mod_name] == true

							if is_expanded and pkg then
								-- Expanded Card
								table.insert(fs, string.format("box[0.00,%.2f;%.2f,1.60;#0f172acc]", cur_y, row_w))
								table.insert(fs, string.format("box[0.00,%.2f;0.06,1.60;%s]", cur_y, th.colors.brand_green_hover))

								-- Collapse toggle button [-]
								table.insert(fs, string.format("style[btn_mod_exp_%d;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
									i, th.colors.btn_secondary_bg, th.colors.brand_green_hover, th.font_size("button")))
								table.insert(fs, string.format("button[0.10,%.2f;0.34,0.30;btn_mod_exp_%d;-]", cur_y + 0.05, i))
								table.insert(fs, string.format("tooltip[btn_mod_exp_%d;%s]", i, core.formspec_escape(fgettext("Collapse details"))))

								-- Mod technical name & ContentDB badge
								local disp_name = truncate_str(mod_name, 18)
								table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_primary))
								table.insert(fs, string.format("label[0.50,%.2f;%s]", cur_y + 0.18, core.formspec_escape(disp_name)))

								table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.brand_green_hover))
								table.insert(fs, string.format("label[3.20,%.2f;%s]", cur_y + 0.18, core.formspec_escape("[ContentDB]")))

								-- Title and author
								local title_str = pkg.title or mod_name
								local author_str = pkg.author and ("by " .. pkg.author) or ""
								local title_line = truncate_str(title_str .. " " .. author_str, 34)
								table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.brand_cyan))
								table.insert(fs, string.format("label[0.15,%.2f;%s]", cur_y + 0.52, core.formspec_escape(title_line)))

								-- Short description
								local desc = pkg.short_description or fgettext("No description available on ContentDB.")
								desc = truncate_str(desc, 42)
								table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_secondary))
								table.insert(fs, string.format("label[0.15,%.2f;%s]", cur_y + 0.82, core.formspec_escape(desc)))

								-- Action Buttons: [ 🌐 View on CDB ] and [ 🔍 Search CDB ]
								local btn_y = cur_y + 1.14
								table.insert(fs, string.format("style[btn_cdb_view_%d;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
									i, th.colors.brand_green, th.colors.text_primary, th.font_size("caption")))
								table.insert(fs, string.format("button[0.15,%.2f;2.35,0.36;btn_cdb_view_%d;%s]",
									btn_y, i, core.formspec_escape(fgettext("🌐 View Details"))))
								table.insert(fs, string.format("tooltip[btn_cdb_view_%d;%s]", i, core.formspec_escape(fgettext("Open package details to view screenshots and install"))))

								table.insert(fs, string.format("style[btn_cdb_search_%d;border=false;bgcolor=%s;textcolor=%s;font=normal;%s]",
									i, th.colors.btn_secondary_bg, th.colors.text_primary, th.font_size("caption")))
								table.insert(fs, string.format("button[2.58,%.2f;2.02,0.36;btn_cdb_search_%d;%s]",
									btn_y, i, core.formspec_escape(fgettext("🔍 Search"))))
								table.insert(fs, string.format("tooltip[btn_cdb_search_%d;%s]", i, core.formspec_escape(fgettext("Search ContentDB catalog for this mod"))))

								cur_y = cur_y + 1.68
							else
								-- Collapsed Row
								local bg_col = pkg and "#1e293b77" or "#11182744"
								table.insert(fs, string.format("box[0.00,%.2f;%.2f,0.40;%s]", cur_y, row_w, bg_col))

								if pkg then
									-- Expand toggle button [+]
									table.insert(fs, string.format("style[btn_mod_exp_%d;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
										i, th.colors.btn_secondary_bg, th.colors.brand_green_hover, th.font_size("button")))
									table.insert(fs, string.format("button[0.06,%.2f;0.34,0.30;btn_mod_exp_%d;+]", cur_y + 0.05, i))
									table.insert(fs, string.format("tooltip[btn_mod_exp_%d;%s]", i, core.formspec_escape(fgettext("Expand ContentDB details"))))

									local disp_name = truncate_str(mod_name, 19)
									table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_primary))
									table.insert(fs, string.format("label[0.48,%.2f;%s]", cur_y + 0.20, core.formspec_escape(disp_name)))

									table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.brand_green_hover))
									table.insert(fs, string.format("label[3.20,%.2f;%s]", cur_y + 0.20, core.formspec_escape("[ContentDB]")))
								else
									-- Non-CDB mod: direct search button [🔍]
									table.insert(fs, string.format("style[btn_cdb_search_%d;border=false;bgcolor=%s;textcolor=%s;font=normal;%s]",
										i, th.colors.btn_secondary_bg, th.colors.text_primary, th.font_size("caption")))
									table.insert(fs, string.format("button[0.06,%.2f;0.34,0.30;btn_cdb_search_%d;🔍]", cur_y + 0.05, i))
									table.insert(fs, string.format("tooltip[btn_cdb_search_%d;%s]", i, core.formspec_escape(fgettext("Search ContentDB for mod"))))

									local disp_name = truncate_str(mod_name, 22)
									table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_secondary))
									table.insert(fs, string.format("label[0.48,%.2f;%s]", cur_y + 0.20, core.formspec_escape(disp_name)))

									table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
									table.insert(fs, string.format("label[3.55,%.2f;%s]", cur_y + 0.20, core.formspec_escape("(Server)")))
								end

								cur_y = cur_y + 0.46
							end
						end
					end

					table.insert(fs, "scroll_container_end[]")

					-- Dynamic scrollbar if content exceeds container height
					local visible_h = 3.26
					local scroll_factor = 0.1
					if cur_y > visible_h then
						local max_scroll_dist = math.max(0, cur_y - visible_h)
						local scroll_max = math.max(10, math.ceil(max_scroll_dist / scroll_factor))
						local thumb_size = math.max(10, math.floor(visible_h / scroll_factor))
						local clamped_scroll = math.min(s_scroll, scroll_max)

						table.insert(fs, string.format("scrollbaroptions[min=0;max=%d;smallstep=5;largestep=25;thumbsize=%d]", scroll_max, thumb_size))
						table.insert(fs, string.format("scrollbar[17.55,5.04;0.25,3.26;vertical;server_mods_scroll;%d]", clamped_scroll))
					end
				else
					local items = {}
					for _, m in ipairs(sorted_mods) do
						items[#items + 1] = core.formspec_escape(m)
					end
					table.insert(fs, th.tableoptions())
					table.insert(fs, "tablecolumns[text]")
					table.insert(fs, string.format("style[server_mods_list;font=normal;%s]", th.font_size("table")))
					local sel_m = tonumber(st.selected_server_mod) or 0
					table.insert(fs, string.format("table[12.65,4.48;5.10,3.80;server_mods_list;%s;%d]",
						table.concat(items, ","), sel_m))
				end
			else
				local is_loc = (sel_local_type ~= nil)
				table.insert(fs, "style_type[label;font=bold;font_size=+0;textcolor=" .. (is_loc and th.colors.brand_green_hover or th.colors.warn_gold) .. "]")
				local no_mods_title = is_loc
					and fgettext("Direct / Local Network Server")
					or fgettext("No custom mods reported.")
				table.insert(fs, string.format("label[12.75,4.75;%s]", core.formspec_escape(no_mods_title)))

				table.insert(fs, "style_type[label;font=bold;font_size=+0;textcolor=" .. th.colors.text_primary .. "]")
				table.insert(fs, string.format("label[12.75,5.20;%s]",
					core.formspec_escape(is_loc and fgettext("Direct Connection Details:") or fgettext("Possible Reasons:"))))

				local r_bullet = "  • "
				if is_loc then
					table.insert(fs, "style_type[label;font=bold;font_size=+0;textcolor=" .. th.colors.brand_cyan .. "]")
					table.insert(fs, string.format("label[12.75,5.65;%s]",
						core.formspec_escape(r_bullet .. fgettext("Private Server"))))
					table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")
					table.insert(fs, string.format("label[13.15,5.95;%s]",
						core.formspec_escape(fgettext("Server is private and not indexed on public server lists."))))

					table.insert(fs, "style_type[label;font=bold;font_size=+0;textcolor=" .. th.colors.brand_cyan .. "]")
					table.insert(fs, string.format("label[12.75,6.45;%s]",
						core.formspec_escape(r_bullet .. fgettext("Automatic Media Sync"))))
					table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")
					table.insert(fs, string.format("label[13.15,6.75;%s]",
						core.formspec_escape(fgettext("All active server mods and media download upon joining."))))

					table.insert(fs, "style_type[label;font=bold;font_size=+0;textcolor=" .. th.colors.brand_cyan .. "]")
					table.insert(fs, string.format("label[12.75,7.25;%s]",
						core.formspec_escape(r_bullet .. fgettext("Local Direct Access"))))
					table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")
					table.insert(fs, string.format("label[13.15,7.55;%s]",
						core.formspec_escape(fgettext("Directly joinable without internet routing or port forwarding."))))
				else
					table.insert(fs, "style_type[label;font=bold;font_size=+0;textcolor=" .. th.colors.brand_cyan .. "]")
					table.insert(fs, string.format("label[12.75,5.65;%s]",
						core.formspec_escape(r_bullet .. fgettext("Pure Vanilla server"))))
					table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")
					table.insert(fs, string.format("label[13.15,5.95;%s]",
						core.formspec_escape(fgettext("Runs unmodified game without extra mods."))))

					table.insert(fs, "style_type[label;font=bold;font_size=+0;textcolor=" .. th.colors.brand_cyan .. "]")
					table.insert(fs, string.format("label[12.75,6.45;%s]",
						core.formspec_escape(r_bullet .. fgettext("Modlist not broadcast"))))
					table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")
					table.insert(fs, string.format("label[13.15,6.75;%s]",
						core.formspec_escape(fgettext("Server keeps active mod names hidden."))))

					table.insert(fs, "style_type[label;font=bold;font_size=+0;textcolor=" .. th.colors.brand_cyan .. "]")
					table.insert(fs, string.format("label[12.75,7.25;%s]",
						core.formspec_escape(r_bullet .. fgettext("Server-side dynamic content"))))
					table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")
					table.insert(fs, string.format("label[13.15,7.55;%s]",
						core.formspec_escape(fgettext("Required media downloads upon joining."))))
				end

				-- Helpful pointer to Engine tab for base game details
				table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.brand_green_hover))
				table.insert(fs, string.format("label[12.75,8.05;%s]",
					core.formspec_escape(fgettext("ℹ Switch to Engine tab to view Base Game & rules"))))
			end

		else
			-- Default Sub-view: Latency & Server Details
			table.insert(fs, string.format("box[12.55,4.05;5.30,0.43;%s]", th.colors.inspector_header_bg))
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("title"), th.colors.brand_green_hover))
			table.insert(fs, string.format("label[12.75,4.27;%s]",
				core.formspec_escape(fgettext("SERVER DESCRIPTION & MOTD"))))
			table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")

			-- Rating & Star Badge
			local rating_str = selected_server.rating and string.format("%.1f ★", selected_server.rating) or ""
			local rating_col = th.colors.text_muted
			if selected_server.rating then
				if selected_server.rating >= 4.0 then
					rating_col = th.colors.warn_gold
				elseif selected_server.rating >= 2.5 then
					rating_col = th.colors.brand_cyan
				end
			end
			local rating = (rating_str ~= "") and string.format("%s: %s", fgettext("Community Rating"), rating_str) or ""
			if rating ~= "" then
				table.insert(fs, "style_type[label;font=bold;font_size=+0;textcolor=" .. rating_col .. "]")
				table.insert(fs, string.format("label[12.8,4.60;• %s]", core.formspec_escape(rating)))
				table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" .. th.colors.text_secondary .. "]")
			end

			-- MOTD / Description Textarea
			local raw_sname = unescape_formspec_text(selected_server.name or "")
			local raw_desc = selected_server.description
			if not raw_desc or raw_desc == "" then
				if sel_local_type == "localhost" then
					local s_port = tostring(selected_server.port or 30000)
					raw_desc = fgettext("[Localhost Server • 127.0.0.1]\n\nThis server is hosted locally on your device.\n• Ultra-low latency loopback connection (< 1ms).\n• Instant direct join without public internet routing.\n• Accessible on this computer on port $1.", s_port)
				elseif sel_local_type == "lan" then
					local s_addr = tostring(selected_server.address or "")
					raw_desc = fgettext("[Local Area Network (LAN) Server • $1]\n\nThis server is hosted on your local network / Wi-Fi.\n• High-speed local network connection.\n• Joinable by any device on the same local subnet.\n• Private to your local network (no port forwarding required).", s_addr)
				else
					raw_desc = format_raw_text("No description available.")
				end
			else
				raw_desc = unescape_formspec_text(raw_desc)
			end
			local title_arg = (#raw_sname > 30) and raw_sname or nil
			table.insert(fs, th.textarea_readonly(12.65, 4.85, 5.10, 3.45, raw_desc, title_arg))
		end

		-- Determine active focused field with intelligent default if none set
		local cur_focus = st.focused_field
		if not cur_focus then
			cur_focus = (st.player_name and st.player_name ~= "") and "te_pwd" or "te_name"
		end
		local is_name_focused = (cur_focus == "te_name")
		local is_pwd_focused = (cur_focus == "te_pwd")

		-- Player Credentials Input with Modern Voxel Inset Containers & Click-to-Focus
		table.insert(fs, string.format("style[te_name,te_pwd;border=false;textcolor=%s;font=normal;%s]",
			th.colors.text_primary, th.font_size("body")))
		table.insert(fs, th.text_input(12.55, 9.15, 2.58, 0.65, "te_name", "", st.player_name, is_name_focused, fgettext("Your multiplayer player name"), fgettext("Player Name"), "btn_focus_name"))
		table.insert(fs, th.password_input(15.27, 9.15, 2.58, 0.65, "te_pwd", "", is_pwd_focused, fgettext("Enter server account password (leave blank if none or registering)"), fgettext("Password"), "btn_focus_pwd"))

		-- Actions: Favorite | Website | Register | JOIN SERVER
		local enable_split = core.settings:get_bool("enable_split_login_register")
		if enable_split == nil then
			enable_split = true
		end

		local slot_y = 9.95
		local slot_h = 0.72

		-- Slot 1: Favorite Toggle Button (Fixed x = 12.55, w = 0.72)
		local fav_icon = selected_server.is_favorite and "server_favorite_delete.png" or "server_favorite.png"
		local fav_tip = selected_server.is_favorite and fgettext("Remove server from favorites") or fgettext("Add server to favorites")
		table.insert(fs, th.button_icon(12.55, slot_y, 0.72, slot_h, "btn_add_favorite", defaulttexturedir .. fav_icon, fav_tip))

		-- Slot 2: Server Website Button (Fixed x = 13.40, w = 0.72)
		if selected_server.url and selected_server.url ~= "" then
			table.insert(fs, th.button_icon(13.40, slot_y, 0.72, slot_h, "btn_server_url", defaulttexturedir .. "server_url.png", fgettext("Open server website: $1", selected_server.url)))
		else
			local menupath = custom_menupath or (core and core.get_mainmenu_path and core.get_mainmenu_path()) or "."
			local unavail_icon = menupath .. DIR_DELIM .. "textures" .. DIR_DELIM .. "icon_server_url_unavailable.png"
			local f_icon = io.open(unavail_icon, "r")
			if f_icon then
				f_icon:close()
			else
				unavail_icon = defaulttexturedir .. "server_url_unavailable.png"
			end
			table.insert(fs, string.format("image[13.40,%f;0.72,%f;%s]", slot_y, slot_h, core.formspec_escape(unavail_icon)))
			table.insert(fs, th.tooltip_area(13.40, slot_y, 0.72, slot_h, fgettext("No server website available")))
		end

		-- Slot 3: Register Button (Fixed x = 14.25, w = 3.60)
		if enable_split then
			table.insert(fs, th.button_secondary("14.25", slot_y, "3.60", slot_h, "btn_mp_register", fgettext("Register"), fgettext("Register a new account on this server")))
		end

		-- Primary Action: JOIN SERVER CTA (Full Width x = 12.55, w = 5.30)
		local join_btn_x = 12.55
		local join_btn_w = 5.30
		local join_btn_y = 10.82
		local join_btn_h = 0.82
		local join_label = "▶  " .. fgettext("JOIN SERVER")
		local hero_font = th.font_size("hero")

		table.insert(fs, th.button_primary(join_btn_x, join_btn_y, join_btn_w, join_btn_h, "btn_mp_login", join_label, fgettext("Connect and play on this server"), hero_font))
	else
		-- Empty State
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), th.colors.text_muted))
		table.insert(fs, string.format("label[13.2,5.5;%s]", core.formspec_escape(fgettext("No server selected"))))
		table.insert(fs, "style_type[label;font=normal;textcolor=" .. th.colors.text_muted .. "]")
		table.insert(fs, string.format("label[13.2,6.0;%s]", core.formspec_escape(fgettext("Select a server to view details and connect"))))
	end

	table.insert(fs, "container_end[]")
	return table.concat(fs, "")
end

return view_online
