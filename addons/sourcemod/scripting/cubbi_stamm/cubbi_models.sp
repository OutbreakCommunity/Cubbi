#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>
#include <cubbi>
#include <multicolors>
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <rules>

#define MODELPATH 0
#define MODELNAME 1
#define MODELTEAM 2
#define MODELLEVEL 3

int PlayerHasModel[MAXPLAYERS + 1];
int LastTeam[MAXPLAYERS + 1];
int modelCount;
int model_change;
int same_models;

char PlayerModel[MAXPLAYERS + 1][PLATFORM_MAX_PATH + 1];
char models[64][4][PLATFORM_MAX_PATH + 1];

enum struct GlobalData {
    ConVar ModelChange;
    ConVar SameModels;
}
GlobalData Core;

bool g_bReady[MAXPLAYERS + 1] = { false, ... };
bool g_bRules = false;


public Plugin myinfo =
{
    name = "Cubbi - Models",
    author = "Bara (Original author: dordnung)",
    version = "1.0.0",
    description = "",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("cubbi.more_ammo");
    Core.ModelChange = AutoExecConfig_CreateConVar("model_change", "1", "0 = Players can only change models, when changing team, 1 = Players can always change it");
    Core.SameModels = AutoExecConfig_CreateConVar("model_models", "0", "1 = VIP's can choose the model, 0 = Random Skin every Round");
    AutoExecConfig_CleanFile();
    AutoExecConfig_ExecuteFile();
    
    
    HookEvent("player_team", eventPlayerTeam);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    
    ModelDownloads();

    RegConsoleCmd("sm_models", CmdModel);

    g_bRules = LibraryExists("rules");
}

public void Cubbi_OnLoaded()
{
    char sPath[PLATFORM_MAX_PATH + 1];
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/cubbi/ModelSettings.txt");
    if (!FileExists(sPath))
    {
        SetFailState("Couldn't load Cubbi Models. \"%s\" missing.", sPath);
    }
    
    // To Keyvalues
    KeyValues kvSettings = new KeyValues("ModelSettings");


    kvSettings.ImportFromFile(sPath);



    // Key value loop
    if (kvSettings.GotoFirstSubKey())
    {
        do
        {
            // Get Settings for each model
            kvSettings.GetString("team", models[modelCount][MODELTEAM], sizeof(models[][]));
            kvSettings.GetString("model", models[modelCount][MODELPATH], sizeof(models[][]));

            if (!StrEqual(models[modelCount][MODELPATH], "") && !StrEqual(models[modelCount][MODELPATH], "0"))
            {
                PrecacheModel(models[modelCount][MODELPATH]);
            }

            kvSettings.GetString("name", models[modelCount][MODELNAME], sizeof(models[][]));
            IntToString(kvSettings.GetNum("level"), models[modelCount][MODELLEVEL], sizeof(models[][]));

            char sTeam[8];
            if (StringToInt(models[modelCount][MODELTEAM]) == CS_TEAM_T)
            {
                FormatEx(sTeam, sizeof(sTeam), "T-");
            }
            else if (StringToInt(models[modelCount][MODELTEAM]) == CS_TEAM_CT)
            {
                FormatEx(sTeam, sizeof(sTeam), "CT-");
            }

            char sName[MAX_FEATURE_NAME_LENGTH];
            FormatEx(sName, sizeof(sName), "%sModel: %s", sTeam, models[modelCount][MODELNAME]);

            char sDescription[MAX_FEATURE_DESCRIPTION_LENGTH];
            FormatEx(sDescription, sizeof(sDescription), "Get access to model %s", models[modelCount][MODELNAME]);

            Cubbi_RegisterFeature(sName, sDescription, kvSettings.GetNum("level"), kvSettings.GetNum("points"), kvSettings.GetNum("expiration"), view_as<bool>(kvSettings.GetNum("refundable")), view_as<bool>(kvSettings.GetNum("tradeable")));

            modelCount++;
        }
        while (kvSettings.GotoNextKey());
    }

    delete kvSettings;
}

public void OnConfigsExecuted()
{
    model_change = GetConVarInt(Core.ModelChange);
    same_models = GetConVarInt(Core.SameModels);
}

public void OnMapStart()
{
    for (int i = 0; i < modelCount; i++)
    {
        if (!StrEqual(models[i][MODELPATH], "") && !StrEqual(models[i][MODELPATH], "0"))
        {
            PrecacheModel(models[i][MODELPATH]);
        }
    }
}

public void OnAllPluginsLoaded()
{
    g_bRules = LibraryExists("rules");
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "rules"))
    {
        g_bRules = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "rules"))
    {
        g_bRules = false;
    }
}

// TODO: ???
public void STAMM_OnClientRequestFeatureInfo(int client, int block, Handle &array)
{
    char fmt[256];
    bool found = false;
    
    for (int item = 0; item < modelCount; item++)
    {
        // Right team and right level?
        if (GetClientTeam(client) == StringToInt(models[item][MODELTEAM]) && ((StringToInt(models[item][MODELLEVEL]) == 0) || (Cubbi_GetClientLevel(client) >= StringToInt(models[item][MODELLEVEL]))))
        {
            if (!StrEqual(models[item][MODELPATH], "") && !StrEqual(models[item][MODELPATH], "0"))
            {
                found = true;
                
                break;
            }
        }
    }
    
    if (found)
    {
        if (model_change && same_models)
        {
            Format(fmt, sizeof(fmt), "%T", "GetModelChange", client, "!models");
        }
        else 
        {
            Format(fmt, sizeof(fmt), "%T", "GetModel", client);
        }

        PushArrayString(array, fmt);
    }
}

public void OnClientDisconnect(int client)
{
    g_bReady[client] = false;
}


public void Rules_OnPlayerReady(int client)
{
    g_bReady[client] = true;

    if (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
    {
        PrepareSameModels(client);
    }
}


// Player spawned
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int  userid = GetEventInt(event, "userid");
    int  client = GetClientOfUserId(userid);
    
    // Valid?
    if (client && IsClientInGame(client) && (!g_bRules || g_bReady[client]))
    {
        // Valid team?
        if (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
        {
            PrepareSameModels(client);
        }
    }

    return Plugin_Continue;
}





// Player changed team
public Action eventPlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    // Reset model
    if (client && IsClientInGame(client))
    {
        PlayerHasModel[client] = 0;
        
        Format(PlayerModel[client], sizeof(PlayerModel[]), "");
    }

    return Plugin_Continue;
}





// Download all model files
void ModelDownloads()
{
    char sPath[PLATFORM_MAX_PATH + 1];
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/cubbi/ModelDownloads.txt");

    // Do we have a model downloads file?
    if (!FileExists(sPath))
    {
        LogError("Couldn't find \"%s\"", sPath);

        return;
    }


    // If yes, open it
    Handle downloadfile = OpenFile(sPath, "rb");
    
    // Read out all downloads
    if (downloadfile != INVALID_HANDLE)
    {
        while (!IsEndOfFile(downloadfile))
        {
            // And add them to the downloads table
            char filecontent[PLATFORM_MAX_PATH + 10];
            
            ReadFileLine(downloadfile, filecontent, sizeof(filecontent));
            ReplaceString(filecontent, sizeof(filecontent), " ", "");
            ReplaceString(filecontent, sizeof(filecontent), "\n", "");
            ReplaceString(filecontent, sizeof(filecontent), "\t", "");
            ReplaceString(filecontent, sizeof(filecontent), "\r", "");
            

            if (strlen(filecontent) > 2 && !(filecontent[0] == '/' && filecontent[1] == '/'))
            {
                if (filecontent[strlen(filecontent) - 1] == '*')
                {
                    filecontent[strlen(filecontent) - 2] = '\0';

                    if (DirExists(filecontent))
                    {
                        Handle dir = OpenDirectory(filecontent);

                        if (dir != INVALID_HANDLE)
                        {
                            char content[PLATFORM_MAX_PATH + 1];
                            FileType type;

                            while (ReadDirEntry(dir, content, sizeof(content), type))
                            {
                                if (type == FileType_File)
                                {
                                    Format(content, sizeof(content), "%s/%s", filecontent, content);

                                    AddFileToDownloadsTable(filecontent);
                                }
                            }
                        }
                    }
                    else
                    {
                        LogError("Found folder '%s' in ModelDownloads, but folder does not exist!", filecontent);
                    }
                }
                else
                {
                    if (FileExists(filecontent))
                    {
                        AddFileToDownloadsTable(filecontent);
                    }
                    else
                    {
                        LogError("Found file '%s' in ModelDownloads, but file does not exist!", filecontent);
                    }
                }
            }
        }

        delete downloadfile;
    }
}





// Player want a new model
public Action CmdModel(int client, int args)
{
    // Valid?
    if (client && IsClientInGame(client))
    {
        // Valid team?
        if (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
        {
            // Is in a new team?
            if (LastTeam[client] != GetClientTeam(client))
            {
                // Delete old Model
                PlayerHasModel[client] = 0;
                
                Format(PlayerModel[client], sizeof(PlayerModel[]), "");
            }
            
            // Get last Team
            LastTeam[client] = GetClientTeam(client);

            // is VIP?
            if (same_models) 
            {
                PrepareSameModels(client);
            }
            else
            { 
                PrepareRandomModels(client);
            }
        }
    }
    
    return Plugin_Handled;
}





// The model menu handler
public int ModelMenuCall(Handle menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        if (param1 && IsClientInGame(param1))
        {
            char ModelChoose[128];
            
            GetMenuItem(menu, param2, ModelChoose, sizeof(ModelChoose));
            

            // don't want standard model
            if (!StrEqual(ModelChoose, "standard"))
            {
                // set the new model
                SetEntityModel(param1, ModelChoose);
                
                // and mark it
                PlayerHasModel[param1] = 1;
                
                Format(PlayerModel[param1], sizeof(PlayerModel[]), ModelChoose);
            }
            else
            {
                // Reset model
                // But mark he don't want a model
                PlayerHasModel[param1] = 1;
                
                Format(PlayerModel[param1], sizeof(PlayerModel[]), "");
            }
        }
    }
    else if (action == MenuAction_End) 
    {
        delete menu;
    }

    return 0;
}






// Perpare the models
void PrepareSameModels(int client)
{
    // does the player have already a model?
    if (!PlayerHasModel[client])
    { 
        char ModelChooseLang[256];
        char StandardModel[256];

        bool found = false;
        

        // if not open a menu with model choose
        Format(ModelChooseLang, sizeof(ModelChooseLang), "%T", "ChooseModel", client);
        Format(StandardModel, sizeof(StandardModel), "%T", "StandardModel", client);
        
        Handle ModelMenu = CreateMenu(ModelMenuCall);
        
        SetMenuTitle(ModelMenu, ModelChooseLang);
        SetMenuExitButton(ModelMenu, false);


        // Loop through available models
        for (int item = 0; item < modelCount; item++)
        {
            // Right team and right level?
            if (GetClientTeam(client) == StringToInt(models[item][MODELTEAM]) && ((StringToInt(models[item][MODELLEVEL]) == 0) || (Cubbi_GetClientLevel(client) >= StringToInt(models[item][MODELLEVEL]))))
            {
                if (!StrEqual(models[item][MODELPATH], "") && !StrEqual(models[item][MODELPATH], "0"))
                {
                    // Add model to menu
                    AddMenuItem(ModelMenu, models[item][MODELPATH], models[item][MODELNAME]);

                    found = true;
                }
            }
        }
        

        // Also add standard choose
        AddMenuItem(ModelMenu, "standard", StandardModel);
        
        // Display the menu
        if (found)
        {
            SetMenuExitButton(ModelMenu, true);
            DisplayMenu(ModelMenu, client, MENU_TIME_FOREVER);
        }
        else
        {
            delete ModelMenu;
        }
    }
    else if (PlayerHasModel[client] && !StrEqual(PlayerModel[client], ""))
    {
        SetEntityModel(client, PlayerModel[client]);
    }
}






// Prepare random models
void PrepareRandomModels(int client)
{
    int randomValue;
    int found = 0;
    int modelsFound[64];


    // Collect available models of the client
    for (int item = 0; item < modelCount; item++)
    {
        if (StringToInt(models[item][MODELTEAM]) == GetClientTeam(client) && ((StringToInt(models[item][MODELLEVEL]) == 0) || (Cubbi_GetClientLevel(client) >= StringToInt(models[item][MODELLEVEL]))))
        {
            modelsFound[found] = item;

            found++;
        }
    }


    // Found available ones?
    if (found > 0)
    {
        // Get a random one
        randomValue = GetRandomInt(1, found);
        
        // set the new model
        if (!StrEqual(models[randomValue-1][MODELPATH], "") && !StrEqual(models[randomValue-1][MODELPATH], "0"))
        {
            SetEntityModel(client, models[randomValue-1][MODELPATH]);
        }
    }
}