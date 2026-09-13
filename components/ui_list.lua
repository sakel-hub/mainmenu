-- Luanti Main Menu Redesign
-- Reusable UI List Component (Formspec Version 7)
-- Replaces table[] with performant, pixel-aligned scroll_container lists

local ui_list = {}

-- Safely escapes text for Formspec
local function escape(str)
	return core.formspec_escape(str or "")
end

-- Truncates string with ellipsis if exceeding max characters
function ui_list.truncate(str, max_len)
	if not str then return "" end
	if max_len and #str > max_len then
		return str:sub(1, max_len - 1) .. "…"
	end
	return str
end
local truncate = ui_list.truncate

--- Formats a timestamp into clean human-readable date & time
-- Handles strings, Unix seconds, and 13-digit millisecond epochs
function ui_list.format_last_played(ts)
	local nts = tonumber(ts)
	if not nts or nts <= 0 then
		return "-"
	end
	-- Normalize 13-digit millisecond timestamps (e.g. JS epoch) to seconds
	if nts > 1000000000000 then
		nts = math.floor(nts / 1000)
	end

	local now = os.time()
	local diff = now - nts
	if diff < 0 then
		return os.date("%Y-%m-%d", nts)
	end

	local today_str = os.date("%Y-%m-%d", now)
	local item_date_str = os.date("%Y-%m-%d", nts)

	if today_str == item_date_str then
		return fgettext("Today") .. " " .. os.date("%H:%M", nts)
	end

	local yesterday_str = os.date("%Y-%m-%d", now - 86400)
	if yesterday_str == item_date_str then
		return fgettext("Yesterday") .. " " .. os.date("%H:%M", nts)
	end

	-- Within the same calendar year: show month and day, e.g. "Sep 13 16:30"
	if os.date("%Y", now) == os.date("%Y", nts) then
		return os.date("%b %d %H:%M", nts)
	end

	return os.date("%Y-%m-%d", nts)
end

--- Returns full timestamp format for inspector panels and tooltips
function ui_list.format_timestamp_full(ts)
	local nts = tonumber(ts)
	if not nts or nts <= 0 then
		return "-"
	end
	if nts > 1000000000000 then
		nts = math.floor(nts / 1000)
	end
	return os.date("%Y-%m-%d %H:%M:%S", nts)
end

--- Column definitions for Local Game and Play Online
function ui_list.get_columns(view_type, is_compact)
	if view_type == "local" then
		if is_compact then
			return {
				{ id = "name",        title = fgettext("World Name"),  x = 0.00, w = 4.50, header_w = 4.50, tip = fgettext("Sort alphabetically by World Name") },
				{ id = "game",        title = fgettext("Game"),        x = 4.50, w = 2.40, header_w = 2.40, tip = fgettext("Sort by Game Title") },
				{ id = "mods",        title = fgettext("Mods"),        x = 6.90, w = 1.40, header_w = 1.40, tip = fgettext("Sort by Enabled Custom Mods Count") },
				{ id = "last_played", title = fgettext("Last Played"), x = 8.30, w = 2.95, header_w = 3.30, tip = fgettext("Sort by Last Played or Modified Date") },
			}
		else
			return {
				{ id = "name",        title = fgettext("World Name"),  x = 0.00, w = 2.50, align = "left",   sortable = true, tip = fgettext("Sort alphabetically by World Name") },
				{ id = "game",        title = fgettext("Game"),        x = 2.50, w = 2.00, align = "left",   sortable = true, tip = fgettext("Sort by Game Title") },
				{ id = "mg",          title = fgettext("Mapgen"),      x = 4.50, w = 1.35, align = "left",   sortable = true, tip = fgettext("Sort by Map Generator Algorithm") },
				{ id = "version",     title = fgettext("Ver"),         x = 5.85, w = 0.85, align = "left",   sortable = true, tip = fgettext("Sort by Target Engine/Game Version") },
				{ id = "mods",        title = fgettext("Mods"),        x = 6.70, w = 0.90, align = "left",   sortable = true, tip = fgettext("Sort by Enabled Custom Mods Count") },
				{ id = "size",        title = fgettext("Size"),        x = 7.60, w = 1.15, align = "left",   sortable = true, tip = fgettext("Sort by Total World Storage Size") },
				{ id = "last_played", title = fgettext("Last Played"), x = 8.75, w = 2.50, align = "left",   sortable = true, header_w = 2.50, tip = fgettext("Sort by Last Played or Modified Date") },
			}
		end
	elseif view_type == "online" then
		if is_compact then
			return {
				{ id = "ping",    title = fgettext("Ping"),        x = 0.00, w = 1.15, header_w = 1.15, tip = fgettext("Sort by Latency (Ping)") },
				{ id = "players", title = fgettext("Players"),     x = 1.15, w = 1.45, header_w = 1.45, tip = fgettext("Sort by Online Players") },
				{ id = "flags",   title = fgettext("Flags"),       x = 2.60, w = 1.05, header_w = 1.05, tip = fgettext("Sort by Gameplay Rules (Creative / PvP)") },
				{ id = "name",    title = fgettext("Server Name"), x = 3.65, w = 7.60, header_w = 7.95, tip = fgettext("Sort alphabetically by Server Name") },
			}
		else
			return {
				{ id = "ping",    title = fgettext("Ping"),        x = 0.00, w = 1.25, header_w = 1.25, tip = fgettext("Sort by Latency (Ping)") },
				{ id = "players", title = fgettext("Players"),     x = 1.25, w = 1.35, header_w = 1.35, tip = fgettext("Sort by Online Players") },
				{ id = "version", title = fgettext("Ver"),         x = 2.60, w = 1.00, header_w = 1.00, tip = fgettext("Sort by Engine Version") },
				{ id = "mods",    title = fgettext("Mods"),        x = 3.60, w = 0.90, header_w = 0.90, tip = fgettext("Sort by Active Mods Count") },
				{ id = "flags",   title = fgettext("Flags"),       x = 4.50, w = 0.90, header_w = 0.90, tip = fgettext("Sort by Gameplay Rules (Creative / PvP)") },
				{ id = "name",    title = fgettext("Server Name"), x = 5.40, w = 5.85, header_w = 5.85, tip = fgettext("Sort alphabetically by Server Name") },
			}
		end
	end
	return {}
end

--- Renders interactive sortable column header buttons
function ui_list.render_header(fs, params)
	local hx = params.x or 0.45
	local hy = params.y or 1.35
	local hw = params.w or 11.60
	local hh = params.h or 0.44
	local cols = params.columns or {}
	local sort_col = params.sort_col or ""
	local sort_dir = params.sort_dir or "asc"
	local btn_prefix = params.btn_prefix or "btn_sort_"
	local th = params.th

	-- Header Bar Background
	table.insert(fs, string.format("box[%.2f,%.2f;%.2f,%.2f;%s]", hx, hy, hw, hh, th.colors.header_bar_bg))

	local arrow = (sort_dir == "asc") and " ▲" or " ▼"

	for _, col in ipairs(cols) do
		local is_active = (sort_col == col.id)
		local title = col.title .. (is_active and arrow or "")
		local btn_name = btn_prefix .. col.id
		local col_x = hx + col.x
		local col_w = col.header_w or col.w

		-- Hover and pressed styling on the transparent clickable header button
		table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000]", btn_name))
		table.insert(fs, string.format("style[%s:hovered;border=false;sound=ui_click;bgcolor=%s]", btn_name, th.colors.list_hover_bg))
		table.insert(fs, string.format("style[%s:pressed;border=false;sound=ui_click;bgcolor=%s]", btn_name, th.colors.list_pressed_bg))
		table.insert(fs, string.format("style[%s:focused;border=false;bgcolor=#00000000]", btn_name))

		table.insert(fs, string.format("button[%.2f,%.2f;%.2f,%.2f;%s;]", col_x, hy, col_w, hh, btn_name))
		if col.tip then
			table.insert(fs, th.tooltip(btn_name, col.tip))
		end

		-- Active sort indicator line
		if is_active then
			table.insert(fs, string.format("box[%.2f,%.2f;%.2f,0.03;%s]", col_x, hy + hh - 0.04, col_w, th.colors.brand_green_hover))
		end

		local text_color = is_active and th.colors.brand_green_hover or th.colors.text_muted
		local font_style = (th and th.font_size and th.font_size("caption")) or "font_size=+0"
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", font_style, text_color))
		table.insert(fs, string.format("label[%.2f,%.2f;%s]", col_x + 0.05, hy + 0.22, escape(title)))
	end
end

--- Opens a Formspec 7 scroll container
function ui_list.render_scroll_start(fs, x, y, w, h, scroll_name, scroll_factor, thumb_factor)
	table.insert(fs, string.format(
		"scroll_container[%.2f,%.2f;%.2f,%.2f;%s;vertical;%.2f;%.2f]",
		x, y, w, h, scroll_name, scroll_factor or 0.1, thumb_factor or 0.25
	))
end

--- Renders a single pixel-aligned list row with optional per-cell interactive tooltips
function ui_list.render_row(fs, params)
	local y = params.y or 0.0
	local w = params.w or 11.25
	local h = params.h or 0.46
	local btn_name = params.btn_name
	local is_selected = params.is_selected == true
	local is_even = params.is_even == true
	local th = params.th
	local cells = params.cells or {}

	-- 1. Row Background
	if is_selected then
		-- Glowing emerald highlight for active/selected item
		table.insert(fs, string.format("box[0.00,%.2f;%.2f,%.2f;%s]", y, w, h, th.colors.list_row_selected_bg))
		-- Left emerald accent bar
		table.insert(fs, string.format("box[0.00,%.2f;0.05,%.2f;%s]", y, h, th.colors.brand_green_hover))
	else
		if is_even then
			table.insert(fs, string.format("box[0.00,%.2f;%.2f,%.2f;%s]", y, w, h, th.colors.list_row_alternate_bg))
		end
	end

	-- 2. Clickable buttons covering the row:
	-- If cells specify individual tooltips, render transparent cell buttons for immediate hover tooltip feedback.
	-- Otherwise, render a single transparent button covering the entire row.
	local has_cell_tooltips = false
	for _, cell in ipairs(cells) do
		if cell.tooltip and cell.tooltip ~= "" then
			has_cell_tooltips = true
			break
		end
	end

	if btn_name then
		local hov_border = th.colors.list_hover_border or "#38bdf844"
		local hov_bg = th.colors.list_hover_bg or "#1e293b55"
		local pre_border = th.colors.border_subtle or "#3e6c9c33"
		local pre_bg = th.colors.list_pressed_bg or "#1d365044"

		if has_cell_tooltips then
			for c_idx, cell in ipairs(cells) do
				local cx = cell.x or 0.0
				local cw = cell.w or 1.0
				local cell_btn = string.format("%s_%d", btn_name, c_idx)
				local tip_content = (cell.tooltip and cell.tooltip ~= "") and cell.tooltip or params.tooltip

				table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000]", cell_btn))
				table.insert(fs, string.format("style[%s:hovered;border=true;bordercolor=%s;sound=ui_click;bgcolor=%s]", cell_btn, hov_border, hov_bg))
				table.insert(fs, string.format("style[%s:pressed;border=true;bordercolor=%s;sound=ui_click;bgcolor=%s]", cell_btn, pre_border, pre_bg))
				table.insert(fs, string.format("style[%s:focused;border=false;bgcolor=#00000000]", cell_btn))
				table.insert(fs, string.format("button[%.2f,%.2f;%.2f,%.2f;%s;]", cx, y, cw, h, cell_btn))

				if tip_content and tip_content ~= "" then
					table.insert(fs, th.tooltip(cell_btn, tip_content))
				end
			end
		else
			table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000]", btn_name))
			table.insert(fs, string.format("style[%s:hovered;border=true;bordercolor=%s;sound=ui_click;bgcolor=%s]", btn_name, hov_border, hov_bg))
			table.insert(fs, string.format("style[%s:pressed;border=true;bordercolor=%s;sound=ui_click;bgcolor=%s]", btn_name, pre_border, pre_bg))
			table.insert(fs, string.format("style[%s:focused;border=false;bgcolor=#00000000]", btn_name))
			table.insert(fs, string.format("button[0.00,%.2f;%.2f,%.2f;%s;]", y, w, h, btn_name))

			if params.tooltip and params.tooltip ~= "" then
				table.insert(fs, th.tooltip(btn_name, params.tooltip))
			end
		end
	end


	-- 3. Render each cell at its exact column coordinates
	for _, cell in ipairs(cells) do
		local cx = cell.x or 0.0
		local cw = cell.w or 1.0
		local ctype = cell.type or "text"

		if ctype == "text" then
			local text = cell.text or ""
			if cell.max_chars then
				text = truncate(text, cell.max_chars)
			end
			local px = cell.pad_x or 0.05
			local py = cell.pad_y or 0.23
			local color = cell.color or (is_selected and th.colors.text_primary or th.colors.text_secondary)
			local weight = cell.font_weight or "normal"
			local font_style = (th and th.font_size and th.font_size("caption")) or "font_size=+0"
			table.insert(fs, string.format("style_type[label;font=%s;%s;textcolor=%s]", weight, font_style, color))
			table.insert(fs, string.format("label[%.2f,%.2f;%s]", cx + px, y + py, escape(text)))

		elseif ctype == "icon" then
			local texture = cell.texture
			if texture and texture ~= "" then
				local iw = cell.icon_w or 0.32
				local ih = cell.icon_h or 0.32
				local px = cell.pad_x or 0.05
				local py = cell.pad_y or 0.07
				table.insert(fs, string.format("image[%.2f,%.2f;%.2f,%.2f;%s]", cx + px, y + py, iw, ih, escape(texture)))
			end

		elseif ctype == "badge" then
			local text = cell.text or ""
			local bg = cell.bg_color or th.colors.card_inner_bg
			local fg = cell.text_color or th.colors.text_primary
			local bw = cell.badge_w or (cw - 0.10)
			local bh = cell.badge_h or (h - 0.14)
			local px = cell.pad_x or 0.05
			local py = cell.pad_y or 0.07
			table.insert(fs, string.format("box[%.2f,%.2f;%.2f,%.2f;%s]", cx + px, y + py, bw, bh, bg))
			table.insert(fs, string.format("style_type[label;font=bold;font_size=-1;textcolor=%s]", fg))
			table.insert(fs, string.format("label[%.2f,%.2f;%s]", cx + px + 0.08, y + py + 0.15, escape(text)))

		elseif ctype == "custom" and type(cell.fn) == "function" then
			cell.fn(fs, y, cx, cw, cell)
		end
	end
end

--- Renders a visual group / section divider inside the list
function ui_list.render_section_divider(fs, y, w, h, title, icon, color, th)
	table.insert(fs, string.format("box[0.00,%.2f;%.2f,%.2f;%s]", y, w, h, th.colors.card_bg))
	table.insert(fs, string.format("box[0.00,%.2f;0.05,%.2f;%s]", y, h, color or th.colors.brand_green))

	local text_x = 0.15
	if icon and icon ~= "" then
		table.insert(fs, string.format("image[0.10,%.2f;0.30,0.30;%s]", y + (h - 0.30) / 2, escape(icon)))
		text_x = 0.50
	end

	table.insert(fs, string.format("style_type[label;font=bold;font_size=+0;textcolor=%s]", color or th.colors.text_primary))
	table.insert(fs, string.format("label[%.2f,%.2f;%s]", text_x, y + 0.22, escape(title)))
end

--- Renders an empty list state with helpful feedback
function ui_list.render_empty(fs, y, w, _h, message, clear_btn_name, th)
	table.insert(fs, string.format("style_type[label;font=bold;font_size=+0;textcolor=%s]", th.colors.text_muted))
	table.insert(fs, string.format("label[%.2f,%.2f;%s]", (w / 2) - 2.5, y + 1.5, escape(message)))

	if clear_btn_name then
		table.insert(fs, th.button_secondary(
			(w / 2) - 1.5, y + 2.2, 3.0, 0.65,
			clear_btn_name, fgettext("Clear Search"), fgettext("Clear search filter to view all items")
		))
	end
end

--- Closes scroll container and creates dynamic scrollbar if needed
function ui_list.render_scroll_end(fs, params)
	local visible_h = params.visible_h or 9.75
	local total_h = params.total_h or 0.0
	local scroll_val = params.scroll_val or 0
	local bar_x = params.bar_x or 11.75
	local bar_y = params.bar_y or 1.85
	local bar_w = params.bar_w or 0.25
	local bar_h = params.bar_h or 9.75
	local scroll_name = params.scroll_name or "list_scroll"
	local scroll_factor = params.scroll_factor or 0.1

	table.insert(fs, "scroll_container_end[]")

	if total_h > visible_h then
		local max_scroll_dist = math.max(0, total_h - visible_h)
		local scroll_max = math.max(10, math.ceil(max_scroll_dist / scroll_factor))
		local thumb_size = math.max(10, math.floor(visible_h / scroll_factor))
		local clamped_scroll = math.min(scroll_val, scroll_max)

		table.insert(fs, string.format(
			"scrollbaroptions[min=0;max=%d;smallstep=5;largestep=25;thumbsize=%d]",
			scroll_max, thumb_size
		))
		table.insert(fs, string.format(
			"scrollbar[%.2f,%.2f;%.2f,%.2f;vertical;%s;%d]",
			bar_x, bar_y, bar_w, bar_h, scroll_name, clamped_scroll
		))
	end
end

return ui_list
