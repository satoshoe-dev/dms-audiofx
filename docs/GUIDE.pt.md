# AudioFX: passo a passo

[English](GUIDE.md) · [Deutsch](GUIDE.de.md) · [Español](GUIDE.es.md) · [Français](GUIDE.fr.md) · [Italiano](GUIDE.it.md) · **Português** · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · [简体中文](GUIDE.zh_CN.md)

## 1. Instale as dependências

O AudioFX lê o áudio pelo cava. O brilho também precisa de python3 com numpy e Pillow.

```sh
# Arch
sudo pacman -S cava python-numpy python-pillow
# Fedora
sudo dnf install cava python3-numpy python3-pillow
```

## 2. Instale e ative o plugin

Pelo registro de plugins:

```sh
dms plugins install audioFx
```

Ou clone o repositório na pasta de plugins do DMS:

```sh
git clone https://github.com/satoshoe-dev/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
```

Abra Configurações → Plugins e ative o AudioFX.

![Lista de plugins com AudioFX](images/01-plugin-list.png)

## 3. Só no niri: mantenha no lugar

No niri, superfícies de fundo se movem junto com os espaços de trabalho, a menos que fiquem no backdrop. Adicione estas regras a `~/.config/niri/config.kdl`:

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

Outros compositores não precisam disso.

## 4. O visualizador

Toque alguma música. O visualizador aparece ao longo da borda inferior.

![Visualizador na borda inferior](images/02-visualizer.png)

Expanda o AudioFX na lista de plugins para alterá-lo. “Estilo” alterna entre ondas, barras, blocos e pontos. “Borda”, “Profundidade” e “Recuo lateral” definem a posição. “Cor” e “Opacidade” definem a aparência.

![Configurações do visualizador](images/03-visualizer-settings.png)

Se as barras piscarem em trechos baixos, aumente “Calma”. Se quase não se moverem, aumente “Sensibilidade”.

## 5. Ligar e desligar pelo painel de controle

Abra o painel de controle, entre no modo de edição, clique em “Adicionar Widget” e escolha AudioFX. Um clique no bloco liga ou desliga o visualizador.

![Bloco do AudioFX no painel de controle](images/04-tile.png)

## 6. O brilho

Role até “Brilho no papel de parede” e ative “Ativar brilho”. O AudioFX procura pontos luminosos no seu papel de parede. Na primeira vez isso leva cerca de um segundo e depois fica em cache.

![Configurações do brilho](images/05-glow-settings.png)

O brilho funciona melhor com papéis de parede que têm fontes de luz pequenas e fortes: lâmpadas, neon, brasas, luzes da cidade. Em um papel de parede sem esses pontos, nada acende.

Escolha como os pontos reagem em “Como os pontos pulsam”:

- Tudo junto
- Por altura
- Fluindo
- Cintilar
- Espectro ao longo da largura

![Pontos brilhando no papel de parede](images/06-glow.png)

Se acender demais ou de menos, mova “Limite de detecção”. “Intensidade do brilho” e “Halo” mudam a luminosidade.

## 7. O disco do player

Abra Configurações → Widgets da Área de Trabalho → Adicionar Widget de Área de Trabalho e escolha AudioFX. Arraste o disco para onde quiser e ajuste o tamanho.

![Disco do player na área de trabalho](images/07-disc.png)

Passe o ponteiro sobre o disco para ver anterior, reproduzir e próxima. Em “Disco do player”, nas configurações do AudioFX, escolha o visualizador em volta da capa: uma onda, barras em círculo ou um anel luminoso. “Tingir com a cor de destaque” tinge a capa com a cor de destaque do DMS.

## 8. Comandos (opcional)

```sh
dms ipc call audiofx glow toggle
dms ipc call audiofx mode flow
dms ipc call audiofx set glowStrength 150
```
