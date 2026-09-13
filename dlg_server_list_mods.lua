-- Luanti
-- Copyright (C) 2024 cx384
-- SPDX-License-Identifier: LGPL-2.1-or-later

local function get_formspec(dialogdata)
	local TOUCH_GUI = core.settings:get_bool("touch_gui")
	local server = dialogdata.server
	local group_by_prefix = dialogdata.group_by_prefix
	local expand_all = dialogdata.expand_all

	-- A wrongly behaving server may send ill formed mod names
	table.sort(server.mods)

	local cells = {}
	if group_by_prefix then
		local function get_prefix(mod)
			return mod:match("[^_]*")
		end
		local count = {}
		for _, mod in ipairs(server.mods) do
			local prefix = get_prefix(mod)
			count[prefix] = (count[prefix] or 0) + 1
		end
		local last_prefix
		local function add_row(depth, mod)
			table.insert(cells, ("%d"):format(depth))
			table.insert(cells, mod)
		end
		for _, mod in ipairs(server.mods) do
			local prefix = get_prefix(mod)
			if last_prefix == prefix then
				add_row(1, mod)
			elseif count[prefix] > 1 then
				add_row(0, prefix)
				add_row(1, mod)
			else
				add_row(0, mod)
			end
			last_prefix = prefix
		end
	else
		cells = table.copy(server.mods)
	end

	for i, cell in ipairs(cells) do
		cells[i] = core.formspec_escape(cell)
	end
	cells = table.concat(cells, ",")

	local heading
	if server.gameid then
		heading = fgettext("The $1 server uses a game called $2 and the following mods:",
			"<b>" .. core.hypertext_escape(server.name) .. "</b>",
			"<style font=mono>" .. core.hypertext_escape(server.gameid) .. "</style>")
	else
		heading = fgettext("The $1 server uses the following mods:",
				"<b>" .. core.hypertext_escape(server.name) .. "</b>")
	end

	local th = (mainmenu and mainmenu.theme) or (custom_menupath and dofile(custom_menupath .. DIR_DELIM .. "theme.lua"))

	local formspec = {
		"formspec_version[8]",
		"size[8,9.5]",
		TOUCH_GUI and "padding[0.01,0.01]" or "",
		"hypertext[0,0;8,1.5;;<global margin=5 halign=center valign=middle>", heading, "]",
		"tablecolumns[", group_by_prefix and
			(expand_all and "indent;text" or "tree;text") or "text", "]",
		"table[0.5,1.5;7,6.8;mods;", cells, "]",
		-- TRANSLATORS: A toggle; if enabled, it will group mods by their prefix
		(th and th.toggle_switch and th.toggle_switch(0.5, 8.55, 4.8, 0.42, "group_by_prefix", fgettext("Group by prefix"), group_by_prefix) or
			("checkbox[0.5,8.7;group_by_prefix;" .. fgettext("Group by prefix") .. ";" .. (group_by_prefix and "true" or "false") .. "]")),
		-- TRANSLATORS: Expand all entries in a tree view
		group_by_prefix and (th and th.toggle_switch and th.toggle_switch(0.5, 9.05, 4.8, 0.42, "expand_all", fgettext("Expand all"), expand_all) or
			("checkbox[0.5,9.15;expand_all;" .. fgettext("Expand all") .. ";" .. (expand_all and "true" or "false") .. "]")) or "",
		(th and th.button_primary and th.button_primary(5.5, 8.5, 2, 0.8, "quit", "OK", nil, true, "font_size=+1")) or
			"button[5.5,8.5;2,0.8;quit;OK]"
	}
	return table.concat(formspec, "")
end

local function buttonhandler(this, fields)
	if fields.quit then
		this:delete()
		return true
	end

	if fields.group_by_prefix ~= nil then
		if fields.group_by_prefix == "" or fields.group_by_prefix == "toggle" then
			this.data.group_by_prefix = not this.data.group_by_prefix
		else
			this.data.group_by_prefix = core.is_yes(fields.group_by_prefix)
		end
		return true
	end

	if fields.expand_all ~= nil then
		if fields.expand_all == "" or fields.expand_all == "toggle" then
			this.data.expand_all = not this.data.expand_all
		else
			this.data.expand_all = core.is_yes(fields.expand_all)
		end
		return true
	end

	return false
end

function create_server_list_mods_dialog(server)
	local retval = dialog_create("dlg_server_list_mods",
		get_formspec,
		buttonhandler,
		nil)
	retval.data.group_by_prefix = false
	retval.data.expand_all = false
	retval.data.server = server
	return retval
end
