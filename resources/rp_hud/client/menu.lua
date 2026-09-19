local menuOpen = false

local function openMenu()
    if menuOpen then return end
    menuOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false

    -- Toujours retirer le focus NUI en sortant, sinon le joueur reste bloque
    -- (souris visible, impossible de bouger/tirer) meme si le HTML plante.
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterKeyMapping('rp_hud:toggleMenu', 'Ouvrir/fermer le menu', 'keyboard', Config.MenuKey)
RegisterCommand('rp_hud:toggleMenu', function()
    if menuOpen then
        closeMenu()
    else
        openMenu()
    end
end, false)

-- Le HTML appelle ca quand le joueur clique sur "Fermer" ou appuie sur Echap
RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('openInventory', function(_, cb)
    closeMenu()

    if GetResourceState(Config.InventoryResource) ~= 'started' then
        TriggerEvent('chat:addMessage', {
            args = { '^1Erreur', ('La ressource "%s" n\'est pas demarree sur ce serveur.'):format(Config.InventoryResource) }
        })
        cb('missing')
        return
    end

    -- ox_inventory gere lui-meme l'ouverture/fermeture (touche Echap, focus NUI, etc.)
    exports[Config.InventoryResource]:openInventory()
    cb('ok')
end)

-- Si le joueur meurt ou se deconnecte pendant que le menu est ouvert, on force la fermeture
-- pour ne jamais rester coince avec le focus NUI actif (bug classique).
AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and menuOpen then
        SetNuiFocus(false, false)
    end
end)

RegisterNetEvent('baseevents:onPlayerDied', function()
    if menuOpen then
        closeMenu()
    end
end)
