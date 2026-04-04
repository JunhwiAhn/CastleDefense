// 인게임 렌더링: 배경, 경로, 타워 슬롯, 타워, 몬스터, 투사물, VFX
part of '../castle_defense_game.dart';

extension GameRendering on CastleDefenseGame {

  // ─── 인게임 전체 렌더 (waving / prep) ─────────
  void _renderGame(Canvas canvas) {
    _renderBackground(canvas);
    _renderPath(canvas);
    _renderTowerSlots(canvas);
    _renderTowers(canvas);
    _renderMonsters(canvas);
    _renderProjectiles(canvas);
    _renderVfx(canvas);
    _renderDamageNumbers(canvas);
    _renderCastle(canvas);
  }

  // ─── 배경 ────────────────────────────────────
  void _renderBackground(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF1A2E1A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);

    // 격자 패턴
    final gridPaint = Paint()
      ..color = const Color(0xFF243524)
      ..strokeWidth = 1;
    for (double x = 0; x < size.x; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }
  }

  // ─── 경로 렌더링 ─────────────────────────────
  void _renderPath(Canvas canvas) {
    const double pathW = 60.0;

    // 경로 채우기
    final fillPaint = Paint()..color = const Color(0xFF5D4E37);
    // 경로 테두리
    final borderPaint = Paint()
      ..color = const Color(0xFF8B7355)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < kPathWaypointDefs.length - 1; i++) {
      final a = kPathWaypointDefs[i];
      final b = kPathWaypointDefs[i + 1];
      final rect = _segmentRect(a.$1, a.$2, b.$1, b.$2, pathW);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
    }

    // 방향 화살표 (각 구간 중앙)
    final arrowPaint = Paint()
      ..color = const Color(0xFFAA9977)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 1; i < kPathWaypointDefs.length - 1; i++) {
      final a = kPathWaypointDefs[i];
      final b = kPathWaypointDefs[i + 1];
      final mx = (a.$1 + b.$1) / 2;
      final my = (a.$2 + b.$2) / 2;
      final dx = b.$1 - a.$1;
      final dy = b.$2 - a.$2;
      final len = sqrt(dx * dx + dy * dy).clamp(1.0, double.infinity);
      final nx = dx / len * 10;
      final ny = dy / len * 10;
      canvas.drawLine(Offset(mx - nx, my - ny), Offset(mx + nx, my + ny), arrowPaint);
    }

    // 스폰 표시
    _drawCenteredText(canvas, 'SPAWN',
        Offset(kPathWaypointDefs[0].$1, 20), fontSize: 10,
        color: const Color(0xFFFFAA44));
  }

  // 두 점을 잇는 직사각형 구간 (경로 폭 적용)
  Rect _segmentRect(double ax, double ay, double bx, double by, double w) {
    final hw = w / 2;
    if ((bx - ax).abs() > (by - ay).abs()) {
      // 수평 구간
      return Rect.fromLTRB(
        min(ax, bx), ay - hw, max(ax, bx), ay + hw);
    } else {
      // 수직 구간
      return Rect.fromLTRB(
        ax - hw, min(ay, by), ax + hw, max(ay, by));
    }
  }

  // ─── 타워 슬롯 렌더링 ─────────────────────────
  void _renderTowerSlots(Canvas canvas) {
    for (final slot in towerSlots) {
      if (!slot.isEmpty) continue;

      final isHighlighted = placingTowerType != null;
      final paint = Paint()
        ..color = isHighlighted
            ? const Color(0x8844FF88)
            : const Color(0x44FFFFFF)
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = isHighlighted
            ? const Color(0xFF44FF88)
            : const Color(0x88FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(
        Offset(slot.pos.x, slot.pos.y), 22, paint);
      canvas.drawCircle(
        Offset(slot.pos.x, slot.pos.y), 22, border);

      // "+" 아이콘
      _drawCenteredText(canvas, '+',
          Offset(slot.pos.x, slot.pos.y),
          fontSize: 18,
          color: isHighlighted
              ? const Color(0xFF44FF88)
              : const Color(0xAAFFFFFF));
    }
  }

  // ─── 타워 렌더링 ──────────────────────────────
  void _renderTowers(Canvas canvas) {
    for (final slot in towerSlots) {
      final tower = slot.tower;
      if (tower == null) continue;

      // 사거리 원 (선택된 타워만)
      if (tower.showRange || selectedTower == tower) {
        final rangePaint = Paint()
          ..color = const Color(0x33FFFFFF)
          ..style = PaintingStyle.fill;
        final rangeBorder = Paint()
          ..color = const Color(0x88FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        final effectiveRange = tower.range * getRaceRangeBonus();
        canvas.drawCircle(
            Offset(tower.pos.x, tower.pos.y), effectiveRange, rangePaint);
        canvas.drawCircle(
            Offset(tower.pos.x, tower.pos.y), effectiveRange, rangeBorder);
      }

      // 타워 아이콘 (스프라이트 있으면 사용, 없으면 폴백)
      final img = _getTowerImage(tower);
      if (img != null) {
        final src = Rect.fromLTWH(0, 0,
            img.width.toDouble(), img.height.toDouble());
        final dst = Rect.fromCenter(
            center: Offset(tower.pos.x, tower.pos.y),
            width: 44, height: 44);
        canvas.drawImageRect(img, src, dst, Paint());
      } else {
        _drawTowerFallback(canvas, tower);
      }

      // 레벨 배지
      if (tower.level > 1) {
        final badgePaint = Paint()..color = const Color(0xFFFFD700);
        canvas.drawCircle(
            Offset(tower.pos.x + 14, tower.pos.y - 14), 8, badgePaint);
        _drawCenteredText(canvas, '${tower.level}',
            Offset(tower.pos.x + 14, tower.pos.y - 14),
            fontSize: 9, color: const Color(0xFF000000));
      }
    }
  }

  Image? _getTowerImage(_Tower tower) {
    if (tower.characterId != null) {
      final def = CharacterDefinitions.byId(tower.characterId!);
      return characterImages[def.classType.name];
    }
    return null;
  }

  void _drawTowerFallback(Canvas canvas, _Tower tower) {
    final (color, icon) = switch (tower.type) {
      TowerType.archer => (const Color(0xFF44BB44), '🏹'),
      TowerType.cannon => (const Color(0xFFBB4444), '💣'),
      TowerType.mage   => (const Color(0xFF4444BB), '🔮'),
      TowerType.sniper => (const Color(0xFFBBBB44), '🎯'),
    };

    final paint = Paint()..color = color;
    final border = Paint()
      ..color = color.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(tower.pos.x, tower.pos.y),
            width: 40, height: 40),
        const Radius.circular(8)),
      paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(tower.pos.x, tower.pos.y),
            width: 40, height: 40),
        const Radius.circular(8)),
      border);
    _drawCenteredText(canvas, icon,
        Offset(tower.pos.x, tower.pos.y), fontSize: 20);
  }

  // ─── 몬스터 렌더링 ────────────────────────────
  void _renderMonsters(Canvas canvas) {
    for (final m in monsters) {
      if (!m.isAlive) continue;

      // 피격 점멸
      final alpha = m.damageFlashTimer > 0 ? 0.4 : 1.0;
      final paint = Paint()..color = Color.fromRGBO(255, 255, 255, alpha);

      // 스프라이트 또는 폴백
      final img = _getMonsterImage(m);
      if (img != null) {
        final src = Rect.fromLTWH(0, 0,
            img.width.toDouble(), img.height.toDouble());
        final size = _monsterDisplaySize(m);
        final dst = Rect.fromCenter(
            center: Offset(m.pos.x, m.pos.y),
            width: size, height: size);
        canvas.drawImageRect(img, src, dst, paint);
      } else {
        _drawMonsterFallback(canvas, m, alpha);
      }

      // HP 바
      _renderMonsterHpBar(canvas, m);

      // 슬로우 표시
      if (m.slowTimer > 0) {
        final slowPaint = Paint()
          ..color = const Color(0x882196F3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(m.pos.x, m.pos.y), 14, slowPaint);
      }
    }
  }

  Image? _getMonsterImage(_Monster m) {
    return switch (m.enemyType) {
      EnemyType.boss     => bossMonsterImage,
      EnemyType.miniBoss => minibossMonsterImage,
      _                  => goblinImage,
    };
  }

  double _monsterDisplaySize(_Monster m) => switch (m.enemyType) {
    EnemyType.boss     => 52.0,
    EnemyType.miniBoss => 38.0,
    EnemyType.tank     => 32.0,
    _                  => 26.0,
  };

  void _drawMonsterFallback(Canvas canvas, _Monster m, double alpha) {
    final color = switch (m.enemyType) {
      EnemyType.normal   => Color.fromRGBO(220,  80,  80, alpha),
      EnemyType.fast     => Color.fromRGBO(220, 180,  80, alpha),
      EnemyType.tank     => Color.fromRGBO(100, 100, 220, alpha),
      EnemyType.miniBoss => Color.fromRGBO(220,  80, 220, alpha),
      EnemyType.boss     => Color.fromRGBO(255,  50,  50, alpha),
    };
    final r = _monsterDisplaySize(m) / 2;
    canvas.drawCircle(Offset(m.pos.x, m.pos.y), r,
        Paint()..color = color);
  }

  void _renderMonsterHpBar(Canvas canvas, _Monster m) {
    const double barW = 28.0, barH = 4.0;
    final ratio = (m.hp / m.maxHp).clamp(0.0, 1.0);
    final left = m.pos.x - barW / 2;
    final top = m.pos.y - _monsterDisplaySize(m) / 2 - 7;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barW, barH),
          const Radius.circular(2)),
      Paint()..color = const Color(0xFF444444));
    if (ratio > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, barW * ratio, barH),
            const Radius.circular(2)),
        Paint()..color = const Color(0xFF44DD44));
    }
  }

  // ─── 투사물 렌더링 ────────────────────────────
  void _renderProjectiles(Canvas canvas) {
    for (final p in projectiles) {
      // 잔상
      for (int i = 0; i < p.trail.length; i++) {
        final t = p.trail[i];
        final a = (i + 1) / (p.trail.length + 1) * 0.4;
        canvas.drawCircle(Offset(t.x, t.y), 3,
            Paint()..color = Color.fromRGBO(255, 255, 200, a));
      }

      final color = switch (p.sourceTower) {
        TowerType.archer => const Color(0xFF88FF88),
        TowerType.cannon => const Color(0xFFFF8833),
        TowerType.mage   => const Color(0xFF8888FF),
        TowerType.sniper => const Color(0xFFFFFF44),
      };
      final r = p.splashRadius > 0 ? 5.0 : 4.0;
      canvas.drawCircle(Offset(p.pos.x, p.pos.y), r,
          Paint()..color = color);
    }
  }

  // ─── VFX 렌더링 ──────────────────────────────
  void _renderVfx(Canvas canvas) {
    for (final v in vfxEffects) {
      final t = v.progress;
      switch (v.type) {
        case VfxType.hit:
          canvas.drawCircle(
            Offset(v.pos.x, v.pos.y),
            v.maxRadius * t,
            Paint()..color = v.color.withAlpha(((1 - t) * 200).round()));
        case VfxType.death:
          for (int i = 0; i < 6; i++) {
            final angle = i * pi / 3 + t * pi;
            final r = v.maxRadius * t;
            canvas.drawCircle(
              Offset(v.pos.x + cos(angle) * r,
                     v.pos.y + sin(angle) * r),
              3 * (1 - t),
              Paint()..color = v.color.withAlpha(((1 - t) * 255).round()));
          }
        case VfxType.shockwave:
          canvas.drawCircle(
            Offset(v.pos.x, v.pos.y),
            v.maxRadius * t,
            Paint()
              ..color = v.color.withAlpha(((1 - t) * 180).round())
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 * (1 - t));
      }
    }
  }

  // ─── 데미지 숫자 ─────────────────────────────
  void _renderDamageNumbers(Canvas canvas) {
    for (final d in damageNumbers) {
      final t = d.timer / _DamageNumber.duration;
      final y = d.pos.y - t * 25;
      final alpha = (1 - t);
      _drawCenteredText(
        canvas,
        '${d.amount}',
        Offset(d.pos.x, y),
        fontSize: d.isCrit ? 14 : 11,
        color: Color.fromRGBO(
            d.isCrit ? 255 : 255,
            d.isCrit ? 220 : 255,
            d.isCrit ? 50  : 150,
            alpha),
      );
    }
  }

  // ─── 성 렌더링 ────────────────────────────────
  void _renderCastle(Canvas canvas) {
    final cx = kPathWaypointDefs.last.$1;
    final cy = kPathWaypointDefs.last.$2;

    // 점멸 효과
    final flashAlpha = castleFlashTimer > 0
        ? (0.4 + 0.6 * (castleFlashTimer / 0.3)).clamp(0.0, 1.0)
        : 1.0;

    if (castleImageLoaded && castleImage != null) {
      final src = Rect.fromLTWH(0, 0,
          castleImage!.width.toDouble(), castleImage!.height.toDouble());
      final dst = Rect.fromCenter(
          center: Offset(cx, cy), width: 60, height: 60);
      canvas.drawImageRect(
          castleImage!, src, dst,
          Paint()..color = Color.fromRGBO(255, 255, 255, flashAlpha));
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 56, height: 56),
            const Radius.circular(8)),
        Paint()
          ..color = Color.fromRGBO(
              200, castleFlashTimer > 0 ? 50 : 180, 50, flashAlpha));
      _drawCenteredText(canvas, '🏰', Offset(cx, cy), fontSize: 28);
    }
  }

  // ─── 종족 선택 화면 ───────────────────────────
  void _renderRaceSelect(Canvas canvas) {
    // 배경
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF0D1B0D));

    _drawCenteredText(canvas, '종족을 선택하세요',
        Offset(size.x / 2, 80), fontSize: 24,
        color: const Color(0xFFFFD700));
    _drawCenteredText(canvas, '선택 후 변경 불가',
        Offset(size.x / 2, 112), fontSize: 13,
        color: const Color(0xFF888888));

    final races = [
      (RaceType.human,   '인간족',   '⚔️', '골드+15%, 타워 비용-5%',     const Color(0xFF4488FF)),
      (RaceType.orc,     '오크족',   '🪓', '공격력+20%, 대포 업글-20%',  const Color(0xFFFF6633)),
      (RaceType.elf,     '엘프족',   '🌿', '사거리+20%, 공속+10%',       const Color(0xFF44BB44)),
      (RaceType.machina, '기계족',   '⚙️', '업그레이드-25%, 시너지+8%',  const Color(0xFF888888)),
      (RaceType.demon,   '악마족',   '😈', '처치 HP회복, 디버프+30%',    const Color(0xFF9944CC)),
    ];

    const double cardH = 90.0, cardW = 340.0, gap = 10.0;
    final startY = 150.0;

    for (int i = 0; i < races.length; i++) {
      final (race, name, icon, desc, color) = races[i];
      final rect = Rect.fromLTWH(
          (size.x - cardW) / 2, startY + i * (cardH + gap), cardW, cardH);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        Paint()..color = color.withAlpha(40));
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        Paint()
          ..color = color.withAlpha(180)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

      _drawCenteredText(canvas, icon,
          Offset(rect.left + 36, rect.center.dy), fontSize: 28);
      _drawCenteredText(canvas, name,
          Offset(rect.left + 160, rect.center.dy - 14),
          fontSize: 16, color: color);
      _drawCenteredText(canvas, desc,
          Offset(rect.left + 160, rect.center.dy + 10),
          fontSize: 11, color: const Color(0xFFAAAAAA));
    }
  }
}
