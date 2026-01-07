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
    if (i == 5) {
      // 라운드 5: 부보스
      rounds.add(RoundConfig(
        roundNumber: i,
        totalMonsters: 1,
        monsterMaxHp: _getMiniBossHp(stageLevel),
        spawnInterval: 1.0,
        monsterType: MonsterType.miniBoss,
      ));
    } else if (i == 10) {
      // 라운드 10: 보스
      rounds.add(RoundConfig(
        roundNumber: i,
        totalMonsters: 1,
        monsterMaxHp: _getBossHp(stageLevel),
        spawnInterval: 1.0,
        monsterType: MonsterType.boss,
      ));
    } else {
      // 일반 라운드
      rounds.add(RoundConfig(
        roundNumber: i,
        totalMonsters: _getRoundMonsterCount(stageLevel, i),
        monsterMaxHp: _getNormalMonsterHp(stageLevel),
        spawnInterval: _getSpawnInterval(stageLevel),
        monsterType: MonsterType.normal,
      ));
    }
  }

  return rounds;
}

// 스테이지별 일반 몬스터 수
int _getRoundMonsterCount(int stageLevel, int roundNumber) {
  final baseCount = 5 + stageLevel;
  // 후반 라운드일수록 약간 더 많이
  return baseCount + (roundNumber >= 6 && roundNumber <= 9 ? 2 : 0);
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

class CastleDefenseGame extends FlameGame with TapCallbacks {
  // -----------------------------
  // 기본 설정
  // -----------------------------
  final double castleHeight = 40.0;
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
  int defeatedMonsters = 0; // 현재 라운드에서 처치한 몬스터 수

  int monsterMaxHp = 2; // 현재 라운드 몬스터 최대 HP
  double spawnTimer = 0.0;

  // 로딩 화면용
  double _loadingTimer = 0.0;
  final double _loadingDuration = 0.5; // 초 단위

  // 라운드 클리어 대기용
  double _roundClearTimer = 0.0;
  final double _roundClearDuration = 2.0; // 2초 대기

  // 라운드 언락 상태
  int unlockedRoundMax = 1; // 처음엔 라운드 1만 선택 가능

  // 결과 화면용 정보
  bool _lastStageClear = false;

  // 몬스터 리스트
  final List<_Monster> monsters = [];

  // 랜덤
  final Random _random = Random();

  int get killedMonsters => defeatedMonsters;

  // -----------------------------
  // 라이프사이클
  // -----------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loadStage(1); // 내부 파라미터 초기화
    gameState = GameState.loading; // GameScreen 진입 즉시 로딩부터 시작
    _loadingTimer = 0.0;
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
    spawnTimer = 0.0;

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

  void _updateLoading(double dt) {
    _loadingTimer += dt;
    if (_loadingTimer >= _loadingDuration) {
      _loadingTimer = 0.0;
      _goToRoundSelect();
    }
  }

  void _updatePlaying(double dt) {
    if (size.x <= 0 || size.y <= 0) return;

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

    // 라운드 클리어 체크: 모든 몬스터를 처치했고 화면에 몬스터가 없을 때
    if (defeatedMonsters >= totalMonstersInRound && monsters.isEmpty) {
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
          castleHp = max(0, castleHp - 1);
          monsters.removeAt(i);
          defeatedMonsters++;
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

    monsters.add(
      _Monster(
        pos: Vector2(x, y),
        hp: monsterMaxHp,
        maxHp: monsterMaxHp,
        falling: true,
        walking: false,
        type: roundCfg.monsterType,
      ),
    );
    spawnedMonsters++;
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

  // 특정 라운드부터 시작
  void _startRound(int roundNumber) {
    _loadStage(1); // 스테이지는 항상 1
    _loadRound(roundNumber);
    gameState = GameState.playing;
  }

  // 플레이 중: 몬스터 공격 또는 일시정지 버튼
  void _handleTapInPlaying(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);

    // 일시정지 버튼 체크 (우측 상단)
    final pauseButtonRect = _pauseButtonRect();
    if (pauseButtonRect.contains(offset)) {
      gameState = GameState.paused;
      return;
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
    const double size = 50.0;
    final double x = this.size.x - size - 10;
    const double y = 10.0;
    return Rect.fromLTWH(x, y, size, size);
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
  // 맵 스타일 라운드 노드 위치 계산
  // -----------------------------
  static const double _nodeRadius = 26.0;

  Offset _roundNodeCenter(int roundIndex) {
    final double topMargin = size.y * 0.20;
    final double bottomMargin = size.y * 0.15;
    final double usableHeight = size.y - topMargin - bottomMargin;

    const int total = 10; // 라운드 10개
    if (total <= 1) {
      return Offset(size.x / 2, size.y * 0.6);
    }

    final double t = (roundIndex - 1) / (total - 1);
    final double y = topMargin + usableHeight * (1.0 - t);

    final int row = roundIndex - 1;
    final bool leftSide = row.isOdd;
    final double centerX = size.x * 0.5;
    final double offsetX = size.x * 0.22;

    final double x = leftSide ? (centerX - offsetX) : (centerX + offsetX);

    return Offset(x, y);
  }

  Rect _roundNodeRect(int roundIndex) {
    final center = _roundNodeCenter(roundIndex);
    return Rect.fromCircle(center: center, radius: _nodeRadius);
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
    const double barHeight = 10.0;
    const double marginTop = 10.0;

    // 라운드 정보 표시
    _drawCenteredText(
      canvas,
      'Round $currentRound / $totalRoundsInStage',
      Offset(size.x / 2, marginTop),
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );

    // 현재 라운드의 진행 게이지
    final killed = defeatedMonsters;
    final total = totalMonstersInRound;
    final ratio = (total == 0) ? 0.0 : killed / total;

    final barWidth = size.x * 0.7;
    final barX = (size.x - barWidth) / 2;
    final barY = marginTop + 24;

    final bgPaint = Paint()..color = const Color(0xFF555555);
    final fgPaint = Paint()..color = const Color(0xFF42A5F5);

    final bgRect = Rect.fromLTWH(barX, barY, barWidth, barHeight);
    canvas.drawRect(bgRect, bgPaint);

    final fgRect = Rect.fromLTWH(
      barX,
      barY,
      barWidth * ratio.clamp(0.0, 1.0),
      barHeight,
    );
    canvas.drawRect(fgRect, fgPaint);

    _drawCenteredText(
      canvas,
      '$killed / $total',
      Offset(size.x / 2, barY + barHeight + 14),
      fontSize: 14,
      color: const Color(0xFFFFFFFF),
    );

    // 보스 라운드 알림
    final cfg = kStageConfigs[stageLevel];
    if (cfg != null && currentRound <= cfg.rounds.length) {
      final roundCfg = cfg.rounds[currentRound - 1];
      if (roundCfg.monsterType == MonsterType.boss) {
        _drawCenteredText(
          canvas,
          '⚔️ BOSS ROUND ⚔️',
          Offset(size.x / 2, barY + barHeight + 38),
          fontSize: 16,
          color: const Color(0xFFFF5252),
        );
      } else if (roundCfg.monsterType == MonsterType.miniBoss) {
        _drawCenteredText(
          canvas,
          '⚡ MINI BOSS ⚡',
          Offset(size.x / 2, barY + barHeight + 38),
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
      ..strokeWidth = 2.0;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // 일시정지 아이콘 (두 개의 세로 막대)
    final iconPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    const double barWidth = 6.0;
    const double barHeight = 20.0;
    const double barGap = 6.0;

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

  void _renderRoundSelectOverlay(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '라운드 선택',
      Offset(size.x / 2, size.y * 0.12),
      fontSize: 24,
      color: const Color(0xFF000000),
    );

    const int total = 10; // 라운드 10개
    final unlocked = unlockedRoundMax.clamp(1, total);

    // 연결선
    final pathPaint = Paint()
      ..color = const Color(0xFF90CAF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < total; i++) {
      final from = _roundNodeCenter(i);
      final to = _roundNodeCenter(i + 1);

      final isLockedPath = i >= unlocked;
      pathPaint.color =
          isLockedPath ? const Color(0xFFCCCCCC) : const Color(0xFF90CAF9);

      canvas.drawLine(from, to, pathPaint);
    }

    // 노드
    for (int i = 1; i <= total; i++) {
      final center = _roundNodeCenter(i);
      final bool isUnlocked = i <= unlocked;
      final bool isCurrent = i == unlocked;

      final baseColor = isUnlocked
          ? (isCurrent ? const Color(0xFF00C853) : const Color(0xFF26A69A))
          : const Color(0xFFBDBDBD);

      final bgPaint = Paint()..color = baseColor;
      final borderPaint = Paint()
        ..color = isUnlocked ? const Color(0xFFFFFFFF) : const Color(0xFF9E9E9E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 3.0 : 2.0;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromCircle(center: center, radius: _nodeRadius),
        const Radius.circular(30),
      );

      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(rrect, borderPaint);

      if (isUnlocked) {
        // 라운드 번호
        _drawCenteredText(
          canvas,
          '$i',
          center.translate(0, -4),
          fontSize: 18,
          color: const Color(0xFFFFFFFF),
        );

        // 보스 라운드 표시
        if (i == 10) {
          _drawCenteredText(
            canvas,
            '⚔️',
            center.translate(0, 14),
            fontSize: 12,
            color: const Color(0xFFFFFFFF),
          );
        } else if (i == 5) {
          _drawCenteredText(
            canvas,
            '⚡',
            center.translate(0, 14),
            fontSize: 12,
            color: const Color(0xFFFFFFFF),
          );
        } else if (isCurrent) {
          _drawCenteredText(
            canvas,
            '★',
            center.translate(0, 14),
            fontSize: 12,
            color: const Color(0xFFFFFFFF),
          );
        }
      } else {
        _drawCenteredText(
          canvas,
          '🔒',
          center,
          fontSize: 18,
          color: const Color(0xFF424242),
        );
      }
    }

    _drawCenteredText(
      canvas,
      '라운드를 탭해서 시작',
      Offset(size.x / 2, size.y * 0.88),
      fontSize: 14,
      color: const Color(0xFF000000),
    );
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
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
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
