std = "lua51"

globals = {
    "core",
    "minetest",
    "DIR_DELIM",
    "INIT",
    "PLATFORM",
    "MAIN_TAB_W",
    "MAIN_TAB_H",
    "TABHEADER_H",
    "GAMEBAR_H",
    "GAMEBAR_OFFSET_DESKTOP",
    "GAMEBAR_OFFSET_TOUCH",
    "defaulttexturedir",
    "custom_menupath",
    "ui",
    "gamedata",
    "menudata",
    "filterlist",
    "compare_worlds",
    "sort_worlds_alphabetic",
    "pkgmgr",
    "mm_game_theme",
    "tabview_create",
    "fgettext",
    "create_exit_dialog",
    "create_settings_dlg",
    "migrate_keybindings",
    "check_reinstall_mtg",
    "check_new_version",
    "current_game",
    "buttonbar_create",
    "dialog_create",
    "mainmenu",
    "fgettext_ne",
    "update_detector",
    "apply_game",
    "create_configure_world_dlg",
    "create_create_world_dlg",
    "create_delete_world_dlg",
    "create_delete_content_dlg",
    "create_contentdb_dlg",
    "create_server_list_mods_dlg",
    "create_server_list_mods_dialog",
    "is_server_protocol_compat",
    "is_server_protocol_compat_or_error",
    "render_serverlist_row",
    "serverlistmgr",
}

read_globals = {
    "table.insert_all",
    "table.copy",
    "table.indexof",
    "table.shuffle",
    "string.split",
    "string.trim",
    "table.unpack",
}

ignore = {
    "111", -- setting non-standard global
    "112", -- mutating non-standard global
    "113", -- accessing undefined variable (for legacy mainmenu cross-file globals)
    "122", -- mutating read-only global
    "631", -- line is too long (formspec markup strings)
}
