# キャラクタースプライト統合計画書

## 概要
MinimalCharacters アセットパック（パーツ分離型・8キャラ）を合成し、
16クラスタイプ + メインキャラクター = 17種のスプライトを `assets/images/characters/` に準備した。
8キャラは直接合成、残り9種は色相シフトによるカラーバリエーションで生成。

## ファイル一覧と元素材

### 直接合成（8種）

| ファイル | 元素材 | 特徴 |
|---------|--------|------|
| `berserker.png` | character_1 (ハンマー+巻き毛) | 茶色ボディ、大型武器 |
| `guardian.png` | character_2 (盾+ヘルメット) | 濃茶ボディ、丸盾 |
| `warrior.png` | character_3 (剣+王冠) | 青紫ボディ、大剣 |
| `gunslinger.png` | character_4 (銃+紫髪) | 緑ボディ、射撃武器 |
| `paladin.png` | character_5 (槍+盾) | 金色ボディ、槍と盾 |
| `archer.png` | character_6 (弓+白髪) | 水色ボディ、弓 |
| `rogue.png` | character_7 (短剣+ベレー帽) | 茶緑ボディ、短剣 |
| `engineer.png` | character_8 (バズーカ+迷彩) | 緑迷彩ボディ、大型銃 |

### カラーバリエーション（9種）

| ファイル | 元素材 | 色相シフト | 結果色 |
|---------|--------|-----------|--------|
| `pyromancer.png` | character_3 (剣) | 0° | オレンジ赤系（火） |
| `cryomancer.png` | character_3 (剣) | 200° | 青系（氷） |
| `warlock.png` | character_3 (剣) | 270° | ピンク紫系（闇） |
| `priest.png` | character_5 (槍盾) | 40° | 黄緑系（回復） |
| `druid.png` | character_6 (弓) | 100° | 緑紫系（自然） |
| `alchemist.png` | character_4 (銃) | 80° | 赤緑系（錬金） |
| `necromancer.png` | character_2 (盾) | 260° | 紫系（死霊） |
| `summoner.png` | character_6 (弓) | 300° | ピンク系（召喚） |
| `main_character.png` | character_3 (剣) | 30° | 黄金系（主人公） |

## ClassType → スプライト マッピング表

### 役割別グループ

#### Tanker（タンカー）
| ClassType | スプライト | 理由 |
|-----------|-----------|------|
| `warrior` | warrior.png | 大剣、王冠 = 前衛戦士 |
| `guardian` | guardian.png | 盾持ち = 防御型 |
| `berserker` | berserker.png | ハンマー = 近接パワー型 |
| `paladin` | paladin.png | 槍+盾 = 聖騎士 |

#### Physical Dealer（物理ディーラー）
| ClassType | スプライト | 理由 |
|-----------|-----------|------|
| `archer` | archer.png | 弓 = 遠距離物理 |
| `gunslinger` | gunslinger.png | 銃 = 射撃 |
| `rogue` | rogue.png | 短剣 = 素早い近接 |

#### Magic Dealer（魔法ディーラー）
| ClassType | スプライト | 理由 |
|-----------|-----------|------|
| `pyromancer` | pyromancer.png | 赤系 = 火魔法 |
| `cryomancer` | cryomancer.png | 青系 = 氷魔法 |
| `warlock` | warlock.png | 紫系 = 闇魔法 |
| `necromancer` | necromancer.png | 濃紫 = 死霊術 |
| `summoner` | summoner.png | ピンク = 召喚魔法 |

#### Priest（回復系）
| ClassType | スプライト | 理由 |
|-----------|-----------|------|
| `priest` | priest.png | 黄緑 = 回復/聖 |
| `druid` | druid.png | 緑紫 = 自然回復 |

#### Utility（ユーティリティ）
| ClassType | スプライト | 理由 |
|-----------|-----------|------|
| `alchemist` | alchemist.png | 銃ベース赤緑 = 調合/投擲 |
| `engineer` | engineer.png | バズーカ+迷彩 = 技術者 |

#### メインキャラクター
| タイプ | スプライト | 理由 |
|--------|-----------|------|
| main | main_character.png | 金色系 = 主人公感 |

## 推奨表示サイズ

### ゲーム内ピクセルサイズ

| 用途 | 推奨サイズ | 理由 |
|------|-----------|------|
| メインキャラ | 32x32 px | 城(80x80)の約40%、スティック操作で動くため視認性重視 |
| タワーキャラ | 24x24 px | タワースロット(±70px配置)に4体並ぶ。城に対して小さめ |
| ショップ/UI表示 | 48x48 px | UI上での選択画面用、やや大きめ |
| レベルアップ表示 | 64x64 px | バフカード選択UI用 |

### サイズ関係
```
城 (80x80) > レベルアップUI (64x64) > ショップUI (48x48) > メインキャラ (32x32) > タワー (24x24)
```

### 元画像サイズ
素材は約100-160px四方。32pxや24pxに縮小して使用。
Flameの `Sprite` で `srcSize` / `destSize` を指定するか、
`SpriteComponent` の `size` で表示サイズを制御する。

## castle_defense_game.dart での読み込み・描画方法提案

### 1. 画像プリロード（onLoad内）
```dart
// onLoad() 内で全キャラスプライトをプリロード
final characterSprites = <String, Sprite>{};
final classTypes = ['warrior', 'guardian', 'berserker', 'archer',
    'gunslinger', 'rogue', 'pyromancer', 'cryomancer', 'warlock',
    'priest', 'druid', 'paladin', 'alchemist', 'engineer',
    'necromancer', 'summoner', 'main_character'];

for (final cls in classTypes) {
  characterSprites[cls] = await loadSprite('characters/$cls.png');
}
```

### 2. メインキャラ描画（_renderMainCharacter内）
```dart
// 現在のCanvas描画を置き換え
final sprite = characterSprites[mainCharClassType] ?? characterSprites['main_character']!;
sprite.render(canvas,
  position: Vector2(mainCharX, mainCharY),
  size: Vector2(32, 32),
  anchor: Anchor.center,
);
```

### 3. タワーキャラ描画
```dart
// 各タワースロットのキャラ描画
for (final slot in partySlots) {
  if (slot.character != null) {
    final cls = slot.character!.classType.name; // enum名がファイル名と一致
    final sprite = characterSprites[cls];
    sprite?.render(canvas,
      position: Vector2(slot.x, slot.y),
      size: Vector2(24, 24),
      anchor: Anchor.center,
    );
  }
}
```

### 4. ClassType enum名とファイル名の対応
`character_enums.dart` の `ClassType` enum値がそのままファイル名になるよう命名済み:
```
ClassType.warrior  → 'characters/warrior.png'
ClassType.guardian → 'characters/guardian.png'
// ... 以下同様
```

## 元素材パス参照

全ての素材は以下から合成:
```
assets/images/references/2D Characters-MinimalCharacters/PNG/character/
  character_1/ (Body, Cape, Head, Leg, Leg2, Mouth, Weapon)
  character_2/ (Body, Cape, Head, Leg, Leg2, Mouth, Weapon)
  character_3/ (Body, Cape, Head, Leg, Leg2, Mouth, Weapon)
  character_4/ (Body, Cape, Head, Leg, Leg2, Mouth, Shot, Weapon, Weapon_)
  character_5/ (Body, Cape, Head, Leg, Leg2, Mouth, Shield, Weapon)
  character_6/ (Back, Body, Cape, Head, Leg, Leg2, Mouth, Shot, Weapon, Weapon_)
  character_7/ (Body, Cape, Head, Leg, Leg2, Mouth, Weapon)
  character_8/ (Body, Cape, Head, Leg, Leg2, Mouth, Neck, Weapon)
```

合成スクリプト: Pythonで Body→中央, Head→上部, Leg→下部, Weapon→右側 に配置後、bounding boxでトリミング。

## SPUM アセット調査結果

`assets/images/references/SPUM/` はUnity SPUM (2D Pixel Unit Maker) のアセット。
- Unity Prefab形式 (.prefab) でキャラが定義されており、PNG単体では使用不可
- パーツは Legacy/0_Unit/0_Sprite/ 以下に Hair, Eye, Body, Pant, Helmet 等が分離
- Flameエンジンへの直接統合は困難（Unityアニメーション前提のアセット構造）
- 将来的にパーツを個別抽出して合成すれば利用可能だが、MinimalCharactersの方が適切

## 今後の改善案

1. **アニメーション対応**: MinimalCharactersのPSBファイルからアニメーションフレームを抽出し、歩行/攻撃アニメーション追加
2. **武器差し替え**: 魔法系クラスの武器パーツを杖に変更（現在は剣ベースのカラバリ）
3. **SPUM連携**: SPUMのパーツを個別抽出し、より多様なキャラバリエーション生成
4. **影の追加**: `Shadow.png` を各キャラの足元に配置して立体感向上
