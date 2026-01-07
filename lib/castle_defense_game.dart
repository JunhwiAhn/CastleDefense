// castle_defense_game.dart

import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

enum GameState {
  loading, // 로딩(0.5초 게이지)
  roundSelect, // 라운드 선택 (맵 스타일)
  playing, // 실제 전투
  paused, // 일시정지
  roundClear, // 라운드 클리어 (잠깐 멈춤)
  result, // 결과 화면 (클리어 or 실패)
}

enum BottomMenu {
  shop, // 상점
  inventory, // 인벤토리
  home, // 홈 (라운드 선택)
  gacha, // 뽑기
  settings, // 설정
}

enum MonsterType {
  normal, // 일반 몬스터
  miniBoss, // 부보스 (라운드 5)
  boss, // 보스 (라운드 10)
}

class RoundConfig {
  final int roundNumber;
  final int totalMonsters;
  final int monsterMaxHp;
  final double spawnInterval;
  final MonsterType monsterType;

  const RoundConfig({
    required this.roundNumber,
    required this.totalMonsters,
    required this.monsterMaxHp,
    required this.spawnInterval,
    this.monsterType = MonsterType.normal,
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

// 헬퍼 함수: 일반 라운드 생성
List<RoundConfig> _createStageRounds(int stageLevel) {
  final rounds = <RoundConfig>[];

  for (int i = 1; i <= 10; i++) {
    // 모든 라운드는 일반 몬스터 수 계산 적용
    // 보스/미니보스 라운드도 일반 몬스터가 나오고, 추가로 보스가 나옴
    rounds.add(RoundConfig(
      roundNumber: i,
      totalMonsters: _getRoundMonsterCount(stageLevel, i),
      monsterMaxHp: _getNormalMonsterHp(stageLevel),
      spawnInterval: _getSpawnInterval(stageLevel),
      monsterType: i == 10 ? MonsterType.boss : i == 5 ? MonsterType.miniBoss : MonsterType.normal,
    ));
  }

  return rounds;
}

// 스테이지별 일반 몬스터 수 (모든 라운드에 적용)
int _getRoundMonsterCount(int stageLevel, int roundNumber) {
  // 스테이지별 시작 몬스터 수와 라운드당 증가량
  int baseCount;
  int incrementPerRound;

  switch (stageLevel) {
    case 1:
      baseCount = 6; // 라운드 1 시작
      incrementPerRound = 4; // 라운드마다 4씩 증가
      break;
    case 2:
      baseCount = 22; // 라운드 1 시작
      incrementPerRound = 6; // 라운드마다 6씩 증가
      break;
    case 3:
      baseCount = 40; // 라운드 1 시작
      incrementPerRound = 8; // 라운드마다 8씩 증가
      break;
    case 4:
      baseCount = 60; // 라운드 1 시작
      incrementPerRound = 10; // 라운드마다 10씩 증가
      break;
    case 5:
      baseCount = 85; // 라운드 1 시작
      incrementPerRound = 12; // 라운드마다 12씩 증가
      break;
    default:
      baseCount = 100;
      incrementPerRound = 15;
      break;
  }

  return baseCount + ((roundNumber - 1) * incrementPerRound);
}

// 스테이지별 일반 몬스터 HP
int _getNormalMonsterHp(int stageLevel) {
  return 1 + stageLevel;
}

// 스테이지별 부보스 HP
int _getMiniBossHp(int stageLevel) {
  return 10 + (stageLevel * 5);
}

// 스테이지별 보스 HP
int _getBossHp(int stageLevel) {
  return 20 + (stageLevel * 10);
}

// 스테이지별 스폰 간격
double _getSpawnInterval(int stageLevel) {
  switch (stageLevel) {
    case 1:
      return 1.0;
    case 2:
      return 0.8;
    case 3:
      return 0.7;
    case 4:
      return 0.6;
    case 5:
      return 0.5;
    default:
      return 0.5;
  }
}

// 스테이지별 설정 (5개 스테이지, 각 10라운드)
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

class _Monster {
  Vector2 pos;
  int hp;
  int maxHp;
  bool falling;
  bool walking;
  MonsterType type;

  _Monster({
    required this.pos,
    required this.hp,
    required this.maxHp,
    required this.falling,
    required this.walking,
    this.type = MonsterType.normal,
  });
}

// 캐릭터 슬롯 (향후 자동공격/스킬 사용)
class _CharacterSlot {
  final int slotIndex; // 0~3
  bool hasCharacter; // 캐릭터가 배치되어 있는지
  String characterName; // 캐릭터 이름 (프로토타입용)
  bool skillReady; // 스킬 사용 가능 여부

  _CharacterSlot({
    required this.slotIndex,
    this.hasCharacter = false,
    this.characterName = '',
    this.skillReady = false,
  });
}

class CastleDefenseGame extends FlameGame with TapCallbacks {
  // -----------------------------
  // 기본 설정
  // -----------------------------
  final double castleHeight = 80.0; // 2배로 확대
  final int castleMaxHp = 10;
  int castleHp = 10;

  // 몬스터 설정
  final double monsterRadius = 16.0;
  final double monsterFallSpeed = 80.0; // 낙하 속도
  final double monsterWalkSpeed = 50.0; // 걷기 속도

  // 무기 (프로토타입)
  final int weaponDamage = 1; // 기본검 데미지

  // 스테이지 & 라운드 관련
  GameState gameState = GameState.loading;
  int stageLevel = 1;
  int currentRound = 1; // 현재 라운드 (1~10)
  int totalRoundsInStage = 10; // 스테이지당 라운드 수

  // 현재 라운드 스폰 관련
  int totalMonstersInRound = 5; // 현재 라운드의 총 몬스터 수
  int spawnedMonsters = 0; // 현재 라운드에서 스폰된 몬스터 수
  int defeatedMonsters = 0; // 현재 라운드에서 플레이어가 처치한 몬스터 수
  int escapedMonsters = 0; // 현재 라운드에서 성에 도달한 몬스터 수 (미처치)

  int monsterMaxHp = 2; // 현재 라운드 몬스터 최대 HP
  double spawnTimer = 0.0;

  bool bossSpawned = false; // 보스/미니보스가 이미 스폰되었는지 여부

  // 라운드 시간 제한
  double roundTimer = 0.0; // 현재 라운드 경과 시간
  double roundTimeLimit = 120.0; // 현재 라운드 제한 시간 (초)

  // 로딩 화면용
  double _loadingTimer = 0.0;
  final double _loadingDuration = 0.5; // 초 단위

  // 라운드 클리어 대기용
  double _roundClearTimer = 0.0;
  final double _roundClearDuration = 2.0; // 2초 대기

  // 라운드 언락 상태
  int unlockedRoundMax = 1; // 처음엔 라운드 1만 선택 가능

  // 스테이지 선택 화면용
  int selectedStageInUI = 1; // 라운드 선택 화면에서 현재 보고 있는 스테이지

  // 하단 메뉴
  BottomMenu currentBottomMenu = BottomMenu.home;

  // 결과 화면용 정보
  bool _lastStageClear = false;

  // 테스트 갓 모드
  bool _godModeEnabled = false;

  // 플레이어 정보 (네비게이션 바용)
  String playerNickname = 'Player';
  int playerLevel = 1;
  int playerGold = 1000;
  int playerGem = 50;
  int playerEnergy = 50;
  int playerMaxEnergy = 50;
  DateTime _lastEnergyUpdateTime = DateTime.now();

  // 몬스터 리스트
  final List<_Monster> monsters = [];

  // 캐릭터 슬롯 (4개)
  final List<_CharacterSlot> characterSlots = [];

  // 랜덤
  final Random _random = Random();

  int get killedMonsters => defeatedMonsters;

  // -----------------------------
  // 라이프사이클
  // -----------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializeCharacterSlots(); // 캐릭터 슬롯 초기화
    _loadStage(1); // 내부 파라미터 초기화
    gameState = GameState.loading; // GameScreen 진입 즉시 로딩부터 시작
    _loadingTimer = 0.0;
  }

  // 캐릭터 슬롯 초기화 (처음에는 모두 비어있음)
  void _initializeCharacterSlots() {
    characterSlots.clear();
    for (int i = 0; i < 4; i++) {
      characterSlots.add(_CharacterSlot(
        slotIndex: i,
        hasCharacter: false, // 모든 슬롯이 처음엔 비어있음
        characterName: '',
        skillReady: false,
      ));
    }
  }

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

    // 라운드 타입에 따라 시간 제한 설정
    roundTimer = 0.0;
    if (roundCfg.monsterType == MonsterType.boss) {
      roundTimeLimit = 300.0; // 보스: 5분
    } else if (roundCfg.monsterType == MonsterType.miniBoss) {
      roundTimeLimit = 180.0; // 미니보스: 3분
    } else {
      roundTimeLimit = 120.0; // 일반: 2분
    }

    monsters.clear();
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

  // -----------------------------
  // 업데이트 루프
  // -----------------------------
  @override
  void update(double dt) {
    super.update(dt);

    // 에너지 충전 업데이트 (모든 상태에서 지속적으로 실행)
    _updateEnergy();

    switch (gameState) {
      case GameState.loading:
        _updateLoading(dt);
        return;
      case GameState.roundSelect:
        return;
      case GameState.playing:
        _updatePlaying(dt);
        return;
      case GameState.paused:
        // 일시정지 중에는 업데이트 하지 않음
        return;
      case GameState.roundClear:
        _updateRoundClear(dt);
        return;
      case GameState.result:
        return;
    }
  }

  // 에너지 충전 로직 (10분에 1개씩, 최대 50개)
  void _updateEnergy() {
    if (playerEnergy >= playerMaxEnergy) {
      _lastEnergyUpdateTime = DateTime.now();
      return;
    }

    final now = DateTime.now();
    final diff = now.difference(_lastEnergyUpdateTime);

    // 10분마다 1개씩 충전
    final energyToAdd = diff.inMinutes ~/ 10;
    if (energyToAdd > 0) {
      playerEnergy = (playerEnergy + energyToAdd).clamp(0, playerMaxEnergy);
      _lastEnergyUpdateTime = _lastEnergyUpdateTime.add(
        Duration(minutes: energyToAdd * 10),
      );
    }
  }

  void _updateLoading(double dt) {
    _loadingTimer += dt;
    if (_loadingTimer >= _loadingDuration) {
      _loadingTimer = 0.0;
      _goToRoundSelect();
    }
  }

  void _updatePlaying(double dt) {
    if (size.x <= 0 || size.y <= 0) return;

    // 라운드 타이머 업데이트
    roundTimer += dt;

    // 시간 제한 체크
    if (roundTimer >= roundTimeLimit) {
      _onTimeOver();
      return;
    }

    _updateMonsters(dt);

    // 현재 라운드의 몬스터 스폰
    if (spawnedMonsters < totalMonstersInRound) {
      spawnTimer += dt;
      final cfg = kStageConfigs[stageLevel];
      if (cfg != null && currentRound <= cfg.rounds.length) {
        final roundCfg = cfg.rounds[currentRound - 1];
        if (spawnTimer >= roundCfg.spawnInterval) {
          spawnTimer = 0.0;
          _spawnMonster();
        }
      }
    }

    // 성 HP가 0이면 게임오버
    if (castleHp <= 0 && gameState == GameState.playing) {
      _onGameOver();
      return;
    }

    // 라운드 클리어 체크: 모든 몬스터가 처리되었고 화면에 몬스터가 없을 때
    // (처치된 몬스터 + 성에 도달한 몬스터 = 전체 몬스터)
    if ((defeatedMonsters + escapedMonsters) >= totalMonstersInRound && monsters.isEmpty) {
      _onRoundClear();
    }
  }

  void _updateRoundClear(double dt) {
    _roundClearTimer += dt;
    if (_roundClearTimer >= _roundClearDuration) {
      _roundClearTimer = 0.0;
      _startNextRound();
    }
  }

  // -----------------------------
  // 몬스터 업데이트 / 스폰
  // -----------------------------
  void _updateMonsters(double dt) {
    final groundY = size.y - castleHeight - monsterRadius - 8.0;
    final castleCenterX = size.x / 2;
    const double castleHitWidth = 60.0;

    for (var i = monsters.length - 1; i >= 0; i--) {
      final m = monsters[i];

      if (m.falling) {
        m.pos.y += monsterFallSpeed * dt;
        if (m.pos.y >= groundY) {
          m.pos.y = groundY;
          m.falling = false;
          m.walking = true;
        }
      } else if (m.walking) {
        final dx = castleCenterX - m.pos.x;

        if (dx.abs() < castleHitWidth / 2) {
          // 보스/미니보스가 성에 도달하면 즉시 게임오버
          if (m.type == MonsterType.boss || m.type == MonsterType.miniBoss) {
            castleHp = 0; // 성 체력을 0으로 만들어 게임오버 트리거
            _onGameOver();
            return;
          }

          // 일반 몬스터는 성 HP만 감소
          castleHp = max(0, castleHp - 1);
          monsters.removeAt(i);
          escapedMonsters++; // 성에 도달한 몬스터 (처치 실패)
          continue;
        }

        final dir = dx == 0 ? 0.0 : dx.sign;
        m.pos.x += dir * monsterWalkSpeed * dt;
        m.pos.x = m.pos.x.clamp(monsterRadius, size.x - monsterRadius);
      }
    }
  }

  void _spawnMonster() {
    if (size.x <= 0 || size.y <= 0) return;

    final cfg = kStageConfigs[stageLevel];
    if (cfg == null || currentRound < 1 || currentRound > cfg.rounds.length) {
      return;
    }

    final roundCfg = cfg.rounds[currentRound - 1];

    final x =
        monsterRadius + _random.nextDouble() * (size.x - monsterRadius * 2);
    final y = -monsterRadius * 2;

    // 일반 몬스터 스폰 (보스 라운드에서도 일반 몬스터 타입으로)
    monsters.add(
      _Monster(
        pos: Vector2(x, y),
        hp: monsterMaxHp,
        maxHp: monsterMaxHp,
        falling: true,
        walking: false,
        type: MonsterType.normal, // 항상 일반 몬스터로 스폰
      ),
    );
    spawnedMonsters++;

    // 모든 일반 몬스터를 스폰했고, 보스 라운드이며, 아직 보스가 스폰되지 않았다면
    if (spawnedMonsters >= totalMonstersInRound &&
        !bossSpawned &&
        (roundCfg.monsterType == MonsterType.boss || roundCfg.monsterType == MonsterType.miniBoss)) {
      _spawnBoss(roundCfg.monsterType);
    }
  }

  void _spawnBoss(MonsterType bossType) {
    if (size.x <= 0 || size.y <= 0 || bossSpawned) return;

    final x = size.x / 2; // 보스는 화면 중앙에서 스폰
    final y = -monsterRadius * 4;

    // 보스 HP 결정
    int bossHp;
    if (bossType == MonsterType.boss) {
      bossHp = _getBossHp(stageLevel);
    } else {
      bossHp = _getMiniBossHp(stageLevel);
    }

    monsters.add(
      _Monster(
        pos: Vector2(x, y),
        hp: bossHp,
        maxHp: bossHp,
        falling: true,
        walking: false,
        type: bossType,
      ),
    );

    bossSpawned = true;
    // 보스도 카운트에 포함 (총 몬스터 수 +1)
    totalMonstersInRound++;
  }

  void _killMonsterAtIndex(int index) {
    if (index < 0 || index >= monsters.length) return;
    monsters.removeAt(index);
    defeatedMonsters++;
  }

  bool _isPointInsideMonster(_Monster m, Vector2 tapPos) {
    final dx = tapPos.x - m.pos.x;
    final dy = tapPos.y - m.pos.y;
    final dist2 = dx * dx + dy * dy;

    // 몬스터 타입별 히트박스 크기
    double radius;
    switch (m.type) {
      case MonsterType.boss:
        radius = monsterRadius * 2.0;
        break;
      case MonsterType.miniBoss:
        radius = monsterRadius * 1.5;
        break;
      case MonsterType.normal:
      default:
        radius = monsterRadius;
        break;
    }

    return dist2 <= radius * radius;
  }

  // -----------------------------
  // 상태 전환 (라운드 클리어 / 스테이지 클리어 / 게임오버)
  // -----------------------------
  void _onRoundClear() {
    if (gameState != GameState.playing) return;

    _lastStageClear = true;

    // 라운드 언락: 현재 라운드까지 클리어했으므로 다음 라운드 언락
    if (currentRound >= unlockedRoundMax && currentRound < totalRoundsInStage) {
      unlockedRoundMax = currentRound + 1;
    }

    // 바로 결과 화면으로 전환
    gameState = GameState.result;
  }

  void _onStageClear() {
    _lastStageClear = true;

    // 라운드 언락: 현재 라운드까지 클리어했으므로 다음 라운드 언락
    if (currentRound >= unlockedRoundMax && currentRound < totalRoundsInStage) {
      unlockedRoundMax = currentRound + 1;
    }

    gameState = GameState.result;
  }

  void _onGameOver() {
    if (gameState != GameState.playing) return;

    _lastStageClear = false;

    gameState = GameState.result;
  }

  void _onTimeOver() {
    if (gameState != GameState.playing) return;

    _lastStageClear = false;

    gameState = GameState.result;
  }

  // -----------------------------
  // 입력 처리 (탭)
  // -----------------------------
  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.localPosition;

    switch (gameState) {
      case GameState.loading:
        // 로딩 상태에서는 탭 무시 (자동 진행)
        break;
      case GameState.roundSelect:
        _handleTapInRoundSelect(pos);
        break;
      case GameState.playing:
        _handleTapInPlaying(pos);
        break;
      case GameState.paused:
        _handleTapInPaused(pos);
        break;
      case GameState.roundClear:
        // 라운드 클리어 중에는 탭 무시 (자동 진행)
        break;
      case GameState.result:
        _handleTapInResult(pos);
        break;
    }

    super.onTapDown(event);
  }

  // 라운드 선택 화면: 맵 위 라운드 노드 터치
  void _handleTapInRoundSelect(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);
    const int totalRounds = 10;
    final unlocked = unlockedRoundMax.clamp(1, totalRounds);

    // 하단 메뉴 버튼 체크
    for (int i = 0; i < 5; i++) {
      final rect = _bottomMenuButtonRect(i);
      if (rect.contains(offset)) {
        _handleBottomMenuTap(i);
        return;
      }
    }

    // God Mode 버튼 체크
    final godModeRect = _godModeButtonRect();
    if (godModeRect.contains(offset)) {
      _toggleGodMode();
      return;
    }

    // 왼쪽 스테이지 변경 버튼 체크
    final leftStageButtonRect = _leftStageButtonRect();
    if (leftStageButtonRect.contains(offset)) {
      if (selectedStageInUI > 1) {
        selectedStageInUI--;
      }
      return;
    }

    // 오른쪽 스테이지 변경 버튼 체크
    final rightStageButtonRect = _rightStageButtonRect();
    if (rightStageButtonRect.contains(offset)) {
      if (selectedStageInUI < 8) {
        selectedStageInUI++;
      }
      return;
    }

    for (int i = 1; i <= totalRounds; i++) {
      final rect = _roundNodeRect(i);
      if (rect.contains(offset)) {
        if (i <= unlocked) {
          _startRound(i);
        }
        break;
      }
    }
  }

  // 하단 메뉴 탭 처리
  void _handleBottomMenuTap(int index) {
    switch (index) {
      case 0: // 상점
        currentBottomMenu = BottomMenu.shop;
        break;
      case 1: // 인벤토리
        currentBottomMenu = BottomMenu.inventory;
        break;
      case 2: // 홈
        currentBottomMenu = BottomMenu.home;
        break;
      case 3: // 뽑기
        currentBottomMenu = BottomMenu.gacha;
        break;
      case 4: // 설정
        currentBottomMenu = BottomMenu.settings;
        break;
    }
  }

  // 특정 라운드부터 시작
  void _startRound(int roundNumber) {
    _loadStage(selectedStageInUI); // 선택된 스테이지 로드
    _loadRound(roundNumber);
    gameState = GameState.playing;
  }

  // 플레이 중: 몬스터 공격 또는 일시정지 버튼 또는 캐릭터 스킬
  void _handleTapInPlaying(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);

    // 일시정지 버튼 체크 (우측 상단)
    final pauseButtonRect = _pauseButtonRect();
    if (pauseButtonRect.contains(offset)) {
      gameState = GameState.paused;
      return;
    }

    // 캐릭터 슬롯 체크 (스킬 사용)
    for (int i = 0; i < characterSlots.length; i++) {
      final slotRect = _characterSlotRect(i);
      if (slotRect.contains(offset)) {
        _handleCharacterSlotTap(i);
        return;
      }
    }

    // 몬스터 공격
    for (var i = 0; i < monsters.length; i++) {
      final m = monsters[i];
      if (_isPointInsideMonster(m, tapPos)) {
        m.hp = max(0, m.hp - weaponDamage);
        if (m.hp <= 0) {
          _killMonsterAtIndex(i);
        }
        break;
      }
    }
  }

  // 캐릭터 슬롯 클릭 처리 (스킬 사용)
  void _handleCharacterSlotTap(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= characterSlots.length) return;

    final slot = characterSlots[slotIndex];

    // 캐릭터가 있고 스킬이 준비된 경우에만 스킬 사용
    if (slot.hasCharacter && slot.skillReady) {
      _useCharacterSkill(slotIndex);
    }
  }

  // 캐릭터 스킬 사용 (프로토타입: 화면의 모든 몬스터에게 데미지)
  void _useCharacterSkill(int slotIndex) {
    final slot = characterSlots[slotIndex];

    // 스킬 효과: 모든 몬스터에게 3 데미지
    const int skillDamage = 3;
    int damageCount = 0;

    for (var i = monsters.length - 1; i >= 0; i--) {
      final m = monsters[i];
      m.hp = max(0, m.hp - skillDamage);
      if (m.hp <= 0) {
        _killMonsterAtIndex(i);
      }
      damageCount++;
    }

    // 스킬 사용 후 쿨다운 (프로토타입: 즉시 재사용 불가)
    slot.skillReady = false;

    // 5초 후 스킬 재사용 가능 (실제로는 타이머 필요, 지금은 간단히 표시만)
    // TODO: 실제 쿨다운 타이머 구현
    Future.delayed(const Duration(seconds: 5), () {
      if (slotIndex < characterSlots.length) {
        characterSlots[slotIndex].skillReady = true;
      }
    });

    print('캐릭터 ${slotIndex + 1} 스킬 사용! $damageCount 마리의 몬스터에게 데미지');
  }

  // 일시정지 화면: "재개 / 라운드 선택 / 재시작"
  void _handleTapInPaused(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);

    final resumeRect = _pauseResumeButtonRect();
    final roundSelectRect = _pauseRoundSelectButtonRect();
    final retryRect = _pauseRetryButtonRect();

    if (resumeRect.contains(offset)) {
      gameState = GameState.playing;
      return;
    }

    if (roundSelectRect.contains(offset)) {
      _goToRoundSelect();
      return;
    }

    if (retryRect.contains(offset)) {
      _startRound(currentRound);
      return;
    }
  }

  // 결과 화면: "다시하기 / 라운드 선택 / 다음 라운드"
  void _handleTapInResult(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);

    final retryRect = _resultRetryButtonRect();
    final roundSelectRect = _resultRoundSelectButtonRect();
    final nextRect = _resultNextRoundButtonRect();

    if (retryRect.contains(offset)) {
      _startRound(currentRound);
      return;
    }

    if (roundSelectRect.contains(offset)) {
      _goToRoundSelect();
      return;
    }

    final nextRound = currentRound + 1;
    final canGoNext = _lastStageClear && nextRound <= totalRoundsInStage;

    if (canGoNext && nextRect.contains(offset)) {
      if (nextRound > unlockedRoundMax) {
        unlockedRoundMax = nextRound;
      }
      _startRound(nextRound);
    }
  }

  // -----------------------------
  // 버튼 Rect (일시정지 버튼)
  // -----------------------------
  Rect _pauseButtonRect() {
    const double buttonSize = 35.0; // 작은 버튼
    const double marginTop = 15.0;
    const double marginSide = 20.0;

    // 스테이지-라운드 표시 오른쪽에 배치
    // 스테이지-라운드는 (size.x - marginSide - 30)에 위치하므로 그 오른쪽에 배치
    final double x = this.size.x - marginSide - 10;
    final double y = marginTop - (buttonSize / 2); // 중앙 정렬

    return Rect.fromLTWH(x, y, buttonSize, buttonSize);
  }

  // -----------------------------
  // 캐릭터 슬롯 Rect
  // -----------------------------
  Rect _characterSlotRect(int slotIndex) {
    const double slotSize = 50.0;
    const double slotSpacing = 10.0;
    const double slotPadding = 10.0;

    const totalWidth = (slotSize * 4) + (slotSpacing * 3);
    final startX = (size.x - totalWidth) / 2;
    final slotY = _castleRect.top + slotPadding;

    final x = startX + (slotIndex * (slotSize + slotSpacing));
    return Rect.fromLTWH(x, slotY, slotSize, slotSize);
  }

  // -----------------------------
  // 버튼 Rect (일시정지 화면)
  // -----------------------------
  Rect _pauseResumeButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.50;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _pauseRoundSelectButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.50 + 52;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _pauseRetryButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.50 + 52 * 2;
    return Rect.fromLTWH(x, y, width, height);
  }

  // -----------------------------
  // 버튼 Rect (결과 화면)
  // -----------------------------
  Rect _resultRetryButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.55;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _resultRoundSelectButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.55 + 52;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _resultNextRoundButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.55 + 52 * 2;
    return Rect.fromLTWH(x, y, width, height);
  }

  // -----------------------------
  // 캔디크러쉬 사가 스타일: 사각형 타일 배치 (2열)
  // -----------------------------
  Offset _roundNodeCenter(int roundIndex) {
    const double topMargin = 140.0; // 네비게이션 바(60) + 타이틀 박스(50) + 여백(30)
    const double tileSize = 70.0; // 타일 크기
    const double horizontalSpacing = 15.0; // 좌우 간격
    const double verticalSpacing = 15.0; // 상하 간격

    final double centerX = size.x / 2;

    // 보스 라운드(10)는 맨 밑 중앙에 배치
    if (roundIndex == 10) {
      final double y = topMargin + (3 * (tileSize + verticalSpacing)) + tileSize / 2;
      return Offset(centerX, y);
    }

    // 1-9 라운드: 3열 배치 (3x3 그리드)
    final int row = (roundIndex - 1) ~/ 3; // 0, 1, 2 행
    final int col = (roundIndex - 1) % 3; // 0, 1, 2 열

    // 3개 타일의 전체 너비 계산
    final double totalWidth = (tileSize * 3) + (horizontalSpacing * 2);
    final double startX = centerX - totalWidth / 2 + tileSize / 2;

    final double x = startX + (col * (tileSize + horizontalSpacing));
    final double y = topMargin + (row * (tileSize + verticalSpacing)) + tileSize / 2;

    return Offset(x, y);
  }

  Rect _roundNodeRect(int roundIndex) {
    final center = _roundNodeCenter(roundIndex);
    const double tileSize = 70.0;
    return Rect.fromCenter(center: center, width: tileSize, height: tileSize);
  }

  // God Mode 버튼 Rect (우측 하단, 메뉴 바로 위)
  Rect _godModeButtonRect() {
    const double width = 70;
    const double height = 30;
    final double x = size.x - width - 10;
    final double y = size.y - _bottomMenuHeight - height - 10;
    return Rect.fromLTWH(x, y, width, height);
  }

  // 왼쪽 스테이지 변경 버튼 Rect
  Rect _leftStageButtonRect() {
    const double width = 35.0;
    const double height = 35.0;
    const double x = 15.0;
    const double navBarHeight = 60.0;
    const double titleBoxHeight = 50.0;
    final double y = navBarHeight + (titleBoxHeight - height) / 2; // 타이틀 박스 중앙
    return Rect.fromLTWH(x, y, width, height);
  }

  // 오른쪽 스테이지 변경 버튼 Rect
  Rect _rightStageButtonRect() {
    const double width = 35.0;
    const double height = 35.0;
    final double x = size.x - width - 15;
    const double navBarHeight = 60.0;
    const double titleBoxHeight = 50.0;
    final double y = navBarHeight + (titleBoxHeight - height) / 2; // 타이틀 박스 중앙
    return Rect.fromLTWH(x, y, width, height);
  }

  // God Mode 토글 함수
  void _toggleGodMode() {
    _godModeEnabled = !_godModeEnabled;

    if (_godModeEnabled) {
      // 모든 라운드 언락
      unlockedRoundMax = 10;

      // 모든 캐릭터 슬롯 활성화 및 스킬 준비 완료
      for (var slot in characterSlots) {
        slot.hasCharacter = true;
        slot.skillReady = true;
      }

      // 무한 리소스
      playerGold = 999999;
      playerGem = 999999;
      playerEnergy = playerMaxEnergy;
    }
    // God Mode를 끄면 원래 상태로 돌아가는 것은 구현하지 않음
    // (테스트 목적이므로 한번 켜면 계속 유지)
  }

  // -----------------------------
  // 하단 메뉴 버튼 Rect
  // -----------------------------
  static const double _bottomMenuHeight = 70.0;
  static const double _bottomMenuIconSize = 30.0;

  Rect _bottomMenuRect() {
    return Rect.fromLTWH(0, size.y - _bottomMenuHeight, size.x, _bottomMenuHeight);
  }

  Rect _bottomMenuButtonRect(int index) {
    const int totalButtons = 5;
    final buttonWidth = size.x / totalButtons;
    final x = index * buttonWidth;
    final y = size.y - _bottomMenuHeight;
    return Rect.fromLTWH(x, y, buttonWidth, _bottomMenuHeight);
  }

  // -----------------------------
  // 렌더링
  // -----------------------------
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) return;

    // 라운드 선택 맵: 게임 플레이 화면 없이 흰 배경 + 맵만
    if (gameState == GameState.roundSelect) {
      _renderRoundSelectBackground(canvas);
      _renderRoundSelectOverlay(canvas);
      return;
    }

    // 로딩 화면: 순수 검은 배경
    if (gameState == GameState.loading) {
      _renderLoadingScreen(canvas);
      return;
    }

    // 나머지(플레이, 일시정지, 결과)는 게임 배경 + 성/몬스터 + 오버레이
    _renderBackground(canvas);
    _renderCastle(canvas);
    _renderMonsters(canvas);
    _renderStageProgress(canvas);
    _renderWeaponInfo(canvas);

    // 플레이 중에만 일시정지 버튼 표시
    if (gameState == GameState.playing) {
      _renderPauseButton(canvas);
    }

    _renderGameStateOverlay(canvas);
  }

  void _renderBackground(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF202020);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
  }

  void _renderRoundSelectBackground(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
  }

  void _renderLoadingScreen(Canvas canvas) {
    // 완전 검은 배경
    final paint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
    _renderLoadingOverlay(canvas);
  }

  Rect get _castleRect =>
      Rect.fromLTWH(0, size.y - castleHeight, size.x, castleHeight);

  void _renderCastle(Canvas canvas) {
    final castlePaint = Paint()..color = const Color(0xFF424242);
    canvas.drawRect(_castleRect, castlePaint);

    // 캐릭터 슬롯 렌더링 (성 위에 배치)
    _renderCharacterSlots(canvas);

    const double hpBarHeight = 8.0;
    const double hpBarMargin = 4.0;
    final double hpRatio = castleMaxHp == 0 ? 0 : castleHp / castleMaxHp;

    final hpBarWidth = size.x * 0.6;
    final hpBarX = (size.x - hpBarWidth) / 2;
    final hpBarY = _castleRect.top - hpBarHeight - hpBarMargin;

    final hpBgPaint = Paint()..color = const Color(0xFF555555);
    final hpFgPaint = Paint()..color = const Color(0xFF66BB6A);

    final bgRect = Rect.fromLTWH(hpBarX, hpBarY, hpBarWidth, hpBarHeight);
    canvas.drawRect(bgRect, hpBgPaint);

    final fgRect = Rect.fromLTWH(
      hpBarX,
      hpBarY,
      hpBarWidth * hpRatio.clamp(0.0, 1.0),
      hpBarHeight,
    );
    canvas.drawRect(fgRect, hpFgPaint);

    _drawCenteredText(
      canvas,
      'Castle HP: $castleHp / $castleMaxHp',
      Offset(size.x / 2, hpBarY - 14),
      fontSize: 14,
      color: const Color(0xFFFFFFFF),
    );
  }

  // 캐릭터 슬롯 렌더링
  void _renderCharacterSlots(Canvas canvas) {
    for (int i = 0; i < characterSlots.length; i++) {
      final slot = characterSlots[i];
      final rect = _characterSlotRect(i);

      // 슬롯 배경
      final bgPaint = Paint()
        ..color = slot.hasCharacter
            ? const Color(0xFF37474F) // 캐릭터 있음: 어두운 청회색
            : const Color(0xFF212121); // 캐릭터 없음 (잠금): 매우 어두운 회색

      final borderPaint = Paint()
        ..color = slot.hasCharacter
            ? (slot.skillReady
                ? const Color(0xFF00E676) // 스킬 준비 완료: 초록색
                : const Color(0xFF90A4AE)) // 스킬 쿨다운 중: 회색
            : const Color(0xFF424242) // 캐릭터 없음: 어두운 회색
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(rect, bgPaint);
      canvas.drawRect(rect, borderPaint);

      // 슬롯 내용
      if (slot.hasCharacter) {
        // 캐릭터 아이콘 (프로토타입: 이모지)
        _drawCenteredText(
          canvas,
          '🛡️',
          Offset(rect.center.dx, rect.center.dy - 8),
          fontSize: 24,
          color: const Color(0xFFFFFFFF),
        );

        // 스킬 준비 상태 표시
        if (slot.skillReady) {
          _drawCenteredText(
            canvas,
            '✨',
            Offset(rect.center.dx, rect.bottom - 12),
            fontSize: 12,
            color: const Color(0xFF00E676),
          );
        }
      } else {
        // 캐릭터 없음: 자물쇠 아이콘 (잠금 상태)
        _drawCenteredText(
          canvas,
          '🔒',
          Offset(rect.center.dx, rect.center.dy),
          fontSize: 20,
          color: const Color(0xFF616161),
        );
      }
    }
  }

  void _renderMonsters(Canvas canvas) {
    const double hpBarWidth = 24.0;
    const double hpBarHeight = 4.0;
    const double hpBarMargin = 4.0;

    for (final m in monsters) {
      final center = Offset(m.pos.x, m.pos.y);

      // 몬스터 타입별 색상 및 크기
      Color monsterColor;
      double radius;
      switch (m.type) {
        case MonsterType.boss:
          monsterColor = const Color(0xFFFF5252); // 빨강 (보스)
          radius = monsterRadius * 2.0;
          break;
        case MonsterType.miniBoss:
          monsterColor = const Color(0xFFFF6E40); // 주황 (부보스)
          radius = monsterRadius * 1.5;
          break;
        case MonsterType.normal:
        default:
          monsterColor = const Color(0xFFFFD54F); // 노랑 (일반)
          radius = monsterRadius;
          break;
      }

      final monsterPaint = Paint()..color = monsterColor;
      canvas.drawCircle(center, radius, monsterPaint);

      final ratio = m.maxHp == 0 ? 0 : m.hp / m.maxHp;

      final hpBarX = center.dx - hpBarWidth / 2;
      final hpBarY = center.dy - radius - hpBarHeight - hpBarMargin;

      final bgPaint = Paint()..color = const Color(0xFF555555);
      final fgPaint = Paint()..color = const Color(0xFFEF5350);

      final bgRect = Rect.fromLTWH(hpBarX, hpBarY, hpBarWidth, hpBarHeight);
      canvas.drawRect(bgRect, bgPaint);

      final fgRect = Rect.fromLTWH(
        hpBarX,
        hpBarY,
        hpBarWidth * ratio.clamp(0.0, 1.0),
        hpBarHeight,
      );
      canvas.drawRect(fgRect, fgPaint);

      _drawCenteredText(
        canvas,
        '${m.hp}/${m.maxHp}',
        Offset(center.dx, hpBarY - 10),
        fontSize: 10,
        color: const Color(0xFFFFFFFF),
      );
    }
  }

  void _renderStageProgress(Canvas canvas) {
    const double marginTop = 15.0;
    const double marginSide = 20.0;

    final total = totalMonstersInRound;
    final remaining = total - (defeatedMonsters + escapedMonsters);

    // 왼쪽: 남은 적 카운트 (숫자만)
    final monsterColor = remaining <= 3
        ? const Color(0xFFFF5252) // 3마리 이하면 빨간색
        : const Color(0xFFFFFFFF);

    _drawCenteredText(
      canvas,
      '👾 $remaining',
      Offset(marginSide + 30, marginTop),
      fontSize: 20,
      color: monsterColor,
    );

    // 중앙: 카운트다운 타이머
    final remainingTime = (roundTimeLimit - roundTimer).clamp(0.0, roundTimeLimit);
    final minutes = (remainingTime ~/ 60);
    final seconds = (remainingTime % 60).toInt();
    final timeText = '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';

    final timeColor = remainingTime <= 30
        ? const Color(0xFFFF5252) // 30초 이하면 빨간색
        : const Color(0xFFFFFFFF);

    _drawCenteredText(
      canvas,
      timeText,
      Offset(size.x / 2, marginTop),
      fontSize: 24,
      color: timeColor,
    );

    // 오른쪽: 스테이지-라운드 표시
    _drawCenteredText(
      canvas,
      '$stageLevel-$currentRound',
      Offset(size.x - marginSide - 30, marginTop),
      fontSize: 20,
      color: const Color(0xFFFFFFFF),
    );

    // 보스 라운드 알림 (상단 정보 아래)
    final cfg = kStageConfigs[stageLevel];
    if (cfg != null && currentRound <= cfg.rounds.length) {
      final roundCfg = cfg.rounds[currentRound - 1];
      if (roundCfg.monsterType == MonsterType.boss) {
        _drawCenteredText(
          canvas,
          '⚔️ BOSS ROUND ⚔️',
          Offset(size.x / 2, marginTop + 30),
          fontSize: 16,
          color: const Color(0xFFFF5252),
        );
      } else if (roundCfg.monsterType == MonsterType.miniBoss) {
        _drawCenteredText(
          canvas,
          '⚡ MINI BOSS ⚡',
          Offset(size.x / 2, marginTop + 30),
          fontSize: 16,
          color: const Color(0xFFFF6E40),
        );
      }
    }
  }

  void _renderWeaponInfo(Canvas canvas) {
    const padding = 8.0;
    const panelWidth = 120.0;
    const panelHeight = 40.0;

    final rect = Rect.fromLTWH(
      padding,
      size.y - castleHeight + padding,
      panelWidth,
      panelHeight,
    );

    final bgPaint = Paint()..color = const Color(0x80212121);
    final borderPaint = Paint()
      ..color = const Color(0x80FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(rect, bgPaint);
    canvas.drawRect(rect, borderPaint);

    final textOffset = Offset(
      rect.left + 8,
      rect.top + 10,
    );

    _drawText(
      canvas,
      '기본검 (DMG: $weaponDamage)',
      textOffset,
      fontSize: 12,
      alignCenter: false,
    );
  }

  void _renderPauseButton(Canvas canvas) {
    final rect = _pauseButtonRect();

    // 배경
    final bgPaint = Paint()..color = const Color(0x80212121);
    final borderPaint = Paint()
      ..color = const Color(0x80FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(6),
    );

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // 일시정지 아이콘 (두 개의 세로 막대) - 작게 조정
    final iconPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    const double barWidth = 4.0;
    const double barHeight = 14.0;
    const double barGap = 4.0;

    final centerX = rect.center.dx;
    final centerY = rect.center.dy;

    // 왼쪽 막대
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - barWidth - barGap / 2,
        centerY - barHeight / 2,
        barWidth,
        barHeight,
      ),
      iconPaint,
    );

    // 오른쪽 막대
    canvas.drawRect(
      Rect.fromLTWH(
        centerX + barGap / 2,
        centerY - barHeight / 2,
        barWidth,
        barHeight,
      ),
      iconPaint,
    );
  }

  // -----------------------------
  // 상태별 오버레이
  // -----------------------------
  void _renderGameStateOverlay(Canvas canvas) {
    if (gameState == GameState.roundClear) {
      _renderRoundClearOverlay(canvas);
    } else if (gameState == GameState.paused) {
      _renderPausedOverlay(canvas);
    } else if (gameState == GameState.result) {
      _renderResultOverlay(canvas);
    }
  }

  void _renderLoadingOverlay(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '준비 중...',
      Offset(size.x / 2, size.y * 0.4),
      fontSize: 20,
      color: const Color(0xFFFFFFFF),
    );

    // 게이지 바
    const double barHeight = 12.0;
    final double barWidth = size.x * 0.6;
    final double barX = (size.x - barWidth) / 2;
    final double barY = size.y * 0.5;

    final double progress = (_loadingTimer / _loadingDuration).clamp(0.0, 1.0);

    final bgPaint = Paint()..color = const Color(0xFF424242);
    final fgPaint = Paint()..color = const Color(0xFF42A5F5);

    final bgRect = Rect.fromLTWH(barX, barY, barWidth, barHeight);
    canvas.drawRect(bgRect, bgPaint);

    final fgRect = Rect.fromLTWH(
      barX,
      barY,
      barWidth * progress,
      barHeight,
    );
    canvas.drawRect(fgRect, fgPaint);
  }

  // 네비게이션 바 렌더링
  void _renderNavigationBar(Canvas canvas) {
    const double navBarHeight = 60.0;
    const double padding = 10.0;

    // 네비게이션 바 배경
    final navBarBg = Paint()..color = const Color(0xFFF5F5F5);
    final navBarRect = Rect.fromLTWH(0, 0, size.x, navBarHeight);
    canvas.drawRect(navBarRect, navBarBg);

    // 하단 경계선
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, navBarHeight),
      Offset(size.x, navBarHeight),
      borderPaint,
    );

    // 왼쪽: 프로필 영역
    const double profileIconSize = 40.0;
    final profileIconRect = Rect.fromLTWH(
      padding,
      (navBarHeight - profileIconSize) / 2,
      profileIconSize,
      profileIconSize,
    );

    // 프로필 아이콘 배경 (원형)
    final profileBgPaint = Paint()..color = const Color(0xFF42A5F5);
    canvas.drawCircle(
      profileIconRect.center,
      profileIconSize / 2,
      profileBgPaint,
    );

    // 프로필 아이콘 (이모지)
    _drawCenteredText(
      canvas,
      '👤',
      profileIconRect.center,
      fontSize: 24,
      color: const Color(0xFFFFFFFF),
    );

    // 닉네임과 레벨을 프로필 오른쪽에 세로로 배치
    final nameX = profileIconRect.right + 8;

    // 닉네임 (위)
    _drawText(
      canvas,
      playerNickname,
      Offset(nameX, navBarHeight / 2 - 14),
      fontSize: 13,
      color: const Color(0xFF000000),
      alignCenter: false,
    );

    // 레벨 (아래)
    _drawText(
      canvas,
      'Lv.$playerLevel',
      Offset(nameX, navBarHeight / 2 + 2),
      fontSize: 11,
      color: const Color(0xFF666666),
      alignCenter: false,
    );

    // 오른쪽: 리소스 영역 (골드, 젬, 에너지를 가로로 나열)
    const double resourceSpacing = 70.0;
    final resourceStartX = size.x - padding - (resourceSpacing * 3) + 10;

    // 골드
    _renderResourceHorizontal(
      canvas,
      Offset(resourceStartX, navBarHeight / 2),
      '💰',
      _formatNumber(playerGold),
    );

    // 젬
    _renderResourceHorizontal(
      canvas,
      Offset(resourceStartX + resourceSpacing, navBarHeight / 2),
      '💎',
      _formatNumber(playerGem),
    );

    // 에너지 (배터리)
    _renderResourceHorizontal(
      canvas,
      Offset(resourceStartX + resourceSpacing * 2, navBarHeight / 2),
      '🔋',
      '$playerEnergy',
    );
  }

  // 숫자 포맷팅 (1000 -> 1K)
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  // 개별 리소스 렌더링 헬퍼 (가로 정렬)
  void _renderResourceHorizontal(
    Canvas canvas,
    Offset position,
    String icon,
    String value,
  ) {
    // 아이콘
    _drawCenteredText(
      canvas,
      icon,
      Offset(position.dx, position.dy - 8),
      fontSize: 16,
      color: const Color(0xFF000000),
    );

    // 값
    _drawCenteredText(
      canvas,
      value,
      Offset(position.dx, position.dy + 8),
      fontSize: 11,
      color: const Color(0xFF424242),
    );
  }

  // 스테이지별 배경 렌더링
  void _renderStageBackground(Canvas canvas, int stage) {
    // 네비게이션 바와 하단 메뉴를 제외한 영역에만 배경 렌더링
    const double navBarHeight = 60.0;
    const double titleBoxHeight = 50.0;
    const double topMargin = navBarHeight + titleBoxHeight; // 110px
    final double backgroundHeight = size.y - topMargin - _bottomMenuHeight;

    final backgroundRect = Rect.fromLTWH(0, topMargin, size.x, backgroundHeight);

    Paint bgPaint;
    String emoji1 = '';
    String emoji2 = '';

    switch (stage) {
      case 1: // 초원 & 산
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF87CEEB), // 하늘색
              const Color(0xFF90EE90), // 연한 초록
            ],
          ).createShader(backgroundRect);
        emoji1 = '🏔️'; // 산
        emoji2 = '🌳'; // 나무
        break;

      case 2: // 협곡
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8B7355), // 갈색
              const Color(0xFF654321), // 어두운 갈색
            ],
          ).createShader(backgroundRect);
        emoji1 = '⛰️'; // 산
        emoji2 = '🪨'; // 바위
        break;

      case 3: // 사막
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFA500), // 주황색
              const Color(0xFFEDC9AF), // 모래색
            ],
          ).createShader(backgroundRect);
        emoji1 = '🏜️'; // 사막
        emoji2 = '🌵'; // 선인장
        break;

      case 4: // 바다
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E90FF), // 파란색
              const Color(0xFF006994), // 진한 파란색
            ],
          ).createShader(backgroundRect);
        emoji1 = '🌊'; // 파도
        emoji2 = '🐚'; // 조개
        break;

      case 5: // 화산
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8B0000), // 어두운 빨강
              const Color(0xFFFF4500), // 주황빨강
            ],
          ).createShader(backgroundRect);
        emoji1 = '🌋'; // 화산
        emoji2 = '🔥'; // 불
        break;

      case 6: // 얼음 성
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFB0E0E6), // 파우더 블루
              const Color(0xFFE0FFFF), // 밝은 청록
            ],
          ).createShader(backgroundRect);
        emoji1 = '🏰'; // 성
        emoji2 = '❄️'; // 눈송이
        break;

      case 7: // 천국
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF), // 흰색
              const Color(0xFFFFD700), // 금색
            ],
          ).createShader(backgroundRect);
        emoji1 = '☁️'; // 구름
        emoji2 = '✨'; // 반짝임
        break;

      case 8: // 지옥
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2B0000), // 매우 어두운 빨강
              const Color(0xFF8B0000), // 어두운 빨강
            ],
          ).createShader(backgroundRect);
        emoji1 = '🔥'; // 불
        emoji2 = '💀'; // 해골
        break;

      default:
        bgPaint = Paint()..color = const Color(0xFFE0E0E0);
        break;
    }

    // 배경 그라데이션 그리기
    canvas.drawRect(backgroundRect, bgPaint);

    // 배경 장식 이모지 그리기 (여러 개 배치)
    if (emoji1.isNotEmpty && emoji2.isNotEmpty) {
      final random = Random(stage); // 스테이지별로 같은 패턴

      // 상단에 이모지1 배치 (타이틀 박스 아래부터)
      for (int i = 0; i < 5; i++) {
        final x = random.nextDouble() * size.x;
        final y = topMargin + 50 + random.nextDouble() * 150;
        _drawCenteredText(
          canvas,
          emoji1,
          Offset(x, y),
          fontSize: 32,
        );
      }

      // 하단에 이모지2 배치 (하단 메뉴 위까지)
      for (int i = 0; i < 5; i++) {
        final x = random.nextDouble() * size.x;
        final y = size.y - _bottomMenuHeight - 150 + random.nextDouble() * 100;
        _drawCenteredText(
          canvas,
          emoji2,
          Offset(x, y),
          fontSize: 28,
        );
      }
    }
  }

  void _renderRoundSelectOverlay(Canvas canvas) {
    // 네비게이션 바 렌더링
    _renderNavigationBar(canvas);

    // 현재 선택된 메뉴에 따라 다른 콘텐츠 렌더링
    switch (currentBottomMenu) {
      case BottomMenu.home:
        _renderHomeContent(canvas);
        break;
      case BottomMenu.shop:
        _renderShopContent(canvas);
        break;
      case BottomMenu.inventory:
        _renderInventoryContent(canvas);
        break;
      case BottomMenu.gacha:
        _renderGachaContent(canvas);
        break;
      case BottomMenu.settings:
        _renderSettingsContent(canvas);
        break;
    }

    // 하단 메뉴 렌더링 (항상 표시)
    _renderBottomMenu(canvas);
  }

  // 홈 콘텐츠 (라운드 선택)
  void _renderHomeContent(Canvas canvas) {
    // 스테이지별 배경 렌더링
    _renderStageBackground(canvas, selectedStageInUI);

    // 스테이지 타이틀 박스 (표 형식)
    const double navBarHeight = 60.0;
    const double titleBoxY = navBarHeight; // 네비게이션 바 바로 아래
    const double titleBoxHeight = 50.0;
    final titleBoxRect = Rect.fromLTWH(0, titleBoxY, size.x, titleBoxHeight);

    // 타이틀 박스 배경 (그라데이션 효과)
    final titleBoxPaint = Paint()..color = const Color(0xFF1976D2);
    canvas.drawRect(titleBoxRect, titleBoxPaint);

    // 타이틀 박스 하단 경계선
    final borderPaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(0, titleBoxY + titleBoxHeight),
      Offset(size.x, titleBoxY + titleBoxHeight),
      borderPaint,
    );

    // 스테이지 정보 텍스트
    _drawCenteredText(
      canvas,
      'STAGE $selectedStageInUI',
      Offset(size.x / 2, titleBoxY + titleBoxHeight / 2 - 2),
      fontSize: 20,
      color: const Color(0xFFFFFFFF),
    );

    // 왼쪽 스테이지 변경 버튼 (화살표 버튼)
    final leftButtonRect = _leftStageButtonRect();
    final leftActive = selectedStageInUI > 1;

    final leftButtonPaint = Paint()
      ..color = leftActive
          ? const Color(0xFFFFFFFF)
          : const Color(0xFFBDBDBD);

    canvas.drawRRect(
      RRect.fromRectAndRadius(leftButtonRect, const Radius.circular(6)),
      leftButtonPaint,
    );

    _drawCenteredText(
      canvas,
      '◀',
      leftButtonRect.center,
      fontSize: 18,
      color: leftActive
          ? const Color(0xFF1976D2)
          : const Color(0xFF757575),
    );

    // 오른쪽 스테이지 변경 버튼
    final rightButtonRect = _rightStageButtonRect();
    final rightActive = selectedStageInUI < 8; // 최대 스테이지 8까지

    final rightButtonPaint = Paint()
      ..color = rightActive
          ? const Color(0xFFFFFFFF)
          : const Color(0xFFBDBDBD);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rightButtonRect, const Radius.circular(6)),
      rightButtonPaint,
    );

    _drawCenteredText(
      canvas,
      '▶',
      rightButtonRect.center,
      fontSize: 18,
      color: rightActive
          ? const Color(0xFF1976D2)
          : const Color(0xFF757575),
    );

    const int total = 10; // 라운드 10개
    final unlocked = unlockedRoundMax.clamp(1, total);

    // 캔디크러쉬 사가 스타일: 사각형 타일 렌더링
    for (int i = 1; i <= total; i++) {
      final rect = _roundNodeRect(i);
      final bool isUnlocked = i <= unlocked;
      final bool isCurrent = i == unlocked;
      final bool isBossRound = i == 10;
      final bool isMiniBossRound = i == 5;

      // 타일 배경색
      Color bgColor;
      if (!isUnlocked) {
        bgColor = const Color(0xFFE0E0E0); // 잠금: 회색
      } else if (isBossRound) {
        bgColor = const Color(0xFFE53935); // 보스: 빨강
      } else if (isMiniBossRound) {
        bgColor = const Color(0xFFFB8C00); // 미니보스: 주황
      } else if (isCurrent) {
        bgColor = const Color(0xFF43A047); // 현재: 초록
      } else {
        bgColor = const Color(0xFF42A5F5); // 완료: 파랑
      }

      // 타일 배경
      final bgPaint = Paint()..color = bgColor;
      final tileBorder = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        bgPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        tileBorder,
      );

      // 타일 내용
      if (isUnlocked) {
        if (isBossRound) {
          // 보스 라운드 (라운드 10): 작은 악마 2개 + 큰 악마 머리 1개
          // 왼쪽 작은 악마
          _drawCenteredText(
            canvas,
            '👿',
            Offset(rect.center.dx - 20, rect.center.dy - 8),
            fontSize: 18,
            color: const Color(0xFFFFFFFF),
          );
          // 중앙 큰 악마 머리
          _drawCenteredText(
            canvas,
            '😈',
            Offset(rect.center.dx, rect.center.dy - 8),
            fontSize: 26,
            color: const Color(0xFFFFFFFF),
          );
          // 오른쪽 작은 악마
          _drawCenteredText(
            canvas,
            '👿',
            Offset(rect.center.dx + 20, rect.center.dy - 8),
            fontSize: 18,
            color: const Color(0xFFFFFFFF),
          );
          // 라운드 번호
          _drawCenteredText(
            canvas,
            '$i',
            Offset(rect.center.dx, rect.center.dy + 18),
            fontSize: 14,
            color: const Color(0xFFFFFFFF),
          );
        } else if (isMiniBossRound) {
          // 미니보스 라운드 (라운드 5): 작은 악마 1개
          _drawCenteredText(
            canvas,
            '👿',
            Offset(rect.center.dx, rect.center.dy - 12),
            fontSize: 28,
            color: const Color(0xFFFFFFFF),
          );
          _drawCenteredText(
            canvas,
            '$i',
            Offset(rect.center.dx, rect.center.dy + 14),
            fontSize: 16,
            color: const Color(0xFFFFFFFF),
          );
        } else {
          // 일반 라운드
          _drawCenteredText(
            canvas,
            '$i',
            rect.center,
            fontSize: 32,
            color: const Color(0xFFFFFFFF),
          );

          // 현재 라운드 표시
          if (isCurrent) {
            // 별 표시 (타일 우측 상단)
            _drawCenteredText(
              canvas,
              '★',
              Offset(rect.right - 12, rect.top + 12),
              fontSize: 14,
              color: const Color(0xFFFFD700),
            );
          }
        }
      } else {
        // 잠금 타일
        _drawCenteredText(
          canvas,
          '🔒',
          rect.center,
          fontSize: 28,
          color: const Color(0xFF9E9E9E),
        );
      }
    }

    // God Mode 버튼 (우측 하단, 메뉴 위)
    final godModeRect = _godModeButtonRect();
    final godModeBgPaint = Paint()
      ..color = _godModeEnabled
          ? const Color(0xFFFFD700) // 활성화: 금색
          : const Color(0xFF757575); // 비활성화: 회색

    canvas.drawRRect(
      RRect.fromRectAndRadius(godModeRect, const Radius.circular(8)),
      godModeBgPaint,
    );

    _drawCenteredText(
      canvas,
      _godModeEnabled ? 'GOD ✓' : 'TEST',
      godModeRect.center,
      fontSize: 12,
      color: _godModeEnabled
          ? const Color(0xFF000000) // 활성화: 검은색 텍스트
          : const Color(0xFFFFFFFF), // 비활성화: 흰색 텍스트
    );
  }

  // 상점 콘텐츠 (플레이스홀더)
  void _renderShopContent(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '🏪 상점',
      Offset(size.x / 2, size.y * 0.4),
      fontSize: 32,
      color: const Color(0xFF000000),
    );

    _drawCenteredText(
      canvas,
      '준비 중...',
      Offset(size.x / 2, size.y * 0.5),
      fontSize: 18,
      color: const Color(0xFF666666),
    );
  }

  // 인벤토리 콘텐츠 (플레이스홀더)
  void _renderInventoryContent(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '🎒 인벤토리',
      Offset(size.x / 2, size.y * 0.4),
      fontSize: 32,
      color: const Color(0xFF000000),
    );

    _drawCenteredText(
      canvas,
      '준비 중...',
      Offset(size.x / 2, size.y * 0.5),
      fontSize: 18,
      color: const Color(0xFF666666),
    );
  }

  // 뽑기 콘텐츠 (플레이스홀더)
  void _renderGachaContent(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '🎰 뽑기',
      Offset(size.x / 2, size.y * 0.4),
      fontSize: 32,
      color: const Color(0xFF000000),
    );

    _drawCenteredText(
      canvas,
      '준비 중...',
      Offset(size.x / 2, size.y * 0.5),
      fontSize: 18,
      color: const Color(0xFF666666),
    );
  }

  // 설정 콘텐츠 (플레이스홀더)
  void _renderSettingsContent(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '⚙️ 설정',
      Offset(size.x / 2, size.y * 0.4),
      fontSize: 32,
      color: const Color(0xFF000000),
    );

    _drawCenteredText(
      canvas,
      '준비 중...',
      Offset(size.x / 2, size.y * 0.5),
      fontSize: 18,
      color: const Color(0xFF666666),
    );
  }

  // 하단 메뉴 렌더링
  void _renderBottomMenu(Canvas canvas) {
    // 메뉴 배경
    final menuBgPaint = Paint()..color = const Color(0xFFFFFFFF);
    final menuRect = Rect.fromLTWH(0, size.y - _bottomMenuHeight, size.x, _bottomMenuHeight);
    canvas.drawRect(menuRect, menuBgPaint);

    // 상단 경계선
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.y - _bottomMenuHeight),
      Offset(size.x, size.y - _bottomMenuHeight),
      borderPaint,
    );

    // 메뉴 아이템들
    final menuItems = [
      {'icon': '🏪', 'label': '상점', 'menu': BottomMenu.shop},
      {'icon': '🎒', 'label': '인벤토리', 'menu': BottomMenu.inventory},
      {'icon': '🏠', 'label': '홈', 'menu': BottomMenu.home},
      {'icon': '🎰', 'label': '뽑기', 'menu': BottomMenu.gacha},
      {'icon': '⚙️', 'label': '설정', 'menu': BottomMenu.settings},
    ];

    for (int i = 0; i < menuItems.length; i++) {
      final item = menuItems[i];
      final rect = _bottomMenuButtonRect(i);
      final isSelected = currentBottomMenu == item['menu'];

      // 선택된 메뉴 배경
      if (isSelected) {
        final selectedBgPaint = Paint()..color = const Color(0xFFE3F2FD);
        canvas.drawRect(rect, selectedBgPaint);
      }

      // 아이콘
      _drawCenteredText(
        canvas,
        item['icon'] as String,
        Offset(rect.center.dx, rect.center.dy - 12),
        fontSize: 24,
        color: isSelected ? const Color(0xFF1976D2) : const Color(0xFF666666),
      );

      // 라벨
      _drawCenteredText(
        canvas,
        item['label'] as String,
        Offset(rect.center.dx, rect.center.dy + 12),
        fontSize: 11,
        color: isSelected ? const Color(0xFF1976D2) : const Color(0xFF666666),
      );
    }
  }

  void _renderRoundClearOverlay(Canvas canvas) {
    // 반투명 오버레이
    final overlayPaint = Paint()..color = const Color(0x80000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      overlayPaint,
    );

    final cfg = kStageConfigs[stageLevel];
    if (cfg != null && currentRound <= cfg.rounds.length) {
      final roundCfg = cfg.rounds[currentRound - 1];

      String title = 'Round $currentRound Clear!';
      Color titleColor = const Color(0xFF00E676);

      if (roundCfg.monsterType == MonsterType.boss) {
        title = '🎉 BOSS DEFEATED! 🎉';
        titleColor = const Color(0xFFFFD700);
      } else if (roundCfg.monsterType == MonsterType.miniBoss) {
        title = '⚡ MINI BOSS DEFEATED! ⚡';
        titleColor = const Color(0xFFFF6E40);
      }

      _drawCenteredText(
        canvas,
        title,
        Offset(size.x / 2, size.y * 0.4),
        fontSize: 28,
        color: titleColor,
      );
    }

    _drawCenteredText(
      canvas,
      '다음 라운드 준비 중...',
      Offset(size.x / 2, size.y * 0.5),
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );
  }

  void _renderPausedOverlay(Canvas canvas) {
    // 반투명 어두운 배경
    final overlayPaint = Paint()..color = const Color(0xC0000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      overlayPaint,
    );

    // 제목
    _drawCenteredText(
      canvas,
      '일시정지',
      Offset(size.x / 2, size.y * 0.35),
      fontSize: 32,
      color: const Color(0xFFFFFFFF),
    );

    // 버튼 그리기
    final resumeRect = _pauseResumeButtonRect();
    final roundSelectRect = _pauseRoundSelectButtonRect();
    final retryRect = _pauseRetryButtonRect();

    final buttonPaint = Paint()..color = const Color(0xFF424242);
    final buttonTextColor = const Color(0xFFFFFFFF);

    // 재개 버튼
    canvas.drawRect(resumeRect, buttonPaint);
    _drawCenteredText(
      canvas,
      '재개',
      Offset(
        resumeRect.left + resumeRect.width / 2,
        resumeRect.top + resumeRect.height / 2 - 8,
      ),
      fontSize: 18,
      color: buttonTextColor,
    );

    // 라운드 선택 버튼
    canvas.drawRect(roundSelectRect, buttonPaint);
    _drawCenteredText(
      canvas,
      '라운드 선택',
      Offset(
        roundSelectRect.left + roundSelectRect.width / 2,
        roundSelectRect.top + roundSelectRect.height / 2 - 8,
      ),
      fontSize: 18,
      color: buttonTextColor,
    );

    // 재시작 버튼
    canvas.drawRect(retryRect, buttonPaint);
    _drawCenteredText(
      canvas,
      '재시작',
      Offset(
        retryRect.left + retryRect.width / 2,
        retryRect.top + retryRect.height / 2 - 8,
      ),
      fontSize: 18,
      color: buttonTextColor,
    );
  }

  void _renderResultOverlay(Canvas canvas) {
    final overlayPaint = Paint()..color = const Color(0xC0000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      overlayPaint,
    );

    // 제목
    final title = _lastStageClear
        ? 'Round $currentRound 클리어!'
        : 'Round $currentRound 실패...';

    final titleColor = _lastStageClear
        ? const Color(0xFF00E676)
        : const Color(0xFFEF5350);

    _drawCenteredText(
      canvas,
      title,
      Offset(size.x / 2, size.y * 0.25),
      fontSize: 28,
      color: titleColor,
    );

    // 별점 표시 (클리어 시에만)
    if (_lastStageClear) {
      final stars = _calculateStars();
      _renderStars(canvas, stars, Offset(size.x / 2, size.y * 0.35));
    }

    // 무찌른 적 수
    _drawCenteredText(
      canvas,
      '무찌른 적: $defeatedMonsters / $totalMonstersInRound',
      Offset(size.x / 2, size.y * 0.45),
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );

    final retryRect = _resultRetryButtonRect();
    final roundSelectRect = _resultRoundSelectButtonRect();
    final nextRect = _resultNextRoundButtonRect();

    _drawButton(canvas, retryRect, '다시하기');
    _drawButton(canvas, roundSelectRect, '라운드 선택');

    // 클리어 시에만 다음 라운드 버튼 표시
    final nextRound = currentRound + 1;
    if (_lastStageClear && nextRound <= totalRoundsInStage) {
      _drawButton(canvas, nextRect, '다음 라운드', enabled: true);
    }
  }

  // 별점 계산 (처치한 몬스터 비율 기준)
  int _calculateStars() {
    if (totalMonstersInRound == 0) return 0;

    final ratio = defeatedMonsters / totalMonstersInRound;

    if (ratio >= 1.0) {
      return 3; // 100%: 별 3개
    } else if (ratio >= 0.7) {
      return 2; // 70% 이상: 별 2개
    } else if (ratio >= 0.4) {
      return 1; // 40% 이상: 별 1개
    } else {
      return 0; // 40% 미만: 별 0개
    }
  }

  // 별 렌더링
  void _renderStars(Canvas canvas, int starCount, Offset center) {
    const double starSize = 30.0;
    const double starSpacing = 45.0;

    final startX = center.dx - starSpacing;

    for (int i = 0; i < 3; i++) {
      final x = startX + (i * starSpacing);
      final starCenter = Offset(x, center.dy);

      if (i < starCount) {
        // 획득한 별 (노란색)
        _drawCenteredText(
          canvas,
          '★',
          starCenter,
          fontSize: starSize,
          color: const Color(0xFFFFD700),
        );
      } else {
        // 획득하지 못한 별 (회색)
        _drawCenteredText(
          canvas,
          '☆',
          starCenter,
          fontSize: starSize,
          color: const Color(0xFF757575),
        );
      }
    }
  }

  // -----------------------------
  // 버튼 / 텍스트 헬퍼
  // -----------------------------
  void _drawButton(
    Canvas canvas,
    Rect rect,
    String label, {
    bool enabled = true,
  }) {
    final bgColor = enabled ? const Color(0xFF3949AB) : const Color(0xFFB0BEC5);

    final bgPaint = Paint()..color = bgColor;
    final borderPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    _drawCenteredText(
      canvas,
      label,
      rect.center,
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center, {
    double fontSize = 16,
    bool multiLine = false,
    Color color = const Color(0xFFFFFFFF),
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: multiLine ? null : 3,
    )..layout();

    final offset = Offset(center.dx - tp.width / 2, center.dy - tp.height / 2);
    tp.paint(canvas, offset);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    double fontSize = 14,
    bool alignCenter = false,
    Color color = const Color(0xFFFFFFFF),
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: alignCenter ? TextAlign.center : TextAlign.left,
      maxLines: 2,
    )..layout();

    Offset drawOffset = offset;
    if (alignCenter) {
      drawOffset = Offset(
        offset.dx - tp.width / 2,
        offset.dy - tp.height / 2,
      );
    }

    tp.paint(canvas, drawOffset);
  }
}
