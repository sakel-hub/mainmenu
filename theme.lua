-- Luanti Main Menu Redesign
-- Theme & Styling Module (Formspec Version 7)

local theme = {}

-- Modern Translucent Outdoor Slate & Vibrant Luanti Green Palette
theme.colors = {
	-- Translucent Backgrounds & Glassmorphic Panels
	backdrop                 = "#00000000", -- Fully transparent to prevent compounding layers
	backdrop_overlay         = "#08131e33", -- Sheer atmospheric tint (~20% opacity) so 3D sky/clouds shine through
	transparent              = "#00000000", -- Fully transparent color
	sidebar_bg               = "#0b172455", -- Frosted translucent sidebar glass (~33% opacity)
	sidebar_border           = "#25405c55",
	content_bg               = "#00000000",
	card_bg                  = "#0f203048", -- Translucent frosted glass card (~28% opacity)
	card_bg_hover            = "#16314866", -- Light interactive hover (~40% opacity)
	card_border_light        = "#4a77a366", -- Translucent voxel top/left highlight
	card_border_dark         = "#050c1455", -- Translucent voxel bottom/right shadow
	card_inner_bg            = "#0a172555", -- Translucent inset (~33% opacity) for tables and inputs
	input_bg                 = "#0a172555", -- Default translucent input background
	input_bg_focused         = "#020712f5", -- Rich, visibly darker obsidian background (~96% opacity) for focused/selected inputs
	header_bar_bg            = "#0b172488", -- Header bar background for table columns
	card_active_bg           = "#12302066", -- Active hero/card green-tinted translucent background
	tile_active_bg           = "#12302099", -- Active metric tile green-tinted background
	inspector_header_bg      = "#11263888", -- Translucent header bar for inspector sub-views
	subheader_bg             = "#1e293b77", -- Sub-headers in inspector panels
	card_expanded_bg         = "#0f172acc", -- Expanded card background for mods and ContentDB
	card_item_bg             = "#1e293b66", -- Collapsed mod card and server mod row background
	badge_contentdb_bg       = "#16653455", -- ContentDB translucent badge pill
	badge_server_bg          = "#1e293b66", -- Server mod badge pill

	-- Tables & Lists Selection & Interaction Colors
	table_highlight          = "#15803d88", -- Glowing translucent emerald selection highlight
	table_highlight_text     = "#ffffff",
	table_highlight_cyan     = "#0284c788", -- Translucent cyan highlight for mod lists
	list_hover_bg            = "#3e6c9c28", -- Table and list row hover
	list_pressed_bg          = "#1d365044", -- Table and list row pressed
	list_row_selected_bg     = "#15803d66", -- Emerald selection highlight for list rows
	list_row_alternate_bg    = "#0f203022", -- Alternating row background

	-- ContentDB & Package Type Badges
	badge_txp                = "#c084fc", -- Texture pack purple
	badge_mod                = "#4ade80", -- Mod emerald green
	badge_game               = "#fbbf24", -- Game gold
	badge_modpack            = "#38bdf8", -- Modpack sky cyan

	-- Vibrant Luanti Green Theme Accents
	brand_green              = "#22c55e", -- Emerald primary accent
	brand_green_hover        = "#4ade80", -- Mint highlight glow
	brand_green_pressed      = "#16a34a", -- Deep emerald
	brand_green_dark         = "#15803d",
	brand_green_deep         = "#14532d",
	brand_green_light        = "#86efac",
	brand_green_badge        = "#166534",
	brand_cyan               = "#38bdf8", -- Sky cyan complement
	brand_glow               = "#4ade80",

	-- Primary Action Buttons (Play World / Connect / Singleplayer / Join Server / Resume / Save)
	btn_primary_bg                  = "#16a34a",
	btn_primary_hover               = "#22c55e",
	btn_primary_pressed             = "#14532d",
	btn_primary_pressed_text        = "#86efac",
	btn_primary_focus               = "#4ade80",
	btn_primary_translucent_bg      = "#14532d66", -- Translucent deep emerald green glass
	btn_primary_border_light        = "#22c55e99", -- Vibrant emerald voxel highlight
	btn_primary_border_dark         = "#14532d88", -- Deep emerald voxel shadow
	btn_primary_translucent_hover   = "#16a34a88", -- Responsive emerald hover glow
	btn_primary_translucent_pressed = "#0d351d99", -- Depressed emerald glass

	-- Active Navigation & Filter Buttons / Selected State
	btn_active_bg            = "#15803d",
	btn_active_hover         = "#189648",
	btn_active_pressed       = "#14532d",
	btn_active_pressed_text  = "#86efac",
	btn_active_focus         = "#4ade80",

	-- Secondary & Management Buttons (Global Default, World Config, Settings, Dialog Cancel)
	btn_secondary_bg         = "#0f203048", -- Translucent slate-blue glass (exact same style as game tab cards)
	btn_secondary_hover      = "#16314899", -- Responsive frosted slate-blue hover
	btn_secondary_pressed    = "#08131e88", -- Soft depressed translucent glass
	btn_secondary_focus      = "#38bdf8",
	btn_solid_secondary_bg   = "#334155",   -- Solid high-contrast dialog secondary button
	btn_solid_secondary_hover= "#475569",   -- Solid dialog secondary button hover
	btn_solid_secondary_pressed = "#1e293b",-- Solid dialog secondary button pressed

	-- Navigation Pills & Category Filter Buttons (Inactive State)
	btn_pill_bg              = "#00000000",
	btn_pill_hover           = "#16314866",
	btn_pill_pressed         = "#08131e88",
	btn_pill_focus           = "#38bdf8",
	btn_filter_bg            = "#00000000",
	btn_filter_hover         = "#16314866",

	-- Compact Utility Buttons (Search / Clear / Refresh / Add Favorite / URL)
	btn_util_bg              = "#00000000",
	btn_util_hover           = "#16314866",
	btn_util_pressed         = "#08131e88",
	btn_util_focus           = "#38bdf8",

	-- Metric Tiles (Play Online)
	tile_btn_bg              = "#183248aa",
	tile_btn_hover           = "#254866aa",
	tile_btn_pressed         = "#0f2130cc",
	tile_btn_focus           = "#38bdf8",
	tile_btn_active_bg       = "#143d28",
	tile_btn_active_hover    = "#1b5236",
	tile_btn_active_pressed  = "#0e2b1c",
	tile_btn_active_focus    = "#4ade80",

	-- Destructive Action Buttons (Delete World / Quit Game / Uninstall)
	btn_danger_bg                 = "#dc2626",
	btn_danger_hover              = "#ef4444",
	btn_danger_pressed            = "#991b1b",
	btn_danger_focus              = "#f87171",
	btn_danger_text               = "#ffffff",
	btn_danger_pressed_text       = "#fca5a5",
	btn_danger_translucent_bg     = "#35121855", -- Sophisticated translucent crimson tint
	btn_danger_border_light       = "#991b1b88", -- Subtle red voxel highlight
	btn_danger_border_dark        = "#450a0a88", -- Deep red voxel shadow
	btn_danger_translucent_hover  = "#4c131b88", -- Responsive ruby red hover
	btn_danger_translucent_pressed= "#22070c99", -- Soft depressed ruby glass

	-- Status & Action Colors
	play_green               = "#22c55e",
	play_green_hover         = "#4ade80",
	play_green_pressed       = "#16a34a",
	danger_red               = "#ef4444",
	danger_red_hover         = "#f87171",
	danger_red_pressed       = "#b91c1c",
	warn_gold                = "#f59e0b",
	warn_gold_hover          = "#fbbf24",
	purple_creative          = "#a855f7",

	-- Ping & Latency Status Indicators
	ping_great               = "#4ade80", -- < 50ms
	ping_good                = "#a3e635", -- < 100ms
	ping_fair                = "#facc15", -- < 200ms
	ping_poor                = "#f87171", -- 200ms+

	-- Server Capacity & Client Count Indicators
	clients_empty            = "#64748b",
	clients_low              = "#cbd5e1",
	clients_med              = "#4ade80",
	clients_high             = "#facc15",
	clients_orange           = "#fb923c",
	clients_max              = "#ef4444",
	status_fav               = "#fde047",
	grey_out                 = "#aaaaaa",

	-- High-Contrast Readable Text Colors
	text_primary             = "#ffffff",
	text_secondary           = "#f1f5f9",
	text_muted               = "#cbd5e1", -- Unified high-contrast readable muted white
	text_green               = "#4ade80",
	text_accent              = "#22c55e",

	-- Sleek Modern Frosted Tooltip Colors
	tooltip_bg               = "#0b1724f5", -- Deep translucent obsidian slate (96% opacity)
	tooltip_text             = "#f8fafc",   -- Crisp, bright readable white
	tooltip_border           = "#22c55e",   -- Subtle emerald accent
}

local cached_vp_info = nil
local cached_vp_time = 0

-- Safely queries window information and computes viewport scale and tiers (cached per frame / 100ms)
function theme.get_viewport_info()
	local now = (core.get_us_time and core.get_us_time()) or (os.clock() * 1000000)
	if cached_vp_info and (now - cached_vp_time < 100000) then
		return cached_vp_info
	end

	local winfo = core.get_window_info()

	local max_x = (winfo and winfo.max_formspec_size and winfo.max_formspec_size.x) or 21.6
	local max_y = (winfo and winfo.max_formspec_size and winfo.max_formspec_size.y) or 12.0
	local is_touch = (winfo and winfo.touch_controls == true) or false
	local gui_scaling = (winfo and winfo.real_gui_scaling) or 1.0
	if gui_scaling <= 0 then gui_scaling = 1.0 end

	-- max_formspec_size is already converted into formspec coordinates by the engine
	local scale_x = max_x / 21.6
	local scale_y = max_y / 12.0
	local scale = math.min(scale_x, scale_y)

	local is_compact = (scale < 1.05) or is_touch
	local is_mobile = (scale < 0.70) or (is_touch and scale < 0.90)

	local tier = "desktop"
	if is_mobile then
		tier = "mobile"
	elseif is_compact then
		tier = "compact"
	end

	cached_vp_info = {
		winfo = winfo,
		scale = scale,
		tier = tier,
		is_touch = is_touch,
		is_compact = is_compact,
		is_mobile = is_mobile,
		real_gui_scaling = gui_scaling,
	}
	cached_vp_time = now

	return cached_vp_info
end


-- Proportional typography mapping: guarantees legibility and prevents clipping on small/mobile screens
function theme.font_size(level)
	local vp = theme.get_viewport_info()
	local tier = vp.tier

	if level == "hero" then
		-- Massive primary CTA buttons (e.g., "▶ JOIN SERVER")
		if tier == "desktop" then
			return "font_size=+2"
		elseif tier == "compact" then
			return "font_size=+1"
		else
			return "font_size=+0"
		end
	elseif level == "display" then
		-- Splash view titles (e.g. About logo LUANTI)
		if tier == "desktop" then
			return "font_size=+4"
		elseif tier == "compact" then
			return "font_size=+2"
		else
			return "font_size=+1"
		end
	elseif level == "title" then
		-- Card & Section titles ("WORLD DETAILS", "CONTENT DETAILS", "ONLINE PLAYERS")
		if tier == "desktop" then
			return "font_size=+2"
		elseif tier == "compact" then
			return "font_size=+1"
		else
			return "font_size=+0"
		end
	elseif level == "subtitle" then
		-- Card sub-headers, mod titles in thumbnail cards, dialog headings
		if tier == "desktop" then
			return "font_size=+1"
		else
			return "font_size=+0"
		end
	elseif level == "button" then
		-- Primary action buttons (play_world, dc_connect, world_create_confirm)
		if tier == "desktop" then
			return "font_size=+1"
		else
			return "font_size=+0"
		end
	elseif level == "button_sub" then
		-- Secondary buttons (world_configure, btn_mp_register, dialog cancel)
		return "font_size=+0"
	elseif level == "button_danger" then
		-- Destructive action buttons (delete world, quit confirm)
		if tier == "desktop" then
			return "font_size=+1"
		else
			return "font_size=+0"
		end
	elseif level == "table" or level == "list" then
		-- Table and textlist entries (servers, sp_worlds, pkglist)
		if tier == "desktop" then
			return "font_size=+1"
		else
			return "font_size=+0"
		end
	else
		-- Standard body, labels, badges, captions: NEVER negative to ensure legibility floor
		return "font_size=+0"
	end
end

-- Helper to generate style_type[label;...] with unified typography
function theme.label_style(level, color, font_weight)
	local weight = font_weight or "normal"
	local clr = color or theme.colors.text_primary
	return string.format("style_type[label;font=%s;%s;textcolor=%s]", weight, theme.font_size(level), clr)
end

-- Modern tableoptions helper using consolidated theme colors
function theme.tableoptions()
	return string.format(
		"tableoptions[background=%s;highlight=%s;highlight_text=%s;border=false]",
		theme.colors.card_inner_bg,
		theme.colors.table_highlight,
		theme.colors.table_highlight_text
	)
end

-- Modern frosted translucent voxel input container (eliminates legacy 3D sunken grey borders)
function theme.input_box(x, y, w, h, is_focused)
	local bg = is_focused and theme.colors.input_bg_focused or theme.colors.input_bg
	local b_light = is_focused and theme.colors.brand_green_hover or theme.colors.card_border_light
	local b_dark = is_focused and theme.colors.brand_green or theme.colors.card_border_dark
	local t = is_focused and 0.04 or 0.035 -- crisp voxel edge

	local res = {
		string.format("box[%f,%f;%f,%f;%s]", x, y, w, h, bg),
		string.format("box[%f,%f;%f,%f;%s]", x, y, w, t, b_light),
		string.format("box[%f,%f;%f,%f;%s]", x, y, t, h, b_light),
		string.format("box[%f,%f;%f,%f;%s]", x, y + h - t, w, t, b_dark),
		string.format("box[%f,%f;%f,%f;%s]", x + w - t, y, t, h, b_dark),
	}
	if is_focused then
		table.insert(res, string.format("box[%f,%f;%f,0.05;%s]", x, y + h - 0.05, w, theme.colors.brand_green_hover))
		table.insert(res, string.format("box[%f,%f;%f,0.02;%s]", x, y, w, theme.colors.brand_green_hover))
	end
	return table.concat(res, "")
end

-- Standard consistent horizontal padding for text inside input fields (field, pwdfield)
theme.input_padding_x = 0.15

-- Helper to calculate padded field coordinates from container coordinates (x, y, w, h)
function theme.field_coords(x, y, w, h, pad_x)
	local px = pad_x or theme.input_padding_x
	return x + px, y, w - (2 * px), h
end

-- Generates field[...] element with consistent left/right padding inside its container
function theme.field(x, y, w, h, name, label, default, pad_x)
	local fx, fy, fw, fh = theme.field_coords(x, y, w, h, pad_x)
	local l_str = (label and label ~= "") and core.formspec_escape(label) or ""
	local d_str = (default and default ~= "") and core.formspec_escape(default) or ""
	return string.format("field[%f,%f;%f,%f;%s;%s;%s]", fx, fy, fw, fh, name, l_str, d_str)
end

-- Generates password field element with consistent left/right padding inside its container.
-- Note: Luanti's C++ engine (GUIFormSpecMenu::parsePwdField) omits e->setDrawBackground(border),
-- which forces Irrlicht to paint hardcoded EGDC_EDITABLE (grey) and EGDC_FOCUSED_EDITABLE (green)
-- background rectangles over pwdfield. Generating field[...] with border=false properly suppresses
-- the engine background, allowing the modern voxel container and consistent styling to show through.
function theme.pwdfield(x, y, w, h, name, label, pad_x)
	local fx, fy, fw, fh = theme.field_coords(x, y, w, h, pad_x)
	local l_str = (label and label ~= "") and core.formspec_escape(label) or ""
	return string.format("field[%f,%f;%f,%f;%s;%s;]", fx, fy, fw, fh, name, l_str)
end

-- Transparent click-to-focus overlay for unfocused input fields and force-focus for active fields.
-- When a field is focused, it emits set_focus to give it keyboard focus and blinking cursor.
-- When unfocused, it places a transparent, silent button over the input container so clicking into it
-- immediately focuses that field and switches the green border to it.
function theme.focus_overlay(x, y, w, h, name, is_focused)
	if is_focused then
		return string.format("set_focus[%s;true]", name)
	else
		local btn_id = "btn_focus_" .. name
		return string.format("style[%s,%s:hovered,%s:pressed;border=false;bgcolor=#00000000;sound=]button[%f,%f;%f,%f;%s;]",
			btn_id, btn_id, btn_id, x, y, w, h, btn_id)
	end
end

-- Helper to ensure formspec text is escaped exactly once (prevents double-escaping when fgettext was used)
function theme.escape_once(text)
	if not text or text == "" then return "" end
	-- If the string already contains formspec escape sequences like \, \; \[ \] \$, unescape them first
	local unescaped = tostring(text):gsub("\\([\\%[%];,$])", "%1")
	return core.formspec_escape(unescaped)
end

-- Formspec tooltip helper with modern translucent slate styling
function theme.tooltip(name, text)
	if not text or text == "" then return "" end
	return string.format("tooltip[%s;%s;%s;%s]",
		name,
		theme.escape_once(text),
		theme.colors.tooltip_bg,
		theme.colors.tooltip_text
	)
end

-- Formspec area tooltip helper with modern translucent slate styling
function theme.tooltip_area(x, y, w, h, text)
	if not text or text == "" then return "" end
	return string.format("tooltip[%.2f,%.2f;%.2f,%.2f;%s;%s;%s]",
		x, y, w, h,
		theme.escape_once(text),
		theme.colors.tooltip_bg,
		theme.colors.tooltip_text
	)
end

-- Renders a voxel card with crisp top/left highlight and bottom/right shadow
function theme.voxel_box(x, y, w, h, bg_color, border_highlight, border_shadow)
	local bg = bg_color or theme.colors.card_bg
	local b_light = border_highlight or theme.colors.card_border_light
	local b_dark = border_shadow or theme.colors.card_border_dark
	local t = 0.035 -- thickness of voxel edge

	return string.format(
		"box[%f,%f;%f,%f;%s]" ..
		"box[%f,%f;%f,%f;%s]" ..
		"box[%f,%f;%f,%f;%s]" ..
		"box[%f,%f;%f,%f;%s]" ..
		"box[%f,%f;%f,%f;%s]",
		x, y, w, h, bg,
		x, y, w, t, b_light,                  -- Top highlight
		x, y, t, h, b_light,                  -- Left highlight
		x, y + h - t, w, t, b_dark,           -- Bottom shadow
		x + w - t, y, t, h, b_dark            -- Right shadow
	)
end

-- Modern voxel card / panel (alias to voxel_box)
function theme.card(x, y, w, h, bg_color, border_highlight, border_shadow)
	return theme.voxel_box(x, y, w, h, bg_color, border_highlight, border_shadow)
end

-- Inner inset card / sub-panel using card_inner_bg
function theme.inner_card(x, y, w, h)
	return theme.voxel_box(x, y, w, h, theme.colors.card_inner_bg, theme.colors.card_border_light, theme.colors.card_border_dark)
end

-- Header bar with background box and title label
function theme.header_bar(x, y, w, h, title, icon)
	local fs = {
		string.format("box[%f,%f;%f,%f;%s]", x, y, w, h, theme.colors.header_bar_bg),
	}
	local text_x = x + 0.15
	if icon and icon ~= "" then
		local icon_size = math.max(0.2, h - 0.15)
		local icon_y = y + (h - icon_size) / 2
		table.insert(fs, string.format("image[%f,%f;%f,%f;%s]", text_x, icon_y, icon_size, icon_size, core.formspec_escape(icon)))
		text_x = text_x + icon_size + 0.15
	end
	table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", theme.font_size("subtitle"), theme.colors.text_primary))
	table.insert(fs, string.format("label[%f,%f;%s]", text_x, y + h / 2, core.formspec_escape(title or "")))
	return table.concat(fs, "")
end

-- Formatted label with typography scaling and color
function theme.label(x, y, text, level, color, font_weight)
	local l_style = theme.label_style(level or "body", color, font_weight)
	return string.format("%slabel[%f,%f;%s]", l_style, x, y, core.formspec_escape(text or ""))
end

-- Badge / Pill tag with solid background and bold label
function theme.badge(x, y, w, h, text, bg_color, text_color)
	local bg = bg_color or theme.colors.card_inner_bg
	local tc = text_color or theme.colors.text_primary
	local fs = {
		theme.voxel_box(x, y, w, h, bg, theme.colors.card_border_light, theme.colors.card_border_dark),
		string.format("style_type[label;font=bold;%s;textcolor=%s]", theme.font_size("caption"), tc),
		string.format("label[%f,%f;%s]", x + 0.15, y + h / 2, core.formspec_escape(text or "")),
	}
	return table.concat(fs, "")
end

local function to_coord_str(val)
	if type(val) == "string" then
		return val
	elseif type(val) == "number" then
		return string.format("%f", val)
	end
	return tostring(val or "")
end

-- Primary action button (translucent emerald green CTA voxel button matching theme)
function theme.button_primary(x, y, w, h, name, label, tooltip, is_solid, custom_font)
	if type(is_solid) == "string" and not custom_font then
		custom_font = is_solid
		is_solid = false
	end
	local c = theme.colors
	local font = custom_font or theme.font_size("button")
	local fs = {}
	local nx, ny, nw, nh = tonumber(x) or 0, tonumber(y) or 0, tonumber(w) or 0, tonumber(h) or 0

	if is_solid then
		table.insert(fs, string.format("style[%s;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_primary_bg, c.text_primary, font))
		table.insert(fs, string.format("style[%s:hovered;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_primary_hover, c.text_primary, font))
		table.insert(fs, string.format("style[%s:focused;border=true;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_primary_focus, c.btn_primary_hover, c.text_primary, font))
		table.insert(fs, string.format("style[%s:focused+hovered;border=true;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_primary_focus, c.btn_primary_hover, c.text_primary, font))
		table.insert(fs, string.format("style[%s:pressed;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_primary_pressed, c.btn_primary_pressed_text, font))
		table.insert(fs, string.format("button[%s,%s;%s,%s;%s;%s]", to_coord_str(x), to_coord_str(y), to_coord_str(w), to_coord_str(h), name, theme.escape_once(label or "")))
	else
		local bg_color = c.btn_primary_translucent_bg or "#14532d66"
		local b_light = c.btn_primary_border_light or "#22c55e99"
		local b_dark = c.btn_primary_border_dark or "#14532d88"
		table.insert(fs, theme.voxel_box(nx, ny, nw, nh, bg_color, b_light, b_dark))
		table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000;textcolor=%s;font=bold;%s]",
			name, c.text_primary, font))
		table.insert(fs, string.format("style[%s:hovered;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.text_primary, c.btn_primary_translucent_hover or "#16a34a88", font))
		table.insert(fs, string.format("style[%s:focused;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.btn_primary_focus or "#4ade80", c.text_primary, c.btn_primary_translucent_hover or "#16a34a88", font))
		table.insert(fs, string.format("style[%s:focused+hovered;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.btn_primary_focus or "#4ade80", c.text_primary, c.btn_primary_translucent_hover or "#16a34a88", font))
		table.insert(fs, string.format("style[%s:pressed;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.btn_primary_pressed_text or "#86efac", c.btn_primary_translucent_pressed or "#0d351d99", font))
		table.insert(fs, string.format("button[%s,%s;%s,%s;%s;%s]",
			to_coord_str(x), to_coord_str(y), to_coord_str(w), to_coord_str(h), name, theme.escape_once(label or "")))
	end

	if tooltip and tooltip ~= "" then
		table.insert(fs, theme.tooltip(name, tooltip))
	end
	return table.concat(fs, "")
end

-- Secondary action button (translucent slate-blue or solid for dialogs)
function theme.button_secondary(x, y, w, h, name, label, tooltip, is_solid, custom_font)
	if type(is_solid) == "string" and not custom_font then
		custom_font = is_solid
		is_solid = false
	end
	local c = theme.colors
	local font = custom_font or theme.font_size("button_sub")
	local fs = {}

	local nx, ny, nw, nh = tonumber(x) or 0, tonumber(y) or 0, tonumber(w) or 0, tonumber(h) or 0
	if is_solid then
		local s_bg = c.btn_solid_secondary_bg or "#334155"
		local s_hov = c.btn_solid_secondary_hover or "#475569"
		local s_pre = c.btn_solid_secondary_pressed or "#1e293b"
		table.insert(fs, string.format("style[%s;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]", name, s_bg, c.text_secondary, font))
		table.insert(fs, string.format("style[%s:hovered;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]", name, s_hov, c.text_primary, font))
		table.insert(fs, string.format("style[%s:focused;border=true;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_secondary_focus, s_bg, c.text_primary, font))
		table.insert(fs, string.format("style[%s:focused+hovered;border=true;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_secondary_focus, s_hov, c.text_primary, font))
		table.insert(fs, string.format("style[%s:pressed;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]", name, s_pre, c.text_muted, font))
		table.insert(fs, string.format("button[%s,%s;%s,%s;%s;%s]", to_coord_str(x), to_coord_str(y), to_coord_str(w), to_coord_str(h), name, theme.escape_once(label or "")))
	else
		table.insert(fs, theme.voxel_box(nx, ny, nw, nh, c.card_inner_bg, c.card_border_light, c.card_border_dark))
		table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000;textcolor=%s;font=bold;%s]", name, c.text_secondary, font))
		table.insert(fs, string.format("style[%s:hovered;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]", name, c.text_primary, c.card_bg_hover, font))
		table.insert(fs, string.format("style[%s:focused;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]", name, c.btn_secondary_focus, c.text_primary, c.card_bg_hover, font))
		table.insert(fs, string.format("style[%s:focused+hovered;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]", name, c.btn_secondary_focus, c.text_primary, c.card_bg_hover, font))
		table.insert(fs, string.format("style[%s:pressed;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]", name, c.text_muted, c.btn_secondary_pressed, font))
		table.insert(fs, string.format("button[%s,%s;%s,%s;%s;%s]", to_coord_str(x), to_coord_str(y), to_coord_str(w), to_coord_str(h), name, theme.escape_once(label or "")))
	end

	if tooltip and tooltip ~= "" then
		table.insert(fs, theme.tooltip(name, tooltip))
	end
	return table.concat(fs, "")
end

-- Destructive action button (red, translucent voxel button by default matching Settings/Quit)
function theme.button_danger(x, y, w, h, name, label, tooltip, is_solid, custom_font)
	if type(is_solid) == "string" and not custom_font then
		custom_font = is_solid
		is_solid = false
	end
	local c = theme.colors
	local font = custom_font or theme.font_size("button_danger")
	local fs = {}
	local nx, ny, nw, nh = tonumber(x) or 0, tonumber(y) or 0, tonumber(w) or 0, tonumber(h) or 0

	if is_solid then
		table.insert(fs, string.format("style[%s;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_danger_bg, c.btn_danger_text, font))
		table.insert(fs, string.format("style[%s:hovered;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_danger_hover, c.text_primary, font))
		table.insert(fs, string.format("style[%s:focused;border=true;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_danger_focus, c.btn_danger_hover, c.text_primary, font))
		table.insert(fs, string.format("style[%s:focused+hovered;border=true;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_danger_focus, c.btn_danger_hover, c.text_primary, font))
		table.insert(fs, string.format("style[%s:pressed;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]", name, c.btn_danger_pressed, c.btn_danger_pressed_text, font))
		table.insert(fs, string.format("button[%s,%s;%s,%s;%s;%s]", to_coord_str(x), to_coord_str(y), to_coord_str(w), to_coord_str(h), name, theme.escape_once(label or "")))
	else
		local bg_color = c.btn_danger_translucent_bg or "#35121855"
		local b_light = c.btn_danger_border_light or "#991b1b88"
		local b_dark = c.btn_danger_border_dark or "#450a0a88"
		table.insert(fs, theme.voxel_box(nx, ny, nw, nh, bg_color, b_light, b_dark))
		table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000;textcolor=%s;font=bold;%s]",
			name, c.btn_danger_pressed_text or "#fca5a5", font))
		table.insert(fs, string.format("style[%s:hovered;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.text_primary, c.btn_danger_translucent_hover or "#4c131b88", font))
		table.insert(fs, string.format("style[%s:focused;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.btn_danger_focus or "#ef4444", c.text_primary, c.btn_danger_translucent_hover or "#4c131b88", font))
		table.insert(fs, string.format("style[%s:focused+hovered;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.btn_danger_focus or "#ef4444", c.text_primary, c.btn_danger_translucent_hover or "#4c131b88", font))
		table.insert(fs, string.format("style[%s:pressed;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.text_muted, c.btn_danger_translucent_pressed or "#22070c99", font))
		table.insert(fs, string.format("button[%s,%s;%s,%s;%s;%s]",
			to_coord_str(x), to_coord_str(y), to_coord_str(w), to_coord_str(h), name, theme.escape_once(label or "")))
	end

	if tooltip and tooltip ~= "" then
		table.insert(fs, theme.tooltip(name, tooltip))
	end
	return table.concat(fs, "")
end

-- URL link button (translucent voxel button matching theme.button_secondary)
function theme.button_url(x, y, w, h, name, label, url, tooltip, custom_font)
	local c = theme.colors
	local font = custom_font or theme.font_size("button_sub")
	local fs = {}
	local nx, ny, nw, nh = tonumber(x) or 0, tonumber(y) or 0, tonumber(w) or 0, tonumber(h) or 0

	table.insert(fs, theme.voxel_box(nx, ny, nw, nh, c.card_inner_bg, c.card_border_light, c.card_border_dark))
	table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000;textcolor=%s;font=bold;%s]", name, c.text_secondary, font))
	table.insert(fs, string.format("style[%s:hovered;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]", name, c.text_primary, c.card_bg_hover, font))
	table.insert(fs, string.format("style[%s:focused;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]", name, c.btn_secondary_focus, c.text_primary, c.card_bg_hover, font))
	table.insert(fs, string.format("style[%s:focused+hovered;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]", name, c.btn_secondary_focus, c.text_primary, c.card_bg_hover, font))
	table.insert(fs, string.format("style[%s:pressed;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]", name, c.text_muted, c.btn_secondary_pressed, font))
	table.insert(fs, string.format("button_url[%s,%s;%s,%s;%s;%s;%s]",
		to_coord_str(x), to_coord_str(y), to_coord_str(w), to_coord_str(h), name, theme.escape_once(label or ""), core.formspec_escape(url or "")))

	if tooltip and tooltip ~= "" then
		table.insert(fs, theme.tooltip(name, tooltip))
	end
	return table.concat(fs, "")
end

-- Modern Metric Tile (Play Online / Diagnostics)
function theme.metric_tile(tx, ty, tw, th_h, btn_name, icon_name_or_path, val_str, title_str, is_act, val_clr, tip_str)
	local c = theme.colors
	local fs = {}

	-- Base tile card background
	if is_act then
		table.insert(fs, theme.voxel_box(tx, ty, tw, th_h, c.tile_active_bg or "#0f2f1eaa", c.brand_green, c.brand_green_dark))
	else
		table.insert(fs, theme.voxel_box(tx, ty, tw, th_h, c.card_inner_bg))
	end

	-- Button layer (clean vector bgcolor hover/press states, border=true to prevent engine hover bug)
	if is_act then
		table.insert(fs, string.format("style[%s;border=true;bgcolor=%s;sound=ui_click]", btn_name, c.tile_btn_active_bg))
		table.insert(fs, string.format("style[%s:hovered;border=true;bgcolor=%s]", btn_name, c.tile_btn_active_hover))
		table.insert(fs, string.format("style[%s:focused;border=true;bordercolor=%s;bgcolor=%s]",
			btn_name, c.tile_btn_active_focus, c.tile_btn_active_bg))
		table.insert(fs, string.format("style[%s:focused+hovered;border=true;bordercolor=%s;bgcolor=%s]",
			btn_name, c.tile_btn_active_focus, c.tile_btn_active_hover))
		table.insert(fs, string.format("style[%s:pressed;border=true;bgcolor=%s]", btn_name, c.tile_btn_active_pressed))
	else
		table.insert(fs, string.format("style[%s;border=true;bgcolor=%s;sound=ui_click]", btn_name, c.tile_btn_bg))
		table.insert(fs, string.format("style[%s:hovered;border=true;bgcolor=%s]", btn_name, c.tile_btn_hover))
		table.insert(fs, string.format("style[%s:focused;border=true;bordercolor=%s;bgcolor=%s]",
			btn_name, c.tile_btn_focus, c.tile_btn_bg))
		table.insert(fs, string.format("style[%s:focused+hovered;border=true;bordercolor=%s;bgcolor=%s]",
			btn_name, c.tile_btn_focus, c.tile_btn_hover))
		table.insert(fs, string.format("style[%s:pressed;border=true;bgcolor=%s]", btn_name, c.tile_btn_pressed))
	end
	table.insert(fs, string.format("button[%f,%f;%f,%f;%s;]", tx, ty, tw, th_h, btn_name))
	if tip_str and tip_str ~= "" then
		table.insert(fs, theme.tooltip(btn_name, tip_str))
	end

	-- Active indicator accent bar
	if is_act then
		table.insert(fs, string.format("box[%f,%f;%f,0.04;%s]", tx, ty, tw, c.brand_green_hover))
	end

	-- Foreground Icon (rendered on top of button; engine passes clicks through)
	local icon_path = icon_name_or_path or ""
	if defaulttexturedir and not icon_path:find("/") then
		icon_path = defaulttexturedir .. icon_path
	end
	table.insert(fs, string.format("image[%f,%f;0.58,0.58;%s]", tx + 0.10, ty + 0.10,
		core.formspec_escape(icon_path)))

	-- Foreground Metric Value (rendered on top of button, with balanced top padding)
	local v_clr = val_clr or c.text_primary
	table.insert(fs, "style_type[label;font=bold;font_size=+0;textcolor=" ..
		(is_act and c.brand_green_hover or v_clr) .. "]")
	table.insert(fs, string.format("label[%f,%f;%s]", tx + 0.80, ty + 0.25, core.formspec_escape(val_str or "")))

	-- Foreground Subtitle Label (rendered on top of button)
	table.insert(fs, "style_type[label;font=normal;font_size=+0;textcolor=" ..
		(is_act and (c.brand_green_light or "#86efac") or c.text_muted) .. "]")
	table.insert(fs, string.format("label[%f,%f;%s]", tx + 0.80, ty + 0.53, core.formspec_escape(title_str or "")))

	return table.concat(fs, "")
end

-- Universal translucent toggle / tab / filter pill button component
function theme.button_tab(x, y, w, h, name, label, is_active, tooltip, active_indicator, custom_font)
	local c = theme.colors
	local font = custom_font or theme.font_size("button_sub")
	local fs = {}
	local nx, ny, nw, nh = tonumber(x) or 0, tonumber(y) or 0, tonumber(w) or 0, tonumber(h) or 0

	if is_active then
		local active_bg = c.card_active_bg or "#12302066"
		table.insert(fs, theme.voxel_box(nx, ny, nw, nh, active_bg, c.brand_green, c.brand_green_dark))
		table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000;textcolor=%s;font=bold;%s]",
			name, c.brand_green_hover or "#4ade80", font))
		table.insert(fs, string.format("style[%s:hovered;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.text_primary, c.card_bg_hover, font))
		table.insert(fs, string.format("style[%s:focused;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.btn_secondary_focus, c.text_primary, c.card_bg_hover, font))
		table.insert(fs, string.format("style[%s:focused+hovered;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.btn_secondary_focus, c.text_primary, c.card_bg_hover, font))
		table.insert(fs, string.format("style[%s:pressed;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.text_muted, c.btn_secondary_pressed, font))
		table.insert(fs, string.format("button[%s,%s;%s,%s;%s;%s]",
			to_coord_str(x), to_coord_str(y), to_coord_str(w), to_coord_str(h), name, theme.escape_once(label or "")))

		if active_indicator == true or active_indicator == "left" then
			table.insert(fs, string.format("box[%f,%f;0.12,%f;%s]", nx, ny, nh, c.brand_green_hover or "#22c55e"))
		elseif active_indicator == "bottom" then
			table.insert(fs, string.format("box[%f,%f;%f,0.035;%s]", nx, ny + nh - 0.035, nw, c.brand_green_hover or "#22c55e"))
		end
	else
		table.insert(fs, theme.voxel_box(nx, ny, nw, nh, c.card_inner_bg, c.card_border_light, c.card_border_dark))
		table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000;textcolor=%s;font=bold;%s]",
			name, c.text_secondary, font))
		table.insert(fs, string.format("style[%s:hovered;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.text_primary, c.card_bg_hover, font))
		table.insert(fs, string.format("style[%s:focused;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.btn_secondary_focus, c.text_primary, c.card_bg_hover, font))
		table.insert(fs, string.format("style[%s:focused+hovered;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.btn_secondary_focus, c.text_primary, c.card_bg_hover, font))
		table.insert(fs, string.format("style[%s:pressed;border=false;textcolor=%s;bgcolor=%s;font=bold;%s]",
			name, c.text_muted, c.btn_secondary_pressed, font))
		table.insert(fs, string.format("button[%s,%s;%s,%s;%s;%s]",
			to_coord_str(x), to_coord_str(y), to_coord_str(w), to_coord_str(h), name, theme.escape_once(label or "")))
	end

	if tooltip and tooltip ~= "" then
		table.insert(fs, theme.tooltip(name, tooltip))
	end
	return table.concat(fs, "")
end

-- Segmented translucent button (delegates directly to button_tab with bottom indicator)
function theme.button_secondary_tab(x, y, w, h, name, label, is_active, tooltip, custom_font)
	return theme.button_tab(x, y, w, h, name, label, is_active, tooltip, "bottom", custom_font)
end

-- Image / icon button with translucent voxel background and tooltip
function theme.button_icon(x, y, w, h, name, texture_path, tooltip)
	local c = theme.colors
	local fs = {}
	local nx, ny, nw, nh = tonumber(x) or 0, tonumber(y) or 0, tonumber(w) or 0, tonumber(h) or 0

	table.insert(fs, theme.voxel_box(nx, ny, nw, nh, c.card_inner_bg, c.card_border_light, c.card_border_dark))
	table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000;sound=ui_click]", name))
	table.insert(fs, string.format("style[%s:hovered;border=false;bgcolor=%s]", name, c.card_bg_hover))
	table.insert(fs, string.format("style[%s:focused;border=false;bordercolor=%s;bgcolor=%s]", name, c.btn_secondary_focus, c.card_bg_hover))
	table.insert(fs, string.format("style[%s:focused+hovered;border=false;bordercolor=%s;bgcolor=%s]", name, c.btn_secondary_focus, c.card_bg_hover))
	table.insert(fs, string.format("style[%s:pressed;border=false;bgcolor=%s]", name, c.btn_secondary_pressed))
	table.insert(fs, string.format("image_button[%.2f,%.2f;%.2f,%.2f;%s;%s;]", x, y, w, h, core.formspec_escape(texture_path or ""), name))

	if tooltip and tooltip ~= "" then
		table.insert(fs, theme.tooltip(name, tooltip))
	end
	return table.concat(fs, "")
end

--- Renders a modern, accessible pill toggle switch with label
-- @param x number Horizontal coordinate
-- @param y number Vertical coordinate
-- @param w number Total interactive bounding width (pill + spacing + label)
-- @param h number Total interactive bounding height (e.g. 0.40 - 0.45)
-- @param name string Fieldname sent on click event
-- @param label string Label text displayed next to the toggle pill
-- @param is_checked boolean Active/enabled state
-- @param tooltip string Optional tooltip text
-- @return string Formspec snippet
function theme.toggle_switch(x, y, w, h, name, label, is_checked, tooltip)
	local c = theme.colors
	local tx = tonumber(x) or 0
	local ty = tonumber(y) or 0
	local tw = tonumber(w) or 4.5
	local th_h = tonumber(h) or 0.42

	local is_on = (is_checked == true or is_checked == "true" or is_checked == 1 or is_checked == "1")

	-- Pill dimensions (2:1 aspect ratio matching 128x64 texture)
	local ph = math.min(th_h, 0.38)
	local pw = ph * 2.0
	local pill_x = tx
	local pill_y = ty + (th_h - ph) / 2

	local tex_name = is_on and "toggle_pill_on.png" or "toggle_pill_off.png"
	local menupath = custom_menupath or core.get_mainmenu_path()
	local sep = (menupath:sub(-1) == "/" or menupath:sub(-1) == "\\") and "" or (DIR_DELIM or "/")
	local tex_path = menupath .. sep .. "textures" .. (DIR_DELIM or "/") .. tex_name

	local fs = {}

	-- 1. Visual Pill Switch Graphic
	table.insert(fs, string.format("image[%.2f,%.2f;%.2f,%.2f;%s]",
		pill_x, pill_y, pw, ph, core.formspec_escape(tex_path)))

	-- 2. Label Text
	local lx = pill_x + pw + 0.15
	local ly = ty + (th_h / 2)
	local tc = is_on and (c.text_primary or "#ffffff") or (c.text_secondary or "#cbd5e1")
	table.insert(fs, string.format("style_type[label;textcolor=%s;font=normal;%s]", tc, theme.font_size("body")))
	table.insert(fs, string.format("label[%.2f,%.2f;%s]", lx, ly, core.formspec_escape(label or "")))

	-- 3. Invisible Interactive Button covering whole pill + label row
	table.insert(fs, string.format("style[%s;border=false;bgcolor=#00000000;sound=ui_click]", name))
	table.insert(fs, string.format("style[%s:hovered;border=false;bgcolor=#00000000;sound=ui_click]", name))
	table.insert(fs, string.format("style[%s:pressed;border=false;bgcolor=#00000000;sound=ui_click]", name))
	table.insert(fs, string.format("style[%s:focused;border=false;bgcolor=#00000000]", name))
	table.insert(fs, string.format("button[%.2f,%.2f;%.2f,%.2f;%s;]", tx, ty, tw, th_h, name))

	-- 4. Tooltip
	if tooltip and tooltip ~= "" then
		table.insert(fs, theme.tooltip(name, tooltip))
	end

	return table.concat(fs, "")
end

-- Dialog action buttons pair (Cancel + Confirm)
function theme.dialog_actions(x, y, w, h, cancel_name, cancel_label, confirm_name, confirm_label, is_danger, custom_font)
	local gap = 0.40
	local btn_w = (w - gap) / 2
	local fs = {
		theme.button_secondary(x, y, btn_w, h, cancel_name, cancel_label, nil, true, custom_font),
	}
	local confirm_x = x + btn_w + gap
	if is_danger then
		table.insert(fs, theme.button_danger(confirm_x, y, btn_w, h, confirm_name, confirm_label, nil, true, custom_font))
	else
		table.insert(fs, theme.button_primary(confirm_x, y, btn_w, h, confirm_name, confirm_label, nil, true, custom_font))
	end
	return table.concat(fs, "")
end

-- Full composite text input with container, padding, focus overlay, and tooltip
function theme.text_input(x, y, w, h, name, label, value, is_focused, tooltip, title_label, label_focus_btn)
	local fs = {}
	if title_label and title_label ~= "" then
		local lbl_y = y - 0.30
		local lbl_col = is_focused and theme.colors.brand_green_hover or theme.colors.text_secondary
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", theme.font_size("caption"), lbl_col))
		table.insert(fs, string.format("label[%.2f,%f;%s]", x, lbl_y, core.formspec_escape(title_label)))
		local focus_btn = label_focus_btn or ("btn_focus_" .. name)
		table.insert(fs, string.format("style[%s,%s:hovered,%s:pressed;border=false;bgcolor=#00000000;sound=]", focus_btn, focus_btn, focus_btn))
		table.insert(fs, string.format("button[%.2f,%f;%.2f,0.30;%s;]", x, lbl_y - 0.05, w, focus_btn))
	end

	table.insert(fs, theme.input_box(x, y, w, h, is_focused))
	if is_focused then
		table.insert(fs, string.format("set_focus[%s;true]", name))
	end
	table.insert(fs, theme.field(x, y, w, h, name, label or "", value or ""))
	if not is_focused then
		table.insert(fs, theme.focus_overlay(x, y, w, h, name, false))
	end
	table.insert(fs, string.format("field_enter_after_edit[%s;true]", name))

	if tooltip and tooltip ~= "" then
		table.insert(fs, theme.tooltip(name, tooltip))
	end
	return table.concat(fs, "")
end

-- Full composite password input with container, padding, focus overlay, and tooltip
function theme.password_input(x, y, w, h, name, label, is_focused, tooltip, title_label, label_focus_btn)
	local fs = {}
	if title_label and title_label ~= "" then
		local lbl_y = y - 0.30
		local lbl_col = is_focused and theme.colors.brand_green_hover or theme.colors.text_secondary
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", theme.font_size("caption"), lbl_col))
		table.insert(fs, string.format("label[%.2f,%f;%s]", x, lbl_y, core.formspec_escape(title_label)))
		local focus_btn = label_focus_btn or ("btn_focus_" .. name)
		table.insert(fs, string.format("style[%s,%s:hovered,%s:pressed;border=false;bgcolor=#00000000;sound=]", focus_btn, focus_btn, focus_btn))
		table.insert(fs, string.format("button[%.2f,%f;%.2f,0.30;%s;]", x, lbl_y - 0.05, w, focus_btn))
	end

	table.insert(fs, theme.input_box(x, y, w, h, is_focused))
	if is_focused then
		table.insert(fs, string.format("set_focus[%s;true]", name))
	end
	table.insert(fs, theme.pwdfield(x, y, w, h, name, label or ""))
	if not is_focused then
		table.insert(fs, theme.focus_overlay(x, y, w, h, name, false))
	end
	table.insert(fs, string.format("field_enter_after_edit[%s;true]", name))

	if tooltip and tooltip ~= "" then
		table.insert(fs, theme.tooltip(name, tooltip))
	end
	return table.concat(fs, "")
end

-- Integrated Search Bar with input field + Search icon button + Clear icon button
function theme.search_bar(x, y, input_w, h, field_name, value, is_focused, search_btn_name, clear_btn_name, tooltip)
	local btn_w = h
	local gap1 = 0.10
	local gap2 = 0.05
	local fs = {
		theme.text_input(x, y, input_w, h, field_name, "", value, is_focused, tooltip),
	}

	local s_icon = (defaulttexturedir or "") .. "search.png"
	local c_icon = (defaulttexturedir or "") .. "clear.png"
	local s_btn_x = x + input_w + gap1
	local c_btn_x = s_btn_x + btn_w + gap2

	if search_btn_name and search_btn_name ~= "" then
		table.insert(fs, theme.button_icon(s_btn_x, y, btn_w, h, search_btn_name, s_icon, fgettext and fgettext("Search") or "Search"))
	end
	if clear_btn_name and clear_btn_name ~= "" then
		table.insert(fs, theme.button_icon(c_btn_x, y, btn_w, h, clear_btn_name, c_icon, fgettext and fgettext("Clear search") or "Clear search"))
	end

	return table.concat(fs, "")
end

-- Truncates a string to max_len, appending an ellipsis if exceeded
function theme.truncate_text(text, max_len)
	if not text then return "" end
	local s = tostring(text)
	if #s > max_len then
		return s:sub(1, max_len - 1) .. "…"
	end
	return s
end

-- Read-only multiline textarea with single escaping and title
function theme.textarea_readonly(x, y, w, h, text, title)
	local raw_desc = tostring(text or ""):gsub("\\([\\%[%];,$])", "%1")
	local full_text = raw_desc
	if title and title ~= "" then
		local raw_title = tostring(title):gsub("\\([\\%[%];,$])", "%1")
		if rawget(_G, "fgettext_ne") then
			full_text = fgettext_ne("Server: $1\n\n$2", raw_title, raw_desc)
		else
			full_text = string.format("Server: %s\n\n%s", raw_title, raw_desc)
		end
	end
	return string.format("textarea[%.2f,%.2f;%.2f,%.2f;;;%s]", x, y, w, h, theme.escape_once(full_text))
end

-- Generates global Formspec Version 7 style_type and style elements
function theme.get_styles()
	local c = theme.colors
	local btn_primary_font = theme.font_size("button")
	local btn_sec_font = theme.font_size("button_sub")
	local btn_danger_font = theme.font_size("button_danger")
	local body_font = theme.font_size("body")

	return table.concat({
		-- Global modern tooltip theme colors via listcolors (Formspec default for all tooltips)
		string.format("listcolors[#00000000;#00000000;#00000000;%s;%s]",
			c.tooltip_bg, c.tooltip_text),

		-- Hypertip modern theme styling
		string.format("style_type[hypertip;bgcolor=%s;border=false;textcolor=%s]",
			c.tooltip_bg, c.tooltip_text),

		-- Global clean button styles: sound feedback, translucent modern vector styling
		string.format("style_type[button,button_exit;border=false;sound=ui_click;font=bold;%s;textcolor=%s;bgcolor=%s]",
			btn_sec_font, c.text_secondary, c.btn_secondary_bg),
		string.format("style_type[button:hovered,button_exit:hovered;border=false;textcolor=%s;bgcolor=%s]",
			c.text_primary, c.btn_secondary_hover),
		string.format("style_type[button:pressed,button_exit:pressed;border=false;textcolor=%s;bgcolor=%s]",
			c.text_muted, c.btn_secondary_pressed),
		string.format("style_type[button:focused,button_exit:focused;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s]",
			c.btn_primary_focus, c.text_primary, c.btn_secondary_hover),
		string.format("style_type[button:focused+hovered,button_exit:focused+hovered;border=false;bordercolor=%s;textcolor=%s;bgcolor=%s]",
			c.btn_primary_focus, c.text_primary, c.btn_secondary_hover),

		-- Label styles
		string.format("style_type[label;textcolor=%s;%s]", c.text_secondary, body_font),

		-- Checkbox styles
		string.format("style_type[checkbox;textcolor=%s;sound=ui_click]", c.text_secondary),
		string.format("style_type[checkbox:focused;textcolor=%s;font=bold]", c.text_primary),

		-- Modern Inputs & Textareas (border=false removes legacy 3D sunken grey frame)
		string.format("style_type[field,pwdfield,textarea;border=false;bgcolor=#00000000;textcolor=%s;font=normal;%s]",
			c.text_primary, body_font),
		string.format("style_type[field:hovered,pwdfield:hovered,textarea:hovered;border=false;textcolor=%s]",
			c.text_primary),
		string.format("style_type[field:focused,pwdfield:focused,textarea:focused;border=false;bgcolor=%s;textcolor=%s;font=normal;%s]",
			c.input_bg_focused or "#020712f5", c.text_primary, body_font),
		string.format("style[te_name,te_pwd,te_passwd,te_playername,dc_address,dc_port,dc_name,dc_pwd,te_server_search,te_server_mod_search,te_world_search,te_content_search,te_resume_name,te_resume_pwd,password,password_2;border=false;bgcolor=#00000000;textcolor=%s;font=normal;%s]",
			c.text_primary, body_font),
		string.format("style[te_name:focused,te_pwd:focused,te_passwd:focused,te_playername:focused,dc_address:focused,dc_port:focused,dc_name:focused,dc_pwd:focused,te_server_search:focused,te_server_mod_search:focused,te_world_search:focused,te_content_search:focused,te_resume_name:focused,te_resume_pwd:focused,password:focused,password_2:focused;border=false;bgcolor=%s;textcolor=%s;font=normal;%s]",
			c.input_bg_focused or "#020712f5", c.text_primary, body_font),

		-- Tables & Textlists
		string.format("style_type[table,textlist;textcolor=%s;bgcolor=%s;border=false;sound=ui_click]",
			c.text_primary, c.card_inner_bg),
		string.format("style_type[table:focused,textlist:focused;border=true;bordercolor=%s]",
			c.brand_green_hover),

		-- Scrollbars
		"style_type[scrollbar;noclip=false]",

		-- Distinct Primary Action Buttons (Play World / Connect / Singleplayer / Join Server / Resume / ContentDB)
		string.format("style[play_world,btn_play_world,btn_connect_srv,btn_mp_login,btn_chooser_singleplayer,btn_resume_adventure,btn_contentdb,dc_connect,reconfigure,world_create_confirm,btn_config_world_save,dlg_register_confirm;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_primary_translucent_bg, c.text_primary, btn_primary_font),
		string.format("style[play_world:hovered,btn_play_world:hovered,btn_connect_srv:hovered,btn_mp_login:hovered,btn_chooser_singleplayer:hovered,btn_resume_adventure:hovered,btn_contentdb:hovered,dc_connect:hovered,reconfigure:hovered,world_create_confirm:hovered,btn_config_world_save:hovered,dlg_register_confirm:hovered;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_primary_translucent_hover, c.text_primary, btn_primary_font),
		string.format("style[play_world:pressed,btn_play_world:pressed,btn_connect_srv:pressed,btn_mp_login:pressed,btn_chooser_singleplayer:pressed,btn_resume_adventure:pressed,btn_contentdb:pressed,dc_connect:pressed,reconfigure:pressed,world_create_confirm:pressed,btn_config_world_save:pressed,dlg_register_confirm:pressed;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_primary_translucent_pressed, c.btn_primary_pressed_text, btn_primary_font),
		string.format("style[play_world:focused,btn_play_world:focused,btn_connect_srv:focused,btn_mp_login:focused,btn_chooser_singleplayer:focused,btn_resume_adventure:focused,btn_contentdb:focused,dc_connect:focused,reconfigure:focused,world_create_confirm:focused,btn_config_world_save:focused,dlg_register_confirm:focused;border=false;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_primary_focus, c.btn_primary_translucent_hover, c.text_primary, btn_primary_font),
		string.format("style[play_world:focused+hovered,btn_play_world:focused+hovered,btn_connect_srv:focused+hovered,btn_mp_login:focused+hovered,btn_chooser_singleplayer:focused+hovered,btn_resume_adventure:focused+hovered,btn_contentdb:focused+hovered,dc_connect:focused+hovered,reconfigure:focused+hovered,world_create_confirm:focused+hovered,btn_config_world_save:focused+hovered,dlg_register_confirm:focused+hovered;border=false;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_primary_focus, c.btn_primary_translucent_hover, c.text_primary, btn_primary_font),

		-- Secondary Management & Toolbar Buttons
		string.format("style[world_create,world_configure,btn_world_new,btn_world_config,btn_srv_direct_connect,btn_chooser_host,btn_chooser_join,btn_nav_to_games,game_open_cdb,open_settings,btn_open_pkg_dir,btn_open_world_folder,userdata,url_website,url_forums,btn_server_list_mods,btn_settings,btn_mp_register;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_secondary_bg, c.text_secondary, btn_sec_font),
		string.format("style[world_create:hovered,world_configure:hovered,btn_world_new:hovered,btn_world_config:hovered,btn_srv_direct_connect:hovered,btn_chooser_host:hovered,btn_chooser_join:hovered,btn_nav_to_games:hovered,game_open_cdb:hovered,open_settings:hovered,btn_open_pkg_dir:hovered,btn_open_world_folder:hovered,userdata:hovered,url_website:hovered,url_forums:hovered,btn_server_list_mods:hovered,btn_settings:hovered,btn_mp_register:hovered;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_secondary_hover, c.text_primary, btn_sec_font),
		string.format("style[world_create:pressed,world_configure:pressed,btn_world_new:pressed,btn_world_config:pressed,btn_srv_direct_connect:pressed,btn_chooser_host:pressed,btn_chooser_join:pressed,btn_nav_to_games:pressed,game_open_cdb:pressed,open_settings:pressed,btn_open_pkg_dir:pressed,btn_open_world_folder:pressed,userdata:pressed,url_website:pressed,url_forums:pressed,btn_server_list_mods:pressed,btn_settings:pressed,btn_mp_register:pressed;border=false;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_secondary_pressed, c.text_muted, btn_sec_font),
		string.format("style[world_create:focused,world_configure:focused,btn_world_new:focused,btn_world_config:focused,btn_srv_direct_connect:focused,btn_chooser_host:focused,btn_chooser_join:focused,btn_nav_to_games:focused,game_open_cdb:focused,open_settings:focused,btn_open_pkg_dir:focused,btn_open_world_folder:focused,userdata:focused,url_website:focused,url_forums:focused,btn_server_list_mods:focused,btn_settings:focused,btn_mp_register:focused;border=false;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_secondary_focus, c.btn_secondary_hover, c.text_primary, btn_sec_font),
		string.format("style[world_create:focused+hovered,world_configure:focused+hovered,btn_world_new:focused+hovered,btn_world_config:focused+hovered,btn_srv_direct_connect:focused+hovered,btn_chooser_host:focused+hovered,btn_chooser_join:focused+hovered,btn_nav_to_games:focused+hovered,game_open_cdb:focused+hovered,open_settings:focused+hovered,btn_open_pkg_dir:focused+hovered,btn_open_world_folder:focused+hovered,userdata:focused+hovered,url_website:focused+hovered,url_forums:focused+hovered,btn_server_list_mods:focused+hovered,btn_settings:focused+hovered,btn_mp_register:focused+hovered;border=false;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_secondary_focus, c.btn_secondary_hover, c.text_primary, btn_sec_font),

		-- Dialog Cancel & Secondary Action Buttons (Solid Visible Background)
		string.format("style[btn_quit_confirm_cancel,dc_cancel,dismiss,world_create_cancel,btn_config_world_cancel,dlg_register_cancel;border=true;bgcolor=#334155;textcolor=%s;font=bold;%s]",
			c.text_secondary, btn_sec_font),
		string.format("style[btn_quit_confirm_cancel:hovered,dc_cancel:hovered,dismiss:hovered,world_create_cancel:hovered,btn_config_world_cancel:hovered,dlg_register_cancel:hovered;border=true;bgcolor=#475569;textcolor=%s;font=bold;%s]",
			c.text_primary, btn_sec_font),
		string.format("style[btn_quit_confirm_cancel:pressed,dc_cancel:pressed,dismiss:pressed,world_create_cancel:pressed,btn_config_world_cancel:pressed,dlg_register_cancel:pressed;border=true;bgcolor=#1e293b;textcolor=%s;font=bold;%s]",
			c.text_muted, btn_sec_font),
		string.format("style[btn_quit_confirm_cancel:focused,dc_cancel:focused,dismiss:focused,world_create_cancel:focused,btn_config_world_cancel:focused,dlg_register_cancel:focused;border=true;bordercolor=%s;bgcolor=#334155;textcolor=%s;font=bold;%s]",
			c.btn_secondary_focus, c.text_primary, btn_sec_font),
		string.format("style[btn_quit_confirm_cancel:focused+hovered,dc_cancel:focused+hovered,dismiss:focused+hovered,world_create_cancel:focused+hovered,btn_config_world_cancel:focused+hovered,dlg_register_cancel:focused+hovered;border=true;bordercolor=%s;bgcolor=#475569;textcolor=%s;font=bold;%s]",
			c.btn_secondary_focus, c.text_primary, btn_sec_font),

		-- Destructive Action Buttons (Delete World / Quit Modal Confirm / Uninstall)
		string.format("style[world_delete,btn_world_delete,btn_quit_confirm_yes,btn_mod_mgr_delete_mod,dlg_delete_content_confirm,world_delete_confirm;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_danger_bg, c.btn_danger_text, btn_danger_font),
		string.format("style[world_delete:hovered,btn_world_delete:hovered,btn_quit_confirm_yes:hovered,btn_mod_mgr_delete_mod:hovered,dlg_delete_content_confirm:hovered,world_delete_confirm:hovered;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_danger_hover, c.text_primary, btn_danger_font),
		string.format("style[world_delete:pressed,btn_world_delete:pressed,btn_quit_confirm_yes:pressed,btn_mod_mgr_delete_mod:pressed,dlg_delete_content_confirm:pressed,world_delete_confirm:pressed;border=true;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_danger_pressed, c.btn_danger_pressed_text, btn_danger_font),
		string.format("style[world_delete:focused,btn_world_delete:focused,btn_quit_confirm_yes:focused,btn_mod_mgr_delete_mod:focused,dlg_delete_content_confirm:focused,world_delete_confirm:focused;border=true;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_danger_focus, c.btn_danger_hover, c.text_primary, btn_danger_font),
		string.format("style[world_delete:focused+hovered,btn_world_delete:focused+hovered,btn_quit_confirm_yes:focused+hovered,btn_mod_mgr_delete_mod:focused+hovered,dlg_delete_content_confirm:focused+hovered,world_delete_confirm:focused+hovered;border=true;bordercolor=%s;bgcolor=%s;textcolor=%s;font=bold;%s]",
			c.btn_danger_focus, c.btn_danger_hover, c.text_primary, btn_danger_font),

		-- Compact Utility Buttons (Search / Clear / Refresh / Fav / URL)
		string.format("style[btn_srv_refresh,btn_srv_clear,btn_srv_search,btn_world_search,btn_world_clear,btn_content_search,btn_content_clear,btn_add_favorite,btn_server_url;border=false;bgcolor=%s]",
			c.btn_util_bg),
		string.format("style[btn_srv_refresh:hovered,btn_srv_clear:hovered,btn_srv_search:hovered,btn_world_search:hovered,btn_world_clear:hovered,btn_content_search:hovered,btn_content_clear:hovered,btn_add_favorite:hovered,btn_server_url:hovered;border=false;bgcolor=%s]",
			c.btn_util_hover),
		string.format("style[btn_srv_refresh:pressed,btn_srv_clear:pressed,btn_srv_search:pressed,btn_world_search:pressed,btn_world_clear:pressed,btn_content_search:pressed,btn_content_clear:pressed,btn_add_favorite:pressed,btn_server_url:pressed;border=false;bgcolor=%s]",
			c.btn_util_pressed),
		string.format("style[btn_srv_refresh:focused,btn_srv_clear:focused,btn_srv_search:focused,btn_world_search:focused,btn_world_clear:focused,btn_content_search:focused,btn_content_clear:focused,btn_add_favorite:focused,btn_server_url:focused;border=false;bordercolor=%s;bgcolor=%s]",
			c.btn_util_focus, c.btn_util_hover),
		string.format("style[btn_srv_refresh:focused+hovered,btn_srv_clear:focused+hovered,btn_srv_search:focused+hovered,btn_world_search:focused+hovered,btn_world_clear:focused+hovered,btn_content_search:focused+hovered,btn_content_clear:focused+hovered,btn_add_favorite:focused+hovered,btn_server_url:focused+hovered;border=false;bordercolor=%s;bgcolor=%s]",
			c.btn_util_focus, c.btn_util_hover),
	}, "")
end

return theme
