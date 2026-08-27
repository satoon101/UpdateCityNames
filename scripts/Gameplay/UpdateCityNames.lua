-- ===========================================================================
--  Update City Names - Gameplay Script
--  Spawns extra units when human players create their first city.
-- ===========================================================================

print("=== Update City Names (Gameplay) Loading ===")

local UPDATE_IS_ENABLED = false
CurrentCityNames = {}

local function FindCurrentCityNames()
    for _, playerID in ipairs(PlayerManager.GetAliveIDs()) do
        local player = Players[playerID]
        if player ~= nil then
            for _, city in player:GetCities():Members() do
                local plotKey = city:GetX() .. "," .. city:GetY()
                CurrentCityNames[plotKey] = city:GetName()
            end
        end
    end
end

Events.LoadGameViewStateDone.Add(FindCurrentCityNames)
Events.TurnBegin.Add(FindCurrentCityNames)

local function UpdateCityName(playerID, cityID)
    if not UPDATE_IS_ENABLED then
        return
    end

    if next(CityNames) == nil then
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
    if CurrentCityNames[plotKey] then
        print("Not updating name")
        return
    end

    local city_count = cities:GetCount()
    local city_name = CityNames[city_count]
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
    CurrentCityNames[plotKey] = city_name
end

Events.CityAddedToMap.Add(UpdateCityName)

CityNames = {}
KNOWN_CITY_NAMES_BY_COUNT = {
    [47] = "LOC_CITY_NAME_SAN_FRANCISCO",
    [55] = "LOC_CITY_NAME_HOUSTON",
}
KNOWN_COUNT_BY_CITY_NAMES = {}
for k, v in pairs(KNOWN_CITY_NAMES_BY_COUNT) do
    KNOWN_COUNT_BY_CITY_NAMES[v] = k
end

local function GatherCityNames()
    UPDATE_IS_ENABLED = true
    if next(CityNames) ~= nil then
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
        local knownName = KNOWN_CITY_NAMES_BY_COUNT[count]
        if knownName ~= nil then
            CityNames[count] = knownName
            count = count + 1
        end
        if row.CivilizationType == civName then
            CityNames[count] = row.CityName
            count = count + 1
        end
    end

    for row in GameInfo.CityNames() do
        local knownName = KNOWN_CITY_NAMES_BY_COUNT[count]
        if knownName ~= nil then
            CityNames[count] = knownName
            count = count + 1
        end
        if row.CivilizationType == "CIVILIZATION_AMERICA" then
            if KNOWN_COUNT_BY_CITY_NAMES[row.CityName] == nil then
                CityNames[count] = row.CityName
                count = count + 1
            end
        end
    end
end

Events.LoadGameViewStateDone.Add(GatherCityNames)

print("=== Update City Names (Gameplay) Loaded ===")
