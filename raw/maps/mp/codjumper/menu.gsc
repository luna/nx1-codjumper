#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\codjumper\functions;
#include maps\mp\codjumper\utils;

VERSION = "v0.15.0";

SCREEN_MAX_WIDTH = 640;
SCREEN_MAX_HEIGHT = 480;
MENU_SCROLL_TIME_SECONDS = 0.25;

SELECTED_PREFIX = "^2-->^7 ";

init()
{
	level._callbackPlayerDamage = ::blank;

	level.MAPS = get_maps();
	level.DVARS = get_dvars();
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

	self.usingSlider = false;

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
	self setClientDvar("cg_drawFPS", 0);
}

watch_buttons()
{
	self endon("end_respawn");
	self endon("disconnect");

	level endon("game_ended");

	self register_command("+melee");
	self register_command("+frag");
	self register_command("+smoke");
	self register_command("+usereload");
	self register_command("+actionslot 1");
	self register_command("+attack");
	self register_command("+speed_throw");

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

		while(self.usingSlider)
			wait .125;
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
	opt.inputs[1] = param2;
	opt.inputs[2] = param3;

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

slider_start(dvar)
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!is_dvar_struct_valid(dvar) || dvar.type != "slider")
	{
		self iPrintln("^1dvar struct is invalid");
		return;
	}

	if(!isDefined(self.cj["slider_hud"]))
		self.cj["slider_hud"] = [];
	else
		self slider_hud_destroy();

	backgroundWidth = SCREEN_MAX_WIDTH;
	backgroundHeight = 50;
	centerYPosition = (SCREEN_MAX_HEIGHT - backgroundHeight) / 2;

	self.cj["slider_hud"]["background"] = self shader("white", 0, centerYPosition, backgroundWidth, backgroundHeight, (0,0,0), 0.5, 4, "TOP LEFT", "fullscreen");

	railWidth = int(SCREEN_MAX_WIDTH * 0.75);
	railHeight = 4;
	centerXPosition = (SCREEN_MAX_WIDTH - railWidth) / 2;
	centerYPosition = (SCREEN_MAX_HEIGHT - railHeight) / 2;

	self.cj["slider_hud"]["rail"] = self shader("white", centerXPosition, centerYPosition, railWidth, railHeight, undefined, 0.75, 5, "TOP LEFT", "fullscreen");

	cursorWidth = 3;
	cursorHeight = int(backgroundHeight / 2);
	cursorStartXPosition = centerXPosition;
	cursorYPosition = centerYPosition - (cursorHeight - railHeight) / 2;

	self.cj["slider_hud"]["cursor"] = self shader("white", cursorStartXPosition, cursorYPosition, cursorWidth, cursorHeight, self.themeColor, 1, 6, "TOP LEFT", "fullscreen");

	dvarValue = self get_saved_client_dvar(dvar.name, dvar.default_value);

	update_cursor_position(dvar, dvarValue, self.cj["slider_hud"]["cursor"], centerXPosition, railWidth, cursorWidth);

	self.cj["slider_hud"]["cursor"].alpha = 1;

	self.cj["slider_hud"]["value"] = self text("", 0, -50, "default", 3, 1, 4, "CENTER", "CENTER");
	self.cj["slider_hud"]["value"] SetValue(dvarValue);

	instructions = [];
	instructions[instructions.size] = "[{+smoke}] Decrease";
	instructions[instructions.size] = "[{+frag}] Increase";
	instructions[instructions.size] = "[{+melee}] Save and exit";

	instructionsString = "";
	foreach(instruction in instructions)
		instructionsString += instruction + "\n";

	self.cj["slider_hud"]["instructions"] = createFontString("default", 1.4);
	self.cj["slider_hud"]["instructions"] setPoint("TOPLEFT", "TOPLEFT", -30, -20);
	self.cj["slider_hud"]["instructions"] setText(instructionsString);

	self.usingSlider = true;

	for(;;)
	{
		if(self fragButtonPressed() || self secondaryOffhandButtonPressed())
		{
			if (self fragbuttonpressed())
			{
				dvarValue += dvar.step;
				if (dvarValue > dvar.max)
					dvarValue = dvar.min; // Wrap around to min
			}
			else if (self secondaryoffhandbuttonpressed())
			{
				dvarValue -= dvar.step;
				if (dvarValue < dvar.min)
					dvarValue = dvar.max; // Wrap around to max
			}

			update_cursor_position(dvar, dvarValue, self.cj["slider_hud"]["cursor"], centerXPosition, railWidth, cursorWidth);
			self.cj["slider_hud"]["value"] SetValue(dvarValue);
			self set_saved_client_dvar(dvar.name, dvarValue);

			wait .05;
		}
		else if(self meleeButtonPressed())
		{
			self set_saved_client_dvar(dvar.name, dvarValue);
			self slider_hud_destroy();

			self.usingSlider = false;
			return;
		}

		wait .05;
	}
}

update_cursor_position(dvar, dvarValue, sliderCursor, centerXPosition, railWidth, cursorWidth)
{
	normalizedPosition = (dvarValue - dvar.min) / (dvar.max - dvar.min);
	sliderCursor.x = centerXPosition + int(normalizedPosition * (railWidth - cursorWidth));
}

slider_hud_destroy()
{
	if (!isDefined(self.cj["slider_hud"]))
		return;

	keys = getArrayKeys(self.cj["slider_hud"]);
	for (i = 0; i < keys.size; i++)
	{
		if (isDefined(self.cj["slider_hud"][keys[i]]))
			self.cj["slider_hud"][keys[i]] destroy();
	}
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
	self add_menu("main");

	self add_menu_option("main", "DVAR menu", ::menu_action, "CHANGE_MENU", "dvar_menu");
	self add_menu("dvar_menu", "main");
	self add_menu_option("dvar_menu", "^1Reset All^7", ::reset_all_client_dvars);

	dvars = getArrayKeys(level.DVARS);
	for(i = 0;i < level.DVARS.size;i++)
	{
		dvar = level.DVARS[dvars[i]];

		if(!self isHost() && isDefined(dvar.scope) && dvar.scope == "global")
			continue;

		if (dvar.type == "slider")
			self add_menu_option("dvar_menu", dvar.name, ::slider_start, dvar);
		else if (dvar.type == "boolean")
			self add_menu_option("dvar_menu", dvar.name, ::toggle_boolean_dvar, dvar);
	}


	if(self isHost())
	{
		if(getDvarInt("ui_allow_teamchange") == 1)
		{
			self add_menu_option("main", "Select Map", ::menu_action, "CHANGE_MENU", "host_menu_maps");
			self add_menu("host_menu_maps", "main");

			maps = getArrayKeys(level.MAPS);
			for (i = 0; i < maps.size; i++)
			{
				mapname = maps[i];
				label = level.MAPS[mapname];
				self add_menu_option("host_menu_maps", label, ::change_map, mapname);
			}
		}
	}
}