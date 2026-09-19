# AudioFX: passo dopo passo

[English](GUIDE.md) · [Deutsch](GUIDE.de.md) · [Español](GUIDE.es.md) · [Français](GUIDE.fr.md) · **Italiano** · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · [简体中文](GUIDE.zh_CN.md)

## 1. Installa ciò che serve

AudioFX legge l'audio tramite cava. Il bagliore richiede inoltre python3 con numpy e Pillow.

```sh
# Arch
sudo pacman -S cava python-numpy python-pillow
# Fedora
sudo dnf install cava python3-numpy python3-pillow
```

## 2. Installa e attiva il plugin

Dal registro dei plugin:

```sh
dms plugins install audioFx
```

Oppure clona il repository nella cartella dei plugin di DMS:

```sh
git clone https://github.com/satoshoe-dev/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
```

Apri Impostazioni → Plugin e attiva AudioFX.

![Elenco dei plugin con AudioFX](images/01-plugin-list.png)

## 3. Solo niri: tienilo fermo

Su niri le superfici di sfondo si spostano con gli spazi di lavoro, a meno che non si trovino nel backdrop. Aggiungi queste regole a `~/.config/niri/config.kdl`:

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

Gli altri compositor non ne hanno bisogno.

## 4. Il visualizzatore

Riproduci un po' di musica. Il visualizzatore compare lungo il bordo inferiore.

![Visualizzatore sul bordo inferiore](images/02-visualizer.png)

Espandi AudioFX nell'elenco dei plugin per modificarlo. «Stile» alterna onde, barre, blocchi e punti. «Bordo», «Profondità» e «Rientro laterale» ne definiscono la posizione. «Colore» e «Opacità» ne definiscono l'aspetto.

![Impostazioni del visualizzatore](images/03-visualizer-settings.png)

Se le barre tremolano nei passaggi quieti, aumenta «Calma». Se si muovono appena, aumenta «Sensibilità».

## 5. Accendere e spegnere dal centro di controllo

Apri il centro di controllo, passa alla modalità di modifica, fai clic su «Aggiungi widget» e scegli AudioFX. Un clic sul riquadro accende o spegne il visualizzatore.

![Riquadro di AudioFX nel centro di controllo](images/04-tile.png)

## 6. Il bagliore

Scorri fino a «Bagliore nello sfondo» e attiva «Attiva bagliore». AudioFX cerca i punti luminosi nel tuo sfondo. La prima volta ci vuole circa un secondo, poi il risultato resta in cache.

![Impostazioni del bagliore](images/05-glow-settings.png)

Il bagliore rende al meglio con sfondi che hanno piccole fonti di luce intense: lampade, neon, braci, luci della città. Su uno sfondo senza punti di questo tipo non si illumina nulla.

Scegli come reagiscono i punti in «Come pulsano i punti»:

- Tutto insieme
- Per altezza
- Fluido
- Scintillio
- Spettro in larghezza

![Punti luminosi nello sfondo](images/06-glow.png)

Se si illumina troppo o troppo poco, sposta «Soglia di rilevamento». «Intensità del bagliore» e «Alone» cambiano la luminosità.

## 7. Il disco del lettore

Apri Impostazioni → Widget su desktop → Aggiungi widget su desktop e scegli AudioFX. Trascina il disco dove preferisci e ridimensionalo.

![Disco del lettore sul desktop](images/07-disc.png)

Passa il puntatore sul disco per brano precedente, riproduzione e brano successivo. In «Disco del lettore», nelle impostazioni di AudioFX, scegli il visualizzatore intorno alla copertina: un'onda, barre in cerchio o un anello luminoso. «Colora con il colore d’accento» colora la copertina con il colore d’accento di DMS.

## 8. Comandi (facoltativo)

```sh
dms ipc call audiofx glow toggle
dms ipc call audiofx mode flow
dms ipc call audiofx set glowStrength 150
```
