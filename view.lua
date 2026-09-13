-- Luanti Main Menu Redesign
-- Formspec Version 7 Master View Generator

local view = {}

local sidebar_comp      = dofile(custom_menupath .. DIR_DELIM .. "components" .. DIR_DELIM .. "sidebar.lua")
local view_games_comp   = dofile(custom_menupath .. DIR_DELIM .. "components" .. DIR_DELIM .. "view_games.lua")
local view_local_comp   = dofile(custom_menupath .. DIR_DELIM .. "components" .. DIR_DELIM .. "view_local.lua")
local view_online_comp  = dofile(custom_menupath .. DIR_DELIM .. "components" .. DIR_DELIM .. "view_online.lua")
local view_content_comp = dofile(custom_menupath .. DIR_DELIM .. "components" .. DIR_DELIM .. "view_content.lua")
local view_about_comp   = dofile(custom_menupath .. DIR_DELIM .. "components" .. DIR_DELIM .. "view_about.lua")

function view.render(st, th)
	local fs = {}

	-- Modern Formspec 7 Header & Relative Centered Anchoring
	table.insert(fs, "formspec_version[7]")
	table.insert(fs, "size[21.6,12.0,false]")
	table.insert(fs, "position[0.5,0.5]")
	table.insert(fs, "anchor[0.5,0.5]")
	table.insert(fs, "no_prepend[]")
	table.insert(fs, string.format("bgcolor[%s;neither]", th.colors.backdrop))

	-- Sanitize and validate active keyboard focus for current tab
	local tab = st.active_tab or "games"
	local cur_f = st.focused_field
	if cur_f and cur_f ~= "" then
		local is_search = (cur_f == "te_world_search" or cur_f == "te_server_search" or cur_f == "te_content_search")
		if is_search then
			local target_search = nil
			if tab == "local" then
				target_search = "te_world_search"
			elseif tab == "online" then
				target_search = "te_server_search"
			elseif tab == "content" then
				target_search = "te_content_search"
			end
			if cur_f ~= target_search then
				st.focused_field = target_search
				if st.set then
					st.set("focused_field", target_search)
				end
			end
		else
			local valid = false
			if tab == "local" and st.is_hosting and (cur_f == "te_playername" or cur_f == "te_passwd") then
				valid = true
			elseif tab == "online" and (cur_f == "te_name" or cur_f == "te_pwd" or cur_f == "te_server_mod_search") then
				valid = true
			end
			if not valid then
				st.focused_field = nil
				if st.set then
					st.set("focused_field", nil)
				end
			end
		end
	end

	-- Set initial / active keyboard focus before any elements are parsed
	local active_focus = st.focused_field
	if not active_focus then
		if tab == "online" then
			active_focus = (st.player_name and st.player_name ~= "") and "te_pwd" or "te_name"
		elseif tab == "local" and st.is_hosting then
			active_focus = (st.player_name and st.player_name ~= "") and "te_passwd" or "te_playername"
		end
	end
	if active_focus and active_focus ~= "" then
		table.insert(fs, string.format("set_focus[%s;true]", active_focus))
	end

	-- Global theme styling rules
	table.insert(fs, th.get_styles())

	-- Main Window Outer Voxel Frame & Translucent Backdrop
	table.insert(fs, string.format("box[0,0;21.6,12.0;%s]", th.colors.backdrop_overlay))

	-- Render Left Sidebar
	table.insert(fs, sidebar_comp.render(st, th))

	-- Render Active Content Tab
	tab = st.active_tab or "games"
	if tab == "games" then
		table.insert(fs, view_games_comp.render(st, th))
	elseif tab == "local" then
		table.insert(fs, view_local_comp.render(st, th))
	elseif tab == "online" then
		table.insert(fs, view_online_comp.render(st, th))
	elseif tab == "content" then
		table.insert(fs, view_content_comp.render(st, th))
	elseif tab == "about" then
		table.insert(fs, view_about_comp.render(st, th))
	else
		table.insert(fs, view_games_comp.render(st, th))
	end

	return table.concat(fs, "")
end

function view.invalidate_content()
	if view_content_comp.invalidate then
		view_content_comp.invalidate()
	end
end

function view.clear_local_cache(world_path)
	if view_local_comp.clear_cache then
		view_local_comp.clear_cache(world_path)
	end
end
view.view_local = view_local_comp

return view
