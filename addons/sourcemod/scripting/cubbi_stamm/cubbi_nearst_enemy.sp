#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <autoexecconfig>
#include <cubbi>

#define FEATURE_NAME_DISTANCE "Nearest Enemy - Distance"
#define FEATURE_NAME_DIRECTION "Nearest Enemy - Direction"
#define FEATURE_DESCRIPTION_DISTANCE "See the distance to the nearest player"
#define FEATURE_DESCRIPTION_DIRECTION "See the direction to the nearest player"

enum struct GlobalData {
    ConVar LevelDistance;
    ConVar LevelDirection;
    ConVar PointsDistance;
    ConVar PointsDirection;
    ConVar ExpirationDistance;
    ConVar ExpirationDirection;
    ConVar RefundableDistance;
    ConVar RefundableDirection;
    ConVar TradableDistance;
    ConVar TradableDirection;
}
GlobalData Core;

enum struct PlayerData {
    bool Distance;
    bool Direction;

    void Reset() {
        this.Distance = false;
        this.Direction = false;
    }
}
PlayerData Player[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Cubbi - Nearst Enemy (Distance + Direction)",
    author = "Bara (Original author: dordnung)",
    version = "1.0.0",
    description = "",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("cubbi.nearest_enemy");
    Core.LevelDistance = AutoExecConfig_CreateConVar("connect_message_level_distance", "5", "[Distance] Which level is required to bought this feature?");
    Core.LevelDirection = AutoExecConfig_CreateConVar("connect_message_level_direction", "5", "[Direction] Which level is required to bought this feature?");
    Core.PointsDistance = AutoExecConfig_CreateConVar("connect_message_points_distance", "200", "[Distance] How much points are required to bought this feature?");
    Core.PointsDirection = AutoExecConfig_CreateConVar("connect_message_points_direction", "200", "[Direction] How much points are required to bought this feature?");
    Core.ExpirationDistance = AutoExecConfig_CreateConVar("connect_message_expiration_distance", "0", "[Distance] How long (time in minutes) this feature for earch should be exists? 0 - Lifetime");
    Core.ExpirationDirection = AutoExecConfig_CreateConVar("connect_message_expiration_direction", "0", "[Direction] How long (time in minutes) this feature for earch should be exists? 0 - Lifetime");
    Core.RefundableDistance = AutoExecConfig_CreateConVar("connect_message_refundable_distance", "1", "[Distance] Allow players to refund this feature?", _, true, 0.0, true, 1.0);
    Core.RefundableDirection = AutoExecConfig_CreateConVar("connect_message_refundable_direction", "1", "[Direction] Allow players to refund this feature?", _, true, 0.0, true, 1.0);
    Core.TradableDistance = AutoExecConfig_CreateConVar("connect_message_tradable_distance", "0", "[Distance] Allow players to trade this feature to other players or market?", _, true, 0.0, true, 1.0);
    Core.TradableDirection = AutoExecConfig_CreateConVar("connect_message_tradable_direction", "0", "[Direction] Allow players to trade this feature to other players or market?", _, true, 0.0, true, 1.0);
    AutoExecConfig_CleanFile();
    AutoExecConfig_ExecuteFile();
}

public void OnConfigsExecuted()
{
    if (FindConVar("sv_hudhint_sound") != null)
    {
        SetConVarInt(FindConVar("sv_hudhint_sound"), 0);
    }
}

public void Cubbi_OnLoaded()
{
    if (
        Cubbi_RegisterFeature(FEATURE_NAME_DISTANCE, FEATURE_DESCRIPTION_DISTANCE, Core.LevelDistance.IntValue, Core.PointsDistance.IntValue, Core.ExpirationDistance.IntValue, Core.RefundableDistance.BoolValue, Core.TradableDistance.BoolValue)
            &&
        Cubbi_RegisterFeature(FEATURE_NAME_DIRECTION, FEATURE_DESCRIPTION_DIRECTION, Core.LevelDirection.IntValue, Core.PointsDirection.IntValue, Core.ExpirationDirection.IntValue, Core.RefundableDirection.BoolValue, Core.TradableDirection.BoolValue)
        )
    {
        CreateTimer(0.2, Timer_CheckClients, _, TIMER_REPEAT);
    }
}

public void OnClientPutInServer(int client)
{
    Player[client].Reset();
}

public void Cubbi_OnClientReady(int client, ArrayList features)
{
    for (int i = 0; i < features.Length; i++)
    {
        PlayerFeatureData PlayerFeature;
        features.GetArray(i, PlayerFeature, sizeof(PlayerFeature));
        
        if (StrEqual(PlayerFeature.Name, FEATURE_NAME_DISTANCE, false))
        {
            Player[client].Distance = true;
        }

        if (StrEqual(PlayerFeature.Name, FEATURE_NAME_DIRECTION, false))
        {
            Player[client].Direction = true;
        }

        if (Player[client].Distance && Player[client].Direction)
        {
            break;
        }
    }
}

public Action Timer_CheckClients(Handle timer)
{
    float clientOrigin[3];
    float searchOrigin[3];
    float near;
    float distance;

    int nearest;

    for (int client = 1; client <= MaxClients; client++)
    {
        if ((Player[client].Distance || Player[client].Direction) && IsPlayerAlive(client))
        {
            nearest = 0;
            near = 0.0;

            GetClientAbsOrigin(client, clientOrigin);

            for (int search = 1; search <= MaxClients; search++)
            {
                if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
                {
                    GetClientAbsOrigin(search, searchOrigin);

                    distance = GetVectorDistance(clientOrigin, searchOrigin);

                    if (near == 0.0)
                    {
                        near = distance;
                        nearest = search;
                    }

                    if (distance < near)
                    {
                        near = distance;
                        nearest = search;
                    }
                }
            }

            if (nearest != 0)
            {
                float dist;
                float vecPoints[3];
                float vecAngles[3];
                float clientAngles[3];
                
                char directionString[64];
                char textToPrint[64];

                if (Player[client].Direction)
                {
                    // Get the origin of the nearest player
                    GetClientAbsOrigin(nearest, searchOrigin);

                    // Angles
                    GetClientAbsAngles(client, clientAngles);

                    // Angles from origin
                    MakeVectorFromPoints(clientOrigin, searchOrigin, vecPoints);
                    GetVectorAngles(vecPoints, vecAngles);

                    // Differenz
                    float diff = clientAngles[1] - vecAngles[1];

                    // Correct it
                    if (diff < -180)
                    {
                        diff = 360 + diff;
                    }

                    if (diff > 180)
                    {
                        diff = 360 - diff;
                    }

                    // Up
                    if (diff >= -22.5 && diff < 22.5)
                    {
                        Format(directionString, sizeof(directionString), "\xe2\x86\x91");
                    }

                    // right up
                    else if (diff >= 22.5 && diff < 67.5)
                    {
                        Format(directionString, sizeof(directionString), "\xe2\x86\x97");
                    }

                    // right
                    else if (diff >= 67.5 && diff < 112.5)
                    {
                        Format(directionString, sizeof(directionString), "\xe2\x86\x92");
                    }

                    // right down
                    else if (diff >= 112.5 && diff < 157.5)
                    {
                        Format(directionString, sizeof(directionString), "\xe2\x86\x98");
                    }

                    // down
                    else if (diff >= 157.5 || diff < -157.5)
                    {
                        Format(directionString, sizeof(directionString), "\xe2\x86\x93");
                    }

                    // down left
                    else if (diff >= -157.5 && diff < -112.5)
                    {
                        Format(directionString, sizeof(directionString), "\xe2\x86\x99");
                    }

                    // left
                    else if (diff >= -112.5 && diff < -67.5)
                    {
                        Format(directionString, sizeof(directionString), "\xe2\x86\x90");
                    }

                    // left up
                    else if (diff >= -67.5 && diff < -22.5)
                    {
                        Format(directionString, sizeof(directionString), "\xe2\x86\x96");
                    }

                    if (Player[client].Distance)
                    {
                        Format(textToPrint, sizeof(textToPrint), "%s\n", directionString);
                    }
                    else
                    {
                        Format(textToPrint, sizeof(textToPrint), directionString);
                    }
                }

                if (Player[client].Distance)
                {
                    // Distance to meters
                    dist = near * 0.01905;
                    Format(textToPrint, sizeof(textToPrint), "%s(%i %s)", textToPrint, RoundFloat(dist), (RoundFloat(dist) == 1 ? "meter" : "meters"));
                }

                PrintHintText(client, textToPrint);
            }
        }
    }

    return Plugin_Continue;
}
