// UI 오버레이, 메뉴, HUD, 스틱, 헬퍼 등 렌더링
part of '../castle_defense_game.dart';

extension UIRendering on CastleDefenseGame {
  // -----------------------------
  // 이미지 캐시 헬퍼 (null 반환 시 Canvas 폴백)
  // -----------------------------
  Image? _tryGetImage(String path) {
    try {
      return images.fromCache(path);
    } catch (_) {
      return null;
    }
  }

  /// 이미지 아이콘 그리기 헬퍼 (이미지 없으면 fallbackEmoji로 폴백)
  void _drawImageIcon(
    Canvas canvas,
    String imagePath,
    Offset center,
    double iconSize, {
    String fallbackEmoji = '',
    double alpha = 1.0,
  }) {
    final img = _tryGetImage(imagePath);
    if (img != null) {
      final srcRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dstRect = Rect.fromCenter(center: center, width: iconSize, height: iconSize);
      final paint = Paint()..color = Color.fromRGBO(255, 255, 255, alpha);
      canvas.drawImageRect(img, srcRect, dstRect, paint);
    } else if (fallbackEmoji.isNotEmpty) {
      _drawCenteredText(canvas, fallbackEmoji, center, fontSize: iconSize * 0.7);
    }
  }

  /// 이미지 패널/카드 배경 그리기 (drawImageRect 스트레치)
  void _drawImagePanel(Canvas canvas, String imagePath, Rect rect, {double alpha = 1.0}) {
    final img = _tryGetImage(imagePath);
    if (img != null) {
      final srcRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final paint = Paint()..color = Color.fromRGBO(255, 255, 255, alpha);
      canvas.drawImageRect(img, srcRect, rect, paint);
    }
  }

  /// 이미지 바 그리기 (배경 + 필 비율)
  void _drawImageBar(
    Canvas canvas,
    String bgPath,
    String fillPath,
    Rect barRect,
    double ratio, {
    Color? fallbackBgColor,
    Color? fallbackFillColor,
  }) {
    final bgImg = _tryGetImage(bgPath);
    final fillImg = _tryGetImage(fillPath);

    if (bgImg != null && fillImg != null) {
      // 배경 이미지
      final bgSrc = Rect.fromLTWH(0, 0, bgImg.width.toDouble(), bgImg.height.toDouble());
      canvas.drawImageRect(bgImg, bgSrc, barRect, Paint());

      // 필 이미지 (비율에 맞게 클리핑)
      if (ratio > 0) {
        final clampedRatio = ratio.clamp(0.0, 1.0);
        final fillRect = Rect.fromLTWH(barRect.left, barRect.top, barRect.width * clampedRatio, barRect.height);
        final fillSrcW = fillImg.width.toDouble() * clampedRatio;
        final fillSrc = Rect.fromLTWH(0, 0, fillSrcW, fillImg.height.toDouble());
        canvas.drawImageRect(fillImg, fillSrc, fillRect, Paint());
      }
    } else {
      // 폴백: Canvas 직접 그리기
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
        Paint()..color = fallbackBgColor ?? const Color(0xFF333333),
      );
      if (ratio > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barRect.left, barRect.top, barRect.width * ratio.clamp(0.0, 1.0), barRect.height),
            const Radius.circular(3),
          ),
          Paint()..color = fallbackFillColor ?? const Color(0xFF4CAF50),
        );
      }
    }
  }

  /// 이미지 버튼 그리기 헬퍼
  void _drawImageButton(
    Canvas canvas,
    String imagePath,
    Rect rect,
    String label, {
    bool enabled = true,
    double fontSize = 16,
    Color textColor = const Color(0xFFFFFFFF),
  }) {
    final img = _tryGetImage(imagePath);
    if (img != null) {
      final srcRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final paint = Paint()..color = Color.fromRGBO(255, 255, 255, enabled ? 1.0 : 0.5);
      canvas.drawImageRect(img, srcRect, rect, paint);
    } else {
      // 폴백: Canvas 직접 그리기
      final bgColor = enabled ? const Color(0xFF5B21B6) : const Color(0xFFB0BEC5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = bgColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    _drawCenteredText(canvas, label, rect.center, fontSize: fontSize, color: textColor);
  }

  // -----------------------------
  // 상태별 오버레이
  // -----------------------------
  void _renderGameStateOverlay(Canvas canvas) {
    if (gameState == GameState.roundClear) {
      _renderRoundClearOverlay(canvas);
    } else if (gameState == GameState.paused) {
      _renderPausedOverlay(canvas);
    } else if (gameState == GameState.augmentSelect) {
      _renderAugmentSelectionUI(canvas); // 증강 선택 화면
    } else if (gameState == GameState.shopOpen) {
      _renderShopOverlay(canvas); // 리디자인 B-2-16: 상점 화면
    } else if (gameState == GameState.result) {
      _renderResultOverlay(canvas);
    }
  }

  // #37 증강 선택 UI (스펙 준수: 티어별 색상 카드, 전설 글로우 연출)
  void _renderAugmentSelectionUI(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xF00A0A1A));

    // 타이틀 (금색 펄스)
    final double tp = 0.9 + 0.1 * sin(gameTime * 2.5);
    _drawCenteredText(canvas, '⚡ 증강 선택 ⚡',
        Offset(size.x / 2, size.y * 0.06),
        fontSize: 22,
        color: Color.fromRGBO(255, (215 * tp).toInt(), 0, 1.0));
    _drawCenteredText(canvas, 'Round \$currentRound — 1つを選択してください',
        Offset(size.x / 2, size.y * 0.13),
        fontSize: 11, color: const Color(0xFF888888));

    if (_augmentOptions.isEmpty) {
      _drawCenteredText(canvas, '増強なし', Offset(size.x / 2, size.y / 2),
          fontSize: 16, color: const Color(0xFF555555));
      return;
    }

    final double cW = size.x / 3 - 10;
    final double cH = size.y * 0.52;
    final double cY = size.y * 0.19;

    for (int i = 0; i < _augmentOptions.length; i++) {
      final aug = _augmentOptions[i];
      final double cX = i * (size.x / 3) + 5;
      final cRect = Rect.fromLTWH(cX, cY, cW, cH);

      Color bg, brd, lblC;
      String lbl;
      switch (aug.tier) {
        case AugmentTier.legendary:
          bg = const Color(0xCC3D2B00); brd = const Color(0xFFFFD700);
          lblC = const Color(0xFFFFD700); lbl = '✨ 伝説'; break;
        case AugmentTier.rare:
          bg = const Color(0xCC0D1F3C); brd = const Color(0xFF2196F3);
          lblC = const Color(0xFF64B5F6); lbl = '💎 希少'; break;
        default:
          bg = const Color(0xCC1C1C1C); brd = const Color(0xFF9E9E9E);
          lblC = const Color(0xFFBBBBBB); lbl = '⬜ 一般';
      }

      // 전설 글로우 링
      if (aug.tier == AugmentTier.legendary) {
        final double ga = 0.15 + 0.1 * sin(gameTime * 3 + i * 1.2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(cRect.inflate(3), const Radius.circular(13)),
          Paint()..color = Color.fromRGBO(255, 215, 0, ga));
      }

      // 카드 배경 (이미지 패널 우선, 폴백 Canvas)
      final String panelAsset;
      switch (aug.tier) {
        case AugmentTier.legendary: panelAsset = 'ui/panel_dark_yellow.png'; break;
        case AugmentTier.rare:      panelAsset = 'ui/panel_dark_blue.png'; break;
        default:                    panelAsset = 'ui/panel_dark.png';
      }
      final panelImg = _tryGetImage(panelAsset);
      if (panelImg != null) {
        _drawImagePanel(canvas, panelAsset, cRect);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(cRect, const Radius.circular(10)),
            Paint()..color = bg);
      }
      canvas.drawRRect(RRect.fromRectAndRadius(cRect, const Radius.circular(10)),
          Paint()
            ..color = brd
            ..style = PaintingStyle.stroke
            ..strokeWidth = aug.tier == AugmentTier.legendary ? 2.5 : 1.5);

      // 티어 레이블
      _drawCenteredText(canvas, lbl, Offset(cX + cW / 2, cY + 16),
          fontSize: 10, color: lblC);

      // 구분선
      canvas.drawLine(Offset(cX + 8, cY + 29), Offset(cX + cW - 8, cY + 29),
          Paint()..color = brd.withValues(alpha: 0.4)..strokeWidth = 0.8);

      // 카테고리 아이콘 (이미지 우선) + 이름 + 설명
      final catImgPath = _augmentCategoryImagePath(aug.category);
      if (catImgPath != null) {
        _drawImageIcon(canvas, catImgPath, Offset(cX + cW / 2, cY + 52), 28,
            fallbackEmoji: _augmentCategoryIcon(aug.category));
      } else {
        _drawCenteredText(canvas, _augmentCategoryIcon(aug.category),
            Offset(cX + cW / 2, cY + 52), fontSize: 24);
      }
      _drawCenteredText(canvas, aug.nameJp,
          Offset(cX + cW / 2, cY + 82), fontSize: 13, color: const Color(0xFFFFFFFF));
      _drawCenteredText(canvas, aug.description,
          Offset(cX + cW / 2, cY + 108), fontSize: 8.5, color: const Color(0xFFBBBBBB));
    }

    // 하단 안내 점멸
    _drawCenteredText(canvas, 'カードをタップして選択',
        Offset(size.x / 2, size.y * 0.84),
        fontSize: 12,
        color: Color.fromRGBO(200, 200, 200, 0.6 + 0.4 * sin(gameTime * 2)));
  }

  // 증강 카테고리 아이콘 헬퍼 (이미지 우선, 폴백 이모지)
  String _augmentCategoryIcon(AugmentCategory cat) {
    switch (cat) {
      case AugmentCategory.main:      return '⚔️';
      case AugmentCategory.tower:     return '🏹';
      case AugmentCategory.castle:    return '🏰';
      case AugmentCategory.utility:   return '🔧';
      case AugmentCategory.economy:   return '💰';
      case AugmentCategory.elemental: return '🌟';
      case AugmentCategory.special:   return '✨';
      case AugmentCategory.synergy:   return '🔗';
    }
  }

  /// 증강 카테고리 이미지 경로 (null이면 폴백 이모지 사용)
  String? _augmentCategoryImagePath(AugmentCategory cat) {
    switch (cat) {
      case AugmentCategory.main:      return 'ui/icon_attack.png';
      case AugmentCategory.tower:     return 'ui/icon_tower.png';
      case AugmentCategory.castle:    return 'ui/icon_heal.png';
      case AugmentCategory.utility:   return 'ui/icon_settings.png';
      case AugmentCategory.economy:   return 'ui/icon_coin.png';
      case AugmentCategory.elemental: return 'ui/icon_energy.png';
      case AugmentCategory.special:   return 'ui/icon_crown.png';
      case AugmentCategory.synergy:   return 'ui/icon_gem.png';
    }
  }

  // D-2-2: 스테이지 클리어 후 상점 UI (Violet Theme)
  // 탭 영역은 _handleTapInShop 과 동기화:
  //   centerYs = [0.40, 0.575, 0.725], cardH = 70 → 각 카드 Rect 기준 판정
  //   계속 버튼: y > 0.80
  void _renderShopOverlay(Canvas canvas) {
    // 배경 오버레이
    final bgPaint = Paint()..color = const Color(0xEE0A0A20);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // 상단 장식 바 (골드)
    final topBarPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 4), topBarPaint);

    // "STAGE CLEAR!" 제목
    _drawCenteredText(
      canvas,
      'STAGE CLEAR!',
      Offset(size.x / 2, size.y * 0.07),
      fontSize: 26,
      color: const Color(0xFFFFD700),
    );

    // 골드 표시 패널 (이미지 패널 우선)
    final goldPanelRect = Rect.fromLTWH(size.x / 2 - 70, size.y * 0.14, 140, 28);
    final goldPanelImg = _tryGetImage('ui/panel_dark_yellow.png');
    if (goldPanelImg != null) {
      _drawImagePanel(canvas, 'ui/panel_dark_yellow.png', goldPanelRect);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(goldPanelRect, const Radius.circular(14)),
        Paint()..color = const Color(0xFF2A1C00),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(goldPanelRect, const Radius.circular(14)),
        Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    // 코인 아이콘 + 골드 텍스트
    _drawImageIcon(canvas, 'icons/icon_hud_coin.png',
        Offset(size.x / 2 - 40, size.y * 0.19 + 14), 18, fallbackEmoji: '🪙');
    _drawCenteredText(
      canvas,
      '  $playerGold G',
      Offset(size.x / 2 + 6, size.y * 0.19 + 14),
      fontSize: 14,
      color: const Color(0xFFFFD700),
    );

    // 상점 아이템 3개
    const List<String> names  = ['城 最大HP +20', 'タワー 攻撃力 +5%', 'メインHP +10'];
    const List<String> icons  = ['🏰', '🗼', '🧑'];
    // 아이콘 이미지 경로 (이미지 우선, 폴백 이모지)
    const List<String> iconImages = ['ui/icon_heal.png', 'ui/icon_tower.png', 'icons/icon_heart.png'];
    const List<int>    prices = [50, 30, 20];
    final List<int> counts    = [_shopCastleMaxHpCount, _shopTowerPowerCount, _shopMainCharHpCount];
    const List<int> maxes     = [10, 10, 5];
    // 탭 존 중앙 Y 좌표
    final List<double> centerYs = [
      size.y * 0.40,
      size.y * 0.575,
      size.y * 0.725,
    ];

    for (int i = 0; i < 3; i++) {
      final bool maxed       = counts[i] >= maxes[i];
      final bool affordable  = !maxed && playerGold >= prices[i];
      final Color bgColor    = maxed ? const Color(0xFF1A1A1A)
          : affordable ? const Color(0xFF1A1040)
          : const Color(0xFF151515);
      final Color borderColor = maxed ? const Color(0xFF444444)
          : affordable ? const Color(0xFF7C3AED)
          : const Color(0xFF555555);
      final Color textColor  = maxed ? const Color(0xFF666666)
          : affordable ? const Color(0xFFFFFFFF)
          : const Color(0xFF888888);

      final double cardH = 70.0;
      final cardRect = Rect.fromLTWH(20, centerYs[i] - cardH / 2, size.x - 40, cardH);

      // 카드 배경 (이미지 패널 우선)
      final cardPanelAsset = affordable ? 'ui/panel_dark_purple.png' : 'ui/panel_dark.png';
      final cardPanelImg = _tryGetImage(cardPanelAsset);
      if (cardPanelImg != null) {
        _drawImagePanel(canvas, cardPanelAsset, cardRect, alpha: maxed ? 0.5 : 1.0);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(cardRect, const Radius.circular(10)),
          Paint()..color = bgColor,
        );
      }
      // 카드 테두리
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(10)),
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // 아이콘 (이미지 우선)
      _drawImageIcon(
        canvas,
        iconImages[i],
        Offset(cardRect.left + 35, centerYs[i]),
        26,
        fallbackEmoji: icons[i],
      );

      // 아이템 이름
      _drawCenteredText(
        canvas,
        names[i],
        Offset(cardRect.left + 110, centerYs[i] - 10),
        fontSize: 13,
        color: textColor,
      );

      // 구매 횟수 표시
      _drawCenteredText(
        canvas,
        maxed ? 'MAX' : '${counts[i]} / ${maxes[i]}',
        Offset(cardRect.left + 110, centerYs[i] + 10),
        fontSize: 11,
        color: maxed ? const Color(0xFF888888) : const Color(0xFFAAAAAA),
      );

      // 가격 배지
      final priceColor = affordable ? const Color(0xFFFFD700) : const Color(0xFF888888);
      final priceBgRect = Rect.fromLTWH(
        cardRect.right - 62, centerYs[i] - 14, 54, 28,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(priceBgRect, const Radius.circular(8)),
        Paint()..color = maxed ? const Color(0xFF222222) : const Color(0xFF2A1C00),
      );
      _drawCenteredText(
        canvas,
        maxed ? 'MAX' : '${prices[i]}G',
        Offset(priceBgRect.center.dx, priceBgRect.center.dy),
        fontSize: 13,
        color: priceColor,
      );
    }

    // 계속 버튼 (y > 0.80) — 이미지 버튼 우선
    final continueRect = Rect.fromLTWH(
      (size.x - 200) / 2, size.y * 0.84, 200, 44,
    );
    _drawImageButton(canvas, 'ui/btn_violet.png', continueRect, '続ける  →');
  }

  void _renderLoadingOverlay(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '準備中...',
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

    // 로딩 바 (이미지 바 우선)
    _drawImageBar(
      canvas,
      'ui/bar_background.png',
      'ui/bar_blue.png',
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      progress,
      fallbackBgColor: const Color(0xFF424242),
      fallbackFillColor: const Color(0xFF42A5F5),
    );
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

    // 골드 (이미지 아이콘 우선)
    _renderResourceHorizontalImg(
      canvas,
      Offset(resourceStartX, navBarHeight / 2),
      'icons/icon_hud_coin.png',
      '💰',
      _formatNumber(playerGold),
    );

    // 젬 (이미지 아이콘 우선)
    _renderResourceHorizontalImg(
      canvas,
      Offset(resourceStartX + resourceSpacing, navBarHeight / 2),
      'icons/icon_hud_gem.png',
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

  // 개별 리소스 렌더링 헬퍼 (이미지 아이콘 우선)
  void _renderResourceHorizontalImg(
    Canvas canvas,
    Offset position,
    String imagePath,
    String fallbackEmoji,
    String value,
  ) {
    // 아이콘 (이미지 우선)
    _drawImageIcon(canvas, imagePath,
        Offset(position.dx, position.dy - 8), 18, fallbackEmoji: fallbackEmoji);

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
    final double backgroundHeight = size.y - topMargin - CastleDefenseGame._bottomMenuHeight;

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
        final y = size.y - CastleDefenseGame._bottomMenuHeight - 150 + random.nextDouble() * 100;
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

    // 파티 슬롯 렌더링 (홈 화면에서만 표시)
    if (currentBottomMenu == BottomMenu.home) {
      _renderPartySlots(canvas);
    }

    // 파티 선택 팝업 (최상단)
    if (showPartySelectionPopup) {
      _renderPartySelectionPopup(canvas);
    }
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

  // 파티 선택 팝업 렌더링 (그리드 레이아웃)
  void _renderPartySelectionPopup(Canvas canvas) {
    // 반투명 배경 (전체 화면)
    final overlayPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlayPaint);

    // 팝업 박스
    const double popupWidth = 350.0;
    const double popupHeight = 500.0;
    final double popupX = (size.x - popupWidth) / 2;
    final double popupY = (size.y - popupHeight) / 2;
    final popupRect = Rect.fromLTWH(popupX, popupY, popupWidth, popupHeight);

    // 팝업 배경
    final popupBgPaint = Paint()..color = const Color(0xFF2C2C2C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(popupRect, const Radius.circular(16)),
      popupBgPaint,
    );

    // 팝업 테두리
    final popupBorderPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(popupRect, const Radius.circular(16)),
      popupBorderPaint,
    );

    // 헤더
    _drawCenteredText(
      canvas,
      'キャラクター選択',
      Offset(popupRect.center.dx, popupY + 25),
      fontSize: 18,
      color: const Color(0xFFFFFFFF),
    );

    // 닫기 버튼 (X)
    final closeButtonRect = Rect.fromLTWH(popupX + popupWidth - 40, popupY + 10, 30, 30);
    final closeButtonPaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(closeButtonRect.center, 15, closeButtonPaint);
    _drawCenteredText(
      canvas,
      '✕',
      closeButtonRect.center,
      fontSize: 18,
      color: const Color(0xFFFFFFFF),
    );

    // 보유 캐릭터가 없는 경우
    if (ownedCharacters.isEmpty) {
      _drawCenteredText(
        canvas,
        '所持キャラクターがいません',
        Offset(popupRect.center.dx, popupRect.center.dy),
        fontSize: 16,
        color: const Color(0xFF999999),
      );
      return;
    }

    // 캐릭터 목록 영역 (그리드)
    const double listStartY = 60.0;
    const double bottomButtonHeight = 50.0;
    final double listHeight = popupHeight - listStartY - bottomButtonHeight - 10;

    const double cardWidth = 60.0;
    const double cardHeight = 80.0;
    const double cardSpacing = 10.0;
    const int cardsPerRow = 4;

    // 스크롤 영역 클리핑
    canvas.save();
    final clipRect = Rect.fromLTWH(
      popupX + 15,
      popupY + listStartY,
      popupWidth - 30,
      listHeight,
    );
    canvas.clipRect(clipRect);

    // 배경
    final listBgPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(clipRect, const Radius.circular(8)),
      listBgPaint,
    );

    // 캐릭터별 개수 계산 및 중복 제거
    final characterMap = <String, List<OwnedCharacter>>{};
    for (final character in ownedCharacters) {
      if (!characterMap.containsKey(character.characterId)) {
        characterMap[character.characterId] = [];
      }
      characterMap[character.characterId]!.add(character);
    }

    // 고유 캐릭터 목록으로 렌더링
    final uniqueCharacterIds = characterMap.keys.toList();
    for (int i = 0; i < uniqueCharacterIds.length; i++) {
      final characterId = uniqueCharacterIds[i];
      final characterInstances = characterMap[characterId]!;
      final character = characterInstances.first; // 첫 번째 인스턴스 사용
      final definition = CharacterDefinitions.byId(character.characterId);
      final count = characterInstances.length;

      final row = i ~/ cardsPerRow;
      final col = i % cardsPerRow;

      final double x = popupX + 20 + col * (cardWidth + cardSpacing);
      final double y = popupY + listStartY + 10 + row * (cardHeight + cardSpacing) - partyPopupScrollOffset;

      // 화면 밖이면 스킵
      if (y + cardHeight < popupY + listStartY || y > popupY + listStartY + listHeight) {
        continue;
      }

      final cardRect = Rect.fromLTWH(x, y, cardWidth, cardHeight);

      // 이 캐릭터의 어떤 인스턴스라도 파티에 있는지 확인
      final isInParty = characterInstances.any((c) => partySlots.contains(c.instanceId));

      // 카드 배경
      final cardBgPaint = Paint()..color = isInParty
          ? const Color(0xFF1B5E20) // 파티에 있으면 어두운 초록
          : const Color(0xFF424242);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
        cardBgPaint,
      );

      // 카드 테두리 (랭크 색상)
      Color rankColor;
      switch (definition.rank) {
        case RankType.s:
          rankColor = const Color(0xFFFFD700);
          break;
        case RankType.a:
          rankColor = const Color(0xFFFF6B6B);
          break;
        case RankType.b:
          rankColor = const Color(0xFF4ECDC4);
          break;
        case RankType.c:
          rankColor = const Color(0xFFBDBDBD);
          break;
      }

      final cardBorderPaint = Paint()
        ..color = rankColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
        cardBorderPaint,
      );

      // 랭크 표시 (좌측 상단)
      _drawText(
        canvas,
        definition.rank.displayName,
        Offset(x + 4, y + 4),
        fontSize: 10,
        color: rankColor,
      );

      // 캐릭터 이름 (중앙)
      _drawCenteredText(
        canvas,
        definition.name,
        Offset(cardRect.center.dx, y + cardHeight / 2),
        fontSize: 10,
        color: const Color(0xFFFFFFFF),
      );

      // 레벨 (하단)
      _drawCenteredText(
        canvas,
        'Lv.${character.level}',
        Offset(cardRect.center.dx, y + cardHeight - 12),
        fontSize: 9,
        color: const Color(0xFFBDBDBD),
      );

      // 파티에 있으면 체크 표시
      if (isInParty) {
        _drawText(
          canvas,
          '✓',
          Offset(x + cardWidth - 15, y + 4),
          fontSize: 12,
          color: const Color(0xFF4CAF50),
        );
      }

      // 개수 표시 (우측 하단, 2개 이상일 때만)
      if (count > 1) {
        // 배경 원
        final countBgPaint = Paint()..color = const Color(0xCC000000);
        canvas.drawCircle(
          Offset(x + cardWidth - 12, y + cardHeight - 12),
          10,
          countBgPaint,
        );

        // 개수 텍스트
        _drawCenteredText(
          canvas,
          'x$count',
          Offset(x + cardWidth - 12, y + cardHeight - 12),
          fontSize: 8,
          color: const Color(0xFFFFFFFF),
        );
      }
    }

    canvas.restore();

    // "제거" 버튼 (슬롯에 캐릭터가 있는 경우만)
    if (selectedPartySlotIndex >= 0 && partySlots[selectedPartySlotIndex] != null) {
      final removeButtonRect = Rect.fromLTWH(
        popupX + 20,
        popupY + popupHeight - 45,
        popupWidth - 40,
        35,
      );

      final removeButtonPaint = Paint()..color = const Color(0xFFFF5252);
      canvas.drawRRect(
        RRect.fromRectAndRadius(removeButtonRect, const Radius.circular(8)),
        removeButtonPaint,
      );

      _drawCenteredText(
        canvas,
        'パーティから外す',
        removeButtonRect.center,
        fontSize: 14,
        color: const Color(0xFFFFFFFF),
      );
    }
  }

  // 파티 슬롯 렌더링 (도감 스타일)
  void _renderPartySlots(Canvas canvas) {
    const double bottomMenuHeight = 70.0;
    const double slotSize = 60.0; // 도감과 동일한 크기
    const double slotSpacing = 10.0; // 도감과 동일한 간격
    final double slotY = size.y - bottomMenuHeight - slotSize - 8.0; // 푸터 바로 위

    // 파티 설정 배경 (반투명 회색) - 5슬롯 (메인1 + 타워4)
    const double bgPadding = 10.0;
    final double bgWidth = (slotSize * 5) + (slotSpacing * 4) + (bgPadding * 2);
    final double bgX = (size.x - bgWidth) / 2;
    final bgRect = Rect.fromLTWH(bgX, slotY - bgPadding - 15, bgWidth, slotSize + bgPadding * 2 + 15);

    final bgPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
      bgPaint,
    );

    // "PARTY" 라벨 (위쪽에 배치)
    _drawCenteredText(
      canvas,
      'PARTY',
      Offset(bgRect.center.dx, bgRect.top + 10),
      fontSize: 10,
      color: const Color(0xFFFFFFFF),
    );

    // 5개의 슬롯 렌더링 (메인1 + 타워4)
    for (int i = 0; i < 5; i++) {
      final double slotX = (size.x - (slotSize * 5 + slotSpacing * 4)) / 2 + i * (slotSize + slotSpacing);
      final slotRect = Rect.fromLTWH(slotX, slotY, slotSize, slotSize);

      final instanceId = partySlots[i];

      if (instanceId != null) {
        // 캐릭터가 설정된 경우
        final character = ownedCharacters.firstWhere(
          (c) => c.instanceId == instanceId,
          orElse: () => ownedCharacters.first,
        );
        final definition = CharacterDefinitions.byId(character.characterId);

        // 카드 배경 (랭크 색상 + 반투명)
        final bgColor = Color(definition.rank.color).withOpacity(0.3);
        final cardPaint = Paint()..color = bgColor;
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(8)),
          cardPaint,
        );

        // 테두리 (랭크 색상)
        final borderPaint = Paint()
          ..color = Color(definition.rank.color)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(8)),
          borderPaint,
        );

        // 랭크 표시 (상단)
        _drawCenteredText(
          canvas,
          definition.rank.displayName,
          Offset(slotRect.center.dx, slotY + 12),
          fontSize: 10,
          color: Color(definition.rank.color),
        );

        // 역할 이모지 (중앙)
        _drawCenteredText(
          canvas,
          definition.role.emoji,
          Offset(slotRect.center.dx, slotRect.center.dy - 2),
          fontSize: 22,
        );

        // 캐릭터 이름 (하단, 짧게)
        final shortName = definition.name.length > 5
            ? '${definition.name.substring(0, 5)}..'
            : definition.name;
        _drawCenteredText(
          canvas,
          shortName,
          Offset(slotRect.center.dx, slotY + slotSize - 12),
          fontSize: 8,
          color: const Color(0xFF000000),
        );

        // 레벨 배지 (우측 하단)
        final levelBadgeRect = Rect.fromLTWH(
          slotX + slotSize - 22,
          slotY + slotSize - 18,
          20,
          14,
        );
        final levelBadgePaint = Paint()..color = const Color(0xFF4CAF50);
        canvas.drawRRect(
          RRect.fromRectAndRadius(levelBadgeRect, const Radius.circular(7)),
          levelBadgePaint,
        );
        _drawCenteredText(
          canvas,
          'L${character.level}',
          levelBadgeRect.center,
          fontSize: 8,
          color: const Color(0xFFFFFFFF),
        );
      } else {
        // 빈 슬롯 (도감 스타일)
        final slotBgPaint = Paint()..color = const Color(0xFFBDBDBD);
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(8)),
          slotBgPaint,
        );

        // 테두리
        final slotBorderPaint = Paint()
          ..color = const Color(0xFF757575)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(8)),
          slotBorderPaint,
        );

        // 빈 슬롯 표시
        _drawCenteredText(
          canvas,
          '+',
          slotRect.center,
          fontSize: 28,
          color: const Color(0xFF757575),
        );
      }
    }
  }

  // 상점 콘텐츠 (플레이스홀더)
  void _renderShopContent(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '🏪 ショップ',
      Offset(size.x / 2, size.y * 0.4),
      fontSize: 32,
      color: const Color(0xFF000000),
    );

    _drawCenteredText(
      canvas,
      '準備中...',
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
      '準備中...',
      Offset(size.x / 2, size.y * 0.5),
      fontSize: 18,
      color: const Color(0xFF666666),
    );
  }

  // 뽑기 콘텐츠 (플레이스홀더)
  void _renderGachaContent(Canvas canvas) {
    const double navBarHeight = 60.0;
    const double contentStartY = navBarHeight + 10;

    // 뽑기 결과 표시 중이면 결과 화면
    if (gachaResults != null && gachaResults!.isNotEmpty) {
      _renderGachaResults(canvas);
      return;
    }

    // 타이틀 & 젬 표시 (한 줄로 압축)
    _drawCenteredText(
      canvas,
      '🎰 소환  |  💎 $playerGem',
      Offset(size.x / 2, contentStartY + 15),
      fontSize: 18,
      color: const Color(0xFF000000),
    );

    // 단일 뽑기 버튼
    final singleButtonRect = _gachaSingleButtonRect();
    final singleCost = gachaSystem.getSingleSummonCost();
    final canAffordSingle = playerGem >= singleCost;

    final singleBgPaint = Paint()
      ..color = canAffordSingle
          ? const Color(0xFF4CAF50)
          : const Color(0xFFBDBDBD);

    canvas.drawRRect(
      RRect.fromRectAndRadius(singleButtonRect, const Radius.circular(12)),
      singleBgPaint,
    );

    _drawCenteredText(
      canvas,
      '単体召喚',
      Offset(singleButtonRect.center.dx, singleButtonRect.center.dy - 15),
      fontSize: 20,
      color: const Color(0xFFFFFFFF),
    );

    _drawCenteredText(
      canvas,
      '💎 $singleCost',
      Offset(singleButtonRect.center.dx, singleButtonRect.center.dy + 10),
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );

    // 10연차 뽑기 버튼
    final tenButtonRect = _gachaTenButtonRect();
    final tenCost = gachaSystem.getTenSummonCost();
    final canAffordTen = playerGem >= tenCost;

    final tenBgPaint = Paint()
      ..color = canAffordTen ? const Color(0xFFFF9800) : const Color(0xFFBDBDBD);

    canvas.drawRRect(
      RRect.fromRectAndRadius(tenButtonRect, const Radius.circular(12)),
      tenBgPaint,
    );

    _drawCenteredText(
      canvas,
      '10연차 소환',
      Offset(tenButtonRect.center.dx, tenButtonRect.center.dy - 25),
      fontSize: 20,
      color: const Color(0xFFFFFFFF),
    );

    _drawCenteredText(
      canvas,
      '💎 $tenCost',
      Offset(tenButtonRect.center.dx, tenButtonRect.center.dy),
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );

    _drawCenteredText(
      canvas,
      '(A랭크 이상 1개 보장)',
      Offset(tenButtonRect.center.dx, tenButtonRect.center.dy + 20),
      fontSize: 12,
      color: const Color(0xFFFFFFFF),
    );

    // 확률 안내
    const infoStartY = 135.0;
    _drawCenteredText(
      canvas,
      'S: 3% | A: 12% | B: 35% | C: 50%',
      Offset(size.x / 2, infoStartY),
      fontSize: 11,
      color: const Color(0xFF666666),
    );

    // 캐릭터 도감 영역
    _renderCharacterCollection(canvas);
  }

  Rect _gachaSingleButtonRect() {
    const double navBarHeight = 60.0;
    const double buttonWidth = 140.0;
    const double buttonHeight = 70.0;
    const double buttonSpacing = 10.0;
    const double topMargin = 15.0;

    final double centerX = size.x / 2;
    final double y = navBarHeight + topMargin;

    return Rect.fromLTWH(centerX - buttonWidth - buttonSpacing / 2, y, buttonWidth, buttonHeight);
  }

  Rect _gachaTenButtonRect() {
    const double navBarHeight = 60.0;
    const double buttonWidth = 140.0;
    const double buttonHeight = 70.0;
    const double buttonSpacing = 10.0;
    const double topMargin = 15.0;

    final double centerX = size.x / 2;
    final double y = navBarHeight + topMargin;

    return Rect.fromLTWH(centerX + buttonSpacing / 2, y, buttonWidth, buttonHeight);
  }

  void _renderCharacterCollection(Canvas canvas) {
    const double collectionStartY = 165.0;
    const double bottomMenuHeight = 70.0;
    const double availableHeight = 600.0 - collectionStartY - bottomMenuHeight - 20;

    // 타이틀
    _drawCenteredText(
      canvas,
      '📖 キャラクター図鑑',
      Offset(size.x / 2, collectionStartY),
      fontSize: 16,
      color: const Color(0xFF000000),
    );

    // 보유/전체 표시 및 중복 개수 계산
    final ownedCountMap = <String, int>{};
    for (final owned in ownedCharacters) {
      ownedCountMap[owned.characterId] =
          (ownedCountMap[owned.characterId] ?? 0) + 1;
    }
    final totalCharacters = CharacterDefinitions.all.length;
    final ownedCount = ownedCountMap.keys.length;

    _drawCenteredText(
      canvas,
      '所持: $ownedCount / $totalCharacters',
      Offset(size.x / 2, collectionStartY + 25),
      fontSize: 12,
      color: const Color(0xFF666666),
    );

    // 캐릭터 리스트 영역
    const double listStartY = collectionStartY + 50;
    const double cardWidth = 60.0;
    const double cardHeight = 80.0;
    const double cardSpacing = 10.0;
    const int cardsPerRow = 5;

    // 스크롤 영역 클리핑
    canvas.save();
    final clipRect = Rect.fromLTWH(
      10,
      listStartY,
      size.x - 20,
      availableHeight,
    );
    canvas.clipRect(clipRect);

    // 배경
    final bgPaint = Paint()..color = const Color(0xFFF5F5F5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(clipRect, const Radius.circular(8)),
      bgPaint,
    );

    // 캐릭터 카드 렌더링
    final allCharacters = CharacterDefinitions.all;
    final totalRows = (allCharacters.length / cardsPerRow).ceil();

    for (int i = 0; i < allCharacters.length; i++) {
      final character = allCharacters[i];
      final row = i ~/ cardsPerRow;
      final col = i % cardsPerRow;

      final count = ownedCountMap[character.id] ?? 0;
      final isOwned = count > 0;

      final double x = 15 + col * (cardWidth + cardSpacing);
      final double y = listStartY + 10 + row * (cardHeight + cardSpacing) -
          characterListScrollOffset;

      // 화면 밖이면 스킵
      if (y + cardHeight < listStartY || y > listStartY + availableHeight) {
        continue;
      }

      _renderCharacterCard(
        canvas,
        character,
        Offset(x, y),
        cardWidth,
        cardHeight,
        isOwned,
        count,
      );
    }

    canvas.restore();

    // 스크롤 인디케이터
    if (totalRows * (cardHeight + cardSpacing) > availableHeight) {
      final scrollBarHeight = availableHeight * 0.3;
      final maxScroll =
          totalRows * (cardHeight + cardSpacing) - availableHeight + 20;
      final scrollRatio = characterListScrollOffset / maxScroll;

      final indicatorY =
          listStartY + scrollRatio * (availableHeight - scrollBarHeight);

      final scrollBarPaint = Paint()..color = const Color(0x80000000);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.x - 15, indicatorY, 5, scrollBarHeight),
          const Radius.circular(2.5),
        ),
        scrollBarPaint,
      );
    }
  }

  void _renderCharacterCard(
    Canvas canvas,
    CharacterDefinition character,
    Offset position,
    double width,
    double height,
    bool isOwned,
    int count,
  ) {
    final cardRect = Rect.fromLTWH(position.dx, position.dy, width, height);

    // 카드 배경
    final bgColor = isOwned
        ? Color(character.rank.color).withOpacity(0.3)
        : const Color(0xFFBDBDBD);

    final cardPaint = Paint()..color = bgColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
      cardPaint,
    );

    // 테두리
    final borderPaint = Paint()
      ..color = isOwned ? Color(character.rank.color) : const Color(0xFF757575)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
      borderPaint,
    );

    if (isOwned) {
      // 랭크 표시
      _drawCenteredText(
        canvas,
        character.rank.displayName,
        Offset(cardRect.center.dx, cardRect.top + 12),
        fontSize: 10,
        color: Color(character.rank.color),
      );

      // 역할 이모지
      _drawCenteredText(
        canvas,
        character.role.emoji,
        Offset(cardRect.center.dx, cardRect.center.dy - 5),
        fontSize: 24,
      );

      // 캐릭터 이름 (짧게)
      final shortName = character.name.length > 6
          ? '${character.name.substring(0, 6)}..'
          : character.name;

      _drawCenteredText(
        canvas,
        shortName,
        Offset(cardRect.center.dx, cardRect.bottom - 15),
        fontSize: 9,
        color: const Color(0xFF000000),
      );

      // 중복 보유 개수 표시 (2개 이상일 때만)
      if (count > 1) {
        // 우측 상단에 배지 형태로 표시
        final badgeRect = Rect.fromLTWH(
          cardRect.right - 20,
          cardRect.top + 2,
          18,
          12,
        );

        final badgePaint = Paint()..color = const Color(0xFFFF5252);
        canvas.drawRRect(
          RRect.fromRectAndRadius(badgeRect, const Radius.circular(6)),
          badgePaint,
        );

        _drawCenteredText(
          canvas,
          'x$count',
          Offset(badgeRect.center.dx, badgeRect.center.dy),
          fontSize: 8,
          color: const Color(0xFFFFFFFF),
        );
      }
    } else {
      // 잠김 아이콘
      _drawCenteredText(
        canvas,
        '🔒',
        Offset(cardRect.center.dx, cardRect.center.dy - 10),
        fontSize: 20,
        color: const Color(0xFF757575),
      );

      // ???
      _drawCenteredText(
        canvas,
        '???',
        Offset(cardRect.center.dx, cardRect.bottom - 15),
        fontSize: 10,
        color: const Color(0xFF757575),
      );
    }
  }

  void _renderGachaResults(Canvas canvas) {
    if (gachaResults == null || gachaResults!.isEmpty) return;

    const double navBarHeight = 60.0;
    const double startY = navBarHeight + 40;

    // 배경 어둡게
    final dimPaint = Paint()..color = const Color(0xDD000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), dimPaint);

    // 타이틀
    _drawCenteredText(
      canvas,
      '✨ 소환 결과 ✨',
      Offset(size.x / 2, startY),
      fontSize: 26,
      color: const Color(0xFFFFFFFF),
    );

    // 현재 표시 중인 캐릭터
    if (gachaResultIndex < gachaResults!.length) {
      final character = gachaResults![gachaResultIndex];
      final cardY = startY + 80;

      // 카드 배경
      final cardRect = Rect.fromCenter(
        center: Offset(size.x / 2, cardY + 100),
        width: 280,
        height: 200,
      );

      final cardPaint = Paint()..color = Color(character.rank.color);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(16)),
        cardPaint,
      );

      // 랭크 표시
      _drawCenteredText(
        canvas,
        '${character.rank.displayName} 랭크',
        Offset(size.x / 2, cardY + 20),
        fontSize: 20,
        color: const Color(0xFFFFFFFF),
      );

      // 역할 이모지
      _drawCenteredText(
        canvas,
        character.role.emoji,
        Offset(size.x / 2, cardY + 60),
        fontSize: 40,
      );

      // 캐릭터 이름
      _drawCenteredText(
        canvas,
        character.name,
        Offset(size.x / 2, cardY + 120),
        fontSize: 18,
        color: const Color(0xFFFFFFFF),
      );

      // 역할
      _drawCenteredText(
        canvas,
        character.role.displayName,
        Offset(size.x / 2, cardY + 145),
        fontSize: 14,
        color: const Color(0xFFE0E0E0),
      );

      // 진행 상황
      _drawCenteredText(
        canvas,
        '${gachaResultIndex + 1} / ${gachaResults!.length}',
        Offset(size.x / 2, cardY + 180),
        fontSize: 14,
        color: const Color(0xFFFFFFFF),
      );

      // 안내 메시지
      _drawCenteredText(
        canvas,
        '画面をタッチして続行',
        Offset(size.x / 2, size.y - 120),
        fontSize: 16,
        color: const Color(0xFFFFFFFF),
      );
    }
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
      '準備中...',
      Offset(size.x / 2, size.y * 0.5),
      fontSize: 18,
      color: const Color(0xFF666666),
    );
  }

  // 하단 메뉴 렌더링
  void _renderBottomMenu(Canvas canvas) {
    // 메뉴 배경
    final menuBgPaint = Paint()..color = const Color(0xFFFFFFFF);
    final menuRect = Rect.fromLTWH(0, size.y - CastleDefenseGame._bottomMenuHeight, size.x, CastleDefenseGame._bottomMenuHeight);
    canvas.drawRect(menuRect, menuBgPaint);

    // 상단 경계선
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.y - CastleDefenseGame._bottomMenuHeight),
      Offset(size.x, size.y - CastleDefenseGame._bottomMenuHeight),
      borderPaint,
    );

    // 메뉴 아이템들 (이미지 아이콘 경로 추가)
    final menuItems = [
      {'icon': '🏪', 'img': 'icons/icon_hud_shop.png', 'label': 'ショップ', 'menu': BottomMenu.shop},
      {'icon': '🎒', 'img': 'icons/icon_shield.png', 'label': 'インベントリ', 'menu': BottomMenu.inventory},
      {'icon': '🏠', 'img': 'icons/icon_crown.png', 'label': 'ホーム', 'menu': BottomMenu.home},
      {'icon': '🎰', 'img': 'icons/icon_gem.png', 'label': 'ガチャ', 'menu': BottomMenu.gacha},
      {'icon': '⚙️', 'img': 'icons/icon_settings.png', 'label': '設定', 'menu': BottomMenu.settings},
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

      // 아이콘 (이미지 우선)
      _drawImageIcon(
        canvas,
        item['img'] as String,
        Offset(rect.center.dx, rect.center.dy - 12),
        26,
        fallbackEmoji: item['icon'] as String,
        alpha: isSelected ? 1.0 : 0.5,
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

  // D-1-6: 라운드 클리어 연출 (강화)
  void _renderRoundClearOverlay(Canvas canvas) {
    // 반투명 오버레이 (그라디언트 느낌)
    final overlayPaint = Paint()..color = const Color(0xA0000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlayPaint);

    String title = 'Round $currentRound Clear!';
    Color titleColor = const Color(0xFF00E676);
    bool isBoss = false;
    bool isMiniBoss = false;

    final cfg = kStageConfigs[stageLevel];
    if (cfg != null && currentRound <= cfg.rounds.length) {
      final roundCfg = cfg.rounds[currentRound - 1];
      if (roundCfg.monsterType == MonsterType.boss) {
        title = '🎉 BOSS DEFEATED! 🎉';
        titleColor = const Color(0xFFFFD700);
        isBoss = true;
      } else if (roundCfg.monsterType == MonsterType.miniBoss) {
        title = '⚡ MINI BOSS DEFEATED! ⚡';
        titleColor = const Color(0xFFFF6E40);
        isMiniBoss = true;
      }
    }

    // 보스/미니보스 클리어 시: 배경 광채 펄스
    if (isBoss || isMiniBoss) {
      final double pulseAlpha = 0.08 + 0.07 * sin(gameTime * 4);
      final glowColor = isBoss ? const Color(0xFFFFD700) : const Color(0xFFFF6E40);
      final glowPaint = Paint()
        ..color = Color.fromRGBO(
          glowColor.red, glowColor.green, glowColor.blue, pulseAlpha);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), glowPaint);
    }

    // 제목 (펄스 크기 효과: sin으로 폰트 크기 미세 변동은 Canvas로 불가 → 색상 밝기로 대신)
    final double textBrightness = 0.85 + 0.15 * sin(gameTime * 3);
    final r = (titleColor.red * textBrightness).clamp(0.0, 255.0).toInt();
    final g = (titleColor.green * textBrightness).clamp(0.0, 255.0).toInt();
    final b = (titleColor.blue * textBrightness).clamp(0.0, 255.0).toInt();
    _drawCenteredText(
      canvas, title,
      Offset(size.x / 2, size.y * 0.38),
      fontSize: isBoss ? 26 : 24,
      color: Color.fromRGBO(r, g, b, 1.0),
    );

    // 스테이지 표시
    _drawCenteredText(
      canvas, 'Stage $stageLevel',
      Offset(size.x / 2, size.y * 0.48),
      fontSize: 13,
      color: const Color(0xFFAAAAAA),
    );

    // D-1-6: 획득 XP/골드 플라이인 애니메이션
    // t=0~0.5s: 슬라이드업+페이드인 / t=0.5~2.5s: 유지 / t=2.5~3.0s: 페이드아웃
    if (_roundXpGained > 0 || _roundGoldGained > 0) {
      final double t = _roundClearTimer.clamp(0.0, _roundClearDuration);
      final double flyAlpha;
      final double slideY;
      if (t < 0.5) {
        final double p = t / 0.5;
        flyAlpha = p;
        slideY = 20.0 * (1.0 - p);
      } else if (t < 2.5) {
        flyAlpha = 1.0;
        slideY = 0.0;
      } else {
        final double p = (t - 2.5) / 0.5;
        flyAlpha = (1.0 - p).clamp(0.0, 1.0);
        slideY = 0.0;
      }
      // XP 획득 표시 (파란색, 좌측)
      if (_roundXpGained > 0) {
        _drawCenteredText(
          canvas,
          '+$_roundXpGained XP',
          Offset(size.x * 0.35, size.y * 0.57 + slideY),
          fontSize: 18,
          color: Color.fromRGBO(33, 150, 243, flyAlpha),
        );
      }
      // 골드 획득 표시 (금색, 우측)
      if (_roundGoldGained > 0) {
        _drawCenteredText(
          canvas,
          '+${_roundGoldGained}G',
          Offset(size.x * 0.65, size.y * 0.57 + slideY),
          fontSize: 18,
          color: Color.fromRGBO(255, 215, 0, flyAlpha),
        );
      }
    }

    // 다음 라운드 카운트다운 바 (이미지 바 우선)
    final double progressRatio = _roundClearDuration > 0
        ? (1.0 - _roundClearTimer / _roundClearDuration).clamp(0.0, 1.0)
        : 0.0;
    const double barW = 160.0;
    const double barH = 6.0;
    final double barX = size.x / 2 - barW / 2;
    final double barY = size.y * 0.64;

    _drawImageBar(
      canvas,
      'ui/bar_background.png',
      'ui/bar_green.png',
      Rect.fromLTWH(barX, barY, barW, barH),
      progressRatio,
      fallbackBgColor: const Color(0xFF333333),
      fallbackFillColor: const Color(0xFF4CAF50),
    );

    _drawCenteredText(
      canvas, '次のラウンド準備中...',
      Offset(size.x / 2, size.y * 0.59),
      fontSize: 13,
      color: const Color(0xFF888888),
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
      '一時停止',
      Offset(size.x / 2, size.y * 0.35),
      fontSize: 32,
      color: const Color(0xFFFFFFFF),
    );

    // 버튼 그리기 (이미지 버튼 우선)
    final resumeRect = _pauseResumeButtonRect();
    final roundSelectRect = _pauseRoundSelectButtonRect();
    final retryRect = _pauseRetryButtonRect();

    // 재개 버튼
    _drawImageButton(canvas, 'ui/btn_green.png', resumeRect, '再開', fontSize: 18);

    // 라운드 선택 버튼
    _drawImageButton(canvas, 'ui/btn_blue.png', roundSelectRect, 'ラウンド選択', fontSize: 18);

    // 재시작 버튼
    _drawImageButton(canvas, 'ui/btn_red.png', retryRect, 'リスタート', fontSize: 18);
  }

  void _renderResultOverlay(Canvas canvas) {
    // 게임 오버 (성 HP=0) 는 전용 화면으로
    if (!_lastStageClear) {
      _renderGameOver(canvas);
      return;
    }

    final overlayPaint = Paint()..color = const Color(0xC0000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      overlayPaint,
    );

    // 클리어 제목
    _drawCenteredText(
      canvas,
      'Round $currentRound クリア!',
      Offset(size.x / 2, size.y * 0.25),
      fontSize: 28,
      color: const Color(0xFF00E676),
    );

    // 별점 표시
    final stars = _calculateStars();
    _renderStars(canvas, stars, Offset(size.x / 2, size.y * 0.35));

    // 획득 골드 표시
    _drawCenteredText(
      canvas,
      '獲得ゴールド: ${_roundGoldGained}G',
      Offset(size.x / 2, size.y * 0.45),
      fontSize: 16,
      color: const Color(0xFFFFD700),
    );

    final retryRect = _resultRetryButtonRect();
    final roundSelectRect = _resultRoundSelectButtonRect();
    final nextRect = _resultNextRoundButtonRect();

    _drawImageButton(canvas, 'ui/btn_violet.png', retryRect, 'もう一度');
    _drawImageButton(canvas, 'ui/btn_violet.png', roundSelectRect, 'ステージ選択');

    final nextRound = currentRound + 1;
    if (nextRound <= totalRoundsInStage) {
      _drawImageButton(canvas, 'ui/btn_green.png', nextRect, '次のラウンド');
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

  // D-2-3: 게임 오버 화면 (통일 디자인: 클리어 화면과 동일 레이아웃)
  void _renderGameOver(Canvas canvas) {
    // 반투명 어두운 배경 (클리어 화면과 통일)
    final overlayPaint = Paint()..color = const Color(0xC0000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlayPaint);

    // "GAME OVER" 타이틀
    _drawCenteredText(
      canvas,
      'GAME OVER',
      Offset(size.x / 2, size.y * 0.25),
      fontSize: 28,
      color: const Color(0xFFEF5350),
    );

    // 라운드 표시
    _drawCenteredText(
      canvas,
      'Round $currentRound',
      Offset(size.x / 2, size.y * 0.35),
      fontSize: 16,
      color: const Color(0xFFBBBBBB),
    );

    // 획득 골드 표시
    _drawCenteredText(
      canvas,
      '獲得ゴールド: ${_roundGoldGained}G',
      Offset(size.x / 2, size.y * 0.45),
      fontSize: 16,
      color: const Color(0xFFFFD700),
    );

    // 버튼 (재시도 / 스테이지 선택)
    final retryRect  = _resultRetryButtonRect();
    final selectRect = _resultRoundSelectButtonRect();

    _drawImageButton(canvas, 'ui/btn_red.png', retryRect, 'もう一度');
    _drawImageButton(canvas, 'ui/btn_violet.png', selectRect, 'ステージ選択');
  }

  // 별 렌더링 (이미지 우선)
  void _renderStars(Canvas canvas, int starCount, Offset center) {
    const double starSize = 30.0;
    const double starSpacing = 45.0;

    final startX = center.dx - starSpacing;

    for (int i = 0; i < 3; i++) {
      final x = startX + (i * starSpacing);
      final starCenter = Offset(x, center.dy);

      if (i < starCount) {
        // 획득한 별 (이미지 우선)
        _drawImageIcon(canvas, 'ui/star_filled.png', starCenter, starSize,
            fallbackEmoji: '★');
      } else {
        // 획득하지 못한 별 (이미지 우선)
        _drawImageIcon(canvas, 'ui/star_empty.png', starCenter, starSize,
            fallbackEmoji: '☆');
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
    // 이미지 버튼 우선 (Violet Theme)
    final btnAsset = enabled
        ? (label.contains('もう一度') ? 'ui/btn_red.png' : 'ui/btn_violet.png')
        : 'ui/btn_disabled.png';
    final btnImg = _tryGetImage(btnAsset);

    if (btnImg != null) {
      final srcRect = Rect.fromLTWH(0, 0, btnImg.width.toDouble(), btnImg.height.toDouble());
      final paint = Paint()..color = Color.fromRGBO(255, 255, 255, enabled ? 1.0 : 0.5);
      canvas.drawImageRect(btnImg, srcRect, rect, paint);
    } else {
      // 폴백: Canvas 직접 그리기
      final bgColor = enabled ? const Color(0xFF5B21B6) : const Color(0xFFB0BEC5);
      final bgPaint = Paint()..color = bgColor;
      final borderPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(rrect, borderPaint);
    }

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

  // ============================================================
  // D-1-3: 버추얼 스틱 UI (화면 좌측 하단, 외경 60px, 노브 25px)
  // ============================================================
  void _renderVirtualStick(Canvas canvas) {
    const double outerRadius = 60.0;
    const double knobRadius = 25.0;
    const double marginLeft = 80.0;
    const double marginBottom = 110.0;
    final Offset baseCenter = Offset(marginLeft, size.y - marginBottom);

    // 외부 링 (반투명 흰색 채우기)
    final outerFillPaint = Paint()..color = const Color(0x22FFFFFF);
    canvas.drawCircle(baseCenter, outerRadius, outerFillPaint);

    // 외부 링 테두리
    final outerBorderPaint = Paint()
      ..color = const Color(0x88FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(baseCenter, outerRadius, outerBorderPaint);

    // 십자 가이드 선
    final guidePaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(baseCenter.dx - outerRadius + 10, baseCenter.dy),
      Offset(baseCenter.dx + outerRadius - 10, baseCenter.dy),
      guidePaint,
    );
    canvas.drawLine(
      Offset(baseCenter.dx, baseCenter.dy - outerRadius + 10),
      Offset(baseCenter.dx, baseCenter.dy + outerRadius - 10),
      guidePaint,
    );

    // 노브 (반투명 흰색)
    final knobFillPaint = Paint()..color = const Color(0xAAFFFFFF);
    canvas.drawCircle(baseCenter, knobRadius, knobFillPaint);

    // 노브 테두리
    final knobBorderPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(baseCenter, knobRadius, knobBorderPaint);

    // 노브 중앙 점
    final knobDotPaint = Paint()..color = const Color(0x88333333);
    canvas.drawCircle(baseCenter, 5.0, knobDotPaint);
  }

  // ============================================================
  // D-1-4: 스킬 버튼 UI (화면 우측 하단, 원형 게이지)
  // ============================================================
  void _renderSkillButton(Canvas canvas) {
    const double btnRadius = 38.0;
    const double gaugeStroke = 6.0;
    const double marginRight = 55.0;
    const double marginBottom = 90.0;
    final Offset center = Offset(size.x - marginRight, size.y - marginBottom);

    // 버튼 배경 (반투명 검정)
    final bgPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawCircle(center, btnRadius, bgPaint);

    // 게이지 트랙 (어두운 회색)
    final trackPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = gaugeStroke;
    canvas.drawCircle(center, btnRadius - gaugeStroke / 2, trackPaint);

    // 원형 게이지 (skillGauge 0~100 → 호 각도)
    if (skillGauge > 0) {
      final gaugeColor = skillReady
          ? const Color(0xFFFF6E40) // 준비 완료: 주황-빨강
          : const Color(0xFF2196F3); // 충전 중: 파랑
      final gaugePaint = Paint()
        ..color = gaugeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = gaugeStroke
        ..strokeCap = StrokeCap.round;
      const double startAngle = -3.14159265 / 2; // 12시 방향
      final double sweepAngle = 2 * 3.14159265 * (skillGauge / 100.0);
      canvas.drawArc(
        Rect.fromCircle(
            center: center, radius: btnRadius - gaugeStroke / 2),
        startAngle,
        sweepAngle,
        false,
        gaugePaint,
      );
    }

    // 스킬 아이콘 (이미지 우선)
    final skillIconPath = skillReady ? 'icons/icon_skill_bomb.png' : 'ui/icon_skill.png';
    _drawImageIcon(
      canvas, skillIconPath,
      Offset(center.dx, center.dy - 6), 24,
      fallbackEmoji: skillReady ? '💥' : '⚡',
    );

    // 게이지 퍼센트 텍스트
    _drawCenteredText(
      canvas,
      skillReady ? 'READY' : '${skillGauge.toInt()}%',
      Offset(center.dx, center.dy + 14),
      fontSize: 9,
      color: skillReady ? const Color(0xFFFF6E40) : const Color(0xAAFFFFFF),
    );

    // 준비 완료 시 외곽 발광 링
    if (skillReady) {
      final glowPaint = Paint()
        ..color = const Color(0x44FF6E40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawCircle(center, btnRadius + 6, glowPaint);
    }
  }

  // ============================================================
  // D-1-5: 골드 표시 UI (화면 우측 하단, 스킬 버튼 왼쪽)
  // ============================================================
  void _renderGoldDisplay(Canvas canvas) {
    const double marginRight = 110.0;
    const double marginBottom = 78.0;
    const double bgW = 72.0;
    const double bgH = 28.0;
    final double x = size.x - marginRight - bgW / 2;
    final double y = size.y - marginBottom;

    // 반투명 배경 박스
    final bgPaint = Paint()..color = const Color(0x80000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: bgW, height: bgH),
        const Radius.circular(14),
      ),
      bgPaint,
    );

    // 테두리
    final borderPaint = Paint()
      ..color = const Color(0x88FFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: bgW, height: bgH),
        const Radius.circular(14),
      ),
      borderPaint,
    );

    // 코인 아이콘 + 골드 수치 (이미지 우선)
    _drawImageIcon(canvas, 'icons/icon_hud_coin.png',
        Offset(x - 22, y), 16, fallbackEmoji: '🪙');
    _drawCenteredText(
      canvas,
      '${playerGold}G',
      Offset(x + 6, y),
      fontSize: 13,
      color: const Color(0xFFFFD700),
    );
  }

  // ============================================================
  // D-4-2: 타워 슬롯 프레임 (성 중심 ±70px 대각선 4곳)
  // ============================================================
  void _renderTowerSlots(Canvas canvas) {
    const double slotSize = 40.0;
    final double cx = size.x / 2;
    final double cy = size.y / 2;
    const double towerOffset = 70.0;

    // T1~T4 슬롯 중심 좌표
    final List<Offset> slotCenters = [
      Offset(cx - towerOffset, cy - towerOffset), // T1: 좌상
      Offset(cx + towerOffset, cy - towerOffset), // T2: 우상
      Offset(cx - towerOffset, cy + towerOffset), // T3: 좌하
      Offset(cx + towerOffset, cy + towerOffset), // T4: 우하
    ];

    for (int i = 0; i < slotCenters.length; i++) {
      final center = slotCenters[i];
      final Rect slotRect =
          Rect.fromCenter(center: center, width: slotSize, height: slotSize);

      // partySlots 인덱스: 0=메인, 1~4=타워
      final int towerSlotIndex = i + 1;
      final bool hasTower = towerSlotIndex < partySlots.length &&
          partySlots[towerSlotIndex] != null;

      if (hasTower) {
        // 배치된 타워: 랭크 색상 배경 + 역할 이모지
        final instanceId = partySlots[towerSlotIndex]!;
        final character = ownedCharacters.firstWhere(
          (c) => c.instanceId == instanceId,
          orElse: () => ownedCharacters.isNotEmpty
              ? ownedCharacters.first
              : OwnedCharacter(instanceId: '', characterId: ''),
        );

        if (character.characterId.isNotEmpty) {
          final definition = CharacterDefinitions.byId(character.characterId);

          // 랭크 색상 반투명 배경
          final bgPaint = Paint()
            ..color = Color(definition.rank.color).withValues(alpha: 0.35);
          canvas.drawRRect(
            RRect.fromRectAndRadius(slotRect, const Radius.circular(6)),
            bgPaint,
          );

          // 스킬 준비 여부에 따른 테두리 색상
          final bool skillReady = towerSlotIndex < characterSlots.length &&
              characterSlots[towerSlotIndex].skillReady;
          final borderPaint = Paint()
            ..color = skillReady
                ? const Color(0xFF00E676)
                : Color(definition.rank.color)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(slotRect, const Radius.circular(6)),
            borderPaint,
          );

          // 역할 이모지
          _drawCenteredText(canvas, definition.role.emoji, center, fontSize: 22);

          // 스킬 준비 표시
          if (skillReady) {
            _drawCenteredText(
              canvas,
              '✨',
              Offset(slotRect.right - 8, slotRect.top + 8),
              fontSize: 10,
            );
          }
        }
      } else {
        // 빈 슬롯: 반투명 배경 + 점선 프레임 + 슬롯 번호
        final emptyBgPaint = Paint()..color = const Color(0x22FFFFFF);
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(6)),
          emptyBgPaint,
        );

        final dashBorderPaint = Paint()
          ..color = const Color(0x66FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(6)),
          dashBorderPaint,
        );

        // 슬롯 번호
        _drawCenteredText(
          canvas,
          'T${i + 1}',
          center,
          fontSize: 13,
          color: const Color(0x99FFFFFF),
        );
      }
    }
  }

  // ============================================================
  // D-1-2: 성 HP 바 (성 스프라이트 바로 위, 80×6px, 녹→황→적)
  // ============================================================
  void _renderCastleHP(Canvas canvas) {
    const double barWidth = 80.0;
    const double barHeight = 6.0;
    const double barMargin = 6.0;
    final double cx = size.x / 2;
    final double castleTop = size.y / 2 - 40.0; // 80px 높이의 절반
    final double hpRatio =
        castleMaxHp == 0 ? 0 : (castleHp / castleMaxHp).clamp(0.0, 1.0);
    final double barX = cx - barWidth / 2;
    final double barY = castleTop - barHeight - barMargin;

    // 성 HP 바 (이미지 바 우선)
    final Color barColor;
    if (hpRatio > 0.66) {
      barColor = const Color(0xFF4CAF50);
    } else if (hpRatio > 0.33) {
      barColor = const Color(0xFFFFEB3B);
    } else {
      barColor = const Color(0xFFF44336);
    }

    final castleHpFillPath = hpRatio > 0.33 ? 'ui/hp_bar_fill_green.png' : 'ui/hp_bar_fill.png';
    _drawImageBar(
      canvas,
      'ui/hp_bar_bg.png',
      castleHpFillPath,
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      hpRatio,
      fallbackBgColor: const Color(0xFF333333),
      fallbackFillColor: barColor,
    );

    // HP 수치 텍스트 (아이콘 이미지 우선)
    _drawImageIcon(canvas, 'ui/icon_heal.png',
        Offset(cx - 42, barY - 10), 14, fallbackEmoji: '🏰');
    _drawCenteredText(
      canvas,
      '$castleHp / $castleMaxHp',
      Offset(cx + 6, barY - 10),
      fontSize: 11,
      color: const Color(0xFFFFFFFF),
    );
  }

  // ============================================================
  // D-1-1: 게임 화면 HUD (상단 UI)
  // 레이아웃:
  //   [1행] 캐릭터 아이콘 + HP바  |  Lv.X  |  XP바 (플레이스홀더)
  //   [2행] 👾몬스터수  |  ⏱타이머  |  Stage X-Y
  // ============================================================
  void _renderHUD(Canvas canvas) {
    const double topPad = 8.0;
    const double leftPad = 12.0;
    const double barHeight = 7.0;

    // ── 반투명 HUD 배경 (D-03: 3행→2행 축소, 60→50px) ──
    final bgPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 50), bgPaint);

    // ── 1행: HP바 ──
    final _CharacterUnit? mainUnit = () {
      final filtered = characterUnits.where((u) => !u.isTower).toList();
      return filtered.isEmpty ? null : filtered.first;
    }();

    const double hpBarW = 100.0;
    const double row1Y = topPad + 6;

    // 캐릭터 아이콘 (메인 유닛 역할 이모지)
    if (mainUnit != null) {
      _drawCenteredText(
        canvas,
        mainUnit.definition.role.emoji,
        Offset(leftPad + 10, row1Y + 4),
        fontSize: 16,
      );
    } else {
      _drawCenteredText(
        canvas,
        '🏃',
        Offset(leftPad + 10, row1Y + 4),
        fontSize: 16,
      );
    }

    // HP 바 (이미지 바 우선, 폴백 Canvas)
    final double hpRatio =
        (_mainCharHp / _mainCharMaxHp).clamp(0.0, 1.0);
    final double hpBarX = leftPad + 24;

    final Color hpColor;
    if (hpRatio > 0.66) {
      hpColor = const Color(0xFF4CAF50);
    } else if (hpRatio > 0.33) {
      hpColor = const Color(0xFFFFEB3B);
    } else {
      hpColor = const Color(0xFFF44336);
    }

    // HP바: 비율에 따라 초록/빨강 선택
    final hpFillPath = hpRatio > 0.33 ? 'ui/hp_bar_fill_green.png' : 'ui/hp_bar_fill.png';
    _drawImageBar(
      canvas,
      'ui/hp_bar_bg.png',
      hpFillPath,
      Rect.fromLTWH(hpBarX, row1Y, hpBarW, barHeight),
      hpRatio,
      fallbackBgColor: const Color(0xFF333333),
      fallbackFillColor: hpColor,
    );

    // HP 수치 (_mainCharHp 실제 값 사용)
    final String hpText = '$_mainCharHp/$_mainCharMaxHp';
    _drawText(
      canvas,
      hpText,
      Offset(hpBarX + 2, row1Y + 9),
      fontSize: 8,
      color: const Color(0xFFFFFFFF),
    );

    // 속성 아이콘 (HP 바 오른쪽, 이미지 우선)
    if (_mainCharElement != ElementType.none) {
      final elemImgPath = _elementImagePath(_mainCharElement);
      if (elemImgPath != null) {
        _drawImageIcon(canvas, elemImgPath,
            Offset(hpBarX + hpBarW + 12, row1Y + 4), 16,
            fallbackEmoji: _mainCharElement.emoji);
      } else {
        _drawCenteredText(
          canvas,
          _mainCharElement.emoji,
          Offset(hpBarX + hpBarW + 12, row1Y + 4),
          fontSize: 14,
        );
      }
    }

    // Lv 표시 (중앙 상단, 이미지 아이콘 우선)
    _drawImageIcon(canvas, 'icons/icon_hud_star.png',
        Offset(size.x / 2 - 28, row1Y + 4), 14, fallbackEmoji: '⭐');
    _drawCenteredText(
      canvas,
      'Lv.$playerLevel',
      Offset(size.x / 2 + 4, row1Y + 4),
      fontSize: 13,
      color: const Color(0xFFFFD700),
    );

    // XP 바 (이미지 바 우선)
    const double xpBarW = 90.0;
    final double xpBarX = size.x - leftPad - xpBarW;
    final double xpRatio = _xpToNextLevel() > 0
        ? (playerXp / _xpToNextLevel()).clamp(0.0, 1.0)
        : 0.0;
    _drawImageBar(
      canvas,
      'ui/hp_bar_bg.png',
      'ui/xp_bar_fill.png',
      Rect.fromLTWH(xpBarX, row1Y, xpBarW, barHeight),
      xpRatio,
      fallbackBgColor: const Color(0xFF333333),
      fallbackFillColor: const Color(0xFF2196F3),
    );
    _drawText(
      canvas,
      'Lv.$playerCharLevel XP',
      Offset(xpBarX + 2, row1Y + 9),
      fontSize: 8,
      color: const Color(0xAAFFFFFF),
    );

    // ── 2행: 몬스터수 | 타이머 | 스테이지 ──
    const double row2Y = topPad + 24;

    // 좌측: 몬스터 수 (이미지 아이콘 우선)
    final int remaining = totalMonstersInRound - defeatedMonsters;
    _drawImageIcon(canvas, 'icons/icon_skull.png',
        Offset(leftPad + 8, row2Y + 8), 14, fallbackEmoji: '👾');
    _drawText(
      canvas,
      ' $remaining',
      Offset(leftPad + 18, row2Y + 4),
      fontSize: 12,
      color: const Color(0xFFFFFFFF),
    );

    // 중앙: 경과 타이머 (이미지 아이콘 우선)
    final int totalSec = roundTimer.toInt();
    final int minutes = totalSec ~/ 60;
    final int seconds = totalSec % 60;
    final String timerText = '$minutes:${seconds.toString().padLeft(2, '0')}';
    _drawImageIcon(canvas, 'icons/icon_timer.png',
        Offset(size.x / 2 - 26, row2Y + 4), 14, fallbackEmoji: '⏱');
    _drawCenteredText(
      canvas,
      timerText,
      Offset(size.x / 2 + 4, row2Y + 4),
      fontSize: 12,
      color: const Color(0xFFFFFFFF),
    );

    // 우측: 스테이지 표시
    _drawText(
      canvas,
      'Stage $stageLevel-$currentRound',
      Offset(size.x - leftPad - 80, row2Y + 4),
      fontSize: 12,
      color: const Color(0xFFAAAAAA),
    );

    // D-03: HUD Row3 제거 — 골드는 _renderGoldDisplay()에서, 속성은 Row1에서 표시
  }

  // D-1-5: 속성 이모지 헬퍼
  String _elementIcon(ElementType e) {
    switch (e) {
      case ElementType.fire:     return '🔥';
      case ElementType.water:    return '💧';
      case ElementType.earth:    return '🌿';
      case ElementType.electric: return '⚡';
      case ElementType.dark:     return '🌑';
      case ElementType.none:     return '';
    }
  }

  // 속성 이미지 경로 헬퍼
  String? _elementImagePath(ElementType e) {
    switch (e) {
      case ElementType.fire:     return 'ui/icon_fire.png';
      case ElementType.water:    return 'ui/icon_water.png';
      case ElementType.earth:    return 'ui/icon_earth.png';
      case ElementType.electric: return 'ui/icon_electric.png';
      case ElementType.dark:     return 'ui/icon_dark.png';
      case ElementType.none:     return null;
    }
  }

  // D-1-5: 속성 색상 헬퍼
  Color _elementColor(ElementType e) {
    switch (e) {
      case ElementType.fire:     return const Color(0xFFF44336);
      case ElementType.water:    return const Color(0xFF2196F3);
      case ElementType.earth:    return const Color(0xFF8BC34A);
      case ElementType.electric: return const Color(0xFFFFD700);
      case ElementType.dark:     return const Color(0xFF9C27B0);
      case ElementType.none:     return const Color(0xFFFFFFFF);
    }
  }

  // ============================================================
  // D-2-4: 메인 캐릭터 사망 카운트다운 UI
  // - 화면 중앙에 큰 숫자 표시 (5→4→3→2→1)
  // - 사용법: Engineer가 mainCharReviveCountdown 변수 추가 후 아래 메서드를 render()에서 호출
  //   if (mainCharReviveCountdown > 0) _renderReviveCountdown(canvas, mainCharReviveCountdown);
  // ============================================================
  void _renderReviveCountdown(Canvas canvas, double countdown) {
    // 반투명 오버레이
    final overlayPaint = Paint()..color = const Color(0x80000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlayPaint);

    // 카운트다운 숫자 (올림 처리: 0.1초 남아도 "1"로 표시)
    final int countInt = countdown.ceil().clamp(1, 5);

    // 숫자 색상: 빨간→주황→노랑 (시간이 줄수록 다급해지는 느낌)
    final Color countColor;
    if (countInt >= 4) {
      countColor = const Color(0xFFFF5252); // 빨강
    } else if (countInt >= 2) {
      countColor = const Color(0xFFFF6E40); // 주황
    } else {
      countColor = const Color(0xFFFFEB3B); // 노랑
    }

    // 큰 숫자
    _drawCenteredText(
      canvas,
      '$countInt',
      Offset(size.x / 2, size.y / 2 - 20),
      fontSize: 80,
      color: countColor,
    );

    // "REVIVING..." 서브텍스트 (점멸: sin 파형으로 알파 제어)
    final double alpha = (0.5 + 0.5 * sin(gameTime * 6)).clamp(0.3, 1.0);
    _drawCenteredText(
      canvas,
      'REVIVING...',
      Offset(size.x / 2, size.y / 2 + 50),
      fontSize: 16,
      color: Color.fromRGBO(255, 255, 255, alpha),
    );
  }

  // ============================================================
  // D-3-2: XP 젬 묘사 (파란 마름모, 소멸 전 점멸)
  // ============================================================
  void _renderXpGems(Canvas canvas) {
    const double gemSize = 7.0;

    for (final gem in xpGems) {
      final cx = gem.pos.x;
      final cy = gem.pos.y;

      // 소멸 전 5초 이하: sin 파형 점멸
      final double gemAlpha =
          gem.isBlinking ? (0.4 + 0.6 * sin(gameTime * 8)).clamp(0.1, 1.0) : 1.0;

      if (xpGemImageLoaded && xpGemImage != null) {
        // D-3-2: 참조 에셋 스프라이트로 XP 젬 렌더링
        final srcRect = Rect.fromLTWH(
          0, 0,
          xpGemImage!.width.toDouble(),
          xpGemImage!.height.toDouble(),
        );
        final dstRect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: gemSize * 2.0,
          height: gemSize * 2.0,
        );
        final spritePaint = Paint()
          ..color = Color.fromRGBO(255, 255, 255, gemAlpha);
        canvas.drawImageRect(xpGemImage!, srcRect, dstRect, spritePaint);
      } else {
        // 폴백: Canvas 절차적 드로잉
        final path = Path()
          ..moveTo(cx, cy - gemSize)
          ..lineTo(cx + gemSize * 0.6, cy)
          ..lineTo(cx, cy + gemSize)
          ..lineTo(cx - gemSize * 0.6, cy)
          ..close();
        final fillPaint = Paint()
          ..color = Color.fromRGBO(21, 101, 192, gemAlpha);
        canvas.drawPath(path, fillPaint);
        final hlPath = Path()
          ..moveTo(cx, cy - gemSize)
          ..lineTo(cx + gemSize * 0.6, cy)
          ..lineTo(cx, cy)
          ..close();
        final hlPaint = Paint()
          ..color = Color.fromRGBO(100, 181, 246, gemAlpha * 0.7);
        canvas.drawPath(hlPath, hlPaint);
        final borderPaint = Paint()
          ..color = Color.fromRGBO(33, 150, 243, gemAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawPath(path, borderPaint);
      }

      // 고가치 젬 (10XP 이상) 수치 표시
      if (gem.xpValue >= 10) {
        _drawCenteredText(
          canvas,
          '${gem.xpValue}',
          Offset(cx, cy + gemSize + 8),
          fontSize: 8,
          color: Color.fromRGBO(144, 202, 249, gemAlpha),
        );
      }
    }
  }

  // ============================================================
  // D-3-4: XP 마그넷 연출 (레벨업 직후 1초간 메인 캐릭터 주위 파란 링 펄스)
  // ============================================================
  void _renderXpMagnetEffect(Canvas canvas) {
    if (_xpMagnetTimer <= 0) return;
    // 메인 캐릭터 위치 취득
    final mainUnit = _mainCharAlive
        ? characterUnits.where((u) => !u.isTower).firstOrNull
        : null;
    if (mainUnit == null) return;

    final cx = mainUnit.pos.x;
    final cy = mainUnit.pos.y;
    // 진행률 (0.0=시작, 1.0=종료)
    final progress = 1.0 - (_xpMagnetTimer / CastleDefenseGame._xpMagnetDuration);

    // 외부 링: 확대되며 사라짐
    final outerRadius = 20.0 + progress * 60.0;
    final outerAlpha = (1.0 - progress).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(cx, cy),
      outerRadius,
      Paint()
        ..color = const Color(0xFF1565C0).withValues(alpha: outerAlpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // 내부 펄스 링: sin 파형으로 깜빡임
    final innerPulse = (sin(gameTime * 15) * 0.3 + 0.7).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(cx, cy),
      _xpCollectRadius,
      Paint()
        ..color = const Color(0xFF1565C0).withValues(alpha: innerPulse * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ============================================================
  // D-3-3: 골드 코인 묘사 (금색 원형, goldYellow #FFD700)
  // ============================================================
  void _renderGoldDrops(Canvas canvas) {
    const double coinRadius = 6.0;

    for (final gold in goldDrops) {
      final cx = gold.pos.x;
      final cy = gold.pos.y;

      if (goldCoinImageLoaded && goldCoinImage != null) {
        // D-3-3: 참조 에셋 스프라이트로 코인 렌더링
        final srcRect = Rect.fromLTWH(
          0, 0,
          goldCoinImage!.width.toDouble(),
          goldCoinImage!.height.toDouble(),
        );
        final dstRect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: coinRadius * 2.5,
          height: coinRadius * 2.5,
        );
        canvas.drawImageRect(goldCoinImage!, srcRect, dstRect, Paint());
      } else {
        // 폴백: Canvas 절차적 드로잉
        final coinPaint = Paint()..color = const Color(0xFFFFD700);
        canvas.drawCircle(Offset(cx, cy), coinRadius, coinPaint);
        final hlPaint = Paint()..color = const Color(0xFFFFF9C4);
        canvas.drawCircle(Offset(cx - 1.5, cy - 1.5), coinRadius * 0.4, hlPaint);
        final borderPaint = Paint()
          ..color = const Color(0xFFFF8F00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(Offset(cx, cy), coinRadius, borderPaint);
      }

      // 고액 골드 수치 표시
      if (gold.goldValue >= 5) {
        _drawCenteredText(
          canvas,
          '${gold.goldValue}',
          Offset(cx, cy + coinRadius + 8),
          fontSize: 8,
          color: const Color(0xFFFFD700),
        );
      }
    }
  }

  // ============================================================
  // #34 속성UI: 부유 데미지 숫자 렌더링
  // - 속성에 따른 색상 / 유리(1.5x)=SUPER! / 불리(0.75x)=RESIST
  // ============================================================
  void _renderDamageNumbers(Canvas canvas) {
    for (final dn in _damageNumbers) {
      final double progress = (dn.timer / _DamageNumber.duration).clamp(0.0, 1.0);
      // 위로 올라가는 이동 + 후반 페이드아웃
      final double riseY = dn.pos.y - progress * 30;
      final double alpha = progress < 0.7 ? 1.0 : 1.0 - (progress - 0.7) / 0.3;

      // 속성 색상
      final Color baseColor = _elementColor(dn.element);

      // 데미지 수치
      _drawCenteredText(
        canvas,
        '-${dn.amount}',
        Offset(dn.pos.x, riseY),
        fontSize: dn.elementMult >= 1.5 ? 16 : (dn.elementMult <= 0.75 ? 11 : 13),
        color: Color.fromRGBO(baseColor.red, baseColor.green, baseColor.blue, alpha),
      );

      // SUPER! / RESIST 태그
      if (dn.elementMult >= 1.5) {
        _drawCenteredText(
          canvas,
          'SUPER!',
          Offset(dn.pos.x, riseY - 16),
          fontSize: 10,
          color: Color.fromRGBO(255, 200, 0, alpha),
        );
      } else if (dn.elementMult <= 0.75) {
        _drawCenteredText(
          canvas,
          'RESIST',
          Offset(dn.pos.x, riseY - 14),
          fontSize: 9,
          color: Color.fromRGBO(150, 150, 150, alpha),
        );
      }
    }
  }
}
