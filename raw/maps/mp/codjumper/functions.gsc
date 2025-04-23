#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\codjumper\utils;

replenish_ammo()
{
	self endon("end_respawn");
	self endon("disconnect");

	level endon("game_ended");

	for(;;)
	{
		self giveMaxAmmo(self getCurrentWeapon());

		wait 1;
	}
}

reset_fov()
{
	if(isDefined(self.cj["settings"]["cg_fov"]))
		self setClientDvar("cg_fov", self.cj["settings"]["cg_fov"]);
}

toggle_ufo()
{
	SESSION_STATES = strTok("playing;spectator", ";");

	if(!isDefined(self.ufo_mode))
		self.ufo_mode = false;

	self.ufo_mode ^= 1;

	self allowSpectateTeam("freelook", self.ufo_mode);
	self.sessionstate = SESSION_STATES[self.ufo_mode];

	self iPrintln("UFO mode " + level.TOGGLES[self.ufo_mode]);
}

save_pos(i)
{
	if(!self isOnGround())
		return;

	self.savedOrigin = self.origin;
	self.savedAngles = self getPlayerAngles();
}

load_pos(i)
{
	self freezeControls(true);
	wait .05;

	self setOrigin(self.savedOrigin);
	self setPlayerAngles(self.savedAngles);

	wait .05;
	self freezeControls(false);
}

change_map(mapname)
{
	map(mapname);
}