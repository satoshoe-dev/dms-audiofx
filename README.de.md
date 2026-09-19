# AudioFX

[English](README.md) · **Deutsch** · [Español](README.es.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [日本語](README.ja.md) · [简体中文](README.zh_CN.md)

Ein Plugin für [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) mit drei Audio-Effekten: ein Visualizer an einer Bildschirmkante, ein Glow, der die hellen Stellen des Hintergrundbilds zur Musik pulsieren lässt, und eine runde Player-Scheibe für den Desktop.

![AudioFX](assets/screenshot.png)

Schritt für Schritt mit Bildern: [Anleitung zu Installation und Einrichtung](docs/GUIDE.de.md).

## Visualizer

Der Visualizer liegt an einer Bildschirmkante und spart den DMS-Rahmen und die Leiste aus. Es gibt acht Darstellungen: Welle gefüllt, Welle als Linie, Welle gespiegelt, Balken, Balken gespiegelt, Balken hängend, Blöcke und Punkte. Farbe, Deckkraft, Tiefe, Bänder, Abstand und Bildrate lassen sich einstellen.

cava läuft in der Grundeinstellung nur, solange ein MPRIS-Player spielt, und wird beendet, sobald die Wiedergabe endet. Ist „Nur bei laufender Wiedergabe“ ausgeschaltet, läuft cava dauerhaft und zeigt auch Ton von Programmen ohne MPRIS. Eine Kachel im Kontrollzentrum schaltet den Visualizer ein und aus.

## Glow

Das Plugin sucht im aktuellen Hintergrundbild nach leuchtenden Stellen: kräftige, helle Pixel im häufigsten Farbton, die sich von ihrer Umgebung abheben. Lampen, Glut, Neon oder Lava funktionieren gut. Große, gleichmäßig helle Flächen wie ein Himmel bleiben außen vor. Die Auswertung läuft einmal pro Hintergrundbild und wird zwischengespeichert.

Die Stellen leuchten dann zur Musik auf. Es gibt fünf Modi:

- Gleichzeitig: Jede Stelle folgt Bass und Lautstärke.
- Nach Tonhöhe: Große Stellen folgen dem Bass, mittlere den Mitten, kleine den Höhen.
- Fließend: Jeder Bassschlag schickt eine Leuchtfront über die Stellen, beginnend am Bildrand.
- Funkeln: Jede Stelle flackert in ihrem eigenen Rhythmus.
- Spektrum über die Breite: tiefe Töne links, hohe Töne rechts.

Ohne Wiedergabe kann der Glow aus bleiben, ruhig glimmen oder langsam atmen. Die Farbe kommt aus dem Bild oder vom DMS-Akzent.

## Player-Scheibe

Ein Desktop-Widget mit dem runden Cover des aktuellen Titels. Es dreht sich während der Wiedergabe, zeigt den Fortschritt des Titels als Ring und blendet beim Überfahren Zurück, Wiedergabe und Weiter ein. Um das Cover liegt ein Visualizer: eine Welle wie im DMS-Dashboard, Balken im Kreis oder ein Glow-Ring.

Läuft Pear Desktop (YouTube Music) mit eingeschaltetem API-Server, lädt die Scheibe das Cover in 1200 px. MPRIS liefert bei Chromium-basierten Playern nur 120 px.

## Voraussetzungen

- DankMaterialShell 1.6.1 oder neuer
- cava
- Für den Glow: python3 mit numpy und Pillow

Ich nutze es unter niri. Visualizer und Glow verwenden eigene Layer-Surfaces auf der Background-Ebene. Unter niri wandern Background-Surfaces mit den Workspaces mit, außer sie liegen im Backdrop. Diese Regeln in die niri-Konfiguration eintragen, damit beide an ihrem Platz bleiben:

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

Die Player-Scheibe ist ein normales DMS-Desktop-Widget und verhält sich wie die anderen Widgets auf dem jeweiligen Compositor.

## Installation

Aus der Plugin-Registry:

```sh
dms plugins install audioFx
dms ipc call plugins enable audioFx
```

Das Plugin steht auch in DMS unter Einstellungen → Plugins → Durchsuchen. Oder direkt aus dem Repository:

```sh
git clone https://github.com/satoshoe-dev/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
dms ipc call plugins enable audioFx
```

Die Player-Scheibe fügt man unter Einstellungen → Desktop Widgets → Desktop-Widget hinzufügen → AudioFX hinzu.

## IPC

```sh
dms ipc call audiofx glow on|off|toggle
dms ipc call audiofx mode sync|bands|flow|sparkle|spectrum
dms ipc call audiofx set <key> <value>
dms ipc call audiofx get <key>
```

`set` und `get` verwenden die Schlüssel aus den Plugin-Einstellungen, zum Beispiel `glowStrength` oder `discForm`.

## Leistung

Der Glow deckt den ganzen Bildschirm ab, deshalb zeichnet der Compositor ihn bei jedem Frame neu, solange Musik läuft. Die Bildrate des Glow steht standardmäßig auf 30 und lässt sich senken. Außerhalb der leuchtenden Stellen kehrt der Shader sofort zurück.

## Übersetzungen

Die Einstellungsseite gibt es auf Deutsch, Spanisch, Französisch, Italienisch, Portugiesisch, Russisch, Japanisch und vereinfachtem Chinesisch. Sie folgt der Sprache, die in DMS eingestellt ist. Wenn eine Übersetzung falsch klingt, ist ein Pull-Request willkommen.

## Hinweis

Ich habe dieses Plugin mit Hilfe von Claude (Anthropic) geschrieben und jede Änderung auf meinem eigenen niri-Desktop getestet. `AudioFxHalo.qml` basiert auf `MediaBlobHalo.qml` aus DankMaterialShell (MIT, Copyright (c) 2025 Avenge Media LLC).

## Lizenz

MIT
