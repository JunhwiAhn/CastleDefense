// 스테이지/라운드 로딩 및 전환
part of '../castle_defense_game.dart';

extension StageSystem on CastleDefenseGame {
  // -----------------------------
  // 스테이지 로딩 / 시작 / 전환
  // -----------------------------
  void _loadStage(int level) {
    final cfg = kStageConfigs[level] ?? kStageConfigs[1]!;

    stageLevel = cfg.stageLevel;
    currentRound = 1; // 첫 번째 라운드부터 시작
    totalRoundsInStage = cfg.rounds.length;

    castleHp = castleMaxHp;
    monsters.clear();
    // 리디자인 B-2-10: 인게임 XP 초기화
    playerXp = 0;
    playerCharLevel = 1;
    // 속성 시스템: 스테이지 시작 시 속성 리셋 (바프로 재부여)
    _mainCharElement = ElementType.none;
    _elementMasteryCount = 0;
    // 증강 시스템: 스테이지 시작 시 비전설 증강 리셋, 전설은 carryOver 유지
    activeAugments = activeAugments.where((a) => a.carryOverToNextStage).toList();
    _acquiredAugmentIds.clear();
    for (final a in activeAugments) { _acquiredAugmentIds.add(a.id); }
    _augmentOptions = [];
    _augmentL01Used = false;
    _augmentL03Used = false;
    _augmentR12Used = false;
    _augmentR04Stacks = 0;
    _augmentR04Timer = 0.0;
    _augmentL02Active = false;
    _augmentL02Timer = 0.0;
    _augmentL03BarrierActive = false;
    _augmentL03BarrierTimer = 0.0;
    _buffSelectionCount.clear();

    _loadRound(1); // 첫 번째 라운드 로딩
  }

  void _loadRound(int roundNumber) {
    final cfg = kStageConfigs[stageLevel];
    if (cfg == null || roundNumber < 1 || roundNumber > cfg.rounds.length) {
      return;
    }

    final roundCfg = cfg.rounds[roundNumber - 1];
    currentRound = roundNumber;
    totalMonstersInRound = roundCfg.totalMonsters;
    monsterMaxHp = roundCfg.monsterMaxHp;

    spawnedMonsters = 0;
    defeatedMonsters = 0;
    escapedMonsters = 0;
    spawnTimer = 0.0;
    bossSpawned = false;
    miniBossesSpawned = 0; // 리디자인 B-2-17

    // D-1-6: 라운드 시작 시 XP/골드 추적 초기화
    _roundXpGained = 0;
    _roundGoldGained = 0;

    // 라운드 타입에 따라 시간 제한 설정
    roundTimer = 0.0;
    if (roundCfg.monsterType == MonsterType.boss) {
      roundTimeLimit = 300.0; // 보스: 5분
    } else if (roundCfg.monsterType == MonsterType.miniBoss) {
      roundTimeLimit = 180.0; // 미니보스: 3분
    } else {
      roundTimeLimit = 120.0; // 일반: 2분
    }

    // 라운드 시작 시 맵 요소 전체 클리어 (이전 라운드 잔여물 제거)
    monsters.clear();
    goldDrops.clear();
    xpGems.clear();
    projectiles.clear();
    vfxEffects.clear();
    _damageNumbers.clear();

    // 라운드 시작 시 증강 리셋 (라운드 중에만 유효)
    activeAugments.clear();
    _acquiredAugmentIds.clear();
    _augmentOptions = [];
    _augmentL01Used = false;
    _augmentL03Used = false;
    _augmentR12Used = false;
    _augmentR04Stacks = 0;
    _augmentR04Timer = 0.0;
    _augmentL02Active = false;
    _augmentL02Timer = 0.0;
    _augmentL03BarrierActive = false;
    _augmentL03BarrierTimer = 0.0;
    _buffSelectionCount.clear();

    // 메인 캐릭터 상태 초기화
    _mainCharAlive = true;
    _mainCharRespawning = false;
    _mainCharHp = _mainCharMaxHp;
    _respawnTimer = 0.0;
    _invincibleTimer = 0.0;
  }

  void _goToRoundSelect() {
    monsters.clear();
    gameState = GameState.roundSelect;
  }

  void _startNextRound() {
    if (currentRound < totalRoundsInStage) {
      _loadRound(currentRound + 1);
      gameState = GameState.playing;
    } else {
      // 모든 라운드 클리어 (스테이지 클리어)
      _onStageClear();
    }
  }
}
