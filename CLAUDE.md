# CLAUDE.md

## 概要

OS のシステム HTTP プロキシ設定を取得する federated Flutter plugin の Melos (v6) モノレポ。

- `packages/detect_proxy_setting` — アプリが依存する公開パッケージ。android / ios / macos / windows の `default_package` を指定
- `packages/proxy_setting_platform_interface` — `ProxySettingPlatform` と `ProxySetting` モデル（`ProxySettingModeEnum { proxy, direct }`）
- `packages/proxy_setting_{android,ios,macos,windows}` — 各プラットフォーム実装
- Linux / Web は未実装

## ツールチェーンとコマンド

- Flutter のバージョンは `.tool-versions`（mise）で管理: `flutter 3.47.6`
- Melos は 6.3.3（`dart pub global activate melos 6.3.3`）

```sh
melos bs              # bootstrap。各パッケージに pubspec_overrides.yaml（gitignore 済み）を生成してローカル参照にする
melos run lint        # dart analyze + dart format --set-exit-if-changed packages tests
melos run test        # test/ を持つパッケージで flutter test（example は除外）
cd packages/<pkg> && flutter test   # 単一パッケージのテスト
```

- フォーマットは CI でチェックされるため、Dart を変更したら `dart format packages tests` を実行する
- Android の native unit test（JUnit）: `packages/proxy_setting_android/android/src/test/kotlin/...`。AGP 9 はルートプロジェクトへの適用を禁止しているためプラグイン単体ではビルドできない。`tests` で一度 `flutter build apk --debug` してから `cd tests/android && ./gradlew :proxy_setting_android:testDebugUnitTest` で実行する（Java 17 が必要。CI では実行されない）

## アーキテクチャ

- 公開 API は `packages/detect_proxy_setting/lib/detect_proxy_setting.dart` の `Future<ProxySetting?> proxySetting({String? url})`。`ProxySettingPlatform.instance` に委譲する
- 各プラットフォームは独自の MethodChannel `playon.jp/proxy_setting_<platform>` を持ち、method は `proxySetting`、引数は `{'url': String?}`
- native 側は map を返す。キーは `mode`（`"proxy"` / `"direct"`）、`isAutoDetect`、`proxy`、`proxyBypass`、`configUrl`
- `isAutoDetect` の Dart 側の変換はプラットフォームごとに異なる（android / windows は `_asBool`、ios / macos は `== 1`）。戻り値の型を変えるときは Dart 側も合わせる
- platform_interface の `playon.jp/proxy_setting` チャネルはフォールバック用で、native 側には登録されていない

| Platform | native 実装 |
|---|---|
| Android | `packages/proxy_setting_android/android/src/main/kotlin/jp/playon/proxy_setting_android/`（`ProxySettingPlugin.kt`, `ProxySettingResolver.kt`） |
| iOS | `packages/proxy_setting_ios/ios/proxy_setting_ios/Sources/proxy_setting_ios/ProxySettingPlugin.swift`（SPM: `Package.swift`、CocoaPods: `proxy_setting_ios.podspec`） |
| macOS | `packages/proxy_setting_macos/macos/proxy_setting_macos/Sources/proxy_setting_macos/ProxySettingPlugin.swift`（SPM / CocoaPods 両対応） |
| Windows | `packages/proxy_setting_windows/windows/proxy_setting_plugin.cpp` ほか（WinHTTP で PAC / 自動検出） |

各プラットフォームの Dart 側テストは `setMockMethodCallHandler` でチャネルをモックしている。

## 規約と注意点

- **iOS と macOS の Swift 実装はほぼ同一のコード**（CFNetwork による PAC 実行など）。片方を変更したら、もう片方も同じように揃える
- **バージョン更新は手動**（`melos version` は使っていない）。変更したパッケージごとに以下を行う:
  1. そのパッケージの `pubspec.yaml` の version を上げ、`CHANGELOG.md` の先頭に `## x.y.z` と `*` 箇条書きを追加
  2. iOS / macOS は `*.podspec` の `s.version` も同じ値にする
  3. `detect_proxy_setting` の version と、プラットフォームパッケージへの caret 制約を更新し、CHANGELOG に追記
  4. ルートの `README.md` と `packages/detect_proxy_setting/README.md` のインストール例（`detect_proxy_setting: ^x.y.z`）を更新
- `tests/` は手動確認用のサンプルアプリ（path 依存 + `dependency_overrides`）。`packages/detect_proxy_setting/example` は Melos の対象外
- `packages/detect_proxy_setting/example/.flutter-plugins-dependencies` は生成物だが git で追跡されている。ローカルの絶対パスが入るので、意図しない差分はコミットしない
- `pubspec.lock` と `pubspec_overrides.yaml` は gitignore 対象

## CI

`.github/workflows/test.yaml`（ubuntu-latest）で `melos run lint` と `melos run test-ci` を実行する。Dart のテストのみで、native ビルドや native テストは実行しない。

- セットアップは `.github/actions/setup-flutter/action.yaml`（Java 17 + mise + melos）
- mise の Flutter キャッシュは無効化している（キャッシュした Flutter だと Dart SDK が壊れるため）
- テスト結果は `scripts/combine_test.sh` で `report/` にまとめる
