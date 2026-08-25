# Phase 12〜14 リリースチェックリスト

## Phase 12: TestFlight候補

- [x] Flutter unit/widget tests: 18件 PASS
- [x] `flutter analyze`: 問題0件（ASCII一時パスで実行）
- [x] iPhone/iPad相当サイズwidget test: PASS
- [ ] Xcode Archive
- [ ] iOS実機保存テスト
- [ ] TestFlightインストール・再起動テスト
- [ ] StoreKit購入／復元テスト

候補ビルドは、Xcode環境とBundle ID確定後に作成する。未確認の状態で提出候補をPASS扱いしない。

## Phase 13: App Store提出情報

- Bundle ID: 未確定（App Store Connect登録禁止）
- Version / Build: `1.0.0+1`（候補）
- 対象: iPhone / iPad、iOS / iPadOS
- プライバシー申告: 実装とAppleの質問票を照合して人間が確定
- IAP商品: Product ID、価格、表示名、説明をApp Store Connectと1文字単位で照合
- スクリーンショット: 実機キャプチャを使用。未作成
- 審査用アカウント: 不要（オフライン設計）

## Phase 14: App Review

提出前に、購入場所、復元場所、各商品の内容、無料でも令和到達可能であることを審査メモへ記載する。
Xcode、App Store Connect、Sandbox、TestFlightの未確認項目が残る場合は提出しない。
