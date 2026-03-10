# CastleDefense Project

## Overview
Vampire Survivors x Tower Defense ハイブリッドモバイルゲーム。
Flutter + Flame エンジンで開発中。

## Core Documents (必ず読むこと)
- `docs/新ゲーム仕様書.md` — ゲーム全体仕様 (数値・レイアウト・全システム定義)
- `docs/タスク分担表.md` — 66タスクの分担・依存関係・フェーズ順序

## Project Structure
```
lib/
  castle_defense_game.dart   ← メインゲームファイル (非常に大きい。Read時はoffset/limitを使うこと)
  models/
    character_model.dart     ← キャラクターモデル
    character_enums.dart     ← 役割Enum
  data/
    character_definitions.dart ← キャラクター定数
  systems/
    gacha_system.dart        ← ガチャシステム
assets/images/
  goblin.png               ← Stage1モンスタースプライト
docs/
  新ゲーム仕様書.md
  タスク分担表.md
```

## GitHub Issue Tracking
- 全タスクはGitHub Issues #1〜#68 で管理
- ラベルでフィルタ: `team:planner` / `team:designer` / `team:backend`
- フェーズ: `phase:1-core` 〜 `phase:6-test`
- Project: https://github.com/users/JunhwiAhn/projects/1
- タスク完了時: `gh issue close #番号` を実行

## Language Rules
- コード内コメント: 韓国語
- コミットメッセージ: 日本語
- ドキュメント: 日本語 (韓国語ゲーム用語はそのまま)

## Key Specifications (Quick Reference)
```
城: 80×80px, 画面中央, HP=200, 接触半径=50px
タワー: 城中心±70px 対角4箇所
メインキャラ: HP=50, 速度=150px/s
敵速度: 通常=40, ミニボス=30, ボス=25 (px/s)
XPジェム: 回収半径=20px, 消滅=30秒
レベルアップ必要XP: 10 + (Lv × 5)
スキルゲージ: 通常+3%, ミニボス+15%, ボス+50%
基準解像度: 390×844 (FitWidth)
既存射程: rangedRange=375, physicalDealerRange=525, priestRange=600
```

## Coding Guidelines
- 既存コードのパターンと命名規則を踏襲する
- 流用コードは変更しない: `_handleMeleeUnit`, `_handleArcherUnit`, `_handleGunslingerUnit`, `_handleMagicUnit`, `_handleRangedUnit`, `_Projectile`, `_updateProjectiles()`, `_fireProjectile()`
- ガチャ・インベントリUI は変更しない
- `flutter analyze` でエラーがないことを確認してからコミット

## Coordination Rules
- 同じファイルを複数のチームメイトが同時に編集しない
- `castle_defense_game.dart` への変更はエンジニアが担当。デザイナーはレンダリングメソッド (`_render*`) のみ追加可
- 仕様変更があれば `docs/新ゲーム仕様書.md` を更新し、影響するIssueにコメントする
- Phase 1のコア基盤完了後にPhase 2以降に着手する (座標系が確定するため)
