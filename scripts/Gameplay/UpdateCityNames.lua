-- ===========================================================================
--  Update City Names - Gameplay Script
--  Spawns extra units when human players create their first city.
-- ===========================================================================

print("=== Update City Names (Gameplay) Loading ===")

SAVE_KEY_CURRENT_CITY_NAMES = "UpdateCityNames_CurrentCityPlots"
g_CurrentCityNames = {}

function storeCurrentCityNames()
    local serializedString = ""

    for plotKey, isExempt in pairs(g_CurrentCityNames) do
        if isExempt then
            if string.len(serializedString) > 0 then
                serializedString = serializedString .. ";" .. plotKey
            else
                serializedString = plotKey
            end
        end
    end

    -- Write the raw string data into the game engine's save configuration file
    Game:SetProperty(SAVE_KEY_CURRENT_CITY_NAMES, serializedString)
end

function loadCurrentCityNames()
    g_CurrentCityNames = {} -- Reset memory allocation cleanly

    -- Retrieve the saved string data from the loaded file structure
    local serializedString = Game:GetProperty(SAVE_KEY_CURRENT_CITY_NAMES)

    if serializedString ~= nil then
        if string.len(serializedString) > 0 then
            -- Split the string by our semicolon delimiter
            for plotKey in string.gmatch(serializedString, "([^;]+)") do
                g_CurrentCityNames[plotKey] = true
            end
        end
    else
        findCurrentCityNames()
    end
end

function findCurrentCityNames()
    for _, playerID in ipairs(PlayerManager.GetAliveIDs()) do
        local player = Players[playerID]
        if player ~= nil then
            for _, city in player:GetCities():Members() do
                local plotKey = city:GetX() .. "," .. city:GetY()
                g_CurrentCityNames[plotKey] = city:GetName()
            end
        end
    end
end

function OnTurnBegin()
    findCurrentCityNames()
    storeCurrentCityNames()
end

Events.TurnBegin.Add(OnTurnBegin)

function updateCityName(playerID, cityID)
    if next(g_CityNames) == nil then
        print("Array is empty.")
        return
    end

    local player = Players[playerID]
    if not player:IsHuman() then
        print("Player is not human.")
        return
    end

    -- only run for the first city, once it's built
    local cities = player:GetCities()
    local city = cities:FindID(cityID)
    local plotKey = city:GetX() .. "," .. city:GetY()
    if g_CurrentCityNames[plotKey] then
        print("Not updating name")
        return
    end

    local city_count = cities:GetCount()
    local city_name = g_CityNames[city_count]
    if city_name == nil then
        print("No city name found.")
        return
    end

    local current_name = city:GetName()
    if current_name == city_name then
        print("No need to set name, already set to: " .. city_name)
        return
    end

    print("Setting name.  Current: " .. current_name .. " New: " .. city_name)
    city:SetName(city_name)
end

Events.CityAddedToMap.Add(updateCityName)

g_CityNames = {}
SAN_FRANCISCO_CITY_NUMBER = 47
SAN_FRANCISCO_CITY_NAME = "LOC_CITY_NAME_SAN_FRANCISCO"
HOUSTON_CITY_NUMBER = 55
HOUSTON_CITY_NAME = "LOC_CITY_NAME_HOUSTON"
DEFAULT_CITY_NAMES = {
    [SAN_FRANCISCO_CITY_NUMBER] = SAN_FRANCISCO_CITY_NAME,
    [HOUSTON_CITY_NUMBER] = HOUSTON_CITY_NAME,
}

function gatherCityNames()
    loadCurrentCityNames()
    if next(g_CityNames) ~= nil then
        return
    end

    local playerID = Game.GetLocalPlayer()
    local player = Players[playerID]
    if not player:IsHuman() then
        return
    end

    local civName = PlayerConfigurations[playerID]:GetCivilizationTypeName()
    if civName == "CIVILIZATION_AMERICA" then
        return
    end

    local count = 1
    for row in GameInfo.CityNames() do
        if (
            count == SAN_FRANCISCO_CITY_NUMBER or
            count == HOUSTON_CITY_NUMBER
        ) then
            g_CityNames[count] = DEFAULT_CITY_NAMES[count]
            count = count + 1
        end
        if row.CivilizationType == civName then
            g_CityNames[count] = row.CityName
            count = count + 1
        end
    end

    for row in GameInfo.CityNames() do
        if (
            count == SAN_FRANCISCO_CITY_NUMBER or
            count == HOUSTON_CITY_NUMBER
        ) then
            g_CityNames[count] = DEFAULT_CITY_NAMES[count]
            count = count + 1
        end
        if row.CivilizationType == "CIVILIZATION_AMERICA" then
            if (
                row.CityName ~= SAN_FRANCISCO_CITY_NAME and
                row.CityName ~= HOUSTON_CITY_NAME
            ) then
                g_CityNames[count] = row.CityName
                count = count + 1
            end
        end
    end
end

Events.LoadScreenClose.Add(gatherCityNames)

print("=== Update City Names (Gameplay) Loaded ===")
