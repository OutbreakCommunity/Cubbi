void ShowTopMainMenu(int client)
{
    Menu menu = new Menu(Menu_TopMainMenu);
    menu.SetTitle("Select Option\n ");
    menu.AddItem("points", "Most Points");
    menu.AddItem("level", "Highest Level");
    menu.AddItem("monthly", "Monthly Points");
    menu.ExitBackButton = true;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_TopMainMenu(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[12];
        menu.GetItem(param, sParam, sizeof(sParam));

        if (StrEqual(sParam, "points", false))
        {
            ShowMostPointsMenu(client);
        }
        else if (StrEqual(sParam, "level", false))
        {
            ShowHighestLevelMenu(client);
        }
        else if (StrEqual(sParam, "monthly", false))
        {
            ShowMonthlyMonthsMenu(client);
        }
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

void ShowMostPointsMenu(int client)
{
    char sQuery[256];
    Core.Database.Format(sQuery, sizeof(sQuery), "SELECT name, points FROM players ORDER BY points DESC LIMIT %d", Core.TopLimit.IntValue);
    Core.Database.Query(SQL_ShowMostPointsMenu, sQuery, GetClientUserId(client));
}

public int Menu_ShowMostPointsMenu(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Cancel)
    {
        if (param == MenuCancel_ExitBack)
        {
            ShowTopMainMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}

void ShowHighestLevelMenu(int client)
{
    char sQuery[256];
    Core.Database.Format(sQuery, sizeof(sQuery), "SELECT name, level FROM players ORDER BY hidden_points DESC LIMIT %d", Core.TopLimit.IntValue);
    Core.Database.Query(SQL_ShowHighestLevelMenu, sQuery, GetClientUserId(client));
}

public int Menu_ShowHighestLevelMenu(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Cancel)
    {
        if (param == MenuCancel_ExitBack)
        {
            ShowTopMainMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}

void ShowMonthlyMonthsMenu(int client)
{
    char sQuery[256];
    Core.Database.Format(sQuery, sizeof(sQuery), "SELECT month, year FROM monthly_players GROUP BY month, year ORDER BY year DESC, month DESC");
    Core.Database.Query(SQL_ShowMonthlyMonthsMenu, sQuery, GetClientUserId(client));
}

public int Menu_ShowMonthlyMonthsMenu(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[8];
        menu.GetItem(param, sParam, sizeof(sParam));

        char sData[2][4];
        ExplodeString(sParam, ";", sData, sizeof(sData), sizeof(sData[]));

        int iMonth = StringToInt(sData[0]);
        int iYear = StringToInt(sData[1]);

        DataPack pack = new DataPack();
        pack.WriteCell(GetClientUserId(client));
        pack.WriteCell(iMonth);
        pack.WriteCell(iYear);

        char sQuery[512];
        Core.Database.Format(sQuery, sizeof(sQuery), "SELECT players.name, monthly_players.hidden_points FROM monthly_players INNER JOIN players ON players.accountid = monthly_players.accountid WHERE monthly_players.month = %d AND monthly_players.year = %d ORDER BY monthly_players.hidden_points DESC LIMIT %d", iMonth, iYear, Core.TopLimit.IntValue);
        Core.Database.Query(SQL_ShowMonthlyTopPointsMenu, sQuery, pack);
    }
    else if (action == MenuAction_Cancel)
    {
        if (param == MenuCancel_ExitBack)
        {
            ShowTopMainMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}

public int Menu_ShowMonthlyTopPointsMenu(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Cancel)
    {
        if (param == MenuCancel_ExitBack)
        {
            ShowMonthlyMonthsMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}
