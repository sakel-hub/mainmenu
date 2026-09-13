-- Luanti Main Menu Redesign
-- Direct Connect Modal Dialog

local function direct_connect_formspec(dialogdata)
	dialogdata = dialogdata or {}
	local th = (mainmenu and mainmenu.theme) or rawget(_G, "theme") or (custom_menupath and dofile(custom_menupath .. DIR_DELIM .. "theme.lua"))
	local c = (th and th.colors) or {}

	local fs = {
		"formspec_version[7]",
		"size[9,6.2]",
	}

	if th and th.get_styles then
		table.insert(fs, th.get_styles())
	else
		table.insert(fs, "style_type[field,pwdfield;border=false;textcolor=#ffffff]")
	end

	if th and th.label then
		table.insert(fs, th.label(0.5, 0.65, fgettext("DIRECT CONNECT TO SERVER"), "title", c.text_primary, "bold"))
		table.insert(fs, th.label(0.5, 1.05, fgettext("Enter a server address or IP and port to join directly"), "body", c.text_muted, "normal"))
	else
		table.insert(fs, "style_type[label;font=bold;textcolor=" .. c.text_primary .. "]")
		table.insert(fs, string.format("label[0.5,0.65;%s]", core.formspec_escape(fgettext("DIRECT CONNECT TO SERVER"))))
		table.insert(fs, "style_type[label;font=normal;textcolor=" .. c.text_muted .. "]")
		table.insert(fs, string.format("label[0.5,1.05;%s]", core.formspec_escape(fgettext("Enter a server address or IP and port to join directly"))))
	end

	local focused_f = dialogdata.focused_field or ((not dialogdata.address or dialogdata.address == "") and "dc_address" or "dc_pwd")
	table.insert(fs, th.text_input(0.5, 1.85, 5.5, 0.75, "dc_address", fgettext("Server Address / Host"), dialogdata.address or "", focused_f == "dc_address"))
	table.insert(fs, th.text_input(6.2, 1.85, 2.3, 0.75, "dc_port", fgettext("Port"), tostring(dialogdata.port or "30000"), focused_f == "dc_port"))
	table.insert(fs, th.text_input(0.5, 3.15, 3.8, 0.75, "dc_name", fgettext("Player Name"), dialogdata.name or "", focused_f == "dc_name"))
	table.insert(fs, th.password_input(4.7, 3.15, 3.8, 0.75, "dc_pwd", fgettext("Password"), focused_f == "dc_pwd"))

	table.insert(fs, th.toggle_switch(0.5, 4.25, 8.0, 0.42, "dc_add_fav",
		fgettext("Add to Favorites"),
		dialogdata.add_fav ~= false,
		fgettext("Save this server to your favorites list for quick access")
	))

	if dialogdata.error then
		table.insert(fs, string.format("box[0.5,4.75;8.0,0.45;%s]", c.btn_danger_bg))
		table.insert(fs, string.format("label[0.7,4.98;%s]", core.formspec_escape(dialogdata.error)))
	end

	local btn_font = (th and th.font_size and th.font_size("button")) or "font_size=+1"
	local btn_y = dialogdata.error and 5.35 or 5.0
	if th and th.dialog_actions then
		table.insert(fs, th.dialog_actions(0.5, btn_y, 8.0, 0.85, "dc_cancel", fgettext("Cancel"), "dc_connect", fgettext("CONNECT"), false, btn_font))
	else
		table.insert(fs, string.format("button[0.5,%f;3.8,0.85;dc_cancel;%s]", btn_y, core.formspec_escape(fgettext("Cancel"))))
		table.insert(fs, string.format("button[4.7,%f;3.8,0.85;dc_connect;%s]", btn_y, core.formspec_escape(fgettext("CONNECT"))))
	end

	return table.concat(fs, "")
end

local function direct_connect_buttonhandler(this, fields)
	for k in pairs(fields) do
		if k:sub(1, 10) == "btn_focus_" then
			this.data.focused_field = k:sub(11)
			return true
		end
	end
	if fields.key_enter_field then
		this.data.focused_field = fields.key_enter_field
	end
	if fields.dc_address ~= nil and fields.dc_address ~= (this.data.address or "") then
		this.data.focused_field = "dc_address"
	elseif fields.dc_port ~= nil and fields.dc_port ~= (this.data.port or "") then
		this.data.focused_field = "dc_port"
	elseif fields.dc_name ~= nil and fields.dc_name ~= (this.data.name or "") then
		this.data.focused_field = "dc_name"
	elseif fields.dc_pwd ~= nil and fields.dc_pwd ~= (this.data.pwd or "") then
		this.data.focused_field = "dc_pwd"
	end
	if fields.dc_address then
		local s = mainmenu and mainmenu.sanitize_input and mainmenu.sanitize_input(fields.dc_address, 128) or (fields.dc_address.trim and fields.dc_address:trim() or fields.dc_address:match("^%s*(.-)%s*$") or "")
		this.data.address = s
	end
	if fields.dc_port then
		local s = mainmenu and mainmenu.sanitize_input and mainmenu.sanitize_input(fields.dc_port, 10) or (fields.dc_port.trim and fields.dc_port:trim() or fields.dc_port:match("^%s*(.-)%s*$") or "")
		this.data.port = s
	end
	if fields.dc_name then
		local s = mainmenu and mainmenu.sanitize_player_name and mainmenu.sanitize_player_name(fields.dc_name) or (fields.dc_name.trim and fields.dc_name:trim() or fields.dc_name:match("^%s*(.-)%s*$") or "")
		this.data.name = s
	end
	if fields.dc_add_fav ~= nil then
		if fields.dc_add_fav == "" or fields.dc_add_fav == "toggle" then
			this.data.add_fav = (this.data.add_fav == false)
		else
			this.data.add_fav = core.is_yes(fields.dc_add_fav)
		end
		return true
	end
	this.data.error = nil

	if fields.dc_cancel then
		this:delete()
		if this.parent then
			this.parent:show()
		end
		return true
	end

	if fields.dc_connect or fields.key_enter then
		local addr = this.data.address or ""
		if addr == "" then
			this.data.error = fgettext("Please enter a valid server address")
			return true
		end

		local port = tonumber(this.data.port) or 30000
		if port < 1 or port > 65535 then
			this.data.error = fgettext("Port must be between 1 and 65535")
			return true
		end

		local player_name = this.data.name or ""
		if player_name == "" then
			player_name = core.settings:get("name") or "Player"
		end

		local s_name = addr
		if addr == "127.0.0.1" or addr:lower() == "localhost" or addr == "::1" then
			s_name = "Localhost Server"
		end

		core.settings:set("address", addr)
		core.settings:set("remote_port", tostring(port))
		core.settings:set("name", player_name)
		core.settings:set("mainmenu_last_session_type", "server")
		core.settings:set("mainmenu_last_server_name", s_name)
		core.settings:set("mainmenu_last_server_address", addr)
		core.settings:set("mainmenu_last_server_port", tostring(port))
		core.settings:set("mainmenu_session_tab", "online")
		core.settings:write()

		if this.data.add_fav and serverlistmgr and serverlistmgr.add_favorite then
			serverlistmgr.add_favorite({
				address = addr,
				port = port,
				name = s_name
			})
		end

		gamedata.mode = "join"
		gamedata.address = addr
		gamedata.port = port
		gamedata.playername = player_name
		gamedata.password = fields.dc_pwd or ""
		gamedata.selected_world = 0

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

function create_direct_connect_dialog(address, port, name, pwd, add_fav)
	local current_addr = address or core.settings:get("address") or ""
	local current_port = port or core.settings:get("remote_port") or "30000"
	local player_name = name or core.settings:get("name") or ""

	local dlg = dialog_create("dlg_direct_connect",
		direct_connect_formspec,
		direct_connect_buttonhandler,
		event_handler)

	dlg.data = {
		address = current_addr,
		port = current_port,
		name = player_name,
		pwd = pwd or "",
		add_fav = (add_fav ~= nil) and add_fav or true,
		error = nil,
	}

	return dlg
end
