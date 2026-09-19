Config = {}

-- Touche qui ouvre/ferme le menu (rebindable par le joueur dans les parametres FiveM > Touches > FiveM)
Config.MenuKey = 'F5'

-- Nom exact de la ressource inventaire a utiliser (ox_inventory)
Config.InventoryResource = 'ox_inventory'

-- Faim / soif : perte de points par minute
Config.HungerDecayPerMinute = 1.0
Config.ThirstDecayPerMinute = 1.4

-- Intervalle du thread serveur de decay (ms). Un seul thread par joueur, jamais plusieurs.
Config.NeedsTickMs = 60000

-- En dessous de ce seuil, le joueur commence a perdre de la vie (0 = desactive)
Config.StarvationHealthDamageThreshold = 5
Config.StarvationHealthDamagePerTick = 1

-- Items consommables et leur effet. name = nom exact de l'item cote inventaire (ox_inventory).
Config.ConsumableItems = {
    water_bottle = { thirst = 40 },
    bread        = { hunger = 25 },
    sandwich     = { hunger = 35 },
}
