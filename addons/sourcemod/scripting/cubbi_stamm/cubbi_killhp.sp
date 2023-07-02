#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <autoexecconfig>
#include <cubbi>
#include <outbreak>
#include <lastrequest>

#define FEATURE_NAME "HP per Kill"
#define FEATURE_DESCRIPTION "Get for every (non-teamkill) kill few HP back"

enum struct GlobalData {
    ConVar Level;
    ConVar Points;
    ConVar Expiration;
    ConVar Refundable;
    ConVar Tradable;
    ConVar HP;
}
GlobalData Core;

enum struct PlayerData {
    bool HasFeature;
}
PlayerData Player[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Cubbi - Kill HP",
    author = "Bara (Original author: dordnung)",
    version = "1.0.0",
    description = "",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("cubbi.killhp");
    Core.Level = AutoExecConfig_CreateConVar("killhp_level", "5", "Which level is required to bought this feature?");
    Core.Points = AutoExecConfig_CreateConVar("killhp_points", "200", "How much points are required to bought this feature?");
    Core.Expiration = AutoExecConfig_CreateConVar("killhp_expiration", "0", "How long (time in minutes) this feature for earch should be exists? 0 - Lifetime");
    Core.Refundable = AutoExecConfig_CreateConVar("killhp_refundable", "1", "Allow players to refund this feature?", _, true, 0.0, true, 1.0);
    Core.Tradable = AutoExecConfig_CreateConVar("killhp_tradable", "0", "Allow players to trade this feature to other players or market?", _, true, 0.0, true, 1.0);
    Core.HP = AutoExecConfig_CreateConVar("killhp_hp", "5", "HP a VIP gets every kill");
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
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    

    if (client && IsClientInGame(client) && attacker && IsClientInGame(attacker))
    {
        // Give HP to Killer
        if (Player[attacker].HasFeature && !IsClientInLastRequest(attacker))
        {
            int iOldHP = GetClientHealth(attacker);
            int iMaxHP = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");

            if (iOldHP > iMaxHP)
            {
                return Plugin_Continue;
            }

            int iNewHP = iOldHP + Core.HP.IntValue;

            if (iNewHP > iMaxHP)
            {
                iNewHP = iMaxHP;
            }
            
            if (iNewHP < GetClientHealth(attacker))
            {
                return Plugin_Continue;
            }
            
            SetEntityHealth(attacker, iNewHP);
        }
    }

    return Plugin_Continue;
}
