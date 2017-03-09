#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required // 2015 rules 
#define PLUGIN_VERSION "1.0"
#define WATER_LIMIT 2
#define DEFENDER_TEAM 3
#define ZOMBIE_TEAM 2

Handle hEnabled;
Handle hAutoBhop;
Handle hDefenderHealth;
Handle hZombieHealth;
int defenderHealth;
int zombieHealth;

public Plugin myinfo =
{
	name = "[CS:GO] Zombie Defence",
	author = "Quinn",
	description = "Plugin for zombie defence",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{   
	AutoExecConfig(true, "zombie_defence");
	CreateConVar("zombie_defence_version", PLUGIN_VERSION, "Zombie defense version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hEnabled = CreateConVar("zombie_defence", "1", "Enable/disable zombie defence plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);

	// Bhop
	hAutoBhop = CreateConVar("auto_bhop", "1", "Enable/Disable bhopping", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	if (GetConVarInt(hEnabled) == 1) BhopOn();

	// Zombie defence
	hDefenderHealth = CreateConVar("defender_health", "40", "The starting healh of the defenders", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hZombieHealth = CreateConVar("zombie_health", "150", "The starting health of the zombies", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	defenderHealth = GetConVarInt(hDefenderHealth);
	zombieHealth = GetConVarInt(hZombieHealth);
	HookEvent("player_spawn", PlayerSpawn);
}


public Action PreThink(int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && GetConVarInt(hEnabled) == 1)
	{
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0); 
	}
}

void BhopOn()
{
	SetCvar("sv_enablebunnyhopping", "1"); 
	SetCvar("sv_staminamax", "0");
	SetCvar("sv_airaccelerate", "2000");
	SetCvar("sv_staminajumpcost", "0");
	SetCvar("sv_staminalandcost", "0");
}

void ZombieDefenceOn()
{
	SetCvar("mp_buytime", "100");
	SetCvar("mp_autoteambalance", "0");
	SetCvar("mp_limitteams", "0");
	SetCvar("mp_autokick", "0");
	SetCvar("mp_respawn_on_death_t", "1");
	SetCvar("mp_solid_teammates", "1");

	SetCvar("mp_restartgame", "5");
}

public void PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int playerId = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetClientTeam(playerId);

	if (team == DEFENDER_TEAM) {
		SetEntityHealth(playerId, defenderHealth);
	} else if (team == ZOMBIE_TEAM) {
		SetEntityHealth(playerId, zombieHealth);
	}
}

stock void SetCvar(char[] scvar, char[] svalue)
{
	Handle cvar = FindConVar(scvar);
	SetConVarString(cvar, svalue, true);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(GetConVarInt(hEnabled) == 1 && GetConVarInt(hAutoBhop) == 1) //Check if plugin and autobhop is enabled
		if (IsPlayerAlive(client) && buttons & IN_JUMP) //Check if player is alive and is in pressing space
			if(!(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND)) //Check if is not in ladder and is in air
				if(WaterCheck(client) < WATER_LIMIT)
					buttons &= ~IN_JUMP; 
	return Plugin_Continue;
}

int WaterCheck(int client)
{
	int index = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	return index;
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}