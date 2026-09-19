-- Etat faim/soif : source unique de verite = Player(src).state (state bag, sync
-- automatique vers le client proprietaire). Un seul thread de decay total pour
-- tout le serveur (pas un thread par joueur, pas un thread par resource start),
-- ce qui evite le bug classique "la faim/soif descend 2x ou 3x trop vite" cause
-- par plusieurs boucles qui tournent en meme temps apres un restart de la ressource.

local activePlayers = {} -- [source] = true

local function kvpKey(license)
    return ('rp_hud:needs:%s'):format(license)
end

local function getLicense(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find('license:') == 1 then
            return id
        end
    end
    return nil
end

local function loadNeeds(src)
    local license = getLicense(src)
    if not license then
        return 100.0, 100.0
    end

    local raw = GetResourceKvpString(kvpKey(license))
    if not raw then
        return 100.0, 100.0
    end

    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then
        return 100.0, 100.0
    end

    return tonumber(data.hunger) or 100.0, tonumber(data.thirst) or 100.0
end

local function saveNeeds(src, hunger, thirst)
    local license = getLicense(src)
    if not license then return end

    SetResourceKvp(kvpKey(license), json.encode({ hunger = hunger, thirst = thirst }))
end

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function setNeeds(src, hunger, thirst, skipSave)
    hunger = clamp(hunger, 0, 100)
    thirst = clamp(thirst, 0, 100)

    local ply = Player(src)
    if not ply then return end

    ply.state:set('hunger', hunger, true)
    ply.state:set('thirst', thirst, true)

    TriggerClientEvent('rp_hud:client:needsUpdated', src, hunger, thirst)

    if not skipSave then
        saveNeeds(src, hunger, thirst)
    end
end

AddEventHandler('playerJoining', function()
    -- no-op: on attend l'evenement explicite du client (resource start) pour
    -- eviter de charger les needs avant que le personnage soit selectionne.
end)

RegisterNetEvent('rp_hud:server:requestNeeds', function()
    local src = source
    local hunger, thirst = loadNeeds(src)

    activePlayers[src] = true
    setNeeds(src, hunger, thirst, true)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activePlayers[src] then
        local ply = Player(src)
        if ply then
            saveNeeds(src, ply.state.hunger or 100.0, ply.state.thirst or 100.0)
        end
        activePlayers[src] = nil
    end
end)

exports('useConsumable', function(src, itemName)
    local item = Config.ConsumableItems[itemName]
    if not item then return false end

    local ply = Player(src)
    if not ply then return false end

    local hunger = (ply.state.hunger or 100.0) + (item.hunger or 0)
    local thirst = (ply.state.thirst or 100.0) + (item.thirst or 0)

    setNeeds(src, hunger, thirst)
    return true
end)

-- Boucle unique de decay. Garde active jusqu'a l'arret de la ressource.
CreateThread(function()
    while true do
        Wait(Config.NeedsTickMs)

        local hungerLoss = Config.HungerDecayPerMinute * (Config.NeedsTickMs / 60000)
        local thirstLoss = Config.ThirstDecayPerMinute * (Config.NeedsTickMs / 60000)

        for src in pairs(activePlayers) do
            local ply = Player(src)
            if not ply then
                activePlayers[src] = nil
            else
                local hunger = (ply.state.hunger or 100.0) - hungerLoss
                local thirst = (ply.state.thirst or 100.0) - thirstLoss

                setNeeds(src, hunger, thirst)

                if Config.StarvationHealthDamageThreshold > 0
                    and (hunger <= Config.StarvationHealthDamageThreshold
                        or thirst <= Config.StarvationHealthDamageThreshold) then
                    local health = GetEntityHealth(GetPlayerPed(src))
                    SetEntityHealth(GetPlayerPed(src), math.max(0, health - Config.StarvationHealthDamagePerTick))
                end
            end
        end
    end
end)
