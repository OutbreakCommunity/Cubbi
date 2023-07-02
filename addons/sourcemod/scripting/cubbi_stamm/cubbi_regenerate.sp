#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <autoexecconfig>
#include <cubbi>

#define FEATURE_NAME "Regenerate"
#define FEATURE_DESCRIPTION "You will get hp after a specific interval"

enum struct GlobalData {
    ConVar Level;
    ConVar Points;
    ConVar Expiration;
    ConVar Refundable;
    ConVar Tradable;
    ConVar HP;
    ConVar Interval;
}
GlobalData Core;

enum struct PlayerData {
    bool HasFeature;
}
PlayerData Player[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Cubbi - Regenerate",
    author = "Bara (Original author: dordnung)",
    version = "1.0.0",
    description = "",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("cubbi.regenerate");
    Core.Level = AutoExecConfig_CreateConVar("regenerate_level", "5", "Which level is required to bought this feature?");
    Core.Points = AutoExecConfig_CreateConVar("regenerate_points", "200", "How much points are required to bought this feature?");
    Core.Expiration = AutoExecConfig_CreateConVar("regenerate_expiration", "0", "How long (time in minutes) this feature for earch should be exists? 0 - Lifetime");
    Core.Refundable = AutoExecConfig_CreateConVar("regenerate_refundable", "1", "Allow players to refund this feature?", _, true, 0.0, true, 1.0);
    Core.Tradable = AutoExecConfig_CreateConVar("regenerate_tradable", "0", "Allow players to trade this feature to other players or market?", _, true, 0.0, true, 1.0);
    Core.HP = AutoExecConfig_CreateConVar("regenerate_hp", "2", "HP regeneration of a VIP, every x seconds per block");
    Core.Interval = AutoExecConfig_CreateConVar("regenerate_time", "1", "Time interval to regenerate (in Seconds)");
    AutoExecConfig_CleanFile();
    AutoExecConfig_ExecuteFile();
}

public void Cubbi_OnLoaded()
{
    if (Cubbi_RegisterFeature(FEATURE_NAME, FEATURE_DESCRIPTION, Core.Level.IntValue, Core.Points.IntValue, Core.Expiration.IntValue, Core.Refundable.BoolValue, Core.Tradable.BoolValue))
    {
        CreateTimer(Core.Interval.FloatValue, Timer_Interval, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
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

public Action Timer_Interval(Handle timer)
{
    for (int client=1; client <= MaxClients; client++)
    {
        if (client && IsClientInGame(client) && Player[client].HasFeature)
        {
            int iMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
            int iOldHP = GetClientHealth(client);
            int iNewHP = iOldHP + Core.HP.IntValue;
            
            if (iNewHP > iMaxHealth)
            {
                if (iOldHP < iMaxHealth) 
                {
                    iNewHP = iMaxHealth;
                }
                else 
                {
                    continue;
                }
            }
            
            SetEntityHealth(client, iNewHP);
        }
    }
    
    return Plugin_Continue;
}
