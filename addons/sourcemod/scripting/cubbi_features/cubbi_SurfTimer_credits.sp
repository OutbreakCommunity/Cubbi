#include <sourcemod>
#include <multicolors>
#include <sdktools>
#include <cstrike>
#include <surftimer>
#include <cubbi>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

bool mapFinished[MAXPLAYERS + 1] = { false, ... };
bool bonusFinished[MAXPLAYERS + 1] = { false, ... };
bool practiceFinished[MAXPLAYERS + 1] = { false, ... };

char g_sTag[32];
ConVar gc_sTag;

Handle g_hCreditsNormal = INVALID_HANDLE;
Handle g_hCreditsBonus = INVALID_HANDLE;
Handle g_hCreditsPractice = INVALID_HANDLE;
Handle g_hCreditsNormalAfterCompletion = INVALID_HANDLE;
Handle g_hCreditsBonusAfterCompletion = INVALID_HANDLE;
Handle g_hCreditsPracticeAfterCompletion = INVALID_HANDLE;

int g_CreditsNormal, g_CreditsBonus, g_CreditsPractice, g_CreditsNormalAfterCompletion, g_CreditsBonusAfterCompletion, g_CreditsPracticeAfterCompletion;

public Plugin myinfo =
{
	name = "SurfTimer - Credits/points",
	author = "Simon, Cruze, Caaine",
	description = "Give credits on completion.",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_hCreditsNormal = CreateConVar("zeph_surf_normal", "50", "Credits given when a player finishes a map.");
	g_hCreditsBonus = CreateConVar("zeph_surf_bonus", "100", "Credits given when a player finishes a bonus.");
	g_hCreditsPractice = CreateConVar("zeph_surf_practice", "25", "Credits given when a player finishes a map in practice mode.");
	g_hCreditsNormalAfterCompletion = CreateConVar("zeph_surf_normal_again", "20", "Credits given when a player finishes a map again.");
	g_hCreditsBonusAfterCompletion = CreateConVar("zeph_surf_bonus_again", "50", "Credits given when a player finishes a bonus again.");
	g_hCreditsPracticeAfterCompletion = CreateConVar("zeph_surf_practice_again", "5", "Credits given when a player finishes a map in practice mode again.");
	
	HookConVarChange(g_hCreditsNormal, OnConVarChanged);
	HookConVarChange(g_hCreditsBonus, OnConVarChanged);
	HookConVarChange(g_hCreditsPractice, OnConVarChanged);
	HookConVarChange(g_hCreditsNormalAfterCompletion, OnConVarChanged);
	HookConVarChange(g_hCreditsBonusAfterCompletion, OnConVarChanged);
	HookConVarChange(g_hCreditsPracticeAfterCompletion, OnConVarChanged);
	
	AutoExecConfig(true, "surftimer_credits");
	LoadTranslations("surftimer_credits.phrases");
}

public int OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCreditsNormal)
	{
		g_CreditsNormal = StringToInt(newValue);
	}
	else if (convar == g_hCreditsBonus)
	{
		g_CreditsBonus = StringToInt(newValue);
	}
	else if (convar == g_hCreditsPractice)
	{
		g_CreditsPractice = StringToInt(newValue);
	}
	else if (convar == g_hCreditsNormalAfterCompletion)
	{
		g_CreditsNormalAfterCompletion = StringToInt(newValue);
	}
	else if (convar == g_hCreditsBonusAfterCompletion)
	{
		g_CreditsBonusAfterCompletion = StringToInt(newValue);
	}
	else if (convar == g_hCreditsPracticeAfterCompletion)
	{
		g_CreditsPracticeAfterCompletion = StringToInt(newValue);
	}

	return 0;
}

public void OnConfigsExecuted()
{
	g_CreditsNormal = GetConVarInt(g_hCreditsNormal);
	g_CreditsBonus = GetConVarInt(g_hCreditsBonus);
	g_CreditsPractice = GetConVarInt(g_hCreditsPractice);
	g_CreditsNormalAfterCompletion = GetConVarInt(g_hCreditsNormalAfterCompletion);
	g_CreditsBonusAfterCompletion = GetConVarInt(g_hCreditsBonusAfterCompletion);
	g_CreditsPracticeAfterCompletion = GetConVarInt(g_hCreditsPracticeAfterCompletion);
	
	gc_sTag = FindConVar("ck_chat_prefix");
	gc_sTag.GetString(g_sTag, sizeof(g_sTag));
	
}

public void OnMapStart()
{
	for(int i = 1; i < MaxClients; i++)
	{
		mapFinished[i] = false;
		bonusFinished[i] = false;
		practiceFinished[i] = false;
	}
}

public Action surftimer_OnMapFinished(int client, float fRunTime, char sRunTime[54], float PBDiff, float WRDiff, int rank, int total, int style)
{
	if(!mapFinished[client])
	{
		CPrintToChat(client, "%t", "OnMapFinished", g_sTag, g_CreditsNormal);
		Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + g_CreditsNormal);
		mapFinished[client] = true;
	}
	else
	{
		CPrintToChat(client, "%t", "OnMapFinishedAgain", g_sTag, g_CreditsNormalAfterCompletion);
		Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + g_CreditsNormalAfterCompletion);
	}

	return Plugin_Continue;
}

public Action surftimer_OnBonusFinished(int client, float fRunTime, char sRunTime[54], float fPBDiff, float fSRDiff, int rank, int total, int bonusid, int style)
{
	if(!bonusFinished[client])
	{
		CPrintToChat(client, "%t", "OnBonusFinished", g_sTag, g_CreditsBonus);
		Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + g_CreditsBonus);
		bonusFinished[client] = true;
	}
	else
	{
		CPrintToChat(client, "%t", "OnBonusFinishedAgain", g_sTag, g_CreditsBonusAfterCompletion);
		Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + g_CreditsBonusAfterCompletion);
	}

	return Plugin_Continue;
}

public Action surftimer_OnPracticeFinished(int client, float fRunTime, char sRunTime[54])
{
	if(!practiceFinished[client])
	{
		CPrintToChat(client, "%t", "OnPracticeFinished", g_sTag, g_CreditsPractice);
		Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + g_CreditsPractice);
		practiceFinished[client] = true;
	}
	else
	{
		CPrintToChat(client, "%t", "On PracticeFinishedAgain", g_sTag, g_CreditsPracticeAfterCompletion);
		Cubbi_SetClientPoints(client, Cubbi_GetClientPoints(client) + g_CreditsPracticeAfterCompletion);
	}

	return Plugin_Continue;
}
