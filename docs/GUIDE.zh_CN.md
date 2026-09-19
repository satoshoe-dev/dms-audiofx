# AudioFX：分步指南

[English](GUIDE.md) · [Deutsch](GUIDE.de.md) · [Español](GUIDE.es.md) · [Français](GUIDE.fr.md) · [Italiano](GUIDE.it.md) · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · **简体中文**

## 1. 安装依赖

AudioFX 通过 cava 读取音频。辉光还需要装有 numpy 和 Pillow 的 python3。

```sh
# Arch
sudo pacman -S cava python-numpy python-pillow
# Fedora
sudo dnf install cava python3-numpy python3-pillow
```

## 2. 安装并启用插件

从插件注册表安装：

```sh
dms plugins install audioFx
```

或者将仓库克隆到 DMS 插件目录：

```sh
git clone https://github.com/satoshoe-dev/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
```

打开 设置 → 插件，启用 AudioFX。

![列出 AudioFX 的插件列表](images/01-plugin-list.png)

## 3. 仅限 niri：固定位置

在 niri 中，背景图层会随工作区一起移动，除非它们位于 backdrop 中。将以下规则添加到 `~/.config/niri/config.kdl`：

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

其他合成器不需要这样做。

## 4. 可视化效果

播放音乐，可视化效果会沿屏幕底部边缘出现。

![底部边缘的可视化效果](images/02-visualizer.png)

在插件列表中展开 AudioFX 即可修改。“样式”可在波形、柱状、方块和圆点之间切换。“边缘”、“深度”和“两端内缩”决定位置，“颜色”和“不透明度”决定外观。

![可视化设置](images/03-visualizer-settings.png)

如果柱在安静段落中闪烁，请调高“平稳度”。如果几乎不动，请调高“灵敏度”。

## 5. 在控制中心开关

打开控制中心，切换到编辑模式，点击“添加部件”并选择 AudioFX。单击磁贴即可开启或关闭可视化效果。

![控制中心中的 AudioFX 磁贴](images/04-tile.png)

## 6. 辉光

滚动到“壁纸辉光”，打开“启用辉光”。AudioFX 会在壁纸中查找发光的区域。第一次大约需要一秒，之后会被缓存。

![辉光设置](images/05-glow-settings.png)

辉光最适合带有小而明亮光源的壁纸：灯、霓虹、余烬、城市灯光。壁纸中没有这类区域时，什么都不会亮起。

在“脉动方式”中选择这些区域如何反应：

- 同步
- 按音高
- 流动
- 闪烁
- 横向频谱

![壁纸中发光的区域](images/06-glow.png)

如果亮起的区域太多或太少，请调整“检测阈值”。“辉光强度”和“光晕”用于改变亮度。

## 7. 播放器圆盘

打开 设置 → 桌面部件 → 添加桌面部件，选择 AudioFX。将圆盘拖到想要的位置并调整大小。

![桌面上的播放器圆盘](images/07-disc.png)

将指针悬停在圆盘上，会显示上一首、播放和下一首。在 AudioFX 设置的“播放器圆盘”中，选择封面周围的可视化效果：波形、环形柱状或辉光环。 “用强调色着色”会用 DMS 的强调色为封面着色。

## 8. 命令（可选）

```sh
dms ipc call audiofx glow toggle
dms ipc call audiofx mode flow
dms ipc call audiofx set glowStrength 150
```
