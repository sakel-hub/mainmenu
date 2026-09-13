-- Luanti Main Menu Redesign
-- Resume Server Modal Dialog with User Name & Password Entry
-- Note: Passwords are NEVER saved to disk or persistent settings.

local function resume_server_formspec(dialogdata)
	dialogdata = dialogdata or {}
	local th = (mainmenu and mainmenu.theme) or rawget(_G, "theme") or (custom_menupath and dofile(custom_menupath .. DIR_DELIM .. "theme.lua"))
	local c = th and th.colors or {
		btn_secondary_bg = "#1e3852aa",
		btn_secondary_hover = "#2d557caa",
		btn_secondary_pressed = "#162c42cc",
		btn_secondary_focus = "#38bdf8",
		btn_primary_bg = "#16a34a",
		btn_primary_hover = "#22c55e",
		btn_primary_pressed = "#14532d",
		btn_primary_pressed_text = "#86efac",
		btn_primary_focus = "#4ade80",
		btn_danger_bg = "#dc2626",
		card_bg = "#0f1f33f0",
		card_inner_bg = "#0b1724cc",
		card_border_light = "#38bdf844",
		card_border_dark = "#0c1520cc",
		brand_cyan = "#06b6d4",
		brand_green_hover = "#22c55e",
		text_muted = "#cbd5e1",
		text_primary = "#ffffff",
	}

	local s_name = dialogdata.server and (dialogdata.server.name or dialogdata.server.address) or dialogdata.address or "Server"
	local s_addr = dialogdata.address or (dialogdata.server and dialogdata.server.address) or ""
	local s_port = tostring(dialogdata.port or (dialogdata.server and dialogdata.server.port) or "30000")

	local box_h = dialogdata.error and 5.8 or 5.2
	local btn_y = dialogdata.error and 4.65 or 4.10
	local btn_font = (th and th.font_size and th.font_size("button")) or "font_size=+1"

	local fs = {
		"formspec_version[7]",
		string.format("size[8.2,%f]", box_h),
	}

	if th and th.get_styles then
		table.insert(fs, th.get_styles())
	else
		table.insert(fs, "style_type[field,pwdfield;border=false;textcolor=#ffffff]")
	end

	-- Header Section
	if th and th.label then
		table.insert(fs, th.label(0.5, 0.60, fgettext("RESUME SERVER"), "title", c.brand_cyan, "bold"))
		table.insert(fs, th.label(0.5, 1.02, fgettext("Connecting to $1 ($2:$3)", s_name:sub(1, 28), s_addr, s_port), "body", c.text_muted, "normal"))
	else
		table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]",
			(th and th.font_size and th.font_size("title")) or "font_size=+2", c.brand_cyan))
		table.insert(fs, string.format("label[0.5,0.60;%s]", core.formspec_escape(fgettext("RESUME SERVER"))))

		table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]",
			(th and th.font_size and th.font_size("body")) or "font_size=+0", c.text_muted))
		table.insert(fs, string.format("label[0.5,1.02;%s]",
			core.formspec_escape(fgettext("Connecting to $1 ($2:$3)", s_name:sub(1, 28), s_addr, s_port))))
	end

	-- User Name & Password Input Boxes
	local is_pwd_focused = (dialogdata.focused_field == "te_resume_pwd") or (not dialogdata.focused_field and dialogdata.name and dialogdata.name ~= "")
	local is_name_focused = not is_pwd_focused
	if th and th.text_input and th.password_input then
		table.insert(fs, th.text_input(0.5, 1.70, 7.2, 0.75, "te_resume_name", fgettext("User Name"), dialogdata.name or "", is_name_focused))
		table.insert(fs, th.password_input(0.5, 2.95, 7.2, 0.75, "te_resume_pwd", fgettext("Password"), is_pwd_focused))
	else
		if th and th.input_box then
			table.insert(fs, th.input_box(0.5, 1.70, 7.2, 0.75, is_name_focused))
			table.insert(fs, th.input_box(0.5, 2.95, 7.2, 0.75, is_pwd_focused))
		end

		local pad_x = 0.15
		table.insert(fs, string.format("field[%f,1.70;%f,0.75;te_resume_name;%s;%s]",
			0.5 + pad_x, 7.2 - 2 * pad_x,
			core.formspec_escape(fgettext("User Name")),
			core.formspec_escape(dialogdata.name or "")))
		table.insert(fs, string.format("field[%f,2.95;%f,0.75;te_resume_pwd;%s;]",
			0.5 + pad_x, 7.2 - 2 * pad_x,
			core.formspec_escape(fgettext("Password"))))

		if th and th.focus_overlay then
			table.insert(fs, th.focus_overlay(0.5, 1.70, 7.2, 0.75, "te_resume_name", is_name_focused))
			table.insert(fs, th.focus_overlay(0.5, 2.95, 7.2, 0.75, "te_resume_pwd", is_pwd_focused))
		end

		table.insert(fs, "field_enter_after_edit[te_resume_name;true]")
		table.insert(fs, "field_enter_after_edit[te_resume_pwd;true]")
	end

	-- Error message display
	if dialogdata.error then
		if th and th.label then
			table.insert(fs, th.label(0.5, 3.95, "⚠ " .. dialogdata.error, "caption", c.btn_danger_bg, "bold"))
		else
			table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]",
				(th and th.font_size and th.font_size("caption")) or "font_size=-1", c.btn_danger_bg))
			table.insert(fs, string.format("label[0.5,3.95;⚠ %s]", core.formspec_escape(dialogdata.error)))
		end
	end

	-- Button Styles & Controls
	if th and th.button_secondary and th.button_primary then
		table.insert(fs, th.button_secondary(0.5, btn_y, 3.45, 0.85, "btn_resume_cancel", fgettext("Cancel"), nil, true, btn_font))
		table.insert(fs, th.button_primary(4.25, btn_y, 3.45, 0.85, "btn_resume_connect", fgettext("▶ CONNECT"), nil, true, btn_font))
	else
		table.insert(fs, string.format("button[0.5,%f;3.45,0.85;btn_resume_cancel;%s]",
			btn_y, core.formspec_escape(fgettext("Cancel"))))
		table.insert(fs, string.format("button[4.25,%f;3.45,0.85;btn_resume_connect;%s]",
			btn_y, core.formspec_escape(fgettext("▶ CONNECT"))))
	end

	return table.concat(fs, "")
end

local function resume_server_buttonhandler(this, fields)
	for k in pairs(fields) do
		if k:sub(1, 10) == "btn_focus_" then
			this.data.focused_field = k:sub(11)
			return true
		end
	end
	if fields.key_enter_field then
		if fields.key_enter_field == "te_resume_name" then
			this.data.focused_field = "te_resume_pwd"
		else
			this.data.focused_field = fields.key_enter_field
		end
	end
	if fields.te_resume_name ~= nil and fields.te_resume_name ~= (this.data.name or "") then
		this.data.focused_field = "te_resume_name"
	elseif fields.te_resume_pwd ~= nil and fields.te_resume_pwd ~= "" then
		this.data.focused_field = "te_resume_pwd"
	end
	if fields.te_resume_name then
		local s = (mainmenu and mainmenu.sanitize_player_name and mainmenu.sanitize_player_name(fields.te_resume_name)) or fields.te_resume_name:trim()
		this.data.name = s
	end
	this.data.error = nil

	if fields.btn_resume_cancel then
		this:delete()
		if this.parent then
			this.parent:show()
		end
		return true
	end

	if fields.btn_resume_connect or fields.key_enter then
		local player_name = this.data.name or ""
		if player_name == "" then
			this.data.error = fgettext("Please enter your user name")
			return true
		end

		local addr = this.data.address or ""
		local port = tonumber(this.data.port) or 30000
		local s_name = this.data.server and this.data.server.name or addr
		if not s_name or s_name == "" or s_name == addr then
			if addr == "127.0.0.1" or addr:lower() == "localhost" or addr == "::1" then
				s_name = "Localhost Server"
			end
		end

		-- Save user name to settings (passwords are NEVER stored)
		core.settings:set("name", player_name)
		core.settings:set("address", addr)
		core.settings:set("remote_port", tostring(port))
		core.settings:set("mainmenu_last_session_type", "server")
		core.settings:set("mainmenu_last_server_name", s_name)
		core.settings:set("mainmenu_last_server_address", addr)
		core.settings:set("mainmenu_last_server_port", tostring(port))
		core.settings:set("mainmenu_session_tab", "online")
		core.settings:write()

		local st = (mainmenu and mainmenu.state) or rawget(_G, "state")
		if st then
			st.set("player_name", player_name)
		end

		-- Configure join gamedata directly for engine
		_G.gamedata = _G.gamedata or {}
		gamedata.mode = "join"
		gamedata.address = addr
		gamedata.port = port
		gamedata.playername = player_name
		gamedata.password = fields.te_resume_pwd or ""
		gamedata.selected_world = 0
		gamedata.singleplayer = false

		local enable_split = core.settings:get_bool("enable_split_login_register")
		if enable_split == nil then
			enable_split = true
		end
		gamedata.allow_login_or_register = enable_split and "login" or "any"

		if this.data.server and this.data.server.name and this.data.server.name ~= "" then
			gamedata.servername = this.data.server.name
			gamedata.serverdescription = this.data.server.description or ""
			if serverlistmgr and serverlistmgr.add_favorite then
				serverlistmgr.add_favorite(this.data.server)
			end
		else
			gamedata.servername = ""
			gamedata.serverdescription = ""
			if serverlistmgr and serverlistmgr.add_favorite then
				serverlistmgr.add_favorite({
					address = addr,
					port = port,
					name = s_name,
				})
			end
		end

		this:delete()
		core.start()
		return true
	end

	return false
end

local function event_handler(event)
	if event == "DialogShow" then
		if mm_game_theme and mm_game_theme.set_engine then
			mm_game_theme.set_engine(true)
		end
		return true
	elseif event == "DialogHide" then
		if mainmenu and mainmenu.sync_game_theme then
			mainmenu.sync_game_theme(true)
		end
		return true
	end
	return false
end

function create_resume_server_dialog(server)
	server = server or {}
	local addr = server.address or core.settings:get("mainmenu_last_server_address") or core.settings:get("address") or ""
	local port = server.port or tonumber(core.settings:get("mainmenu_last_server_port") or core.settings:get("remote_port")) or 30000
	local player_name = core.settings:get("name") or ""

	local dlg = dialog_create("dlg_resume_server",
		resume_server_formspec,
		resume_server_buttonhandler,
		event_handler)

	dlg.data = {
		server = server,
		address = addr,
		port = port,
		name = player_name,
		error = nil,
	}

	return dlg
end
