-- Luanti Main Menu Redesign
-- ContentDB & Packages View Component (Formspec Version 7)

local view_content = {}

local packages_raw, packages

local function append_items(dest, src)
	for _, item in ipairs(src) do
		dest[#dest + 1] = item
	end
end

local update_packages


local function get_content_icons(packages_with_updates)
	local ret = {}
	for _, content in ipairs(packages_with_updates) do
		ret[content.virtual_path or content.path] = { type = "update" }
	end
	return ret
end

local function truncate_str(s, max_len)
	if not s then return "" end
	local str = tostring(s)
	if #str > max_len then
		return str:sub(1, max_len - 1) .. "…"
	end
	return str
end

local screenshot_cache = {}
local modpack_children_cache = {}

function view_content.clear_cache()
	screenshot_cache = {}
	modpack_children_cache = {}
end

local function get_package_screenshot(pkg)
	if not pkg or not pkg.path then
		return defaulttexturedir .. "no_screenshot.png"
	end
	if screenshot_cache[pkg.path] then
		return screenshot_cache[pkg.path]
	end
	local valid_screenshots = {
		pkg.path .. DIR_DELIM .. "screenshot.png",
		pkg.path .. DIR_DELIM .. "screenshot.jpg",
		pkg.path .. DIR_DELIM .. "screenshot.jpeg",
		pkg.path .. DIR_DELIM .. "icon.png",
		pkg.path .. DIR_DELIM .. "logo.png",
		pkg.path .. DIR_DELIM .. "menu" .. DIR_DELIM .. "icon.png",
	}
	for _, sf in ipairs(valid_screenshots) do
		local f = io.open(sf, "r")
		if f then
			f:close()
			screenshot_cache[pkg.path] = sf
			return sf
		end
	end
	local fallback = defaulttexturedir .. "no_screenshot.png"
	screenshot_cache[pkg.path] = fallback
	return fallback
end

local function get_modpack_children(pkg)
	local children = {}
	if not pkg or (not pkg.is_modpack and pkg.type ~= "modpack") then
		return children
	end
	local cache_key = pkg.path or pkg.name or pkg.id
	if modpack_children_cache[cache_key] then
		return modpack_children_cache[cache_key]
	end

	local all_mods = (pkgmgr.global_mods and pkgmgr.global_mods:get_list()) or {}
	local pkg_prefix = pkg.path and (pkg.path .. DIR_DELIM)
	local seen_paths = {}

	for _, m in ipairs(all_mods) do
		-- Condition A: Engine modpack match (m.modpack must be a non-empty string matching pkg name or id)
		local is_engine_child = (m.modpack and m.modpack ~= "" and (m.modpack == pkg.name or (pkg.id and m.modpack == pkg.id)))
		-- Condition B: Disk path containment inside this modpack directory
		local is_path_child = (pkg_prefix and m.path and m.path:find(pkg_prefix, 1, true) == 1)

		if (is_engine_child or is_path_child) and m.path ~= pkg.path then
			local m_key = m.path or m.name
			if not seen_paths[m_key] then
				seen_paths[m_key] = true
				children[#children + 1] = m
			end
		end
	end

	-- Fallback to scanning subdirectories if engine mod list did not enumerate them
	if #children == 0 and pkg.path then
		local subdirs = core.get_dir_list(pkg.path, true)
		if subdirs then
			for _, dirname in ipairs(subdirs) do
				local subpath = pkg.path .. DIR_DELIM .. dirname
				local conf_path = subpath .. DIR_DELIM .. "mod.conf"
				local f_init = io.open(subpath .. DIR_DELIM .. "init.lua", "r")
				if f_init then
					f_init:close()
					local title = dirname
					local desc = ""
					local f_conf = io.open(conf_path, "r")
					if f_conf then
						f_conf:close()
						local conf = Settings(conf_path)
						title = (conf and conf:get("title")) or (conf and conf:get("name")) or dirname
						desc = (conf and conf:get("description")) or ""
					end
					children[#children + 1] = {
						name = dirname,
						title = title,
						path = subpath,
						type = "mod",
						description = desc,
					}
				end
			end
		end
	end

	for _, child in ipairs(children) do
		child.parent_pkg_name = pkg.name or pkg.id
		child.is_child_mod = true
		if not child.author or child.author == "" then
			child.author = pkg.author
		end
		if (not child.title or child.title == "") and child.path then
			local f_conf = io.open(child.path .. DIR_DELIM .. "mod.conf", "r")
			if f_conf then
				f_conf:close()
				local conf = Settings(child.path .. DIR_DELIM .. "mod.conf")
				child.title = conf and (conf:get("title") or conf:get("name"))
			end
			child.title = child.title or child.name
		end
		if (not child.description or child.description == "") and child.path then
			local f_desc = io.open(child.path .. DIR_DELIM .. "description.txt", "r")
			if f_desc then
				child.description = f_desc:read("*a")
				f_desc:close()
			else
				local f_conf = io.open(child.path .. DIR_DELIM .. "mod.conf", "r")
				if f_conf then
					f_conf:close()
					local conf = Settings(child.path .. DIR_DELIM .. "mod.conf")
					child.description = conf and conf:get("description") or ""
				end
			end
		end
	end

	-- Sort children alphabetically by title/name
	table.sort(children, function(a, b)
		local ta = (a.title or a.name or ""):lower()
		local tb = (b.title or b.name or ""):lower()
		return ta < tb
	end)

	modpack_children_cache[cache_key] = children
	return children
end

local function package_filter(element, criteria)
	if not criteria then return true end

	-- 1. Type Filter: "all", "mod", "game", "txp"
	local filter_type = criteria.type or "all"
	if filter_type ~= "all" then
		if filter_type == "mod" then
			if element.type ~= "mod" and element.type ~= "modpack" and not element.is_modpack then
				return false
			end
		elseif filter_type == "game" then
			if element.type ~= "game" then
				return false
			end
		elseif filter_type == "txp" then
			if element.type ~= "txp" then
				return false
			end
		end
	end

	-- 2. Search Query Matching
	local q = criteria.query
	if q and q ~= "" then
		local query = q:lower():gsub("^%s+", ""):gsub("%s+$", "")
		if query ~= "" then
			local name = (element.name or ""):lower()
			local title = (element.title or ""):lower()
			local author = (element.author or ""):lower()
			local desc = (element.description or ""):lower()
			local id = (element.id or ""):lower()

			if name:find(query, 1, true) or title:find(query, 1, true) or
			   author:find(query, 1, true) or desc:find(query, 1, true) or
			   id:find(query, 1, true) then
				return true
			end

			-- Modpack child inspection
			if element.is_modpack or element.type == "modpack" then
				local children = get_modpack_children(element)
				for _, ch in ipairs(children) do
					local ch_name = (ch.name or ""):lower()
					local ch_title = (ch.title or ""):lower()
					local ch_author = (ch.author or ""):lower()
					local ch_desc = (ch.description or ""):lower()
					if ch_name:find(query, 1, true) or ch_title:find(query, 1, true) or
					   ch_author:find(query, 1, true) or ch_desc:find(query, 1, true) then
						return true
					end
				end
			end

			return false
		end
	end

	return true
end

function update_packages()
	if view_content.clear_cache then
		view_content.clear_cache()
	end
	pkgmgr.load_all()

	packages_raw = {}
	append_items(packages_raw, pkgmgr.games)
	append_items(packages_raw, pkgmgr.texture_packs)
	append_items(packages_raw, pkgmgr.global_mods:get_list())

	local function get_data()
		return packages_raw
	end

	local function is_equal(element, uid)
		return (element.type == "game" and element.id == uid) or element.name == uid
	end

	packages = filterlist.create(get_data, pkgmgr.compare_package, is_equal, package_filter, {})
end

function view_content.render(st, th)
	if not packages then
		update_packages()
	end

	local search_q = (st.get and st.get("content_search_query")) or st.content_search_query or ""
	local filter_type = (st.get and st.get("content_filter")) or st.content_filter or "all"

	packages:set_filtercriteria({
		query = search_q,
		type = filter_type,
	})

	local fs = {}
	table.insert(fs, "container[3.3,0]")

	-- Main content background (Width: 18.3, Height: 12.0)
	table.insert(fs, string.format("box[0,0;18.3,12.0;%s]", th.colors.backdrop))

	----------------------------------------------------------------------------
	-- Top Toolbar: Search, Filters & Browse ContentDB Online (Matches Local & Online)
	----------------------------------------------------------------------------
	table.insert(fs, th.voxel_box(0.35, 0.25, 17.65, 0.95, th.colors.card_bg))

	-- Search field with modern inset box & action buttons (Matches Local & Online 5.60 width)
	local is_content_search_focused = (st.focused_field == "te_content_search")
	table.insert(fs, string.format("style[te_content_search;border=false;textcolor=%s;font=normal;%s]",
		th.colors.text_primary, th.font_size("body")))
	table.insert(fs, string.format("style[te_content_search:focused;border=false;textcolor=%s;bgcolor=%s;font=normal;%s]",
		th.colors.text_primary, th.colors.input_bg_focused or "#020712f5", th.font_size("body")))
	table.insert(fs, th.search_bar(0.55, 0.38, 5.60, 0.65, "te_content_search", search_q, is_content_search_focused, "btn_content_search", "btn_content_clear", fgettext("Search installed mods, games, and texture packs")))

	-- Filter Buttons: All, Mods, Games, Textures
	local filter_x = 7.85
	local filters = {
		{ id = "all",  name = "btn_content_filter_all",   label = fgettext("All"),      tip = fgettext("Show all installed content"), pill_w = 1.10 },
		{ id = "mod",  name = "btn_content_filter_mods",  label = fgettext("Mods"),     tip = fgettext("Show only installed mods and modpacks"), pill_w = 1.15 },
		{ id = "game", name = "btn_content_filter_games", label = fgettext("Games"),    tip = fgettext("Show only installed games"), pill_w = 1.20 },
		{ id = "txp",  name = "btn_content_filter_txp",   label = fgettext("Textures"), tip = fgettext("Show only installed texture packs"), pill_w = 1.30 },
	}

	for _, flt in ipairs(filters) do
		local is_act = (filter_type == flt.id)
		table.insert(fs, th.button_tab(filter_x, 0.38, flt.pill_w, 0.65, flt.name, flt.label, is_act, flt.tip))
		filter_x = filter_x + flt.pill_w + 0.10
	end

	-- Browse ContentDB Online Button (Matches right action button in Local & Online)
	local packages_with_updates = update_detector.get_all()
	local update_icons = get_content_icons(packages_with_updates)
	local update_count = #packages_with_updates

	local contentdb_label = fgettext("Browse ContentDB Online")
	if update_count > 0 then
		contentdb_label = fgettext("Browse ContentDB [$1 Updates]", update_count)
	end

	local cdb_btn_x = 13.15
	local cdb_btn_w = 17.80 - cdb_btn_x
	table.insert(fs, th.button_secondary(cdb_btn_x, 0.38, cdb_btn_w, 0.65, "btn_contentdb", contentdb_label, fgettext("Browse and install community mods, games, and texture packs online"), false, th.font_size("button_sub")))

	----------------------------------------------------------------------------
	-- Main Split Area: Left = Package List/Cards, Right = Package Details
	----------------------------------------------------------------------------
	local use_technical_names = core.settings:get_bool("show_technical_names")
	local selected_pkg_idx = (st.get and st.get("selected_pkg")) or st.selected_pkg or 1
	local pkg_list = packages:get_list()
	if #pkg_list == 0 then
		selected_pkg_idx = 0
	elseif selected_pkg_idx > #pkg_list or selected_pkg_idx < 1 then
		selected_pkg_idx = 1
	end
	local selected_pkg = (selected_pkg_idx > 0) and pkg_list[selected_pkg_idx] or nil
	local selected_child_mod = (st.get and st.get("selected_child_mod")) or st.selected_child_mod
	if rawget(_G, "menudata") then
		menudata.pkg_list = pkg_list
		menudata.child_mods_lookup = {}
	end

	-- Left Panel Container (Width: 11.90, Height: 10.45, matching Local & Online)
	table.insert(fs, th.voxel_box(0.35, 1.30, 11.90, 10.45, th.colors.card_bg))

	-- View Switcher Buttons (List vs Thumbnail Cards) using translucent button style
	local view_mode = (st.get and st.get("content_view_mode")) or st.content_view_mode or "list"
	local is_list = (view_mode == "list")

	table.insert(fs, th.button_secondary_tab(0.55, 1.38, 5.65, 0.52, "btn_content_view_list", fgettext("☰ List View"), is_list, fgettext("Compact tree list view of installed content")))
	table.insert(fs, th.button_secondary_tab(6.40, 1.38, 5.65, 0.52, "btn_content_view_thumbs", fgettext("☷ Thumbnail Cards"), not is_list, fgettext("Card view with screenshots, details, and expandable modpacks")))

	if is_list then
		------------------------------------------------------------------------
		-- Mode A: Sleek Expandable Mod List View (Reused from Play Online)
		------------------------------------------------------------------------
		local list_scroll = (st.get and st.get("content_list_scroll")) or st.content_list_scroll or 0
		local expanded_pkgs = (st.get and st.get("content_list_expanded")) or st.content_list_expanded or {}

		table.insert(fs, string.format("scroll_container[0.55,2.02;11.10,9.55;content_list_scroll;vertical;0.1;0.25]"))

		local cur_y = 0.0
		local row_w = 11.00

		if #pkg_list == 0 then
			local msg = (search_q ~= "")
				and fgettext("No packages matching '$1'", search_q)
				or fgettext("No packages found")
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), th.colors.text_muted))
			table.insert(fs, string.format("label[3.5,3.5;%s]", core.formspec_escape(msg)))
			table.insert(fs, th.button_secondary(4.0, 4.2, 3.2, 0.75, "btn_content_clear", fgettext("Clear Search"), fgettext("Clear active search filter")))
			cur_y = 5.0
		end

		for i, pkg in ipairs(pkg_list) do
			if not pkg.modpack or pkg.modpack == "" then
				local is_selected_pkg = (i == selected_pkg_idx)
				local is_modpack = (pkg.is_modpack or pkg.type == "modpack")
				local children = is_modpack and get_modpack_children(pkg) or {}
				local exp_key = pkg.name or pkg.id or tostring(i)
				local is_expanded = expanded_pkgs[exp_key] == true
				local has_update = update_icons[pkg.virtual_path or pkg.path] ~= nil

				if rawget(_G, "menudata") and menudata.child_mods_lookup then
					menudata.child_mods_lookup[i] = children
				end

				local type_badge, type_color
				if pkg.type == "txp" then
					type_badge = fgettext("Texture")
					type_color = "#c084fc"
				elseif is_modpack then
					type_badge = fgettext("Modpack")
					type_color = "#4ade80"
				elseif pkg.type == "game" then
					type_badge = fgettext("Game")
					type_color = "#fbbf24"
				else
					type_badge = fgettext("Mod")
					type_color = "#38bdf8"
				end

				local child_rows = (is_modpack and #children > 0) and math.min(#children, 8) or 0
				local card_h = 1.52 + (child_rows > 0 and (0.35 + math.ceil(child_rows / 2) * 0.40) or 0)

				if is_expanded then
					-- Expanded Card
					table.insert(fs, string.format("box[0.00,%.2f;%.2f,%.2f;#0f172acc]", cur_y, row_w, card_h))
					table.insert(fs, string.format("box[0.00,%.2f;0.06,%.2f;%s]", cur_y, card_h, th.colors.brand_green_hover))

					-- Collapse toggle button [-]
					local exp_name = "btn_pkg_exp_" .. i
					table.insert(fs, string.format("style[%s;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
						exp_name, th.colors.btn_secondary_bg, th.colors.brand_green_hover, th.font_size("button")))
					table.insert(fs, string.format("button[0.08,%.2f;0.34,0.30;%s;-]", cur_y + 0.06, exp_name))
					table.insert(fs, string.format("tooltip[%s;%s]", exp_name, core.formspec_escape(fgettext("Collapse details"))))

					-- Technical name & Badges
					local tech_name = truncate_str(pkg.name or pkg.id or "", 26)
					table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_primary))
					table.insert(fs, string.format("label[0.52,%.2f;%s]", cur_y + 0.20, core.formspec_escape(tech_name)))

					table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), type_color))
					table.insert(fs, string.format("label[5.20,%.2f;%s]", cur_y + 0.20, core.formspec_escape(type_badge)))

					if has_update then
						table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.warn_gold))
						table.insert(fs, string.format("label[8.80,%.2f;%s]", cur_y + 0.20, core.formspec_escape(fgettext("Update Available"))))
					elseif is_modpack then
						local count_str = string.format("(%d %s)", #children, fgettext("mods"))
						table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.brand_cyan))
						table.insert(fs, string.format("label[8.80,%.2f;%s]", cur_y + 0.20, core.formspec_escape(count_str)))
					end

					-- Title and author
					local full_title = (pkg.title and pkg.title ~= "") and pkg.title or (pkg.name or "")
					local author_part = (pkg.author and pkg.author ~= "") and (" by " .. pkg.author) or ""
					local title_line = truncate_str(full_title .. author_part, 65)
					table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.brand_cyan))
					table.insert(fs, string.format("label[0.15,%.2f;%s]", cur_y + 0.52, core.formspec_escape(title_line)))

					-- Short description
					local desc_raw = (pkg.description and pkg.description ~= "") and pkg.description or fgettext("No description available.")
					local desc_line = desc_raw:gsub("[\r\n]+", " ")
					desc_line = truncate_str(desc_line, 85)
					table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_secondary))
					table.insert(fs, string.format("label[0.15,%.2f;%s]", cur_y + 0.82, core.formspec_escape(desc_line)))

					-- Action Buttons: [ 🔍 Inspect Details ] and [ 📁 Open Folder ]
					local btn_inspect = "btn_select_pkg_" .. i
					table.insert(fs, string.format("style[%s;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
						btn_inspect, th.colors.brand_green, th.colors.text_primary, th.font_size("caption")))
					table.insert(fs, string.format("button[0.15,%.2f;2.60,0.34;%s;%s]",
						cur_y + 1.12, btn_inspect, core.formspec_escape(fgettext("🔍 Inspect Details"))))
					table.insert(fs, string.format("tooltip[%s;%s]", btn_inspect, core.formspec_escape(fgettext("Select package and inspect in right panel"))))

					table.insert(fs, string.format("style[btn_open_pkg_dir;border=false;bgcolor=%s;textcolor=%s;font=normal;%s]",
						th.colors.btn_secondary_bg, th.colors.text_primary, th.font_size("caption")))
					table.insert(fs, string.format("button[2.90,%.2f;2.20,0.34;btn_open_pkg_dir;%s]",
						cur_y + 1.12, core.formspec_escape(fgettext("📁 Open Folder"))))
					table.insert(fs, th.tooltip("btn_open_pkg_dir", fgettext("Open local directory in system file explorer")))

					-- Bundled Child Mods Grid if modpack (2 balanced columns across width 11.00)
					if is_modpack and child_rows > 0 then
						local sub_y = cur_y + 1.52
						table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
						table.insert(fs, string.format("label[0.15,%.2f;%s]", sub_y + 0.16, core.formspec_escape(fgettext("BUNDLED MODS:"))))
						sub_y = sub_y + 0.32

						for c_idx, child in ipairs(children) do
							if c_idx <= 8 then
								local col_idx = (c_idx - 1) % 2
								local row_offset = math.floor((c_idx - 1) / 2) * 0.38
								local child_x = 0.15 + col_idx * 5.45
								local child_y = sub_y + row_offset
								local is_child_active = (selected_child_mod and selected_child_mod.name == child.name and is_selected_pkg)
								local c_bg = is_child_active and th.colors.btn_active_bg or th.colors.card_inner_bg
								local c_txt_col = is_child_active and "#ffffff" or th.colors.text_primary
								local c_btn = string.format("btn_select_child_%d_%d", i, c_idx)
								local c_title = truncate_str(child.title or child.name, 26)

								table.insert(fs, string.format("style[%s;border=false;bgcolor=%s;textcolor=%s;font=normal;%s]",
									c_btn, c_bg, c_txt_col, th.font_size("caption")))
								table.insert(fs, string.format("button[%.2f,%.2f;5.25,0.34;%s;%s]",
									child_x, child_y, c_btn, core.formspec_escape(c_title)))
								table.insert(fs, string.format("tooltip[%s;%s]", c_btn, core.formspec_escape(fgettext("Inspect bundled mod $1", child.title or child.name))))
							end
						end
					end

					cur_y = cur_y + card_h + 0.08
				else
					-- Collapsed Row (Sleek single-line matching Play Online mods across 11.00 width)
					local is_card_active = is_selected_pkg and not selected_child_mod
					local bg_col = is_card_active and "#14532d88" or "#1e293b66"
					table.insert(fs, string.format("box[0.00,%.2f;%.2f,0.44;%s]", cur_y, row_w, bg_col))
					if is_card_active then
						table.insert(fs, string.format("box[0.00,%.2f;0.05,0.44;%s]", cur_y, th.colors.brand_green))
					end

					-- Clickable selection button across the entire row
					local sel_name = "btn_select_pkg_" .. i
					table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000]", sel_name))
					table.insert(fs, string.format("style[%s:hovered;border=false;bgcolor=#3e6c9c22]", sel_name))
					table.insert(fs, string.format("style[%s:pressed;border=false;bgcolor=#1d365044]", sel_name))
					table.insert(fs, string.format("button[0.00,%.2f;%.2f,0.44;%s;]", cur_y, row_w, sel_name))
					table.insert(fs, th.tooltip(sel_name, fgettext("Select and inspect $1", pkg.title or pkg.name)))

					-- Expand toggle button [+]
					local exp_name = "btn_pkg_exp_" .. i
					table.insert(fs, string.format("style[%s;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
						exp_name, th.colors.btn_secondary_bg, th.colors.brand_green_hover, th.font_size("button")))
					table.insert(fs, string.format("button[0.08,%.2f;0.34,0.30;%s;+]", cur_y + 0.06, exp_name))
					table.insert(fs, string.format("tooltip[%s;%s]", exp_name, core.formspec_escape(fgettext("Expand package details"))))

					-- Title / Name
					local raw_name = use_technical_names and (pkg.name or pkg.title or "") or (pkg.title or pkg.name or "")
					local disp_title = truncate_str(raw_name, 34)
					local title_col = is_card_active and th.colors.brand_green_hover or th.colors.text_primary
					table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), title_col))
					table.insert(fs, string.format("label[0.52,%.2f;%s]", cur_y + 0.22, core.formspec_escape(disp_title)))

					-- Type badge
					table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), type_color))
					table.insert(fs, string.format("label[5.20,%.2f;%s]", cur_y + 0.22, core.formspec_escape(type_badge)))

					-- Author
					local disp_author = truncate_str(pkg.author and ("by " .. pkg.author) or "", 22)
					table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
					table.insert(fs, string.format("label[6.60,%.2f;%s]", cur_y + 0.22, core.formspec_escape(disp_author)))

					-- Update badge or modpack count
					if has_update then
						table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.warn_gold))
						table.insert(fs, string.format("label[9.20,%.2f;%s]", cur_y + 0.22, core.formspec_escape(fgettext("Update"))))
					elseif is_modpack then
						local count_str = string.format("(%d %s)", #children, fgettext("mods"))
						table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.brand_cyan))
						table.insert(fs, string.format("label[9.20,%.2f;%s]", cur_y + 0.22, core.formspec_escape(count_str)))
					end

					cur_y = cur_y + 0.48
				end
			end
		end

		table.insert(fs, "scroll_container_end[]")

		-- Dynamic scrollbar if content exceeds container height
		local visible_h = 9.55
		local scroll_factor = 0.1
		if cur_y > visible_h then
			local max_scroll_dist = math.max(0, cur_y - visible_h)
			local scroll_max = math.max(10, math.ceil(max_scroll_dist / scroll_factor))
			local thumb_size = math.max(10, math.floor(visible_h / scroll_factor))
			local clamped_scroll = math.min(list_scroll, scroll_max)

			table.insert(fs, string.format("scrollbaroptions[min=0;max=%d;smallstep=5;largestep=25;thumbsize=%d]", scroll_max, thumb_size))
			table.insert(fs, string.format("scrollbar[11.75,2.02;0.25,9.55;vertical;content_list_scroll;%d]", clamped_scroll))
		end
	else
		------------------------------------------------------------------------
		-- Mode B: Thumbnail Cards View (Whole-card clickable, expandable modpacks)
		------------------------------------------------------------------------
		local thumbs_scroll = (st.get and st.get("content_thumbs_scroll")) or st.content_thumbs_scroll or 0
		local expanded_modpacks = (st.get and st.get("expanded_modpacks")) or st.expanded_modpacks or {}

		table.insert(fs, string.format("scroll_container[0.55,2.02;11.10,9.55;content_thumbs_scroll;vertical;0.1;0.25]"))

		local card_y = 0.0
		local card_w = 11.00

		if #pkg_list == 0 then
			local msg = (search_q ~= "")
				and fgettext("No packages matching '$1'", search_q)
				or fgettext("No packages found")
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), th.colors.text_muted))
			table.insert(fs, string.format("label[3.5,3.5;%s]", core.formspec_escape(msg)))
			table.insert(fs, th.button_secondary(4.0, 4.2, 3.2, 0.75, "btn_content_clear", fgettext("Clear Search"), fgettext("Clear active search filter")))
		end

		for i, pkg in ipairs(pkg_list) do
			if not pkg.modpack or pkg.modpack == "" then
				local is_selected_pkg = (i == selected_pkg_idx)
				local is_modpack = (pkg.is_modpack or pkg.type == "modpack")
				local children = is_modpack and get_modpack_children(pkg) or {}
				local is_expanded = is_modpack and expanded_modpacks[pkg.name]

				if rawget(_G, "menudata") and menudata.child_mods_lookup then
					menudata.child_mods_lookup[i] = children
				end

				local base_card_h = is_modpack and 1.85 or 1.60

				-- Visual card backing with active border/glow when selected
				local is_this_card_active = is_selected_pkg and not selected_child_mod
				local is_child_of_this_active = is_selected_pkg and selected_child_mod ~= nil
				local card_bg = is_this_card_active and th.colors.card_active_bg or th.colors.card_inner_bg
				local border_light = (is_this_card_active or is_child_of_this_active) and th.colors.brand_green or th.colors.card_border_light
				local border_dark = (is_this_card_active or is_child_of_this_active) and th.colors.brand_green_dark or th.colors.card_border_dark

				table.insert(fs, th.voxel_box(0, card_y, card_w, base_card_h, card_bg, border_light, border_dark))

				-- Whole-tile clickable button (under text/modpack expander, transparent with subtle hover)
				local select_btn_name = "btn_select_pkg_" .. i
				table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000]", select_btn_name))
				table.insert(fs, string.format("style[%s:hovered;border=false;bgcolor=#3e6c9c22]", select_btn_name))
				table.insert(fs, string.format("style[%s:pressed;border=false;bgcolor=#1d365044]", select_btn_name))
				table.insert(fs, string.format("button[0.00,%.2f;%.2f,%.2f;%s;]", card_y, card_w, base_card_h, select_btn_name))
				table.insert(fs, th.tooltip(select_btn_name, fgettext("Inspect $1", pkg.title or pkg.name or "")))

				-- Thumbnail screenshot on left
				local screenshot = get_package_screenshot(pkg)
				table.insert(fs, string.format("box[0.10,%f;2.20,%f;%s]", card_y + 0.10, base_card_h - 0.20, th.colors.input_bg))
				table.insert(fs, string.format("image[0.10,%f;2.20,%f;%s]", card_y + 0.10, base_card_h - 0.20, core.formspec_escape(screenshot)))

				-- Right text details
				local title = pkg.title or pkg.name or pkg.id or fgettext("Unknown")
				if #title > 34 then
					title = title:sub(1, 33) .. "…"
				end

				local type_label = pkg.type:upper()
				if pkg.type == "txp" then
					type_label = fgettext("TEXTURE PACK")
				elseif is_modpack then
					type_label = fgettext("MODPACK")
				elseif pkg.type == "mod" then
					type_label = fgettext("MOD")
				elseif pkg.type == "game" then
					type_label = fgettext("GAME")
				end

				local author = pkg.author or fgettext("Unknown")
				if #author > 20 then
					author = author:sub(1, 19) .. "…"
				end

				local meta_text = string.format("%s • %s", type_label, author)

				local desc_raw = (pkg.description and pkg.description ~= "") and pkg.description or fgettext("No description available")
				local desc_line = desc_raw:gsub("[\r\n]+", " ")
				if #desc_line > 65 then
					desc_line = desc_line:sub(1, 64) .. "…"
				end

				local title_color = is_this_card_active and th.colors.brand_green_hover or "#ffffff"
				table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), title_color))
				table.insert(fs, string.format("label[2.45,%f;%s]", card_y + 0.32, core.formspec_escape(title)))

				table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.brand_green_hover))
				table.insert(fs, string.format("label[2.45,%f;%s]", card_y + 0.72, core.formspec_escape(meta_text)))

				table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("body"), th.colors.text_muted))
				table.insert(fs, string.format("label[2.45,%f;%s]", card_y + 1.10, core.formspec_escape(desc_line)))

				-- Selection state is cleanly indicated by the green card border and title highlight

				-- Modpack expand/collapse button (sits on top of the card button)
				if is_modpack then
					local toggle_label = is_expanded
						and fgettext("▲ Collapse ($1 mods)", #children)
						or fgettext("▼ Expand ($1 mods)", #children)
					local toggle_btn_name = "btn_modpack_toggle_" .. pkg.name
					table.insert(fs, th.voxel_box(2.45, card_y + 1.35, 5.20, 0.42,
						is_expanded and th.colors.card_active_bg or th.colors.card_inner_bg,
						is_expanded and th.colors.brand_green or th.colors.card_border_light,
						is_expanded and th.colors.brand_green_dark or th.colors.card_border_dark))
					table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000;textcolor=%s;font=bold;%s]",
						toggle_btn_name,
						is_expanded and th.colors.brand_green_hover or th.colors.brand_cyan,
						th.font_size("caption")))
					table.insert(fs, string.format("style[%s:hovered;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
						toggle_btn_name, th.colors.card_bg_hover, th.colors.text_primary, th.font_size("caption")))
					table.insert(fs, string.format("button[2.45,%f;5.20,0.42;%s;%s]",
						card_y + 1.35, toggle_btn_name, core.formspec_escape(toggle_label)))
				end

				card_y = card_y + base_card_h

				-- Vertically stacked interactive child mod sub-tiles when expanded
				if is_modpack and is_expanded then
					if #children == 0 then
						local sub_h = 0.65
						table.insert(fs, th.voxel_box(0.50, card_y + 0.05, 10.40, sub_h, th.colors.card_bg))
						table.insert(fs, string.format("style_type[label;font=italic;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
						table.insert(fs, string.format("label[0.70,%f;%s]", card_y + 0.38, core.formspec_escape(fgettext("No child mods found in this modpack."))))
						card_y = card_y + sub_h + 0.10
					else
						for c_idx, child in ipairs(children) do
							local is_child_selected = selected_child_mod and (selected_child_mod.name == child.name and (selected_child_mod.parent_pkg_name == pkg.name or selected_child_mod.parent_pkg_name == pkg.id))
							local sub_h = 0.95

							local child_bg = is_child_selected and th.colors.card_active_bg or th.colors.card_bg
							local child_border_light = is_child_selected and th.colors.brand_green or th.colors.card_border_light
							local child_border_dark = is_child_selected and th.colors.brand_green_dark or th.colors.card_border_dark

							table.insert(fs, th.voxel_box(0.50, card_y + 0.05, 10.40, sub_h, child_bg, child_border_light, child_border_dark))

							-- Interactive transparent button covering child mod sub-tile
							local child_btn_name = string.format("btn_select_child_%d_%d", i, c_idx)
							table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000]", child_btn_name))
							table.insert(fs, string.format("style[%s:hovered;border=false;bgcolor=#3e6c9c22]", child_btn_name))
							table.insert(fs, string.format("style[%s:pressed;border=false;bgcolor=#1d365044]", child_btn_name))
							table.insert(fs, string.format("button[0.50,%.2f;10.40,%.2f;%s;]", card_y + 0.05, sub_h, child_btn_name))
							table.insert(fs, th.tooltip(child_btn_name, fgettext("Inspect child mod $1", child.title or child.name or "")))

							local child_icon = get_package_screenshot(child)
							if child_icon == defaulttexturedir .. "no_screenshot.png" then
								child_icon = screenshot
							end
							table.insert(fs, string.format("box[0.60,%f;1.00,%f;%s]", card_y + 0.12, sub_h - 0.14, th.colors.input_bg))
							table.insert(fs, string.format("image[0.60,%f;1.00,%f;%s]", card_y + 0.12, sub_h - 0.14, core.formspec_escape(child_icon)))

							local c_title = child.title or child.name or fgettext("Mod")
							if #c_title > 38 then c_title = c_title:sub(1, 37) .. "…" end

							local c_desc = (child.description and child.description ~= "") and child.description or fgettext("Included in modpack")
							local c_desc_line = c_desc:gsub("[\r\n]+", " ")
							if #c_desc_line > 65 then c_desc_line = c_desc_line:sub(1, 64) .. "…" end

							local child_title_color = is_child_selected and th.colors.brand_green_hover or th.colors.text_primary
							table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), child_title_color))
							table.insert(fs, string.format("label[1.75,%f;%s]", card_y + 0.32, core.formspec_escape(c_title)))

							table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
							table.insert(fs, string.format("label[1.75,%f;%s]", card_y + 0.68, core.formspec_escape(c_desc_line)))



							card_y = card_y + sub_h + 0.06
						end
					end
				end

				card_y = card_y + 0.15
			end
		end

		table.insert(fs, "scroll_container_end[]")

		-- Scrollbar alongside the cards list with tuned range and thumb proportions
		local visible_h = 9.55
		local scroll_factor = 0.1
		if card_y > visible_h then
			local max_scroll_dist = math.max(0, card_y - visible_h)
			local scroll_max = math.max(10, math.ceil(max_scroll_dist / scroll_factor))
			local thumb_size = math.max(10, math.floor(visible_h / scroll_factor))
			local clamped_scroll = math.min(thumbs_scroll, scroll_max)

			table.insert(fs, string.format("scrollbaroptions[min=0;max=%d;smallstep=5;largestep=25;thumbsize=%d]", scroll_max, thumb_size))
			table.insert(fs, string.format("scrollbar[11.75,2.02;0.25,9.55;vertical;content_thumbs_scroll;%d]", clamped_scroll))
		end
	end

	----------------------------------------------------------------------------
	-- Right Panel: Package / Child Mod Details & Actions (Width: 5.60, Height: 10.45)
	-- Matches Local Game World Details and Play Online Server Details layout!
	----------------------------------------------------------------------------
	table.insert(fs, th.voxel_box(12.40, 1.30, 5.60, 10.45, th.colors.card_bg))

	local display_pkg = selected_child_mod or selected_pkg
	if display_pkg then
		local title = display_pkg.title or display_pkg.name or display_pkg.id
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("title"), th.colors.brand_green_hover))
		local disp_title = title
		if #disp_title > 24 then
			disp_title = disp_title:sub(1, 23) .. "…"
		end
		table.insert(fs, string.format("label[12.60,1.55;%s]", core.formspec_escape(disp_title)))
		table.insert(fs, th.tooltip_area(12.60, 1.35, 5.20, 0.40, title))

		table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("body"), th.colors.text_muted))

		local type_label
		if display_pkg.is_child_mod then
			type_label = string.format("%s (%s: %s)", fgettext("MOD"), fgettext("Modpack"), truncate_str(display_pkg.parent_pkg_name or "", 12))
		elseif display_pkg.type == "txp" then
			type_label = fgettext("TEXTURE PACK")
		elseif display_pkg.is_modpack or display_pkg.type == "modpack" then
			type_label = fgettext("MODPACK")
		elseif display_pkg.type == "mod" then
			type_label = fgettext("MOD")
		elseif display_pkg.type == "game" then
			type_label = fgettext("GAME")
		else
			type_label = (display_pkg.type or ""):upper()
		end

		table.insert(fs, string.format("label[12.60,1.88;%s: %s | %s: %s]",
			core.formspec_escape(fgettext("Type")), core.formspec_escape(type_label),
			core.formspec_escape(fgettext("Author")), core.formspec_escape(truncate_str(display_pkg.author or fgettext("Unknown"), 14))
		))

		-- Screenshot Preview (Matches World Screenshot card in Local Game)
		local modscreenshot = get_package_screenshot(display_pkg)
		if modscreenshot == defaulttexturedir .. "no_screenshot.png" and selected_pkg then
			modscreenshot = get_package_screenshot(selected_pkg)
		end
		table.insert(fs, th.inner_card(12.60, 2.20, 5.20, 2.70))
		table.insert(fs, string.format("image[12.60,2.20;5.20,2.70;%s]", core.formspec_escape(modscreenshot)))

		-- Description Box
		table.insert(fs, th.inner_card(12.60, 5.05, 5.20, 5.50))
		local desc = (display_pkg.description and display_pkg.description ~= "") and display_pkg.description or fgettext("No package description available")
		table.insert(fs, string.format("textarea[12.65,5.15;5.10,5.30;;;%s]", core.formspec_escape(desc)))

		-- Bottom Action Buttons (Placed at y = 10.75, height = 0.85 matching Local & Online)
		local btn_y = 10.75
		local btn_h = 0.85
		local btn_w = 2.50
		if display_pkg.is_child_mod then
			table.insert(fs, th.button_secondary(12.60, btn_y, btn_w, btn_h, "btn_open_pkg_dir", fgettext("Open Folder"), fgettext("Open this child mod directory in system file manager")))
			table.insert(fs, th.button_secondary(15.30, btn_y, btn_w, btn_h, "btn_back_to_parent_pkg", fgettext("View Modpack"), fgettext("Return to viewing parent modpack details")))
		elseif (display_pkg.type == "modpack" or display_pkg.is_modpack) then
			table.insert(fs, th.button_secondary(12.60, btn_y, btn_w, btn_h, "btn_mod_mgr_rename_modpack", fgettext("Rename"), fgettext("Rename this modpack")))
			table.insert(fs, th.button_danger(15.30, btn_y, btn_w, btn_h, "btn_mod_mgr_delete_mod", fgettext("Uninstall"), fgettext("Permanently uninstall and delete this package")))
		else
			table.insert(fs, th.button_secondary(12.60, btn_y, btn_w, btn_h, "btn_open_pkg_dir", fgettext("Open Folder"), fgettext("Open this package directory in system file manager")))
			table.insert(fs, th.button_danger(15.30, btn_y, btn_w, btn_h, "btn_mod_mgr_delete_mod", fgettext("Uninstall"), fgettext("Permanently uninstall and delete this package")))
		end
	else
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), th.colors.text_muted))
		table.insert(fs, string.format("label[13.60,5.5;%s]", core.formspec_escape(fgettext("No package selected"))))
	end

	table.insert(fs, "container_end[]")
	return table.concat(fs, "")
end

function view_content.invalidate()
	packages = nil
end

return view_content
