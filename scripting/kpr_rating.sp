#include <sourcemod>
#include <sdktools>
#include <kpr_rating>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "kills per round rating",
	author = "Justin (ff)",
	description = "A method of rating players based on their kills per round",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/namenotjustin"
}

enum struct ClientData
{
	bool spawned;
	int roundKills;
	int rounds;
	float kpr;
}

ClientData cd[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max)
{
	CreateNative("KPRRating_GetScore", Native_GetScore);
	RegPluginLibrary("kpr_rating");
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		cd[client].kpr = 0.0;
		cd[client].rounds = 0;
		cd[client].spawned = false;
		cd[client].roundKills = 0;
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, CheckIfClientSpawned, event.GetInt("userid"));
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (victim > 0 && victim <= MaxClients && IsClientInGame(victim) && attacker && attacker <= MaxClients && IsClientInGame(attacker))
	{
		++cd[attacker].roundKills;
	}
}

Action CheckIfClientSpawned(Handle timer, int userId)
{
	int client = GetClientOfUserId(userId);
	if (!IsWarmupActive() && client > 0 && client <= MaxClients && IsClientInGame(client) && !cd[client].spawned && IsPlayerAlive(client))
	{
		cd[client].spawned = true;
		++cd[client].rounds;
	}
	return Plugin_Handled;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client))
		{
			cd[client].spawned = false;
			cd[client].rounds = 0;
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsWarmupActive())
	{
		for(int client = 1; client <= MaxClients; ++client)
		{
			if (IsClientInGame(client) && cd[client].rounds > 0)
			{
				cd[client].kpr = ((cd[client].rounds - 1) * cd[client].kpr + cd[client].roundKills) / cd[client].rounds;
			}
		}
	}
}

bool IsWarmupActive()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}

public any Native_GetScore(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return cd[client].kpr;
}