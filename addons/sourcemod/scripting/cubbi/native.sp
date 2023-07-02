public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    Core.OnLoaded = new GlobalForward("Cubbi_OnLoaded", ET_Ignore);
    Core.OnPurchase = new GlobalForward("Cubbi_OnClientPurchase", ET_Ignore, Param_Cell, Param_String);
    Core.OnClientReady = new GlobalForward("Cubbi_OnClientReady", ET_Ignore, Param_Cell, Param_Cell);

    CreateNative("Cubbi_GetClientLevel", Native_GetClientLevel);
    CreateNative("Cubbi_GetClientPoints", Native_GetClientPoints);
    CreateNative("Cubbi_GetClientHiddenPoints", Native_GetClientHiddenPoints);
    
    CreateNative("Cubbi_AddClientPoints", Native_AddClientPoints);
    CreateNative("Cubbi_SetClientPoints", Native_SetClientPoints);
    CreateNative("Cubbi_DelClientPoints", Native_DelClientPoints);

    CreateNative("Cubbi_RegisterFeature", Native_RegisterFeature);
    CreateNative("Cubbi_HasClientFeature", Native_HasClientFeature);

    RegPluginLibrary("cubbi");

    return APLRes_Success;
}

public int Native_GetClientLevel(Handle plugin, int numParams)
{
    return Player[GetNativeCell(1)].Level;
}

public int Native_GetClientPoints(Handle plugin, int numParams)
{
    return Player[GetNativeCell(1)].Points;
}

public int Native_GetClientHiddenPoints(Handle plugin, int numParams)
{
    return Player[GetNativeCell(1)].HiddenPoints;
}

public any Native_RegisterFeature(Handle plugin, int numParams)
{
    FeatureData Feature;
    GetNativeString(1, Feature.Name, sizeof(FeatureData::Name));
    GetNativeString(2, Feature.Description, sizeof(FeatureData::Description));
    Feature.Level = GetNativeCell(3);
    Feature.Points = GetNativeCell(4);
    Feature.Expiration = GetNativeCell(5);
    Feature.Refundable = view_as<bool>(GetNativeCell(6));
    Feature.Tradable = view_as<bool>(GetNativeCell(7));

    for (int i = 0; i < Core.Features.Length; i++)
    {
        FeatureData fTemp;
        Core.Features.GetArray(i, fTemp, sizeof(fTemp));

        if (StrEqual(fTemp.Name, Feature.Name, false))
        {
            return false;
        }
    }

    Core.Features.PushArray(Feature, sizeof(Feature));

    SortADTArrayCustom(Core.Features, SortFeatures);

    return true;
}

public int SortFeatures(int i, int j, Handle array, Handle hndl)
{
    FeatureData feature1;
    Core.Features.GetArray(i, feature1);

    FeatureData feature2;
    Core.Features.GetArray(j, feature2);

    if (feature1.Name[0] < feature2.Name[0])
    {
        return -1;
    }
    else if (feature1.Name[0] > feature2.Name[0])
    {
        return 1;
    }

    return 0;
}

public any Native_HasClientFeature(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char sName[MAX_FEATURE_NAME_LENGTH];
    GetNativeString(2, sName, sizeof(sName));

    PlayerFeatureData PlayerFeature;
    for (int i = 0; i < Player[client].Features.Length; i++)
    {
        Player[client].Features.GetArray(i, PlayerFeature, sizeof(PlayerFeature));

        if (StrEqual(PlayerFeature.Name, sName, false))
        {
            return true;
        }
    }

    return false;
}

public any Native_AddClientPoints(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int points = GetNativeCell(2);

    if (points < 0)
    {
        return false;
    }

    Player[client].Points += points;
    UpdateClientPoints(client);

    return true;
}

public any Native_SetClientPoints(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int points = GetNativeCell(2);

    if (points < 0)
    {
        return false;
    }

    Player[client].Points = points;
    UpdateClientPoints(client);

    return true;
}

public any Native_DelClientPoints(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int points = GetNativeCell(2);

    if (points < 0)
    {
        return false;
    }

    if (points > Player[client].Points)
    {
        points = Player[client].Points;
    }

    Player[client].Points -= points;
    UpdateClientPoints(client);

    return true;
}
