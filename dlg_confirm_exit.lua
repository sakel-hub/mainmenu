-- Luanti
-- Copyright (C) 2025 siliconsniffer
-- SPDX-License-Identifier: LGPL-2.1-or-later


local function exit_dialog_formspec()
	local show_dialog = core.settings:get_bool("enable_esc_dialog", true)
	local th = (mainmenu and mainmenu.theme) or (custom_menupath and dofile(custom_menupath .. DIR_DELIM .. "theme.lua"))
	local c = th and th.colors or {
		btn_secondary_bg = "#1e3852aa",
		btn_secondary_hover = "#2d557caa",
		btn_secondary_pressed = "#162c42cc",
		btn_secondary_focus = "#38bdf8",
		btn_danger_bg = "#dc2626",
		btn_danger_hover = "#ef4444",
		btn_danger_pressed = "#991b1b",
		btn_danger_focus = "#f87171",
		btn_danger_text = "#ffffff",
		btn_danger_pressed_text = "#fca5a5",
		text_muted = "#cbd5e1",
		text_primary = "#ffffff",
	}
	local formspec = {
		"formspec_version[7]" ..
		"size[10,3.6]" ..
		"style_type[label;font=bold]" ..
		string.format("style[btn_quit_confirm_cancel;border=true;bgcolor=#334155;textcolor=#f1f5f9;font=bold;font_size=+1]") ..
		string.format("style[btn_quit_confirm_cancel:hovered;border=true;bgcolor=#475569;textcolor=#ffffff;font=bold;font_size=+1]") ..
		string.format("style[btn_quit_confirm_cancel:focused;border=true;bordercolor=%s;bgcolor=#334155;textcolor=#ffffff;font=bold;font_size=+1]",
			c.btn_secondary_focus) ..
		string.format("style[btn_quit_confirm_cancel:focused+hovered;border=true;bordercolor=%s;bgcolor=#475569;textcolor=#ffffff;font=bold;font_size=+1]",
			c.btn_secondary_focus) ..
		string.format("style[btn_quit_confirm_cancel:pressed;border=true;bgcolor=#1e293b;textcolor=#cbd5e1;font=bold;font_size=+1]") ..
		string.format("style[btn_quit_confirm_yes;border=true;bgcolor=%s;textcolor=#ffffff;font=bold;font_size=+1]",
			c.btn_danger_bg) ..
		string.format("style[btn_quit_confirm_yes:hovered;border=true;bgcolor=%s;textcolor=#ffffff;font=bold;font_size=+1]",
			c.btn_danger_hover) ..
		string.format("style[btn_quit_confirm_yes:focused;border=true;bordercolor=%s;bgcolor=%s;textcolor=#ffffff;font=bold;font_size=+1]",
			c.btn_danger_focus, c.btn_danger_bg) ..
		string.format("style[btn_quit_confirm_yes:focused+hovered;border=true;bordercolor=%s;bgcolor=%s;textcolor=#ffffff;font=bold;font_size=+1]",
			c.btn_danger_focus, c.btn_danger_hover) ..
		string.format("style[btn_quit_confirm_yes:pressed;border=true;bgcolor=%s;textcolor=%s;font=bold;font_size=+1]",
			c.btn_danger_pressed, c.btn_danger_pressed_text) ..
		"label[0.5,0.5;" .. fgettext("Are you sure you want to quit?") .. "]" ..
		(th and th.toggle_switch and th.toggle_switch(0.5, 1.35, 9.0, 0.42, "cb_show_dialog", fgettext("Always show this dialog."), show_dialog) or
		("checkbox[0.5,1.4;cb_show_dialog;" .. fgettext("Always show this dialog.") .. ";" .. tostring(show_dialog) .. "]")) ..
		"button[0.5,2.3;3,0.8;btn_quit_confirm_cancel;" .. fgettext("Cancel") .. "]" ..
		"button[6.5,2.3;3,0.8;btn_quit_confirm_yes;" .. fgettext("Quit") .. "]" ..
		"set_focus[btn_quit_confirm_yes]"
	}
	return table.concat(formspec, "")
end


local function exit_dialog_buttonhandler(this, fields)
	if fields.cb_show_dialog ~= nil then
		local cur = core.settings:get_bool("enable_esc_dialog", true)
		local val
		if fields.cb_show_dialog == "" or fields.cb_show_dialog == "toggle" then
			val = not cur
		else
			val = core.is_yes(fields.cb_show_dialog)
		end
		core.settings:set_bool("enable_esc_dialog", val)
		return true
	elseif fields.btn_quit_confirm_yes then
		if core.settings then
			core.settings:set("maintab_LAST", "games")
			core.settings:set("mainmenu_session_tab", "")
			if core.settings.write then
				core.settings:write()
			end
		end
		this:delete()
		core.close()
		return true
	elseif fields.btn_quit_confirm_cancel then
		this:delete()
		if mainmenu and mainmenu.sync_game_theme then
			mainmenu.sync_game_theme(true)
		end
		return true
	end
end


local function event_handler(event)
	if event == "DialogShow" then
		mm_game_theme.set_engine(true) -- hide the menu header
		return true
	elseif event == "DialogHide" then
		if mainmenu and mainmenu.sync_game_theme then
			mainmenu.sync_game_theme(true)
		end
		return true
	end
	return false
end


function create_exit_dialog()
	local retval = dialog_create("dlg_exit",
		exit_dialog_formspec,
		exit_dialog_buttonhandler,
		event_handler)
	return retval
end
