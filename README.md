# macOS 15 Sequoia - Exhibition Machine Setup

展示・キオスク用Macの初期設定スクリプト（macOS 15 Sequoia / Apple Silicon専用）

## 概要

インスタレーション、デジタルサイネージ、展示用Macを24時間無人運用するための設定スクリプトです。

**対象環境:**
- macOS 15 (Sequoia) 以降
- Apple Silicon (M1/M2/M3/M4) のみ

## 機能一覧

### 🖥️ ディスプレイ・スクリーンセーバー
- デスクトップを黒に設定
- スクリーンセーバー無効化
- スクリーンセーバーパスワード要求無効化

### 🔲 Dock
- Dockを左側に配置
- 自動非表示有効化
- 最近使用したアプリの非表示

### 🪟 Mission Control
- ディスプレイごとの個別Spaces無効化
- Spacesの自動並び替え無効化

### 🔔 通知
- 通知プレビュー無効化
- Tips/Apple Intelligence通知の抑制
- ※Do Not Disturbは手動設定が必要

### ⚡ 電源管理 (Apple Silicon最適化)
- システムスリープ無効化
- ディスプレイスリープ無効化
- 電源復帰時の自動起動
- Power Nap無効化
- スタンバイ/Autopoweroff無効化
- Wake on LAN有効化

### 🔐 セキュリティ
- Gatekeeper設定（手動確認が必要）
- ダウンロード検疫警告無効化

### 🔄 自動更新
- ソフトウェアアップデート自動チェック無効化
- App Store自動更新無効化
- 更新通知の抑制

### 🔧 その他
- 自動ログイン設定
- クラッシュレポーター無効化
- ウィンドウ復元無効化
- .DS_Store作成抑制（ネットワーク/USB）
- AirDrop/Handoff無効化

## 使用方法

### 1. ダウンロード

```bash
curl -O https://raw.githubusercontent.com/ie3jp/macOS15-exhibition-setup/main/macOS15-exhibition-setup.command
```

### 2. 実行権限を付与

```bash
chmod +x macOS15-exhibition-setup.command
```

### 3. 実行

```bash
./macOS15-exhibition-setup.command
```

管理者パスワードの入力が求められます。

## 手動設定が必要な項目

macOS 15のセキュリティ強化により、以下の項目は手動での設定が必要です：

### Gatekeeper（未署名アプリの許可）

1. **システム設定 > プライバシーとセキュリティ** を開く
2. ウィンドウを開いたまま、ターミナルで以下を実行:
   ```bash
   sudo spctl --master-disable
   ```
3. システム設定に戻り、「すべてのアプリケーションを許可」を選択

### 集中モード（Do Not Disturb）

1. **システム設定 > 集中モード > おやすみモード** を開く
2. スケジュールを設定: 00:00 〜 23:59

### 自動ログイン

1. FileVaultが無効になっていることを確認
2. **システム設定 > ユーザとグループ > 自動ログイン** を設定

### 起動時のアプリ自動起動

1. **システム設定 > 一般 > ログイン項目** を開く
2. 展示用アプリケーションを追加

## macOS 14以前との主な違い

| 項目 | macOS 14以前 | macOS 15 |
|------|-------------|----------|
| Gatekeeper無効化 | `spctl --master-disable` で完了 | 手動確認が必要 |
| 通知センター | launchctlで無効化可能 | SIP保護により不可 |
| Dashboard | 存在（Catalinaで廃止済み） | 廃止 |
| pmset | Intel向けオプション多数 | Apple Silicon専用オプション |

## Apple Silicon固有の設定

- `lowpowermode 0` - 低電力モード無効化
- `proximitywake 0` - iPhone/Apple Watch接近時の起動無効化
- `standby 0` - ディープスリープ無効化
- `autopoweroff 0` - 自動電源オフ無効化

## トラブルシューティング

### 設定が反映されない

```bash
# 関連サービスを再起動
killall Dock
killall Finder
killall SystemUIServer
```

### 電源設定の確認

```bash
pmset -g
```

### 現在の設定値を確認

```bash
defaults read com.apple.screensaver
defaults read com.apple.dock
```

## 設定のリセット

元に戻す場合は、各項目をシステム設定から手動で変更するか、以下のコマンドで個別にリセット:

```bash
# スクリーンセーバーをリセット
defaults delete com.apple.screensaver

# Dockをリセット
defaults delete com.apple.dock && killall Dock

# 電源設定をリセット
sudo pmset restoredefaults
```

## ライセンス

MIT License

## 作者

- Original (2015): [rettuce](https://github.com/rettuce) - [Original Gist](https://gist.github.com/rettuce/71c801881e1433c3a9de)
- Updated for macOS 15 (2025): rettuce

## 参考リンク

- [Apple Developer - pmset documentation](https://developer.apple.com/documentation/)
- [macOS Sequoia Release Notes](https://developer.apple.com/documentation/macos-release-notes/)
- [Der Flounder - spctl changes in Sequoia](https://derflounder.wordpress.com/2024/09/23/spctl-command-line-tool-no-longer-able-to-manage-gatekeeper-on-macos-sequoia/)
