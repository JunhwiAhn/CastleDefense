// castle_defense_game.dart

import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

enum GameState {
  loading, // 로딩(0.5초 게이지)
  stageSelect, // 스테이지 선택 (맵 스타일)
  playing, // 실제 전투
  result, // 결과 화면 (클리어 or 실패)
}

class StageConfig {
  final int stageLevel;
  final int totalMonsters;
  final int monsterMaxHp;
  final double spawnInterval;

  const StageConfig({
    required this.stageLevel,
    required this.totalMonsters,
    required this.monsterMaxHp,
    required this.spawnInterval,
  });
}

// 스테이지별 설정
const Map<int, StageConfig> kStageConfigs = {
  1: StageConfig(
    stageLevel: 1,
    totalMonsters: 10,
    monsterMaxHp: 2,
    spawnInterval: 0.5,
  ),
  2: StageConfig(
    stageLevel: 2,
    totalMonsters: 15,
    monsterMaxHp: 2,
    spawnInterval: 0.5,
  ),
  3: StageConfig(
    stageLevel: 3,
    totalMonsters: 20,
    monsterMaxHp: 3,
    spawnInterval: 0.4,
  ),
  4: StageConfig(
    stageLevel: 4,
    totalMonsters: 25,
    monsterMaxHp: 3,
    spawnInterval: 0.3,
  ),
};

class _Monster {
  Vector2 pos;
  int hp;
  bool falling;
  bool walking;

  _Monster({
    required this.pos,
    required this.hp,
    required this.falling,
    required this.walking,
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
  int monsterMaxHp = 2; // 스테이지 설정에 의해 변경됨

  // 무기 (프로토타입)
  final int weaponDamage = 1; // 기본검 데미지

  // 스테이지 & 스폰 관련
  GameState gameState = GameState.loading;
  int stageLevel = 1;
  int totalMonstersInStage = 10;
  int spawnedMonsters = 0;
  int defeatedMonsters = 0;

  double spawnTimer = 0.0;

  // 로딩 화면용
  double _loadingTimer = 0.0;
  final double _loadingDuration = 0.5; // 초 단위

  // 스테이지 언락 상태
  int unlockedStageMax = 1; // 처음엔 스테이지 1만 선택 가능

  // 결과 화면용 정보
  bool _lastStageClear = false;
  int _lastStageLevel = 1;

  // 몬스터 리스트
  final List<_Monster> monsters = [];

  // 랜덤
  final Random _random = Random();

  int get killedMonsters => defeatedMonsters;

  int get maxStageLevel {
    if (kStageConfigs.isEmpty) return 1;
    return kStageConfigs.keys.reduce(max);
  }

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
    totalMonstersInStage = cfg.totalMonsters;
    monsterMaxHp = cfg.monsterMaxHp;

    spawnedMonsters = 0;
    defeatedMonsters = 0;
    spawnTimer = 0.0;
    castleHp = castleMaxHp;

    monsters.clear();
  }

  void _startStage(int level) {
    _loadStage(level);
    gameState = GameState.playing;
  }

  void _goToStageSelect() {
    monsters.clear();
    gameState = GameState.stageSelect;
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
      case GameState.stageSelect:
        return;
      case GameState.playing:
        _updatePlaying(dt);
        return;
      case GameState.result:
        return;
    }
  }

  void _updateLoading(double dt) {
    _loadingTimer += dt;
    if (_loadingTimer >= _loadingDuration) {
      _loadingTimer = 0.0;
      _goToStageSelect();
    }
  }

  void _updatePlaying(double dt) {
    if (size.x <= 0 || size.y <= 0) return;

    _updateMonsters(dt);

    if (spawnedMonsters < totalMonstersInStage) {
      spawnTimer += dt;
      final cfg = kStageConfigs[stageLevel] ?? kStageConfigs[1]!;
      if (spawnTimer >= cfg.spawnInterval) {
        spawnTimer = 0.0;
        _spawnMonster();
      }
    }

    if (castleHp <= 0 && gameState == GameState.playing) {
      _onGameOver();
      return;
    }

    if (defeatedMonsters >= totalMonstersInStage && monsters.isEmpty) {
      _onStageClear();
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

    final x =
        monsterRadius + _random.nextDouble() * (size.x - monsterRadius * 2);
    final y = -monsterRadius * 2;

    monsters.add(
      _Monster(
        pos: Vector2(x, y),
        hp: monsterMaxHp,
        falling: true,
        walking: false,
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
    return dist2 <= monsterRadius * monsterRadius;
  }

  // -----------------------------
  // 상태 전환 (클리어/게임오버 → 결과 화면)
  // -----------------------------
  void _onStageClear() {
    if (gameState != GameState.playing) return;

    _lastStageClear = true;
    _lastStageLevel = stageLevel;

    if (stageLevel >= unlockedStageMax && stageLevel < maxStageLevel) {
      unlockedStageMax = stageLevel + 1;
    }

    gameState = GameState.result;
  }

  void _onGameOver() {
    if (gameState != GameState.playing) return;

    _lastStageClear = false;
    _lastStageLevel = stageLevel;

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
      case GameState.stageSelect:
        _handleTapInStageSelect(pos);
        break;
      case GameState.playing:
        _handleTapInPlaying(pos);
        break;
      case GameState.result:
        _handleTapInResult(pos);
        break;
    }

    super.onTapDown(event);
  }

  // 스테이지 선택 화면: 맵 위 스테이지 노드 터치
  void _handleTapInStageSelect(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);
    final total = maxStageLevel;
    final unlocked = unlockedStageMax.clamp(1, maxStageLevel);

    for (int i = 1; i <= total; i++) {
      final rect = _stageNodeRect(i);
      if (rect.contains(offset)) {
        if (i <= unlocked) {
          _startStage(i);
        }
        break;
      }
    }
  }

  // 플레이 중: 몬스터 공격
  void _handleTapInPlaying(Vector2 tapPos) {
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

  // 결과 화면: "다시하기 / 스테이지 선택 / 다음 스테이지"
  void _handleTapInResult(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);

    final retryRect = _resultRetryButtonRect();
    final stageSelectRect = _resultStageSelectButtonRect();
    final nextRect = _resultNextStageButtonRect();

    if (retryRect.contains(offset)) {
      _startStage(_lastStageLevel);
      return;
    }

    if (stageSelectRect.contains(offset)) {
      _goToStageSelect();
      return;
    }

    final nextLevel = _lastStageLevel + 1;
    final canGoNext = _lastStageClear &&
        nextLevel <= maxStageLevel &&
        kStageConfigs.containsKey(nextLevel);

    if (canGoNext && nextRect.contains(offset)) {
      if (nextLevel > unlockedStageMax) {
        unlockedStageMax = nextLevel;
      }
      _startStage(nextLevel);
    }
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

  Rect _resultStageSelectButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.55 + 52;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _resultNextStageButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.55 + 52 * 2;
    return Rect.fromLTWH(x, y, width, height);
  }

  // -----------------------------
  // 맵 스타일 스테이지 노드 위치 계산
  // -----------------------------
  static const double _nodeRadius = 26.0;

  Offset _stageNodeCenter(int stageIndex) {
    final double topMargin = size.y * 0.25;
    final double bottomMargin = size.y * 0.15;
    final double usableHeight = size.y - topMargin - bottomMargin;

    final int total = maxStageLevel;
    if (total <= 1) {
      return Offset(size.x / 2, size.y * 0.6);
    }

    final double t = (stageIndex - 1) / (total - 1);
    final double y = topMargin + usableHeight * (1.0 - t);

    final int row = stageIndex - 1;
    final bool leftSide = row.isOdd;
    final double centerX = size.x * 0.5;
    final double offsetX = size.x * 0.22;

    final double x = leftSide ? (centerX - offsetX) : (centerX + offsetX);

    return Offset(x, y);
  }

  Rect _stageNodeRect(int stageIndex) {
    final center = _stageNodeCenter(stageIndex);
    return Rect.fromCircle(center: center, radius: _nodeRadius);
  }

  // -----------------------------
  // 렌더링
  // -----------------------------
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) return;

    // 스테이지 맵: 게임 플레이 화면 없이 흰 배경 + 맵만
    if (gameState == GameState.stageSelect) {
      _renderStageSelectBackground(canvas);
      _renderStageSelectOverlay(canvas);
      return;
    }

    // 로딩 화면: 순수 검은 배경
    if (gameState == GameState.loading) {
      _renderLoadingScreen(canvas);
      return;
    }

    // 나머지(플레이, 결과)는 게임 배경 + 성/몬스터 + 오버레이
    _renderBackground(canvas);
    _renderCastle(canvas);
    _renderMonsters(canvas);
    _renderStageProgress(canvas);
    _renderWeaponInfo(canvas);

    _renderGameStateOverlay(canvas);
  }

  void _renderBackground(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF202020);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
  }

  void _renderStageSelectBackground(Canvas canvas) {
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
    final monsterPaint = Paint()..color = const Color(0xFFFFD54F);
    const double hpBarWidth = 24.0;
    const double hpBarHeight = 4.0;
    const double hpBarMargin = 4.0;

    for (final m in monsters) {
      final center = Offset(m.pos.x, m.pos.y);

      canvas.drawCircle(center, monsterRadius, monsterPaint);

      final ratio = monsterMaxHp == 0 ? 0 : m.hp / monsterMaxHp;

      final hpBarX = center.dx - hpBarWidth / 2;
      final hpBarY = center.dy - monsterRadius - hpBarHeight - hpBarMargin;

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
        '${m.hp}/${monsterMaxHp}',
        Offset(center.dx, hpBarY - 10),
        fontSize: 10,
        color: const Color(0xFFFFFFFF),
      );
    }
  }

  void _renderStageProgress(Canvas canvas) {
    const double barHeight = 10.0;
    const double marginTop = 10.0;

    final killed = killedMonsters;
    final total = totalMonstersInStage;
    final ratio = (total == 0) ? 0.0 : killed / total;

    final barWidth = size.x * 0.7;
    final barX = (size.x - barWidth) / 2;
    final barY = marginTop;

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
  }

  void _renderWeaponInfo(Canvas canvas) {
    final padding = 8.0;
    final panelWidth = 120.0;
    final panelHeight = 40.0;

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

  // -----------------------------
  // 상태별 오버레이 (지금은 결과 화면만)
  // -----------------------------
  void _renderGameStateOverlay(Canvas canvas) {
    if (gameState == GameState.result) {
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

  void _renderStageSelectOverlay(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '스테이지 맵',
      Offset(size.x / 2, size.y * 0.12),
      fontSize: 24,
      color: const Color(0xFF000000),
    );

    final total = maxStageLevel;
    final unlocked = unlockedStageMax.clamp(1, maxStageLevel);

    // 연결선
    final pathPaint = Paint()
      ..color = const Color(0xFF90CAF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < total; i++) {
      final from = _stageNodeCenter(i);
      final to = _stageNodeCenter(i + 1);

      final isLockedPath = i >= unlocked;
      pathPaint.color =
          isLockedPath ? const Color(0xFFCCCCCC) : const Color(0xFF90CAF9);

      canvas.drawLine(from, to, pathPaint);
    }

    // 노드
    for (int i = 1; i <= total; i++) {
      final center = _stageNodeCenter(i);
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
        _drawCenteredText(
          canvas,
          '$i',
          center.translate(0, -4),
          fontSize: 18,
          color: const Color(0xFFFFFFFF),
        );
        if (isCurrent) {
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
      '스테이지 버블을 탭해서 시작',
      Offset(size.x / 2, size.y * 0.88),
      fontSize: 14,
      color: const Color(0xFF000000),
    );
  }

  void _renderResultOverlay(Canvas canvas) {
    final overlayPaint = Paint()..color = const Color(0xC0000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      overlayPaint,
    );

    final title = _lastStageClear
        ? 'Stage $_lastStageLevel 클리어!'
        : 'Stage $_lastStageLevel 실패...';

    _drawCenteredText(
      canvas,
      title,
      Offset(size.x / 2, size.y * 0.32),
      fontSize: 24,
      color: const Color(0xFFFFFFFF),
    );

    _drawCenteredText(
      canvas,
      '쓰러뜨린 몬스터: $defeatedMonsters / $totalMonstersInStage',
      Offset(size.x / 2, size.y * 0.40),
      fontSize: 14,
      color: const Color(0xFFFFFFFF),
    );

    final retryRect = _resultRetryButtonRect();
    final stageSelectRect = _resultStageSelectButtonRect();
    final nextRect = _resultNextStageButtonRect();

    _drawButton(canvas, retryRect, '다시하기');
    _drawButton(canvas, stageSelectRect, '스테이지 선택');

    final nextLevel = _lastStageLevel + 1;
    final canGoNext = _lastStageClear &&
        nextLevel <= maxStageLevel &&
        kStageConfigs.containsKey(nextLevel);

    _drawButton(
      canvas,
      nextRect,
      '다음 스테이지',
      enabled: canGoNext,
    );
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
