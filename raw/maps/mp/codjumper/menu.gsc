#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\codjumper\functions;
#include maps\mp\codjumper\utils;

VERSION = "v0.15.0";

SCREEN_MAX_WIDTH = 640;
SCREEN_MAX_HEIGHT = 480;
MENU_SCROLL_TIME_SECONDS = .25;

SELECTED_PREFIX = "^2-->^7 ";

init()
{
	level._callbackPlayerDamage = ::blank;

	level.THEMES = get_themes();
	level.TOGGLES = strTok("OFF;ON", ";");

	gametype = level._gametype;
	setDvar("scr_" + gametype + "_scorelimit", 0);
	setDvar("scr_" + gametype + "_timelimit", 0);
	setDvar("scr_" + gametype + "_playerrespawndelay", 0);
	setDvar("scr_" + gametype + "_numlives", 0);
	setDvar("scr_" + gametype + "_roundlimit", 0);

	setDvar("player_sprintUnlimited", 1);
	setDvar("jump_slowdownEnable", 0);

	setDvar("g_TeamName_Allies", "Jumpers");
	setDvar("g_TeamName_Axis", "Bots");

	setDvar("bg_fallDamageMaxHeight", 9999);
	setDvar("bg_fallDamageMinHeight", 9998);

	setDvar("player_spectateSpeedScale", 1.5);

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	level endon("game_ended");

	for(;;)
	{
		level waittill("connecting", player);

		if(isDefined(player.pers["isBot"]))
			continue;

		player setup_player();
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
	self endon("disconnect");
	level endon("game_ended");

	for(;;)
	{
		self waittill("spawned_player");

		self thread replenish_ammo();
		self thread watch_buttons();
		self reset_fov();
	}
}

setup_player()
{
	self.cj = [];
	self.cj["bots"] = [];
	self.cj["botnumber"] = 0;
	self.cj["clones"] = [];
	self.cj["maxbots"] = 4;
	self.cj["savenum"] = 0;
	self.cj["saves"] = [];
	self.cj["settings"] = [];
	self.cj["settings"]["rpg_switch_enabled"] = false;
	self.cj["settings"]["rpg_switched"] = false;

	self.cj["meter_hud"] = [];

	self.cj["menu_open"] = false;

	self.cj["spectator_speed_index"] = 5;
	self.cj["forge_change_mode_index"] = 0;

	self.cj["dvars"] = [];

	// Default loadout
	self.cj["loadout"] = spawnstruct();
	self.cj["loadout"].primary = "ump45_mp";
	self.cj["loadout"].primaryCamoIndex = 0;
	self.cj["loadout"].sidearm = "coltanaconda_mp";
	self.cj["loadout"].fastReload = false;
	self.cj["loadout"].incomingWeapon = undefined;

	self setClientDvars("loc_warnings", 0, "loc_warningsAsErrors", 0, "cg_errordecay", 1, "con_errormessagetime", 0, "uiscript_debug", 0);
	self setClientDvars("cg_overheadRankSize", 0, "cg_overheadIconSize", 0);
	self setClientDvars("fx_enable", 0, "fx_marks", 0, "fx_marks_ents", 0, "fx_marks_smodels", 0);
	self setClientDvar("cg_descriptiveText", 0);
	self setClientDvar("ui_hud_hardcore", 1);
}

watch_buttons()
{
	self endon("end_respawn");
	self endon("disconnect");
	level endon("game_ended");

	self registerCommand("+melee");
	self registerCommand("+frag");
	self registerCommand("+smoke");
	self registerCommand("+usereload");
	self registerCommand("+actionslot 1");
	self registerCommand("+attack");
	self registerCommand("+speed_throw");

	for(;;)
	{
		button = self waittill_button_press();
		menuOpen = self.cj["menu_open"];

		switch(button)
		{
			case "usereload":
				if(!menuOpen && self button_pressed_twice(button))
					self menu_action("OPEN");
				else if(menuOpen)
					self menu_action("SELECT");

				break;
			case "melee":
				if(!menuOpen && self button_pressed_twice("melee"))
					self save_pos(0);
				else if(menuOpen)
					self menu_action("BACK");

				break;
			case "smoke":
				if(self.sessionstate == "playing")
					self load_pos(0);

				break;
			case "frag":
				self toggle_ufo();
				break;
			case "actionslot 1":
				self iPrintln("dpad up pressed!"); // spawn bot here
				break;
			case "speed_throw":
			case "attack":
				direction = strTok("DOWN;UP", ";");
				self menu_action(direction[button == "speed_throw"]);

				break;
		}
	}
}

add_menu(menuKey, parentMenuKey)
{
	if(!isDefined(self.menuOptions))
		self.menuOptions = [];

	menu = spawnstruct();
	menu.parent = parentMenuKey;
	menu.options = [];

	self.menuOptions[menuKey] = menu;
}

add_menu_option(menuKey, label, func, param1, param2, param3)
{
	opt = spawnstruct();
	opt.label = label;
	opt.func = func;

	opt.inputs = [];
	opt.inputs[0] = param1;
	opt.inputs[2] = param2;
	opt.inputs[1] = param3;

	self.menuOptions[menuKey].options[self.menuOptions[menuKey].options.size] = opt;
}

menu_key_exists(menuKey)
{
	return isDefined(self.menuOptions[menuKey]);
}

get_menu_text()
{
	if(!menu_key_exists(self.menuKey))
	{
		self iPrintLn("^1menu key " + self.menuKey + " does not exist");
		return "";
	}

	string = "";
	foreach(option in self.menuOptions[self.menuKey].options)
		string += option.label + "\n";

	if(string.size > 255)
		self iPrintLn("^1menu text exceeds 255 characters. current size: " + string.size);

	return string;
}

init_menu_hud()
{
	menuWidth = int(SCREEN_MAX_WIDTH * .25);
	leftPad = 5;
	menuScrollerAlpha = 0.7;

	self.menuBackground = self shader("white", (SCREEN_MAX_WIDTH - menuWidth), 0, menuWidth, SCREEN_MAX_HEIGHT, (0,0,0), 0.5, 1, "TOP LEFT", "fullscreen");

	leftBorderWidth = 2;
	self.menuBorderLeft = self shader("white", (SCREEN_MAX_WIDTH - menuWidth), 0, leftBorderWidth, SCREEN_MAX_HEIGHT, self.themeColor, 1, 2, "TOP LEFT", "fullscreen");

	self.menuScroller = self shader("white", (SCREEN_MAX_WIDTH - menuWidth), int(SCREEN_MAX_HEIGHT * 0.15), menuWidth, int(level._fontHeight * 1.5), self.themeColor, 1, 2, "TOP LEFT", "fullscreen");

	self.menuTextFontElem = self text(get_menu_text(), (SCREEN_MAX_WIDTH - menuWidth) + leftPad, int(SCREEN_MAX_HEIGHT * 0.15), "default", 1.5, 1, 3, "TOP LEFT", "fullscreen");

	self.menuHeaderFontElem = self text("CodJumper", (SCREEN_MAX_WIDTH - menuWidth) + leftPad, int(SCREEN_MAX_HEIGHT * 0.025), "objective", 2, 1, 2, "TOP LEFT", "fullscreen");
	self.menuHeaderFontElem.glowAlpha = 1;
	self.menuHeaderFontElem.glowColor = self.themeColor;

	self.menuHeaderAuthorFontElem = self text("by mo", (SCREEN_MAX_WIDTH - menuWidth) + leftPad, int(SCREEN_MAX_HEIGHT * 0.075), "default", 1.5, 1, 2, "TOP LEFT", "fullscreen");
	self.menuHeaderAuthorFontElem.glowAlpha = 1;
	self.menuHeaderAuthorFontElem.glowColor = self.themeColor;

	self.menuVersionFontElem = self text(VERSION, (SCREEN_MAX_WIDTH - menuWidth) + leftPad, int(SCREEN_MAX_HEIGHT - (level._fontHeight * 1.4) - leftPad), "default", 1.4, 0.5, 2, "TOP LEFT", "fullscreen");
}

menu_action(action, param1)
{
	if(!isDefined(self.themeColor))
		self.themeColor = level.THEMES["skyblue"];

	if(!isDefined(self.menuKey))
		self.menuKey = "main";

	if(!isDefined(self.menuCursor))
		self.menuCursor = [];

	if(!isDefined(self.menuCursor[self.menuKey]))
		self.menuCursor[self.menuKey] = 0;

	menu = self.menuOptions[self.menuKey];
	cursor = self.menuCursor[self.menuKey];
	switch(action)
	{
		case "UP":
		case "DOWN":
			if(action == "UP")
				cursor--;
			else
				cursor++;

			if(cursor < 0)
				cursor = menu.options.size - 1;
			else if(cursor >= menu.options.size)
				cursor = 0;

			self.menuCursor[self.menuKey] = cursor;

			self.menuScroller moveOverTime(MENU_SCROLL_TIME_SECONDS);
			self.menuScroller.y = (SCREEN_MAX_HEIGHT * 0.15 + ((level._fontHeight * 1.5) * cursor));

			break;
		case "SELECT":
			opt = menu.options[cursor];
			self [[opt.func]](opt.inputs[0], opt.inputs[1], opt.inputs[2]);

			wait .1;

			break;
		case "CLOSE":
			self.menuBackground destroy();
			self.menuBorderLeft destroy();
			self.menuScroller destroy();
			self.menuTextFontElem destroy();
			self.menuHeaderFontElem destroy();
			self.menuHeaderAuthorFontElem destroy();
			self.menuVersionFontElem destroy();

			self.cj["menu_open"] = false;
			self freezeControls(false);

			break;
		case "BACK":
			if(!isDefined(menu.parent))
				self menu_action("CLOSE");
			else
				self menu_action("CHANGE_MENU", menu.parent);

			break;
		case "OPEN":
			self.cj["menu_open"] = true;
			self freezeControls(true);

			self generate_menu_options();
			self init_menu_hud();
			self.menuScroller.y = (SCREEN_MAX_HEIGHT * 0.15 + ((level._fontHeight * 1.5) * cursor));

			break;
		case "CHANGE_THEME":
			self.themeColor = level.THEMES[param1];
			self menu_action("REFRESH");

			break;
		case "CHANGE_MENU":
			self.menuKey = param1;
			self menu_action("REFRESH");

			break;
		case "REFRESH_TEXT":
			if(!menu_key_exists(self.menuKey))
			{
				self iPrintLn("^1menu key " + self.menuKey + " does not exist");
				self.menuKey = "main";
			}

			self.menuTextFontElem setText(get_menu_text());
			self.menuScroller moveOverTime(MENU_SCROLL_TIME_SECONDS);
			self.menuScroller.y = (SCREEN_MAX_HEIGHT * 0.15 + ((level._fontHeight * 1.5) * self.menuCursor[self.menuKey]));

			break;
		case "REFRESH":
			self menu_action("CLOSE");
			self menu_action("OPEN");

			break;
		default:
			self iPrintLn("^1unknown menu action " + action);
			break;
	}
}

generate_menu_options()
{
	isHost = self getEntityNumber() == 0;

	self add_menu("main");
	for(i = 0;i < 15;i++)
		self add_menu_option("main", "Option " + i, ::blank);
}