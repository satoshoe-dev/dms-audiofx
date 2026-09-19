# AudioFX: Schritt für Schritt

[English](GUIDE.md) · **Deutsch** · [Español](GUIDE.es.md) · [Français](GUIDE.fr.md) · [Italiano](GUIDE.it.md) · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · [简体中文](GUIDE.zh_CN.md)

## 1. Abhängigkeiten installieren

AudioFX liest den Ton über cava. Der Glow braucht zusätzlich python3 mit numpy und Pillow.

```sh
# Arch
sudo pacman -S cava python-numpy python-pillow
# Fedora
sudo dnf install cava python3-numpy python3-pillow
```

## 2. Plugin installieren und einschalten

Aus der Plugin-Registry:

```sh
dms plugins install audioFx
```

Oder klone das Repository in deinen DMS-Plugin-Ordner:

```sh
git clone https://github.com/satoshoe-dev/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
```

Öffne Einstellungen → Plugins und schalte AudioFX ein.

![Plugin-Liste mit AudioFX](images/01-plugin-list.png)

## 3. Nur niri: an Ort und Stelle halten

Unter niri wandern Hintergrundflächen mit den Workspaces mit, außer sie liegen im Backdrop. Füge diese Regeln in `~/.config/niri/config.kdl` ein:

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

Andere Compositors brauchen das nicht.

## 4. Der Visualizer

Spiel Musik ab. Der Visualizer erscheint an der unteren Kante.

![Visualizer an der unteren Kante](images/02-visualizer.png)

Klappe AudioFX in der Plugin-Liste auf, um ihn anzupassen. „Darstellung“ wechselt zwischen Welle, Balken, Blöcken und Punkten. „Kante“, „Tiefe“ und „Seitlich einrücken“ legen die Lage fest. „Farbe“ und „Deckkraft“ bestimmen das Aussehen.

![Visualizer-Einstellungen](images/03-visualizer-settings.png)

Flackern die Balken in leisen Passagen, erhöhe „Beruhigung“. Bewegen sie sich kaum, erhöhe „Empfindlichkeit“.

## 5. Ein und aus im Kontrollzentrum

Öffne das Kontrollzentrum, wechsle in den Bearbeitungsmodus, klicke auf „Widget hinzufügen“ und wähle AudioFX. Ein Klick auf die Kachel schaltet den Visualizer ein oder aus.

![AudioFX-Kachel im Kontrollzentrum](images/04-tile.png)

## 6. Der Glow

Scrolle zu „Glow im Hintergrundbild“ und schalte „Glow einschalten“ ein. AudioFX sucht leuchtende Stellen in deinem Hintergrundbild. Beim ersten Mal dauert das etwa eine Sekunde, danach liegt das Ergebnis im Cache.

![Glow-Einstellungen](images/05-glow-settings.png)

Der Glow wirkt am besten bei Hintergrundbildern mit kleinen hellen Lichtquellen: Lampen, Neon, Glut, Lichter einer Stadt. Auf einem Hintergrundbild ohne solche Stellen leuchtet nichts auf.

Wähle unter „Wie die Stellen pulsieren“, wie die Stellen reagieren:

- Gleichzeitig
- Nach Tonhöhe
- Fließend
- Funkeln
- Spektrum über die Breite

![Leuchtende Stellen im Hintergrundbild](images/06-glow.png)

Leuchtet zu viel oder zu wenig auf, verschiebe „Schwelle der Erkennung“. „Leuchtkraft“ und „Lichthof“ ändern die Helligkeit.

## 7. Die Player-Scheibe

Öffne Einstellungen → Desktop Widgets → Desktop-Widget hinzufügen und wähle AudioFX. Zieh die Scheibe an die gewünschte Stelle und passe ihre Größe an.

![Player-Scheibe auf dem Desktop](images/07-disc.png)

Fährst du mit der Maus über die Scheibe, erscheinen Zurück, Wiedergabe und Weiter. Unter „Player-Scheibe“ in den AudioFX-Einstellungen wählst du den Visualizer um das Cover: eine Welle, Balken im Kreis oder einen Glow-Ring.

## 8. Befehle (optional)

```sh
dms ipc call audiofx glow toggle
dms ipc call audiofx mode flow
dms ipc call audiofx set glowStrength 150
```
