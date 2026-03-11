# デザイン・アセット改善提案

> 作成日: 2026-03-11
> 担当: Designer
> 対象ビルド: コミット 60905d1 時点
> 参照: `docs/reviews/P-3-3_UXフロー評価.md`

---

## 1. 概要

CastleDefenseプロジェクトのUI/UXおよびアセットの現状を棚卸しし、改善提案をまとめた。
主な発見は以下の通り:

1. **アセットの大半が未活用** — 6個の画像アセットのみ使用中。参照素材パック(538+ PNG)はほぼ手つかず
2. **全UIが絵文字ベース** — 40箇所以上で絵文字をアイコンとして使用。デバイス間で表示差異が発生する
3. **カラーパレットが未統一** — Violet Themeを意図しているが、実際には画面ごとに異なる色体系
4. **フォントサイズが散在** — 8px〜34pxまで30種以上のサイズが混在し、視覚的階層が不明瞭
5. **参照素材に重複コピーが存在** — `references/`に不要なコピーディレクトリと`.meta`ファイルが散在

---

## 2. アセット棚卸し

### 2.1 使用中アセット一覧

| ファイル名 | サイズ | 用途 | ロード箇所 (行番号) |
|---|---|---|---|
| `goblin.png` | 4KB | Stage1 通常モンスタースプライト | L748 |
| `castle.png` | 10KB | 城スプライト | L758 |
| `xp_gem.png` | 13KB | XPジェム | L768 |
| `gold_coin.png` | 19KB | ゴールドコイン | L778 |
| `boss_monster.png` | 1KB | ボスモンスター | L788 |
| `miniboss_monster.png` | 1KB | ミニボス | L794 |

**所見**: 全6ファイル、合計約48KB。ボスとミニボスは各1KBと非常に小さく、プレースホルダー品質の可能性がある。

### 2.2 未使用・不要ファイル

#### references/ 内の重複・不要ファイル

| パス | 問題 | 推奨 |
|---|---|---|
| `references/2D Characters-CasualMonsters copy/` | 元フォルダの完全コピー (5.7MB重複) | 削除推奨 |
| `references/Pixel Monster Pack copy/` | 元フォルダの完全コピー | 削除推奨 |
| `references/SPUM copy/` | 元フォルダの完全コピー | 削除推奨 |
| `references/*.meta` (6ファイル) | Unity用メタファイル。Flutterプロジェクトでは不要 | 削除推奨 |
| `references/2D Characters-CasualMonsters copy 2.meta` | 孤立メタファイル | 削除推奨 |
| `references/2D Characters-MinimalCharacters copy.meta` | 孤立メタファイル | 削除推奨 |
| `references/2D Characters-CasualMonsters copy.meta` | 孤立メタファイル | 削除推奨 |

**推定削減容量**: 重複コピー3フォルダで約15MB以上

#### ゲームアセットの不足

以下はコード内で絵文字が使われているが、画像アセットが存在しない項目:

- モンスター属性アイコン (火/水/地/電気/闇)
- バフカードアイコン (ATK/SPD/RANGE/HP等)
- UIアイコン (設定歯車、一時停止、ゴールドコイン等)
- スキルボタンアイコン (雷/爆発)
- ショップアイテムアイコン (城/タワー/キャラクター)
- 増強カテゴリアイコン (剣/弓/城/工具等)

### 2.3 参照素材の活用提案

#### Violet Theme UI (538 PNG) — 最優先活用

| カテゴリ | ファイル数 | 活用提案 |
|---|---|---|
| **Buttons/** | 10色ボタン + Square系 | `_drawButton` の現在のプログラマティック描画を画像ベースに置換。Purple/Violetをメイン、Redをゲームオーバー用に |
| **Panels/NEW Panels/** | 32パネル画像 | レベルアップカード、増強カード、ショップカードの背景に使用 |
| **Progress Bars/** | 9色バー + BG | HP/XP/スキルゲージを画像ベースプログレスバーに置換 |
| **Colored Icons/** | 84アイコン | Sword, Shield, Heart, Coin, Gem, Bomb, Crown, Star, Settings, Potion等 — 絵文字の完全置換が可能 |
| **White Icons/** | 280+アイコン | HUDアイコン、メニューアイコンに使用可能。Castle, Sword, Shield, Heart, Fire, Bomb, Crown, Speed Boost等 |
| **GemsAndCoins/** | 6種 | ゴールド/ジェム表示の画像化。Coin Stack, Gem Stack等 |
| **Sliders/Switch/Toggles/** | 各種 | 設定画面のUI要素 |

#### 2D Characters-CasualMonsters (5.7MB)

| 素材 | 活用提案 |
|---|---|
| `PNG/All/goblin/` (3種) | goblin, goblin_archer, goblin_warrior — ステージ1モンスターのバリエーション |
| `PNG/All/green_slime/` (3種) | slime, slime_king, stone_slime — ステージ2モンスター候補 |
| `PNG/All/skull/` (3種) | skull, skull_archer, skull_warrior — ステージ3モンスター候補 |
| `PNG/All/skull_posion/` (3種) | 毒属性のスカルバリエーション — 闇属性モンスター候補 |
| `PNG/Bar/` (4種) | prg_bar, prg_bar_green, prg_bar_red, prg_bg — HPバー画像素材 |
| `PNG/Bg/` (12種) | 背景画像、要塞画像 — ステージ背景に使用可能 |

#### 2D Characters-MinimalCharacters

| 素材 | 活用提案 |
|---|---|
| `PNG/character/character_1〜8/` | 各キャラクターのパーツ別PNG (Head, Body, Leg, Weapon, Cape等)。ガチャキャラクターの画像化に使用可能 |
| `PNG/fortress/` (4種) | fortress_1/2のup/down — 城スプライトの代替候補 |
| `PNG/bar/` (4種) | プログレスバー素材 |
| `PNG/map/` (7種) | 背景マップ素材 (sky, tree, field, middle layers) |

#### Pixel Monster Pack (82 PNG)

| 素材 | 活用提案 |
|---|---|
| `32x32 monsters/` | boneworm, cerberus, ooze, rat, scorpion, skull, slime, spider — 各4色バリエーション。属性別モンスターカラーに直接対応可能 |
| `64x64 monsters/` | 同モンスターの高解像度版。ボス/ミニボス用に適切 |

#### 2D Icons-CasualIconPack

| 素材 | 活用提案 |
|---|---|
| `Icons/128/` `256/` `512/` | Lightning, Coin, Star, Heart, Sword, Gem, Trophy, Shop, Gift, Bag, Map, Mission等。HUD・ショップ・リザルト画面のアイコンに使用可能 |

---

## 3. UI一貫性

### 3.1 カラーパレット分析

現在のコードで使用されている主要な色を分析した。

#### Violet Theme系 (意図された統一テーマ)

| 用途 | 色コード | 使用箇所 |
|---|---|---|
| 紫メイン | `#7C3AED` | レベルアップヘッダー、ショップボーダー |
| 暗紫背景 | `#1E1040` / `#0A0014` | レベルアップカード、増強背景 |
| 紫ボーダー | `#9B59F5` | レベルアップカード枠 |
| ピンク紫 | `#D946EF` | ショップ続けるボタン枠 |
| 濃紫 | `#5B21B6` | ショップ続けるボタン背景 |
| 暗紫テキスト | `#BBAAFF` / `#CCAAFF` | バフ説明、補助テキスト |

#### 非Violet (テーマ外の色)

| 用途 | 色コード | 問題 |
|---|---|---|
| `_drawButton` 背景 | `#3949AB` (インディゴ) | Violet Themeの紫系(`#7C3AED`)と不一致 |
| ゲームオーバー再試行 | `#B71C1C` (暗赤) | 意図的な差別化だが、ボーダー色`#EF5350`との組み合わせが粗い |
| HUD背景 | `#CC000000` (半透明黒) | 統一されているが、Violet Themeのパネル画像を使えばより洗練される |
| スキルゲージ充電中 | `#2196F3` (Material Blue) | Violet系でない純正Material色 |
| HP緑 | `#4CAF50` | Material Green。統一感よりは機能性を優先した色選択 |

**改善提案**:
- `_drawButton` の `#3949AB` を `#5B21B6` (Violet系) に統一
- スキルゲージ充電中を `#7C3AED` (紫) に変更し、テーマ統一
- HUD背景にViolet Theme UIの `Menu Background.png` を NinePatch的に使用
- レベルアップ/増強/ショップのカード背景にパネル画像を使用

### 3.2 フォント・テキスト

#### フォントサイズの分布 (castle_defense_game.dart内)

| サイズ範囲 | 使用回数 | 用途 |
|---|---|---|
| 8-9px | 12箇所 | HP数値、XPテキスト、バフスタック数、増強説明 |
| 10-11px | 14箇所 | HUDサブテキスト、ゴールド表示、購入回数 |
| 12-14px | 20箇所 | HUDメイン、ボスHP名、ラウンドクリア補足、ショップ情報 |
| 16-18px | 18箇所 | ボタンラベル、モンスターダメージ数字、キャラ名 |
| 20-24px | 10箇所 | StageProgress情報、タイトル系、増強アイコン |
| 26-34px | 6箇所 | 画面タイトル (GAME OVER, STAGE CLEAR!, 増強タイトル) |
| 80px | 1箇所 | 復活カウントダウン数字 |

**問題**:
- 明確なタイポグラフィ階層 (H1/H2/Body/Caption) が定義されていない
- 同じ論理レベルの情報が異なるサイズで表示される (例: HUD Row2のfontSize=12 vs StageProgressのfontSize=20-24)
- fontFamilyが未指定のため、デバイスデフォルトフォントに依存

**改善提案**:
```
定義すべきフォントスケール:
- Title:     28-32px (GAME OVER, STAGE CLEAR等)
- Heading:   20-24px (セクションタイトル、ラウンド表示)
- Subtitle:  16-18px (ボタンラベル、強調テキスト)
- Body:      13-14px (通常情報テキスト)
- Caption:   10-11px (補助情報、サブテキスト)
- Micro:     8-9px   (バー内数値、最小表示)
```
- フォントサイズ定数を `_kFontTitle`, `_kFontHeading` 等で定義し、全`_render*`で統一使用
- カスタムフォント (例: Noto Sans JP) の導入を検討

### 3.3 ボタン・パネルデザイン

#### `_drawButton` の使用状況

- 定義: L7205 — 基本的なRRect (角丸8px) + テキスト中央配置
- 色: enabled時 `#3949AB`、disabled時 `#B0BEC5`
- 使用箇所: ステージ選択ボタン、一時停止メニュー内ボタン等

**問題**:
- ボタンスタイルが1種類のみ。Primary/Secondary/Danger の区別がない
- ショップの「続ける」ボタン (L5241-5251) は `_drawButton` を使わず個別実装
- ゲームオーバーの「もう一度」ボタン (L7146-7163) も個別実装
- 結果: 画面ごとにボタンの見た目が異なる

**改善提案**:
- `_drawButton` を拡張して `ButtonStyle` enum (primary, secondary, danger, gold) を追加
- Violet Theme UIのボタン画像 (`Button Purple.png`, `Button Red.png` 等) を9-slice表示で使用
- 全ボタンを `_drawButton` 経由で統一描画

---

## 4. ビジュアル品質

### 4.1 アニメーション不足箇所

| 画面 | 現状 | 改善案 | 優先度 |
|---|---|---|---|
| バーチャルスティック | ノブが固定位置のまま動かない (P-09) | `_stickKnobPos` でノブ位置をリアルタイム描画 | **高** |
| レベルアップカード選択 | タップ即遷移 (P-14) | カード拡大 + 白フラッシュ (0.3秒) | 中 |
| 増強カード選択 | タップ即確定 (P-23) | ハイライト→確定の2段階 + 選択エフェクト | 中 |
| ショップ購入 | 数値変化のみ (P-17) | カード色フラッシュ (緑=成功/赤=失敗) | 中 |
| 戦闘開始 | 即座に敵スポーン (P-02) | 「3, 2, 1, GO!」カウントダウン表示 | 中 |
| 画面遷移全般 | 即切り替え | フェードイン/フェードアウト (0.2-0.3秒) | 低 |
| ボタンタップ | 視覚フィードバックなし | スケール縮小 (0.95x) + 色変化 | 低 |

### 4.2 絵文字→画像アセット置換提案

現在40箇所以上で絵文字がUIアイコンとして使用されている。絵文字はデバイス/OS/バージョンによって以下の問題がある:
- 表示サイズが不統一
- 色/デザインがOS間で異なる (iOS vs Android)
- 一部の絵文字が表示されない可能性
- フォントレンダリングのパフォーマンスコスト

#### 置換優先度: 高 (HUD・常時表示)

| 現在の絵文字 | 使用箇所 | 推奨代替アセット |
|---|---|---|
| `👾` | HUD モンスター数 | `Violet/White Icons/White Skull.png` |
| `⏱` | HUD タイマー | `Violet/Colored Icons/Timer.png` or `White Timer.png` |
| `🪙` | HUD/右下 ゴールド | `Violet/Colored Icons/Coin.png` or `Violet/GemsAndCoins/Coin Stack.png` |
| `🔥💧🌿⚡🌑` | 属性アイコン (HUD) | `Violet/White Icons/White Fire.png`, `White Water Droplet.png`, `White Leaf.png`, `White Energy.png`, `White Moon.png` |
| `🏃` | メインキャラアイコン | `Violet/White Icons/White Speed Boost.png` |

#### 置換優先度: 中 (オーバーレイ画面)

| 現在の絵文字 | 使用箇所 | 推奨代替アセット |
|---|---|---|
| `⚔` `⚡` | バフアイコン | `Violet/Colored Icons/Sword.png`, `Violet/White Icons/White Energy.png` |
| `🎯` | 射程バフ | `Violet/Colored Icons/target.png` |
| `🛡` | バリアバフ | `Violet/Colored Icons/Shield.png` |
| `💥` `⚡` | スキルボタン | `Violet/White Icons/White Explosion.png`, `White Energy.png` |
| `🏰` `🗼` `🧑` | ショップアイテム | `Violet/White Icons/White Castle 1.png`, `White Pilar.png`, `White Person.png` |
| `⚔️` `🏹` `🏰` `🔧` `💰` `🌟` `✨` `🔗` | 増強カテゴリ | Violet Colored/White Icons の対応アイコン |
| `★` `☆` | リザルト星評価 | `Violet/Colored Icons/Star.png`, `Star Dark.png` |
| `⚙️` | 設定 | `Violet/Colored Icons/Settings.png` |

#### 置換優先度: 低 (ゲーム内エフェクト)

| 現在の絵文字 | 使用箇所 | 推奨代替アセット |
|---|---|---|
| `🔥` `❄️` `⚡` | モンスター状態異常アイコン | 専用16x16アイコン作成 or Colored Icons縮小 |
| `🏔️` `⛰️` `🏜️` `☁️` | ステージ背景装飾 | `MinimalCharacters/PNG/map/` 素材活用 |
| `🎉` | ボスクリア演出 | `Violet/White Icons/White Party Pop.png` |

### 4.3 エフェクト改善

| 項目 | 現状 | 改善案 |
|---|---|---|
| 城ダメージ点滅 | `Color.fromRGBO` で赤フラッシュ | 点滅にパーティクル散乱を追加 |
| ボスオーラ | 円形グラデーション | パルス速度を遅くし、リング2重に |
| XPジェム | 画像スプライト | 回転アニメーション + 浮遊感のbobbing追加 |
| ゴールドコイン | 画像スプライト | 回転アニメーション追加 |
| スキル発動 | shockwave VFX | 画面揺れ (screen shake) 追加 |

---

## 5. レイアウト最適化 (390x844)

### 現状のレイアウト配置

```
┌──────────── 390px ────────────┐
│ HUD Row1 (y=14): HP+Lv+XP    │ 14px
│ HUD Row2 (y=32): 👾+⏱+Stage  │ 32px
│ HUD Row3 (y=57): 🪙+属性      │ 57-75px
├───────────────────────────────┤ 75px
│ StageProgress (y=15):         │ ← HUDと重複!
│   👾fontSize20 / Timer24 /    │
│   Stage20                     │
│                               │
│ WeaponInfo (y≈772):           │ ← スティックと重複
│   基本剣 DMG:1                │
│                               │
│    [Castle 80x80 中央]        │
│    [Tower ±70px 対角]         │
│                               │
│ 🕹(80,734)     🪙(208,766)   │
│              💥SKILL(335,754) │
└───────────────────────────────┘ 844px
```

### 問題点

1. **HUD と StageProgress の重複** (P-04): y=14-75 の HUD と y=15 の StageProgress が完全に重なる。StageProgressのフォントサイズ (20-24px) がHUD (12px) より大きく、視覚的に競合
2. **WeaponInfo の位置** (P-06): y≈772 はスティック (y=734) やスキルボタン (y=754) と近接。操作エリアとの干渉
3. **HUD Row3 の冗長性** (P-07): ゴールド表示が HUD内 (y=57) と右下 (y=766) の2箇所に存在。属性アイコンも同様に HUD Row1 (y=14) と Row3 (y=57) で重複
4. **操作エリアの競合** (P-10): スティック中心 (80, 734) とスキルボタン中心 (335, 754) のY距離が20pxしかない

### 改善案レイアウト

```
┌──────────── 390px ────────────┐
│ HUD (y=0-50px, 2行のみ):      │
│  Row1: [属性]HP■■■ Lv.5 XP■■│ y=8-22
│  Row2: 👾12 | 0:45 | S1-R3   │ y=28-42
├───────────────────────────────┤ 50px
│                               │
│ (ボスラウンド時のみ)           │
│  ⚔ BOSS ROUND ⚔  y=55       │
│                               │
│    [Castle 80x80 中央]        │
│    [Tower ±70px 対角]         │
│                               │
│                               │
│ 🕹(80,710)   🪙30G(240,700)  │ ← 20px上に移動
│              💥SKILL(335,730) │ ← 20px上に移動
└───────────────────────────────┘ 844px
```

変更点:
- `_renderStageProgress()` を削除 (HUD Row2に統合済み)
- `_renderWeaponInfo()` を削除 (デバッグ情報)
- HUD Row3 を廃止 (ゴールドは右下のみ、属性はRow1のみ)
- HUD高さを60+18=78px → 50pxに圧縮 (戦闘領域+28px拡大)
- スティック/スキルボタンを20px上方に移動し、画面端からの距離を確保

---

## 6. 優先実装リスト

### Tier 1: 高優先度 (ブロッカー級、1-2日)

| # | 項目 | 労力 | 効果 | 担当 |
|---|---|---|---|---|
| D-01 | `_renderStageProgress()` の削除 (HUDとの重複解消) | 小 | 高 | Designer |
| D-02 | `_renderWeaponInfo()` の削除 | 小 | 中 | Designer |
| D-03 | HUD Row3 廃止 (3行→2行化) | 小 | 中 | Designer |
| D-04 | スティックノブの入力追従 (`_stickKnobPos` 反映) | 小 | **高** | Designer※ |

※ D-04はスティックの `_stickKnobPos` 変数をrenderメソッドで参照するため、Engineer側の変数公開が前提

### Tier 2: 中優先度 (品質向上、3-5日)

| # | 項目 | 労力 | 効果 | 担当 |
|---|---|---|---|---|
| D-05 | `_drawButton` のViolet Theme統一 (`#3949AB` → `#5B21B6`) | 小 | 中 | Designer |
| D-06 | フォントサイズ定数の定義と統一適用 | 中 | 中 | Designer |
| D-07 | HUDアイコンの絵文字→Violet Theme画像置換 (👾⏱🪙) | 中 | 高 | Designer |
| D-08 | バフカード/増強カードアイコンの画像化 | 中 | 中 | Designer |
| D-09 | ゲームオーバー画面にゴールド表示追加 (P-19) | 小 | 中 | Designer |
| D-10 | スキルゲージ色のViolet Theme統一 | 小 | 低 | Designer |
| D-11 | レベルアップカード選択フィードバック追加 | 中 | 中 | Designer |

### Tier 3: 低優先度 (ポリッシュ、1-2週)

| # | 項目 | 労力 | 効果 | 担当 |
|---|---|---|---|---|
| D-12 | Violet Theme Panel画像をカード背景に使用 | 大 | 中 | Designer |
| D-13 | Progress Bar画像をHP/XPバーに使用 | 大 | 中 | Designer |
| D-14 | Violet Theme Button画像をボタンに使用 | 大 | 中 | Designer |
| D-15 | ステージ背景の画像化 (MinimalCharacters/map) | 大 | 高 | Designer |
| D-16 | Pixel Monster Packによるモンスターバリエーション | 大 | 高 | Designer+Engineer |
| D-17 | MinimalCharactersによるキャラクター画像化 | 大 | 高 | Designer+Engineer |
| D-18 | 画面遷移フェードイン/フェードアウト | 中 | 低 | Designer |
| D-19 | references/ 重複コピーの削除 | 小 | - | Designer |
| D-20 | カスタムフォント導入 | 中 | 中 | Designer+Engineer |

### 即座に対応可能な修正 (コード変更なし)

1. **references/ のクリーンアップ**: 重複コピーディレクトリ3つと孤立.metaファイル6つの削除で約15MB削減可能
2. **pubspec.yaml**: 現在 `assets/images/` のみ指定。参照素材を実際に使う場合は個別パスの追加が必要

---

## 付録: 色コード一覧 (統一後の推奨パレット)

```
// ── Violet Theme 統一パレット ──
Primary:        #7C3AED  (紫メイン — ヘッダー、アクセント)
Primary Dark:   #5B21B6  (濃紫 — ボタン背景)
Primary Light:  #9B59F5  (淡紫 — ボーダー)
Surface:        #1E1040  (暗紫 — カード背景)
Background:     #0A0014  (最暗紫 — オーバーレイ背景)

// ── 機能色 ──
Success:        #4CAF50  (HP高, 購入成功)
Warning:        #FFEB3B  (HP中)
Danger:         #F44336  (HP低, ゲームオーバー)
Info:           #7C3AED  (XPバー, スキルゲージ — Material Blue #2196F3 から変更)
Gold:           #FFD700  (ゴールド, 伝説ティア)

// ── テキスト色 ──
Text Primary:   #FFFFFF
Text Secondary: #BBAAFF  (淡紫)
Text Muted:     #888888
Text Disabled:  #555555
```
