#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <autoexecconfig>
#include <cubbi>
#include <outbreak>

#define FEATURE_NAME "Show Damage"
#define FEATURE_DESCRIPTION "Shows hud text with dealed damage"

enum struct GlobalData {
    ConVar Level;
    ConVar Points;
    ConVar Expiration;
    ConVar Refundable;
    ConVar Tradable;
}
GlobalData Core;

enum struct PlayerData {
    bool HasFeature;
}
PlayerData Player[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Cubbi - Show Damage",
    author = "Bara (Original author: dordnung)",
    version = "1.0.0",
    description = "",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("cubbi.show_damage");
    Core.Level = AutoExecConfig_CreateConVar("show_damage_level", "5", "Which level is required to bought this feature?");
    Core.Points = AutoExecConfig_CreateConVar("show_damage_points", "200", "How much points are required to bought this feature?");
    Core.Expiration = AutoExecConfig_CreateConVar("show_damage_expiration", "0", "How long (time in minutes) this feature for earch should be exists? 0 - Lifetime");
    Core.Refundable = AutoExecConfig_CreateConVar("show_damage_refundable", "1", "Allow players to refund this feature?", _, true, 0.0, true, 1.0);
    Core.Tradable = AutoExecConfig_CreateConVar("show_damage_tradable", "0", "Allow players to trade this feature to other players or market?", _, true, 0.0, true, 1.0);
    AutoExecConfig_CleanFile();
    AutoExecConfig_ExecuteFile();

    HookEvent("player_death", Event_PlayerDeath);
}

public void Cubbi_OnLoaded()
{
    Cubbi_RegisterFeature(FEATURE_NAME, FEATURE_DESCRIPTION, Core.Level.IntValue, Core.Points.IntValue, Core.Expiration.IntValue, Core.Refundable.BoolValue, Core.Tradable.BoolValue);
}

public void Cubbi_OnClientReady(int client, ArrayList features)
{
    for (int i = 0; i < features.Length; i++)
    {
        PlayerFeatureData PlayerFeature;
        features.GetArray(i, PlayerFeature, sizeof(PlayerFeature));
        
        if (StrEqual(PlayerFeature.Name, FEATURE_NAME, false))
        {
            Player[client].HasFeature = true;
            break;
        }
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client && IsClientInGame(client))
	{
		if (Player[client].HasFeature)
		{
			int iHPDamage = GetEventInt(event, "dmg_health");
			int iArmorDamage = GetEventInt(event, "dmg_armor");

			PrintCSGOHUDText(client, "- %i HP | - %i Armor", iHPDamage, iArmorDamage);
		}
	}

	return Plugin_Continue;
}
