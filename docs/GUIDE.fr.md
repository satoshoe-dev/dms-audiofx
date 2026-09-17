# AudioFX : pas à pas

[English](GUIDE.md) · [Deutsch](GUIDE.de.md) · [Español](GUIDE.es.md) · **Français** · [Italiano](GUIDE.it.md) · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · [简体中文](GUIDE.zh_CN.md)

## 1. Installer les dépendances

AudioFX lit l'audio via cava. La lueur nécessite en plus python3 avec numpy et Pillow.

```sh
# Arch
sudo pacman -S cava python-numpy python-pillow
# Fedora
sudo dnf install cava python3-numpy python3-pillow
```

## 2. Installer et activer le plugin

```sh
git clone https://github.com/21Rebel/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
```

Ouvrez Paramètres → Plugins et activez AudioFX.

![Liste des plugins avec AudioFX](images/01-plugin-list.png)

## 3. niri uniquement : le garder en place

Sous niri, les surfaces d'arrière-plan se déplacent avec les espaces de travail, sauf si elles se trouvent dans le backdrop. Ajoutez ces règles à `~/.config/niri/config.kdl` :

```kdl
layer-rule {
    match namespace="^audiofx$"
    place-within-backdrop true
}
layer-rule {
    match namespace="^audiofx-glow$"
    place-within-backdrop true
}
```

Les autres compositeurs n'en ont pas besoin.

## 4. Le visualiseur

Lancez de la musique. Le visualiseur apparaît le long du bord inférieur.

![Visualiseur sur le bord inférieur](images/02-visualizer.png)

Dépliez AudioFX dans la liste des plugins pour le modifier. « Style » bascule entre ondes, barres, blocs et points. « Bord », « Profondeur » et « Retrait latéral » le positionnent. « Couleur » et « Opacité » règlent l'apparence.

![Réglages du visualiseur](images/03-visualizer-settings.png)

Si les barres scintillent dans les passages calmes, augmentez « Calme ». Si elles bougent à peine, augmentez « Sensibilité ».

## 5. Activer et désactiver depuis le centre de contrôle

Ouvrez le centre de contrôle, passez en mode édition, cliquez sur « Ajouter un widget » et choisissez AudioFX. Un clic sur la tuile active ou désactive le visualiseur.

![Tuile AudioFX dans le centre de contrôle](images/04-tile.png)

## 6. La lueur

Faites défiler jusqu'à « Lueur dans le fond d'écran » et activez « Activer la lueur ». AudioFX cherche les zones lumineuses de votre fond d'écran. La première fois, cela prend environ une seconde, ensuite le résultat est mis en cache.

![Réglages de la lueur](images/05-glow-settings.png)

La lueur fonctionne le mieux avec des fonds d'écran qui ont de petites sources de lumière vives : lampes, néons, braises, lumières de la ville. Sur un fond d'écran sans ces zones, rien ne s'allume.

Choisissez la réaction des zones sous « Façon dont les zones pulsent » :

- Tout ensemble
- Selon la hauteur
- Fluide
- Scintillement
- Spectre sur la largeur

![Zones lumineuses dans le fond d'écran](images/06-glow.png)

Si trop ou trop peu de zones s'allument, déplacez « Seuil de détection ». « Intensité de la lueur » et « Halo » modifient la luminosité.

## 7. Le disque du lecteur

Ouvrez Paramètres → Widgets de bureau → Ajouter un widget de bureau et choisissez AudioFX. Faites glisser le disque à l'endroit voulu et redimensionnez-le.

![Disque du lecteur sur le bureau](images/07-disc.png)

Survolez le disque pour afficher précédent, lecture et suivant. Sous « Disque du lecteur » dans les réglages d'AudioFX, choisissez le visualiseur autour de la pochette : une onde, des barres en cercle ou un anneau lumineux.

## 8. Commandes (facultatif)

```sh
dms ipc call audiofx glow toggle
dms ipc call audiofx mode flow
dms ipc call audiofx set glowStrength 150
```
