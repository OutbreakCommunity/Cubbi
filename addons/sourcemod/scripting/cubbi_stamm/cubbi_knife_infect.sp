#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <autoexecconfig>
#include <cubbi>
#include <outbreak>
#include <lastrequest>

#define FEATURE_NAME_HP "Knife Infect - HP"
#define FEATURE_NAME_OVERLAY "Knife Infect - Overlay"
#define FEATURE_DESCRIPTION_HP "Reduce HP over a specific time"
#define FEATURE_DESCRIPTION_OVERLAY "Infected player will see an overlay"

enum struct GlobalData {
    ConVar LevelHP;
    ConVar LevelOverlay;
    ConVar PointsHP;
    ConVar PointsOverlay;
    ConVar ExpirationHP;
    ConVar ExpirationOverlay;
    ConVar RefundableHP;
    ConVar RefundableOverlay;
    ConVar TradableHP;
    ConVar TradableOverlay;
    ConVar Duration;
    ConVar HP;
}
GlobalData Core;

enum struct PlayerData {
    bool HP;
    bool Overlay;
    bool Infected;

    int Timers;

    void Reset() {
        this.HP = false;
        this.Overlay = false;
        this.Infected = false;

        this.Timers = 0;
    }
}
PlayerData Player[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Cubbi - Knife Infect (HP + Overlay)",
    author = "Bara (Original author: dordnung)",
    version = "1.0.0",
    description = "",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("player_spawn", Event_PlayerDeath);

    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("cubbi.knife_infect");
    Core.LevelHP = AutoExecConfig_CreateConVar("knife_infect_level_hp", "5", "[HP] Which level is required to bought this feature?");
    Core.LevelOverlay = AutoExecConfig_CreateConVar("knife_infect_level_overlay", "5", "[Overlay] Which level is required to bought this feature?");
    Core.PointsHP = AutoExecConfig_CreateConVar("knife_infect_points_hp", "200", "[HP] How much points are required to bought this feature?");
    Core.PointsOverlay = AutoExecConfig_CreateConVar("knife_infect_points_overlay", "200", "[Overlay] How much points are required to bought this feature?");
    Core.ExpirationHP = AutoExecConfig_CreateConVar("knife_infect_expiration_hp", "0", "[HP] How long (time in minutes) this feature for earch should be exists? 0 - Lifetime");
    Core.ExpirationOverlay = AutoExecConfig_CreateConVar("knife_infect_expiration_overlay", "0", "[Overlay] How long (time in minutes) this feature for earch should be exists? 0 - Lifetime");
    Core.RefundableHP = AutoExecConfig_CreateConVar("knife_infect_refundable_hp", "1", "[HP] Allow players to refund this feature?", _, true, 0.0, true, 1.0);
    Core.RefundableOverlay = AutoExecConfig_CreateConVar("knife_infect_refundable_overlay", "1", "[Overlay] Allow players to refund this feature?", _, true, 0.0, true, 1.0);
    Core.TradableHP = AutoExecConfig_CreateConVar("knife_infect_tradable_hp", "0", "[HP] Allow players to trade this feature to other players or market?", _, true, 0.0, true, 1.0);
    Core.TradableOverlay = AutoExecConfig_CreateConVar("knife_infect_tradable_overlay", "0", "[Overlay] Allow players to trade this feature to other players or market?", _, true, 0.0, true, 1.0);
    Core.Duration = AutoExecConfig_CreateConVar("knife_infect_duration", "0", "Infect Duration, 0 = Until Next Spawn, x = Time in Seconds");
    Core.HP = AutoExecConfig_CreateConVar("knife_infect_hp", "2", "X HP lose every Second");
    AutoExecConfig_CleanFile();
    AutoExecConfig_ExecuteFile();

    CSetPrefix("{purple}[Cubbi]{default}");
}

public void Cubbi_OnLoaded()
{
    if (
        Cubbi_RegisterFeature(FEATURE_NAME_HP, FEATURE_DESCRIPTION_HP, Core.LevelHP.IntValue, Core.PointsHP.IntValue, Core.ExpirationHP.IntValue, Core.RefundableHP.BoolValue, Core.TradableHP.BoolValue)
            &&
        Cubbi_RegisterFeature(FEATURE_NAME_OVERLAY, FEATURE_DESCRIPTION_OVERLAY, Core.LevelOverlay.IntValue, Core.PointsOverlay.IntValue, Core.ExpirationOverlay.IntValue, Core.RefundableOverlay.BoolValue, Core.TradableOverlay.BoolValue)
        )
    {
        CreateTimer(1.0, Timer_SecondTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

public void Cubbi_OnClientReady(int client, ArrayList features)
{
    for (int i = 0; i < features.Length; i++)
    {
        PlayerFeatureData PlayerFeature;
        features.GetArray(i, PlayerFeature, sizeof(PlayerFeature));
        
        if (StrEqual(PlayerFeature.Name, FEATURE_NAME_HP, false))
        {
            Player[client].HP = true;
        }

        if (StrEqual(PlayerFeature.Name, FEATURE_NAME_OVERLAY, false))
        {
            Player[client].Overlay = true;
        }

        if (Player[client].HP && Player[client].Overlay)
        {
            break;
        }
    }
}

public Action Timer_SecondTimer(Handle timer)
{
    int iHP = Core.HP.IntValue;

    for (int i=1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if (Player[i].Infected)
            {
                if (Core.Duration.IntValue)
                {
                    Player[i].Timers--;
                    
                    if (Player[i].Timers <= 0)
                    {
                        Player[i].Infected = false;
                        ClientCommand(i, "r_screenoverlay \"\"");

                        continue;
                    }
                }

                int iNewHP = GetClientHealth(i) - iHP;
                
                if (iNewHP <= 0)
                {
                    iNewHP = 0;
                    ForcePlayerSuicide(i);
                }
                
                SetEntityHealth(i, iNewHP);
            }
        }
    }
    
    return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (client && IsClientInGame(client) && Player[client].Infected)
    {
        Player[client].Infected = false;
        ClientCommand(client, "r_screenoverlay \"\"");
    }

    return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if (client && IsClientInGame(client) && attacker && IsClientInGame(attacker))
    {
        if (!IsClientInLastRequest(client) && !IsClientInLastRequest(attacker))
        {
            char sWeapon[64];
            GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
            
            if ((StrContains(sWeapon, "knife", false) != -1 || StrContains(sWeapon, "bayonet", false) != -1) && !Player[client].Infected)
            {
                if (Player[attacker].HP || Player[attacker].Overlay)
                {
                    Player[client].Infected = true;
                    
                    if (Player[attacker].Overlay)
                    {
                        ClientCommand(client, "r_drawscreenoverlay 1");
                        ClientCommand(client, "r_screenoverlay effects/nightvision");
                    }
                    
                    if (Core.Duration.IntValue)
                    {
                        if (Player[attacker].HP)
                        {
                            Player[client].Timers = Core.Duration.IntValue;
                        }
    
                        CPrintToChat(client, "You got infected by %s%N%s for %s%d%s seconds", attacker, Core.Duration.IntValue);
                    }
                    else 
                    {
                        CPrintToChat(client, "You got infected by %s%N%s until next spawn", attacker);
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}
