#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <autoexecconfig>
#include <cubbi>

#define MAX_ENTITIES 2048
#define FEATURE_NAME "More Speed"
#define FEATURE_DESCRIPTION "Gives you few percent more speed"

enum struct GlobalData {
    ConVar Level;
    ConVar Points;
    ConVar Expiration;
    ConVar Refundable;
    ConVar Tradable;
    ConVar Factor;
}
GlobalData Core;

enum struct PlayerData {
    bool HasFeature;
    int Weapons[MAX_ENTITIES];
}
PlayerData Player[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Cubbi - More Speed",
    author = "Bara (Original author: dordnung)",
    version = "1.0.0",
    description = "",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("cubbi.more_speed");
    Core.Level = AutoExecConfig_CreateConVar("more_speed_level", "5", "Which level is required to bought this feature?");
    Core.Points = AutoExecConfig_CreateConVar("more_speed_points", "200", "How much points are required to bought this feature?");
    Core.Expiration = AutoExecConfig_CreateConVar("more_speed_expiration", "0", "How long (time in minutes) this feature for earch should be exists? 0 - Lifetime");
    Core.Refundable = AutoExecConfig_CreateConVar("more_speed_refundable", "1", "Allow players to refund this feature?", _, true, 0.0, true, 1.0);
    Core.Tradable = AutoExecConfig_CreateConVar("more_speed_tradable", "0", "Allow players to trade this feature to other players or market?", _, true, 0.0, true, 1.0);
    Core.Factor = AutoExecConfig_CreateConVar("more_speed_amount", "5", "Speed increase in percent");
    AutoExecConfig_CleanFile();
    AutoExecConfig_ExecuteFile();

    HookEvent("player_spawn", Event_PlayerSpawn);
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

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    SetClientSpeed(client);
    
    return Plugin_Continue;
}

public void Cubbi_OnClientPurchase(int client, const char[] name)
{
    SetClientSpeed(client);
}

void SetClientSpeed(int client)
{
    if (client && IsClientInGame(client) && IsPlayerAlive(client) && Player[client].HasFeature)
    {
        float fSpeed;
        
        fSpeed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") + (Core.Factor.FloatValue / 100.0);
        
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", fSpeed);
    }
}