/**
* DoD:S Voice Communications by Root
*
* Description:
*   Forces different voice commands on some events (when player hurts, spawn, captures a point etc).
*
* Version 1.0
* Changelog & more info at http://goo.gl/4nKhJ
*/

#pragma semicolon 1

// ====[ CONSTANTS ]==========================================================
#define PLUGIN_NAME    "DoD:S Voice Communications"
#define PLUGIN_VERSION "1.0"

#define SIZE_OF_INT    2147483647

// ID's for events
enum
{
	WeaponID_Bazooka = 17,
	WeaponID_Pschreck,
	WeaponID_Frag_US,
	WeaponID_Frag_GER,
	WeaponID_Frag_US_Live,
	WeaponID_Frag_GER_Live,
	WeaponID_Smoke_US,
	WeaponID_Smoke_GER,
	WeaponID_Riflegren_US,
	WeaponID_Riflegren_GER,
	WeaponID_Riflegren_US_Live,
	WeaponID_Riflegren_GER_Live
};

// ====[ VARIABES ]===========================================================
enum VCType
{
	Handle:SPAWN,
	Handle:HURT,
	Handle:ATTACK,
	Handle:CAPTURE,
	Handle:CAPBLOCK,
	Handle:PLANT,
	Handle:DEFUSE,
	Handle:ROUNDWIN
};

new	Handle:VC_Enabled, VC_Chance[VCType], bool:IsRoundEnd;

// ====[ PLUGIN ]=============================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "Forces different voice commands eventually!",
	version     = PLUGIN_VERSION,
	url         = "http://dodsplugins.com/"
}


/* OnPluginStart()
 *
 * When the plugin starts up.
 * --------------------------------------------------------------------------- */
public OnPluginStart()
{
	// Register version ConVar
	CreateConVar("dod_voicecomms_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Register other ConVars
	VC_Enabled          = CreateConVar("dod_voice_communications",    "1", "Whether or not enable Voice Communications",                                       FCVAR_PLUGIN, true, 0.0, true, 1.0);
	VC_Chance[SPAWN]    = CreateConVar("dod_vc_chance_spawn",         "5", "Max chance bounds to voice command on every respawn",                              FCVAR_PLUGIN, true, 1.0);
	VC_Chance[HURT]     = CreateConVar("dod_vc_chance_hurt",          "4", "Max chance bounds to voice command when player is hurt (for more than 80 health)", FCVAR_PLUGIN, true, 1.0);
	VC_Chance[ATTACK]   = CreateConVar("dod_vc_chance_attack",        "1", "Max chance bounds to voice command on grenade/smoke throws and a rocket shots",    FCVAR_PLUGIN, true, 1.0);
	VC_Chance[CAPTURE]  = CreateConVar("dod_vc_chance_capture",       "3", "Max chance bounds to voice command on point capture (for both teams)",             FCVAR_PLUGIN, true, 1.0);
	VC_Chance[CAPBLOCK] = CreateConVar("dod_vc_chance_capture_block", "3", "Max chance bounds to voice command on capture block\n1 means always use command",  FCVAR_PLUGIN, true, 1.0);
	VC_Chance[PLANT]    = CreateConVar("dod_vc_chance_bomb_plant",    "2", "Max chance bounds to voice command on bomb plant",                                 FCVAR_PLUGIN, true, 1.0);
	VC_Chance[DEFUSE]   = CreateConVar("dod_vc_chance_bomb_defuse",   "2", "Max chance bounds to voice command on bomb defuse",                                FCVAR_PLUGIN, true, 1.0);
	VC_Chance[ROUNDWIN] = CreateConVar("dod_vc_chance_roundwin",      "3", "Max chance bounds to voice command when round ends (for both teams)",              FCVAR_PLUGIN, true, 1.0);

	// Hook only main ConVar changes
	HookConVarChange(VC_Enabled, OnConVarChange);

	// Manually trigger OnConVarChange to hook plugin's events
	OnConVarChange(VC_Enabled, "0", "1");

	// Plugin config
	AutoExecConfig(true, "dod_voicecomms.cfg");
}

/* OnConVarChange()
 *
 * When convar's value is changed.
 * --------------------------------------------------------------------------- */
public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Main ConVar is a bool, so dont need to check whatever else
	switch (StringToInt(newValue))
	{
		case false:
		{
			UnhookEvent("player_spawn",            Event_Player_Spawn,    EventHookMode_Post);
			UnhookEvent("player_hurt",             Event_Player_Hurt,     EventHookMode_Post);
			UnhookEvent("dod_stats_weapon_attack", Event_Player_Attack,   EventHookMode_Post);
			UnhookEvent("dod_point_captured",      Event_Point_Captured,  EventHookMode_Post);
			UnhookEvent("dod_capture_blocked",     Event_Capture_Blocked, EventHookMode_Post);
			UnhookEvent("dod_bomb_planted",        Event_Bomb_Planted,    EventHookMode_Post);
			UnhookEvent("dod_bomb_defused",        Event_Bomb_Defused,    EventHookMode_Post);
			UnhookEvent("dod_round_win",           Event_Round_End,       EventHookMode_Post);
			UnhookEvent("dod_round_start",         Event_Game_Over,       EventHookMode_PostNoCopy);
			UnhookEvent("dod_game_over",           Event_Game_Over,       EventHookMode_PostNoCopy);
		}
		case true:
		{
			HookEvent("player_spawn",            Event_Player_Spawn,    EventHookMode_Post);
			HookEvent("player_hurt",             Event_Player_Hurt,     EventHookMode_Post);
			HookEvent("dod_stats_weapon_attack", Event_Player_Attack,   EventHookMode_Post);
			HookEvent("dod_point_captured",      Event_Point_Captured,  EventHookMode_Post);
			HookEvent("dod_capture_blocked",     Event_Capture_Blocked, EventHookMode_Post);
			HookEvent("dod_bomb_planted",        Event_Bomb_Planted,    EventHookMode_Post);
			HookEvent("dod_bomb_defused",        Event_Bomb_Defused,    EventHookMode_Post);
			HookEvent("dod_round_win",           Event_Round_End,       EventHookMode_Post);
			HookEvent("dod_round_start",         Event_Game_Over,       EventHookMode_PostNoCopy);
			HookEvent("dod_game_over",           Event_Game_Over,       EventHookMode_PostNoCopy);
		}
	}
}

/* Event_player_spawn()
 *
 * Called when a player spawns.
 * --------------------------------------------------------------------------- */
public Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Ignore this event when round ends
	if (!IsRoundEnd)
	{
		// Use voice command if value of random seed is matches with minimal possible
		if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[SPAWN])) == 1)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));

			// Get random voice command
			switch (Math_GetRandomInt(0, 6))
			{
				case 0: FakeClientCommand(client, "voice_attack");
				case 1: FakeClientCommand(client, "voice_sticktogether");
				case 2: FakeClientCommand(client, "voice_mgahead");
				case 3: FakeClientCommand(client, "voice_moveupmg");
				case 4: FakeClientCommand(client, "voice_coverflanks");
				case 5: FakeClientCommand(client, "voice_movewithtank");
				case 6: FakeClientCommand(client, "voice_enemyahead");
			}
		}
	}
}

/* Event_player_hurt()
 *
 * Called when a player gets hurt.
 * --------------------------------------------------------------------------- */
public Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsRoundEnd)
	{
		if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[HURT])) == 1)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));

			// Check whether or not client has less than 20 health
			if (GetClientHealth(client) <= 20)
			{
				// Emit one of random voice commands which give to know that player is weak
				switch (Math_GetRandomInt(0, 3))
				{
					case 0: FakeClientCommand(client, "voice_backup");
					case 1: FakeClientCommand(client, "voice_medic");
					case 2: FakeClientCommand(client, "voice_fireleft");
					case 3: FakeClientCommand(client, "voice_fireright");
				}
			}
		}
	}
}

/* Event_player_hurt()
 *
 * Called when a player attacks with a weapon.
 * --------------------------------------------------------------------------- */
public Event_Player_Attack(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Ignore round end too
	if (!IsRoundEnd)
	{
		if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[ATTACK])) == 1)
		{
			// short attacker
			new client = GetClientOfUserId(GetEventInt(event, "attacker"));

			// Check which weapon player is firing
			switch (GetEventInt(event, "weapon"))
			{
				// Rocket
				case WeaponID_Bazooka, WeaponID_Pschreck:
				{
					// Notice teammates
					FakeClientCommand(client, "voice_usebazooka");
				}
				case // Any grenades
					WeaponID_Frag_US,
					WeaponID_Frag_GER,
					WeaponID_Riflegren_US,
					WeaponID_Riflegren_GER:
				{
					// Counter-Strike!
					FakeClientCommand(client, "voice_fireinhole");
				}
				case // Live grenades
					WeaponID_Frag_US_Live,
					WeaponID_Frag_GER_Live,
					WeaponID_Riflegren_US_Live,
					WeaponID_Riflegren_GER_Live:
				{
					// Use different and more dangerously voice command here
					FakeClientCommand(client, "voice_grenade");
				}
				case WeaponID_Smoke_US, WeaponID_Smoke_GER:
				{
					// Smoke
					FakeClientCommand(client, "voice_usesmoke");
				}
			}
		}
	}
}

/* Event_Point_Captured()
 *
 * Called when a client(s) captured point.
 * --------------------------------------------------------------------------- */
public Event_Point_Captured(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Initialize 'clients' to get one of random client from both teams
	decl clients[MaxClients], numAttackers, numDefenders,
	randomAttacker, randomDefender, i, x, String:cappers[256];
	GetEventString(event, "cappers", cappers, sizeof(cappers));

	numAttackers = numDefenders = 0;

	// Loop through all cappers
	for (i = 0; i < strlen(cappers); i++)
	{
		// Now through all clients
		for (x = 1; x <= MaxClients; x++)
		{
			if (IsClientInGame(x) && IsPlayerAlive(x))
			{
				if (GetClientTeam(x) == GetClientTeam(cappers[i]))
				{
					// Get max amount of teammates
					clients[numAttackers++] = x;
					randomAttacker = clients[Math_GetRandomInt(0, numAttackers - 1)];
				}
				else
				{
					// And enemies
					clients[numDefenders++] = x;
					randomDefender = clients[Math_GetRandomInt(0, numDefenders - 1)];
				}
			}
		}
	}

	// Check whether or not random seed is matches
	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[CAPTURE])) == 1)
	{
		// Check whether or not any teammate of capper is valid
		if (IsValidClient(randomAttacker))
		{
			switch (Math_GetRandomInt(0, 4))
			{
				case 0: FakeClientCommand(randomAttacker, "voice_hold");
				case 1: FakeClientCommand(randomAttacker, "voice_sticktogether");
				case 2: FakeClientCommand(randomAttacker, "voice_wegothim");
				case 3: FakeClientCommand(randomAttacker, "voice_moveupmg");
				case 4: FakeClientCommand(randomAttacker, "voice_coverflanks");
			}
		}
	}

	// Teammates random may not match, so check enemies now
	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[CAPTURE])) == 1)
	{
		if (IsValidClient(randomDefender))
		{
			// Get random voice command
			switch (Math_GetRandomInt(0, 4))
			{
				// Execute a voice command on random enemy
				case 0: FakeClientCommand(randomDefender, "voice_attack");
				case 1: FakeClientCommand(randomDefender, "voice_backup");
				case 2: FakeClientCommand(randomDefender, "voice_displace");
				case 3: FakeClientCommand(randomDefender, "voice_usebazooka");
				case 4: FakeClientCommand(randomDefender, "voice_enemyahead");
			}
		}
	}
}

/* Event_Capture_Blocked()
 *
 * Called when a player blocked capture.
 * --------------------------------------------------------------------------- */
public Event_Capture_Blocked(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check random seed before initializing anything
	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[CAPBLOCK])) == 1)
	{
		// short "blocker"
		new client = GetEventInt(event, "blocker");

		switch (Math_GetRandomInt(0, 3))
		{
			case 0: FakeClientCommand(client, "voice_hold");
			case 1: FakeClientCommand(client, "voice_cover");
			case 2: FakeClientCommand(client, "voice_backup");
			case 3: FakeClientCommand(client, "voice_areaclear");
		}
	}
}

/* Event_Bomb_Planted()
 *
 * Called when a player planted bomb.
 * --------------------------------------------------------------------------- */
public Event_Bomb_Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl clients[MaxClients], numClients, client, randomEnemy;
	client = GetClientOfUserId(GetEventInt(event, "userid"));

	numClients = 0;

	// Shout help/backup voice command on planter for calling a teammates
	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[PLANT])) == 1)
	{
		switch (Math_GetRandomInt(0, 1))
		{
			case 0: FakeClientCommand(client, "voice_cover");
			case 1: FakeClientCommand(client, "voice_backup");
		}
	}

	// Check another random stream
	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[PLANT])) == 1)
	{
		// Loop through all clients
		for (new i = 1; i <= MaxClients; i++)
		{
			// From enemies team
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(client))
			{
				clients[numClients++] = i;
				randomEnemy = clients[Math_GetRandomInt(0, numClients - 1)];
			}
		}

		// If enemy is valid, execute some warning commands on it
		if (IsValidClient(randomEnemy))
		{
			switch (Math_GetRandomInt(0, 6))
			{
				case 0: FakeClientCommand(randomEnemy, "voice_attack");
				case 1: FakeClientCommand(randomEnemy, "voice_sticktogether");
				case 2: FakeClientCommand(randomEnemy, "voice_usegrens");
				case 3: FakeClientCommand(randomEnemy, "voice_moveupmg");
				case 4: FakeClientCommand(randomEnemy, "voice_usebazooka");
				case 5: FakeClientCommand(randomEnemy, "voice_coverflanks");
				case 6: FakeClientCommand(randomEnemy, "voice_enemyahead");
			}
		}
	}
}

/* Event_Bomb_Defused()
 *
 * Called when a player defused bomb.
 *---------------------------------------------------------------------------- */
public Event_Bomb_Defused(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Continue after successfull random seed
	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[DEFUSE])) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		switch (Math_GetRandomInt(0, 2))
		{
			case 0: FakeClientCommand(client, "voice_hold"); // Hold this position
			case 1: FakeClientCommand(client, "voice_areaclear"); // Area clear
			case 2: FakeClientCommand(client, "voice_moveupmg"); // Move up MG here
		}
	}
}

/* Event_Round_End()
 *
 * Called when a round ends.
  ---------------------------------------------------------------------------- */
public Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Initialize clients, winners, losers and random clients
	decl clients[MaxClients], numWinners, numLosers, randomWinner, randomLoser;

	// Reset amount of winners and losers to properly check how many players are available in both teams
	numWinners = numLosers = 0;

	for (new client = 1; client <= MaxClients; client++)
	{
		// Loop through only ingame and alive players
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			// Winners
			if (GetClientTeam(client) == GetEventInt(event, "team"))
			{
				clients[numWinners++] = client;
				randomWinner = clients[Math_GetRandomInt(0, numWinners - 1)];
			}

			// Not a winners
			else
			{
				clients[numLosers++] = client;

				// Get random client from losers team
				randomLoser = clients[Math_GetRandomInt(0, numLosers - 1)];
			}
		}
	}

	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[ROUNDWIN])) == 1)
	{
		if (IsValidClient(randomWinner))
		{
			// Only 3 winning voice commands are exists
			switch (Math_GetRandomInt(0, 2))
			{
				case 0: FakeClientCommand(randomWinner, "voice_dropweapons");
				case 1: FakeClientCommand(randomWinner, "voice_gogogo");
				case 2: FakeClientCommand(randomWinner, "voice_wtf");
			}
		}
	}

	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[ROUNDWIN])) == 1)
	{
		// Any loser is alive?
		if (IsValidClient(randomLoser))
		{
			// Only 2 losers voice commands are exists
			switch (Math_GetRandomInt(0, 1))
			{
				case 0: FakeClientCommand(randomLoser, "voice_ceasefire");
				case 1: FakeClientCommand(randomLoser, "voice_fallback");
			}
		}
	}

	// Set round end
	IsRoundEnd = true;
}

/* Event_Game_Over()
 *
 * Called when a round starts and game ends.
* ---------------------------------------------------------------------------- */
public Event_Game_Over(Handle:event, const String:name[], bool:dontBroadcast)
{
	// I have to use two events here
	new clients[MaxClients], numClients;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			// Emit 'cease fire' voice - because on those events players cant fire
			clients[numClients++] = client;
			FakeClientCommand(clients[Math_GetRandomInt(0, numClients - 1)], "voice_ceasefire");
		}
	}

	// Set round end boolean to false
	IsRoundEnd = false;
}

/**
 * Returns a random, uniform Integer number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 * Rewritten by MatthiasVance, thanks.
 *
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Integer number between min and max
 */
Math_GetRandomInt(min, max)
{
	new random = GetURandomInt();

	if (random == 0)
	{
		random++;
	}

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

/* IsValidClient()
 *
 * Checks if a client is valid.
 * --------------------------------------------------------------------------- */
bool:IsValidClient(client) return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)) ? true : false;