#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\codjumper\functions;
#include maps\mp\codjumper\utils;

init()
{
	level._callbackPlayerDamage = ::blank;

	level.TOGGLES = strTok("OFF;ON", ";");

	gametype = level._gametype;
	setDvar("scr_" + gametype + "_scorelimit", 0);
	setDvar("scr_" + gametype + "_timelimit", 0);
	setDvar("scr_" + gametype + "_playerrespawndelay", 0);
	setDvar("scr_" + gametype + "_numlives", 0);
	setDvar("scr_" + gametype + "_roundlimit", 0);

	setDvar("player_sprintUnlimited", 1);
	setDvar("jump_slowdownEnable", 0);

	setDvar("bg_fallDamageMaxHeight", 9999);
	setDvar("bg_fallDamageMinHeight", 9998);

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
	}
}

watch_buttons()
{
	self endon("end_respawn");
	self endon("disconnect");
	level endon("game_ended")

	self registerCommand("+melee");
	self registerCommand("+frag");
	self registerCommand("+smoke");

	for(;;)
	{
		button = self waittill_button_press();

		switch(button)
		{
			case "melee":
				if(self button_pressed_twice("melee"))
					self save_pos(0);

				break;
			case "frag":
				self toggle_ufo();
				break;
			case "smoke":
				self load_pos(0);
				break;
		}
	}
}