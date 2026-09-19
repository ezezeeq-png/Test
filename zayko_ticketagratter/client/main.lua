ESX = exports['es_extended']:getSharedObject()

local isMenuOpen = false
local isNearShop = false

local function drawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(x, y)
end

local function buildTicketsForNui()
    local list = {}
    for _, ticket in ipairs(Config.Tickets) do
        local legend = {}
        for _, r in ipairs(ticket.rewards) do
            if r.type ~= 'none' then
                legend[#legend + 1] = { symbol = r.symbol, label = r.label }
            end
        end
        list[#list + 1] = {
            id = ticket.id,
            label = ticket.label,
            price = ticket.price,
            desc = ticket.desc,
            color = ticket.color,
            legend = legend,
        }
    end
    return list
end

local function openStore()
    if isMenuOpen then return end
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openStore',
        tickets = buildTicketsForNui(),
    })
end

local function closeMenu()
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('buyTicket', function(data, cb)
    TriggerServerEvent('zayko_ticketagratter:buyTicket', data.id)
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNetEvent('zayko_ticketagratter:ticketResult', function(resultData)
    SendNUIMessage({
        action = 'openScratch',
        result = resultData,
    })
end)

RegisterNetEvent('zayko_ticketagratter:buyDenied', function()
    SendNUIMessage({ action = 'buyDenied' })
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local closest, closestDist = nil, Config.MarkerDistance

        for _, coords in ipairs(Config.Locations) do
            local dist = #(playerCoords - coords)
            if dist < closestDist then
                closest = coords
                closestDist = dist
            end
        end

        if closest then
            sleep = 0
            DrawMarker(1, closest.x, closest.y, closest.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 0.6,
                255, 215, 0, 120, false, true, 2, false, nil, nil, false)

            if closestDist < Config.InteractDistance then
                isNearShop = true
                drawText3D(closest, '[E] Ouvrir la loterie')

                if IsControlJustPressed(0, 38) and not isMenuOpen then -- E
                    openStore()
                end
            else
                isNearShop = false
            end
        else
            isNearShop = false
        end

        if isMenuOpen and not isNearShop then
            closeMenu()
        end

        Wait(sleep)
    end
end)

if Config.Blip.enabled then
    CreateThread(function()
        for _, coords in ipairs(Config.Locations) do
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, Config.Blip.sprite)
            SetBlipColour(blip, Config.Blip.color)
            SetBlipScale(blip, Config.Blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(Config.Blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end)
end
