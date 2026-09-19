ESX = exports['es_extended']:getSharedObject()

local SHOP_MENU_ID = 'zayko_ticketagratter_shop'

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

local function buildLegendText(ticket)
    local lines = { ticket.desc, '', 'Gains possibles :' }
    for _, r in ipairs(ticket.rewards) do
        if r.type ~= 'none' then
            lines[#lines + 1] = ('%s %s'):format(r.symbol, r.label)
        end
    end
    return table.concat(lines, '\n')
end

local function openShopMenu()
    exports.ZaykoRAGEUI:CreateMenu(SHOP_MENU_ID, '🎰 Loterie', 'Choisis ton ticket')

    for _, ticket in ipairs(Config.Tickets) do
        local label = ('%s - %d$'):format(ticket.label, ticket.price)
        exports.ZaykoRAGEUI:AddButton(SHOP_MENU_ID, label, buildLegendText(ticket), ticket.id)
    end

    exports.ZaykoRAGEUI:Open(SHOP_MENU_ID)
end

AddEventHandler('ZaykoRAGEUI:onSelect', function(menuId, data)
    if menuId ~= SHOP_MENU_ID then return end
    TriggerServerEvent('zayko_ticketagratter:buyTicket', data)
end)

local function openScratchScreen(resultData)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openScratch',
        result = resultData,
    })
end

RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb('ok')
end)

RegisterNetEvent('zayko_ticketagratter:openScratch', function(resultData)
    openScratchScreen(resultData)
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

                if IsControlJustPressed(0, 38) and not exports.ZaykoRAGEUI:IsOpen(SHOP_MENU_ID) then -- E
                    openShopMenu()
                end
            else
                isNearShop = false
            end
        else
            isNearShop = false
        end

        if not isNearShop and exports.ZaykoRAGEUI:IsOpen(SHOP_MENU_ID) then
            exports.ZaykoRAGEUI:Close()
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
