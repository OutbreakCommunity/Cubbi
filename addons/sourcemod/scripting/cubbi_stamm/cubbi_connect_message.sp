#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>
#include <outbreak>
#include <cubbi>

#define FEATURE_NAME "VIP Connect Message"
#define FEATURE_DESCRIPTION "Get a VIP tagged connect message on each join"

enum struct GlobalData {
    ConVar Level;
    ConVar Points;
    ConVar Expiration;
    ConVar Refundable;
    ConVar Tradable;
}
GlobalData Core;

public Plugin myinfo =
{
    name = "Cubbi - Connect Message",
    author = "Bara (Original author: dordnung)",
    version = "1.0.0",
    description = "",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("cubbi.connect_message");
    Core.Level = AutoExecConfig_CreateConVar("connect_message_level", "5", "Which level is required to bought this feature?");
    Core.Points = AutoExecConfig_CreateConVar("connect_message_points", "200", "How much points are required to bought this feature?");
    Core.Expiration = AutoExecConfig_CreateConVar("connect_message_expiration", "0", "How long (time in minutes) this feature for earch should be exists? 0 - Lifetime");
    Core.Refundable = AutoExecConfig_CreateConVar("connect_message_refundable", "1", "Allow players to refund this feature?", _, true, 0.0, true, 1.0);
    Core.Tradable = AutoExecConfig_CreateConVar("connect_message_tradable", "0", "Allow players to trade this feature to other players or market?", _, true, 0.0, true, 1.0);
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public void Cubbi_OnLoaded()
{
    Cubbi_RegisterFeature(FEATURE_NAME, FEATURE_DESCRIPTION, Core.Level.IntValue, Core.Points.IntValue, Core.Expiration.IntValue, Core.Refundable.BoolValue, Core.Tradable.BoolValue);
}

public Action Event_PlayerConnect(Event event, const char[] event_name, bool dontBroadcast)
{
    event.BroadcastDisabled = true;
    return Plugin_Changed;
}

public Action Event_PlayerDisconnect(Event event, const char[] event_name, bool dontBroadcast)
{
    event.BroadcastDisabled = true;
    return Plugin_Changed;
}

public void Cubbi_OnClientReady(int client, ArrayList features)
{
    if (CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
    {
        return;
    }

    bool bHasFeature = false;

    for (int i = 0; i < features.Length; i++)
    {
        PlayerFeatureData PlayerFeature;
        features.GetArray(i, PlayerFeature, sizeof(PlayerFeature));
        
        if (StrEqual(PlayerFeature.Name, FEATURE_NAME, false))
        {
            bHasFeature = true;
            break;
        }
    }

    if (bHasFeature)
    {
        CPrintToChatAll("{darkred}VIP %s%N %sjoined the server.", SPECIAL, client, TEXT);
    }
    else
    {
        CPrintToChatAll("%s%N %shat das Spiel betreten.", SPECIAL, client, TEXT);
    }
}
