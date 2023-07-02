
public void OnSQLConnect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        SetFailState("(OnSQLConnect) Can't connect to mysql");
        return;
    }
    
    Core.Database = db;

    CreateTables();
}

void CreateTables()
{
    char sQuery[1024];
    Core.Database.Format(sQuery, sizeof(sQuery),
        "CREATE TABLE IF NOT EXISTS `players` ( \
            `accountid` INT NOT NULL, \
            `name` VARCHAR(%d) NOT NULL, \
            `level` TINYINT NOT NULL, \
            `points` INT NOT NULL, \
            `hidden_points` INT NOT NULL, \
            PRIMARY KEY (`accountid`) \
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;", MAX_NAME_LENGTH);
    Core.Database.Query(SQL_CreatePlayersTable, sQuery);
}

public void SQL_CreatePlayersTable(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_CreatePlayersTable) Fail at Query: %s", error);
        return;
    }

    char sQuery[1024];
    Core.Database.Format(sQuery, sizeof(sQuery),
        "CREATE TABLE IF NOT EXISTS `purchased_features` ( \
            `id` INT NOT NULL AUTO_INCREMENT, \
            `accountid` INT NOT NULL, \
            `feature` VARCHAR(64) NOT NULL, \
            `price` INT NOT NULL, \
            `purchased_date` INT NOT NULL, \
            `expiration_date` INT NOT NULL, \
            `expired` TINYINT NULL, \
            `refundable` TINYINT NOT NULL, \
            `refunded` TINYINT NOT NULL, \
            `refunded_date` INT NULL, \
            `refunded_points` INT NULL, \
            `tradable` TINYINT NOT NULL, \
            PRIMARY KEY (`id`) \
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    Core.Database.Query(SQL_CreatePurchasedFeaturesTable, sQuery);
}

public void SQL_CreatePurchasedFeaturesTable(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_CreatePurchasedFeaturesTable) Fail at Query: %s", error);
        return;
    }

    char sQuery[1024];
    Core.Database.Format(sQuery, sizeof(sQuery),
        "CREATE TABLE IF NOT EXISTS `monthly_players` ( \
            `accountid` INT NOT NULL, \
            `month` TINYINT NOT NULL, \
            `year` TINYINT NOT NULL, \
            `hidden_points` INT NOT NULL, \
            PRIMARY KEY (`accountid`) \
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    Core.Database.Query(SQL_CreateMonthlyPlayers, sQuery);
}

public void SQL_CreateMonthlyPlayers(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_CreateMonthlyPlayers) Fail at Query: %s", error);
        return;
    }

    char sQuery[1024];
    Core.Database.Format(sQuery, sizeof(sQuery),
        "CREATE TABLE IF NOT EXISTS `feature_logs` ( \
            `featureid` INT NOT NULL, \
            `accountid` INT NOT NULL, \
            `date` INT NOT NULL, \
            `action` ENUM('purchased', 'refund', 'trade', 'market', 'auction'), \
            `price` INT NULL, \
            `fees` INT NULL, \
            `points` INT NULL, \
            `targetid` INT NULL \
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    Core.Database.Query(SQL_CreateFeatureLogsTable, sQuery);
}

public void SQL_CreateFeatureLogsTable(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_CreateFeatureLogsTable) Fail at Query: %s", error);
        return;
    }

    LoadLevels();
}

public void SQL_LoadClient(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_LoadClient) Fail at Query: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!client)
    {
        return;
    }

    if (GetSteamAccountID(client) == 0)
    {
        NotifyClientInvalidId(client);
        CreateTimer(3.0, Timer_CheckSteamId, GetClientUserId(client));
        return;
    }

    if (results.RowCount > 0 && results.FetchRow())
    {
        Player[client].Init(results.FetchInt(0), results.FetchInt(1), results.FetchInt(2));
        
        CPrintToChat(client, "Your data has been loaded!");
        CreateTimer(Core.Interval.FloatValue, Timer_PlayerTimer, GetClientUserId(client));
        
        LoadClientFeatures(client);

        return;
    }

    CPrintToChat(client, "No data found... let me create your sql entry.");

    char sQuery[512];
    Core.Database.Format(sQuery, sizeof(sQuery), "INSERT INTO players (accountid, name, level, points, hidden_points) VALUES (%d, \"%N\", 0, 0, 0);", GetSteamAccountID(client), client);
    Core.Database.Query(SQL_InsertPlayer, sQuery, GetClientUserId(client));
}

public void SQL_InsertPlayer(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_InsertPlayer) Fail at Query: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!client)
    {
        return;
    }

    LoadClient(client);
}

public void SQL_AddClientPoints(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_AddClientPoints) Fail at Query: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!client)
    {
        return;
    }

    Player[client].Points++;
    Player[client].HiddenPoints++;

    CPrintToChat(client, "You have now %s%d%s points and %s%d%s hidden points.", SPECIAL, Player[client].Points, TEXT, SPECIAL, Player[client].HiddenPoints, TEXT);

    CheckClientLevel(client);
}

public void SQL_AddClientMonthlyPoints(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_AddClientMonthlyPoints) Fail at Query: %s", error);
        return;
    }
}

public void SQL_UpdateClientLevel(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_UpdateClientLevel) Fail at Query: %s", error);
        return;
    }
}

public void SQL_UpdateClientPoints(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_UpdateClientPoints) Fail at Query: %s", error);
        return;
    }
}

public void SQL_UpdateClientFeature(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_UpdateClientFeature) Fail at Query: %s", error);
        return;
    }
}

public void SQL_ShowMostPointsMenu(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_ShowMostPointsMenu) Fail at Query: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!client)
    {
        return;
    }

    Menu menu = new Menu(Menu_ShowMostPointsMenu);
    
    char sTitle[42];
    FormatEx(sTitle, sizeof(sTitle), "Top %d - Most Points\n ", Core.TopLimit.IntValue);
    menu.SetTitle(sTitle);

    while (results.FetchRow())
    {
        char sName[MAX_NAME_LENGTH];
        results.FetchString(0, sName, sizeof(sName));

        int iPoints = results.FetchInt(1);

        char sItem[256];
        FormatEx(sItem, sizeof(sItem), "Points %d - %s", iPoints, sName);
        menu.AddItem("", sItem, ITEMDRAW_DISABLED);
    }

    menu.ExitBackButton = true;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public void SQL_ShowHighestLevelMenu(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_ShowHighestLevelMenu) Fail at Query: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!client)
    {
        return;
    }

    Menu menu = new Menu(Menu_ShowHighestLevelMenu);
    
    char sTitle[42];
    FormatEx(sTitle, sizeof(sTitle), "Top %d - Highest Level\n ", Core.TopLimit.IntValue);
    menu.SetTitle(sTitle);

    while (results.FetchRow())
    {
        char sName[MAX_NAME_LENGTH];
        results.FetchString(0, sName, sizeof(sName));

        int ilevel = results.FetchInt(1);

        char sItem[256];
        FormatEx(sItem, sizeof(sItem), "Level: %d - %s", ilevel, sName);
        menu.AddItem("", sItem, ITEMDRAW_DISABLED);
    }

    menu.ExitBackButton = true;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public void SQL_ShowMonthlyMonthsMenu(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_ShowMonthlyMonthsMenu) Fail at Query: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!client)
    {
        return;
    }

    Menu menu = new Menu(Menu_ShowMonthlyMonthsMenu);
    menu.SetTitle("Select Month/Year\n ");

    while (results.FetchRow())
    {
        int iMonth = results.FetchInt(0);
        int iYear = results.FetchInt(1);

        char sMonth[16];
        GetMonthStringByInt(iMonth, sMonth, sizeof(sMonth));

        char sData[8], sItem[64];
        FormatEx(sData, sizeof(sData), "%d;%d", iMonth, iYear);
        FormatEx(sItem, sizeof(sItem), "%s 20%d", sMonth, iYear);
        menu.AddItem(sData, sItem);
    }

    menu.ExitBackButton = true;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public void SQL_ShowMonthlyTopPointsMenu(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_ShowMonthlyTopPointsMenu) Fail at Query: %s", error);
        delete pack;
        return;
    }

    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());
    int iMonth = pack.ReadCell();
    char sMonth[16];
    GetMonthStringByInt(iMonth, sMonth, sizeof(sMonth));
    int iYear = pack.ReadCell();
    delete pack;

    if (!client)
    {
        return;
    }

    Menu menu = new Menu(Menu_ShowMonthlyTopPointsMenu);
    char sTitle[128];
    FormatEx(sTitle, sizeof(sTitle), "%s 20%d - Most Points\n ", sMonth, iYear);
    menu.SetTitle(sTitle);

    while (results.FetchRow())
    {
        char sName[MAX_NAME_LENGTH];
        results.FetchString(0, sName, sizeof(sName));

        int ilevel = results.FetchInt(1);

        char sItem[256];
        FormatEx(sItem, sizeof(sItem), "Points: %d - %s", ilevel, sName);
        menu.AddItem("", sItem, ITEMDRAW_DISABLED);
    }

    menu.ExitBackButton = true;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public void SQL_LoadClientFeatures(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_LoadClientFeatures) Fail at Query: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!client)
    {
        return;
    }

    delete Player[client].Features;
    Player[client].Features = new ArrayList(sizeof(PlayerFeatureData));

    while (results.FetchRow())
    {
        PlayerFeatureData PlayerFeature;

        PlayerFeature.Id = results.FetchInt(0);
        results.FetchString(1, PlayerFeature.Name, sizeof(PlayerFeatureData::Name));
        PlayerFeature.Price = results.FetchInt(2);
        PlayerFeature.PurchasedDate = results.FetchInt(3);
        PlayerFeature.ExpirationDate = results.FetchInt(4);
        PlayerFeature.Refundable = view_as<bool>(results.FetchInt(5));
        PlayerFeature.Tradable = view_as<bool>(results.FetchInt(6));

        Player[client].Features.PushArray(PlayerFeature, sizeof(PlayerFeature));
        PrintToServer("Id: %d, Feature: %s, Price: %d, Purchase:  %d, Expiration: %d, Refundable: %d, Tradable: %d", PlayerFeature.Id, PlayerFeature.Name, PlayerFeature.Price, PlayerFeature.PurchasedDate, PlayerFeature.ExpirationDate, PlayerFeature.Refundable, PlayerFeature.Tradable)
    }

    CPrintToChat(client, "Loaded %s%d%s features.", SPECIAL, Player[client].Features.Length, TEXT);

    Call_StartForward(Core.OnClientReady);
    Call_PushCell(client);
    Call_PushCell(view_as<int>(Player[client].Features));
    Call_Finish();
}

public void SQL_AddPurchaseLog(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_AddPurchaseLog) Fail at Query: %s", error);
        return;
    }
}

public void SQL_AddRefundLog(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_AddRefundLog) Fail at Query: %s", error);
        return;
    }
}
