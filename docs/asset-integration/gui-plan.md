# GUI素材統合計画書

## 概要
Violet Theme UI と CasualIconPack から選定したGUI素材を `assets/images/ui/` にコピーし、
既存の絵文字/Canvas描画ベースのUIをスプライト画像ベースに置換する計画。

---

## 1. コピー済みファイル一覧

### ボタン (Violet Theme UI / Buttons)
| ファイル名 | 元ファイル | 用途 |
|---|---|---|
| `btn_normal.png` | Button Purple.png | 通常ボタン背景 |
| `btn_pressed.png` | Button Violet.png | 押下時ボタン背景 |
| `btn_disabled.png` | Button Blue.png | 無効ボタン背景 |
| `btn_square_normal.png` | Small Square Button Purple.png | 正方形ボタン通常 |
| `btn_square_pressed.png` | Small Square Button Violet.png | 正方形ボタン押下 |

### パネル・背景 (Violet Theme UI / Panels)
| ファイル名 | 元ファイル | 用途 |
|---|---|---|
| `panel_dark.png` | Dark Panel Purple.png | メインパネル背景（ダーク） |
| `panel_dark_alt.png` | Dark Panel Violet.png | 代替ダークパネル |
| `panel_card.png` | White Panel Purple.png | バフカード/増強カード背景 |
| `panel_card_alt.png` | Dark Panels Style 2 Purple.png | 代替カード背景 |
| `panel_ribbon.png` | Panel 1 BLUE.png | リボン付きパネル（タイトル用） |
| `panel_menu_bg.png` | Menu Background.png | メニュー全体背景 |
| `panel_dialog_bg.png` | Background.png | ダイアログ全体背景 |
| `panel_input_bg.png` | Input Field Background.png | 入力フィールド背景 |

### プログレスバー (Violet Theme UI / Progress Bars)
| ファイル名 | 元ファイル | 用途 |
|---|---|---|
| `hp_bar_bg.png` | Progress Bar Background.png | バー共通背景 |
| `hp_bar_fill.png` | Progress Bar Red.png | 城HP / メインHP (赤) |
| `hp_bar_fill_green.png` | Progress Bar Green.png | 城HP高残量時 (緑) |
| `xp_bar_fill.png` | Progress Bar Blue.png | XPバー (青) |
| `skill_bar_fill.png` | Progress Bar Yellow.png | スキルゲージ (黄) |
| `bar_fill_purple.png` | Progress Bar Purple.png | 汎用バー (紫) |

### ジェム・コイン (Violet Theme UI / GemsAndCoins)
| ファイル名 | 元ファイル | 用途 |
|---|---|---|
| `coin_stack.png` | Coin Stack.png | ショップ/ゴールド表示 |
| `gem_stack.png` | Gem Stack.png | ジェム表示 |

### カラーアイコン (Violet Theme UI / Colored Icons)
| ファイル名 | 元ファイル | 用途 |
|---|---|---|
| `icon_heal.png` | Heart.png | HP回復/REPAIR |
| `icon_barrier.png` | Shield.png | バリアアイコン |
| `icon_magnet.png` | Magnet.png | マグネットバフ |
| `icon_dark.png` | Skull.png | 闇属性 |
| `icon_electric.png` | Energy.png | 電気属性 |
| `icon_bomb.png` | Bomb.png | ボムエフェクト |
| `icon_coin.png` | Coin.png | ゴールドアイコン |
| `icon_range.png` | target.png | 射程バフ |
| `icon_earth.png` | leaf.png | 地属性 |
| `icon_potion.png` | Potion Red.png | ポーション |
| `icon_crown.png` | Crown 1.png | ランク/レアリティ |
| `icon_gem.png` | Gem 1 Purple.png | ジェムアイコン |
| `icon_close.png` | Close.png | 閉じるボタン |
| `icon_check.png` | Check.png | チェックマーク |
| `icon_settings.png` | Settings.png | 設定 |

### ホワイトアイコン (Violet Theme UI / White Icons)
| ファイル名 | 元ファイル | 用途 |
|---|---|---|
| `icon_attack.png` | White Swords.png | 攻撃力バフ (ATK UP) |
| `icon_attack_alt.png` | White Cross Swords.png | 攻撃力バフ代替 |
| `icon_speed.png` | White Speed Boost.png | 速度バフ (SPD UP) |
| `icon_fire.png` | White Fire.png | 火属性 |
| `icon_water.png` | White Water Droplet.png | 水属性 |
| `icon_dark_alt.png` | White Moon.png | 闇属性代替 (月) |
| `icon_shield.png` | White Shield 1.png | 防御/バリア |
| `icon_tower.png` | White Castle 1.png | タワーバフ (TOWER UP) |
| `icon_skill.png` | White Explosion.png | スキルボタン/必殺技 |
| `icon_bow.png` | White Bow.png | 弓アイコン |
| `icon_energy.png` | White Energy.png | エネルギー |
| `icon_tornado.png` | White Tornado.png | 竜巻/風 |
| `icon_freeze.png` | White Snow.png | 凍結状態異常 |
| `icon_strength_up.png` | White Strength Up.png | 強化アイコン |
| `star_filled.png` | White Star.png | 獲得済み星 (ティア表示) |
| `star_empty.png` | White Star Hollow.png | 未獲得星 |

### CasualIconPack (128px)
| ファイル名 | 元ファイル | 用途 |
|---|---|---|
| `icon_attack_casual.png` | Icon_Equipment_Weapon_Sword02.png | 攻撃アイコン (カラー版) |
| `icon_heal_casual.png` | Icon_Resources_Heart01_Red.png | 回復アイコン (カラー版) |
| `icon_lightning_casual.png` | Icon_Resources_Lightning01_Blue.png | 稲妻アイコン |
| `icon_coin_casual.png` | Icon_Resources_Coin01_Gold.png | コインアイコン |
| `icon_star_casual.png` | Icon_Resources_Star01_Gold.png | 星アイコン (ゴールド) |
| `icon_gem_casual.png` | Icon_Materials_Gem02_Purple.png | ジェムアイコン |
| `icon_shop.png` | Icon_ETC_Buildings_Shop01.png | ショップアイコン |

---

## 2. 見つからなかった素材（スキップ）
- 磁石のカラーアイコン → `icon_magnet.png` (Colored Icons版) で代用OK
- 水属性カラーアイコン → `icon_water.png` (White Icons版) を使用
- 電気属性のカラー稲妻 → `icon_electric.png` (Energy) + `icon_lightning_casual.png` で代用

---

## 3. 各素材の使用先マッピング

### `_renderHUD()` — HUD表示
| 現在の表示 | 置換先アセット |
|---|---|
| Canvas描画のHPバー | `hp_bar_bg.png` + `hp_bar_fill.png` |
| `TextPaint` ゴールド表示 | `icon_coin.png` + テキスト |
| `TextPaint` XP表示 | `xp_bar_fill.png` + `hp_bar_bg.png` |
| スキルゲージ Canvas描画 | `skill_bar_fill.png` + `hp_bar_bg.png` |

### `_renderSkillButton()` — スキルボタン
| 現在の表示 | 置換先アセット |
|---|---|
| Canvas矩形ボタン | `btn_square_normal.png` / `btn_square_pressed.png` |
| テキスト「SKILL」 | `icon_skill.png` オーバーレイ |

### `_renderLevelUpUI()` — レベルアップバフ選択
| 現在の表示 | 置換先アセット |
|---|---|
| 半透明オーバーレイ | `panel_dialog_bg.png` |
| バフカード背景 | `panel_card.png` |
| バフアイコン(絵文字) | 下記マッピング参照 |
| 選択ボタン | `btn_normal.png` / `btn_pressed.png` |

### `_renderShopOverlay()` — ショップUI
| 現在の表示 | 置換先アセット |
|---|---|
| ショップ全体背景 | `panel_menu_bg.png` + `panel_dark.png` |
| 商品カード | `panel_card.png` |
| 購入ボタン | `btn_normal.png` |
| ゴールド価格表示 | `icon_coin.png` + テキスト |
| ショップアイコン | `icon_shop.png` |

### `_renderGameOver()` — ゲームオーバー画面
| 現在の表示 | 置換先アセット |
|---|---|
| 背景オーバーレイ | `panel_dialog_bg.png` |
| リトライボタン | `btn_normal.png` |
| スコア表示パネル | `panel_dark.png` |

### `_renderRoundClear()` — ラウンドクリア
| 現在の表示 | 置換先アセット |
|---|---|
| クリア表示パネル | `panel_ribbon.png` |
| 星評価 | `star_filled.png` / `star_empty.png` |

### `_renderAugmentSelectionUI()` — 増強選択UI
| 現在の表示 | 置換先アセット |
|---|---|
| 選択パネル背景 | `panel_dialog_bg.png` |
| 増強カード | `panel_card.png` (Common) / `panel_card_alt.png` (Rare/Legendary) |
| ティア表示 | `star_filled.png` × ティア数 |
| 選択ボタン | `btn_normal.png` |

### `_renderCastleHP()` — 城HPバー
| 現在の表示 | 置換先アセット |
|---|---|
| Canvas矩形HPバー | `hp_bar_bg.png` + `hp_bar_fill.png` / `hp_bar_fill_green.png` |

### `_renderMonsterStatusIcons()` — 状態異常アイコン
| 現在の表示 | 置換先アセット |
|---|---|
| 絵文字「火」 | `icon_fire.png` |
| 絵文字「氷」 | `icon_freeze.png` |
| 絵文字「雷」 | `icon_electric.png` |

---

## 4. バフカード絵文字→アイコン置換マッピング

| バフ名 | 現在(絵文字) | 置換アイコン |
|---|---|---|
| ATK UP | 文字表示 | `icon_attack.png` |
| SPD UP | 文字表示 | `icon_speed.png` |
| RANGE UP | 文字表示 | `icon_range.png` |
| REPAIR | 文字表示 | `icon_heal.png` |
| TOWER UP | 文字表示 | `icon_tower.png` |
| MAGNET | 文字表示 | `icon_magnet.png` |
| BARRIER | 文字表示 | `icon_barrier.png` |
| BOMB | 文字表示 | `icon_bomb.png` |

---

## 5. 属性アイコンマッピング

| 属性 | アイコン (メイン) | 代替 |
|---|---|---|
| 火 (fire) | `icon_fire.png` | — |
| 水 (water) | `icon_water.png` | — |
| 地 (earth) | `icon_earth.png` | — |
| 電気 (electric) | `icon_electric.png` | `icon_lightning_casual.png` |
| 闇 (dark) | `icon_dark.png` | `icon_dark_alt.png` (月) |

---

## 6. 読み込みコード例

### pubspec.yaml にアセット登録
```yaml
flutter:
  assets:
    - assets/images/ui/
```

### Flame での画像読み込み
```dart
// onLoad() 内で一括読み込み
await images.loadAll([
  'ui/btn_normal.png',
  'ui/btn_pressed.png',
  'ui/btn_disabled.png',
  'ui/panel_dark.png',
  'ui/panel_card.png',
  'ui/hp_bar_bg.png',
  'ui/hp_bar_fill.png',
  'ui/icon_attack.png',
  'ui/icon_speed.png',
  'ui/icon_range.png',
  'ui/icon_heal.png',
  'ui/icon_tower.png',
  'ui/icon_magnet.png',
  'ui/icon_barrier.png',
  'ui/icon_bomb.png',
  'ui/icon_fire.png',
  'ui/icon_water.png',
  'ui/icon_earth.png',
  'ui/icon_electric.png',
  'ui/icon_dark.png',
  'ui/icon_skill.png',
  'ui/star_filled.png',
  'ui/star_empty.png',
  'ui/icon_coin.png',
  'ui/icon_shop.png',
  'ui/skill_bar_fill.png',
  'ui/xp_bar_fill.png',
]);
```

### スプライト描画例 (render内)
```dart
// NineTileBox でパネル背景をスケーラブル描画
final panelSprite = Sprite(images.fromCache('ui/panel_dark.png'));
panelSprite.render(
  canvas,
  position: Vector2(x, y),
  size: Vector2(width, height),
);

// アイコン描画
final attackIcon = Sprite(images.fromCache('ui/icon_attack.png'));
attackIcon.render(
  canvas,
  position: Vector2(iconX, iconY),
  size: Vector2(32, 32),  // アイコンは32x32pxに統一推奨
);

// プログレスバー描画
final barBg = Sprite(images.fromCache('ui/hp_bar_bg.png'));
final barFill = Sprite(images.fromCache('ui/hp_bar_fill.png'));
barBg.render(canvas, position: Vector2(bx, by), size: Vector2(barW, barH));
barFill.render(
  canvas,
  position: Vector2(bx, by),
  size: Vector2(barW * (currentHP / maxHP), barH),  // 割合でクリップ
);
```

---

## 7. サイズ推奨

| カテゴリ | 描画サイズ (px) | 備考 |
|---|---|---|
| バフ/属性アイコン | 32x32 | HUD内、カード内 |
| ボタン | 120x40 〜 160x50 | NineTileBox推奨 |
| カードパネル | 100x140 | バフ選択3枚横並び |
| プログレスバー | 幅可変 x 12〜16px高 | HPバー、XPバー |
| 星アイコン | 20x20 | ティア表示 |
| スキルボタン | 50x50 | 正方形ボタン使用 |

---

## 8. 実装優先順位

1. **HPバー/スキルゲージ** — `_renderHUD()`, `_renderCastleHP()` (効果が即座に見える)
2. **バフ選択UI** — `_renderLevelUpUI()` (パネル + アイコン + ボタン)
3. **増強選択UI** — `_renderAugmentSelectionUI()` (パネル + ティア星)
4. **ショップUI** — `_renderShopOverlay()` (パネル + コイン + ボタン)
5. **ゲームオーバー** — `_renderGameOver()` (パネル + ボタン)
6. **状態異常アイコン** — `_renderMonsterStatusIcons()` (属性アイコン)
7. **ラウンドクリア** — `_renderRoundClear()` (リボンパネル + 星)
