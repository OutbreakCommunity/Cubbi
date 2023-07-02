public Action Command_Cubbi(int client, int args)
{
    if (!client)
    {
        return Plugin_Handled;
    }

    if (!Player[client].Loaded)
    {
        CPrintToChat(client, "Your data hasn't been loaded yet...");
        return Plugin_Handled;
    }

    ShowMainMenu(client);

    return Plugin_Handled;
}

public Action Command_Points(int client, int args)
{
    if (!client)
    {
        return Plugin_Handled;
    }

    if (!Player[client].Loaded)
    {
        CPrintToChat(client, "Your data hasn't been loaded yet...");
        return Plugin_Handled;
    }

    CPrintToChatAll("%s%N%s is on level %s%d%s with %s%d%s (hidden points: %s%d%s) points.", SPECIAL, client, TEXT, SPECIAL, Player[client].Level, TEXT, SPECIAL, Player[client].Points, TEXT, SPECIAL, Player[client].HiddenPoints, TEXT);

    return Plugin_Handled;
}

public Action Command_Shop(int client, int args)
{
    if (!client)
    {
        return Plugin_Handled;
    }

    if (!Player[client].Loaded)
    {
        CPrintToChat(client, "Your data hasn't been loaded yet...");
        return Plugin_Handled;
    }

    ShowShopMainMenu(client, true);

    return Plugin_Handled;
}

public Action Command_Features(int client, int args)
{
    if (!client)
    {
        return Plugin_Handled;
    }

    if (!Player[client].Loaded)
    {
        CPrintToChat(client, "Your data hasn't been loaded yet...");
        return Plugin_Handled;
    }

    ShowFeaturesMenu(client, true);

    return Plugin_Handled;
}

public Action Command_Toplists(int client, int args)
{
    if (!client)
    {
        return Plugin_Handled;
    }

    if (!Player[client].Loaded)
    {
        CPrintToChat(client, "Your data hasn't been loaded yet...");
        return Plugin_Handled;
    }

    ShowTopMainMenu(client);

    return Plugin_Handled;
}

public Action Command_AddPoints(int client, int args)
{
    if (args != 2)
    {
        CReplyToCommand(client, "sm_addpoints <#UserID|Name> <Points>");
        return Plugin_Handled;
    }
    
    int  targets[129];
    bool ml = false;
    char buffer[MAX_NAME_LENGTH], arg1[MAX_NAME_LENGTH], arg2[12];
    
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    if (!IsStringNumeric(arg2))
    {
        CReplyToCommand(client, "Only numbers are allowed!")
        return Plugin_Handled;
    }

    int count = ProcessTargetString(arg1, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, buffer, sizeof(buffer), ml);
    if (count <= 0)
    {
        CReplyToCommand(client, "Invalid Target");
        return Plugin_Handled;
    }

    for (int i = 0; i < count; i++)
    {
        int target = targets[i];
        
        if(!IsClientValid(target))
        {
            return Plugin_Handled;
        }

        int points = StringToInt(arg2);
        int iTemp = StringToInt(arg2);
        
        if (points < 0)
        {
            CReplyToCommand(client, "Invalid points value (%d).", points);
        }

        Cubbi_AddClientPoints(client, points);

        LogMessage("\"%L\" added \"%L\" %d points", client, target, iTemp);
        CPrintToChatAll("%s%N%s added %s%N%s %s%d%s points", SPECIAL, client, TEXT, SPECIAL, target, TEXT, SPECIAL, iTemp, TEXT);
    }
    return Plugin_Handled;
}

public Action Command_SetPoints(int client, int args)
{
    if (args != 2)
    {
        CReplyToCommand(client, "sm_setpoints <#UserID|Name> <Points>");
        return Plugin_Handled;
    }
    
    int  targets[129];
    bool ml = false;
    char buffer[MAX_NAME_LENGTH], arg1[MAX_NAME_LENGTH], arg2[12];
    
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    if (!IsStringNumeric(arg2))
    {
        CReplyToCommand(client, "Only numbers are allowed!")
        return Plugin_Handled;
    }

    int count = ProcessTargetString(arg1, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, buffer, sizeof(buffer), ml);
    if (count <= 0)
    {
        CReplyToCommand(client, "Invalid Target");
        return Plugin_Handled;
    }

    for (int i = 0; i < count; i++)
    {
        int target = targets[i];
        
        if(!IsClientValid(target))
        {
            return Plugin_Handled;
        }

        int points = StringToInt(arg2);
        int iTemp = StringToInt(arg2);
        
        if (points < 0)
        {
            CReplyToCommand(client, "Invalid points value (%d).", points);
        }

        Cubbi_SetClientPoints(client, points);

        LogMessage("\"%L\" has set the points of \"%L\" to %d", client, target, iTemp);
        CPrintToChatAll("%s%N%s set points of %s%N%s to %s%d", SPECIAL, client, TEXT, SPECIAL, target, TEXT, SPECIAL, iTemp);
    }
    return Plugin_Handled;
}

public Action Command_DelPoints(int client, int args)
{
    if (args != 2)
    {
        CReplyToCommand(client, "sm_delpoints <#UserID|Name> <Points>");
        return Plugin_Handled;
    }
    
    int  targets[129];
    bool ml = false;
    char buffer[MAX_NAME_LENGTH], arg1[MAX_NAME_LENGTH], arg2[12];
    
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    if (!IsStringNumeric(arg2))
    {
        CReplyToCommand(client, "Only numbers are allowed!")
        return Plugin_Handled;
    }

    int count = ProcessTargetString(arg1, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, buffer, sizeof(buffer), ml);
    if (count <= 0)
    {
        CReplyToCommand(client, "Invalid Target");
        return Plugin_Handled;
    }

    for (int i = 0; i < count; i++)
    {
        int target = targets[i];
        
        if(!IsClientValid(target))
        {
            return Plugin_Handled;
        }

        int points = StringToInt(arg2);
        int iTemp = StringToInt(arg2);

        if (points > Player[target].Points)
        {
            points = Player[target].Points;
            CReplyToCommand(client, "Too much points to remove. Set points value to %d", points);
        }
        
        if (points < 0)
        {
            CReplyToCommand(client, "Invalid points value (%d).", points);
        }

        Cubbi_DelClientPoints(client, points);

        LogMessage("\"%L\" removed \"%L\" %d points", client, target, iTemp);
        CPrintToChatAll("%s%N%s removed %s%N%s %s%d%s points", SPECIAL, client, TEXT, SPECIAL, target, TEXT, SPECIAL, iTemp, TEXT);
    }
    return Plugin_Handled;
}
