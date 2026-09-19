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
-- Sinon, la grille est reguliree pour qu'aucun symbole n'apparaisse 3 fois (perdu).
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

RegisterNetEvent('zayko_ticketagratter:buyTicket', function(ticketId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local now = GetGameTimer()
    if playerCooldowns[src] and now - playerCooldowns[src] < 1000 then
        return
    end
    playerCooldowns[src] = now

    local ticket = getTicketById(ticketId)
    if not ticket then return end

    if xPlayer.getMoney() < ticket.price then
        TriggerClientEvent('esx:showNotification', src, "Vous n'avez pas assez d'argent pour ce ticket.")
        TriggerClientEvent('zayko_ticketagratter:buyDenied', src)
        return
    end

    xPlayer.removeMoney(ticket.price)

    local reward = pickReward(ticket.rewards)
    local resultData = {
        ticketLabel = ticket.label,
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

    TriggerClientEvent('zayko_ticketagratter:ticketResult', src, resultData)
end)
