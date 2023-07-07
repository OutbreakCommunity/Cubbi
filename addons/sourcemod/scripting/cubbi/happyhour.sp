void ConfigureHappyHour(int client)
{
    Player[client].HappyHourTime = true;
    CPrintToChat(client, "Type happy hour %stime in minutes %sin the chat.", SPECIAL, TEXT);
}

void ConfirmHappyHourSettings(int client)
{
    Menu menu = new Menu(Menu_ConfirmHappyHourSettings);

    char sTitle[256];
    FormatEx(sTitle, sizeof(sTitle), "Confirm following settings:\n \nTime: %d minutes\nPercent: %d\n \nStart Happy Hour?");
    menu.SetTitle(sTitle);
    menu.AddItem("n", "No");
    menu.AddItem("y", "Yes");
    menu.ExitBackButton = false;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_ConfirmHappyHourSettings(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[4];
        menu.GetItem(param, sParam, sizeof(sParam));

        if (sParam[0] == 'n')
        {
            Core.ResetHappyHour();
            CPrintToChat(client, "Happy Hour process aborted!");
        }
        else if (sParam[0] == 'y')
        {
            Core.HappyHourTime = GetTime() + (Core.HappyHourTime * 60);

            char sQuery[256];

            FormatEx(sQuery, sizeof(sQuery), "INSERT INTO settings (key, value) VALUES (happyhour_time, %d) ON DUPLICATE KEY UPDATE value = %d;", Core.HappyHourTime, Core.HappyHourTime);
            Core.Database.Query(SQL_UpdateHappyHour, sQuery, false);

            FormatEx(sQuery, sizeof(sQuery), "INSERT INTO settings (key, value) VALUES (happyhour_factor, %d) ON DUPLICATE KEY UPDATE value = %d;", Core.HappyHourFactor, Core.HappyHourFactor);
            Core.Database.Query(SQL_UpdateHappyHour, sQuery, true);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}

void CheckHappyHour()
{
    char sQuery[256];
    FormatEx(sQuery, sizeof(sQuery), "SELECT value FROM settings WHERE key = \"happyhour_time\"");
    Core.Database.Query(SQL_CheckHappyHour, sQuery);
}

void GetHappyHourFactor()
{
    char sQuery[256];
    FormatEx(sQuery, sizeof(sQuery), "SELECT value FROM settings WHERE key = \"happyhour_factor\"");
    Core.Database.Query(SQL_GetHappyHourFactor, sQuery);
}

void ResetHappyHour()
{
    char sQuery[256];

    FormatEx(sQuery, sizeof(sQuery), "UPDATE settings SET value = 0 WHERE key = \"happyhour_time\"");
    Core.Database.Query(SQL_ResetHappyHour, sQuery, false);

    FormatEx(sQuery, sizeof(sQuery), "UPDATE settings SET value = 0.0 WHERE key = \"happyhour_factor\"");
    Core.Database.Query(SQL_ResetHappyHour, sQuery, true);
}
