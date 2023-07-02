#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <autoexecconfig>
#include <cubbi>
#include <outbreak>

#define FEATURE_NAME "Clan Tag"
#define FEATURE_DESCRIPTION "Sets a clan tag for you"

enum struct GlobalData {
    ConVar Level;
    ConVar Points;
    ConVar Expiration;
    ConVar Refundable;
    ConVar Tradable;
    ConVar Tag;
    ConVar Admin;
}
GlobalData Core;

enum struct PlayerData {
    bool HasFeature;
}
PlayerData Player[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Cubbi - Clan Tag",
    author = "Bara (Original author: dordnung)",
    version = "1.0.0",
    description = "",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("cubbi.tag");
    Core.Level = AutoExecConfig_CreateConVar("tag_level", "5", "Which level is required to bought this feature?");
    Core.Points = AutoExecConfig_CreateConVar("tag_points", "200", "How much points are required to bought this feature?");
    Core.Expiration = AutoExecConfig_CreateConVar("tag_expiration", "0", "How long (time in minutes) this feature for earch should be exists? 0 - Lifetime");
    Core.Refundable = AutoExecConfig_CreateConVar("tag_refundable", "1", "Allow players to refund this feature?", _, true, 0.0, true, 1.0);
    Core.Tradable = AutoExecConfig_CreateConVar("tag_tradable", "0", "Allow players to trade this feature to other players or market?", _, true, 0.0, true, 1.0);
    Core.Tag = AutoExecConfig_CreateConVar("tag_text", "*CAAINE SUCKT*", "Cubbi/VIP Tag");
    Core.Admin = AutoExecConfig_CreateConVar("tag_admin", "1", "1=Admins get also tag, 0=Off");
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
            SetClientTag(client);
            break;
        }
    }
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    SetClientTag(client);
    
    return Plugin_Continue;
}

public void Cubbi_OnClientPurchase(int client, const char[] name)
{
    SetClientTag(client);
}

void SetClientTag(int client)
{
    char sCurrentTag[MAX_NAME_LENGTH+1];
    char sTag[PLATFORM_MAX_PATH + 1];

    CS_GetClientClanTag(client, sCurrentTag, sizeof(sCurrentTag));
    Core.Tag.GetString(sTag, sizeof(sTag));

    if (!Player[client].HasFeature && StrContains(sCurrentTag, sTag) != -1)
    {
        ReplaceString(sCurrentTag, sizeof(sCurrentTag), sTag, "");
        CS_SetClientClanTag(client, sCurrentTag);

        return;
    }

    if (Player[client].HasFeature) 
    {
        if (Core.Admin.BoolValue || (!Core.Admin.BoolValue && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))) 
        {
            CS_SetClientClanTag(client, sTag);
        }
    }
}
