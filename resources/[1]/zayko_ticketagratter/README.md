# zayko_ticketagratter

Ressource ESX (FiveM) : ticket a gratter achetable a un point de loterie.

## Fonctionnement

1. Le joueur s'approche d'un point de vente (`Config.Locations`).
2. Un marqueur + texte `[E] Ouvrir la loterie` s'affiche.
3. `E` ouvre le magasin en **ZaykoRAGEUI** (menu natif, pas de NUI) proposant 3 tickets
   differents (prix, legende des gains).
4. Le joueur achete un ticket : l'argent est verifie et retire cote serveur, et il
   recoit l'item correspondant dans son inventaire (`ticket_chance`, `ticket_fortune`,
   `ticket_jackpot`). **Rien ne se gratte a l'achat.**
5. Quand le joueur veut, il utilise le ticket depuis son inventaire. Le tirage
   (gagne/perdu + montant/item) est alors calcule cote serveur (anti-triche), l'item
   est consomme, et le client affiche un **vrai mini-jeu de grattage** en Canvas :
   le joueur gratte a la souris (ou tactile) pour reveler chaque case. Le resultat
   final (deja decide par le serveur) s'affiche une fois toutes les cases revelees.

## Installation

1. Copie les dossiers `ZaykoRAGEUI` et `zayko_ticketagratter` dans ton dossier `resources`.
2. Dans `server.cfg`, demarre-les dans cet ordre (apres `es_extended`) :
   ```
   ensure es_extended
   ensure ZaykoRAGEUI
   ensure zayko_ticketagratter
   ```
3. Cree les items `ticket_chance`, `ticket_fortune`, `ticket_jackpot` dans ton
   inventaire (items.lua / table SQL selon ton systeme), marques **usables/utilisables**.
4. Adapte `config.lua` :
   - `Config.Locations` : coordonnees du/des point(s) de vente.
   - `Config.Tickets` : prix, item du ticket, recompenses (argent et/ou items),
     ponderations (`weight`).
   - Verifie que les items utilises dans les recompenses (`lockpick`, `diamond`,
     `goldbar`, `watch`, ...) existent bien dans ton inventaire, ou remplace-les.

## Dependances

- `es_extended` (ESX Legacy)
- `ZaykoRAGEUI` (fourni a cote, menu natif simple, aucune autre dependance)
