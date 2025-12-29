// castle_defense_game.dart

import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

enum GameState {
  title, // 타이틀 화면
  playing, // 전투 중
  stageClear, // 스테이지 클리어
  gameOver, // 성 파괴(HP 0)
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
  GameState gameState = GameState.title;
  int stageLevel = 1;
  int totalMonstersInStage = 10;
  int spawnedMonsters = 0;
  int defeatedMonsters = 0;

  double spawnTimer = 0.0;

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
    _loadStage(1);
    gameState = GameState.title;
  }

  // -----------------------------
  // 스테이지 로딩
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

  // -----------------------------
  // 업데이트 루프
  // -----------------------------
  @override
  void update(double dt) {
    super.update(dt);

    switch (gameState) {
      case GameState.title:
        // 타이틀 화면에서는 논리 업데이트 없음
        return;

      case GameState.playing:
        _updatePlaying(dt);
        return;

      case GameState.stageClear:
        // 필요하면 연출 업데이트
        return;

      case GameState.gameOver:
        // 게임오버 상태
        return;
    }
  }

  void _updatePlaying(double dt) {
    if (size.x <= 0 || size.y <= 0) return;

    // 1) 몬스터 이동/상태 업데이트
    _updateMonsters(dt);

    // 2) 스폰 로직
    if (spawnedMonsters < totalMonstersInStage) {
      spawnTimer += dt;
      final cfg = kStageConfigs[stageLevel] ?? kStageConfigs[1]!;
      if (spawnTimer >= cfg.spawnInterval) {
        spawnTimer = 0.0;
        _spawnMonster();
      }
    }

    // 3) 스테이지 클리어 체크
    if (defeatedMonsters >= totalMonstersInStage && monsters.isEmpty) {
      _onStageClear();
    }

    // 4) 게임오버 체크
    if (castleHp <= 0 && gameState == GameState.playing) {
      _onGameOver();
    }
  }

  // -----------------------------
  // 몬스터 업데이트 / 스폰
  // -----------------------------
  void _updateMonsters(double dt) {
    final groundY = size.y - castleHeight - monsterRadius - 8.0;
    final castleCenterX = size.x / 2;
    const double castleHitWidth = 60.0;

    // 뒤에서부터 순회하면서 제거
    for (var i = monsters.length - 1; i >= 0; i--) {
      final m = monsters[i];

      if (m.falling) {
        // 낙하
        m.pos.y += monsterFallSpeed * dt;
        if (m.pos.y >= groundY) {
          m.pos.y = groundY;
          m.falling = false;
          m.walking = true;
        }
      } else if (m.walking) {
        final dx = castleCenterX - m.pos.x;

        // 성에 도달
        if (dx.abs() < castleHitWidth / 2) {
          castleHp = max(0, castleHp - 1);
          monsters.removeAt(i);
          defeatedMonsters++;
          continue;
        }

        // 성 방향으로 걷기
        final dir = dx == 0 ? 0.0 : dx.sign; // -1 or 1
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
  // 상태 전환
  // -----------------------------
  void _startGame() {
    _loadStage(1);
    gameState = GameState.playing;
  }

  void _goToNextStage() {
    final nextLevel = stageLevel + 1;
    if (!kStageConfigs.containsKey(nextLevel)) {
      _loadStage(1); // 마지막 스테이지 이후에는 1스테이지로 루프
    } else {
      _loadStage(nextLevel);
    }
    gameState = GameState.playing;
  }

  void _restartFromStage1() {
    _loadStage(1);
    gameState = GameState.playing;
  }

  void _onStageClear() {
    if (gameState == GameState.stageClear) return;
    gameState = GameState.stageClear;
  }

  void _onGameOver() {
    if (gameState == GameState.gameOver) return;
    gameState = GameState.gameOver;
  }

  // -----------------------------
  // 입력 처리 (탭)
  // -----------------------------
  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.localPosition;

    switch (gameState) {
      case GameState.title:
        _startGame();
        break;

      case GameState.playing:
        _handleTapInPlaying(pos);
        break;

      case GameState.stageClear:
        _goToNextStage();
        break;

      case GameState.gameOver:
        _restartFromStage1();
        break;
    }

    super.onTapDown(event);
  }

  void _handleTapInPlaying(Vector2 tapPos) {
    for (var i = 0; i < monsters.length; i++) {
      final m = monsters[i];
      if (_isPointInsideMonster(m, tapPos)) {
        m.hp = max(0, m.hp - weaponDamage);
        if (m.hp <= 0) {
          _killMonsterAtIndex(i);
        }
        break; // 한 마리만 처리
      }
    }
  }

  // -----------------------------
  // 렌더링
  // -----------------------------
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) return;

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

  Rect get _castleRect =>
      Rect.fromLTWH(0, size.y - castleHeight, size.x, castleHeight);

  void _renderCastle(Canvas canvas) {
    // 성 바탕
    final castlePaint = Paint()..color = const Color(0xFF424242);
    canvas.drawRect(_castleRect, castlePaint);

    // 성 HP 바
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

    // 성 HP 텍스트
    _drawCenteredText(
      canvas,
      'Castle HP: $castleHp / $castleMaxHp',
      Offset(size.x / 2, hpBarY - 14),
      fontSize: 14,
    );
  }

  void _renderMonsters(Canvas canvas) {
    final monsterPaint = Paint()..color = const Color(0xFFFFD54F);
    const double hpBarWidth = 24.0;
    const double hpBarHeight = 4.0;
    const double hpBarMargin = 4.0;

    for (final m in monsters) {
      final center = Offset(m.pos.x, m.pos.y);

      // 몸통 (원)
      canvas.drawCircle(center, monsterRadius, monsterPaint);

      // HP 비율
      final ratio = monsterMaxHp == 0 ? 0 : m.hp / monsterMaxHp;

      // HP 바 위치
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

      // HP 텍스트 (ex: 1/2)
      _drawCenteredText(
        canvas,
        '${m.hp}/${monsterMaxHp}',
        Offset(center.dx, hpBarY - 10),
        fontSize: 10,
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

    // 텍스트: "killed/total"
    _drawCenteredText(
      canvas,
      '$killed / $total',
      Offset(size.x / 2, barY + barHeight + 14),
      fontSize: 14,
    );
  }

  void _renderWeaponInfo(Canvas canvas) {
    // 성 내부 왼쪽 아래에 작은 패널
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

  void _renderGameStateOverlay(Canvas canvas) {
    String? message;

    switch (gameState) {
      case GameState.title:
        message = 'Castle Defense\n탭해서 게임 시작';
        break;
      case GameState.stageClear:
        message = 'Stage $stageLevel Clear!\n탭해서 다음 스테이지';
        break;
      case GameState.gameOver:
        message = 'Game Over\n탭해서 다시 시작';
        break;
      case GameState.playing:
        break;
    }

    if (message == null) return;

    // 반투명 오버레이 배경
    final overlayPaint = Paint()..color = const Color(0x80000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      overlayPaint,
    );

    _drawCenteredText(
      canvas,
      message,
      Offset(size.x / 2, size.y * 0.4),
      fontSize: 24,
      multiLine: true,
    );
  }

  // -----------------------------
  // 텍스트 헬퍼
  // -----------------------------
  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center, {
    double fontSize = 16,
    bool multiLine = false,
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
      textAlign: TextAlign.center,
      maxLines: multiLine ? null : 1,
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
