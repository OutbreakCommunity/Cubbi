void ShowShopMainMenu(int client, bool command = false)
{
    if (command && (Core.Features == null || Core.Features.Length < 1))
    {
        CPrintToChat(client, "There are no shop items yet...");
        return;
    }

    Menu menu = new Menu(Menu_ShopMainMenu);
    menu.SetTitle("Cubbi Shop\n ");

    if (Core.Features == null || Core.Features.Length < 1)
    {
        menu.AddItem("", "There are no shop items yet...");
    }
    else
    {
        for (int i = 0; i < Core.Features.Length; i++)
        {
            FeatureData Feature;
            Core.Features.GetArray(i, Feature, sizeof(Feature));

            char sItem[128];
            FormatEx(sItem, sizeof(sItem), "%s\nLevel: %d, Price: %d\n ", Feature.Name, Feature.Level, Feature.Points);
            menu.AddItem(Feature.Name, sItem);
        }
    }

    menu.ExitBackButton = true;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_ShopMainMenu(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sName[64];
        menu.GetItem(param, sName, sizeof(sName));
        ShowFeatureConfirmMenu(client, sName);
    }
    else if (action == MenuAction_Cancel)
    {
        if (param == MenuCancel_ExitBack)
        {
            ShowMainMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}

void ShowFeatureConfirmMenu(int client, const char[] name)
{
    Menu menu = new Menu(Menu_ShowFeatureConfirmMenu);

    bool bFound = false;

    for (int i = 0; i < Core.Features.Length; i++)
    {
        FeatureData Feature;
        Core.Features.GetArray(i, Feature, sizeof(Feature));

        if (StrEqual(Feature.Name, name, false))
        {
            bFound = true;

            char sTitle[MAX_FEATURE_DESCRIPTION_LENGTH * 2];
            FormatEx(sTitle, sizeof(sTitle), "%s\n \n%s\n \nLevel: %d\nPrice: %d\nRefundable: %d\nTradable: %d\n \n ", Feature.Name, Feature.Description, Feature.Level, Feature.Points, Feature.Refundable, Feature.Tradable);
            menu.SetTitle(sTitle);

            menu.AddItem("", "No, sorry!");
            menu.AddItem(Feature.Name, "Yes, I want it!", (Feature.Level <= Player[client].Level && Feature.Points <= Player[client].Points) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            
            break;
        }
    }

    if (!bFound)
    {
        ShowShopMainMenu(client);
        CPrintToChat(client, "Feature not found...?");

        delete menu;
        return;
    }

    menu.ExitBackButton = false;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_ShowFeatureConfirmMenu(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[64];
        menu.GetItem(param, sParam, sizeof(sParam));

        if (strlen(sParam) < 1)
        {
            ShowShopMainMenu(client);
            return 0;
        }

        PurchaseFeature(client, sParam);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}

void PurchaseFeature(client, const char[] name)
{
    PlayerFeatureData PlayerFeature;
    for (int i = 0; i < Player[client].Features.Length; i++)
    {
        Player[client].Features.GetArray(i, PlayerFeature, sizeof(PlayerFeature));

        if (StrEqual(PlayerFeature.Name, name, false))
        {
            ShowShopMainMenu(client);
            CPrintToChat(client, "You already own this item.");
            return;
        }
    }

    bool bFound = false;

    FeatureData Feature;
    for (int i = 0; i < Core.Features.Length; i++)
    {
        Core.Features.GetArray(i, Feature, sizeof(Feature));

        if (StrEqual(Feature.Name, name, false))
        {
            bFound = true;
            break;
        }
    }

    if (!bFound)
    {
        ShowShopMainMenu(client);
        CPrintToChat(client, "Feature not found...?");
        return;
    }

    if (Feature.Points > Player[client].Points)
    {
        ShowShopMainMenu(client);
        CPrintToChat(client, "You don't have enough points to buy %s%s", SPECIAL, Feature.Name);
        return;
    }

    if (Feature.Level > Player[client].Level)
    {
        ShowShopMainMenu(client);
        CPrintToChat(client, "You level is too low for %s%s", SPECIAL, Feature.Name);
        return;
    }

    char sQuery[512];
    Core.Database.Format(sQuery, sizeof(sQuery), "INSERT INTO purchased_features (accountid, feature, price, purchased_date, expiration_date, refundable, refunded, tradable) VALUES (%d, \"%s\", %d, UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, 0, %d);",
    GetSteamAccountID(client), Feature.Name, Feature.Points, Feature.Expiration, Feature.Refundable, Feature.Tradable);
    LogMessage(sQuery);

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCellArray(Feature, sizeof(Feature));
    Core.Database.Query(SQL_InsertClientFeature, sQuery, pack);
}

public void SQL_InsertClientFeature(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("(SQL_InsertClientFeature) Fail at Query: %s", error);
        delete pack;
        return;
    }

    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());
    FeatureData Feature;
    pack.ReadCellArray(Feature, sizeof(Feature));
    delete pack;

    if (!client)
    {
        return;
    }

    Player[client].Points -= Feature.Points;

    char sQuery[256];
    Core.Database.Format(sQuery, sizeof(sQuery), "UPDATE players SET points = %d WHERE accountid = %d;", Player[client].Points, GetSteamAccountID(client));
    Core.Database.Query(SQL_UpdateClientPoints, sQuery);
    
    CPrintToChat(client, "You have successfully bought %s%s", SPECIAL, Feature.Name);
    LoadClientFeatures(client);

    Call_StartForward(Core.OnPurchase);
    Call_PushCell(client);
    Call_PushString(Feature.Name);
    Call_Finish();

    Core.Database.Format(sQuery, sizeof(sQuery), "INSERT INTO feature_logs (featureid, accountid, date, action, price) VALUES (%d, %d, UNIX_TIMESTAMP(), \"purchase\", %d, %d, %d)", results.InsertId, GetSteamAccountID(client), Feature.Points);
    Core.Database.Query(SQL_AddPurchaseLog, sQuery);
}
