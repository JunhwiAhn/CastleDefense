# CastleDefense Project

## Overview
Vampire Survivors x Tower Defense ハイブリッドモバイルゲーム。
Flutter + Flame エンジンで開発中。

## Core Documents (必ず読むこと)
- `docs/新ゲーム仕様書.md` — ゲーム全体仕様 (数値・レイアウト・全システム定義・属性・増強)
- `docs/タスク分担表.md` — 66タスクの分担・依存関係・フェーズ順序
- `docs/specs/element-system.md` — 属性システム仕様 (火・水・地・電気・闇)
- `docs/specs/augment-system.md` — 増強(オーグメント)システム仕様 (34種・3ティア)
- `docs/research/` — Planner調査成果物 (P-1-1〜P-1-5)
- `docs/specs/` — Planner仕様策定 (P-2-1〜P-2-6, P-3-1)
- `docs/reviews/` — Phase 6 レビューレポート (バランス・UX・バフ・ゲームプレイ・技術・デザイン)

## Project Structure
```
lib/
  castle_defense_game.dart   ← メインゲームファイル (非常に大きい。Read時はoffset/limitを使うこと)
  models/
    character_model.dart     ← キャラクターモデル (CharacterDefinition.element getter追加済み)
    character_enums.dart     ← 役割Enum + ElementType enum + ClassType.defaultElement
  data/
    character_definitions.dart ← キャラクター定数 (属性マッピング済み)
  systems/
    gacha_system.dart        ← ガチャシステム
assets/images/
  goblin.png               ← Stage1モンスタースプライト
  castle.png               ← 城スプライト
  boss_monster.png          ← ボスモンスター
  miniboss_monster.png      ← ミニボス
  xp_gem.png               ← XPジェム
  gold_coin.png             ← ゴールドコイン
  references/               ← 参照用アセットパック (デザイン時に活用すること)
    2D Characters-CasualMonsters/  ← モンスター・城・HPバー素材
    2D Characters-MinimalCharacters/ ← キャラクタースプライト
    2D Icons-CasualIconPack/       ← アイコン素材
    Pixel Monster Pack/            ← 32x32/64x64モンスターシート
    Violet Theme Ui/               ← UIパーツ(ボタン・パネル・ジェム)
docs/
  新ゲーム仕様書.md
  タスク分担表.md
  research/   ← Planner調査レポート
  specs/      ← 詳細仕様書
  reviews/    ← Phase 6 レビューレポート
```

## GitHub Issue Tracking
- 全タスクはGitHub Issues #1〜#74 で管理
- ラベルでフィルタ: `team:planner` / `team:designer` / `team:backend`
- フェーズ: `phase:1-core` 〜 `phase:6-test`
- Project: https://github.com/users/JunhwiAhn/projects/1
- タスク完了時: gh issue comment で作業内容記載 → `gh issue close #番号`
- **Issue closeコメントフォーマット:**
```
## 完了作業
- やった内容

## 主要ファイル
- 変更ファイルパス
- コミットハッシュ
```

## 実装完了状況 (2026-03-11時点)

### 全完了 (74/74 Issues closed)

#### Backend (全完了)
- **Phase 1 コア基盤** (#38-#45): 城中央化、partySlots5要素、falling削除、4辺スポーン、直線移動、キャラ分離、ターゲット優先度
- **Phase 2 操作&戦闘** (#46-#52): 城HP、ダメージ処理、聖職者回復、スティック入力、メイン移動、メインHP、復活
- **Phase 2 成長** (#53-#57): XPジェムドロップ/回収、レベルアップ、バフカード8種、XPマグネット
- **Phase 2 必殺技&ゴールド** (#58-#61): スキルゲージ、必殺技発動、ゴールド、ショップ
- **Phase 2 ラウンド** (#62-#65): ラウンド進行テーブル、インターバル、40体上限、城バリア
- **Phase 3 最適化** (#66-#68): 画面スケーリング(390×844)、オブジェクトプール、当たり判定最適化
- **属性システム** (#69-#73): ElementType enum、属性マッピング、ダメージ計算統合、ステージ別属性、属性バフカード6種
- **増強システム** (#74): 34種オーグメント、3ティア、R2/R4/R5選択トリガー

#### Designer (全完了)
- Phase 1: 城スプライト(#33)、タワースロット枠(#34)、スティックUI(#18)
- Phase 2: HUD(#16)、城HPバー(#17)、復活カウントダウン(#25)、城ダメージ点滅(#26)、復活無敵(#31)
- Phase 3: XPジェム描画(#27)、ゴールドコイン(#28)
- Phase 4: SKILLボタン(#19)、ゴールド表示(#20)、ラウンドクリア(#21)
- Phase 5: XPマグネット演出(#29)、ボムエフェクト(#30)、バリアエフェクト(#32)、ボス(#35)、ミニボス(#36)、バフカードアート(#37)
- Phase 6: レベルアップバフ選択UI(#22)、ショップUI(#23)、ゲームオーバー画面(#24)
- 増強選択UI、属性UI(HUDアイコン+状態異常アイコン)

#### Planner (全完了)
- ベンチマーク調査 (#1-#5): レベルアップバフ、TD バランス、スティックUX、ゴールド経済、スポーンパターン
- 仕様策定 (#6-#11): バフバランス、ラウンドテーブル、敵ステータス、ショップ価格、役割適性、難易度カーブ
- プレイテスト評価シート (#12)
- **Phase 6 レビュー** (#13-#15): 実装後バランスレビュー、UXフロー評価、バフカード体感テスト

## Key Specifications (Quick Reference)
```
城: 80×80px, 画面中央(size.x/2, size.y/2), HP=200, 接触半径=50px
タワー: 城中心±70px 対角4箇所 (T1:-70,-70 / T2:+70,-70 / T3:-70,+70 / T4:+70,+70)
メインキャラ: HP=50, 速度=150px/s, スティック外径60px/ノブ25px/デッドゾーン7px
敵速度: 通常=40, ミニボス=30, ボス=25 (px/s), 同時上限=40体
XPジェム: 回収半径=20px, 消滅=30秒, ドロップ(通常1/ミニボス10/ボス50)
レベルアップ必要XP: 10 + (Lv × 5)
スキルゲージ: 通常+3%, ミニボス+15%, ボス+50%, 100%で全画面999ダメージ
ゴールド: 通常1G/ミニボス5G/ボス20G
基準解像度: 390×844 (FixedResolutionViewport)
属性: 火→地→電気→水→火 (有利x1.5/不利x0.75), 闇=全属性x1.1
増強: R2/R4/R5クリア後に3択, Common/Rare/Legendary, 計34種
ラウンド: R1(2.0s,8体)→R5(1.0s,20体+ボス)→R6以降(-0.1s/R, +3体/R)
```

## 実装済みクラス・メソッド (castle_defense_game.dart)
```
# ゲッター
castleCenterX, castleCenterY

# 属性システム
ElementType enum (character_enums.dart)
ClassType.defaultElement (character_enums.dart)
getElementMultiplier(attacker, defender)
_damageMonsterWithElement()

# 増強システム
AugmentTier, AugmentCategory, Augment クラス
GameState.augmentSelect
_applyAugment()
_renderAugmentSelectionUI()

# レンダリング (Designer実装済み)
_renderCastle(), _renderCastleHP(), _renderHUD()
_renderVirtualStick(), _renderSkillButton()
_renderReviveCountdown(), _renderRoundClear()
_renderXpMagnetEffect(), _renderMonsterStatusIcons()
_renderLevelUpUI()
_renderShopOverlay()
_renderGameOver()

# VFX
VfxType.shockwave, VfxType.barrier
_VfxEffect クラス, _updateVfxEffects()

# オブジェクトプール
_MonsterPool (GCプレッシャー軽減)
```

## Language Rules
- コード内コメント: 韓国語
- コミットメッセージ: 日本語
- ドキュメント: 日本語 (韓国語ゲーム用語はそのまま)

## Coding Guidelines
- 既存コードのパターンと命名規則を踏襲する
- 流用コードは変更しない: `_handleMeleeUnit`, `_handleArcherUnit`, `_handleGunslingerUnit`, `_handleMagicUnit`, `_handleRangedUnit`, `_Projectile`, `_updateProjectiles()`, `_fireProjectile()`
- ガチャ・インベントリUI は変更しない
- `flutter analyze` でエラーがないことを確認してからコミット
- Issue close時は必ずコメント(完了作業・主要ファイル・コミット)を残す

## Coordination Rules
- 同じファイルを複数のチームメイトが同時に編集しない
- `castle_defense_game.dart` への変更はエンジニアが担当。デザイナーはレンダリングメソッド (`_render*`) のみ追加可
- 仕様変更があれば `docs/新ゲーム仕様書.md` を更新し、影響するIssueにコメントする

## Agent Team Configuration
- チーム名: `castle_defense_team`
- Planner: 調査・仕様策定 (コードは書かない)
- Engineer: ゲームロジック・バックエンド (castle_defense_game.dart メイン)
- Designer: UI/UX・エフェクト・アセット (_render* メソッドのみ)
- bypassPermissions モードで起動すると権限待ちなく進行
- agents/ にプロンプトテンプレートあり

## Git Authentication
- GitHub認証済み (JunhwiAhn, https経由)
- コミットは全てローカルに保存済み(20コミット)
