# AudioFX

[English](README.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [日本語](README.ja.md) · **简体中文**

一个 [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) 插件，包含三种音频视觉效果：沿屏幕边缘显示的可视化、让壁纸中明亮区域随音乐脉动的辉光，以及放在桌面上的圆形播放器圆盘。

![AudioFX](assets/screenshot.png)

带图片的分步说明：[安装与设置指南](docs/GUIDE.zh_CN.md)。

## 可视化

可视化沿屏幕的一条边显示，并避开 DMS 框架和状态栏。共有八种样式：填充波形、线条波形、镜像波形、柱状、镜像柱状、倒挂柱状、方块和圆点。颜色、不透明度、深度、频段、间距和帧率都可以调整。

只有 MPRIS 播放器正在播放时，cava 才会运行。播放停止后，进程会被停止，而不只是隐藏。控制中心里的一个磁贴可以开关可视化。

## 辉光

插件会在当前壁纸中寻找发光的区域：最常见色相中饱和且明亮、在周围环境中显得突出的像素。灯、余烬、霓虹灯或熔岩效果都很好。像天空这样大面积均匀明亮的区域会被排除。每张壁纸只分析一次，结果会被缓存。

之后这些区域会随音乐亮起。共有五种模式：

- 同步：所有区域都跟随低音和音量。
- 按音高：大区域跟随低音，中等区域跟随中音，小区域跟随高音。
- 流动：每个低音节拍都会从图像边缘出发，沿着各区域送出一道光波。
- 闪烁：每个区域按自己的节奏闪烁。
- 横向频谱：低音在左，高音在右。

没有播放时，辉光可以关闭、微微发光或缓慢呼吸。颜色取自图像，或使用 DMS 的强调色。

## 播放器圆盘

一个桌面部件，显示当前曲目的圆形封面。播放时它会旋转，用圆环显示曲目进度，鼠标悬停时显示上一首、播放和下一首。封面周围有一个可视化效果：与 DMS 仪表盘相同的波形、环形柱状或辉光环。

如果 Pear Desktop (YouTube Music) 正在运行并启用了 API 服务器，圆盘会加载 1200 px 的封面。对于基于 Chromium 的播放器，MPRIS 只提供 120 px。

## 要求

- DankMaterialShell 1.6.1 或更高版本
- cava
- 辉光需要：带 numpy 和 Pillow 的 python3

我在 niri 上使用。可视化和辉光在 background 层上使用各自的 layer surface。在 niri 中，background 层的 surface 会随工作区一起移动，除非把它们放进 backdrop。把下面的规则加到 niri 配置中，两者就会留在原位：

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

播放器圆盘是普通的 DMS 桌面部件，在你的合成器上的表现与其他部件相同。

## 安装

```sh
git clone https://github.com/21Rebel/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
dms ipc call plugins enable audioFx
```

在 设置 → 桌面部件 → 添加桌面部件 → AudioFX 中添加播放器圆盘。

## IPC

```sh
dms ipc call audiofx glow on|off|toggle
dms ipc call audiofx mode sync|bands|flow|sparkle|spectrum
dms ipc call audiofx set <key> <value>
dms ipc call audiofx get <key>
```

`set` 和 `get` 使用插件设置中的键，例如 `glowStrength` 或 `discForm`。

## 性能

辉光覆盖整个屏幕，所以音乐播放时合成器每一帧都要重绘它。辉光帧率默认是 30，可以调低。在发光区域之外，着色器会立即返回。

## 翻译

设置页面提供德语、西班牙语、法语、意大利语、葡萄牙语、俄语、日语和简体中文版本，并跟随 DMS 中设置的语言。如果哪里翻译得不对，欢迎提交 pull request。

## 说明

我在 Claude (Anthropic) 的帮助下编写了这个插件，并在自己的 niri 桌面上测试了每一处改动。`AudioFxHalo.qml` 基于 DankMaterialShell 中的 `MediaBlobHalo.qml`（MIT，Copyright (c) 2025 Avenge Media LLC）。

## 许可证

MIT
