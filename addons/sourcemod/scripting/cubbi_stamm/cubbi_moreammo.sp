#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <autoexecconfig>
#include <cubbi>

#define MAX_ENTITIES 2048
#define FEATURE_NAME "More Ammo"
#define FEATURE_DESCRIPTION "Gives you few percent more ammo"

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
    name = "Cubbi - More Ammo",
    author = "Bara (Original author: dordnung)",
    version = "1.0.0",
    description = "",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("cubbi.more_ammo");
    Core.Level = AutoExecConfig_CreateConVar("more_ammo_level", "5", "Which level is required to bought this feature?");
    Core.Points = AutoExecConfig_CreateConVar("more_ammo_points", "200", "How much points are required to bought this feature?");
    Core.Expiration = AutoExecConfig_CreateConVar("more_ammo_expiration", "0", "How long (time in minutes) this feature for earch should be exists? 0 - Lifetime");
    Core.Refundable = AutoExecConfig_CreateConVar("more_ammo_refundable", "1", "Allow players to refund this feature?", _, true, 0.0, true, 1.0);
    Core.Tradable = AutoExecConfig_CreateConVar("more_ammo_tradable", "0", "Allow players to trade this feature to other players or market?", _, true, 0.0, true, 1.0);
    Core.Factor = AutoExecConfig_CreateConVar("more_ammo_amount", "20", "Ammo increase in percent");
    AutoExecConfig_CleanFile();
    AutoExecConfig_ExecuteFile();

    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_start", Event_RoundStart);
}

public void Cubbi_OnLoaded()
{
    if (Cubbi_RegisterFeature(FEATURE_NAME, FEATURE_DESCRIPTION, Core.Level.IntValue, Core.Points.IntValue, Core.Expiration.IntValue, Core.Refundable.BoolValue, Core.Tradable.BoolValue))
    {
        CreateTimer(1.0, Timer_CheckWeapons, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    for (int x=0; x < MAX_ENTITIES; x++) 
    {
        Player[client].Weapons[x] = false;
    }

    return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int x=0; x < MAX_ENTITIES; x++)
    {
        for (int i=0; i <= MaxClients; i++) 
        {
            Player[i].Weapons[x] = false;
        }
    }

    return Plugin_Continue;
}

public Action Timer_CheckWeapons(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i && IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT))
        {
            for (int x = 0; x < 2; x++)
            {
                int weapon = GetPlayerWeaponSlot(i, x);

                if (weapon != -1 && !Player[i].Weapons[weapon])
                {
                    int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");

                    if (ammotype != -1)
                    {
                        int cAmmo = GetEntProp(i, Prop_Send, "m_iAmmo", _, ammotype);
                        
                        if (cAmmo > 0)
                        {
                            int newAmmo;
                            
                            newAmmo = RoundToZero(cAmmo + ((float(cAmmo)/100.0) * Core.Factor.IntValue));
                            
                            SetEntProp(i, Prop_Send, "m_iAmmo", newAmmo, _, ammotype);
                            
                            Player[i].Weapons[weapon] = true;
                        }
                    }
                }
            }
        }
    }
    
    return Plugin_Continue;
}
