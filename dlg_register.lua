-- Luanti
-- Copyright (C) 2022 rubenwardy
-- SPDX-License-Identifier: LGPL-2.1-or-later

--------------------------------------------------------------------------------

local function register_formspec(dialogdata)
	dialogdata = dialogdata or {}
	local th = (mainmenu and mainmenu.theme) or rawget(_G, "theme") or (custom_menupath and dofile(custom_menupath .. DIR_DELIM .. "theme.lua"))
	local c = (th and th.colors) or {}
	-- TRANSLATORS: Message when joining a server
	local title = fgettext("Joining $1", dialogdata.server and dialogdata.server.name or dialogdata.address)
	local buttons_y = 4 + 1.3
	if dialogdata.error then
		buttons_y = buttons_y + 0.8
	end

	local btn_font = (th and th.font_size and th.font_size("button")) or "font_size=+1"

	local retval = {
		"formspec_version[7]",
		"size[8,", tostring(buttons_y + 1.175), "]",
	}

	if th and th.get_styles then
		table.insert(retval, th.get_styles())
	else
		table.insert(retval, "style_type[field,pwdfield;border=false;textcolor=#ffffff]")
	end

	if th and th.label then
		table.insert(retval, th.label(0.375, 0.8, title, "title", c.text_secondary or "#f1f5f9", "bold"))
	else
		table.insert_all(retval, {
			"style_type[label;font=bold;textcolor=" .. (c.text_secondary or "#f1f5f9") .. "]",
			"label[0.375,0.8;", title, "]",
		})
	end

	local focused_f = dialogdata.focused_field or (dialogdata.name ~= "" and "password" or "name")
	if th and th.text_input and th.password_input then
		table.insert(retval, th.text_input(0.375, 1.575, 7.25, 0.8, "name", fgettext("Name"), dialogdata.name or "", focused_f == "name"))
		table.insert(retval, th.password_input(0.375, 2.875, 7.25, 0.8, "password", fgettext("Password"), focused_f == "password"))
		table.insert(retval, th.password_input(0.375, 4.175, 7.25, 0.8, "password_2", fgettext("Confirm Password"), focused_f == "password_2"))
	else
		if th and th.input_box then
			table.insert(retval, th.input_box(0.375, 1.575, 7.25, 0.8, focused_f == "name"))
			table.insert(retval, th.input_box(0.375, 2.875, 7.25, 0.8, focused_f == "password"))
			table.insert(retval, th.input_box(0.375, 4.175, 7.25, 0.8, focused_f == "password_2"))
		end

		local pad_x = 0.15
		table.insert_all(retval, {
			string.format("field[%f,1.575;%f,0.8;name;%s;%s]",
				0.375 + pad_x, 7.25 - 2 * pad_x,
				core.formspec_escape(fgettext("Name")),
				core.formspec_escape(dialogdata.name or "")),
			string.format("field[%f,2.875;%f,0.8;password;%s;]",
				0.375 + pad_x, 7.25 - 2 * pad_x,
				core.formspec_escape(fgettext("Password"))),
			string.format("field[%f,4.175;%f,0.8;password_2;%s;]",
				0.375 + pad_x, 7.25 - 2 * pad_x,
				core.formspec_escape(fgettext("Confirm Password"))),
		})

		if th and th.focus_overlay then
			table.insert(retval, th.focus_overlay(0.375, 1.575, 7.25, 0.8, "name", focused_f == "name"))
			table.insert(retval, th.focus_overlay(0.375, 2.875, 7.25, 0.8, "password", focused_f == "password"))
			table.insert(retval, th.focus_overlay(0.375, 4.175, 7.25, 0.8, "password_2", focused_f == "password_2"))
		end

		table.insert_all(retval, {
			"field_enter_after_edit[name;true]",
			"field_enter_after_edit[password;true]",
			"field_enter_after_edit[password_2;true]"
		})
	end

	if dialogdata.error then
		table.insert_all(retval, {
			"box[0.375,", tostring(buttons_y - 0.9), ";7.25,0.6;", (c.btn_danger_bg or "#dc2626"), "]",
			"style_type[label;font=bold;textcolor=", (c.text_primary or "#ffffff"), "]",
			"label[0.625,", tostring(buttons_y - 0.6), ";", core.formspec_escape(dialogdata.error), "]",
		})
	end

	if th and th.button_primary and th.button_secondary then
		table.insert(retval, th.button_primary(0.375, buttons_y, 2.5, 0.8, "dlg_register_confirm", fgettext("Register"), nil, true, btn_font))
		table.insert(retval, th.button_secondary(5.125, buttons_y, 2.5, 0.8, "dlg_register_cancel", fgettext("Cancel"), nil, true, btn_font))
	else
		table.insert_all(retval, {
			"container[0.375,", tostring(buttons_y), "]",
			"button[0,0;2.5,0.8;dlg_register_confirm;", fgettext("Register"), "]",
			"button[4.75,0;2.5,0.8;dlg_register_cancel;", fgettext("Cancel"), "]",
			"container_end[]",
		})
	end

	return table.concat(retval, "")
end

--------------------------------------------------------------------------------
local function register_buttonhandler(this, fields)
	for k in pairs(fields) do
		if k:sub(1, 10) == "btn_focus_" then
			this.data.focused_field = k:sub(11)
			return true
		end
	end
	if fields.key_enter_field then
		if fields.key_enter_field == "name" then
			this.data.focused_field = "password"
		elseif fields.key_enter_field == "password" then
			this.data.focused_field = "password_2"
		else
			this.data.focused_field = fields.key_enter_field
		end
	end
	if fields.name ~= nil and fields.name ~= (this.data.name or "") then
		this.data.focused_field = "name"
	elseif fields.password ~= nil and fields.password ~= (this.data.password or "") then
		this.data.focused_field = "password"
	elseif fields.password_2 ~= nil and fields.password_2 ~= (this.data.password_2 or "") then
		this.data.focused_field = "password_2"
	end
	this.data.name = fields.name
	this.data.password = fields.password
	this.data.password_2 = fields.password_2
	this.data.error = nil

	if fields.dlg_register_confirm or fields.key_enter then
		if fields.name == "" then
			this.data.error = fgettext("Missing name")
			return true
		end
		if fields.password ~= fields.password_2 then
			this.data.error = fgettext("Passwords do not match")
			return true
		end

		gamedata.mode       = "join"
		gamedata.playername = fields.name
		gamedata.password   = fields.password
		gamedata.address    = this.data.address
		gamedata.port       = this.data.port
		gamedata.allow_login_or_register = "register"
		gamedata.selected_world = 0

		assert(gamedata.address and gamedata.port)

		local server = this.data.server
		if server then
			serverlistmgr.add_favorite(server)
		else
			serverlistmgr.add_favorite({
				address = gamedata.address,
				port = gamedata.port,
			})
		end

		core.settings:set("name", fields.name)
		core.settings:set("address",     gamedata.address)
		core.settings:set("remote_port", gamedata.port)
		core.settings:set("mainmenu_session_tab", "online")
		core.settings:write()

		core.start()
	end

	if fields["dlg_register_cancel"] then
		this:delete()
		return true
	end

	return false
end

--------------------------------------------------------------------------------
function create_register_dialog(address, port, server)
	assert(address)
	assert(type(port) == "number")

	local retval = dialog_create("dlg_register",
			register_formspec,
			register_buttonhandler,
			nil)
	retval.data.address = address
	retval.data.port = port
	retval.data.server = server
	retval.data.name = core.settings:get("name") or ""
	return retval
end
