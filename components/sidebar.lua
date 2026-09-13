-- Luanti Main Menu Redesign
-- Left Sidebar Navigation Component (Option B)

local sidebar = {}

function sidebar.render(st, th)
	local fs = {}
	local logofile = defaulttexturedir .. "logo.png"
	local version = core.get_version()
	local active_tab = st.active_tab

	-- Sidebar base background & voxel border
	table.insert(fs, string.format("container[0,0]"))
	table.insert(fs, string.format("box[0,0;3.3,12.0;%s]", th.colors.sidebar_bg))
	table.insert(fs, string.format("box[3.26,0;0.04,12.0;%s]", th.colors.sidebar_border))

	-- Top Brand Section
	table.insert(fs, string.format("image[0.35,0.35;0.75,0.75;%s]", core.formspec_escape(logofile)))
	table.insert(fs, "style_type[label;font=bold;textcolor=" .. th.colors.brand_green_hover .. "]")
	table.insert(fs, "label[1.25,0.7;LUANTI]")
	table.insert(fs, "style_type[label;font=normal;textcolor=" .. th.colors.text_muted .. "]")
	table.insert(fs, string.format("label[0.35,1.25;v%s]", core.formspec_escape(version.string)))
	table.insert(fs, string.format("box[0.25,1.55;2.8,0.02;%s]", th.colors.sidebar_border))

	-- Navigation Menu Items (including Games Chooser)
	local nav_items = {
		{ id = "games",   name = "nav_games",   label = fgettext("Games"),       icon = defaulttexturedir .. "server_flags_creative.png" },
		{ id = "local",   name = "nav_local",   label = fgettext("Local Game"),  icon = defaulttexturedir .. "start_icon.png" },
		{ id = "online",  name = "nav_online",  label = fgettext("Play Online"), icon = defaulttexturedir .. "server_public.png" },
		{ id = "content", name = "nav_content", label = fgettext("ContentDB"),   icon = defaulttexturedir .. "cdb_update.png" },
		{ id = "about",   name = "nav_about",   label = fgettext("About"),       icon = defaulttexturedir .. "settings_info.png" },
	}

	local start_y = 1.95
	local item_h = 0.92
	local gap = 0.18

	local update_count = 0
	if update_detector and update_detector.get_count then
		update_count = update_detector.get_count() or 0
	end

	for i, item in ipairs(nav_items) do
		local y = start_y + (i - 1) * (item_h + gap)
		local is_active = (active_tab == item.id)
		local label = item.label
		if item.id == "content" and update_count > 0 then
			label = string.format("%s [%d]", item.label, update_count)
		end
		table.insert(fs, th.button_tab(0.25, y, 2.8, item_h, item.name, label, is_active, nil, "left", th.font_size("button")))
	end

	-- Bottom Section: Divider, Settings, Quit Game
	table.insert(fs, string.format("box[0.25,9.85;2.8,0.02;%s]", th.colors.sidebar_border))

	table.insert(fs, th.button_secondary(0.25, 10.10, 2.8, 0.80, "open_settings", fgettext("Settings"), fgettext("Configure graphics, audio, keybindings, and engine settings")))

	table.insert(fs, th.button_danger(0.25, 11.00, 2.8, 0.80, "btn_quit_game", fgettext("Quit"), fgettext("Exit Luanti"), false))

	table.insert(fs, "container_end[]")

	return table.concat(fs, "")
end

return sidebar
