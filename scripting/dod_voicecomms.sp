/**
* DoD:S Voice Communications by Root
*
* Description:
*   Forces different voice commands to players on some events (when player hurts, spawn, captures a point etc).
*
* Version 1.2
* Changelog & more info at http://goo.gl/4nKhJ
*/

#pragma semicolon 1

#include <clientprefs>

// ====[ CONSTANTS ]============================================================
#define PLUGIN_NAME    "DoD:S Voice Communications"
#define PLUGIN_VERSION "1.2"

#define DOD_MAXPLAYERS 33

// For events
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

// ====[ VARIABES ]=============================================================
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

new	Handle:VC_Enabled,
	Handle:VC_clientprefs,
	VC_Chance[VCType],
	bool:IsRoundEnd,
	bool:UseVoice[DOD_MAXPLAYERS + 1] = {true, ...};

// ====[ PLUGIN ]===============================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "Forces different voice commands to players eventually!",
	version     = PLUGIN_VERSION,
	url         = "http://dodsplugins.com/"
}


/* OnPluginStart()
 *
 * When the plugin starts up.
 * ----------------------------------------------------------------------------- */
public OnPluginStart()
{
	// Register ConVars
	CreateConVar("dod_voicecomms_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);

	VC_Enabled          = CreateConVar("dod_voice_communications",  "1", "Whether or not enable Voice Communications",                                      FCVAR_PLUGIN, true, 0.0, true, 1.0);
	VC_Chance[SPAWN]    = CreateConVar("dod_vc_chance_spawn",       "7", "Max chance bounds to voice command on every respawn\n1 means always use command", FCVAR_PLUGIN, true, 1.0);
	VC_Chance[HURT]     = CreateConVar("dod_vc_chance_hurt",        "6", "Max chance bounds to voice command when player is hurt for more than 80 health",  FCVAR_PLUGIN, true, 1.0);
	VC_Chance[ATTACK]   = CreateConVar("dod_vc_chance_attack",      "3", "Max chance bounds to voice command on grenade/smoke throwing and a rocket shot",  FCVAR_PLUGIN, true, 1.0);
	VC_Chance[CAPTURE]  = CreateConVar("dod_vc_chance_capture",     "5", "Max chance bounds to voice command on point capture",                             FCVAR_PLUGIN, true, 1.0);
	VC_Chance[CAPBLOCK] = CreateConVar("dod_vc_chance_block",       "5", "Max chance bounds to voice command on capture block",                             FCVAR_PLUGIN, true, 1.0);
	VC_Chance[PLANT]    = CreateConVar("dod_vc_chance_bomb_plant",  "4", "Max chance bounds to voice command on bomb plant",                                FCVAR_PLUGIN, true, 1.0);
	VC_Chance[DEFUSE]   = CreateConVar("dod_vc_chance_bomb_defuse", "4", "Max chance bounds to voice command on bomb defuse",                               FCVAR_PLUGIN, true, 1.0);
	VC_Chance[ROUNDWIN] = CreateConVar("dod_vc_chance_roundwin",    "6", "Max chance bounds to voice command when round over",                              FCVAR_PLUGIN, true, 1.0);

	// Hook changes for main CVar
	HookConVarChange(VC_Enabled, OnConVarChange);

	// Manually trigger OnConVarChange to hook plugin's events
	OnConVarChange(VC_Enabled, "0", "1");

	// Creates a new clientprefs cookies
	VC_clientprefs = RegClientCookie("VC Preferences", "Voice Communications", CookieAccess_Private);
	SetCookieMenuItem(CookieMenuHandler_VoiceCommunications, MENU_NO_PAGINATION, "Voice Communications");

	// Load "Yes/No" phrases
	LoadTranslations("common.phrases");
	AutoExecConfig(true, "dod_voicecomms");
}

/* OnConVarChange()
 *
 * When convar's value is changed.
 * ----------------------------------------------------------------------------- */
public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
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

/* OnClientCookiesCached()
 *
 * Called once a client's saved cookies have been loaded from the database.
 * ----------------------------------------------------------------------------- */
public OnClientCookiesCached(client) UseVoice[client] = GetVoiceCooikies(client);

/* GetVoiceCooikies()
 *
 * Retrieves client preferences related to Voice Communications.
 * ----------------------------------------------------------------------------- */
bool:GetVoiceCooikies(client)
{
	// Get the cookie
	decl String:buffer[8];
	GetClientCookie(client, VC_clientprefs, buffer, sizeof(buffer));

	// Enable voice comms if value is not equal to "No"
	return !StrEqual(buffer, "No", false) ? true : false;
}

/* CookieMenuHandler_VoiceCommunications()
 *
 * Clientprefs menu handler to select option for Voice Communications.
 * ----------------------------------------------------------------------------- */
public CookieMenuHandler_VoiceCommunications(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	// A cookies option is being drawn for a menu
	if (action == CookieMenuAction_DisplayOption)
	{
		decl String:status[8];

		// Add option for enable/disable voice communications
		if (UseVoice[client])
			 Format(status, sizeof(status), "%T", "Yes", client);
		else Format(status, sizeof(status), "%T", "No",  client);

		// Draw cookies as a separate item
		Format(buffer, maxlen, "Voice Communications: %s", status);
	}
	else // Other is always select
	{
		UseVoice[client] = !UseVoice[client];

		// Set client cookies
		if (UseVoice[client])
			 SetClientCookie(client, VC_clientprefs, "Yes");
		else SetClientCookie(client, VC_clientprefs, "No");

		// Redraw cookies menu on selection
		ShowCookieMenu(client);
	}
}

/* Event_player_spawn()
 *
 * Called when a player spawns.
 * ----------------------------------------------------------------------------- */
public Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Ignore this event when round ends
	if (!IsRoundEnd)
	{
		// Use voice command if value of random seed is matches with minimal possible
		if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[SPAWN])) == 1)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));

			// Make sure client set voice commands via preferences
			if (IsValidClient(client))
			{
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
}

/* Event_player_hurt()
 *
 * Called when a player gets hurt.
 * ----------------------------------------------------------------------------- */
public Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Ignore
	if (!IsRoundEnd)
	{
		if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[HURT])) == 1)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));

			if (IsValidClient(client))
			{
				// Check whether or not client got less than 20 hp
				if (GetClientHealth(client) < 20)
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
}

/* Event_player_hurt()
 *
 * Called when a player attacks with a weapon.
 * ----------------------------------------------------------------------------- */
public Event_Player_Attack(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsRoundEnd)
	{
		if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[ATTACK])) == 1)
		{
			new client = GetClientOfUserId(GetEventInt(event, "attacker"));

			// Check which weapon player is firing
			switch (GetEventInt(event, "weapon"))
			{
				case WeaponID_Bazooka, WeaponID_Pschreck:
				{
					// Make sure client wants to use voice, so then use it
					if (IsValidClient(client)) FakeClientCommand(client, "voice_usebazooka");
				}
				case // Any grenades
					WeaponID_Frag_US,
					WeaponID_Frag_GER,
					WeaponID_Riflegren_US,
					WeaponID_Riflegren_GER:
				{
					// A Counter-Strike style!
					if (IsValidClient(client)) FakeClientCommand(client, "voice_fireinhole");
				}
				case // Live grenades
					WeaponID_Frag_US_Live,
					WeaponID_Frag_GER_Live,
					WeaponID_Riflegren_US_Live,
					WeaponID_Riflegren_GER_Live:
				{
					// Use different voice command here
					if (IsValidClient(client)) FakeClientCommand(client, "voice_grenade");
				}
				case WeaponID_Smoke_US, WeaponID_Smoke_GER:
				{
					// A smoke
					if (IsValidClient(client)) FakeClientCommand(client, "voice_usesmoke");
				}
			}
		}
	}
}

/* Event_Point_Captured()
 *
 * Called when a client(s) captured point.
 * ----------------------------------------------------------------------------- */
public Event_Point_Captured(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Initialize 'clients' to get one of random client from both teams
	decl clients[MaxClients], numAttackers, numDefenders, i,
	capteam, randomAttacker, randomDefender, String:cappers[256];
	GetEventString(event, "cappers", cappers, sizeof(cappers));

	numAttackers = numDefenders = 0;

	// Loop through all cappers
	for (i = 0; i < strlen(cappers); i++)
		capteam = GetClientTeam(cappers[i]);

	// Now through all clients
	for (i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (GetClientTeam(i) == capteam)
			{
				// Get max amount of teammates
				clients[numAttackers++] = i;
				randomAttacker = clients[Math_GetRandomInt(0, numAttackers - 1)];
			}
			else
			{
				// And enemies
				clients[numDefenders++] = i;
				randomDefender = clients[Math_GetRandomInt(0, numDefenders - 1)];
			}
		}
	}

	// Check whether or not random seed is matches
	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[CAPTURE])) == 1)
	{
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
		// There may be no random defenders, so check if they're valid before forcing a command
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
 * ----------------------------------------------------------------------------- */
public Event_Capture_Blocked(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check random seed before initializing anything
	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[CAPBLOCK])) == 1)
	{
		new client = GetEventInt(event, "blocker");

		if (IsValidClient(client))
		{
			switch (Math_GetRandomInt(0, 3))
			{
				case 0: FakeClientCommand(client, "voice_hold");
				case 1: FakeClientCommand(client, "voice_cover");
				case 2: FakeClientCommand(client, "voice_backup");
				case 3: FakeClientCommand(client, "voice_areaclear");
			}
		}
	}
}

/* Event_Bomb_Planted()
 *
 * Called when a player planted bomb.
 * ----------------------------------------------------------------------------- */
public Event_Bomb_Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl clients[MaxClients], i, numClients, client, randomEnemy;
	client = GetClientOfUserId(GetEventInt(event, "userid"));

	numClients = 0;

	// Shout help/backup voice command on planter for calling a teammates
	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[PLANT])) == 1)
	{
		if (IsValidClient(client))
		{
			switch (Math_GetRandomInt(0, 1))
			{
				case 0: FakeClientCommand(client, "voice_cover");
				case 1: FakeClientCommand(client, "voice_backup");
			}
		}
	}

	// Check another random stream
	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[PLANT])) == 1)
	{
		// Loop through all clients
		for (i = 1; i <= MaxClients; i++)
		{
			// From enemies team
			if (IsValidClient(i) && GetClientTeam(i) != GetClientTeam(client))
			{
				clients[numClients++] = i;
				randomEnemy = clients[Math_GetRandomInt(0, numClients - 1)];
			}
		}

		if (IsValidClient(randomEnemy))
		{
			// If enemy is valid, execute some warning commands on it
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
 *------------------------------------------------------------------------------ */
public Event_Bomb_Defused(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Continue after successfull random seed
	if (Math_GetRandomInt(1, GetConVarInt(VC_Chance[DEFUSE])) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (IsValidClient(client))
		{
			switch (Math_GetRandomInt(0, 2))
			{
				case 0: FakeClientCommand(client, "voice_hold"); // Hold this position
				case 1: FakeClientCommand(client, "voice_areaclear"); // Area clear
				case 2: FakeClientCommand(client, "voice_moveupmg"); // Move up MG here
			}
		}
	}
}

/* Event_Round_End()
 *
 * Called when a round ends.
  ------------------------------------------------------------------------------ */
public Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Initialize clients, winners, losers and random clients
	decl clients[MaxClients], client, numWinners, numLosers, randomWinner, randomLoser;

	// Reset amount of winners and losers to properly check how many players are available in both teams
	numWinners = numLosers = 0;

	for (client = 1; client <= MaxClients; client++)
	{
		// Loop through only ingame and alive players
		if (IsValidClient(client))
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
		// There may be no losers in opposite team, so check whether or not there is any valid enemy
		if (IsValidClient(randomLoser))
		{
			// Only 3 losers voice commands are exists
			switch (Math_GetRandomInt(0, 2))
			{
				case 0: FakeClientCommand(randomLoser, "voice_ceasefire");
				case 1: FakeClientCommand(randomLoser, "voice_fallback");
				case 2: FakeClientCommand(randomLoser, "voice_displace");
			}
		}
	}

	// Set round end
	IsRoundEnd = true;
}

/* Event_Game_Over()
 *
 * Called when a round starts and game ends.
* ------------------------------------------------------------------------------ */
public Event_Game_Over(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Plugin using two events here
	decl clients[MaxClients], client, numClients, randomPlayer;
	numClients = 0; // 0

	for (client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			// Emit 'cease fire' voice cmd, because on this event players cant fire
			clients[numClients++] = client;
			randomPlayer = clients[Math_GetRandomInt(0, numClients - 1)];
		}
	}

	// Use voice command on random valid player
	if (IsValidClient(randomPlayer))
		FakeClientCommand(randomPlayer, "voice_ceasefire");

	// Set round end boolean to false
	IsRoundEnd = false;
}

/* Math_GetRandomInt()
 *
 * Returns a random, uniform Integer number in the specified (inclusive) range.
 * This is safe to use multiple times in a function. Copied from SMAC stocks.
* ------------------------------------------------------------------------------ */
Math_GetRandomInt(min, max)
{
	return RoundToNearest(GetURandomFloat() * float(max - min) + float(min));
}

/* IsValidClient()
 *
 * Checks if a client is valid.
 * ----------------------------------------------------------------------------- */
bool:IsValidClient(client) return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && UseVoice[client]) ? true : false;