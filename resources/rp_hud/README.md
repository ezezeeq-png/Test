# rp_hud

Menu F5 + faim/soif corrigees, pense pour un serveur QBCore/standalone avec
[ox_inventory](https://github.com/overextended/ox_inventory) comme inventaire.

## Installation

1. Place ce dossier dans `resources/rp_hud`.
2. Installe `ox_inventory` separement (ce n'est pas vendorise ici, c'est une
   grosse ressource externe avec ses propres dependances : `git clone
   https://github.com/overextended/ox_inventory` dans `resources/`).
3. Dans `server.cfg`, demarre les deux ressources, `ox_inventory` avant `rp_hud` :
   ```
   ensure ox_inventory
   ensure rp_hud
   ```

## Brancher les items consommables sur ox_inventory

`rp_hud` expose un export serveur `useConsumable(source, itemName)` qui applique
les effets definis dans `config.lua` (`Config.ConsumableItems`).

Dans `ox_inventory/data/items.lua`, pour chaque item consommable, ajoute une
reference vers cet export cote serveur. Le nom exact du champ depend de la
version d'ox_inventory installee (`server.export` sur les versions recentes) —
verifie la doc/le code de ta version avant de copier tel quel :

```lua
['water_bottle'] = {
    label = 'Bouteille d\'eau',
    weight = 500,
    stack = true,
    close = true,
    server = {
        export = 'rp_hud.useConsumable'
    }
},
```

C'est volontairement laisse a brancher a la main : ce depot ne contient pas le
code source d'ox_inventory, donc je ne peux pas garantir la signature exacte
de ce hook pour ta version sans l'avoir sous les yeux.

## Ce que ca corrige

- **Menu qui reste bloque a l'ecran** : `SetNuiFocus(false, false)` est
  desormais appele systematiquement a la fermeture (bouton, Echap, mort du
  joueur, arret de la ressource), plus jamais seulement dans un des chemins.
- **Faim/soif qui descend trop vite** : un seul thread de decay pour tout le
  serveur (avant, un thread par joueur ou un thread relance a chaque restart
  de ressource pouvait cumuler plusieurs decays en parallele).
- **Boire de l'eau qui n'augmente pas la soif** : la logique de consommation
  passe par un seul point d'entree (`useConsumable`) qui ecrit dans le state
  bag serveur, source unique de verite. Le client n'a plus sa propre copie
  qui peut se desynchroniser.
- **Reset de la faim/soif a la reconnexion** : persistance via KVP serveur
  (par `license`), rechargee au demarrage de la ressource cote joueur.
