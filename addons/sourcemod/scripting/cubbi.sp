#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <outbreak>
#include <cubbi>
#include <autoexecconfig>

enum struct GlobalData {
    int Month;
    int Year;

    bool HappyHour;
    int HappyHourTime;
    int HappyHourPoints;

    bool Loaded;

    Database Database;

    ConVar NotifyInvalidId;
    ConVar MinPlayers;
    ConVar Interval;
    ConVar MaxLevel;
    ConVar LevelSteps;
    ConVar TopLimit;
    ConVar RefundFees;
    ConVar TradeFees;
    ConVar MarketFees;
    ConVar AuctionFees;

    ArrayList Levels;
    ArrayList Features;

    GlobalForward OnLoaded;
    GlobalForward OnPurchase;
    GlobalForward OnClientReady;

    void ResetHappyHour() {
        this.HappyHour = false;
        this.HappyHourTime = 0;
        this.HappyHourPoints = 0;
    }
}
GlobalData Core;

enum struct PlayerData {
    bool Loaded;
    bool HappyHourTime;
    bool HappyHourPoints;

    int Level;
    int Points;
    int HiddenPoints;

    ArrayList Features;

    void Init(int level, int points, int hidden_points) {
        this.Loaded = true;

        this.Level = level;
        this.Points = points;
        this.HiddenPoints = hidden_points;
    }

    void Reset() {
        this.Loaded = false;
        this.HappyHourTime = false;
        this.HappyHourPoints = false;

        this.Level = 0;
        this.Points = 0;
        this.HiddenPoints = 0;

        delete this.Features;
    }
}
PlayerData Player[MAXPLAYERS + 1];

#include "cubbi/sql.sp"
#include "cubbi/native.sp"
#include "cubbi/command.sp"
#include "cubbi/admin.sp"
#include "cubbi/toplists.sp"
#include "cubbi/shop.sp"
#include "cubbi/feature.sp"
#include "cubbi/refund.sp"
#include "cubbi/happyhour.sp"

public Plugin myinfo = 
{
    name = "Cubbi - Core",
    author = "Bara",
    description = "",
    version = "1.0.0",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    if (!SQL_CheckConfig("cubbi"))
    {
        SetFailState("Can't find an entry in your databases.cfg with the name \"cubbi\"");
        return;
    }

    Database.Connect(OnSQLConnect, "cubbi");

    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("cubbi.core");
    Core.NotifyInvalidId = AutoExecConfig_CreateConVar("cubbi_notify_invalid_id_method", "0", "How player should be notified about invalid id? 0 - Message (3 Sec. Interval), 1 - Kick player", _, true, 0.0, true, 1.0);
    Core.MinPlayers = AutoExecConfig_CreateConVar("cubbi_min_players", "4", "How many players must be online (T+CT)?");
    Core.Interval = AutoExecConfig_CreateConVar("cubbi_interval", "60", "Interval in seconds to get points");
    Core.MaxLevel = AutoExecConfig_CreateConVar("cubbi_max_level", "20", "Set the highest possible level", _, true, 1.0);
    Core.LevelSteps = AutoExecConfig_CreateConVar("cubbi_level_steps", "150", "Define the (hidden-)points between each level", _, true, 1.0);
    Core.TopLimit = AutoExecConfig_CreateConVar("cubbi_top_limit", "25", "Show for each toplist the best X players");
    Core.RefundFees = AutoExecConfig_CreateConVar("cubbi_refund_fees", "15", "How much fees in percent should be removed the original purchase price?");
    Core.TradeFees = AutoExecConfig_CreateConVar("cubbi_trade_fees", "10", "How much fees in percent should be removed the original purchase price?");
    Core.MarketFees = AutoExecConfig_CreateConVar("cubbi_market_fees", "20", "How much fees in percent should be removed the original purchase price?");
    Core.AuctionFees = AutoExecConfig_CreateConVar("cubbi_market_fees", "20", "How much fees in percent should be removed the original purchase price?");
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    CSetPrefix("{purple}[Cubbi]{default}");

    RegConsoleCmd("sm_cubbi", Command_Cubbi);
    RegConsoleCmd("sm_sinfo", Command_Cubbi);

    RegConsoleCmd("sm_points", Command_Points);
    RegConsoleCmd("sm_credits", Command_Points);
    RegConsoleCmd("sm_level", Command_Points);
    RegConsoleCmd("sm_stamm", Command_Points);

    RegConsoleCmd("sm_top", Command_Toplists);
    RegConsoleCmd("sm_rank", Command_Toplists);
    RegConsoleCmd("sm_srank", Command_Toplists);
    RegConsoleCmd("sm_slist", Command_Toplists);

    RegConsoleCmd("sm_shop", Command_Shop);
    RegConsoleCmd("sm_store", Command_Shop);

    RegConsoleCmd("sm_feature", Command_Features);
    RegConsoleCmd("sm_features", Command_Features);
    RegConsoleCmd("sm_item", Command_Features);
    RegConsoleCmd("sm_items", Command_Features);

    RegAdminCmd("sm_addpoints", Command_AddPoints, ADMFLAG_GENERIC);
    RegAdminCmd("sm_setpoints", Command_SetPoints, ADMFLAG_GENERIC);
    RegAdminCmd("sm_delpoints", Command_DelPoints, ADMFLAG_GENERIC);

    RegAdminCmd("sm_cadmin", Command_CAdmin, ADMFLAG_ROOT);
}

public void OnMapStart()
{
    char sBuffer[4];
    FormatTime(sBuffer, sizeof(sBuffer), "%m");
    Core.Month = StringToInt(sBuffer);
    FormatTime(sBuffer, sizeof(sBuffer), "%y");
    Core.Year = StringToInt(sBuffer);
}

public void OnMapEnd()
{
    Core.Loaded = false;
}

public void OnConfigsExecuted()
{
    if (!Core.Loaded && Core.Database != null)
    {
        Call_StartForward(Core.OnLoaded);
        Call_Finish();

        Core.Loaded = true;
    }
}

public void OnClientPutInServer(int client)
{
    LoadClient(client);
}

public void OnClientDisconnect(int client)
{
    if (IsFakeClient(client) || IsClientSourceTV(client))
    {
        return;
    }

    Player[client].Reset();
}

void LoadClient(int client)
{
    if (IsFakeClient(client) || IsClientSourceTV(client))
    {
        return;
    }

    Player[client].Reset();

    char sQuery[256];
    Core.Database.Format(sQuery, sizeof(sQuery), "SELECT level, points, hidden_points FROM players WHERE accountid = %d;", GetSteamAccountID(client));
    Core.Database.Query(SQL_LoadClient, sQuery, GetClientUserId(client));
}

public Action Timer_PlayerTimer(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (!client)
    {
        return Plugin_Stop;
    }

    int iCount = GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T);
    int iRequiredPlayers = Core.MinPlayers.IntValue - iCount;

    if (iRequiredPlayers > 0)
    {
        CPrintToChat(client, "%s%d%s player(s) left to get points.", SPECIAL, Core.MinPlayers.IntValue, TEXT);
        CreateTimer(Core.Interval.FloatValue, Timer_PlayerTimer, userid);
        return Plugin_Stop;
    }

    char sHappyHourPoints[12];
    if (Core.HappyHour)
    {
        if (Core.HappyHourTime >= GetTime())
        {
            FormatEx(sHappyHourPoints, sizeof(sHappyHourPoints), "+ %d", Core.HappyHourPoints);
        }
        else
        {
            Core.HappyHour = false;
            ResetHappyHour(true);
        }
    }

    char sQuery[512];
    Core.Database.Format(sQuery, sizeof(sQuery), "UPDATE players SET name = \"%N\", points = points + 1%s, hidden_points = hidden_points + 1 WHERE accountid = %d;", client, sHappyHourPoints, GetSteamAccountID(client));
    Core.Database.Query(SQL_AddClientPoints, sQuery, GetClientUserId(client));

    Core.Database.Format(sQuery, sizeof(sQuery), "INSERT INTO players_monthly (accountid, month, year, hidden_points) VALUES (%d, %d, %d, 1) ON DUPLICATE KEY UPDATE hidden_points = hidden_points + 1;", GetSteamAccountID(client), Core.Month, Core.Year);
    Core.Database.Query(SQL_AddClientMonthlyPoints, sQuery);

    CreateTimer(Core.Interval.FloatValue, Timer_PlayerTimer, userid);
    return Plugin_Stop;
}

void CheckClientLevel(int client)
{
    int iLevel = 0;

    for (int i = 0; i < Core.Levels.Length; i++)
    {
        int iPoints = Core.Levels.Get(i);

        if (Player[client].HiddenPoints >= iPoints) // TODO Do we need this if statement?
        {
            iLevel = i + 1;
        }
        else if (Player[client].HiddenPoints < iPoints)
        {
            iLevel = i;
            break;
        }
    }

    if (iLevel != Player[client].Level)
    {
        Player[client].Level = iLevel;

        CPrintToChat(client, "You are now on level %s%d%s", SPECIAL, Player[client].Level, TEXT);

        char sQuery[256];
        Core.Database.Format(sQuery, sizeof(sQuery), "UPDATE players SET level = %d WHERE accountid = %d", Player[client].Level, GetSteamAccountID(client));
        Core.Database.Query(SQL_UpdateClientLevel, sQuery);
    }
}

void UpdateClientPoints(int client)
{
    char sQuery[256];
    Core.Database.Format(sQuery, sizeof(sQuery), "UPDATE players SET points = %d WHERE accountid = %d;", Player[client].Points, GetSteamAccountID(client));
    Core.Database.Query(SQL_UpdateClientPoints, sQuery, GetClientUserId(client));
}

void LoadLevels()
{
    delete Core.Levels;
    Core.Levels = new ArrayList();

    for (int i = 1; i <= Core.MaxLevel.IntValue; i++)
    {
        Core.Levels.Push(i * Core.LevelSteps.IntValue);
    }

    LoadFeatures();
}

void LoadFeatures()
{
    if (Core.Features == null)
    {
        Core.Features = new ArrayList(sizeof(FeatureData));
    }

    Call_StartForward(Core.OnLoaded);
    Call_Finish();

    Core.Loaded = true;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || IsClientSourceTV(i))
        {
            continue;
        }

        LoadClient(i);
    }
}

void ShowMainMenu(int client)
{
    Menu menu = new Menu(Menu_MainMenu);
    
    char sTitle[256];

    FormatEx(sTitle, sizeof(sTitle), "Cubbi Main Menu\n \nPoints: %d\nHidden-Points: %d\nLevel: %d \n ", Player[client].Points, Player[client].HiddenPoints, Player[client].Level);
    menu.SetTitle(sTitle);
    
    menu.AddItem("top", "Toplists");

    char sBuffer[64];
    FormatEx(sBuffer, sizeof(sBuffer), "Shop%s", (Core.Features == null || Core.Features.Length < 1) ? " (No features)" : "");
    menu.AddItem("shop", sBuffer, (Core.Features == null || Core.Features.Length < 1) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

    FormatEx(sBuffer, sizeof(sBuffer), "Your Features%s", (Player[client].Features == null || Player[client].Features.Length < 1) ? " (No features)" : "");
    menu.AddItem("features", sBuffer, (Player[client].Features == null || Player[client].Features.Length < 1) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

    menu.ExitBackButton = false;
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_MainMenu(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[12];
        menu.GetItem(param, sParam, sizeof(sParam));

        if (StrEqual(sParam, "top", false))
        {
            ShowTopMainMenu(client);
        }
        else if (StrEqual(sParam, "shop", false))
        {
            ShowShopMainMenu(client);
        }
        else if (StrEqual(sParam, "features", false))
        {
            ShowFeaturesMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}

void LoadClientFeatures(int client)
{
    char sQuery[512];
    // TODO: Add Expiration support
    Core.Database.Format(sQuery, sizeof(sQuery), "SELECT id, feature, price, purchased_date, expiration_date, refundable, tradable FROM purchased_features WHERE accountid = %d AND refunded = 0;", GetSteamAccountID(client));
    Core.Database.Query(SQL_LoadClientFeatures, sQuery, GetClientUserId(client));
}

public Action Timer_CheckSteamId(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (!client)
    {
        return Plugin_Stop;
    }

    NotifyClientInvalidId(client);
    CreateTimer(3.0, Timer_CheckSteamId, GetClientUserId(client));

    return Plugin_Stop;
}

void NotifyClientInvalidId(int client)
{
    if (!Core.NotifyInvalidId.BoolValue)
    {
        CPrintToChat(client, "We can't validate your steam account id. %sPlease rejoin the server.", SPECIAL);
    }
    else
    {
        KickClient(client, "We couldn't validate your steam account id. Please rejoin the server.");
    }
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if (!client)
    {
        return Plugin_Continue;
    }

    if (Player[client].HappyHourTime)
    {
        if (!IsStringNumeric(sArgs))
        {
            CPrintToChat(client, "Your entered value \"%s%s%s\" was not valid. Process aborted!", SPECIAL, sArgs, TEXT);

            Core.ResetHappyHour();
            Player[client].HappyHourTime = false;

            return Plugin_Handled;
        }

        Core.HappyHourTime = StringToInt(sArgs);
        Player[client].HappyHourTime = false;

        CPrintToChat(client, "Type happy hour %show much additional points %sin the chat.", SPECIAL, TEXT);
        Player[client].HappyHourPoints = true;
        
        return Plugin_Handled;
    }

    if (Player[client].HappyHourPoints)
    {
        if (!IsStringNumeric(sArgs))
        {
            CPrintToChat(client, "Your entered value \"%s%s%s\" was not valid. Process aborted!", SPECIAL, sArgs, TEXT);

            Core.ResetHappyHour();
            Player[client].HappyHourPoints = false;

            return Plugin_Handled;
        }

        Core.HappyHourPoints = StringToInt(sArgs);
        Player[client].HappyHourPoints = false;

        ConfirmHappyHourSettings(client);
        
        return Plugin_Handled;
    }

    return Plugin_Continue;
}
