void ConfirmRefund(int client, int id)
{
    PlayerFeatureData PlayerFeature;
    bool bFound = false;

    for (int i = 0; i < Player[client].Features.Length; i++)
    {
        Player[client].Features.GetArray(i, PlayerFeature, sizeof(PlayerFeature));
        
        if (PlayerFeature.Id == id)
        {
            bFound = true;
            break;
        }
    }

    if (!bFound)
    {
        ShowFeaturesMenu(client);
        CPrintToChat(client, "Feature not found...?");
        return;
    }

    Menu menu = new Menu(Menu_ConfirmRefund);
    
    char sTitle[512];
    int iFees = RoundToFloor(PlayerFeature.Price * (Core.RefundFees.IntValue / 100.0));
    FormatEx(sTitle, sizeof(sTitle), "Are you sure?\n \nItem: %s\nPrice: %d\nFees: %d Points\n \nYou'll get: %d\n \n", PlayerFeature.Name, PlayerFeature.Price, iFees, PlayerFeature.Price - iFees);
    menu.SetTitle(sTitle);

    char sBuffer[69];
    FormatEx(sBuffer, sizeof(sBuffer), "%d.0", PlayerFeature.Id);
    menu.AddItem(sBuffer, "No, go back!");

    FormatEx(sBuffer, sizeof(sBuffer), "%d.1", PlayerFeature.Id);
    menu.AddItem(sBuffer, "Yes, give my money!");
    menu.ExitBackButton = false;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_ConfirmRefund(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sBuffer[69], sParam[2][12];
        menu.GetItem(param, sBuffer, sizeof(sBuffer));
        ExplodeString(sBuffer, ".", sParam, sizeof(sParam), sizeof(sParam[]));

        PlayerFeatureData PlayerFeature;
        bool bFound = false;
        int iArrayId = 0;

        for (int i = 0; i < Player[client].Features.Length; i++)
        {
            Player[client].Features.GetArray(i, PlayerFeature, sizeof(PlayerFeature));
            
            if (PlayerFeature.Id == StringToInt(sParam[0]))
            {
                bFound = true;
                iArrayId = i;
                break;
            }
        }

        if (!bFound)
        {
            ShowFeaturesMenu(client);
            CPrintToChat(client, "Feature not found...?");
            return 0;
        }

        if (!view_as<bool>(StringToInt(sParam[1])))
        {
            ShowPlayerFeatureMenu(client, PlayerFeature.Name);
            return 0;
        }

        int iFees = RoundToFloor(PlayerFeature.Price * (Core.RefundFees.IntValue / 100.0));
        Player[client].Points += PlayerFeature.Price - iFees;
        Player[client].Features.Erase(iArrayId);

        char sQuery[256];
        Core.Database.Format(sQuery, sizeof(sQuery), "UPDATE players SET points = %d WHERE accountid = %d;", Player[client].Points, GetSteamAccountID(client));
        Core.Database.Query(SQL_UpdateClientPoints, sQuery);

        Core.Database.Format(sQuery, sizeof(sQuery), "UPDATE purchased_features SET refunded = 1, refunded_date = UNIX_TIMESTAMP(), refunded_points = %d WHERE id = %d AND accountid = %d;", PlayerFeature.Price - iFees, PlayerFeature.Id, GetSteamAccountID(client));
        Core.Database.Query(SQL_UpdateClientFeature, sQuery);

        Core.Database.Format(sQuery, sizeof(sQuery), "INSERT INTO feature_logs (featureid, accountid, date, action, price, fees, points) VALUES (%d, %d, UNIX_TIMESTAMP(), \"refund\", %d, %d, %d)", PlayerFeature.Id, GetSteamAccountID(client), PlayerFeature.Price, iFees, PlayerFeature.Price - iFees);
        Core.Database.Query(SQL_AddRefundLog, sQuery);

        CPrintToChat(client, "You have refunded %s%s%s and got %s%d%s points", SPECIAL, PlayerFeature.Name, TEXT, SPECIAL, PlayerFeature.Price - iFees, TEXT);

        ShowFeaturesMenu(client);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}
