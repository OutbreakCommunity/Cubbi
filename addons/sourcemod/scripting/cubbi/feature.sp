void ShowFeaturesMenu(int client, bool command = false)
{
    if (command && (Player[client].Features == null || Player[client].Features.Length < 1))
    {
        CPrintToChat(client, "You don't have any features...");
        return;
    }

    Menu menu = new Menu(Menu_ShowFeaturesMenu);
    menu.SetTitle("Your features\n ");

    if (Player[client].Features == null || Player[client].Features.Length < 1)
    {
        menu.AddItem("", "You don't have any features...");
    }
    else
    {
        for (int i = 0; i < Player[client].Features.Length; i++)
        {
            PlayerFeatureData PlayerFeature;
            Player[client].Features.GetArray(i, PlayerFeature, sizeof(PlayerFeature));
            menu.AddItem(PlayerFeature.Name, PlayerFeature.Name);
        }
    }

    menu.ExitBackButton = true;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_ShowFeaturesMenu(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sName[64];
        menu.GetItem(param, sName, sizeof(sName));
        ShowPlayerFeatureMenu(client, sName);
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

void ShowPlayerFeatureMenu(int client, const char[] name)
{
    PlayerFeatureData PlayerFeature;
    bool bFound = false;

    for (int i = 0; i < Player[client].Features.Length; i++)
    {
        Player[client].Features.GetArray(i, PlayerFeature, sizeof(PlayerFeature));
        
        if (StrEqual(PlayerFeature.Name, name, false))
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

    Menu menu = new Menu(Menu_PlayerFeatureMenu);

    char sTitle[512], sDate[32];
    FormatTime(sDate, sizeof(sDate), "%d.%m.%Y - %T", PlayerFeature.PurchasedDate);
    FormatEx(sTitle, sizeof(sTitle), "%s\n \nDate: %s\nPrice: %d\nRefundable: %d\nTradable: %d\n \n ", PlayerFeature.Name, sDate, PlayerFeature.Price, PlayerFeature.Refundable, PlayerFeature.Tradable);
    menu.SetTitle(sTitle);

    char sDisplay[64], sBuffer[18];
    FormatEx(sBuffer, sizeof(sBuffer), "refund.%d", PlayerFeature.Id);
    FormatEx(sDisplay, sizeof(sDisplay), "Refund Item (%d%% fees)", Core.RefundFees.IntValue);
    menu.AddItem(sBuffer, sDisplay, (PlayerFeature.Refundable) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    FormatEx(sBuffer, sizeof(sBuffer), "trade.%d", PlayerFeature.Id);
    FormatEx(sDisplay, sizeof(sDisplay), "Player Trade (%d%% fees)", Core.TradeFees.IntValue);
    menu.AddItem(sBuffer, sDisplay, ITEMDRAW_DISABLED);

    FormatEx(sBuffer, sizeof(sBuffer), "sell.%d", PlayerFeature.Id);
    FormatEx(sDisplay, sizeof(sDisplay), "Sell on Market (%d%% fees)", Core.MarketFees.IntValue);
    menu.AddItem(sBuffer, sDisplay, ITEMDRAW_DISABLED);

    menu.ExitBackButton = true;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_PlayerFeatureMenu(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sBuffer[18], sParam[2][12];
        menu.GetItem(param, sBuffer, sizeof(sBuffer));
        ExplodeString(sBuffer, ".", sParam, sizeof(sParam), sizeof(sParam[]));

        if (StrEqual(sParam[0], "refund", false))
        {
            ConfirmRefund(client, StringToInt(sParam[1]));
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (param == MenuCancel_ExitBack)
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
