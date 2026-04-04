// 라운드/웨이브 설정 (TD 방식)
part of '../castle_defense_game.dart';

// 웨이브 내 적 스폰 항목
class _SpawnEntry {
  final EnemyType type;
  final int count;
  const _SpawnEntry(this.type, this.count);
}

// 웨이브 설정
class WaveConfig {
  final int waveNumber;
  final List<_SpawnEntry> spawnList; // 순서대로 스폰
  final double spawnInterval;       // 적 사이 스폰 간격(초)
  final int waveGoldBonus;          // 웨이브 시작 골드 보너스
  final int starShardReward;        // 웨이브 클리어 별조각

  const WaveConfig({
    required this.waveNumber,
    required this.spawnList,
    required this.spawnInterval,
    required this.waveGoldBonus,
    required this.starShardReward,
  });

  int get totalMonsters => spawnList.fold(0, (sum, e) => sum + e.count);
}

// 스테이지 설정
class StageConfig {
  final int stageLevel;
  final List<WaveConfig> waves;
  final int starShardOnStageClear;  // 스테이지 완료 별조각
  final int gemOnStageClear;        // 스테이지 완료 젬
  final int gemOnFirstClear;        // 첫 클리어 젬 보너스

  const StageConfig({
    required this.stageLevel,
    required this.waves,
    this.starShardOnStageClear = 20,
    this.gemOnStageClear = 5,
    this.gemOnFirstClear = 10,
  });
}

// ─────────────────────────────────────────
// 적 기본 스탯 산출 (라운드 기반)
// ─────────────────────────────────────────
int _enemyHp(int waveNumber, EnemyType type) {
  final base = (5 * pow(1.25, waveNumber - 1)).round();
  return switch (type) {
    EnemyType.normal   => base,
    EnemyType.fast     => (base * 0.5).round(),
    EnemyType.tank     => (base * 3.0).round(),
    EnemyType.miniBoss => (base * 8.0).round(),
    EnemyType.boss     => (base * 20.0).round(),
  };
}

double _enemySpeed(EnemyType type) => switch (type) {
  EnemyType.normal   => 70.0,
  EnemyType.fast     => 130.0,
  EnemyType.tank     => 35.0,
  EnemyType.miniBoss => 45.0,
  EnemyType.boss     => 30.0,
};

int _enemyCastleDamage(EnemyType type) => switch (type) {
  EnemyType.normal   => 1,
  EnemyType.fast     => 1,
  EnemyType.tank     => 3,
  EnemyType.miniBoss => 5,
  EnemyType.boss     => 10,
};

int _enemyGold(EnemyType type) => switch (type) {
  EnemyType.normal   => 1,
  EnemyType.fast     => 2,
  EnemyType.tank     => 4,
  EnemyType.miniBoss => 10,
  EnemyType.boss     => 30,
};

// ─────────────────────────────────────────
// 스테이지 1 웨이브 설정 (10웨이브)
// ─────────────────────────────────────────
List<WaveConfig> _buildStage1Waves() {
  return [
    // W1: 노말만
    WaveConfig(waveNumber: 1, spawnInterval: 2.0, waveGoldBonus: 20, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 10)]),
    // W2: 노말
    WaveConfig(waveNumber: 2, spawnInterval: 1.8, waveGoldBonus: 40, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 14)]),
    // W3: 노말+빠름
    WaveConfig(waveNumber: 3, spawnInterval: 1.6, waveGoldBonus: 60, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 12), _SpawnEntry(EnemyType.fast, 6)]),
    // W4: 노말+탱크
    WaveConfig(waveNumber: 4, spawnInterval: 1.5, waveGoldBonus: 80, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 12), _SpawnEntry(EnemyType.tank, 4)]),
    // W5: 노말+미니보스
    WaveConfig(waveNumber: 5, spawnInterval: 1.4, waveGoldBonus: 100, starShardReward: 5,
      spawnList: [_SpawnEntry(EnemyType.normal, 14), _SpawnEntry(EnemyType.miniBoss, 1)]),
    // W6: 노말+빠름+탱크
    WaveConfig(waveNumber: 6, spawnInterval: 1.3, waveGoldBonus: 120, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 10), _SpawnEntry(EnemyType.fast, 6), _SpawnEntry(EnemyType.tank, 3)]),
    // W7: 노말+빠름+탱크
    WaveConfig(waveNumber: 7, spawnInterval: 1.2, waveGoldBonus: 140, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 12), _SpawnEntry(EnemyType.fast, 8), _SpawnEntry(EnemyType.tank, 4)]),
    // W8: 노말+미니보스×2
    WaveConfig(waveNumber: 8, spawnInterval: 1.1, waveGoldBonus: 160, starShardReward: 5,
      spawnList: [_SpawnEntry(EnemyType.normal, 15), _SpawnEntry(EnemyType.miniBoss, 2)]),
    // W9: 전 타입 혼합
    WaveConfig(waveNumber: 9, spawnInterval: 1.0, waveGoldBonus: 180, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 10), _SpawnEntry(EnemyType.fast, 8), _SpawnEntry(EnemyType.tank, 5), _SpawnEntry(EnemyType.miniBoss, 1)]),
    // W10: 보스
    WaveConfig(waveNumber: 10, spawnInterval: 0.8, waveGoldBonus: 200, starShardReward: 8,
      spawnList: [_SpawnEntry(EnemyType.normal, 10), _SpawnEntry(EnemyType.fast, 6), _SpawnEntry(EnemyType.boss, 1)]),
  ];
}

// ─────────────────────────────────────────
// 스테이지 2 웨이브 설정 (10웨이브, 강화된 구성)
// ─────────────────────────────────────────
List<WaveConfig> _buildStage2Waves() {
  return [
    WaveConfig(waveNumber: 1, spawnInterval: 1.8, waveGoldBonus: 25, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 12), _SpawnEntry(EnemyType.fast, 4)]),
    WaveConfig(waveNumber: 2, spawnInterval: 1.6, waveGoldBonus: 50, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 14), _SpawnEntry(EnemyType.fast, 6)]),
    WaveConfig(waveNumber: 3, spawnInterval: 1.5, waveGoldBonus: 75, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 12), _SpawnEntry(EnemyType.fast, 6), _SpawnEntry(EnemyType.tank, 3)]),
    WaveConfig(waveNumber: 4, spawnInterval: 1.4, waveGoldBonus: 100, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 10), _SpawnEntry(EnemyType.fast, 8), _SpawnEntry(EnemyType.tank, 5)]),
    WaveConfig(waveNumber: 5, spawnInterval: 1.3, waveGoldBonus: 125, starShardReward: 5,
      spawnList: [_SpawnEntry(EnemyType.normal, 12), _SpawnEntry(EnemyType.tank, 4), _SpawnEntry(EnemyType.miniBoss, 2)]),
    WaveConfig(waveNumber: 6, spawnInterval: 1.2, waveGoldBonus: 150, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 14), _SpawnEntry(EnemyType.fast, 8), _SpawnEntry(EnemyType.tank, 4)]),
    WaveConfig(waveNumber: 7, spawnInterval: 1.1, waveGoldBonus: 175, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 12), _SpawnEntry(EnemyType.fast, 10), _SpawnEntry(EnemyType.tank, 5)]),
    WaveConfig(waveNumber: 8, spawnInterval: 1.0, waveGoldBonus: 200, starShardReward: 5,
      spawnList: [_SpawnEntry(EnemyType.normal, 15), _SpawnEntry(EnemyType.fast, 8), _SpawnEntry(EnemyType.miniBoss, 2)]),
    WaveConfig(waveNumber: 9, spawnInterval: 0.9, waveGoldBonus: 225, starShardReward: 3,
      spawnList: [_SpawnEntry(EnemyType.normal, 12), _SpawnEntry(EnemyType.fast, 10), _SpawnEntry(EnemyType.tank, 6), _SpawnEntry(EnemyType.miniBoss, 1)]),
    WaveConfig(waveNumber: 10, spawnInterval: 0.8, waveGoldBonus: 250, starShardReward: 8,
      spawnList: [_SpawnEntry(EnemyType.normal, 12), _SpawnEntry(EnemyType.fast, 8), _SpawnEntry(EnemyType.tank, 4), _SpawnEntry(EnemyType.boss, 1)]),
  ];
}

// ─────────────────────────────────────────
// 스테이지 설정 맵
// ─────────────────────────────────────────
final Map<int, StageConfig> kStageConfigs = {
  1: StageConfig(stageLevel: 1, waves: _buildStage1Waves(),
      starShardOnStageClear: 20, gemOnStageClear: 5, gemOnFirstClear: 10),
  2: StageConfig(stageLevel: 2, waves: _buildStage2Waves(),
      starShardOnStageClear: 30, gemOnStageClear: 8, gemOnFirstClear: 15),
};
