// UI 오버레이: HUD, 타워 바, 팝업, 홈, 결과화면, 헬퍼
part of '../castle_defense_game.dart';

extension UIRendering on CastleDefenseGame {

  // ─── 이미지 캐시 헬퍼 ────────────────────────
  Image? _tryGetImage(String path) {
    try { return images.fromCache(path); } catch (_) { return null; }
  }

  void _drawImageIcon(Canvas canvas, String imagePath, Offset center,
      double iconSize, {String fallbackEmoji = '', double alpha = 1.0}) {
    final img = _tryGetImage(imagePath);
    if (img != null) {
      final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = Rect.fromCenter(center: center, width: iconSize, height: iconSize);
      // alpha가 1.0이면 캐시된 Paint 사용
      final p = alpha == 1.0 ? _paintDefault : (Paint()..color = Color.fromRGBO(255, 255, 255, alpha));
      canvas.drawImageRect(img, src, dst, p);
    } else if (fallbackEmoji.isNotEmpty) {
      _drawCenteredText(canvas, fallbackEmoji, center, fontSize: iconSize * 0.7);
    }
  }

  // ─── 텍스트 헬퍼 ─────────────────────────────
  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center, {
    double fontSize = 14,
    Color color = const Color(0xFFFFFFFF),
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    tp.dispose(); // #79: 매 프레임 생성되는 TextPainter 메모리 누수 방지
  }

  // ─── HUD (상단 50px) ──────────────────────────
  void _renderHUD(Canvas canvas) {
    // 배경
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 50),
      Paint()..color = const Color(0xDD0A1A0A));

    // 웨이브 표시
    final waveText = gameState == GameState.prep
        ? 'WAVE ${currentWave + 1} / $totalWavesInStage  준비'
        : 'WAVE $currentWave / $totalWavesInStage';
    _drawCenteredText(canvas, waveText,
        Offset(size.x / 2, 17),
        fontSize: 13, color: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.bold);

    // 골드
    _drawCenteredText(canvas, '🪙 $playerInGameGold',
        Offset(60, 36), fontSize: 13, color: const Color(0xFFFFD700));

    // 별조각
    _drawCenteredText(canvas, '⭐ $playerStarShards',
        Offset(160, 36), fontSize: 13, color: const Color(0xFFFFEE44));

    // 성 HP (하트 아이콘)
    final hpText = '♥ $castleHp / $castleMaxHp';
    _drawCenteredText(canvas, hpText,
        Offset(size.x - 70, 36),
        fontSize: 13, color: const Color(0xFFFF4444));

    // 2배속 버튼
    final speedColor = speedMultiplier > 1.0
        ? const Color(0xFFFFDD00)
        : const Color(0xFF888888);
    _drawCenteredText(canvas, speedMultiplier > 1.0 ? '⏩ 2×' : '▶ 1×',
        Offset(size.x - 22, 17),
        fontSize: 12, color: speedColor);
  }

  // ─── 하단 바 (골드 + 웨이브 시작) ──────────────
  void _renderBottomBar(Canvas canvas) {
    const double barH = 55.0;
    final barY = size.y - barH;

    // 배경
    canvas.drawRect(
      Rect.fromLTWH(0, barY, size.x, barH),
      Paint()..color = const Color(0xEE0A1A0A));
    canvas.drawLine(Offset(0, barY), Offset(size.x, barY),
        Paint()..color = const Color(0xFF336633)..strokeWidth = 1);

    // 골드 표시
    _drawCenteredText(canvas, '🪙 $playerInGameGold',
        Offset(80, barY + barH / 2),
        fontSize: 16, color: const Color(0xFFFFD700),
        fontWeight: FontWeight.bold);

    // 2배속 버튼
    final speedColor = speedMultiplier > 1.0
        ? const Color(0xFFFFDD00)
        : const Color(0xFF888888);
    _drawCenteredText(canvas, speedMultiplier > 1.0 ? '⏩ 2x' : '▶ 1x',
        Offset(size.x / 2, barY + barH / 2),
        fontSize: 14, color: speedColor);

    // 웨이브 시작 버튼 (prep 상태일 때만)
    if (gameState == GameState.prep) {
      _renderWaveStartButton(canvas);
    }
  }

  Rect _waveStartButtonRect() {
    return Rect.fromLTWH(size.x - 110, size.y - 48, 100, 38);
  }

  void _renderWaveStartButton(Canvas canvas) {
    final rect = _waveStartButtonRect();
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF225522));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF44FF44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    _drawCenteredText(canvas, '▶ 시작',
        rect.center, fontSize: 14,
        color: const Color(0xFF44FF44), fontWeight: FontWeight.bold);
  }

  // ─── 타워 팝업 (선택된 타워) ──────────────────
  void _renderTowerPopup(Canvas canvas) {
    final tower = selectedTower;
    if (tower == null) return;

    const double popW = 200.0, popH = 160.0;
    final popX = (tower.pos.x + 30).clamp(0.0, size.x - popW);
    final popY = (tower.pos.y - popH - 10).clamp(50.0, size.y - popH - 110);
    final popRect = Rect.fromLTWH(popX, popY, popW, popH);

    // 배경
    canvas.drawRRect(
      RRect.fromRectAndRadius(popRect, const Radius.circular(10)),
      Paint()..color = const Color(0xEE0D1F0D));
    canvas.drawRRect(
      RRect.fromRectAndRadius(popRect, const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFF44AA44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);

    // 타워 이름
    _drawCenteredText(canvas, tower.displayName,
        Offset(popX + popW / 2, popY + 18),
        fontSize: 13, fontWeight: FontWeight.bold);

    // 스탯
    final dmg = (_applyRaceDamageBonus(tower.damage) * getMachinaAdjacencyBonus(tower)).toStringAsFixed(1);
    final spd = (tower.attackSpeed * getRaceAttackSpeedBonus()).toStringAsFixed(2);
    final rng = (tower.range * getRaceRangeBonus()).toStringAsFixed(0);
    _drawCenteredText(canvas, '⚔️ $dmg  ⏱ ${spd}/s  📏 ${rng}px',
        Offset(popX + popW / 2, popY + 38), fontSize: 10,
        color: const Color(0xFFCCFFCC));

    // 업그레이드 버튼
    if (tower.level < 3) {
      final upgCost = getRaceUpgradeCost(tower);
      final canUpg = playerInGameGold >= upgCost;
      final upgRect = Rect.fromLTWH(popX + 10, popY + 58, popW - 20, 32);
      canvas.drawRRect(
        RRect.fromRectAndRadius(upgRect, const Radius.circular(6)),
        Paint()..color = canUpg ? const Color(0xFF225522) : const Color(0xFF222222));
      canvas.drawRRect(
        RRect.fromRectAndRadius(upgRect, const Radius.circular(6)),
        Paint()
          ..color = canUpg ? const Color(0xFF44FF44) : const Color(0xFF444444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
      _drawCenteredText(canvas, 'Lv${tower.level} → Lv${tower.level + 1}  (${upgCost}g)',
          upgRect.center, fontSize: 12,
          color: canUpg ? const Color(0xFF44FF44) : const Color(0xFF666666));
    } else {
      _drawCenteredText(canvas, '최대 레벨',
          Offset(popX + popW / 2, popY + 74),
          fontSize: 12, color: const Color(0xFFFFD700));
    }

    // 타겟 우선순위
    final priorityLabel = switch (tower.targetPriority) {
      TargetPriority.first     => 'First',
      TargetPriority.strongest => 'Strong',
      TargetPriority.weakest   => 'Weak',
      TargetPriority.closest   => 'Close',
    };
    _drawCenteredText(canvas, '타겟: [$priorityLabel ▼]',
        Offset(popX + popW / 2, popY + 108),
        fontSize: 11, color: const Color(0xFF88CCFF));

    // 철거 버튼
    final sellRect = Rect.fromLTWH(popX + 10, popY + 122, popW - 20, 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sellRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF331111));
    canvas.drawRRect(
      RRect.fromRectAndRadius(sellRect, const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFFFF4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    _drawCenteredText(canvas, '철거 (+${tower.sellValue}g)',
        sellRect.center, fontSize: 11, color: const Color(0xFFFF8888));
  }

  // ─── 웨이브 시작 카운트다운 (3, 2, 1, GO!) ────
  void _renderWaveCountdown(Canvas canvas) {
    // 반투명 오버레이
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0x66000000));

    // 카운트다운 텍스트 결정
    final String text;
    final Color color;
    if (_waveCountdownTimer > 2.0) {
      text = '3';
      color = const Color(0xFF44FF44);
    } else if (_waveCountdownTimer > 1.0) {
      text = '2';
      color = const Color(0xFFFFDD44);
    } else if (_waveCountdownTimer > 0.0) {
      text = '1';
      color = const Color(0xFFFF6644);
    } else {
      text = 'GO!';
      color = const Color(0xFFFF4444);
    }

    // 스케일 애니메이션 (프레임 시작 시 크게 → 작아짐)
    final fraction = _waveCountdownTimer > 0
        ? (_waveCountdownTimer % 1.0)
        : (-_waveCountdownTimer / 0.5).clamp(0.0, 1.0);
    final scale = 1.0 + fraction * 0.3;
    final fontSize = 56.0 * scale;

    _drawCenteredText(canvas, text,
        Offset(size.x / 2, size.y * 0.4),
        fontSize: fontSize, color: color,
        fontWeight: FontWeight.bold);
  }

  // ─── 웨이브 클리어 배너 ───────────────────────
  void _renderWaveClearedBanner(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.4 - 30, size.x, 60),
      Paint()..color = const Color(0xCC0D1F0D));
    _drawCenteredText(canvas, 'WAVE $currentWave 클리어!',
        Offset(size.x / 2, size.y * 0.4),
        fontSize: 26, color: const Color(0xFF44FF44),
        fontWeight: FontWeight.bold);
  }

  // ─── 게임오버 화면 ────────────────────────────
  void _renderGameOver(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xCC000000));

    _drawCenteredText(canvas, 'GAME OVER',
        Offset(size.x / 2, size.y * 0.3),
        fontSize: 32, color: const Color(0xFFFF4444),
        fontWeight: FontWeight.bold);
    _drawCenteredText(canvas,
        '최고 웨이브: $currentWave',
        Offset(size.x / 2, size.y * 0.42),
        fontSize: 16, color: const Color(0xFFCCCCCC));
    _drawCenteredText(canvas, '처치: $defeatedCount',
        Offset(size.x / 2, size.y * 0.49),
        fontSize: 14, color: const Color(0xFFAAAAAA));

    _drawButton(canvas, '재도전', _retryButtonRect(),
        const Color(0xFF225522), const Color(0xFF44FF44));
    _drawButton(canvas, '홈으로', _homeButtonRect(),
        const Color(0xFF221122), const Color(0xFF8844FF));
  }

  // ─── 스테이지 클리어 화면 ─────────────────────
  void _renderStageClear(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xCC000000));

    _drawCenteredText(canvas, 'STAGE CLEAR!',
        Offset(size.x / 2, size.y * 0.28),
        fontSize: 30, color: const Color(0xFFFFD700),
        fontWeight: FontWeight.bold);

    _drawCenteredText(canvas, getStageRewardSummary(),
        Offset(size.x / 2, size.y * 0.42),
        fontSize: 14, color: const Color(0xFFCCFFCC));
    _drawCenteredText(canvas, '젬: $playerGem  별조각: $playerStarShards',
        Offset(size.x / 2, size.y * 0.50),
        fontSize: 13, color: const Color(0xFFAAAAFF));

    _drawButton(canvas, '홈으로', _homeButtonRect(),
        const Color(0xFF225522), const Color(0xFF44FF44));
  }

  // ─── 홈화면 ───────────────────────────────────
  void _renderHome(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF0D1B0D));

    // 타이틀
    _drawCenteredText(canvas, 'Castle Defense',
        Offset(size.x / 2, 50),
        fontSize: 22, color: const Color(0xFFFFD700),
        fontWeight: FontWeight.bold);

    // 종족 표시
    final raceLabel = switch (playerRace) {
      RaceType.human   => '인간족',
      RaceType.orc     => '오크족',
      RaceType.elf     => '엘프족',
      RaceType.machina => '기계족',
      RaceType.demon   => '악마족',
    };
    _drawCenteredText(canvas, '종족: $raceLabel',
        Offset(size.x / 2, 78),
        fontSize: 12, color: const Color(0xFF88AA88));

    // 재화 표시
    _drawCenteredText(canvas, '💎 $playerGem   ⭐ $playerStarShards',
        Offset(size.x / 2, 100),
        fontSize: 13, color: const Color(0xFFFFD700));

    // 스테이지 버튼 목록
    _renderStageButtons(canvas);

    // 하단 메뉴
    _renderBottomMenu(canvas);
  }

  void _renderStageButtons(Canvas canvas) {
    final stageCount = kStageConfigs.length;
    for (int i = 1; i <= stageCount; i++) {
      final rect = _stageButtonRect(i);
      final isUnlocked = i <= unlockedStageMax;
      final isCleared  = _clearedStages.contains(i);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        Paint()..color = isUnlocked
            ? const Color(0xFF1A3A1A)
            : const Color(0xFF1A1A1A));
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        Paint()
          ..color = isUnlocked
              ? const Color(0xFF44AA44)
              : const Color(0xFF444444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

      _drawCenteredText(canvas,
          isUnlocked ? 'STAGE $i${isCleared ? " ✓" : ""}' : '🔒 STAGE $i',
          rect.center,
          fontSize: 16,
          color: isUnlocked
              ? (isCleared ? const Color(0xFF88FF88) : const Color(0xFFFFFFFF))
              : const Color(0xFF666666),
          fontWeight: FontWeight.bold);

      if (isUnlocked) {
        _drawCenteredText(canvas,
            '${kStageConfigs[i]!.waves.length}웨이브',
            Offset(rect.center.dx, rect.center.dy + 18),
            fontSize: 11, color: const Color(0xFF88AA88));
      }
    }
  }

  Rect _stageButtonRect(int stage) {
    const double btnH = 70.0, gap = 12.0, btnW = 320.0;
    final startY = 130.0;
    return Rect.fromLTWH(
        (size.x - btnW) / 2, startY + (stage - 1) * (btnH + gap), btnW, btnH);
  }

  // ─── 하단 내비게이션 메뉴 ─────────────────────
  void _renderBottomMenu(Canvas canvas) {
    const double menuH = 65.0;
    final menuY = size.y - menuH;

    canvas.drawRect(Rect.fromLTWH(0, menuY, size.x, menuH),
        Paint()..color = const Color(0xEE0A1A0A));
    canvas.drawLine(Offset(0, menuY), Offset(size.x, menuY),
        Paint()..color = const Color(0xFF336633)..strokeWidth = 1);

    final items = [
      (BottomMenu.home,       '🏠', '홈'),
      (BottomMenu.collection, '📚', '컬렉션'),
      (BottomMenu.gacha,      '🎰', '뽑기'),
      (BottomMenu.settings,   '⚙️', '설정'),
    ];
    final btnW = size.x / items.length;

    for (int i = 0; i < items.length; i++) {
      final (menu, icon, label) = items[i];
      final isActive = currentBottomMenu == menu;
      final cx = btnW * i + btnW / 2;
      final color = isActive
          ? const Color(0xFF44FF44)
          : const Color(0xFF888888);

      _drawCenteredText(canvas, icon, Offset(cx, menuY + 18), fontSize: 20);
      _drawCenteredText(canvas, label, Offset(cx, menuY + 46),
          fontSize: 10, color: color);

      if (isActive) {
        canvas.drawRect(
          Rect.fromLTWH(btnW * i + 10, menuY, btnW - 20, 2),
          Paint()..color = const Color(0xFF44FF44));
      }
    }
  }

  // ─── 가챠 화면 (추후 재구현, 현재는 캐릭터 목록) ──
  void _renderGachaScreen(Canvas canvas) {
    _drawCenteredText(canvas, '캐릭터 목록',
        Offset(size.x / 2, 120), fontSize: 20,
        color: const Color(0xFFFFD700), fontWeight: FontWeight.bold);
    _drawCenteredText(canvas, '가챠 시스템 준비 중...',
        Offset(size.x / 2, 150), fontSize: 14,
        color: const Color(0xFF88AAFF));

    // 전체 캐릭터 표시
    _renderCharacterGrid(canvas);
  }

  void _renderCharacterGrid(Canvas canvas) {
    const double startY = 180.0;
    const double cardW = 72.0, cardH = 86.0, gap = 8.0;
    const int cols = 4;
    final startX = (size.x - (cardW * cols + gap * (cols - 1))) / 2;
    final allChars = CharacterDefinitions.all;

    for (int i = 0; i < allChars.length; i++) {
      final def = allChars[i];
      final row = i ~/ cols;
      final col = i % cols;
      final x = startX + col * (cardW + gap);
      final y = startY + row * (cardH + gap) - characterListScrollOffset;

      if (y + cardH < 130 || y > size.y - 70) continue;

      // 타워 타입별 색상
      final typeColor = switch (def.towerType) {
        TowerTypeMapping.archer => const Color(0xFF44BB44),
        TowerTypeMapping.cannon => const Color(0xFFBB4444),
        TowerTypeMapping.mage   => const Color(0xFF4444BB),
        TowerTypeMapping.sniper => const Color(0xFFBBBB44),
      };

      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cardW, cardH), const Radius.circular(6)),
        Paint()..color = const Color(0xFF112211));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cardW, cardH), const Radius.circular(6)),
        Paint()
          ..color = typeColor.withAlpha(180)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

      // 첫 프레임 표시
      final img = characterImages[def.id];
      if (img != null) {
        final frameW = img.width / def.frameColumns;
        final frameH = img.height / def.frameRows;
        final src = Rect.fromLTWH(0, 0, frameW, frameH);
        final dst = Rect.fromLTWH(x + 6, y + 4, cardW - 12, cardH - 28);
        canvas.drawImageRect(img, src, dst, _paintDefault);
      }

      _drawCenteredText(canvas,
          def.name.length > 5 ? def.name.substring(0, 5) : def.name,
          Offset(x + cardW / 2, y + cardH - 10),
          fontSize: 9, color: const Color(0xFFFFFFFF));
    }
  }

  // ─── 컬렉션 화면 (캐릭터 도감) ─────────────────
  void _renderCollectionScreen(Canvas canvas) {
    _drawCenteredText(canvas, '컬렉션',
        Offset(size.x / 2, 120), fontSize: 20,
        color: const Color(0xFFFFD700), fontWeight: FontWeight.bold);

    _renderCharacterGrid(canvas);
  }

  // ─── 버튼 헬퍼 ───────────────────────────────
  void _drawButton(Canvas canvas, String label, Rect rect,
      Color bgColor, Color borderColor) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = bgColor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    _drawCenteredText(canvas, label, rect.center,
        fontSize: 14, color: borderColor, fontWeight: FontWeight.bold);
  }

  // ─── 버튼 Rect 정의 ──────────────────────────
  Rect _retryButtonRect() => Rect.fromLTWH(
      (size.x - 200) / 2, size.y * 0.58, 200, 44);
  Rect _homeButtonRect() => Rect.fromLTWH(
      (size.x - 200) / 2, size.y * 0.58 + 54, 200, 44);
  Rect _gachaSingleButtonRect() => Rect.fromLTWH(
      (size.x - 300) / 2, 185, 300, 48);
  Rect _gachaTenButtonRect() => Rect.fromLTWH(
      (size.x - 300) / 2, 243, 300, 48);
  Rect _bottomMenuButtonRect(int i) {
    const double menuH = 65.0;
    final btnW = size.x / 4;
    return Rect.fromLTWH(btnW * i, size.y - menuH, btnW, menuH);
  }

  // ─── 타워 배치 선택 팝업 (슬롯 탭 시) ─────────
  void _renderTowerPlacementPopup(Canvas canvas) {
    if (_pendingSlotId < 0) return;

    final chars = CharacterDefinitions.all;
    final contentH = 60.0 + chars.length * 50.0 + 50.0;
    final popH = contentH.clamp(0.0, size.y - 80);
    const double popW = 340.0;
    final popX = (size.x - popW) / 2;
    final popY = ((size.y - popH) / 2).clamp(30.0, size.y - popH - 10);
    final popRect = Rect.fromLTWH(popX, popY, popW, popH);

    // 반투명 배경 오버레이
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0x88000000));

    canvas.drawRRect(
      RRect.fromRectAndRadius(popRect, const Radius.circular(12)),
      Paint()..color = const Color(0xF00D1F0D));
    canvas.drawRRect(
      RRect.fromRectAndRadius(popRect, const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFF44AA44)
        ..style = PaintingStyle.stroke..strokeWidth = 2);

    _drawCenteredText(canvas, '캐릭터 배치',
        Offset(popX + popW / 2, popY + 22),
        fontSize: 16, fontWeight: FontWeight.bold,
        color: const Color(0xFFFFFFFF));

    // 골드 표시
    _drawCenteredText(canvas, '🪙 $playerInGameGold',
        Offset(popX + popW - 50, popY + 22),
        fontSize: 12, color: const Color(0xFFFFD700));

    for (int i = 0; i < chars.length; i++) {
      final def = chars[i];
      final towerType = switch (def.towerType) {
        TowerTypeMapping.archer => TowerType.archer,
        TowerTypeMapping.cannon => TowerType.cannon,
        TowerTypeMapping.mage   => TowerType.mage,
        TowerTypeMapping.sniper => TowerType.sniper,
      };
      final stat = kTowerBaseStat[towerType]!;
      int cost = stat.cost;
      if (playerRace == RaceType.human) cost = (cost * 0.95).round();
      final canAfford = playerInGameGold >= cost;

      final r = Rect.fromLTWH(popX + 10, popY + 54 + i * 50.0, popW - 20, 44);

      // 타워 타입별 배경 색상
      final typeColor = switch (def.towerType) {
        TowerTypeMapping.archer => const Color(0xFF1A2A1A),
        TowerTypeMapping.cannon => const Color(0xFF2A1A1A),
        TowerTypeMapping.mage   => const Color(0xFF1A1A2A),
        TowerTypeMapping.sniper => const Color(0xFF2A2A1A),
      };
      final borderColor = switch (def.towerType) {
        TowerTypeMapping.archer => const Color(0xFF44BB44),
        TowerTypeMapping.cannon => const Color(0xFFBB4444),
        TowerTypeMapping.mage   => const Color(0xFF4488BB),
        TowerTypeMapping.sniper => const Color(0xFFBBBB44),
      };

      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()..color = canAfford ? typeColor : const Color(0xFF1A1A1A));
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()
          ..color = canAfford ? borderColor.withAlpha(180) : const Color(0xFF444444)
          ..style = PaintingStyle.stroke..strokeWidth = 1.2);

      // 캐릭터 썸네일 (첫 프레임, 정수 정렬)
      final img = characterImages[def.id];
      if (img != null) {
        final fW = (img.width.toDouble() / def.frameColumns).floorToDouble();
        final fH = (img.height.toDouble() / def.frameRows).floorToDouble();
        final src = Rect.fromLTWH(0, 0, fW, fH);
        final dst = Rect.fromLTWH(r.left + 4, r.top + 4, 36, 36);
        canvas.drawImageRect(img, src, dst, _paintDefault);
      }

      // 캐릭터 이름
      _drawCenteredText(canvas, def.name,
          Offset(r.left + 80, r.top + 14),
          fontSize: 13, color: canAfford
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF666666),
          fontWeight: FontWeight.bold);

      // 타워 타입 태그
      final typeLabel = switch (def.towerType) {
        TowerTypeMapping.archer => '궁수',
        TowerTypeMapping.cannon => '대포',
        TowerTypeMapping.mage   => '마법',
        TowerTypeMapping.sniper => '저격',
      };
      _drawCenteredText(canvas, typeLabel,
          Offset(r.left + 80, r.top + 32),
          fontSize: 10, color: borderColor);

      // 스탯 (데미지, 사거리)
      _drawCenteredText(canvas, '⚔${stat.damage.toStringAsFixed(0)}  📏${stat.range.toStringAsFixed(0)}',
          Offset(r.center.dx + 30, r.top + 14),
          fontSize: 10, color: const Color(0xFF88AA88));

      // 비용
      _drawCenteredText(canvas, '${cost}g',
          Offset(r.right - 30, r.center.dy),
          fontSize: 14,
          color: canAfford
              ? const Color(0xFFFFD700)
              : const Color(0xFF666644),
          fontWeight: FontWeight.bold);

      // 구매 불가 표시
      if (!canAfford) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(8)),
          Paint()..color = const Color(0x44000000));
      }
    }

    // 취소 버튼
    _drawButton(canvas, '취소',
        Rect.fromLTWH(popX + popW / 2 - 50, popY + popH - 40, 100, 30),
        const Color(0xFF331111), const Color(0xFFFF4444));
  }
}
