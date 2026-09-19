Config = {}

-- Points de vente (loto). Ajoute ou modifie selon ton serveur.
Config.Locations = {
    vector3(-1222.86, -906.87, 12.33), -- exemple: LTD Gunorama, Vespucci
}

Config.MarkerDistance = 8.0   -- distance a partir de laquelle le marqueur s'affiche
Config.InteractDistance = 1.5 -- distance a partir de laquelle on peut appuyer sur E

Config.Blip = {
    enabled = true,
    sprite = 59,
    color = 5,
    scale = 0.8,
    label = 'Loterie',
}

-- Pool de symboles utilises pour remplir la grille du ticket a gratter.
Config.Symbols = { '🍀', '💰', '🍒', '💎', '7️⃣', '🔔', '🍋', '⭐', '🍇' }

-- Chaque ticket a un prix et une table de recompenses ponderee (weight).
-- type = 'none'  -> perdu, aucun symbole "legende" associe
-- type = 'cash'  -> ajoute de l'argent liquide, symbole associe pour la grille
-- type = 'item'  -> ajoute un item d'inventaire, symbole associe pour la grille
--                   (verifie que ces items existent bien dans ton inventaire avant utilisation)
-- ticket.item = nom de l'item d'inventaire representant le ticket lui-meme
-- (a creer dans ton inventaire, marque "usable"). Achete = tu recois cet item,
-- tu l'utilises depuis l'inventaire quand tu veux pour le gratter.
Config.Tickets = {
    {
        id = 'chance',
        label = 'Ticket Chance',
        item = 'ticket_chance',
        price = 20,
        color = '#2ecc71',
        desc = 'Le ticket dabutant, petites mises, petits gains.',
        rewards = {
            { type = 'none', weight = 55 },
            { type = 'cash', amount = 20,  label = '20$',  symbol = '🍒', weight = 22 },
            { type = 'cash', amount = 50,  label = '50$',  symbol = '🍋', weight = 14 },
            { type = 'cash', amount = 100, label = '100$', symbol = '🍀', weight = 7 },
            { type = 'item', item = 'lockpick', amount = 1, label = 'Crochet', symbol = '🔔', weight = 2 },
        },
    },
    {
        id = 'fortune',
        label = 'Ticket Fortune',
        item = 'ticket_fortune',
        price = 50,
        color = '#3498db',
        desc = 'Plus cher, mais les gains sont bien plus consequents.',
        rewards = {
            { type = 'none', weight = 50 },
            { type = 'cash', amount = 50,   label = '50$',   symbol = '🍒', weight = 20 },
            { type = 'cash', amount = 150,  label = '150$',  symbol = '🍋', weight = 15 },
            { type = 'cash', amount = 300,  label = '300$',  symbol = '⭐', weight = 8 },
            { type = 'item', item = 'diamond', amount = 1, label = 'Diamant', symbol = '💎', weight = 5 },
            { type = 'cash', amount = 1000, label = '1000$ (JACKPOT)', symbol = '7️⃣', weight = 2 },
        },
    },
    {
        id = 'jackpot',
        label = 'Ticket Jackpot',
        item = 'ticket_jackpot',
        price = 100,
        color = '#e74c3c',
        desc = "Le plus cher, le plus risque, mais un vrai jackpot possible.",
        rewards = {
            { type = 'none', weight = 45 },
            { type = 'cash', amount = 100,  label = '100$',  symbol = '🍒', weight = 20 },
            { type = 'cash', amount = 250,  label = '250$',  symbol = '🍋', weight = 15 },
            { type = 'cash', amount = 500,  label = '500$',  symbol = '⭐', weight = 10 },
            { type = 'item', item = 'goldbar', amount = 1, label = "Barre d'or", symbol = '💎', weight = 6 },
            { type = 'cash', amount = 2500, label = '2500$ (JACKPOT)', symbol = '7️⃣', weight = 3 },
            { type = 'item', item = 'watch', amount = 1, label = 'Montre de luxe', symbol = '💰', weight = 1 },
        },
    },
}
