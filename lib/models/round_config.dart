// 라운드/스테이지 설정 클래스 및 테이블
part of '../castle_defense_game.dart';

class RoundConfig {
  final int roundNumber;
  final int totalMonsters;
  final int monsterMaxHp;
  final double spawnInterval;
  final MonsterType monsterType;
  // 리디자인 B-2-17: 미니보스 수 (라운드 내 스폰할 미니보스 수)
  final int miniBossCount;

  const RoundConfig({
    required this.roundNumber,
    required this.totalMonsters,
    required this.monsterMaxHp,
    required this.spawnInterval,
    this.monsterType = MonsterType.normal,
    this.miniBossCount = 0,
  });
}

class StageConfig {
  final int stageLevel;
  final List<RoundConfig> rounds;

  const StageConfig({
    required this.stageLevel,
    required this.rounds,
  });
}

// 리디자인 B-2-17: P-2-2 라운드 테이블 기반 스테이지 설정
// Stage 1 = Global R1~R10, Stage 2 = Global R11~R20
List<RoundConfig> _createStageRounds(int stageLevel) {
  final rounds = <RoundConfig>[];
  final int globalOffset = (stageLevel - 1) * 10;
  for (int i = 1; i <= 10; i++) {
    rounds.add(_buildRoundConfig(i, globalOffset + i));
  }
  return rounds;
}

// P-2-2 테이블에서 글로벌 라운드 번호로 라운드 설정 생성
RoundConfig _buildRoundConfig(int roundNumber, int globalR) {
  // P-2-3: 글로벌 라운드별 HP 스케일링
  int normalHp;
  if (globalR <= 5) {
    normalHp = 5;
  } else if (globalR <= 10) {
    normalHp = 7;
  } else if (globalR <= 15) {
    normalHp = 10;
  } else if (globalR <= 20) {
    normalHp = 13;
  } else {
    normalHp = 13 + 2 * (globalR - 20);
  }

  // P-2-2 테이블: 라운드별 일반 몬스터 수, 스폰 간격, 미니보스 수, 보스 여부
  int normalCount;
  double spawnInterval;
  int miniBossCount;
  bool isBossRound;

  if (globalR == 1) {
    normalCount = 8; spawnInterval = 2.0; miniBossCount = 0; isBossRound = false;
  } else if (globalR == 2) {
    normalCount = 12; spawnInterval = 1.8; miniBossCount = 0; isBossRound = false;
  } else if (globalR == 3) {
    normalCount = 15; spawnInterval = 1.5; miniBossCount = 1; isBossRound = false;
  } else if (globalR == 4) {
    normalCount = 18; spawnInterval = 1.3; miniBossCount = 1; isBossRound = false;
  } else if (globalR == 5) {
    normalCount = 20; spawnInterval = 1.0; miniBossCount = 0; isBossRound = true;
  } else if (globalR == 6) {
    normalCount = 23; spawnInterval = 0.9; miniBossCount = 1; isBossRound = false;
  } else if (globalR == 7) {
    normalCount = 26; spawnInterval = 0.8; miniBossCount = 1; isBossRound = false;
  } else if (globalR == 8) {
    normalCount = 29; spawnInterval = 0.7; miniBossCount = 2; isBossRound = false;
  } else if (globalR == 9) {
    normalCount = 32; spawnInterval = 0.6; miniBossCount = 2; isBossRound = false;
  } else if (globalR == 10) {
    normalCount = 35; spawnInterval = 0.5; miniBossCount = 0; isBossRound = true;
  } else if (globalR == 11) {
    normalCount = 38; spawnInterval = 0.5; miniBossCount = 2; isBossRound = false;
  } else if (globalR == 12) {
    normalCount = 41; spawnInterval = 0.5; miniBossCount = 2; isBossRound = false;
  } else if (globalR == 13) {
    normalCount = 44; spawnInterval = 0.5; miniBossCount = 3; isBossRound = false;
  } else if (globalR == 14) {
    normalCount = 47; spawnInterval = 0.5; miniBossCount = 3; isBossRound = false;
  } else if (globalR == 15) {
    normalCount = 50; spawnInterval = 0.5; miniBossCount = 0; isBossRound = true;
  } else if (globalR == 16) {
    normalCount = 53; spawnInterval = 0.5; miniBossCount = 3; isBossRound = false;
  } else if (globalR == 17) {
    normalCount = 56; spawnInterval = 0.5; miniBossCount = 3; isBossRound = false;
  } else if (globalR == 18) {
    normalCount = 59; spawnInterval = 0.5; miniBossCount = 4; isBossRound = false;
  } else if (globalR == 19) {
    normalCount = 62; spawnInterval = 0.5; miniBossCount = 4; isBossRound = false;
  } else if (globalR == 20) {
    normalCount = 65; spawnInterval = 0.5; miniBossCount = 0; isBossRound = true;
  } else {
    // R21+: 매 라운드 +3 일반, 4 미니보스 상한, 5라운드마다 보스
    normalCount = 65 + 3 * (globalR - 20);
    spawnInterval = 0.5;
    miniBossCount = 4;
    isBossRound = (globalR % 5 == 0);
  }

  final MonsterType roundType = isBossRound
      ? MonsterType.boss
      : (miniBossCount > 0 ? MonsterType.miniBoss : MonsterType.normal);

  return RoundConfig(
    roundNumber: roundNumber,
    totalMonsters: normalCount,
    monsterMaxHp: normalHp,
    spawnInterval: spawnInterval,
    monsterType: roundType,
    miniBossCount: isBossRound ? 0 : miniBossCount,
  );
}

// 스테이지별 미니보스 HP (글로벌 라운드 기반 HP 계산)
int _getMiniBossHp(int stageLevel) {
  final int midR = (stageLevel - 1) * 10 + 5;
  if (midR <= 5) return 40;
  if (midR <= 10) return 55;
  if (midR <= 15) return 75;
  if (midR <= 20) return 100;
  return 100 + 10 * (midR - 20);
}

// 스테이지별 보스 HP
int _getBossHp(int stageLevel) {
  final int midR = (stageLevel - 1) * 10 + 5;
  if (midR <= 5) return 200;
  if (midR <= 10) return 250;
  if (midR <= 15) return 320;
  if (midR <= 20) return 400;
  return 400 + 30 * (midR - 20);
}

// 리디자인 B-2-17: P-2-2 기반 스테이지 설정 맵
final Map<int, StageConfig> kStageConfigs = {
  1: StageConfig(stageLevel: 1, rounds: _createStageRounds(1)),
  2: StageConfig(stageLevel: 2, rounds: _createStageRounds(2)),
  3: StageConfig(stageLevel: 3, rounds: _createStageRounds(3)),
  4: StageConfig(stageLevel: 4, rounds: _createStageRounds(4)),
  5: StageConfig(stageLevel: 5, rounds: _createStageRounds(5)),
  6: StageConfig(stageLevel: 6, rounds: _createStageRounds(6)),
  7: StageConfig(stageLevel: 7, rounds: _createStageRounds(7)),
  8: StageConfig(stageLevel: 8, rounds: _createStageRounds(8)),
};
