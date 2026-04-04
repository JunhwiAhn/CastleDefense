// 스테이지/웨이브 로딩 및 전환 (TD 방식)
part of '../castle_defense_game.dart';

extension StageSystem on CastleDefenseGame {

  // ─── 스테이지 초기화 ───────────────────────────
  void _loadStage(int level) {
    stageLevel = level;
    currentWave = 0;
    totalWavesInStage = kStageConfigs[level]?.waves.length ?? 10;

    castleHp = castleMaxHp;
    castleFlashTimer = 0.0;
    _perfectClearSoFar = true; // 무피해 클리어 추적 초기화

    monsters.clear();
    projectiles.clear();
    vfxEffects.clear();
    damageNumbers.clear();

    // 스테이지 배경 로드
    _loadStageBgImage(level);

    // 타워는 유지 (준비 단계에서 배치한 것 보존)
    // 인게임 골드 리셋
    playerInGameGold = 150 + (level - 1) * 50;
  }

  // ─── 웨이브 로딩 ──────────────────────────────
  void _loadWave(int waveNumber) {
    final cfg = kStageConfigs[stageLevel];
    if (cfg == null || waveNumber < 1 || waveNumber > cfg.waves.length) return;

    final waveCfg = cfg.waves[waveNumber - 1];
    currentWave = waveNumber;
    totalMonstersInWave = waveCfg.totalMonsters;
    spawnedCount = 0;
    defeatedCount = 0;
    escapedCount = 0;
    spawnTimer = 0.0;
    _currentSpawnList = _expandSpawnList(waveCfg.spawnList);
    _spawnListIndex = 0;

    // 웨이브 시작 골드 보너스
    playerInGameGold += waveCfg.waveGoldBonus;

    monsters.clear();
    projectiles.clear();
    damageNumbers.clear();
  }

  // spawnList → 개별 EnemyType 목록으로 확장 (섞지 않고 순서 유지)
  List<EnemyType> _expandSpawnList(List<_SpawnEntry> entries) {
    final result = <EnemyType>[];
    for (final e in entries) {
      for (int i = 0; i < e.count; i++) result.add(e.type);
    }
    return result;
  }

  // ─── 웨이브 시작 (prep → 카운트다운 → waving) ───
  void _startWave() {
    if (gameState != GameState.prep) return;
    // 카운트다운 시작 (3, 2, 1, GO!)
    _waveCountdownActive = true;
    _waveCountdownTimer = 3.0;
    _loadWave(currentWave + 1);
    gameState = GameState.waving;
  }

  // ─── 다음 웨이브로 진행 ────────────────────────
  void _startNextWave() {
    if (currentWave < totalWavesInStage) {
      gameState = GameState.prep;
      // 웨이브 클리어 후 이자 지급 (보유 골드의 3%, 최대 +15g)
      final interest = (playerInGameGold * 0.03).floor().clamp(0, 15);
      playerInGameGold += interest;
    } else {
      _onStageClear();
    }
  }

  // ─── 웨이브 클리어 ────────────────────────────
  void _onWaveClear() {
    if (gameState != GameState.waving) return;

    // 별조각 보상
    final cfg = kStageConfigs[stageLevel];
    if (cfg != null && currentWave <= cfg.waves.length) {
      final waveCfg = cfg.waves[currentWave - 1];
      playerStarShards += waveCfg.starShardReward;
    }

    gameState = GameState.waveCleared;
    _waveClearTimer = 0.0;
  }

  // ─── 스테이지 클리어 ──────────────────────────
  void _onStageClear() {
    final cfg = kStageConfigs[stageLevel];
    if (cfg == null) return;

    // 별조각 + 젬 지급
    playerStarShards += cfg.starShardOnStageClear;
    playerGem += cfg.gemOnStageClear;

    // 무피해 클리어 보너스
    if (_perfectClearSoFar) {
      playerStarShards += 5;
      playerGem += 3;
    }

    // 첫 클리어 보너스
    if (!_clearedStages.contains(stageLevel)) {
      _clearedStages.add(stageLevel);
      playerStarShards += 10;
      playerGem += cfg.gemOnFirstClear;
    }

    // 다음 스테이지 언락
    if (stageLevel >= unlockedStageMax) {
      unlockedStageMax = stageLevel + 1;
    }

    gameState = GameState.stageClear;

    // 스테이지 클리어 데이터 저장
    _saveGameData();
  }

  // ─── 게임오버 ─────────────────────────────────
  void _onGameOver() {
    if (gameState != GameState.waving) return;
    gameState = GameState.gameOver;
  }

  // ─── 웨이브 클리어 인터벌 업데이트 ─────────────
  void _updateWaveCleared(double dt) {
    _waveClearTimer += dt;
    if (_waveClearTimer >= CastleDefenseGame._waveClearDuration) {
      _waveClearTimer = 0.0;
      _startNextWave();
    }
  }

  // ─── 몬스터 스폰 업데이트 ─────────────────────
  void _updateSpawn(double dt) {
    if (spawnedCount >= totalMonstersInWave) return;
    if (_spawnListIndex >= _currentSpawnList.length) return;

    final cfg = kStageConfigs[stageLevel];
    if (cfg == null || currentWave < 1 || currentWave > cfg.waves.length) return;
    final waveCfg = cfg.waves[currentWave - 1];

    spawnTimer += dt;
    if (spawnTimer >= waveCfg.spawnInterval) {
      spawnTimer = 0.0;
      _spawnMonster(_currentSpawnList[_spawnListIndex]);
      _spawnListIndex++;
      spawnedCount++;
    }
  }

  // ─── 몬스터 1마리 생성 ────────────────────────
  void _spawnMonster(EnemyType type) {
    final hp = _enemyHp(currentWave + (stageLevel - 1) * 10, type);
    monsters.add(_Monster(
      pos: Vector2(kPathWaypointDefs[0].$1, kPathWaypointDefs[0].$2),
      hp: hp,
      maxHp: hp,
      enemyType: type,
      speed: _enemySpeed(type),
      castleDamage: _enemyCastleDamage(type),
      goldReward: _enemyGold(type),
      waypointIndex: 0,
    ));
  }

  // ─── 종족 선택 ────────────────────────────────
  void _selectRace(RaceType race) {
    playerRace = race;
    raceSelected = true;
    gameState = GameState.home;

    // 종족 선택 데이터 저장
    _saveGameData();
  }
}
