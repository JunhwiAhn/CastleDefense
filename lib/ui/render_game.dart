// 인게임 렌더링 (레벨업 UI, 배경, 성, 몬스터, 캐릭터, 투사물, VFX 등)
part of '../castle_defense_game.dart';

extension GameRendering on CastleDefenseGame {
  // D-2-1: 레벨업 바프 카드 UI (Violet Theme)
  // 카드 좌표는 _handleTapInLevelUp 과 동기화 (cardW=100, cardH=150, gap=10, cardY=0.30)
  void _renderLevelUpUI(Canvas canvas) {
    // 반투명 보라색 배경 오버레이
    final bgPaint = Paint()..color = const Color(0xDD0A0014);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // 상단 장식 바 (바이올렛)
    final decorPaint = Paint()..color = const Color(0xFF7C3AED);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 4), decorPaint);

    // "LEVEL UP!" 제목
    _drawCenteredText(
      canvas,
      'LEVEL UP!',
      Offset(size.x / 2, size.y * 0.14),
      fontSize: 30,
      color: const Color(0xFFFFD700),
    );

    // 레벨 표시
    _drawCenteredText(
      canvas,
      'Lv.$playerCharLevel',
      Offset(size.x / 2, size.y * 0.22),
      fontSize: 17,
      color: const Color(0xFFE0CCFF),
    );

    // 바프 카드 3장 — _handleTapInLevelUp 좌표와 동기화
    const double cardW = 100.0;
    const double cardH = 150.0;
    const double cardGap = 10.0;
    final double totalW = 3 * cardW + 2 * cardGap;
    final double startX = (size.x - totalW) / 2;
    final double cardY = size.y * 0.30;

    for (int i = 0; i < _buffOptions.length && i < 3; i++) {
      final buff = _buffOptions[i];
      final double cx = startX + i * (cardW + cardGap);
      final cardRect = Rect.fromLTWH(cx, cardY, cardW, cardH);

      // 카드 배경 (다크 바이올렛)
      final cardPaint = Paint()..color = const Color(0xFF1E1040);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(12)),
        cardPaint,
      );

      // 카드 테두리 (보라색 글로우)
      final borderPaint = Paint()
        ..color = const Color(0xFF9B59F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(12)),
        borderPaint,
      );

      // 상단 색상 헤더 바
      final headerRect = Rect.fromLTWH(cx, cardY, cardW, 26);
      final headerPaint = Paint()..color = const Color(0xFF7C3AED);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          headerRect,
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
        ),
        headerPaint,
      );

      // 헤더 아이콘
      _drawCenteredText(
        canvas,
        _buffTypeIcon(buff),
        Offset(cx + cardW / 2, cardY + 13),
        fontSize: 14,
      );

      // 바프 이름
      _drawCenteredText(
        canvas,
        _buffTypeName(buff),
        Offset(cx + cardW / 2, cardY + 48),
        fontSize: 11,
        color: const Color(0xFFFFFFFF),
      );

      // 구분선
      final divPaint = Paint()
        ..color = const Color(0xFF4A3A6A)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(cx + 10, cardY + 62),
        Offset(cx + cardW - 10, cardY + 62),
        divPaint,
      );

      // 바프 설명
      _drawCenteredText(
        canvas,
        _buffTypeDesc(buff),
        Offset(cx + cardW / 2, cardY + 84),
        fontSize: 9,
        color: const Color(0xFFBBAEFF),
        multiLine: true,
      );

      // 스택 카운트 배지
      final stackTxt = _buffStackText(buff);
      if (stackTxt.isNotEmpty) {
        final stackBgPaint = Paint()..color = const Color(0xFF3D1F6E);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + cardW / 2 - 22, cardY + 129, 44, 14),
            const Radius.circular(7),
          ),
          stackBgPaint,
        );
        _drawCenteredText(
          canvas,
          stackTxt,
          Offset(cx + cardW / 2, cardY + 136),
          fontSize: 9,
          color: const Color(0xFFFFD700),
        );
      }
    }

    // 탭 안내 (하단)
    _drawCenteredText(
      canvas,
      'カードをタップして選択',
      Offset(size.x / 2, size.y * 0.85),
      fontSize: 13,
      color: const Color(0x99CCAAFF),
    );
  }

  // D-2-1 헬퍼: 바프 타입 아이콘
  String _buffTypeIcon(BuffType buff) {
    switch (buff) {
      case BuffType.attackUp:             return '⚔';
      case BuffType.attackSpdUp:          return '⚡';
      case BuffType.moveSpeedUp:          return '💨';
      case BuffType.rangeUp:              return '🎯';
      case BuffType.castleRepair:         return '🏰';
      case BuffType.towerPowerUp:         return '🗼';
      case BuffType.xpMagnetUp:           return '🧲';
      case BuffType.castleBarrier:        return '🛡';
      case BuffType.elementFireGrant:     return '🔥';
      case BuffType.elementWaterGrant:    return '💧';
      case BuffType.elementEarthGrant:    return '🌿';
      case BuffType.elementElectricGrant: return '⚡';
      case BuffType.elementDarkGrant:     return '🌑';
      case BuffType.elementMastery:       return '✨';
    }
  }

  // D-2-1 헬퍼: 스택 카운트 텍스트 (무제한 바프는 빈 문자열)
  String _buffStackText(BuffType buff) {
    switch (buff) {
      case BuffType.attackUp:       return '$_atkUpCount / 5';
      case BuffType.attackSpdUp:    return '$_spdUpCount / 5';
      case BuffType.moveSpeedUp:    return '$_moveUpCount / 3';
      case BuffType.rangeUp:        return '$_rangeUpCount / 3';
      case BuffType.towerPowerUp:   return '$_towerUpCount / 5';
      case BuffType.xpMagnetUp:     return '$_magnetCount / 3';
      case BuffType.elementMastery: return '$_elementMasteryCount / 3';
      default:                      return '';
    }
  }

  // 바프 이름 표시
  String _buffTypeName(BuffType buff) {
    switch (buff) {
      case BuffType.attackUp: return 'ATK UP';
      case BuffType.attackSpdUp: return 'SPD UP';
      case BuffType.moveSpeedUp: return 'MOVE UP';
      case BuffType.rangeUp: return 'RANGE UP';
      case BuffType.castleRepair: return 'REPAIR';
      case BuffType.towerPowerUp: return 'TOWER UP';
      case BuffType.xpMagnetUp: return 'MAGNET';
      case BuffType.castleBarrier: return 'BARRIER';
      case BuffType.elementFireGrant: return '🔥 FIRE';
      case BuffType.elementWaterGrant: return '💧 WATER';
      case BuffType.elementEarthGrant: return '🌿 EARTH';
      case BuffType.elementElectricGrant: return '⚡ ELECTRIC';
      case BuffType.elementDarkGrant: return '🌑 DARK';
      case BuffType.elementMastery: return 'ELEM MASTERY';
    }
  }

  // 바프 설명 표시
  String _buffTypeDesc(BuffType buff) {
    switch (buff) {
      case BuffType.attackUp: return 'ATK +15%\n(max 5)';
      case BuffType.attackSpdUp: return 'Interval -10%\n(max 5)';
      case BuffType.moveSpeedUp: return 'Speed +20%\n(max 3)';
      case BuffType.rangeUp: return 'Range +15%\n(max 3)';
      case BuffType.castleRepair: return 'Castle HP +20';
      case BuffType.towerPowerUp: return 'Tower ATK +10%\n(max 5)';
      case BuffType.xpMagnetUp: return 'XP Radius +15px\n(max 3)';
      case BuffType.castleBarrier: return '10s Barrier';
      case BuffType.elementFireGrant: return '火炎属性付与\n(上書き)';
      case BuffType.elementWaterGrant: return '水氷属性付与\n(上書き)';
      case BuffType.elementEarthGrant: return '大地属性付与\n(上書き)';
      case BuffType.elementElectricGrant: return '雷属性付与\n(上書き)';
      case BuffType.elementDarkGrant: return '暗黒属性付与\n(上書き)';
      case BuffType.elementMastery: return '属性ボーナス\n+10% (max 3)';
    }
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

  // 리디자인: 성을 화면 중앙 80×80px 정사각형으로 변경
  Rect get _castleRect => Rect.fromCenter(
    center: Offset(size.x / 2, size.y / 2),
    width: castleHeight,
    height: castleHeight,
  );

  // D-4-1: 새 디자인 — 화면 중앙 80×80px 성 스프라이트 (HP 3단계 시각 변화)
  void _renderCastle(Canvas canvas) {
    final double cx = castleCenterX;
    final double cy = castleCenterY;

    // HP 비율에 따른 3단계 색상
    final double hpRatio =
        castleMaxHp == 0 ? 0 : (castleHp / castleMaxHp).clamp(0.0, 1.0);
    final Color castleBaseColor;
    final Color castleRoofColor;
    if (hpRatio > 0.66) {
      castleBaseColor = const Color(0xFF546E7A); // 양호: 블루그레이
      castleRoofColor = const Color(0xFF37474F);
    } else if (hpRatio > 0.33) {
      castleBaseColor = const Color(0xFF6D4C41); // 손상: 갈색
      castleRoofColor = const Color(0xFF4E342E);
    } else {
      castleBaseColor = const Color(0xFF7B3535); // 위기: 어두운 빨강
      castleRoofColor = const Color(0xFF5D2626);
    }

    // 성 스프라이트 선택: castleFortressImage 우선, 기존 castleImage 폴백
    final Image? activeCastleImg = castleFortressImage ?? castleImage;
    if (activeCastleImg != null) {
      // 스프라이트로 성 렌더링
      final srcRect = Rect.fromLTWH(
        0, 0,
        activeCastleImg.width.toDouble(),
        activeCastleImg.height.toDouble(),
      );
      // HP 비율에 따른 색조 오버레이 알파
      final double tintAlpha = hpRatio > 0.66
          ? 0.0    // 양호: 틴트 없음
          : hpRatio > 0.33
              ? 0.2  // 손상: 갈색 틴트
              : 0.4; // 위기: 빨간 틴트
      canvas.drawImageRect(activeCastleImg, srcRect, _castleRect, Paint());
      if (tintAlpha > 0) {
        final tintColor = hpRatio > 0.33
            ? Color.fromRGBO(109, 76, 65, tintAlpha)    // 갈색
            : Color.fromRGBO(123, 53, 53, tintAlpha);   // 어두운 빨강
        canvas.drawRRect(
          RRect.fromRectAndRadius(_castleRect, const Radius.circular(4)),
          Paint()..color = tintColor,
        );
      }
    } else {
      // 폴백: Canvas 절차적 드로잉
      final castleBodyPaint = Paint()..color = castleBaseColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(_castleRect, const Radius.circular(6)),
        castleBodyPaint,
      );

      // 성문 (하단 중앙 아치형)
      const double gateW = 20.0;
      const double gateH = 26.0;
      final gatePaint = Paint()..color = const Color(0xFF1A1A1A);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - gateW / 2, _castleRect.bottom - gateH, gateW, gateH),
          topLeft: const Radius.circular(10),
          topRight: const Radius.circular(10),
        ),
        gatePaint,
      );

      // 흉벽 (상단 4개 돌출부)
      final crenelPaint = Paint()..color = castleRoofColor;
      for (final xPos in [
        _castleRect.left + 4.0,
        _castleRect.left + 18.0,
        _castleRect.right - 28.0,
        _castleRect.right - 12.0,
      ]) {
        canvas.drawRect(
          Rect.fromLTWH(xPos, _castleRect.top - 9, 8, 11),
          crenelPaint,
        );
      }

      // 창문 (좌우, 황금색 반투명)
      final windowPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6);
      for (final wc in [Offset(cx - 18, cy - 10), Offset(cx + 18, cy - 10)]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: wc, width: 10, height: 12),
            const Radius.circular(5),
          ),
          windowPaint,
        );
      }

      // 외곽 테두리
      final borderPaint = Paint()
        ..color = const Color(0x88FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(_castleRect, const Radius.circular(6)),
        borderPaint,
      );
    }

    // 위기 상태 균열
    if (hpRatio <= 0.33 && castleHp > 0) {
      final crackPaint = Paint()
        ..color = const Color(0xAAFF5252)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(cx - 15, _castleRect.top + 10),
        Offset(cx - 5, _castleRect.top + 30),
        crackPaint,
      );
      canvas.drawLine(
        Offset(cx + 10, _castleRect.top + 15),
        Offset(cx + 20, _castleRect.top + 35),
        crackPaint,
      );
    }

    // D-3-1: 성 피격 점멸 연출 (castleFlashTimer > 0일 때 빨간 오버레이)
    if (castleFlashTimer > 0) {
      // 0.2초 동안 알파가 점진적으로 줄어드는 빨간 점멸
      final double flashAlpha = (castleFlashTimer / 0.2).clamp(0.0, 1.0) * 0.6;
      final flashPaint = Paint()
        ..color = Color.fromRGBO(244, 67, 54, flashAlpha); // hpRed
      canvas.drawRRect(
        RRect.fromRectAndRadius(_castleRect, const Radius.circular(6)),
        flashPaint,
      );
    }

    // 타워 슬롯 렌더링 (D-4-2)
    _renderTowerSlots(canvas);

    // 성 HP 바 렌더링 (D-1-2)
    _renderCastleHP(canvas);
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

      // 몬스터 타입별 스프라이트 또는 폴백 드로잉
      if (m.type == MonsterType.boss) {
        // 보스: 새 스프라이트 우선, 기존 스프라이트 폴백, Canvas 폴백
        _renderBossAura(canvas, center, radius, isBoss: true);
        final bossImg = _getBossImage();
        if (bossImg != null) {
          _renderMonsterSprite(canvas, bossImg, center, radius * 2.2, m.damageFlashTimer > 0);
        } else if (bossMonsterImageLoaded && bossMonsterImage != null) {
          _renderMonsterSprite(canvas, bossMonsterImage!, center, radius * 2.2, m.damageFlashTimer > 0);
        } else {
          _renderBossMonsterFallback(canvas, center, radius, isBoss: true, isDamaged: m.damageFlashTimer > 0);
        }
        _renderBossCrown(canvas, center, radius, isGold: true);
      } else if (m.type == MonsterType.miniBoss) {
        // 미니보스: 새 스프라이트 우선, 기존 스프라이트 폴백, Canvas 폴백
        _renderBossAura(canvas, center, radius, isBoss: false);
        final minibossImg = _getMinibossImage(m);
        if (minibossImg != null) {
          _renderMonsterSprite(canvas, minibossImg, center, radius * 2.2, m.damageFlashTimer > 0);
        } else if (minibossMonsterImageLoaded && minibossMonsterImage != null) {
          _renderMonsterSprite(canvas, minibossMonsterImage!, center, radius * 2.2, m.damageFlashTimer > 0);
        } else {
          _renderBossMonsterFallback(canvas, center, radius, isBoss: false, isDamaged: m.damageFlashTimer > 0);
        }
        _renderBossCrown(canvas, center, radius, isGold: false);
      } else {
        // 일반 몬스터: 스테이지별 스프라이트 선택
        final normalImg = _getNormalMonsterImage(m);
        if (normalImg != null) {
          _renderNormalMonsterSprite(canvas, normalImg, m, radius);
        } else if (goblinImageLoaded && goblinImage != null) {
          // 기존 Goblin 스프라이트 폴백
          _renderGoblinSprite(canvas, m, radius);
        } else {
          // Canvas 폴백: 원형 드로잉
          if (m.damageFlashTimer > 0) {
            final flashPaint = Paint()..color = const Color(0xFFFF0000);
            canvas.drawCircle(center, radius, flashPaint);
          } else {
            final monsterPaint = Paint()..color = monsterColor;
            canvas.drawCircle(center, radius, monsterPaint);
          }
        }
      }

      // 보스/미니보스가 성을 공격 중일 때 효과
      if (m.attackingCastle && (m.type == MonsterType.boss || m.type == MonsterType.miniBoss)) {
        // 공격 표시 (빨간색 펄스 링)
        final attackPaint = Paint()
          ..color = const Color(0xFFFF0000).withValues(alpha: 0.5 + 0.5 * (m.castleAttackTimer % 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawCircle(center, radius + 5, attackPaint);

        // "공격 중!" 텍스트
        _drawCenteredText(
          canvas,
          '⚔️',
          Offset(center.dx, center.dy - radius - 15),
          fontSize: 16,
          color: const Color(0xFFFF0000),
        );
      }

      // 보스/미니보스가 아닌 경우 기존 HP 바
      if (m.type != MonsterType.boss && m.type != MonsterType.miniBoss) {
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

      // 속성 시스템: 상태이상 아이콘 표시 (몬스터 위)
      _renderMonsterStatusIcons(canvas, m, center, radius);
    }

    // 보스/미니보스 HP 바 (화면 상단에 크게)
    _renderBossHealthBar(canvas);
  }

  // 상태이상 아이콘 렌더링 (몬스터 위)
  void _renderMonsterStatusIcons(Canvas canvas, _Monster m, Offset center, double radius) {
    final List<String> icons = [];
    if (m.burnTimer > 0) icons.add('🔥');
    if (m.freezeTimer > 0) icons.add('❄️');
    if (m.bindTimer > 0) icons.add('🌿');
    if (m.shockTimer > 0) icons.add('⚡');
    if (m.curseTimer > 0) icons.add('🌑');
    if (icons.isEmpty) return;

    // 아이콘을 몬스터 위에 가로 나열
    const double iconSize = 9.0;
    const double spacing = 10.0;
    final double totalW = icons.length * spacing - 2;
    final double startX = center.dx - totalW / 2;
    final double iconY = center.dy - radius - 18;

    for (int i = 0; i < icons.length; i++) {
      _drawCenteredText(
        canvas,
        icons[i],
        Offset(startX + i * spacing, iconY),
        fontSize: iconSize,
      );
    }
  }

  // Goblinスプライトレンダリング
  void _renderGoblinSprite(Canvas canvas, _Monster m, double radius) {
    if (goblinImage == null) return;

    // 歩行アニメーション効果 (上下に軽く揺れる)
    final bounceOffset = [0.0, -2.0, 0.0, 2.0][m.currentFrame];
    final center = Offset(m.pos.x, m.pos.y + bounceOffset);

    // スプライトシートのフレームサイズ (画像は1枚のみなので全体を使用)
    final imgWidth = goblinImage!.width.toDouble();
    final imgHeight = goblinImage!.height.toDouble();

    // 描画サイズ (radiusの2.5倍で表示)
    final drawSize = radius * 2.5;

    // ソース矩形 (画像全体)
    final srcRect = Rect.fromLTWH(0, 0, imgWidth, imgHeight);

    // 目標矩形 (中心に描画)
    final dstRect = Rect.fromCenter(
      center: center,
      width: drawSize,
      height: drawSize,
    );

    // ダメージフラッシュ時は赤いオーバーレイ
    if (m.damageFlashTimer > 0) {
      // 赤く染めるためにColorFilterを使用
      final flashPaint = Paint()
        ..colorFilter = const ColorFilter.mode(Color(0xFFFF0000), BlendMode.srcATop);
      canvas.drawImageRect(goblinImage!, srcRect, dstRect, flashPaint);
    } else {
      canvas.drawImageRect(goblinImage!, srcRect, dstRect, Paint());
    }
  }

  // 몬스터 스프라이트 공통 렌더링 (drawImageRect + 데미지 플래시)
  void _renderMonsterSprite(Canvas canvas, Image img, Offset center, double drawSize, bool isDamaged) {
    final srcRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    final dstRect = Rect.fromCenter(center: center, width: drawSize, height: drawSize);
    if (isDamaged) {
      final flashPaint = Paint()
        ..colorFilter = const ColorFilter.mode(Color(0xFFFF0000), BlendMode.srcATop);
      canvas.drawImageRect(img, srcRect, dstRect, flashPaint);
    } else {
      canvas.drawImageRect(img, srcRect, dstRect, Paint());
    }
  }

  // 일반 몬스터 스프라이트 렌더링 (보행 바운스 포함)
  void _renderNormalMonsterSprite(Canvas canvas, Image img, _Monster m, double radius) {
    final bounceOffset = [0.0, -2.0, 0.0, 2.0][m.currentFrame];
    final center = Offset(m.pos.x, m.pos.y + bounceOffset);
    final drawSize = radius * 2.5;
    _renderMonsterSprite(canvas, img, center, drawSize, m.damageFlashTimer > 0);
  }

  // 스테이지별 일반 몬스터 이미지 선택
  Image? _getNormalMonsterImage(_Monster m) {
    // 스테이지별 몬스터 이미지 매핑 (각 스테이지 3종, 해시 기반 선택)
    final stageKeys = <int, List<String>>{
      1: ['monster_stage1_rat', 'monster_stage1_slime', 'monster_stage1_worm'],
      2: ['monster_stage2_skull', 'monster_stage2_slime', 'monster_stage2_spider'],
      3: ['monster_stage3_scorpion', 'monster_stage3_skull', 'monster_stage3_slime'],
      4: ['monster_stage4_skull', 'monster_stage4_spider', 'monster_stage4_wolf'],
      5: ['monster_stage5_boneworm', 'monster_stage5_ooze', 'monster_stage5_wolf'],
    };

    final keys = stageKeys[stageLevel];
    if (keys != null && keys.isNotEmpty) {
      // 몬스터 위치 해시로 일관된 외형 선택
      final idx = (m.pos.x.hashCode ^ m.pos.y.hashCode).abs() % keys.length;
      final img = stageMonsterImages[keys[idx]];
      if (img != null) return img;
      // 해당 키가 없으면 첫 번째 사용 가능한 이미지 반환
      for (final k in keys) {
        if (stageMonsterImages.containsKey(k)) return stageMonsterImages[k];
      }
    }

    // 스테이지 매핑 없으면 기본 일반 몬스터 (normalGoblin 등)
    if (stageLevel == 1 && normalGoblinImage != null) return normalGoblinImage;
    if (stageLevel == 2 && normalSkeletonImage != null) return normalSkeletonImage;
    if (stageLevel == 3 && normalSlimeImage != null) return normalSlimeImage;
    if (stageLevel == 4 && normalPoisonSkullImage != null) return normalPoisonSkullImage;
    if (stageLevel >= 5 && normalGreenGoblinImage != null) return normalGreenGoblinImage;

    // 최종 폴백: 어떤 일반 이미지든 사용
    return normalGoblinImage ?? normalSkeletonImage ?? normalSlimeImage;
  }

  // 보스 이미지 선택 (스테이지별)
  Image? _getBossImage() {
    if (stageLevel <= 3 && bossCerberusImage != null) return bossCerberusImage;
    if (bossPoisonWarriorImage != null) return bossPoisonWarriorImage;
    return bossCerberusImage;
  }

  // 미니보스 이미지 선택 (속성/스테이지별)
  Image? _getMinibossImage(_Monster m) {
    // 속성별 미니보스 우선
    if (m.element != ElementType.none) {
      final elemKey = m.element.name; // fire, water, earth, dark
      final elemImg = minibossElementImages[elemKey];
      if (elemImg != null) return elemImg;
    }
    // 스테이지별 미니보스
    if (stageLevel <= 2 && minibossGoblinWarriorImage != null) return minibossGoblinWarriorImage;
    if (stageLevel <= 4 && minibossSkullWarriorImage != null) return minibossSkullWarriorImage;
    if (minibossSlimeKingImage != null) return minibossSlimeKingImage;
    return minibossGoblinWarriorImage ?? minibossSkullWarriorImage;
  }

  // ClassType → 이미지 파일명 매핑
  Image? _getCharacterImage(_CharacterUnit unit) {
    // 메인 캐릭터 (슬롯 0)
    if (!unit.isTower) {
      final mainImg = characterImages['main_character'];
      if (mainImg != null) return mainImg;
    }
    // ClassType에 대응하는 이미지 키 매핑
    final classToImageKey = <ClassType, String>{
      ClassType.warrior: 'warrior',
      ClassType.crusader: 'guardian',    // crusader → guardian.png
      ClassType.druid: 'druid',
      ClassType.vampire: 'berserker',    // vampire → berserker.png
      ClassType.archer: 'archer',
      ClassType.gunslinger: 'gunslinger',
      ClassType.trickster: 'rogue',      // trickster → rogue.png
      ClassType.pyromancer: 'pyromancer',
      ClassType.cryomancer: 'cryomancer',
      ClassType.necromancer: 'necromancer',
      ClassType.summoner: 'summoner',
      ClassType.priestClass: 'priest',   // priestClass → priest.png
      ClassType.pastor: 'paladin',       // pastor → paladin.png
      ClassType.alchemist: 'alchemist',
      ClassType.engineer: 'engineer',
      ClassType.assistant: 'warlock',    // assistant → warlock.png
    };
    final key = classToImageKey[unit.definition.classType];
    if (key != null && characterImages.containsKey(key)) {
      return characterImages[key];
    }
    return null;
  }

  // D-4-3: 보스/미니보스 발광 오라 렌더링
  void _renderBossAura(Canvas canvas, Offset center, double radius, {required bool isBoss}) {
    // 오라 색상: 보스=빨강, 미니보스=주황
    final Color auraColor = isBoss ? const Color(0xFFFF3030) : const Color(0xFFFF8C00);

    // 다층 반투명 원형 오라
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        center,
        radius + (i * 5.0),
        Paint()..color = auraColor.withValues(alpha: 0.07 * i),
      );
    }

    // 외부 발광 링
    canvas.drawCircle(
      center,
      radius + 5,
      Paint()
        ..color = auraColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // 보스 전용: 황금 이중 링
    if (isBoss) {
      canvas.drawCircle(
        center,
        radius + 10,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  // D-4-3/D-4-4: 보스/미니보스 왕관 오버레이
  void _renderBossCrown(Canvas canvas, Offset center, double radius, {required bool isGold}) {
    final Color crownColor = isGold ? const Color(0xFFFFD700) : const Color(0xFFFF8C00);
    final double crownBaseY = center.dy - radius - 2;
    final double halfW = radius * 0.38;

    // 왕관 패스 (5점형 간략 왕관)
    final path = Path();
    path.moveTo(center.dx - halfW, crownBaseY);
    path.lineTo(center.dx - halfW, crownBaseY - radius * 0.28);
    path.lineTo(center.dx - halfW * 0.4, crownBaseY - radius * 0.15);
    path.lineTo(center.dx, crownBaseY - radius * 0.4);
    path.lineTo(center.dx + halfW * 0.4, crownBaseY - radius * 0.15);
    path.lineTo(center.dx + halfW, crownBaseY - radius * 0.28);
    path.lineTo(center.dx + halfW, crownBaseY);
    path.close();

    canvas.drawPath(path, Paint()..color = crownColor.withValues(alpha: 0.85));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  // D-4-3/D-4-4: 보스/미니보스 Canvas 폴백 (스프라이트 미로드 시)
  void _renderBossMonsterFallback(Canvas canvas, Offset center, double radius,
      {required bool isBoss, required bool isDamaged}) {
    final Color baseColor = isBoss ? const Color(0xFFCC2200) : const Color(0xFFCC5500);
    final Color hlColor = isBoss ? const Color(0xFFFF7777) : const Color(0xFFFFAA44);

    // 메인 바디
    canvas.drawCircle(center, radius, Paint()..color = isDamaged ? const Color(0xFFFF2222) : baseColor);

    // 상단 하이라이트
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.25),
      radius * 0.45,
      Paint()..color = hlColor.withValues(alpha: 0.55),
    );

    // 빛나는 눈
    final eyeR = radius * (isBoss ? 0.16 : 0.13);
    final eyeOffX = radius * 0.3;
    final eyeOffY = radius * 0.1;
    canvas.drawCircle(
      Offset(center.dx - eyeOffX, center.dy - eyeOffY),
      eyeR,
      Paint()..color = const Color(0xFFFFFF00),
    );
    canvas.drawCircle(
      Offset(center.dx + eyeOffX, center.dy - eyeOffY),
      eyeR,
      Paint()..color = const Color(0xFFFFFF00),
    );

    // 보스 전용: 이마 문양 (마름모)
    if (isBoss) {
      final markPath = Path();
      final mx = center.dx;
      final my = center.dy - radius * 0.55;
      final ms = radius * 0.12;
      markPath.moveTo(mx, my - ms);
      markPath.lineTo(mx + ms, my);
      markPath.lineTo(mx, my + ms);
      markPath.lineTo(mx - ms, my);
      markPath.close();
      canvas.drawPath(markPath, Paint()..color = const Color(0xFFFFD700));
    }
  }

  // 보스 HP 바 렌더링 (화면 상단)
  void _renderBossHealthBar(Canvas canvas) {
    // 보스나 미니보스 찾기
    _Monster? boss;
    for (final m in monsters) {
      if (m.type == MonsterType.boss || m.type == MonsterType.miniBoss) {
        boss = m;
        break;
      }
    }

    if (boss == null) return;

    // 화면 상단 중앙에 큰 HP 바
    const double barHeight = 20.0;
    final double barWidth = size.x * 0.8; // 화면의 80%
    final double barX = (size.x - barWidth) / 2;
    const double barY = 50.0;

    // 배경
    final bgPaint = Paint()..color = const Color(0xFF333333);
    final bgRect = Rect.fromLTWH(barX, barY, barWidth, barHeight);
    canvas.drawRect(bgRect, bgPaint);

    // 테두리
    final borderPaint = Paint()
      ..color = boss.type == MonsterType.boss
          ? const Color(0xFFFF5252) // 보스: 빨강
          : const Color(0xFFFF6E40) // 미니보스: 주황
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(bgRect, borderPaint);

    // 실제 HP (빨간색)
    final hpRatio = boss.maxHp == 0 ? 0 : boss.hp / boss.maxHp;
    final hpPaint = Paint()..color = const Color(0xFFEF5350);
    final hpRect = Rect.fromLTWH(
      barX,
      barY,
      barWidth * hpRatio.clamp(0.0, 1.0),
      barHeight,
    );
    canvas.drawRect(hpRect, hpPaint);

    // 표시용 HP (롤 스타일 - 회색으로 천천히 감소)
    if (boss.displayHp > boss.hp) {
      final displayRatio = boss.maxHp == 0 ? 0 : boss.displayHp / boss.maxHp;
      final displayPaint = Paint()..color = const Color(0xFF757575); // 회색
      final displayRect = Rect.fromLTWH(
        barX,
        barY,
        barWidth * displayRatio.clamp(0.0, 1.0),
        barHeight,
      );
      canvas.drawRect(displayRect, displayPaint);
    }

    // HP 텍스트
    final bossName = boss.type == MonsterType.boss ? 'BOSS' : 'MINI BOSS';
    _drawCenteredText(
      canvas,
      '$bossName  ${boss.hp} / ${boss.maxHp}',
      Offset(size.x / 2, barY + barHeight / 2),
      fontSize: 14,
      color: const Color(0xFFFFFFFF),
    );
  }

  // 캐릭터 유닛 렌더링
  void _renderCharacterUnits(Canvas canvas) {
    for (final unit in characterUnits) {
      final center = Offset(unit.pos.x, unit.pos.y);

      // 역할별 색상 (이모지 배경)
      Color unitColor;
      switch (unit.definition.role) {
        case RoleType.tanker:
          unitColor = const Color(0xFF5C6BC0); // 파랑 (탱커)
          break;
        case RoleType.physicalDealer:
          unitColor = const Color(0xFFEF5350); // 빨강 (물리딜러)
          break;
        case RoleType.magicDealer:
          unitColor = const Color(0xFFAB47BC); // 보라 (마법딜러)
          break;
        case RoleType.priest:
          unitColor = const Color(0xFFFFA726); // 주황 (성직자)
          break;
        case RoleType.utility:
          unitColor = const Color(0xFF26A69A); // 청록 (유틸리티)
          break;
      }

      // 버프 효과 (외곽 링)
      if (unit.hasAttackSpeedBuff || unit.hasMoveSpeedBuff) {
        final buffPaint = Paint()
          ..color = const Color(0xFFFFD700) // 금색
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(center, characterUnitRadius + 2.0, buffPaint);
      }

      // D-3-6: 무적 중 반투명 점멸 (메인 캐릭터만)
      final bool isMainUnit = !unit.isTower;
      final double unitAlpha = (isMainUnit && _invincibleTimer > 0)
          ? (0.4 + 0.4 * sin(gameTime * 12)).clamp(0.15, 0.85) // 점멸: sin 파형
          : 1.0;

      // 캐릭터 스프라이트 렌더링 (이미지 우선, 없으면 Canvas 폴백)
      final charImg = _getCharacterImage(unit);
      if (charImg != null) {
        final srcRect = Rect.fromLTWH(0, 0, charImg.width.toDouble(), charImg.height.toDouble());
        final drawSize = characterUnitRadius * 2.5;
        final dstRect = Rect.fromCenter(center: center, width: drawSize, height: drawSize);
        final spritePaint = Paint();
        if (unitAlpha < 1.0) {
          spritePaint.color = Color.fromRGBO(255, 255, 255, unitAlpha);
        }
        canvas.drawImageRect(charImg, srcRect, dstRect, spritePaint);
      } else {
        // 폴백: 원형 드로잉
        final unitPaint = Paint()
          ..color = unitColor.withValues(alpha: unitAlpha);
        canvas.drawCircle(center, characterUnitRadius, unitPaint);
      }

      // 전사 검 휘두르기 효과 렌더링
      if (unit.definition.role == RoleType.tanker && unit.isSwinging) {
        const double swordLength = 50.0;
        const double swordWidth = 6.0;
        const double arcRadius = 55.0;

        // 검 휘두르기 궤적 (반시계방향 호)
        final arcPaint = Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0;

        // 휘두르기 진행에 따른 호 그리기
        final sweepAngle = -unit.swingProgress * 4.71239; // 반시계방향
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: arcRadius),
          0, // 시작 각도 (오른쪽부터)
          sweepAngle,
          false,
          arcPaint,
        );

        // 검 그리기
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(unit.swordSwingAngle);

        // 검 몸통 (흰색)
        final swordPaint = Paint()
          ..color = const Color(0xFFE0E0E0)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(characterUnitRadius, -swordWidth / 2, swordLength, swordWidth),
          swordPaint,
        );

        // 검 테두리 (어두운 색)
        final swordBorderPaint = Paint()
          ..color = const Color(0xFF616161)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRect(
          Rect.fromLTWH(characterUnitRadius, -swordWidth / 2, swordLength, swordWidth),
          swordBorderPaint,
        );

        // 검 끝부분 (삼각형)
        final tipPath = Path()
          ..moveTo(characterUnitRadius + swordLength, -swordWidth / 2)
          ..lineTo(characterUnitRadius + swordLength + 10, 0)
          ..lineTo(characterUnitRadius + swordLength, swordWidth / 2)
          ..close();
        canvas.drawPath(tipPath, swordPaint);
        canvas.drawPath(tipPath, swordBorderPaint);

        // 검 손잡이 (갈색)
        final handlePaint = Paint()..color = const Color(0xFF8D6E63);
        canvas.drawRect(
          Rect.fromLTWH(characterUnitRadius - 5, -swordWidth / 2 - 2, 8, swordWidth + 4),
          handlePaint,
        );

        canvas.restore();

        // 휘두르기 범위 표시 (반투명 원)
        final rangePaint = Paint()
          ..color = const Color(0xFFFF5722).withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 60.0, rangePaint);
      }

      // 역할 이모지 표시 (스프라이트가 있으면 생략)
      if (charImg == null) {
        _drawCenteredText(
          canvas,
          unit.definition.role.emoji,
          center,
          fontSize: 16,
          color: const Color(0xFFFFFFFF),
        );
      }

      // HP 바 (크고 명확하게)
      const double hpBarWidth = 32.0;
      const double hpBarHeight = 4.0;
      const double hpBarMargin = 3.0;

      final hpRatio = unit.maxHp == 0 ? 0 : unit.currentHp / unit.maxHp;
      final hpBarX = center.dx - hpBarWidth / 2;
      final hpBarY = center.dy - characterUnitRadius - hpBarHeight - hpBarMargin;

      // HP 바 배경 (검은색)
      final hpBgPaint = Paint()..color = const Color(0xFF000000);
      final hpBgRect = Rect.fromLTWH(hpBarX, hpBarY, hpBarWidth, hpBarHeight);
      canvas.drawRect(hpBgRect, hpBgPaint);

      // HP 바 전경 (초록색)
      final hpFgPaint = Paint()..color = const Color(0xFF4CAF50);
      final hpFgRect = Rect.fromLTWH(
        hpBarX,
        hpBarY,
        hpBarWidth * hpRatio.clamp(0.0, 1.0),
        hpBarHeight,
      );
      canvas.drawRect(hpFgRect, hpFgPaint);

      // HP 바 테두리 (흰색)
      final hpBorderPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(hpBgRect, hpBorderPaint);

      // 버프 아이콘 표시 (우측 상단)
      if (unit.hasAttackSpeedBuff) {
        _drawCenteredText(
          canvas,
          '⚡', // 번개 = 공격속도
          Offset(center.dx + characterUnitRadius - 4, center.dy - characterUnitRadius + 4),
          fontSize: 10,
          color: const Color(0xFFFFD700), // 금색
        );
      }
      if (unit.hasMoveSpeedBuff) {
        _drawCenteredText(
          canvas,
          '💨', // 바람 = 이동속도
          Offset(center.dx - characterUnitRadius + 4, center.dy - characterUnitRadius + 4),
          fontSize: 10,
          color: const Color(0xFFFFD700), // 금색
        );
      }
    }
  }

  // 투사물 렌더링 (역할별 비주얼)
  void _renderProjectiles(Canvas canvas) {
    for (final proj in projectiles) {
      final center = Offset(proj.pos.x, proj.pos.y);

      // 마법 투사물 (마법사) — 펄스하는 광구 + 스파크 파티클
      if (proj.isMagic) {
        const projColor = Color(0xFFCE93D8);
        // 스플래시 범위 표시
        canvas.drawCircle(
          center,
          proj.splashRadius * 0.5,
          Paint()..color = projColor.withValues(alpha: 0.15),
        );
        // 펄스하는 중심 구체
        final pulseR = 6.0 + sin(gameTime * 10) * 2.0;
        canvas.drawCircle(center, pulseR, Paint()..color = projColor);
        // 글로우
        canvas.drawCircle(
          center,
          pulseR * 1.8,
          Paint()..color = projColor.withValues(alpha: 0.25),
        );
        // 주변 파티클 (2개가 회전)
        for (int i = 0; i < 2; i++) {
          final angle = gameTime * 8 + i * 3.14;
          final px = proj.pos.x + cos(angle) * (pulseR + 5);
          final py = proj.pos.y + sin(angle) * (pulseR + 5);
          canvas.drawCircle(
            Offset(px, py),
            1.5,
            Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7),
          );
        }
        continue;
      }

      // 궁수 — 삼각형 화살 + 짧은 몸통
      if (proj.sourceClass == ClassType.archer) {
        const projColor = Color(0xFFFF8A80);
        final angle = atan2(proj.velocity.y, proj.velocity.x);
        canvas.save();
        canvas.translate(proj.pos.x, proj.pos.y);
        canvas.rotate(angle);
        // 삼각형 화살촉
        final arrowHead = Path()
          ..moveTo(6, 0)
          ..lineTo(-4, -3.5)
          ..lineTo(-4, 3.5)
          ..close();
        canvas.drawPath(arrowHead, Paint()..color = projColor);
        // 몸통 선
        canvas.drawLine(
          const Offset(-4, 0),
          const Offset(-12, 0),
          Paint()
            ..color = projColor.withValues(alpha: 0.6)
            ..strokeWidth = 1.5,
        );
        canvas.restore();
        continue;
      }

      // 총잡이 — 작은 원 + 잔상 트레일
      if (proj.sourceClass == ClassType.gunslinger) {
        const projColor = Color(0xFFFFE082);
        // 잔상 (alpha 감소)
        for (int t = 0; t < proj.trail.length; t++) {
          final alpha = 0.5 - (t * 0.15);
          final r = 2.5 - (t * 0.5);
          canvas.drawCircle(
            Offset(proj.trail[t].x, proj.trail[t].y),
            r.clamp(1.0, 3.0),
            Paint()..color = projColor.withValues(alpha: alpha.clamp(0.1, 0.5)),
          );
        }
        // 선두 탄환
        canvas.drawCircle(center, 3.0, Paint()..color = projColor);
        continue;
      }

      // 성직자 — 떠오르는 십자가
      if (proj.sourceRole == RoleType.priest) {
        const projColor = Color(0xFF81C784);
        final crossPaint = Paint()
          ..color = projColor.withValues(alpha: 0.8)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(proj.pos.x - 4, proj.pos.y),
          Offset(proj.pos.x + 4, proj.pos.y),
          crossPaint,
        );
        canvas.drawLine(
          Offset(proj.pos.x, proj.pos.y - 4),
          Offset(proj.pos.x, proj.pos.y + 4),
          crossPaint,
        );
        continue;
      }

      // 기본 투사물 (fallback)
      Color projColor;
      switch (proj.sourceRole) {
        case RoleType.physicalDealer:
          projColor = const Color(0xFFFF8A80);
          break;
        case RoleType.magicDealer:
          projColor = const Color(0xFFCE93D8);
          break;
        case RoleType.utility:
          projColor = const Color(0xFF80CBC4);
          break;
        default:
          projColor = const Color(0xFFFFFFFF);
          break;
      }
      canvas.drawCircle(center, 4.0, Paint()..color = projColor);
      final tailStart = Offset(
        proj.pos.x - proj.velocity.x * 0.05,
        proj.pos.y - proj.velocity.y * 0.05,
      );
      canvas.drawLine(
        tailStart,
        center,
        Paint()
          ..color = projColor.withValues(alpha: 0.5)
          ..strokeWidth = 2.0,
      );
    }
  }

  // VFX 이펙트 렌더링
  void _renderVfxEffects(Canvas canvas) {
    for (final vfx in vfxEffects) {
      final center = Offset(vfx.pos.x, vfx.pos.y);
      final p = vfx.progress;

      switch (vfx.type) {
        // 히트 스파크: 방사형 선이 퍼지며 사라짐
        case VfxType.hit:
          const sparkCount = 5;
          final radius = 5.0 + p * 12.0;
          final alpha = (1.0 - p).clamp(0.0, 1.0);
          final paint = Paint()
            ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round;
          for (int i = 0; i < sparkCount; i++) {
            final angle = (i / sparkCount) * 3.14159 * 2 + 0.3;
            final dx = cos(angle) * radius;
            final dy = sin(angle) * radius;
            canvas.drawLine(
              Offset(center.dx + dx * 0.3, center.dy + dy * 0.3),
              Offset(center.dx + dx, center.dy + dy),
              paint,
            );
          }
          break;

        // 죽음 파프: 팽창하는 원 + 흩어지는 파티클
        case VfxType.death:
          if (p < 0.4) {
            // Phase 1: 원 팽창
            final phase1 = p / 0.4;
            final radius = 8.0 + phase1 * 18.0;
            final alpha = (1.0 - phase1 * 0.6).clamp(0.0, 1.0);
            canvas.drawCircle(
              center,
              radius,
              Paint()..color = vfx.color.withValues(alpha: alpha),
            );
          } else {
            // Phase 2: 파티클 흩어짐
            final phase2 = (p - 0.4) / 0.6;
            final alpha = (1.0 - phase2).clamp(0.0, 1.0);
            for (int i = 0; i < 6; i++) {
              final angle = (i / 6) * 3.14159 * 2;
              final dist = 10.0 + phase2 * 25.0;
              final px = center.dx + cos(angle) * dist;
              final py = center.dy + sin(angle) * dist;
              canvas.drawCircle(
                Offset(px, py),
                2.5 - phase2 * 1.5,
                Paint()..color = vfx.color.withValues(alpha: alpha),
              );
            }
          }
          break;

        // 충격파: 확대되는 링
        case VfxType.shockwave:
          final maxR = vfx.maxRadius;
          final radius = p * maxR;
          final alpha = (1.0 - p).clamp(0.0, 1.0);
          final strokeW = 20.0 - p * 18.0;
          canvas.drawCircle(
            center,
            radius,
            Paint()
              ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeW.clamp(2.0, 20.0),
          );
          // 중앙 플래시 (처음 0.1초만)
          if (vfx.timer < 0.1) {
            final flashAlpha = (1.0 - vfx.timer / 0.1).clamp(0.0, 1.0);
            canvas.drawRect(
              Rect.fromLTWH(0, 0, size.x, size.y),
              Paint()..color = Color.fromRGBO(255, 255, 255, flashAlpha * 0.3),
            );
          }
          break;

        // 배리어: 회전하는 6각형
        case VfxType.barrier:
          final barrierAlpha = vfx.duration - vfx.timer < 3.0
              ? (sin(vfx.timer * 8) * 0.5 + 0.5).clamp(0.0, 1.0)
              : 0.6;
          final angle = vfx.timer * 0.5;
          final r = vfx.maxRadius;
          final hexPath = Path();
          for (int i = 0; i < 6; i++) {
            final a = angle + (i / 6) * 3.14159 * 2;
            final hx = center.dx + cos(a) * r;
            final hy = center.dy + sin(a) * r;
            if (i == 0) {
              hexPath.moveTo(hx, hy);
            } else {
              hexPath.lineTo(hx, hy);
            }
          }
          hexPath.close();
          canvas.drawPath(
            hexPath,
            Paint()
              ..color = const Color(0xFF00BCD4).withValues(alpha: barrierAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
          break;
      }
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
      '基本剣 (DMG: $weaponDamage)',
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
}
