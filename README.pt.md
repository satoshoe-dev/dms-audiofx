# AudioFX

[English](README.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Italiano](README.it.md) · **Português** · [Русский](README.ru.md) · [日本語](README.ja.md) · [简体中文](README.zh_CN.md)

Um plugin para o [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) com três efeitos de áudio: um visualizador ao longo de uma borda da tela, um brilho que faz os pontos claros do papel de parede pulsarem com a música e um disco do player redondo para a área de trabalho.

![AudioFX](assets/screenshot.png)

Passo a passo com imagens: [guia de instalação e configuração](docs/GUIDE.pt.md).

## Visualizador

O visualizador fica ao longo de uma borda da tela e deixa de fora a moldura e a barra do DMS. São oito estilos: onda preenchida, onda como linha, onda espelhada, barras, barras espelhadas, barras suspensas, blocos e pontos. Cor, opacidade, profundidade, número de bandas, espaçamento e taxa de quadros são ajustáveis.

O cava só roda enquanto um player MPRIS está tocando. Quando a reprodução para, o processo é encerrado, e não apenas ocultado. Um bloco no painel de controle liga e desliga o visualizador.

## Brilho

O plugin procura pontos luminosos no papel de parede atual: pixels saturados e claros no tom mais frequente, que se destacam do entorno. Lâmpadas, brasas, neon ou lava funcionam bem. Áreas grandes com luz uniforme, como um céu, ficam de fora. A análise roda uma vez por papel de parede e fica em cache.

Depois os pontos acendem com a música. São cinco modos:

- Tudo junto: todos os pontos seguem o grave e o volume.
- Por altura: pontos grandes seguem os graves, médios seguem os médios, pequenos seguem os agudos.
- Fluindo: cada batida de grave manda uma frente de luz pelos pontos, começando na borda da imagem.
- Cintilar: cada ponto pisca no seu próprio ritmo.
- Espectro ao longo da largura: notas graves à esquerda, agudas à direita.

Sem reprodução, o brilho pode ficar desligado, brilhar suavemente ou respirar devagar. A cor vem da imagem ou do destaque do DMS.

## Disco do player

Um widget da área de trabalho com a capa redonda da faixa atual. Ele gira durante a reprodução, mostra o progresso da faixa como um anel e mostra anterior, reproduzir e próxima ao passar o ponteiro. Em volta da capa há um visualizador: uma onda como no painel do DMS, barras em círculo ou um anel luminoso.

Se o Pear Desktop (YouTube Music) estiver rodando com o servidor de API ativado, o disco carrega a capa em 1200 px. O MPRIS só entrega 120 px para players baseados em Chromium.

## Requisitos

- DankMaterialShell 1.6.1 ou mais recente
- cava
- Para o brilho: python3 com numpy e Pillow

Eu uso no niri. O visualizador e o brilho usam layer surfaces próprias na camada background. No niri, as surfaces dessa camada se movem junto com os espaços de trabalho, a não ser que fiquem no backdrop. Adicione estas regras à configuração do niri para que os dois fiquem no lugar:

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

O disco do player é um widget da área de trabalho comum do DMS e se comporta como os outros widgets no seu compositor.

## Instalação

```sh
git clone https://github.com/21Rebel/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
dms ipc call plugins enable audioFx
```

Adicione o disco do player em Configurações → Widgets da Área de Trabalho → Adicionar Widget de Área de Trabalho → AudioFX.

## IPC

```sh
dms ipc call audiofx glow on|off|toggle
dms ipc call audiofx mode sync|bands|flow|sparkle|spectrum
dms ipc call audiofx set <key> <value>
dms ipc call audiofx get <key>
```

`set` e `get` usam as chaves das configurações do plugin, por exemplo `glowStrength` ou `discForm`.

## Desempenho

O brilho cobre a tela inteira, então o compositor o redesenha a cada quadro enquanto a música toca. A taxa de quadros do brilho vem em 30 por padrão e pode ser reduzida. Fora dos pontos luminosos, o shader retorna na hora.

## Traduções

A página de configurações está disponível em alemão, espanhol, francês, italiano, português, russo, japonês e chinês simplificado e segue o idioma definido no DMS. Se alguma tradução soar errada, um pull request é bem-vindo.

## Observação

Escrevi este plugin com ajuda do Claude (Anthropic) e testei cada mudança no meu próprio desktop com niri. `AudioFxHalo.qml` é baseado em `MediaBlobHalo.qml` do DankMaterialShell (MIT, Copyright (c) 2025 Avenge Media LLC).

## Licença

MIT
