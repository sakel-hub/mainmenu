-- Luanti Main Menu Redesign
-- About & Credits View Component (Formspec Version 7)

local view_about = {}

local function prepare_credits(dest, source)
	if not source or type(source) ~= "table" then return end
	local str = table.concat(source, "\n") .. "\n"
	str = core.hypertext_escape(str)
	str = str:gsub("%[.-%]", "<gray>%1</gray>")
	table.insert(dest, str)
end

local cached_credits = nil

local function get_credits()
	if cached_credits then
		return cached_credits
	end
	local credits_file = (custom_menupath or core.get_mainmenu_path()) .. "/credits.json"
	local f = io.open(credits_file, "r")
	if not f then return nil end
	local content = f:read("*all")
	f:close()
	if not content then return nil end
	cached_credits = core.parse_json(content)
	return cached_credits
end

local function get_renderer_info()
	local ret = {}
	local s1 = core.get_active_renderer()
	if s1:sub(1, 7) == "OpenGL " then
		s1 = s1:sub(8)
	end
	local m = s1:match("^[%d.]+") or s1:match("^ES [%d.]+")
	ret[#ret+1] = m or s1
	ret[#ret+1] = core.get_active_driver():lower()
	ret[#ret+1] = core.get_active_irrlicht_device():upper()
	return table.concat(ret, " / ")
end

local function append_items(dest, src)
	for _, item in ipairs(src) do
		dest[#dest + 1] = item
	end
end

function view_about.render(_st, th)
	local fs = {}
	table.insert(fs, "container[3.3,0]")

	-- Main content background (Width: 18.3, Height: 12.0)
	table.insert(fs, string.format("box[0,0;18.3,12.0;%s]", th.colors.backdrop))

	local logofile = defaulttexturedir .. "logo.png"
	local version = core.get_version()

	----------------------------------------------------------------------------
	-- Left Panel: Project Info & Hardware (Width: 7.2, Height: 11.3)
	----------------------------------------------------------------------------
	table.insert(fs, th.voxel_box(0.35, 0.35, 7.2, 11.3, th.colors.card_bg))

	-- Logo & Title: 1:1 Square aspect ratio matching 256x256 texture (Centered in 7.2 width)
	table.insert(fs, string.format("image[2.95,0.60;2.0,2.0;%s]", core.formspec_escape(logofile)))
	table.insert(fs, string.format("style_type[label;font=bold;halign=center;valign=center;%s;textcolor=%s]", th.font_size("display"), th.colors.brand_green_hover))
	table.insert(fs, "label[0.35,2.75;7.2,0.45;LUANTI]")
	table.insert(fs, string.format("style_type[label;font=normal;halign=center;valign=center;%s;textcolor=%s]", th.font_size("body"), th.colors.text_muted))
	table.insert(fs, string.format("label[0.35,3.20;7.2,0.35;%s %s]", core.formspec_escape(version.project), core.formspec_escape(version.string)))
	table.insert(fs, "style_type[label;halign=left;valign=top]")

	-- Renderer / Driver Info Box
	table.insert(fs, th.voxel_box(0.65, 3.80, 6.6, 2.75, th.colors.card_inner_bg))
	table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_secondary))
	table.insert(fs, string.format("label[0.85,4.05;%s]", core.formspec_escape(fgettext("System Graphics:"))))
	table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("caption"), th.colors.text_muted))
	table.insert(fs, string.format("label[0.85,4.55;%s: %s]", core.formspec_escape(fgettext("Driver")), core.formspec_escape(core.get_active_driver())))
	table.insert(fs, string.format("label[0.85,5.05;%s: %s]", core.formspec_escape(fgettext("Renderer")), core.formspec_escape(get_renderer_info())))
	table.insert(fs, string.format("label[0.85,5.55;%s: %s]", core.formspec_escape(fgettext("Device")), core.formspec_escape(core.get_active_irrlicht_device())))

	-- Community & User Links
	table.insert(fs, th.button_url(0.65, 6.80, 6.6, 0.80, "url_website", "luanti.org", "https://www.luanti.org/", fgettext("Open the official Luanti website")))
	table.insert(fs, th.button_url(0.65, 7.75, 6.6, 0.80, "url_forums", fgettext("Community Forums"), "https://forum.luanti.org/", fgettext("Join discussions, ask questions, and share content")))
	table.insert(fs, th.button_url(0.65, 8.70, 6.6, 0.80, "url_github", fgettext("GitHub & Source"), "https://github.com/luanti-org/luanti", fgettext("View source code, issue tracker, and release history")))
	if PLATFORM == "Android" then
		table.insert(fs, th.button_secondary(0.65, 9.65, 6.6, 0.80, "share_debug", fgettext("Share Debug Log"), fgettext("Export debug.txt log file for troubleshooting")))
	else
		table.insert(fs, th.button_secondary(0.65, 9.65, 6.6, 0.80, "userdata", fgettext("Open User Data Folder"), fgettext("Open worlds, mods, and games folder in file manager")))
	end

	----------------------------------------------------------------------------
	-- Right Panel: Credits & Contributors (Width: 10.2, Height: 11.3)
	----------------------------------------------------------------------------
	table.insert(fs, th.voxel_box(7.8, 0.35, 10.2, 11.3, th.colors.card_bg))
	table.insert(fs, string.format("style_type[label;font=bold;%s;textcolor=%s]", th.font_size("subtitle"), th.colors.brand_green_hover))
	table.insert(fs, string.format("label[8.1,0.65;%s]", core.formspec_escape(fgettext("Contributors & Credits"))))
	table.insert(fs, string.format("style_type[label;font=normal;%s;textcolor=%s]", th.font_size("body"), th.colors.text_muted))

	local credits = get_credits()
	local credits_ht = {
		"<tag name=heading color=" .. th.colors.brand_green_hover .. ">",
		"<tag name=gray color=" .. th.colors.text_muted .. ">",
	}

	if credits then
		if credits.core_developers and #credits.core_developers > 0 then
			append_items(credits_ht, { "<heading>", fgettext_ne("Core Developers"), "</heading>\n" })
			prepare_credits(credits_ht, credits.core_developers)
		end
		if credits.core_team and #credits.core_team > 0 then
			append_items(credits_ht, { "\n<heading>", fgettext_ne("Core Team"), "</heading>\n" })
			prepare_credits(credits_ht, credits.core_team)
		end
		local contribs = credits.contributors or credits.active_contributors
		if contribs and #contribs > 0 then
			append_items(credits_ht, { "\n<heading>", fgettext_ne("Active Contributors"), "</heading>\n" })
			prepare_credits(credits_ht, contribs)
		end
		if credits.previous_core_developers and #credits.previous_core_developers > 0 then
			append_items(credits_ht, { "\n<heading>", fgettext_ne("Previous Core Developers"), "</heading>\n" })
			prepare_credits(credits_ht, credits.previous_core_developers)
		end
		if credits.previous_contributors and #credits.previous_contributors > 0 then
			append_items(credits_ht, { "\n<heading>", fgettext_ne("Previous Contributors"), "</heading>\n" })
			prepare_credits(credits_ht, credits.previous_contributors)
		end
		append_items(credits_ht, {
			"\n<heading>", fgettext_ne("Website & License"), "</heading>\n",
			"<gray>https://www.luanti.org/</gray>\n",
			fgettext_ne("Luanti is Free and Open Source Software (LGPL 2.1+ / Apache 2.0 / CC BY-SA 3.0)"), "\n",
		})
	else
		table.insert(credits_ht, core.hypertext_escape(fgettext("Credits file not found or failed to parse.")))
	end

	table.insert(fs, string.format("hypertext[8.05,1.0;9.7,10.3;credits;%s]", core.formspec_escape(table.concat(credits_ht, ""))))

	table.insert(fs, "container_end[]")
	return table.concat(fs, "")
end

return view_about
