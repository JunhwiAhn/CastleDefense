# 技術・品質改善提案

> 作成日: 2026-03-11
> 担当: Planner
> 対象: lib/castle_defense_game.dart (8080行) + lib/models/ + lib/data/ + lib/systems/
> 前提: P-3-2(バランスレビュー), P-3-3(UXフロー評価), P-3-4(バフカード体感テスト)で既出の指摘は除外

---

## 1. 概要（全体的な技術負債レベル評価）

**技術負債レベル: 中〜高**

castle_defense_game.dart が8080行の単一ファイルに全ゲームロジック・レンダリング・入力処理・状態管理を内包している。プロトタイプ段階では許容範囲だが、今後の機能追加・バグ修正・チーム分業において深刻なボトルネックになる。

**良い点:**
- オブジェクトプール（_MonsterPool）による GC 圧力軽減が実装済み
- 当たり判定の dist^2 最適化が適用済み
- FixedResolutionViewport による画面スケーリングが正しく実装
- GameState enum による状態遷移が明確に構造化されている

**問題点:**
- Flame エンジンの Component アーキテクチャをほぼ使用していない（FlameGame を巨大な手続き型ゲームループとして使用）
- 毎フレーム Paint/TextPainter オブジェクトを大量生成（約190箇所の Paint(), 約147箇所の _drawCenteredText）
- dispose/リソース解放が一切実装されていない
- テスト可能な単位に分離されたロジックがない

---

## 2. コード構造・分割提案

### 2.1 現状の問題

castle_defense_game.dart に以下の責務が混在している:

| 責務カテゴリ | 推定行数 | 内容 |
|-------------|---------|------|
| 状態変数宣言 | ~250行 (L478-L720) | 100以上のインスタンス変数 |
| ゲームロジック | ~1200行 (L906-L2100) | update, モンスターAI, 戦闘, XP/ゴールド |
| 属性・増強システム | ~400行 (L2186-L2617) | 属性相性計算, 増強選択/適用 |
| 入力処理 | ~500行 (L2662-L3200) | タップ/ドラッグ全状態 |
| UI計算 (Rect) | ~350行 (L3394-L3585) | ボタン位置計算 |
| レンダリング | ~4500行 (L3588-L8079) | 全描画メソッド55個 |

### 2.2 提案するファイル構成

```
lib/
  castle_defense_game.dart        ← 縮小: FlameGame本体 (~500行)
  components/
    castle_component.dart         ← 城の描画+HP管理
    monster_component.dart        ← モンスター描画+AI+プール
    character_unit_component.dart ← キャラクターユニット+攻撃ロジック
    projectile_component.dart     ← 投射物+当たり判定
    hud_component.dart            ← HUD描画
    vfx_component.dart            ← VFXエフェクト
  systems/
    combat_system.dart            ← ダメージ計算, 属性相性
    augment_system.dart           ← 増強選択/適用ロジック (既存 gacha_system.dart と並列)
    buff_system.dart              ← バフカード管理
    round_system.dart             ← ラウンド進行/スポーン管理
    economy_system.dart           ← ゴールド/XP/レベルアップ
  ui/
    level_up_overlay.dart         ← レベルアップUI
    shop_overlay.dart             ← ショップUI
    augment_select_overlay.dart   ← 増強選択UI
    round_select_screen.dart      ← ラウンド選択画面
    result_overlay.dart           ← 結果/ゲームオーバー画面
  data/
    character_definitions.dart    ← (既存)
    round_config.dart             ← RoundConfig/StageConfig クラス + テーブル
    augment_definitions.dart      ← kAllAugments 定義 (現在L60-L98)
  models/
    character_model.dart          ← (既存)
    character_enums.dart          ← (既存)
    game_state.dart               ← GameState enum + ShopItemType + MonsterType
```

### 2.3 分割優先度

1. **最優先**: データクラスの分離（RoundConfig, Augment定義, GameState enum）→ 依存なし、即時実行可能
2. **高**: システムロジックの分離（combat_system, augment_system, buff_system）→ テスト可能性が大幅向上
3. **中**: Componentベース化（monster_component, projectile_component）→ Flame活用
4. **低**: UI/レンダリングの分離 → 描画コードが最大だが、分離の恩恵は保守性のみ

---

## 3. パフォーマンス改善

### 3.1 Paint/TextPainter の毎フレーム生成

**問題**: `_drawCenteredText` が毎フレーム約50〜100回呼ばれ、各呼び出しで `TextPainter` と `TextSpan` を新規生成 → `layout()` を実行している。TextPainter の layout は Dart のテキスト整形パイプラインを通るため、フレームごとの GC 圧力とCPU負荷が高い。

```dart
// 現在: 毎フレーム新規生成 (L7236-L7259)
void _drawCenteredText(...) {
  final tp = TextPainter(...)..layout(); // 毎フレーム生成+レイアウト
  tp.paint(canvas, offset);
  // dispose なし → リーク
}
```

**改善案A (低コスト)**: 静的テキスト（"LEVEL UP!", "SKILL", 固定ラベル等）のTextPainterをフィールドにキャッシュし、`onLoad` 時に一度だけ layout する。

**改善案B (中コスト)**: `_drawCenteredText` に LRU キャッシュを導入。テキスト+fontSize+color のハッシュをキーとして TextPainter をキャッシュし、5フレーム以上使用されなかったエントリを dispose。

**改善案C (高コスト)**: Flame の `TextComponent` を使用する。Component 化と同時に対応。

**影響度**: 中〜高。モンスター40体表示時の HUD + ダメージ数字 + XP/ゴールド表示で TextPainter 生成が数十回/フレーム。低スペック端末でフレーム落ちの原因になりうる。

### 3.2 Paint オブジェクトの毎フレーム生成

**問題**: レンダリングメソッド全体で約190箇所の `Paint()` が毎フレーム new される。Paint は軽量オブジェクトだが、大量生成はGCトリガーとなる。

**改善案**: 色やスタイルが固定の Paint は `static final` または `late final` フィールドに昇格。
```dart
// 改善例
static final _bgPaint = Paint()..color = const Color(0xFF1A0A2E);
static final _borderPaint = Paint()
  ..color = const Color(0xFF9B59F5)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2.0;
```

推定で140/190箇所がフィールド化可能（色が固定の Paint）。残り50箇所は動的な色（alpha アニメーション等）のため、パラメータのみ変更する方式に書き換える。

### 3.3 monsters.contains() の O(n) 検索

**問題**: `_updateProjectiles` (L2307) と `_updateCharacterUnits` (L1679) で `monsters.contains(proj.targetMonster)` が呼ばれている。List.contains は O(n) であり、モンスター40体 x 投射物50個のフレームで2000回の線形検索が発生。

**改善案**: モンスターに `bool isAlive` フラグを持たせ、`contains` の代わりに `target.isAlive` で判定する。撃破時に `isAlive = false` にセット。

### 3.4 _findNearestMonster / _findMonsterNearestToCastle の重複呼び出し

**問題**: `_updateCharacterUnits` でキャラクターごとに `_findNearestMonster` または `_findMonsterNearestToCastle` が呼ばれる。5ユニット x 40モンスター = 200回の距離計算/フレーム。

**改善案**: 「城に最も近いモンスター」はフレーム開始時に1回計算してキャッシュ。タワー4基が同じ結果を共有できる。

### 3.5 VFX/ダメージ数字のリスト removeWhere

**問題**: `_damageNumbers.removeWhere` (L1004), `vfxEffects.removeAt` (L2388) が逆順ループ中に実行。removeAt は O(n) のため、大量VFXで遅延の原因。

**改善案**: 「swap and pop」パターンを使用。リスト末尾と入れ替えて removeLast で O(1)。描画順序が不要な VFX/ダメージ数字に適用可能。

---

## 4. メモリ・リソース管理

### 4.1 TextPainter の dispose 漏れ

**問題**: `_drawCenteredText` (L7244) と `_drawText` で生成される TextPainter は一度も `dispose()` されない。TextPainter は内部でネイティブリソース（Paragraph）を保持しており、dispose しないとネイティブメモリリークが発生する。

**規模**: 毎フレーム約100個の TextPainter が dispose なしで放棄。1分間（60fps）で約360,000個のリーク。GCが回収するまでネイティブメモリが増加し続ける。

**修正案**: キャッシュ化（3.1参照）と合わせて、キャッシュから除外するときに `tp.dispose()` を呼ぶ。キャッシュ不採用なら `_drawCenteredText` 内で `tp.paint()` 後に `tp.dispose()` を追加。

### 4.2 Image リソースの解放

**問題**: `goblinImage`, `castleImage`, `xpGemImage`, `goldCoinImage`, `bossMonsterImage`, `minibossMonsterImage` の6つの Image が `onLoad` でロードされるが、ゲーム終了時の解放がない。`CastleDefenseGame` に `onRemove` や `onDispose` のオーバーライドがなく、Navigator で画面遷移しても Image が解放されない。

**修正案**: `onRemove()` をオーバーライドし、`images.clearCache()` を呼ぶ。または個別に `image?.dispose()` を実行。

### 4.3 GameScreen の CastleDefenseGame 再生成

**問題**: `main.dart` の `GameScreen` (L90-L107) で毎回 `CastleDefenseGame()` を new しているが、Navigator.pop で戻って再度 GameScreen に入ると、前回の CastleDefenseGame インスタンスが GC されるまで残る（Image リソース含む）。

**修正案**: GameScreen を StatefulWidget にし、dispose 時に game.onRemove() を明示的に呼ぶ。または game インスタンスを State に保持し、再利用する。

### 4.4 _monsterPool の無制限膨張

**問題**: `_monsterPool` (L705) にはサイズ上限がない。R15以降で65体以上のモンスターがプールに蓄積され、メモリを占有し続ける。各 _Monster は約20フィールドを持つため、100体で数KB。

**修正案**: プール上限を設定（例: 60体）。超過分は GC に委ねる。
```dart
void _releaseMonster(_Monster m) {
  m.aggroTarget = null;
  if (_monsterPool.length < 60) _monsterPool.add(m);
}
```

### 4.5 GoldDrop の消滅タイマーなし

**問題**: `_GoldDrop` (L406-L411) には `lifeTimer` がない。XpGem は30秒で消滅するが、GoldDrop は永続。長期戦で画面外に散乱した GoldDrop がリストに蓄積し続ける。

**修正案**: `_GoldDrop` に `lifeTimer` を追加（XpGem と同じ30秒 + R-09 増強対応）。`_updateGoldDrops` で消滅処理を実装。

---

## 5. 状態管理・堅牢性

### 5.1 GameState 遷移の競合

**問題**: `_updatePlaying` (L973-L1056) 内で、1フレーム中に複数の状態遷移トリガーが同時に発火しうる:

1. L1046: `castleHp <= 0` → `_onGameOver()` (GameState.result)
2. L1053: `defeatedMonsters + escapedMonsters >= totalMonstersInRound` → `_onRoundClear()` (GameState.roundClear)
3. L983: `roundTimer >= roundTimeLimit` → `_onTimeOver()` (GameState.result)

城HPが0かつモンスター全滅が同フレームで発生した場合、ゲームオーバーとラウンドクリアが競合する。現在は `_onGameOver` が先に実行され return されるが、条件順序に依存した暗黙の優先度は脆い。

**修正案**: 明示的な優先度チェックを導入:
```dart
if (roundTimer >= roundTimeLimit) { _onTimeOver(); return; }
if (castleHp <= 0) { _onGameOver(); return; }
if (allMonstersCleared) { _onRoundClear(); }
```

### 5.2 _attractAllXpGems での XP 二重加算リスク

**問題**: `_attractAllXpGems` (L1944-L1955) はレベルアップ直後に全 XP ジェムを即時収集する。この中で `playerXp += gem.xpValue` を加算しているが、`_checkLevelUp()` を呼んでいない。一方、通常の `_updateXpGems` (L1907) では `_checkLevelUp()` を呼ぶ。

`_attractAllXpGems` が大量のXPを一括加算した場合、次の `_updateXpGems` 呼び出し時にレベルアップ判定が発生するが、「1レベル分しかチェックされない」ため複数レベル分のXPがあっても1レベルしか上がらない。

**修正案**: `_checkLevelUp` を while ループにするか、`_attractAllXpGems` 内でも `_checkLevelUp` を呼ぶ。

### 5.3 _applyAugment での変数流用による副作用

**問題** (P-3-2, P-3-4 で部分的に指摘済みだが、技術的な根本原因は未指摘):

`_applyAugment` (L2525-L2586) で増強効果をバフカードと同じ変数（`_atkUpCount`, `_moveUpCount`, `_rangeUpCount`, `_towerUpCount`）に加算している。これにより:

1. バフカード上限チェック（`_atkUpCount < 5`）が増強で消費されたカウントで汚染される
2. `_generateBuffOptions` で「上限到達済みバフを除外」するロジックが、増強スタック分も含めて判定してしまう
3. C-07（XP磁石+30px）は `_magnetCount += 2` で対応しているが、バフカード「XP磁石拡大」の上限3回中2回分を消費してしまう

**根本修正案**: 増強専用の乗算フィールドを別途設ける:
```dart
double _augmentAtkMultiplier = 1.0;     // 増強由来の攻撃倍率
double _augmentMoveMultiplier = 1.0;    // 増強由来の移動速度倍率
int _augmentExtraMagnetRadius = 0;      // 増強由来の追加磁石半径(px)
```

### 5.4 castleHp が castleMaxHp を超える可能性

**問題**: `_loadStage` (L825) で `castleHp = castleMaxHp` を設定するが、その後 `_applyAugment('C-05')` (L2545-L2546) で `_shopCastleMaxHpCount` を操作して castleMaxHp を変更した上で `castleHp += 25` を実行する。castleMaxHp の変更タイミングと castleHp の加算タイミングが非同期のため、`castleHp > castleMaxHp` になるケースがある。

**修正案**: castleHp のセッターで常に `min(castleMaxHp, value)` をクランプするか、`castleHp` をプロパティにしてクランプをゲッターに組み込む。

### 5.5 characterUnits.where((u) => !u.isTower).firstOrNull の頻出

**問題**: メインキャラクターユニットの取得が以下の箇所で同一パターンで繰り返されている:
- L1831, L1883, L1892, L1924, L1946, L7954 (計6箇所以上)

`characterUnits` リストを毎回線形検索している。

**修正案**: `_CharacterUnit? _mainUnit` フィールドを設け、パーティ設定変更時にキャッシュする。

---

## 6. Flameエンジン活用

### 6.1 現状のFlame使用度

Flame の使用は最小限:
- `FlameGame` の `onLoad`, `update`, `render` のみ使用
- `FixedResolutionViewport` による画面スケーリング
- `images.load` によるアセットロード
- `TapCallbacks`, `DragCallbacks` ミックスイン

使用していない主要機能:
- **Component ツリー**: 全描画がオーバーライド `render()` 内の手続き型コード
- **SpawnComponent**: モンスタースポーンが手動タイマー管理
- **TimerComponent**: バリア/増強タイマーが手動 `dt` 減算
- **HasCollisionDetection / Hitbox**: 当たり判定が手動 O(n^2)
- **SpriteBatchComponent**: 大量同一スプライトの一括描画
- **ParallaxComponent**: 背景スクロール（将来拡張時に有用）
- **TextComponent**: テキスト描画のキャッシュ付きComponent

### 6.2 Component化の提案

**Phase 1: SpriteBatch でモンスター描画最適化**

モンスター40体が同一スプライト（goblin.png）を使用しているため、`SpriteBatch` で1回の draw call にまとめられる。現在は各モンスターごとに `canvas.drawImageRect` を呼んでいる。

**Phase 2: PositionComponent ベースのエンティティ**

```dart
class MonsterComponent extends PositionComponent with HasGameRef<CastleDefenseGame> {
  MonsterType type;
  int hp;
  // ...
  @override
  void update(double dt) { /* AI, 移動 */ }
  @override
  void render(Canvas canvas) { /* スプライト描画 */ }
}
```

メリット:
- Flame の `children` リスト管理で add/remove が効率的
- `HasCollisionDetection` との統合で O(n log n) の当たり判定（Quad-tree）
- Component 単位でのテストが可能

**Phase 3: Collision Detection の活用**

現在の O(n^2) 総当り判定（characterUnits x monsters, projectiles x monsters）を、Flame の `CollisionCallbacks` + `ShapeHitbox` で置き換える。Flame は内部でブロードフェーズ最適化を行うため、40体+50投射物のケースで大幅な性能向上が期待できる。

### 6.3 移行のリスク

- 8080行の手続き型コードを Component 化するには大規模なリファクタリングが必要
- 既存の動作を壊すリスクが高いため、テストカバレッジ確保が先行すべき
- Component 化は段階的に進め、1システムずつ移行するのが安全

---

## 7. テスト戦略

### 7.1 現状

テストファイルなし。ユニットテスト、ウィジェットテスト、統合テストのいずれも存在しない。

### 7.2 優先テスト対象（労力/リスク順）

**最優先: ロジックのユニットテスト**

以下のロジックは CastleDefenseGame から分離すればピュア Dart でテスト可能:

| テスト対象 | 理由 | 推定工数 |
|-----------|------|---------|
| `getElementMultiplier()` | 属性相性表の正しさ。仕様との乖離がバグ直結 | 小 |
| `_buildRoundConfig()` | 全20ラウンドの設定値が仕様テーブルと一致するか | 小 |
| `_generateBuffOptions()` | 上限チェック、除外ロジック、重み付き抽選 | 中 |
| `_generateAugmentChoices()` | ティア確率、重複排除、フォールバック | 中 |
| `_applyBuff()` / `_applyAugment()` | 各バフ/増強の効果適用が仕様通りか | 中 |
| `_xpToNextLevel()` | XP必要量の計算式 | 小 |
| `_buyShopItem()` | ゴールド/上限チェック、HP反映 | 小 |
| ダメージ計算全体 | 属性倍率、増強効果、バフ乗算の統合 | 大 |

**中優先: 状態遷移テスト**

GameState の遷移パスを検証:
- playing → roundClear → augmentSelect → playing
- playing → levelUp → playing
- playing → result (gameOver / timeOver)
- shopOpen → result

**低優先: レンダリング / UIテスト**

Golden test（スナップショットテスト）で主要画面の見た目を固定。

### 7.3 テスト導入のための前提作業

1. ロジッククラスの分離（2.2節の systems/ ディレクトリ）
2. `CastleDefenseGame` からロジックメソッドを static/外部クラスに移動
3. テスト用の `test/` ディレクトリ作成と pubspec.yaml へのテスト依存追加

---

## 8. 優先実装リスト

### Tier 1: 即時対応（バグ/リーク修正、労力: 小、リスク: 低）

| # | 項目 | 概要 | 工数 |
|---|------|------|------|
| T1-1 | TextPainter.dispose 追加 | `_drawCenteredText` / `_drawText` 内で paint 後に dispose() | 0.5h |
| T1-2 | GoldDrop に lifeTimer 追加 | XpGem と同様の消滅タイマー | 1h |
| T1-3 | _monsterPool にサイズ上限追加 | `_releaseMonster` で60体超過分を破棄 | 0.5h |
| T1-4 | _checkLevelUp の while ループ化 | 大量XP一括加算時の複数レベルアップ対応 | 0.5h |
| T1-5 | castleHp のクランプ保証 | HP設定箇所で常に `min(castleMaxHp, value)` | 1h |
| T1-6 | mainUnit のキャッシュ化 | `.where(!isTower).firstOrNull` の6箇所を1フィールド化 | 1h |

### Tier 2: 短期改善（パフォーマンス、労力: 中、リスク: 低）

| # | 項目 | 概要 | 工数 |
|---|------|------|------|
| T2-1 | 固定 Paint のフィールド化 | 色固定の約140箇所を static final に | 4h |
| T2-2 | TextPainter キャッシュ導入 | 静的テキストのキャッシュ（LRU 50エントリ） | 4h |
| T2-3 | Monster.isAlive フラグ | `monsters.contains()` を O(1) に | 2h |
| T2-4 | findMonsterNearestToCastle キャッシュ | フレーム開始時1回計算 | 1h |
| T2-5 | onRemove で Image 解放 | 画面遷移時のメモリ解放 | 1h |

### Tier 3: 中期リファクタリング（構造改善、労力: 大、リスク: 中）

| # | 項目 | 概要 | 工数 |
|---|------|------|------|
| T3-1 | データクラス分離 | RoundConfig, Augment, GameState enum を別ファイルに | 4h |
| T3-2 | システムロジック分離 | combat_system, buff_system, augment_system | 16h |
| T3-3 | 増強専用倍率フィールド | バフカード変数からの分離（5.3節） | 4h |
| T3-4 | ユニットテスト基盤 | テスト環境構築 + 優先テスト20件 | 16h |

### Tier 4: 長期改善（Flame活用、労力: 特大、リスク: 高）

| # | 項目 | 概要 | 工数 |
|---|------|------|------|
| T4-1 | Component 化（段階1: モンスター） | MonsterComponent + SpriteBatch | 24h |
| T4-2 | Component 化（段階2: 投射物） | ProjectileComponent + Hitbox | 16h |
| T4-3 | Flame CollisionDetection 導入 | ShapeHitbox + CollisionCallbacks | 16h |
| T4-4 | TextComponent 移行 | 全テキスト描画を TextComponent に | 16h |

---

## 補足: SDK互換性

### 確認済みの deprecated API 使用

- `withValues(alpha:)` (L7971, L7982): Flutter 3.27+ で `withAlpha` の代替として導入された新API。現時点では問題なし。
- `FixedResolutionViewport` (L729): Flame 1.x 系で有効。Flame 2.x への移行時に `CameraComponent` + `FixedResolutionViewport` のAPIが変更される可能性あるが、現時点では問題なし。
- `TextPainter` のマルチライン制御: `maxLines: null` と `maxLines: 3` が混在（L7254）。挙動は正しいが、`maxLines: null` は実質無制限のため、意図しない長文でレイアウトが崩れる可能性あり。

### アセット読み込み戦略の改善余地

現在の `images.load` は Flame の内蔵キャッシュを使用しており、重複ロードは防止されている。ただし、今後アセット数が増えた場合:
- `Flame.images.loadAll()` で一括ロード
- ステージごとの遅延ロード（現在は全アセットを起動時にロード）
- アセットマニフェストによるプリロード制御

を検討すべき。現在は5画像のみのため問題なし。
