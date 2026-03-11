# モンスター素材統合計画書

## 1. 素材一覧と元パス

### CasualMonsters (Pre-assembled composites)

| コピー先ファイル | 元パス | サイズ |
|---|---|---|
| `normal_goblin.png` | `references/2D Characters-CasualMonsters/PNG/All/goblin/goblin.png` | 75x86px |
| `normal_skeleton.png` | `references/2D Characters-CasualMonsters/PNG/All/skull/skull.png` | 89x112px |
| `normal_slime.png` | `references/2D Characters-CasualMonsters/PNG/All/green_slime/slime.png` | 81x72px |
| `normal_poison_skull.png` | `references/2D Characters-CasualMonsters/PNG/All/skull_posion/skull.png` | 89x112px |
| `normal_green_goblin.png` | `references/2D Characters-CasualMonsters/PNG/All/goblin_green/goblin.png` | 75x86px |
| `miniboss_goblin_warrior.png` | `references/2D Characters-CasualMonsters/PNG/All/goblin/goblin_warrior.png` | 114x114px |
| `miniboss_skull_warrior.png` | `references/2D Characters-CasualMonsters/PNG/All/skull/skull_warrior.png` | 116x131px |
| `miniboss_slime_king.png` | `references/2D Characters-CasualMonsters/PNG/All/orange_slime/slime_king.png` | 125x100px |
| `boss_poison_warrior.png` | `references/2D Characters-CasualMonsters/PNG/All/skull_posion/skull_warrior.png` | 116x131px |

### Pixel Monster Pack (64x64 pixel art)

| コピー先ファイル | 元パス | サイズ |
|---|---|---|
| `boss_cerberus.png` | `references/Pixel Monster Pack/64x64 monsters/cerberus-red.png` | 64x64px |

### 既存コピー済みファイル (前回セッション分)

以下は `monster_stage*` 命名で既にコピー済み（Pixel Monster Pack 64x64由来）:

| ファイル | 元素材 | 用途 |
|---|---|---|
| `monster_stage1_rat.png` | `rat-brown.png` | Stage1 通常 |
| `monster_stage1_slime.png` | `slime-green.png` | Stage1 通常 |
| `monster_stage1_worm.png` | `worm-green.png` | Stage1 通常 |
| `monster_stage2_skull.png` | `skull-red.png` | Stage2 通常 |
| `monster_stage2_slime.png` | `slime-red.png` | Stage2 通常 |
| `monster_stage2_spider.png` | `spider-blue.png` | Stage2 通常 |
| `monster_stage3_scorpion.png` | `scorpion-green.png` | Stage3 通常 |
| `monster_stage3_skull.png` | `skull-green.png` | Stage3 通常 |
| `monster_stage3_slime.png` | `slime-black.png` | Stage3 通常 |
| `monster_stage4_skull.png` | `skull-blue.png` | Stage4 通常 |
| `monster_stage4_spider.png` | `spider-black.png` | Stage4 通常 |
| `monster_stage4_wolf.png` | `wolf-black.png` | Stage4 通常 |
| `monster_stage5_boneworm.png` | `boneworm-black.png` | Stage5 通常 |
| `monster_stage5_ooze.png` | `ooze-black.png` | Stage5 通常 |
| `monster_stage5_wolf.png` | `wolf-black.png` | Stage5 通常 |
| `miniboss_cerberus_fire.png` | `cerberus-red.png` | ミニボス(火) |
| `miniboss_cerberus_water.png` | `cerberus-blue.png` | ミニボス(水) |
| `miniboss_cerberus_earth.png` | `cerberus-green.png` | ミニボス(地) |
| `miniboss_cerberus_dark.png` | `cerberus-black.png` | ミニボス(闇) |
| `monster_spritesheet_64.png` | `sprite-sheet-64x64.png` | 参照用シート |

---

## 2. 各モンスターの用途（ステージ/タイプ）

### 推奨: 2系統アート混合プラン

CasualMonsters（カジュアルスタイル）とPixel Monster Pack（ピクセルスタイル）の2系統がある。
**推奨**: CasualMonstersを主軸に使用し、ボス/特殊敵にPixel Monster Packを混ぜることで視覚的な差別化を実現。

### ステージ別割り当て

| ステージ | 属性 | 通常モンスター | ミニボス | ボス |
|---|---|---|---|---|
| Stage 1 (R1-R5) | 地 | `normal_goblin.png` | `miniboss_goblin_warrior.png` | `boss_cerberus.png` |
| Stage 2 | 火 | `normal_skeleton.png` | `miniboss_skull_warrior.png` | `boss_poison_warrior.png` |
| Stage 3 | 電気 | `normal_slime.png` | `miniboss_slime_king.png` | `boss_cerberus.png` (色変え) |
| Stage 4 | 水 | `normal_poison_skull.png` | `miniboss_skull_warrior.png` (色変え) | `boss_poison_warrior.png` (色変え) |
| Stage 5 | 闇 | `normal_green_goblin.png` | `miniboss_goblin_warrior.png` (色変え) | `boss_cerberus.png` (色変え) |

**代替案: Pixel系ステージ進行**（既存 `monster_stage*` ファイル活用）

| ステージ | 通常1 | 通常2 | 通常3 | ミニボス |
|---|---|---|---|---|
| Stage 1 (地) | `monster_stage1_rat.png` | `monster_stage1_slime.png` | `monster_stage1_worm.png` | `miniboss_cerberus_earth.png` |
| Stage 2 (火) | `monster_stage2_skull.png` | `monster_stage2_slime.png` | `monster_stage2_spider.png` | `miniboss_cerberus_fire.png` |
| Stage 3 (電気) | `monster_stage3_scorpion.png` | `monster_stage3_skull.png` | `monster_stage3_slime.png` | `miniboss_cerberus_water.png` |
| Stage 4 (水) | `monster_stage4_skull.png` | `monster_stage4_spider.png` | `monster_stage4_wolf.png` | `miniboss_cerberus_dark.png` |
| Stage 5 (闇) | `monster_stage5_boneworm.png` | `monster_stage5_ooze.png` | `monster_stage5_wolf.png` | `miniboss_cerberus_dark.png` |

---

## 3. 推奨表示サイズ（ゲーム内px）

基準解像度: 390x844 (FixedResolutionViewport)

| モンスタータイプ | 描画サイズ | 備考 |
|---|---|---|
| 通常モンスター (Casual) | 32x32px | 元画像が75-89px幅。縮小して表示 |
| 通常モンスター (Pixel) | 32x32px | 元画像64x64をそのまま or 半分 |
| ミニボス (Casual) | 48x48px | 通常の1.5倍。威圧感を出す |
| ミニボス (Pixel/Cerberus) | 48x48px | 同上 |
| ボス (Cerberus) | 64x64px | 通常の2倍。存在感重視 |
| ボス (Poison Warrior) | 64x64px | 同上 |

**注意**: リサイズはコード側 (`Sprite.render()` の `size` パラメータ) で行う。画像ファイル自体はリサイズしない。

---

## 4. castle_defense_game.dart での読み込み・描画方法の提案

### 4.1 画像プリロード

```dart
// onLoad() 内で追加
final monsterImages = {
  'normal_goblin': await images.load('monsters/normal_goblin.png'),
  'normal_skeleton': await images.load('monsters/normal_skeleton.png'),
  'normal_slime': await images.load('monsters/normal_slime.png'),
  'normal_poison_skull': await images.load('monsters/normal_poison_skull.png'),
  'normal_green_goblin': await images.load('monsters/normal_green_goblin.png'),
  'miniboss_goblin_warrior': await images.load('monsters/miniboss_goblin_warrior.png'),
  'miniboss_skull_warrior': await images.load('monsters/miniboss_skull_warrior.png'),
  'miniboss_slime_king': await images.load('monsters/miniboss_slime_king.png'),
  'boss_cerberus': await images.load('monsters/boss_cerberus.png'),
  'boss_poison_warrior': await images.load('monsters/boss_poison_warrior.png'),
};
```

### 4.2 モンスターモデル拡張案

```dart
// _Monster クラスに imageKey フィールド追加
class _Monster {
  // 既存フィールド...
  String imageKey; // 'normal_goblin', 'boss_cerberus' 等
}
```

### 4.3 _spawnMonster() での割り当て

```dart
// ステージとモンスタータイプに基づいてimageKeyを設定
String _getMonsterImageKey(int stage, bool isBoss, bool isMiniBoss) {
  if (isBoss) {
    return stage <= 2 ? 'boss_cerberus' : 'boss_poison_warrior';
  }
  if (isMiniBoss) {
    switch (stage) {
      case 1: return 'miniboss_goblin_warrior';
      case 2: return 'miniboss_skull_warrior';
      case 3: return 'miniboss_slime_king';
      case 4: return 'miniboss_skull_warrior';
      case 5: return 'miniboss_goblin_warrior';
    }
  }
  // 通常
  switch (stage) {
    case 1: return 'normal_goblin';
    case 2: return 'normal_skeleton';
    case 3: return 'normal_slime';
    case 4: return 'normal_poison_skull';
    case 5: return 'normal_green_goblin';
  }
  return 'normal_goblin';
}
```

### 4.4 描画（現在のCanvas描画を画像描画に置換）

```dart
// _renderMonsters() 内、現在の Canvas.drawCircle() を以下に置換:
void _renderMonsterSprite(Canvas canvas, _Monster monster) {
  final image = monsterImages[monster.imageKey];
  if (image == null) return;

  final size = monster.isBoss ? 64.0
      : monster.isMiniBoss ? 48.0
      : 32.0;

  final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
  final dst = Rect.fromCenter(
    center: Offset(monster.x, monster.y),
    width: size,
    height: size,
  );
  canvas.drawImageRect(image, src, dst, Paint());
}
```

---

## 5. ステージごとのモンスター出現パターン提案

仕様書のラウンド進行テーブル (R1-R5+) と組み合わせた出現パターン:

### Stage 1 (属性: 地)

| ラウンド | 間隔 | 敵数 | 通常 | ミニボス | ボス |
|---|---|---|---|---|---|
| R1 | 2.0s | 8体 | normal_goblin x8 | - | - |
| R2 | 1.8s | 10体 | normal_goblin x9 | - | - |
| R3 | 1.5s | 13体 | normal_goblin x11 | miniboss_goblin_warrior x2 | - |
| R4 | 1.2s | 16体 | normal_goblin x13 | miniboss_goblin_warrior x3 | - |
| R5 | 1.0s | 20体 | normal_goblin x15 | miniboss_goblin_warrior x4 | boss_cerberus x1 |

### Stage 2 (属性: 火)
- 通常: `normal_skeleton`
- ミニボス: `miniboss_skull_warrior`
- ボス: `boss_poison_warrior`
- 同構成比率、敵ステータス上昇

### Stage 3 (属性: 電気)
- 通常: `normal_slime`
- ミニボス: `miniboss_slime_king`
- ボス: `boss_cerberus` (ティント/色変え推奨)

### Stage 4 (属性: 水)
- 通常: `normal_poison_skull`
- ミニボス: `miniboss_skull_warrior`
- ボス: `boss_poison_warrior`

### Stage 5 (属性: 闇)
- 通常: `normal_green_goblin`
- ミニボス: `miniboss_goblin_warrior`
- ボス: `boss_cerberus`

### ラウンド6以降 (エンドレス)
- スポーン間隔: -0.1s/R, +3体/R
- 全ステージのモンスターをランダム混合で出現させることを推奨
- 色ティント（Paint.colorFilter）で属性を視覚的に区別:
  - 火: 赤ティント / 水: 青ティント / 地: 緑ティント / 電気: 黄ティント / 闇: 紫ティント

---

## 6. アートスタイル選定の最終判断

### 選択肢A: CasualMonsters主軸（推奨）
- **利点**: 高品質なベクター風アート、統一感あり、ボス/ミニボスの差別化が明確（武器/王冠付き）
- **欠点**: 5種族3バリアント = 15体が上限。ステージ5以降は色変え必須

### 選択肢B: Pixel Monster Pack主軸
- **利点**: バリエーション豊富（10種族x4色 = 40体）、属性カラー付き
- **欠点**: 64x64ピクセルアートなのでモバイル画面では粗く見える可能性

### 選択肢C: 混合（本計画の推奨）
- CasualMonstersを通常/ミニボスに使用（メインの見た目品質確保）
- Pixel Monster Packをボス/特殊敵に使用（差別化）
- `monster_stage*` ファイルはラウンド6以降のエンドレスモード雑魚に活用
