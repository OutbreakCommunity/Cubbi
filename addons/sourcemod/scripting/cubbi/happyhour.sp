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
