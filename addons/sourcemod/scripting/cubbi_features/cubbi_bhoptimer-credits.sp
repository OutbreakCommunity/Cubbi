#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>
#include <cubbi>
#include <shavit>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.4.7"
chatstrings_t gS_ChatStrings;

public Plugin myinfo = 
{
    name = "[shavit] Points | Cubbi", 
    author = "SaengerItsWar", 
    description = "Gives Cubbi Points for records", 
    version = PLUGIN_VERSION, 
    url = "https://github.com/saengeritswar/shavit-credits/"
}

// convars
ConVar g_cvNormalEnabled;
ConVar g_cvWREnabled;
ConVar g_cvEnabledPb;
ConVar g_cvT1Enabled;
ConVar g_cvNormalAmount;
ConVar g_cvNormalAmountAgain;
ConVar g_cvWrAmount;
ConVar g_cvWrAmountAgain;
ConVar g_cvPBAmount;
ConVar g_cvPBAmountAgain;
ConVar g_cvBNormalEnabled;
ConVar g_cvBWREnabled;
ConVar g_cvEnabledBPb;
ConVar g_cvNormalBAmount;
ConVar g_cvNormalBAmountAgain;
ConVar g_cvWrBAmount;
ConVar g_cvWrBAmountAgain;
ConVar g_cvBPbAmount;
ConVar g_cvBPbAmountAgain;
ConVar g_cvTasEnabled;
ConVar g_cvNewCalc;

//globals
char g_cMap[160];
int g_iTier;
int g_iStyle[MAXPLAYERS + 1];
float g_fPB[MAXPLAYERS + 1];
int g_iCompletions[MAXPLAYERS + 1];

public void OnAllPluginsLoaded()
{
    if (!LibraryExists("store_zephyrus"))
    {
        SetFailState("Zephyrus store is required for the plugin to work.");
    }
    else if (!LibraryExists("shavit-wr"))
    {
        SetFailState("Shavit WR is required for the plugin to work.");
    }
    else if (!LibraryExists("shavit-rankings"))
    {
        SetFailState("Shavit Rankings is required for the plugin to work.");
    }
}

public void OnPluginStart()
{
    LoadTranslations("shavit-credits.phrases");
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("shavit-credits");
    g_cvNormalEnabled = AutoExecConfig_CreateConVar("credits_enable_normal", "1", "Enable Store credits given for finishing a map?", 0, true, 0.0, true, 1.0);
    g_cvWREnabled = AutoExecConfig_CreateConVar("credits_enable_wr", "1", "Enable Store credits given for greaking the map Record?", 0, true, 0.0, true, 1.0);
    g_cvEnabledPb = AutoExecConfig_CreateConVar("credits_enable_pb", "1", "Enable Store credits given for breaking the map Personal Best?", 0, true, 0.0, true, 1.0);
    g_cvT1Enabled = AutoExecConfig_CreateConVar("credits_enable_t1", "0", "Enable/Disable given credits for Tier 1. This has no effect on WRs and PBs!", 0, true, 0.0, true, 1.0);
    g_cvNormalAmount = AutoExecConfig_CreateConVar("credits_amount_normal", "10.0", "How many points should be given for finishing a Map?(will be claculated per Tier(amount_normal*Tier))", 0, true, 1.0, false);
    g_cvNormalAmountAgain = AutoExecConfig_CreateConVar("credits_amount_normal_again", "5.0", "How many points should be given for finishing a Map Again?(will be claculated per Tier(amount_normal*Tier))", 0, true, 1.0, false);
    g_cvWrAmount = AutoExecConfig_CreateConVar("credits_amount_wr", "25.0", "How many points should be given for breaking a Map record?(will be calculated per Tier(amount_wr*Tier))", 0, true, 1.0, false);
    g_cvWrAmountAgain = AutoExecConfig_CreateConVar("credits_amount_wr_again", "12.0", "How many points should be given for breaking a Map record Again?(will be calculated per Tier(amount_wr*Tier))", 0, true, 1.0, false);
    g_cvPBAmount = AutoExecConfig_CreateConVar("credits_amount_pb", "10.0", "How many point should be given for breaking the own Personal Best?(will be calculated per Tier(amount_pb*Tier))", 0, true, 1.0, false);
    g_cvPBAmountAgain = AutoExecConfig_CreateConVar("credits_amount_pb_again", "5.0", "How many point should be given for breaking the own Personal Best Again?(will be calculated per Tier(amount_pb*Tier))", 0, true, 1.0, false);
    g_cvBNormalEnabled = AutoExecConfig_CreateConVar("credits_enable_normal_bonus", "0", "Enable Store credits given for finishing a map?", 0, true, 0.0, true, 1.0);
    g_cvBWREnabled = AutoExecConfig_CreateConVar("credits_enable_wr_bonus", "0", "Enable Store credits given for greaking the map Record?", 0, true, 0.0, true, 1.0);
    g_cvEnabledBPb = AutoExecConfig_CreateConVar("credits_enable_pb_bonus", "0", "Enable Store credits given for breaking the map Personal Best?", 0, true, 0.0, true, 1.0);
    g_cvNormalBAmount = AutoExecConfig_CreateConVar("credits_amount_normal_bonus", "10.0", "How many points should be given for finishing a Map?", 0, true, 1.0, false);
    g_cvNormalBAmountAgain = AutoExecConfig_CreateConVar("credits_amount_normal_bonus_again", "5.0", "How many points should be given for finishing a Map Again?", 0, true, 1.0, false);
    g_cvWrBAmount = AutoExecConfig_CreateConVar("credits_amount_wr_bonus", "25.0", "How many points should be given for breaking a Map record?", 0, true, 1.0, false);
    g_cvWrBAmountAgain = AutoExecConfig_CreateConVar("credits_amount_wr_bonus_again", "12.0", "How many points should be given for breaking a Map record Again?", 0, true, 1.0, false);
    g_cvBPbAmount = AutoExecConfig_CreateConVar("credits_amount_pb_bonus", "10.0", "How many point should be given for breaking the own Personal Best?", 0, true, 1.0, false);
    g_cvBPbAmountAgain = AutoExecConfig_CreateConVar("credits_amount_pb_bonus_again", "5.0", "How many point should be given for breaking the own Personal Best Again?", 0, true, 1.0, false);
    g_cvTasEnabled = AutoExecConfig_CreateConVar("credits_tas_enabled", "0", "Enable Store Credits for a TAS Style?", 0, true, 0.0, true, 1.0);
    g_cvNewCalc = AutoExecConfig_CreateConVar("credits_new_calculation", "1", "Enable the New Calculation for the credits?", 0, true, 0.0, true, 1.0);
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}


public void OnMapStart()
{
    GetCurrentMap(g_cMap, sizeof(g_cMap));
    GetMapDisplayName(g_cMap, g_cMap, sizeof(g_cMap));
    g_iTier = Shavit_GetMapTier(g_cMap);
}

public void Shavit_OnChatConfigLoaded()
{
    Shavit_GetChatStrings(sMessagePrefix, gS_ChatStrings.sPrefix, sizeof(chatstrings_t::sPrefix));
    Shavit_GetChatStrings(sMessageText, gS_ChatStrings.sText, sizeof(chatstrings_t::sText));
    Shavit_GetChatStrings(sMessageWarning, gS_ChatStrings.sWarning, sizeof(chatstrings_t::sWarning));
    Shavit_GetChatStrings(sMessageVariable, gS_ChatStrings.sVariable, sizeof(chatstrings_t::sVariable));
    Shavit_GetChatStrings(sMessageVariable2, gS_ChatStrings.sVariable2, sizeof(chatstrings_t::sVariable2));
    Shavit_GetChatStrings(sMessageStyle, gS_ChatStrings.sStyle, sizeof(chatstrings_t::sStyle));
}

public void Shavit_OnTierAssigned(const char[] map, int tier)
{
    g_iTier = tier;
}

public void Shavit_OnLeaveZone(int client, int zone, int track, int id, int entity)
{
    if (IsClientInGame(client) && IsFakeClient(client))
        return;
        
    if (zone == Zone_Start) {
        g_iStyle[client] = Shavit_GetBhopStyle(client);
        g_fPB[client] = Shavit_GetClientPB(client, g_iStyle[client], track);
        g_iCompletions[client] = Shavit_GetClientCompletions(client, g_iStyle[client], track);
    }
}

public void Shavit_OnFinish(int client, int style, float time, int jumps, int strafes, float sync, int track)
{
    char sStyleSpecialString[sizeof(stylestrings_t::sSpecialString)];
    Shavit_GetStyleStrings(style, sSpecialString, sStyleSpecialString, sizeof(sStyleSpecialString));
    
    if (StrContains(sStyleSpecialString, "segments") != -1 || Shavit_GetStyleSettingBool(style,"unranked") == true || Shavit_IsPracticeMode(client) == true)
        return;
    
    if (!g_cvTasEnabled.BoolValue)
        if (StrContains(sStyleSpecialString, "tas") != -1)
            return;
    
    if (g_cvNormalEnabled.BoolValue == true)
    {
        if (g_cvT1Enabled.BoolValue == true || g_iTier != 1)
        {
            
            if (track == Track_Main)
            {
                if (g_iCompletions[client] == 0)
                {
                    int iCredits;
                    
                    if (g_cvNewCalc.BoolValue == true)
                    {
                        iCredits = CalculatePoints(g_cvNormalAmount.IntValue, style);
                    }
                    else
                    {
                        iCredits = g_cvNormalAmount.IntValue * g_iTier;
                    }
                    Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                    
                    Shavit_PrintToChat(client, "%t", "NormalFinish", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
                }
                else if (g_iCompletions[client] >=1)
                {
                    int iCredits;
                    
                    if (g_cvNewCalc.BoolValue == true)
                    {
                        iCredits = CalculatePoints(g_cvNormalAmountAgain.IntValue, style);
                    }
                    else
                    {
                        iCredits = g_cvNormalAmountAgain.IntValue * g_iTier;
                    }
                    Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                    
                    Shavit_PrintToChat(client, "%t", "NormalFinishAgain", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
                }
            }
        }
    }
    
    if (g_cvBNormalEnabled.BoolValue == true)
    {
        if (track == Track_Bonus)
        {
            if (g_iCompletions[client] == 0)
            {
                int iCredits;
                if (g_cvNewCalc.BoolValue == true)
                {
                    iCredits = CalculatePointsBonus(g_cvNormalBAmount.IntValue, style);
                }
                else
                {
                        iCredits = g_cvNormalBAmount.IntValue;
                }
                
                Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                Shavit_PrintToChat(client, "%t", "NormalBonusFinish", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
            }
            else if (g_iCompletions[client] >=1)
            {
                int iCredits;
                if (g_cvNewCalc.BoolValue == true)
                {
                    iCredits = CalculatePointsBonus(g_cvNormalBAmountAgain.IntValue, style);
                }
                else
                {
                    iCredits = g_cvNormalBAmountAgain.IntValue;
                }
                
                Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                Shavit_PrintToChat(client, "%t", "NormalBonusFinishAgain", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
            }
        }
    }
    
    if (g_cvEnabledPb.BoolValue == true)
    {
        if (time < g_fPB[client])
        {
            if (track == Track_Main)
            {
                if (g_iCompletions[client] == 0)
                {
                    int iCredits;
                    if (g_cvNewCalc.BoolValue == true)
                    {
                        iCredits = CalculatePoints(g_cvPBAmount.IntValue, style);
                    }
                    else
                    {
                        iCredits = g_cvPBAmount.IntValue * g_iTier;
                    }
                    
                    Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                    Shavit_PrintToChat(client, "%t", "PersonalBest", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
                }
                else if (g_iCompletions[client] >=1)
                {
                    int iCredits;
                    if (g_cvNewCalc.BoolValue == true)
                    {
                        iCredits = CalculatePoints(g_cvPBAmountAgain.IntValue, style);
                    }
                    else
                    {
                        iCredits = g_cvPBAmountAgain.IntValue * g_iTier;
                    }
                    
                    Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                    Shavit_PrintToChat(client, "%t", "PersonalBestAgain", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
                }
            }
        }
    }
    
    if (g_cvEnabledBPb.BoolValue == true)
    {
        if (time < g_fPB[client])
        {
            if (track == Track_Bonus)
            {
                if (g_iCompletions[client] == 0)
                {
                    int iCredits;
                    if (g_cvNewCalc.BoolValue == true)
                    {
                        iCredits = CalculatePointsBonus(g_cvBPbAmount.IntValue, style);
                    }
                    else
                    {
                        iCredits = g_cvBPbAmount.IntValue;
                    }
                    
                    Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                    Shavit_PrintToChat(client, "%t", "BonusPersonalBest", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
                }
                else if (g_iCompletions[client] >=1)
                {
                    int iCredits;
                    if (g_cvNewCalc.BoolValue == true)
                    {
                        iCredits = CalculatePointsBonus(g_cvBPbAmountAgain.IntValue, style);
                    }
                    else
                    {
                        iCredits = g_cvBPbAmountAgain.IntValue;
                    }
                    
                    Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                    Shavit_PrintToChat(client, "%t", "BonusPersonalBestAgain", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
                }
            }
        }
    }
}

public void Shavit_OnWorldRecord(int client, int style, float time, int jumps, int strafes, float sync, int track)
{
    char sStyleSpecialString[sizeof(stylestrings_t::sSpecialString)];
    Shavit_GetStyleStrings(style, sSpecialString, sStyleSpecialString, sizeof(sStyleSpecialString));
    
    if (StrContains(sStyleSpecialString, "segments") != -1 || Shavit_GetStyleSettingBool(style, "unranked") == true || Shavit_IsPracticeMode(client) == true)
        return;
    
    if (!g_cvTasEnabled.BoolValue)
        if (StrContains(sStyleSpecialString, "tas") != -1)
            return;
    
    if (g_cvWREnabled.BoolValue == true)
    {
        if (track == Track_Main)
        {
            if (g_iCompletions[client] == 0)
            {
                int iCredits;
                if (g_cvNewCalc.BoolValue == true)
                {
                    iCredits = CalculatePoints(g_cvWrAmount.IntValue, style);
                }
                else
                {
                    iCredits = g_cvWrAmount.IntValue * g_iTier;
                }
                
                Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                Shavit_PrintToChat(client, "%t", "WorldRecord", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
            }
            else if (g_iCompletions[client] >=1)
            {
                int iCredits;
                if (g_cvNewCalc.BoolValue == true)
                {
                    iCredits = CalculatePoints(g_cvWrAmountAgain.IntValue, style);
                }
                else
                {
                    iCredits = g_cvWrAmountAgain.IntValue * g_iTier;
                }
                
                Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                Shavit_PrintToChat(client, "%t", "WorldRecordAgain", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
            }
        }
    }
    
    if (g_cvBWREnabled.BoolValue == true)
    {
        if (track == Track_Bonus)
        {
            if (g_iCompletions[client] == 0)
            {
                int iCredits;
                if (g_cvNewCalc.BoolValue == true)
                {
                    iCredits = CalculatePointsBonus(g_cvWrBAmount.IntValue, style);
                }
                else
                {
                    iCredits = g_cvWrBAmount.IntValue;
                }
                
                Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                
                Shavit_PrintToChat(client, "%t", "BonusWorldRecord", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
            }
            else if (g_iCompletions[client] >=1)
            {
                int iCredits;
                if (g_cvNewCalc.BoolValue == true)
                {
                    iCredits = CalculatePointsBonus(g_cvWrBAmountAgain.IntValue, style);
                }
                else
                {
                    iCredits = g_cvWrBAmountAgain.IntValue;
                }
                
                Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + iCredits);
                
                Shavit_PrintToChat(client, "%t", "BonusWorldRecordAgain", gS_ChatStrings.sVariable, iCredits, gS_ChatStrings.sText);
            }
        }
    }
}

public int CalculatePoints(int cvAmount, int style)
{
    float fResult = (cvAmount * g_iTier) * Shavit_GetStyleSettingFloat(style, "rankingmultiplier");
    int iRoundResult = RoundFloat(fResult);
    return iRoundResult;
}

public int CalculatePointsBonus(int cvAmount, int style)
{
    float fResult = cvAmount * Shavit_GetStyleSettingFloat(style, "rankingmultiplier");
    int iRoundResult = RoundFloat(fResult);
    return iRoundResult;
}