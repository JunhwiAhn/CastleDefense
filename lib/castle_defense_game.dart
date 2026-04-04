// castle_defense_game.dart — TD 리디자인 메인 파일
import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'models/character_model.dart';
import 'models/character_enums.dart';
import 'data/character_definitions.dart';
import 'systems/gacha_system.dart';

// Part 파일: 모델/enum/데이터
part 'models/game_enums.dart';
part 'models/augment.dart';
part 'models/round_config.dart';
part 'models/game_objects.dart';

// Part 파일: 렌더링
part 'ui/render_game.dart';
part 'ui/render_ui.dart';

// Part 파일: 시스템 로직
part 'systems/stage_system.dart';
part 'systems/combat_system.dart';
part 'systems/progression_system.dart';

class CastleDefenseGame extends FlameGame with TapCallbacks, DragCallbacks {

  // ─── 게임 상태 ───────────────────────────────
  GameState gameState = GameState.loading;

  // ─── 스테이지 / 웨이브 ──────────────────────
  int stageLevel = 1;
  int currentWave = 0;
  int totalWavesInStage = 10;
  int totalMonstersInWave = 0;
  int spawnedCount = 0;
  int defeatedCount = 0;
  int escapedCount = 0;
  double spawnTimer = 0.0;
  List<EnemyType> _currentSpawnList = [];
  int _spawnListIndex = 0;

  // ─── 성(Castle) ──────────────────────────────
  int castleMaxHp = 20;
  int castleHp = 20;
  double castleFlashTimer = 0.0;
  bool _perfectClearSoFar = true;

  // ─── 플레이어 영구 데이터 ─────────────────────
  int playerGem = 300;
  int playerStarShards = 0;
  RaceType playerRace = RaceType.human;
  bool raceSelected = false;
  int unlockedStageMax = 1;
  final Set<int> _clearedStages = {};

  // ─── 인게임 임시 골드 ─────────────────────────
  int playerInGameGold = 150;

  // ─── 게임 오브젝트 리스트 ──────────────────────
  final List<_Monster> monsters = [];
  final List<_Projectile> projectiles = [];
  final List<_VfxEffect> vfxEffects = [];
  final List<_DamageNumber> damageNumbers = [];

  // ─── 타워 슬롯 ───────────────────────────────
  late List<_TowerSlot> towerSlots;

  // ─── UI 상태 ──────────────────────────────────
  BottomMenu currentBottomMenu = BottomMenu.home;
  TowerType? placingTowerType;
  _Tower? selectedTower;
  double speedMultiplier = 1.0;
  int _pendingSlotId = -1;
  TowerType? _pendingTowerType;
  double characterListScrollOffset = 0.0;

  // ─── 웨이브 클리어 인터벌 ─────────────────────
  double _waveClearTimer = 0.0;
  static const double _waveClearDuration = 2.0;

  // ─── 로딩 ────────────────────────────────────
  double _loadingTimer = 0.0;
  static const double _loadingDuration = 0.5;

  // ─── 가챠 ────────────────────────────────────
  final List<OwnedCharacter> ownedCharacters = [];
  final GachaSystem gachaSystem = GachaSystem();
  List<CharacterDefinition>? gachaResults;
  int gachaResultIndex = 0;

  // ─── 스프라이트 ───────────────────────────────
  Image? goblinImage;
  Image? castleImage;    bool castleImageLoaded = false;
  bool goblinImageLoaded = false;
  Image? bossMonsterImage;
  Image? minibossMonsterImage;
  final Map<String, Image> characterImages = {};
  final Map<String, Image> stageMonsterImages = {};

  // ─── 랜덤 ────────────────────────────────────
  final Random _random = Random();

  // ─────────────────────────────────────────────
  // 라이프사이클
  // ─────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport = FixedResolutionViewport(resolution: Vector2(390, 844));

    // 타워 슬롯 초기화
    towerSlots = kTowerSlotDefs.map((d) =>
      _TowerSlot(id: d.$1, pos: Vector2(d.$2, d.$3))).toList();

    // 스프라이트 로드
    await Future.wait([
      _loadGoblinSprite(),
      _loadCastleSprite(),
      _loadBossSprites(),
      _loadCharacterSprites(),
    ]);
  }

  Future<void> _loadGoblinSprite() async {
    try { goblinImage = await images.load('goblin.png'); goblinImageLoaded = true; }
    catch (_) { goblinImageLoaded = false; }
  }

  Future<void> _loadCastleSprite() async {
    try { castleImage = await images.load('castle.png'); castleImageLoaded = true; }
    catch (_) { castleImageLoaded = false; }
  }

  Future<void> _loadBossSprites() async {
    try { bossMonsterImage = await images.load('boss_monster.png'); } catch (_) {}
    try { minibossMonsterImage = await images.load('miniboss_monster.png'); } catch (_) {}
  }

  Future<void> _loadCharacterSprites() async {
    const names = [
      'warrior','guardian','berserker','archer','gunslinger','rogue',
      'pyromancer','cryomancer','warlock','priest','druid','paladin',
      'alchemist','engineer','necromancer','summoner','main_character',
    ];
    for (final n in names) {
      try { characterImages[n] = await images.load('characters/$n.png'); } catch (_) {}
    }
  }

  // ─────────────────────────────────────────────
  // 업데이트 루프
  // ─────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    switch (gameState) {
      case GameState.loading:
        _loadingTimer += dt;
        if (_loadingTimer >= _loadingDuration) {
          _loadingTimer = 0.0;
          gameState = raceSelected ? GameState.home : GameState.raceSelect;
        }
      case GameState.raceSelect:
        break;
      case GameState.home:
        break;
      case GameState.prep:
        if (castleFlashTimer > 0) castleFlashTimer -= dt;
      case GameState.waving:
        _updateWaving(dt);
      case GameState.waveCleared:
        _updateWaveCleared(dt);
      case GameState.stageClear:
        break;
      case GameState.gameOver:
        break;
    }
  }

  void _updateWaving(double dt) {
    final eff = dt * speedMultiplier;
    if (castleFlashTimer > 0) castleFlashTimer -= dt;

    _updateSpawn(eff);
    _updateMonsters(eff);
    _updateTowers(eff);
    _updateProjectiles(eff);
    _updateVfxEffects(dt);

    // 죽은 몬스터 제거
    monsters.removeWhere((m) => !m.isAlive);

    _checkWaveClear();
  }

  // ─────────────────────────────────────────────
  // 렌더링
  // ─────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    switch (gameState) {
      case GameState.loading:
        _renderLoading(canvas);
      case GameState.raceSelect:
        _renderRaceSelect(canvas);
      case GameState.home:
        _renderHomeState(canvas);
      case GameState.prep:
        _renderGame(canvas);
        _renderHUD(canvas);
        _renderTowerBar(canvas);
        if (selectedTower != null) _renderTowerPopup(canvas);
        if (_pendingSlotId >= 0) _renderTowerPlacementPopup(canvas);
      case GameState.waving:
        _renderGame(canvas);
        _renderHUD(canvas);
        _renderTowerBar(canvas);
        if (selectedTower != null) _renderTowerPopup(canvas);
      case GameState.waveCleared:
        _renderGame(canvas);
        _renderHUD(canvas);
        _renderWaveClearedBanner(canvas);
      case GameState.stageClear:
        _renderStageClear(canvas);
      case GameState.gameOver:
        _renderGame(canvas);
        _renderGameOver(canvas);
    }
  }

  void _renderHomeState(Canvas canvas) {
    switch (currentBottomMenu) {
      case BottomMenu.home:
        _renderHome(canvas);
      case BottomMenu.gacha:
        _renderHomeBase(canvas);
        _renderGachaScreen(canvas);
        _renderBottomMenu(canvas);
      case BottomMenu.collection:
        _renderHomeBase(canvas);
        _renderCollectionScreen(canvas);
        _renderBottomMenu(canvas);
      case BottomMenu.settings:
        _renderHomeBase(canvas);
        _renderSettingsPlaceholder(canvas);
        _renderBottomMenu(canvas);
    }
  }

  void _renderHomeBase(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF0D1B0D));
  }

  void _renderSettingsPlaceholder(Canvas canvas) {
    _drawCenteredText(canvas, '설정',
        Offset(size.x / 2, size.y / 2),
        fontSize: 20, color: const Color(0xFFAAAAAA));
  }

  void _renderLoading(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF0D1B0D));
    final progress = (_loadingTimer / _loadingDuration).clamp(0.0, 1.0);
    const barW = 200.0;
    final barX = (size.x - barW) / 2;
    final barY = size.y / 2 - 10;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, 8), const Radius.circular(4)),
      Paint()..color = const Color(0xFF224422));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * progress, 8), const Radius.circular(4)),
      Paint()..color = const Color(0xFF44FF44));
    _drawCenteredText(canvas, 'Castle Defense',
        Offset(size.x / 2, size.y / 2 - 40),
        fontSize: 24, color: const Color(0xFFFFD700),
        fontWeight: FontWeight.bold);
  }

  // ─────────────────────────────────────────────
  // 입력 처리
  // ─────────────────────────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.localPosition;
    switch (gameState) {
      case GameState.raceSelect:
        _handleRaceSelectTap(pos);
      case GameState.home:
        _handleHomeTap(pos);
      case GameState.prep:
        _handlePrepTap(pos);
      case GameState.waving:
        _handleWavingTap(pos);
      case GameState.gameOver:
        _handleGameOverTap(pos);
      case GameState.stageClear:
        _handleStageClearTap(pos);
      default:
        break;
    }
    super.onTapDown(event);
  }

  // ─── 종족 선택 탭 ────────────────────────────
  void _handleRaceSelectTap(Vector2 pos) {
    const races = RaceType.values;
    const double cardH = 90.0, cardW = 340.0, gap = 10.0;
    const double startY = 150.0;
    final startX = (size.x - cardW) / 2;

    for (int i = 0; i < races.length; i++) {
      final rect = Rect.fromLTWH(startX, startY + i * (cardH + gap), cardW, cardH);
      if (rect.contains(Offset(pos.x, pos.y))) {
        _selectRace(races[i]);
        return;
      }
    }
  }

  // ─── 홈화면 탭 ───────────────────────────────
  void _handleHomeTap(Vector2 pos) {
    final offset = Offset(pos.x, pos.y);

    // 하단 메뉴
    for (int i = 0; i < 4; i++) {
      if (_bottomMenuButtonRect(i).contains(offset)) {
        final menus = [BottomMenu.home, BottomMenu.collection,
                       BottomMenu.gacha, BottomMenu.settings];
        currentBottomMenu = menus[i];
        characterListScrollOffset = 0.0;
        return;
      }
    }

    // 가챠 버튼
    if (currentBottomMenu == BottomMenu.gacha) {
      _handleGachaTap(offset);
      return;
    }

    // 컬렉션 카드 업그레이드 버튼
    if (currentBottomMenu == BottomMenu.collection) {
      _handleCollectionTap(offset);
      return;
    }

    // 스테이지 버튼
    if (currentBottomMenu == BottomMenu.home) {
      for (int i = 1; i <= kStageConfigs.length; i++) {
        if (_stageButtonRect(i).contains(offset) && i <= unlockedStageMax) {
          _startStagePrep(i);
          return;
        }
      }
    }
  }

  void _startStagePrep(int stage) {
    _loadStage(stage);
    // 타워 슬롯 초기화 (기존 타워 제거)
    for (final slot in towerSlots) slot.tower = null;
    selectedTower = null;
    placingTowerType = null;
    gameState = GameState.prep;
  }

  // ─── 준비 단계 탭 ────────────────────────────
  void _handlePrepTap(Vector2 pos) {
    final offset = Offset(pos.x, pos.y);

    // 타워 팝업 버튼
    if (selectedTower != null) {
      if (_handleTowerPopupTap(pos)) return;
    }

    // 배치 팝업 버튼
    if (_pendingSlotId >= 0) {
      if (_handlePlacementPopupTap(pos)) return;
      return; // 팝업 외 클릭 시 팝업만 닫기
    }

    // 웨이브 시작 버튼
    if (_waveStartButtonRect().contains(offset)) {
      _startWave();
      return;
    }

    // 타워 바 버튼
    const types = TowerType.values;
    final btnW = (size.x - 10) / types.length;
    final barY = size.y - 100.0;
    for (int i = 0; i < types.length; i++) {
      final btnRect = Rect.fromLTWH(5 + i * btnW, barY + 5, btnW - 5, 90);
      if (btnRect.contains(offset)) {
        placingTowerType = placingTowerType == types[i] ? null : types[i];
        selectedTower = null;
        return;
      }
    }

    // 이미 배치된 타워 탭
    for (final slot in towerSlots) {
      if (slot.tower == null) continue;
      final dx = pos.x - slot.tower!.pos.x;
      final dy = pos.y - slot.tower!.pos.y;
      if (sqrt(dx * dx + dy * dy) < 24) {
        selectedTower = selectedTower == slot.tower ? null : slot.tower;
        placingTowerType = null;
        return;
      }
    }

    // 빈 슬롯 탭 (배치 모드일 때)
    if (placingTowerType != null) {
      for (final slot in towerSlots) {
        if (!slot.isEmpty) continue;
        final dx = pos.x - slot.pos.x;
        final dy = pos.y - slot.pos.y;
        if (sqrt(dx * dx + dy * dy) < 22) {
          _pendingSlotId = slot.id;
          _pendingTowerType = placingTowerType;
          return;
        }
      }
    }

    // 그 외 탭 → 선택 해제
    selectedTower = null;
    placingTowerType = null;
  }

  // ─── 웨이빙 탭 ───────────────────────────────
  void _handleWavingTap(Vector2 pos) {
    final offset = Offset(pos.x, pos.y);

    // 2배속 토글 (우상단)
    final speedRect = Rect.fromLTWH(size.x - 44, 5, 40, 28);
    if (speedRect.contains(offset)) {
      speedMultiplier = speedMultiplier > 1.0 ? 1.0 : 2.0;
      return;
    }

    // 타워 팝업
    if (selectedTower != null) {
      if (_handleTowerPopupTap(pos)) return;
    }

    // 배치된 타워 탭
    for (final slot in towerSlots) {
      if (slot.tower == null) continue;
      final dx = pos.x - slot.tower!.pos.x;
      final dy = pos.y - slot.tower!.pos.y;
      if (sqrt(dx * dx + dy * dy) < 24) {
        selectedTower = selectedTower == slot.tower ? null : slot.tower;
        return;
      }
    }

    selectedTower = null;
  }

  // ─── 타워 팝업 버튼 탭 ───────────────────────
  bool _handleTowerPopupTap(Vector2 pos) {
    final tower = selectedTower;
    if (tower == null) return false;
    final offset = Offset(pos.x, pos.y);

    const double popW = 200.0, popH = 160.0;
    final popX = (tower.pos.x + 30).clamp(0.0, size.x - popW);
    final popY = (tower.pos.y - popH - 10).clamp(50.0, size.y - popH - 110);

    // 업그레이드 버튼
    if (tower.level < 3) {
      final upgRect = Rect.fromLTWH(popX + 10, popY + 58, popW - 20, 32);
      if (upgRect.contains(offset)) {
        upgradeTower(tower);
        return true;
      }
    }

    // 타겟 우선순위 토글
    final priorityRect = Rect.fromLTWH(popX + 10, popY + 95, popW - 20, 24);
    if (priorityRect.contains(offset)) {
      final priorities = TargetPriority.values;
      final idx = priorities.indexOf(tower.targetPriority);
      tower.targetPriority = priorities[(idx + 1) % priorities.length];
      return true;
    }

    // 철거 버튼
    final sellRect = Rect.fromLTWH(popX + 10, popY + 122, popW - 20, 28);
    if (sellRect.contains(offset)) {
      sellTower(tower.slotId);
      selectedTower = null;
      return true;
    }

    // 팝업 바깥 탭 → 닫기
    final popRect = Rect.fromLTWH(popX, popY, popW, popH);
    if (!popRect.contains(offset)) {
      selectedTower = null;
      return true;
    }
    return false;
  }

  // ─── 배치 팝업 탭 ────────────────────────────
  bool _handlePlacementPopupTap(Vector2 pos) {
    if (_pendingSlotId < 0 || _pendingTowerType == null) return false;
    final offset = Offset(pos.x, pos.y);

    const double popW = 320.0, popH = 260.0;
    final popX = (size.x - popW) / 2;
    final popY = (size.y - popH) / 2 - 50;

    // 취소 버튼
    final cancelRect = Rect.fromLTWH(popX + popW / 2 - 50, popY + popH - 40, 100, 30);
    if (cancelRect.contains(offset)) {
      _pendingSlotId = -1;
      _pendingTowerType = null;
      return true;
    }

    // 기본 타워 (캐릭터 없음) 선택
    final defaultRect = Rect.fromLTWH(popX + 10, popY + 65, popW - 20, 32);
    if (defaultRect.contains(offset)) {
      placeTower(_pendingSlotId, _pendingTowerType!, null);
      _pendingSlotId = -1;
      _pendingTowerType = null;
      placingTowerType = null;
      return true;
    }

    // 캐릭터 선택
    final chars = getCharactersForTowerType(_pendingTowerType!);
    for (int i = 0; i < chars.length && i < 4; i++) {
      final r = Rect.fromLTWH(popX + 10, popY + 105 + i * 36.0, popW - 20, 30);
      if (r.contains(offset)) {
        placeTower(_pendingSlotId, _pendingTowerType!, chars[i].characterId);
        _pendingSlotId = -1;
        _pendingTowerType = null;
        placingTowerType = null;
        return true;
      }
    }

    // 팝업 바깥 → 취소
    final popRect = Rect.fromLTWH(popX, popY, popW, popH);
    if (!popRect.contains(offset)) {
      _pendingSlotId = -1;
      _pendingTowerType = null;
    }
    return true;
  }

  // ─── 결과 화면 탭 ────────────────────────────
  void _handleGameOverTap(Vector2 pos) {
    final offset = Offset(pos.x, pos.y);
    if (_retryButtonRect().contains(offset)) {
      _startStagePrep(stageLevel);
    } else if (_homeButtonRect().contains(offset)) {
      gameState = GameState.home;
    }
  }

  void _handleStageClearTap(Vector2 pos) {
    if (_homeButtonRect().contains(Offset(pos.x, pos.y))) {
      gameState = GameState.home;
    }
  }

  // ─── 가챠 탭 ─────────────────────────────────
  void _handleGachaTap(Offset offset) {
    if (gachaResults != null) {
      gachaResultIndex++;
      if (gachaResultIndex >= gachaResults!.length) {
        for (final def in gachaResults!) _processGachaResult(def);
        gachaResults = null;
        gachaResultIndex = 0;
      }
      return;
    }
    if (_gachaSingleButtonRect().contains(offset)) {
      final cost = gachaSystem.getSingleSummonCost();
      if (playerGem >= cost) {
        playerGem -= cost;
        gachaResults = [gachaSystem.summonOne()];
        gachaResultIndex = 0;
      }
      return;
    }
    if (_gachaTenButtonRect().contains(offset)) {
      final cost = gachaSystem.getTenSummonCost();
      if (playerGem >= cost) {
        playerGem -= cost;
        gachaResults = gachaSystem.summonTen();
        gachaResultIndex = 0;
      }
      return;
    }
  }

  // ─── 컬렉션 탭 ───────────────────────────────
  void _handleCollectionTap(Offset offset) {
    const double cardW = 340.0, cardH = 70.0, gap = 8.0;
    final startX = (size.x - cardW) / 2;
    const double startY = 175.0;

    final seen = <String>{};
    final unique = <OwnedCharacter>[];
    for (final c in ownedCharacters) {
      if (seen.add(c.characterId)) unique.add(c);
    }

    for (int i = 0; i < unique.length; i++) {
      final c = unique[i];
      final y = startY + i * (cardH + gap) - characterListScrollOffset;
      if (c.cardLevel >= 5) continue;

      final upgRect = Rect.fromLTWH(startX + cardW - 100, y + 15, 90, 40);
      if (upgRect.contains(offset)) {
        upgradeCard(c.characterId);
        return;
      }
    }
  }

  // ─── 드래그 (컬렉션/가챠 스크롤) ──────────────
  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (gameState == GameState.home &&
        (currentBottomMenu == BottomMenu.gacha ||
         currentBottomMenu == BottomMenu.collection)) {
      characterListScrollOffset =
          (characterListScrollOffset - event.localDelta.y)
              .clamp(0.0, 2000.0);
    }
    super.onDragUpdate(event);
  }

}
