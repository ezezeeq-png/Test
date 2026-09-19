# zayko_ticketagratter

Ressource ESX (FiveM) : ticket a gratter achetable a un point de loterie.

## Fonctionnement

1. Le joueur s'approche d'un point de vente (`Config.Locations`).
2. Un marqueur + texte `[E] Ouvrir la loterie` s'affiche.
3. `E` ouvre le magasin (NUI) proposant 3 tickets differents (prix, legende des gains).
4. Le joueur achete un ticket : l'argent est verifie et retire cote serveur, le tirage
   (gagne/perdu + montant/item) est calcule cote serveur (anti-triche).
5. Le client recoit une grille de 9 symboles et affiche un **vrai mini-jeu de grattage**
   en Canvas : le joueur gratte a la souris (ou tactile) pour reveler chaque case.
   Le resultat final (deja decide par le serveur) s'affiche une fois toutes les cases revelees.

## Installation

1. Copie le dossier `zayko_ticketagratter` dans ton dossier `resources`.
2. Ajoute `ensure zayko_ticketagratter` dans ton `server.cfg` (apres `es_extended`).
3. Adapte `config.lua` :
   - `Config.Locations` : coordonnees du/des point(s) de vente.
   - `Config.Tickets` : prix, recompenses (argent et/ou items), ponderations (`weight`).
   - Verifie que les items utilises dans les recompenses (`lockpick`, `diamond`,
     `goldbar`, `watch`, ...) existent bien dans ton inventaire, ou remplace-les.

## Dependances

- `es_extended` (ESX Legacy)
