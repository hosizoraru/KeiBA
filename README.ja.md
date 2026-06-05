# KeiBA

[![CI][ci-badge]][ci-workflow] ![Platforms][platforms-badge] ![Swift][swift-badge]

[English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

KeiBA は、Blue Archive プレイヤー向けのネイティブ Apple プラットフォーム用
コンパニオンアプリです。日本語圏では「ブルーアーカイブ」「ブルアカ」、グローバルな会話では
BA と呼ばれることもあります。KeiBA は、先生が毎日確認したい AP、カフェ、スケジュール、
募集、学生情報、メモリアルロビー BGM、通知、ウィジェット、Live Activities、Apple Watch
グランスをひとつの Apple らしい体験にまとめます。

このプロジェクトは現在も活発に開発中です。メインアプリは iOS、iPadOS、macOS 26 を
対象にしており、watchOS コンパニオン、WidgetKit サーフェス、Live Activities も同じ
リポジトリで管理し、ローカル検証と CI の通常経路に含めています。日本版、グローバル版、
中国語圏の BA プレイヤーが使う日常ワークフローを意識しながら、Apple プラットフォーム
ごとの自然な操作感を優先します。

## ローカライズと用語

Blue Archive は地域ごとに呼び方や訳語のニュアンスが少しずつ違います。KeiBA の文書と UI は、
単なる直訳ではなく、プレイヤーが普段使う言葉に寄せます。

- 日本語では「先生」「生徒」「シャーレ」「キヴォトス」「カフェ」「募集」「戦術対抗戦」
  「メモリアルロビー」などの表現を自然に使います。
- 英語圏の Sensei / Kivotos、簡体字中国語圏の「老师」「夏莱」「咖啡厅」なども、対応する
  画面や文書ではその地域の読みやすさを優先します。
- 公式サービスのように見せるのではなく、公開ガイドデータを使うファン向けコンパニオンアプリ
  であることを明確にします。

## 主な機能

- AP、カフェ AP、デイリーリセット、カフェ訪問、なでなで、招待券、戦術対抗戦更新、
  先生プロフィール、サーバー別オフィス設定を追跡。
- 公開 BA ガイドデータから、開催中および近日開催のイベント、スケジュール、募集タイムラインを表示。
- 生徒、NPC、衛星キャラクターのガイドを検索し、プロフィール、スキル、固有武器、ギャラリー、
  ボイス情報を確認。
- お気に入り生徒のメモリアルロビー BGM を再生し、ローカル音声キャッシュとシステム
  メディアコントロールに対応。
- ローカル通知を計画し、Live Activities / Dynamic Island で重要な進行状況を表示。
- iOS ウィジェットと watchOS Smart Stack で AP、カフェ AP、イベント、募集状況を素早く確認。
- WatchConnectivity により、iPhone のコンパクトなダッシュボードスナップショットを
  Apple Watch に同期。
- 英語、日本語、簡体字中国語の UI / ローカライズを BA 用語に近い形で保守。

## プラットフォーム対応

| サーフェス | 状態 | 補足 |
| --- | --- | --- |
| iPhone | 開発中 / 利用可能 | 概要、図鑑、音楽、通知、ウィジェット、Live Activities の主要な日常入口。 |
| iPad | 開発中 / 利用可能 | メインアプリターゲットを共有し、大きなウィンドウ、ポインタ、キーボード、分割表示に適応。 |
| Mac | 開発中 / 利用可能 | メインアプリターゲットからビルドし、macOS のツールバー、サイドバー、キーボード、ポインタ、ウィンドウ挙動を考慮。 |
| Apple Watch | 開発中 | 先生ダッシュボード、Smart Stack ウィジェット、通知状態、AP とスケジュール概要を提供。 |
| ウィジェット | 開発中 / 利用可能 | iOS ダッシュボードウィジェットと watchOS Smart Stack が共有ダッシュボードスナップショットを読み取る。 |
| Live Activities | 開発中 / 利用可能 | 対応デバイスで通知の進行状況をロック画面と Dynamic Island に表示。 |

## リポジトリ構成

| パス | 用途 |
| --- | --- |
| `KeiBA/` | メインアプリ、BA 機能モジュール、共有 UI、アセット、ローカライズ、サポートコード。 |
| `KeiBAShared/` | アプリと Live Activities 拡張で共有する型。 |
| `KeiBALiveActivities/` | Live Activities、ロック画面、Dynamic Island 表示用拡張。 |
| `KeiBAiOSWidgets/` | iOS WidgetKit ダッシュボードウィジェット。 |
| `KeiBAWatch/` | watchOS コンパニオンアプリ。 |
| `KeiBAWatchShared/` | iPhone、Watch、ウィジェットで共有する Codable ダッシュボードスナップショットモデル。 |
| `KeiBAWatchWidgets/` | watchOS WidgetKit / Smart Stack 拡張。 |
| `KeiBATests/` | パーサー、設定、通知、メディア、ウィジェット、Watch スナップショット、レイアウトの単体テスト。 |
| `Docs/` | 機能カバレッジ、プラットフォームロードマップ、UIKit/AppKit 連携、Widget 設定、性能基準。 |
| `scripts/` | ローカルおよび CI 用メンテナンススクリプト。 |

## 必要環境

| ツールまたはプラットフォーム | 基準 |
| --- | --- |
| Xcode | ローカル開発では Xcode 26.5 以降を推奨。 |
| SDK | iOS 26.5、iOS Simulator 26.5、macOS 26.5、watchOS 26.5。 |
| Deployment target | iOS 26.0+、iPadOS 26.0+、macOS 26.0+、watchOS 26.0+。 |
| Project format | Xcode 26.3 project format、`objectVersion` 100。 |
| 技術スタック | Swift、SwiftUI、Swift Concurrency、Observation、WidgetKit、ActivityKit、App Intents、WatchConnectivity、Swift Package Manager。 |

Swift Package の依存関係は Xcode project から解決し、コミット済みの
`Package.resolved` で固定しています。

- [AudioStreaming](https://github.com/dimitris-c/AudioStreaming.git)
- [ogg-binary-xcframework](https://github.com/sbooth/ogg-binary-xcframework)
- [vorbis-binary-xcframework][vorbis-binary-xcframework]

## ローカルビルド

Xcode 26.5 以降で `KeiBA.xcodeproj` を開き、`KeiBA` scheme を選択して iOS 26
Simulator、iPadOS 26 Simulator、macOS 26、または署名済みの実機 iPhone/iPad で実行します。
watchOS コンパニオンをビルドする場合は `KeiBAWatch` scheme を選択してください。

コマンドライン例：

```sh
xcodebuild build \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'generic/platform=iOS Simulator'

xcodebuild build \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'generic/platform=macOS'

xcodebuild build \
  -project KeiBA.xcodeproj \
  -scheme KeiBAWatch \
  -destination 'generic/platform=watchOS Simulator'
```

実機 iPhone / iPad に Release ビルドをインストールする手順：

1. `KeiBA` scheme と対象デバイスを選択。
2. `Product > Scheme > Edit Scheme...` を開く。
3. `Run > Info` の `Build Configuration` を `Release` に変更。
4. アプリ、Widget / Live Activities 拡張、Watch アプリ、Watch Widget 拡張に Apple Team
   が設定されていることを確認。
5. `Product > Run` で Release ビルドをビルド、署名、インストール、起動。

配布用ビルドでは `Any iOS Device (arm64)` を選択し、`Product > Archive` を実行したあと、
Organizer から適切な Apple 署名方式で書き出します。

## テストと検証

軽量なローカルチェック：

```sh
jq empty KeiBA/Localizable.xcstrings
jq empty KeiBALiveActivities/Localizable.xcstrings
jq empty KeiBAWatch/Localizable.xcstrings
jq empty KeiBAWatchWidgets/Localizable.xcstrings
git diff --check
```

単体テスト：

```sh
xcodebuild test \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'platform=macOS'
```

図鑑フィルターの集中テスト：

```sh
xcodebuild test \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'platform=macOS' \
  -only-testing:KeiBATests/BaCatalogFilterTests
```

表示を変更する場合は、対象の Simulator または実機で確認し、PR にスクリーンショットや
録画を添付してください。この checkout のローカル agent ワークフローでは、Build iOS Apps
のブラウザ内 Simulator ミラーを使います。

- project: `KeiBA.xcodeproj`
- scheme: `KeiBA`
- bundle id: `os.kei.KeiBA`
- simulator: `iPhone 17 Pro`

## CI と成果物

GitHub Actions は `macos-26` 上で、ローカライズ検証、iOS Simulator ビルドとテスト、
watchOS Simulator ビルド、macOS ビルドとテスト、Watch / Widget スナップショットテスト、
ユーザーデータ同期テスト、未署名パッケージ作成を実行します。

`main` への push と手動 workflow では、サイドロード検証用の成果物をアップロードします。

- `KeiBA-iOS-<version>-unsigned.ipa`
- `KeiBA-macOS-<version>-unsigned.dmg`

これらは未署名で、ローカルのスモークテストや後続の再署名を想定しています。notarize 済み、
TestFlight 用、App Store 用の成果物ではありません。

README、Docs、GitHub community ファイルだけの変更は path filter によりアプリビルド CI を
スキップし、macOS CI 時間を節約します。

## バージョニング

KeiBA は Apple bundle のバージョンと CI 成果物名を分けて管理します。

- `MARKETING_VERSION` / `CFBundleShortVersionString` は `1.0.0` のような 3 要素の
  リリースバージョンを使用。
- `CURRENT_PROJECT_VERSION` / `CFBundleVersion` は CI でリポジトリの commit 数を使用。
- tag なしの CI 成果物名には `1.0.1-162.g6d0c346` のように git メタデータを追加し、
  アプリ bundle 内は Apple 互換の値に保ちます。

CI のバージョン解決スクリプトは、最新のマージ済み semantic tag（`v1.2.3` または
`1.2.3`）を読みます。tag ビルドはそのリリースバージョンを使い、tag 後のビルドは次の
patch バージョンに commit 距離と短い SHA を追加します。

## データとプライバシー

KeiBA は公開されている Blue Archive / BA ガイドデータを読み取ります。Blue Archive の名称、
キャラクター、アートワーク、音楽、ボイス、および関連ゲーム素材は、それぞれの権利者に帰属します。
日本版の公式サイトは [bluearchive.jp](https://bluearchive.jp) です。KeiBA は公式アプリではなく、
アカウント、課金、ゲームサーバーのサポートは提供しません。

アプリは現在、オフィス設定、お気に入り、キャッシュ済みメディアメタデータ、Watch ダッシュボード
スナップショット、同期された当番生徒アイコンのサムネイル、Widget ダッシュボードスナップショット、
通知設定をローカルに保存します。将来の iCloud 同期では、同期する payload を小さく明確にし、
ユーザーがリセットできる形に保つべきです。

脆弱性報告は [SECURITY.md](SECURITY.md)、通常の問題報告は [SUPPORT.md](SUPPORT.md) を参照してください。

## コントリビューション

変更は小さく、プラットフォーム差分が分かる形にしてください。まず
[CONTRIBUTING.md](CONTRIBUTING.md) を読み、PR には実行した検証コマンドを書いてください。
表示が変わる場合は、対象プラットフォームの Simulator または実機キャプチャを添付してください。

関連ドキュメント：

- [BA feature coverage](Docs/BAFeatureCoverage.md)
- [Platform features roadmap](Docs/Platform-Features-Roadmap.md)
- [SwiftUI / UIKit / AppKit interop plan](Docs/SwiftUI-UIKit-AppKit-Interop-Plan.md)
- [Widget extension setup](Docs/Widget-Extension-Setup.md)
- [Performance baselines](Docs/Performance-Baselines.md)

## License

License はまだ最終決定していません。license が追加されるまで、このリポジトリのすべての権利は
リポジトリ所有者に帰属します。

[ci-badge]: https://github.com/hosizoraru/KeiBA/actions/workflows/ci.yml/badge.svg
[ci-workflow]: https://github.com/hosizoraru/KeiBA/actions/workflows/ci.yml
[platforms-badge]: https://img.shields.io/badge/platforms-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20watchOS-0a7ea4
[swift-badge]: https://img.shields.io/badge/Swift-6-orange
[vorbis-binary-xcframework]: https://github.com/sbooth/vorbis-binary-xcframework
