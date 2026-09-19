-- HUD faim/soif. La valeur de verite est cote serveur (Player(src).state),
-- le client se contente d'afficher ce qu'on lui envoie : jamais de decay calcule
-- localement, sinon le client et le serveur se desynchronisent (bug classique).

local function updateHudBars(hunger, thirst)
    SendNUIMessage({
        action = 'needs',
        hunger = hunger,
        thirst = thirst
    })
end

RegisterNetEvent('rp_hud:client:needsUpdated', function(hunger, thirst)
    updateHudBars(hunger, thirst)
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    TriggerServerEvent('rp_hud:server:requestNeeds')
end)
