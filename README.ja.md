# AudioFX

[English](README.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Português](README.pt.md) · [Русский](README.ru.md) · **日本語** · [简体中文](README.zh_CN.md)

[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) 用のプラグインで、3 つのオーディオビジュアルがあります。画面端に沿って表示するビジュアライザー、壁紙の明るい部分を音楽に合わせて脈打たせるグロー、デスクトップ用の丸いプレーヤーディスクです。

![AudioFX](assets/screenshot.png)

画像付きの手順: [インストールと設定のガイド](docs/GUIDE.ja.md)。

## ビジュアライザー

ビジュアライザーは画面の端のひとつに沿って表示され、DMS のフレームとバーの部分は避けます。スタイルは 8 種類で、塗りつぶしウェーブ、線のウェーブ、ミラーウェーブ、バー、ミラーバー、吊り下げバー、ブロック、ドットです。色、不透明度、奥行き、バンド数、間隔、フレームレートを調整できます。

初期設定では、cava は MPRIS プレーヤーが再生している間だけ動き、再生が止まると終了します。「再生中のみ」をオフにすると cava は常に動作し、MPRIS に対応していないプログラムの音も表示します。コントロールセンターのタイルでビジュアライザーのオンとオフを切り替えられます。

## グロー

プラグインは現在の壁紙から光っている部分を探します。対象は、最も多い色相の鮮やかで明るいピクセルのうち、周囲から浮き出ているものです。ランプ、残り火、ネオン、溶岩などがよく合います。空のように均一に明るい大きな領域は除外されます。解析は壁紙ごとに 1 回だけ行われ、キャッシュされます。

その部分が音楽に合わせて光ります。モードは 5 つあります。

- 同時：すべての部分が低音と音量に合わせて光ります。
- 音域別：大きい部分は低音、中くらいの部分は中音、小さい部分は高音に反応します。
- 流れる：低音のビートごとに、画像の端から光の波が各部分を伝っていきます。
- きらめき：各部分がそれぞれのリズムでちらつきます。
- 横幅いっぱいのスペクトル：低い音が左、高い音が右です。

再生していないときは、グローをオフにするか、静かに光らせるか、ゆっくり呼吸させるかを選べます。色は画像から取るか、DMS のアクセントを使います。

## プレーヤーディスク

現在の曲の丸いカバーを表示するデスクトップウィジェットです。再生中は回転し、曲の進み具合をリングで示し、ポインターを合わせると前へ、再生、次へが表示されます。カバーの周りにはビジュアライザーがあり、DMS のダッシュボードと同じウェーブ、円形のバー、グローリングのいずれかになります。

Pear Desktop (YouTube Music) を API サーバーを有効にして動かしている場合、ディスクは 1200 px のカバーを読み込みます。Chromium ベースのプレーヤーでは、MPRIS から得られるのは 120 px だけです。

カバーはDMS のアクセントカラーで着色できます（「アクセントカラーで着色」）。シェルのほかの部分と同じように、テーマやプロファイルに合わせて変わります。

## 動作要件

- DankMaterialShell 1.6.1 以降
- cava
- グローを使う場合：numpy と Pillow を含む python3

私は niri で使っています。ビジュアライザーとグローは、background レイヤー上にそれぞれ専用の layer surface を使います。niri では、background の surface は backdrop に置かない限りワークスペースと一緒に動きます。両方をその場に留めるには、niri の設定に次のルールを追加してください。

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

プレーヤーディスクは通常の DMS デスクトップウィジェットで、お使いのコンポジター上でほかのウィジェットと同じように動作します。

## インストール

プラグインレジストリから:

```sh
dms plugins install audioFx
dms ipc call plugins enable audioFx
```

DMS の 設定 → プラグイン → ブラウズ からも入手できます。リポジトリから直接入れる場合:

```sh
git clone https://github.com/satoshoe-dev/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
dms ipc call plugins enable audioFx
```

プレーヤーディスクは、設定 → デスクトップウィジェット → デスクトップウィジェットを追加 → AudioFX から追加します。

## IPC

```sh
dms ipc call audiofx glow on|off|toggle
dms ipc call audiofx mode sync|bands|flow|sparkle|spectrum
dms ipc call audiofx set <key> <value>
dms ipc call audiofx get <key>
```

`set` と `get` にはプラグイン設定のキーを使います。たとえば `glowStrength` や `discForm` です。

## パフォーマンス

グローは画面全体を覆うため、音楽の再生中はコンポジターが毎フレーム描き直します。グローのフレームレートは初期値が 30 で、下げることもできます。光る部分の外側では、シェーダーはすぐに処理を返します。

## 翻訳

設定ページはドイツ語、スペイン語、フランス語、イタリア語、ポルトガル語、ロシア語、日本語、簡体字中国語に対応していて、DMS の言語設定に従います。おかしな翻訳があれば、プルリクエストを歓迎します。

## 補足

このプラグインは Claude (Anthropic) の助けを借りて書き、すべての変更を自分の niri デスクトップで試しました。`AudioFxHalo.qml` は DankMaterialShell の `MediaBlobHalo.qml` (MIT, Copyright (c) 2025 Avenge Media LLC) をもとにしています。

## ライセンス

MIT
