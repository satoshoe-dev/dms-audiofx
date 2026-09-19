# AudioFX

[English](README.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · **Italiano** · [Português](README.pt.md) · [Русский](README.ru.md) · [日本語](README.ja.md) · [简体中文](README.zh_CN.md)

Un plugin per [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) con tre effetti audio: un visualizzatore lungo un bordo dello schermo, un bagliore che fa pulsare a tempo di musica i punti luminosi dello sfondo e un disco del lettore rotondo per il desktop.

![AudioFX](assets/screenshot.png)

Passo per passo con immagini: [guida all'installazione e alla configurazione](docs/GUIDE.it.md).

## Visualizzatore

Il visualizzatore si trova lungo un bordo dello schermo e lascia libere la cornice e la barra di DMS. Ci sono otto stili: onda piena, onda come linea, onda speculare, barre, barre speculari, barre sospese, blocchi e punti. Colore, opacità, profondità, numero di bande, spaziatura e frequenza fotogrammi sono regolabili.

Per impostazione predefinita cava gira solo mentre un lettore MPRIS è in riproduzione e si chiude quando la riproduzione si ferma. Con «Solo durante la riproduzione» disattivato, cava resta attivo e mostra anche l'audio dei programmi senza MPRIS. Un riquadro nel centro di controllo accende e spegne il visualizzatore.

## Bagliore

Il plugin cerca i punti luminosi nello sfondo attuale: pixel saturi e luminosi nella tonalità più frequente che spiccano rispetto a ciò che li circonda. Lampade, braci, neon o lava funzionano bene. Le grandi aree illuminate in modo uniforme, come un cielo, vengono escluse. L'analisi viene eseguita una volta per sfondo e salvata in cache.

Poi i punti si illuminano con la musica. Ci sono cinque modalità:

- Tutto insieme: ogni punto segue bassi e volume.
- Per altezza: i punti grandi seguono i bassi, quelli medi i medi, quelli piccoli gli acuti.
- Fluido: ogni colpo di basso manda un fronte di luce lungo i punti, partendo dal bordo dell'immagine.
- Scintillio: ogni punto sfarfalla con un ritmo tutto suo.
- Spettro in larghezza: note basse a sinistra, note alte a destra.

Senza riproduzione il bagliore può restare disattivato, brillare piano o respirare lentamente. Il colore viene dall'immagine o dall'accento di DMS.

## Disco del lettore

Un widget su desktop con la copertina rotonda del brano in corso. Gira durante la riproduzione, mostra l'avanzamento del brano come un anello e al passaggio del puntatore mostra precedente, play e successivo. Intorno alla copertina c'è un visualizzatore: un'onda come nella dashboard di DMS, barre in cerchio o un anello luminoso.

Se Pear Desktop (YouTube Music) è in esecuzione con il server API attivo, il disco carica la copertina a 1200 px. MPRIS fornisce solo 120 px per i lettori basati su Chromium.

## Requisiti

- DankMaterialShell 1.6.1 o successivo
- cava
- Per il bagliore: python3 con numpy e Pillow

Io lo uso su niri. Il visualizzatore e il bagliore usano layer surface proprie sul livello background. Su niri le surface di quel livello si spostano insieme agli spazi di lavoro, a meno che non siano messe nel backdrop. Aggiungi queste regole alla configurazione di niri perché restino entrambi al loro posto:

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

Il disco del lettore è un normale widget su desktop di DMS e si comporta come gli altri widget sul tuo compositor.

## Installazione

Dal registro dei plugin:

```sh
dms plugins install audioFx
dms ipc call plugins enable audioFx
```

Si trova anche in DMS in Impostazioni → Plugin → Sfoglia. Per installarlo dal repository:

```sh
git clone https://github.com/satoshoe-dev/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
dms ipc call plugins enable audioFx
```

Aggiungi il disco del lettore da Impostazioni → Widget su desktop → Aggiungi widget su desktop → AudioFX.

## IPC

```sh
dms ipc call audiofx glow on|off|toggle
dms ipc call audiofx mode sync|bands|flow|sparkle|spectrum
dms ipc call audiofx set <key> <value>
dms ipc call audiofx get <key>
```

`set` e `get` usano le chiavi delle impostazioni del plugin, ad esempio `glowStrength` o `discForm`.

## Prestazioni

Il bagliore copre tutto lo schermo, quindi il compositor lo ridisegna a ogni fotogramma mentre suona la musica. La frequenza fotogrammi del bagliore è 30 di default e si può abbassare. Fuori dai punti luminosi lo shader ritorna subito.

## Traduzioni

La pagina delle impostazioni è disponibile in tedesco, spagnolo, francese, italiano, portoghese, russo, giapponese e cinese semplificato e segue la lingua impostata in DMS. Se una traduzione suona male, una pull request è benvenuta.

## Nota

Ho scritto questo plugin con l'aiuto di Claude (Anthropic) e ho provato ogni modifica sul mio desktop niri. `AudioFxHalo.qml` si basa su `MediaBlobHalo.qml` di DankMaterialShell (MIT, Copyright (c) 2025 Avenge Media LLC).

## Licenza

MIT
