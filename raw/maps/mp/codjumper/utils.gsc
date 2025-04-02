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