ESX = exports['es_extended']:getSharedObject()

local playerCooldowns = {}

local function getTicketById(id)
    for _, ticket in ipairs(Config.Tickets) do
        if ticket.id == id then
            return ticket
        end
    end
    return nil
end

local function getTicketByItem(item)
    for _, ticket in ipairs(Config.Tickets) do
        if ticket.item == item then
            return ticket
        end
    end
    return nil
end

local function onCooldown(src)
    local now = GetGameTimer()
    if playerCooldowns[src] and now - playerCooldowns[src] < 1000 then
        return true
    end
    playerCooldowns[src] = now
    return false
end

local function pickReward(rewards)
    local total = 0
    for _, r in ipairs(rewards) do
        total = total + r.weight
    end

    local roll = math.random(1, total)
    local cumulative = 0
    for _, r in ipairs(rewards) do
        cumulative = cumulative + r.weight
        if roll <= cumulative then
            return r
        end
    end

    return rewards[#rewards]
end

-- Genere une grille 3x3. Si winSymbol est fourni, il apparait exactement 3 fois
-- (ticket gagnant) et aucun autre symbole ne peut en atteindre 3.
-- Sinon, la grille est reguliere pour qu'aucun symbole n'apparaisse 3 fois (perdu).
local function generateGrid(winSymbol)
    local grid = {}

    if winSymbol then
        local positions = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
        for i = #positions, 2, -1 do
            local j = math.random(i)
            positions[i], positions[j] = positions[j], positions[i]
        end

        local winSet = {}
        for i = 1, 3 do
            winSet[positions[i]] = true
        end

        local otherSymbols = {}
        for _, s in ipairs(Config.Symbols) do
            if s ~= winSymbol then
                otherSymbols[#otherSymbols + 1] = s
            end
        end

        local counts = {}
        for i = 1, 9 do
            if winSet[i] then
                grid[i] = winSymbol
            else
                local chosen = nil
                for _ = 1, 30 do
                    local candidate = otherSymbols[math.random(#otherSymbols)]
                    if (counts[candidate] or 0) < 2 then
                        chosen = candidate
                        break
                    end
                end
                chosen = chosen or otherSymbols[math.random(#otherSymbols)]
                counts[chosen] = (counts[chosen] or 0) + 1
                grid[i] = chosen
            end
        end
    else
        for _ = 1, 100 do
            local counts = {}
            local ok = true
            for i = 1, 9 do
                local s = Config.Symbols[math.random(#Config.Symbols)]
                grid[i] = s
                counts[s] = (counts[s] or 0) + 1
                if counts[s] >= 3 then
                    ok = false
                end
            end
            if ok then break end
        end
    end

    return grid
end

-- Achat : on verifie/retire l'argent et on donne l'item ticket.
-- Le tirage (gagne/perdu) n'est PAS calcule ici : il l'est seulement quand
-- le joueur utilise le ticket depuis son inventaire, quand il veut.
RegisterNetEvent('zayko_ticketagratter:buyTicket', function(ticketId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if onCooldown(src) then return end

    local ticket = getTicketById(ticketId)
    if not ticket then return end

    if xPlayer.getMoney() < ticket.price then
        TriggerClientEvent('esx:showNotification', src, "Vous n'avez pas assez d'argent pour ce ticket.")
        return
    end

    xPlayer.removeMoney(ticket.price)
    xPlayer.addInventoryItem(ticket.item, 1)
    TriggerClientEvent('esx:showNotification', src,
        ('Ticket achete : %s. Utilise-le depuis ton inventaire quand tu veux le gratter.'):format(ticket.label))
end)

CreateThread(function()
    for _, ticket in ipairs(Config.Tickets) do
        ESX.RegisterUsableItem(ticket.item, function(playerId)
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if not xPlayer then return end
            if onCooldown(playerId) then return end

            local t = getTicketByItem(ticket.item)
            if not t then return end

            xPlayer.removeInventoryItem(t.item, 1)

            local reward = pickReward(t.rewards)
            local resultData = {
                ticketLabel = t.label,
                won = false,
                rewardLabel = 'Perdu, retente ta chance !',
            }

            if reward.type == 'none' then
                resultData.grid = generateGrid(nil)
            else
                resultData.grid = generateGrid(reward.symbol)
                resultData.won = true

                if reward.type == 'cash' then
                    xPlayer.addMoney(reward.amount)
                    resultData.rewardLabel = ('Gagne : %s'):format(reward.label)
                elseif reward.type == 'item' then
                    xPlayer.addInventoryItem(reward.item, reward.amount or 1)
                    resultData.rewardLabel = ('Gagne : %s'):format(reward.label)
                end
            end

            TriggerClientEvent('zayko_ticketagratter:openScratch', playerId, resultData)
        end)
    end
end)
