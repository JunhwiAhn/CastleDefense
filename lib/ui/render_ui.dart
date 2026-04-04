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
      canvas.drawImageRect(img, src, dst,
          Paint()..color = Color.fromRGBO(255, 255, 255, alpha));
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

  // ─── 하단 타워 선택 바 ────────────────────────
  void _renderTowerBar(Canvas canvas) {
    const double barH = 100.0;
    final barY = size.y - barH;

    // 배경
    canvas.drawRect(
      Rect.fromLTWH(0, barY, size.x, barH),
      Paint()..color = const Color(0xEE0A1A0A));
    canvas.drawLine(Offset(0, barY), Offset(size.x, barY),
        Paint()..color = const Color(0xFF336633)..strokeWidth = 1);

    // 타워 버튼 4개
    const types = TowerType.values;
    final btnW = (size.x - 10) / types.length;

    for (int i = 0; i < types.length; i++) {
      final type = types[i];
      final stat = kTowerBaseStat[type]!;
      int cost = stat.cost;
      if (playerRace == RaceType.human) cost = (cost * 0.95).round();

      final isSelected = placingTowerType == type;
      final canAfford = playerInGameGold >= cost;

      final btnX = 5.0 + i * btnW;
      final btnRect = Rect.fromLTWH(btnX, barY + 5, btnW - 5, barH - 10);

      // 버튼 배경
      final btnColor = isSelected
          ? const Color(0xFF226622)
          : canAfford
              ? const Color(0xFF112211)
              : const Color(0xFF1A1A1A);
      canvas.drawRRect(
        RRect.fromRectAndRadius(btnRect, const Radius.circular(8)),
        Paint()..color = btnColor);
      canvas.drawRRect(
        RRect.fromRectAndRadius(btnRect, const Radius.circular(8)),
        Paint()
          ..color = isSelected
              ? const Color(0xFF44FF44)
              : canAfford
                  ? const Color(0xFF336633)
                  : const Color(0xFF333333)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

      // 아이콘
      final icon = switch (type) {
        TowerType.archer => '🏹',
        TowerType.cannon => '💣',
        TowerType.mage   => '🔮',
        TowerType.sniper => '🎯',
      };
      _drawCenteredText(canvas, icon,
          Offset(btnRect.center.dx, btnRect.top + 22), fontSize: 22);

      // 타입 이름
      final name = switch (type) {
        TowerType.archer => '궁수',
        TowerType.cannon => '대포',
        TowerType.mage   => '마법사',
        TowerType.sniper => '저격',
      };
      _drawCenteredText(canvas, name,
          Offset(btnRect.center.dx, btnRect.top + 52),
          fontSize: 11, color: canAfford
              ? const Color(0xFFCCFFCC)
              : const Color(0xFF666666));

      // 비용
      _drawCenteredText(canvas, '${cost}g',
          Offset(btnRect.center.dx, btnRect.top + 68),
          fontSize: 12,
          color: canAfford
              ? const Color(0xFFFFD700)
              : const Color(0xFF888844),
          fontWeight: FontWeight.bold);
    }

    // 웨이브 시작 버튼 (prep 상태일 때만)
    if (gameState == GameState.prep) {
      _renderWaveStartButton(canvas);
    }
  }

  Rect _waveStartButtonRect() {
    return Rect.fromLTWH(size.x - 90, size.y - 95, 85, 40);
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

  // ─── 가챠 화면 ───────────────────────────────
  void _renderGachaScreen(Canvas canvas) {
    // 헤더
    _drawCenteredText(canvas, '캐릭터 뽑기',
        Offset(size.x / 2, 120), fontSize: 20,
        color: const Color(0xFFFFD700), fontWeight: FontWeight.bold);
    _drawCenteredText(canvas, '보유 💎 $playerGem',
        Offset(size.x / 2, 150), fontSize: 14,
        color: const Color(0xFF88AAFF));

    // 뽑기 결과 표시 중
    if (gachaResults != null && gachaResults!.isNotEmpty) {
      _renderGachaResult(canvas);
      return;
    }

    // 단일 뽑기 버튼
    _drawButton(canvas, '단일 뽑기 (💎${gachaSystem.getSingleSummonCost()})',
        _gachaSingleButtonRect(), const Color(0xFF223366), const Color(0xFF4488FF));

    // 10연 뽑기 버튼
    _drawButton(canvas, '10연 뽑기 (💎${gachaSystem.getTenSummonCost()})',
        _gachaTenButtonRect(), const Color(0xFF332244), const Color(0xFF8844FF));

    // 보유 캐릭터 목록
    _renderOwnedCharacterList(canvas);
  }

  void _renderGachaResult(Canvas canvas) {
    if (gachaResults == null) return;
    final idx = gachaResultIndex.clamp(0, gachaResults!.length - 1);
    final def = gachaResults![idx];

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xCC000000));

    final rankColor = Color(def.rank.color);
    _drawCenteredText(canvas, def.rank.displayName,
        Offset(size.x / 2, size.y * 0.3),
        fontSize: 36, color: rankColor, fontWeight: FontWeight.bold);
    _drawCenteredText(canvas, def.name,
        Offset(size.x / 2, size.y * 0.5),
        fontSize: 22, color: const Color(0xFFFFFFFF));
    _drawCenteredText(canvas, def.description,
        Offset(size.x / 2, size.y * 0.6),
        fontSize: 12, color: const Color(0xFFAAAAAA));

    final remaining = gachaResults!.length - idx - 1;
    _drawCenteredText(canvas,
        remaining > 0 ? '탭하여 다음 ($remaining 남음)' : '탭하여 완료',
        Offset(size.x / 2, size.y * 0.75),
        fontSize: 14, color: const Color(0xFF888888));
  }

  void _renderOwnedCharacterList(Canvas canvas) {
    const double startY = 310.0;
    const double cardW = 56.0, cardH = 72.0, gap = 8.0;
    const int cols = 5;
    final startX = (size.x - (cardW * cols + gap * (cols - 1))) / 2;

    // 중복 제거 목록
    final seen = <String>{};
    final unique = <OwnedCharacter>[];
    for (final c in ownedCharacters) {
      if (seen.add(c.characterId)) unique.add(c);
    }

    for (int i = 0; i < unique.length; i++) {
      final c = unique[i];
      final def = CharacterDefinitions.byId(c.characterId);
      final row = i ~/ cols;
      final col = i % cols;
      final x = startX + col * (cardW + gap);
      final y = startY + row * (cardH + gap) - characterListScrollOffset;

      if (y + cardH < 200 || y > size.y - 70) continue;

      final rankColor = Color(def.rank.color);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cardW, cardH), const Radius.circular(6)),
        Paint()..color = const Color(0xFF112211));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cardW, cardH), const Radius.circular(6)),
        Paint()
          ..color = rankColor.withAlpha(180)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

      _drawCenteredText(canvas, def.name.length > 4 ? def.name.substring(0, 4) : def.name,
          Offset(x + cardW / 2, y + cardH / 2 - 8),
          fontSize: 10, color: const Color(0xFFFFFFFF));
      _drawCenteredText(canvas, 'Lv${c.cardLevel}',
          Offset(x + cardW / 2, y + cardH / 2 + 8),
          fontSize: 10, color: const Color(0xFFFFD700));
      _drawCenteredText(canvas, def.rank.displayName,
          Offset(x + cardW - 8, y + 10),
          fontSize: 9, color: rankColor, fontWeight: FontWeight.bold);
    }
  }

  // ─── 컬렉션 화면 (카드 업그레이드) ─────────────
  void _renderCollectionScreen(Canvas canvas) {
    _drawCenteredText(canvas, '컬렉션',
        Offset(size.x / 2, 120), fontSize: 20,
        color: const Color(0xFFFFD700), fontWeight: FontWeight.bold);
    _drawCenteredText(canvas, '⭐ $playerStarShards',
        Offset(size.x / 2, 150), fontSize: 14,
        color: const Color(0xFFFFEE44));

    // 카드 목록 (업그레이드 버튼 포함)
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
      final def = CharacterDefinitions.byId(c.characterId);
      final y = startY + i * (cardH + gap) - characterListScrollOffset;
      if (y + cardH < 130 || y > size.y - 70) continue;

      final cardRect = Rect.fromLTWH(startX, y, cardW, cardH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
        Paint()..color = const Color(0xFF112211));
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
        Paint()
          ..color = const Color(0xFF336633)
          ..style = PaintingStyle.stroke..strokeWidth = 1);

      _drawCenteredText(canvas, def.name,
          Offset(startX + 60, y + 20),
          fontSize: 13, fontWeight: FontWeight.bold);
      _drawCenteredText(canvas,
          'Lv ${c.cardLevel}/5  중복: ${c.duplicateCount}',
          Offset(startX + 60, y + 42), fontSize: 11,
          color: const Color(0xFF88AA88));

      // 업그레이드 버튼
      if (c.cardLevel < 5) {
        final needShards = OwnedCharacter.kStarShardsRequired[c.cardLevel];
        final needDupes  = OwnedCharacter.kDuplicatesRequired[c.cardLevel];
        final canUpgrade = playerStarShards >= needShards
            && c.duplicateCount >= needDupes;

        final upgRect = Rect.fromLTWH(
            startX + cardW - 100, y + 15, 90, 40);
        canvas.drawRRect(
          RRect.fromRectAndRadius(upgRect, const Radius.circular(6)),
          Paint()..color = canUpgrade
              ? const Color(0xFF225522) : const Color(0xFF222222));
        canvas.drawRRect(
          RRect.fromRectAndRadius(upgRect, const Radius.circular(6)),
          Paint()
            ..color = canUpgrade
                ? const Color(0xFF44FF44) : const Color(0xFF444444)
            ..style = PaintingStyle.stroke..strokeWidth = 1);
        _drawCenteredText(canvas,
            '강화\n⭐$needShards+${needDupes}장',
            upgRect.center, fontSize: 10,
            color: canUpgrade
                ? const Color(0xFF44FF44) : const Color(0xFF666666));
      } else {
        _drawCenteredText(canvas, 'MAX',
            Offset(startX + cardW - 55, y + 35),
            fontSize: 12, color: const Color(0xFFFFD700));
      }
    }
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

    const double popW = 320.0, popH = 260.0;
    final popX = (size.x - popW) / 2;
    final popY = (size.y - popH) / 2 - 50;
    final popRect = Rect.fromLTWH(popX, popY, popW, popH);

    canvas.drawRRect(
      RRect.fromRectAndRadius(popRect, const Radius.circular(12)),
      Paint()..color = const Color(0xEE0D1F0D));
    canvas.drawRRect(
      RRect.fromRectAndRadius(popRect, const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFF44AA44)
        ..style = PaintingStyle.stroke..strokeWidth = 1.5);

    _drawCenteredText(canvas, '타워 선택',
        Offset(popX + popW / 2, popY + 20),
        fontSize: 16, fontWeight: FontWeight.bold);

    // 캐릭터 선택 목록 (타워 타입별)
    if (_pendingTowerType != null) {
      final chars = getCharactersForTowerType(_pendingTowerType!);
      _drawCenteredText(canvas, '배치할 캐릭터:',
          Offset(popX + popW / 2, popY + 50),
          fontSize: 12, color: const Color(0xFF88CC88));

      // 기본 (캐릭터 없음) 옵션
      final defaultRect = Rect.fromLTWH(popX + 10, popY + 65, popW - 20, 32);
      canvas.drawRRect(
        RRect.fromRectAndRadius(defaultRect, const Radius.circular(6)),
        Paint()..color = const Color(0xFF112211));
      canvas.drawRRect(
        RRect.fromRectAndRadius(defaultRect, const Radius.circular(6)),
        Paint()..color = const Color(0xFF336633)..style = PaintingStyle.stroke..strokeWidth = 1);
      _drawCenteredText(canvas, '기본 타워 (캐릭터 없음)',
          defaultRect.center, fontSize: 12);

      for (int i = 0; i < chars.length && i < 4; i++) {
        final c = chars[i];
        final def = CharacterDefinitions.byId(c.characterId);
        final r = Rect.fromLTWH(popX + 10, popY + 105 + i * 36.0, popW - 20, 30);
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(6)),
          Paint()..color = const Color(0xFF112211));
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(6)),
          Paint()
            ..color = Color(def.rank.color).withAlpha(160)
            ..style = PaintingStyle.stroke..strokeWidth = 1);
        _drawCenteredText(canvas,
            '${def.name} [${def.rank.displayName}] Lv${c.cardLevel}',
            r.center, fontSize: 11);
      }

      // 취소 버튼
      _drawButton(canvas, '취소',
          Rect.fromLTWH(popX + popW / 2 - 50, popY + popH - 40, 100, 30),
          const Color(0xFF331111), const Color(0xFFFF4444));
    }
  }
}
