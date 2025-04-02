#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init()
{
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

		self iPrintlnBold("B)");
	}
}