void CheckHappyHour()
{
    char sQuery[256];
    FormatEx(sQuery, sizeof(sQuery), "SELECT value FROM settings WHERE key = \"happyhour\"");
    Core.Database.Query(SQL_CheckHappyHour, sQuery);
}

void ResetHappyHour()
{
    char sQuery[256];
    FormatEx(sQuery, sizeof(sQuery), "UPDATE settings SET value = 0 WHERE key = \"happyhour\"");
    Core.Database.Query(SQL_ResetHappyHour, sQuery);
}
