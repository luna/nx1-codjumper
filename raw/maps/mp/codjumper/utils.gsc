#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

blank(){}

register_command(cmd)
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

	return (gettime() - pressed) < 500;
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

get_saved_client_dvar(dvar, default_value)
{
	value = self.cj["dvars"][dvar];
	if (!isDefined(value))
		return default_value;
	else
		return value;
}

set_saved_client_dvar(dvar, value)
{
	self.cj["dvars"][dvar] = value;

	global = false;
	default_value = undefined;
	if (isDefined(level.DVARS[dvar]))
	{
		dvar_struct = level.DVARS[dvar];
		default_value = dvar_struct.default_value;

		if(isDefined(dvar_struct.scope) && dvar_struct.scope == "global")
		{
			global = true;
			setDvar(dvar, value);
		}
	}
	
	if(!global)
		self setClientDvar(dvar, value);

	msg = dvar + ": " + value;
	if (value == default_value)
		msg += " [DEFAULT]";

	self iPrintln(msg);
}

is_dvar_struct_valid(dvar)
{
	// all require name/type/default value
	if (!isDefined(dvar) || !isDefined(dvar.type) || !isDefined(dvar.name) || !isDefined(dvar.default_value))
		return false;

	if (dvar.type == "slider")
	{
		if (!isDefined(dvar.min) || !isDefined(dvar.max) || !isDefined(dvar.step))
			return false;
	}

	return true;
}

toggle_boolean_dvar(dvar)
{
	if (!is_dvar_struct_valid(dvar) || dvar.type != "boolean")
	{
		self iPrintln("^1dvar struct is invalid");
		return;
	}

	dvarValue = self get_saved_client_dvar(dvar.name, dvar.default_value);

	if (dvarValue == 0)
		self set_saved_client_dvar(dvar.name, 1);
	else
		self set_saved_client_dvar(dvar.name, 0);
}

reset_all_client_dvars()
{
	foreach(dvar in level.DVARS)
	{
		if(!isDefined(dvar.scope))
			self set_saved_client_dvar(dvar.name, dvar.default_value);
	}
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

get_dvars()
{
	dvars = [];

	dvars["bg_viewBobMax"] = add_dvar("bg_viewBobMax", "slider", 8, 0, 36, 1);
	dvars["cg_drawGun"] = add_dvar("cg_drawGun", "boolean", 1);
	dvars["cg_drawSpectatorMessages"] = add_dvar("cg_drawSpectatorMessages", "boolean", 1);
	dvars["cg_fov"] = add_dvar("cg_fov", "slider", 65, 65, 90, 1);
	dvars["cg_fovScale"] = add_dvar("cg_fovScale", "slider", 1, 0.2, 2, 0.1);
	dvars["cg_thirdPerson"] = add_dvar("cg_thirdPerson", "boolean", 0);
	dvars["cg_thirdPersonAngle"] = add_dvar("cg_thirdPersonAngle", "slider", 356, -180, 360, 1);
	dvars["cg_thirdPersonRange"] = add_dvar("cg_thirdPersonRange", "slider", 120, 0, 1024, 1);
	dvars["jump_slowdownEnable"] = add_dvar("jump_slowdownEnable", "boolean", 1, undefined, undefined, undefined, "global");
	dvars["r_blur"] = add_dvar("r_blur", "slider", 0, 0, 32, 0.2);
	dvars["r_dof_enable"] = add_dvar("r_dof_enable", "boolean", 1);
	dvars["r_fog"] = add_dvar("r_fog", "boolean", 1);
	dvars["r_fullbright"] = add_dvar("r_fullbright", "boolean", 0);
	dvars["r_zFar"] = add_dvar("r_zFar", "slider", 0, 0, 4000, 500);

	return dvars;
}

add_dvar(name, type, default_value, min, max, step, scope)
{
	dvar = spawnstruct();

	dvar.name = name;
	dvar.type = type;
	dvar.default_value = default_value;

	if(isDefined(scope))
		dvar.scope = scope;

	if(type == "slider")
	{
		assert(isDefined(min) && isDefined(max) && isDefined(step));

		dvar.min = min;
		dvar.max = max;
		dvar.step = step;
	}

	return dvar;
}