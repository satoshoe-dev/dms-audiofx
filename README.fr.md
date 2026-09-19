# AudioFX

[English](README.md) · [Deutsch](README.de.md) · [Español](README.es.md) · **Français** · [Italiano](README.it.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [日本語](README.ja.md) · [简体中文](README.zh_CN.md)

Un plugin pour [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) avec trois effets audio : un visualiseur le long d'un bord de l'écran, une lueur qui fait pulser en musique les zones claires du fond d'écran, et un disque du lecteur rond pour le bureau.

![AudioFX](assets/screenshot.png)

Pas à pas avec des images : [guide d'installation et de configuration](docs/GUIDE.fr.md).

## Visualiseur

Le visualiseur se place le long d'un bord de l'écran et évite le cadre et la barre DMS. Il existe huit styles : onde remplie, onde en ligne, onde en miroir, barres, barres en miroir, barres suspendues, blocs et points. La couleur, l'opacité, la profondeur, le nombre de bandes, l'espacement et la fréquence d'images sont réglables.

Par défaut, cava ne tourne que lorsqu'un lecteur MPRIS joue et s'arrête avec la lecture. Si « Uniquement pendant la lecture » est désactivé, cava tourne en permanence et affiche aussi le son des programmes sans MPRIS. Une tuile du centre de contrôle active et désactive le visualiseur.

## Lueur

Le plugin cherche les zones lumineuses du fond d'écran actuel : des pixels saturés et clairs dans la teinte la plus fréquente, qui se détachent de leur entourage. Les lampes, les braises, le néon ou la lave s'y prêtent bien. Les grandes zones éclairées de façon uniforme, comme un ciel, sont ignorées. L'analyse se fait une fois par fond d'écran et est mise en cache.

Les zones s'allument ensuite avec la musique. Il y a cinq modes :

- Tout ensemble : chaque zone suit les basses et le volume.
- Selon la hauteur : les grandes zones suivent les basses, les moyennes les médiums, les petites les aigus.
- Fluide : chaque coup de basse envoie un front lumineux le long des zones, à partir du bord de l'image.
- Scintillement : chaque zone scintille à son propre rythme.
- Spectre sur la largeur : les notes graves à gauche, les aiguës à droite.

Sans lecture, la lueur peut rester désactivée, luire doucement ou respirer lentement. La couleur vient de l'image ou de l'accent DMS.

## Disque du lecteur

Un widget de bureau avec la pochette ronde du morceau en cours. Il tourne pendant la lecture, affiche la progression du morceau sous forme d'anneau et montre précédent, lecture et suivant au survol. Autour de la pochette se trouve un visualiseur : une onde comme dans le tableau de bord de DMS, des barres en cercle ou un anneau lumineux.

Si Pear Desktop (YouTube Music) tourne avec son serveur API activé, le disque charge la pochette en 1200 px. MPRIS ne fournit que 120 px pour les lecteurs basés sur Chromium.

## Prérequis

- DankMaterialShell 1.6.1 ou plus récent
- cava
- Pour la lueur : python3 avec numpy et Pillow

Je l'utilise sous niri. Le visualiseur et la lueur utilisent leurs propres layer surfaces sur la couche background. Sous niri, les surfaces de cette couche se déplacent avec les espaces de travail, sauf si elles sont placées dans le backdrop. Ajoutez ces règles à votre configuration niri pour que les deux restent en place :

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

Le disque du lecteur est un widget de bureau DMS ordinaire et se comporte comme les autres widgets sur votre compositeur.

## Installation

Depuis le registre des plugins :

```sh
dms plugins install audioFx
dms ipc call plugins enable audioFx
```

Il figure aussi dans DMS sous Paramètres → Plugins → Parcourir. Pour l’installer depuis le dépôt :

```sh
git clone https://github.com/satoshoe-dev/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
dms ipc call plugins enable audioFx
```

Ajoutez le disque du lecteur dans Paramètres → Widgets de bureau → Ajouter un widget de bureau → AudioFX.

## IPC

```sh
dms ipc call audiofx glow on|off|toggle
dms ipc call audiofx mode sync|bands|flow|sparkle|spectrum
dms ipc call audiofx set <key> <value>
dms ipc call audiofx get <key>
```

`set` et `get` utilisent les clés des paramètres du plugin, par exemple `glowStrength` ou `discForm`.

## Performances

La lueur couvre tout l'écran, donc le compositeur la redessine à chaque image pendant que la musique joue. La fréquence d'images de la lueur est réglée sur 30 par défaut et peut être baissée. En dehors des zones lumineuses, le shader retourne immédiatement.

## Traductions

La page des paramètres est disponible en allemand, espagnol, français, italien, portugais, russe, japonais et chinois simplifié, et suit la langue choisie dans DMS. Si une traduction sonne faux, une pull request est la bienvenue.

## Remarque

J'ai écrit ce plugin avec l'aide de Claude (Anthropic) et j'ai testé chaque modification sur mon propre bureau niri. `AudioFxHalo.qml` est basé sur `MediaBlobHalo.qml` de DankMaterialShell (MIT, Copyright (c) 2025 Avenge Media LLC).

## Licence

MIT
