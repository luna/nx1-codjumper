#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

blank(){}

registerCommand(cmd)
{
	if(!isDefined(self.buttons))
		self.buttons = [];

	notif = getSubStr(cmd, 1); // remove the + (e.g. +frag/frag)
	assert(!isDefined(self.buttons[notif])); // don't add the same button twice

	self notifyOnPlayerCommand(notif, cmd);

	self.buttons[self.buttons.size] = notif;
}

button_pressed(command)
{
	if(!isDefined(self.buttons) || !isDefined(self.buttons[command]))
		return false;

	return gettime() - self.buttons[command]["time"] <= 50;
}

button_pressed_twice(command)
{
	if(!self button_pressed(command))
		return false;

	pressed = gettime();

	self waittill_notify_or_timeout(command, .5);

	if((gettime() - pressed) >= 500)
		return false;

	return true;
}

waittill_button_press()
{
	if(!isDefined(self.buttons) || self.buttons.size <= 0)
		return;

	ent = spawnstruct();

	foreach(button in self.buttons)
		self thread waittill_string(button, ent);

	ent waittill("returned", msg);
	ent notify("die");

	self.buttons[msg]["time"] = gettime();

	return msg;
}

shader(shader, x, y, width, height, color, alpha, sort, align, relative)
{
	hud = self createIcon(shader, width, height);

	hud.sort = sort;
	hud.alpha = alpha;
	hud.color = color;

	if(!isDefined(relative))
		relative = "CENTER";
	if(!isDefined(align))
		align = "CENTER";

	hud setPoint(align, relative, x, y);

	if(toLower(relative) == "fullscreen")
	{
		hud.horzAlign = "fullscreen";
		hud.vertAlign = "fullscreen";
	}

	return hud;
}

text(string, x, y, font, fontScale, alpha, sort, align, relative)
{
	text = self createFontString(font, fontScale);

	text.alpha = alpha;
	text.sort = sort;

	if(!isDefined(relative))
		relative = "CENTER";
	if(!isDefined(align))
		align = "CENTER";

	text setText(string);
	text setPoint(align, relative, x, y);

	if(toLower(relative) == "fullscreen")
	{
		text.horzAlign = "fullscreen";
		text.vertAlign = "fullscreen";
	}

	return text;
}

rgb(r, g, b)
{
	return (r / 255, g / 255, b / 255);
}

get_themes()
{
	themes = [];

	themes["blue"] = rgb(0, 0, 255);
	themes["brown"] = rgb(139, 69, 19);
	themes["cyan"] = rgb(0, 255, 255);
	themes["gold"] = rgb(255, 215, 0);
	themes["green"] = rgb(0, 208, 98);
	themes["lime"] = rgb(0, 255, 0);
	themes["magenta"] = rgb(255, 0, 255);
	themes["maroon"] = rgb(128, 0, 0);
	themes["olive"] = rgb(128, 128, 0);
	themes["orange"] = rgb(255, 165, 0);
	themes["pink"] = rgb(255, 25, 127);
	themes["purple"] = rgb(90, 0, 208);
	themes["red"] = rgb(255, 0, 0);
	themes["salmon"] = rgb(250, 128, 114);
	themes["silver"] = rgb(192, 192, 192);
	themes["skyblue"] = rgb(0, 191, 255);
	themes["tan"] = rgb(210, 180, 140);
	themes["teal"] = rgb(0, 128, 128);
	themes["turquoise"] = rgb(64, 224, 208);
	themes["violet"] = rgb(238, 130, 238);
	themes["yellow"] = rgb(255, 255, 0);

	return themes;
}

get_maps()
{
	maps = [];

	maps["mp_nx_bom"] = "BOM";
	maps["mp_nx_border"] = "Border";
	maps["mp_nx_leg_crash"] = "Crash";
	maps["mp_nx_deadzone"] = "DeadZone";
	maps["mp_nx_fallout"] = "Fallout";
	maps["mp_nx_galleria"] = "Galleria";
	maps["mp_nx_ugvhh"] = "Hell in Paradise";
	maps["mp_nx_import"] = "Import";
	maps["mp_nx_leg_overgrown"] = "Overgrown";
	maps["mp_nx_pitstop"] = "Pit Stop";
	maps["mp_nx_contact"] = "Contact";
	maps["mp_nx_meteor"] = "Meteor";
	maps["mp_nx_monorail"] = "Monorail";
	maps["mp_nx_lockdown_v2"] = "Lockdown";
	maps["mp_nx_sandstorm"] = "Sandstorm";
	maps["mp_nx_seaport"] = "Seaport";
	maps["mp_nx_skylab"] = "Skylab";
	maps["mp_nx_stasis"] = "Stasis";
	maps["mp_nx_streets"] = "Streets";
	maps["mp_nx_subyard"] = "Subyard";
	maps["mp_nx_leg_term"] = "Terminal";
	maps["mp_nx_whiteout"] = "Whiteout";

	return maps;
}