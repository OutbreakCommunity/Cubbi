void ShowAdminMenu(int client)
{
    Menu menu = new Menu(MenuHandler_AdminMenu);
    menu.SetTitle("Cubbi Admin Menu");
    menu.AddItem("start_happy", "Start Happy Hour");
    menu.AddItem("stop_happy", "Stop Happy Hour", (Core.HappyHourTime != 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    menu.ExitBackButton = false;
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_AdminMenu(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[32];
        menu.GetItem(param, sParam, sizeof(sParam));

        if (sParam[0] == 's' && sParam[2] == 'o')
        {
            ResetHappyHour();
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}
