# AudioFX: ステップごとの手順

[English](GUIDE.md) · [Deutsch](GUIDE.de.md) · [Español](GUIDE.es.md) · [Français](GUIDE.fr.md) · [Italiano](GUIDE.it.md) · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · **日本語** · [简体中文](GUIDE.zh_CN.md)

## 1. 必要なものをインストールする

AudioFX は cava を通じて音声を読み取ります。グローには、さらに numpy と Pillow を入れた python3 が必要です。

```sh
# Arch
sudo pacman -S cava python-numpy python-pillow
# Fedora
sudo dnf install cava python3-numpy python3-pillow
```

## 2. プラグインをインストールして有効にする

```sh
git clone https://github.com/21Rebel/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
```

設定 → プラグイン を開き、AudioFX をオンにします。

![AudioFX が表示されたプラグイン一覧](images/01-plugin-list.png)

## 3. niri のみ: 位置を固定する

niri では、背景のサーフェスは backdrop に置かれていない限り、ワークスペースと一緒に動きます。次のルールを `~/.config/niri/config.kdl` に追加します。

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

ほかのコンポジターでは必要ありません。

## 4. ビジュアライザー

音楽を再生します。画面の下端に沿ってビジュアライザーが表示されます。

![下端のビジュアライザー](images/02-visualizer.png)

変更するには、プラグイン一覧で AudioFX を展開します。「スタイル」でウェーブ、バー、ブロック、ドットを切り替えます。「画面端」「奥行き」「両端の余白」で位置を決め、「色」と「不透明度」で見た目を決めます。

![ビジュアライザーの設定](images/03-visualizer-settings.png)

静かな部分でバーがちらつく場合は「落ち着き」を上げます。ほとんど動かない場合は「感度」を上げます。

## 5. コントロールセンターからオン・オフする

コントロールセンターを開いて編集モードに切り替え、「ウィジェットを追加」をクリックして AudioFX を選びます。タイルを 1 回クリックするたびに、ビジュアライザーのオンとオフが切り替わります。

![コントロールセンターの AudioFX タイル](images/04-tile.png)

## 6. グロー

「壁紙のグロー」までスクロールし、「グローを有効化」をオンにします。AudioFX が壁紙の中の光っている部分を探します。初回は 1 秒ほどかかり、その後はキャッシュされます。

![グローの設定](images/05-glow-settings.png)

グローが最もよく働くのは、ランプ、ネオン、燃えさし、街の明かりなど、小さく明るい光源がある壁紙です。そうした部分がない壁紙では何も光りません。

光る部分の反応のしかたは「光の脈動のしかた」で選びます。

- 同時
- 音域別
- 流れる
- きらめき
- 横幅いっぱいのスペクトル

![壁紙の中で光る部分](images/06-glow.png)

光る部分が多すぎる場合や少なすぎる場合は、「検出しきい値」を動かします。「グローの強さ」と「ハロー」で明るさが変わります。

## 7. プレーヤーディスク

設定 → デスクトップウィジェット → デスクトップウィジェットを追加 を開き、AudioFX を選びます。ディスクを好きな場所にドラッグし、サイズを変更します。

![デスクトップ上のプレーヤーディスク](images/07-disc.png)

ディスクにポインターを合わせると、前へ、再生、次へが表示されます。AudioFX の設定の「プレーヤーディスク」で、カバーの周りのビジュアライザーをウェーブ、円形のバー、グローリングから選びます。

## 8. コマンド（任意）

```sh
dms ipc call audiofx glow toggle
dms ipc call audiofx mode flow
dms ipc call audiofx set glowStrength 150
```
