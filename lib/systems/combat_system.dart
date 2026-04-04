// 전투 시스템: 타워 자동공격, 웨이포인트 이동, 투사물
part of '../castle_defense_game.dart';

extension CombatSystem on CastleDefenseGame {

  // ─── 몬스터 이동 업데이트 ────────────────────
  void _updateMonsters(double dt) {
    for (var i = monsters.length - 1; i >= 0; i--) {
      final m = monsters[i];
      if (!m.isAlive) continue;

      // 타이머 감소
      if (m.damageFlashTimer > 0) m.damageFlashTimer -= dt;
      if (m.slowTimer > 0) m.slowTimer -= dt;

      // 애니메이션
      m.animTimer += dt;
      if (m.animTimer >= 0.15) {
        m.animTimer = 0.0;
        m.animFrame = (m.animFrame + 1) % 4;
      }

      // 웨이포인트 이동
      final nextIdx = m.waypointIndex + 1;
      if (nextIdx >= kPathWaypointDefs.length) {
        // 성 도달 → 성 HP 감소
        _onMonsterReachedCastle(m, i);
        continue;
      }

      final target = Vector2(
        kPathWaypointDefs[nextIdx].$1,
        kPathWaypointDefs[nextIdx].$2,
      );
      final dx = target.x - m.pos.x;
      final dy = target.y - m.pos.y;
      final dist = sqrt(dx * dx + dy * dy);
      final spd = m.effectiveSpeed * dt;

      if (dist <= spd) {
        // 웨이포인트 도달
        m.pos.setFrom(target);
        m.waypointIndex = nextIdx;
        m.pathProgress = nextIdx.toDouble();
      } else {
        m.pos.x += dx / dist * spd;
        m.pos.y += dy / dist * spd;
        // 진행도 (0.0 ~ totalWaypoints)
        m.pathProgress = nextIdx - 1 + (1.0 - dist / _waypointSegmentLen(nextIdx - 1));
      }
    }
  }

  double _waypointSegmentLen(int fromIdx) {
    if (fromIdx + 1 >= kPathWaypointDefs.length) return 1.0;
    final a = kPathWaypointDefs[fromIdx];
    final b = kPathWaypointDefs[fromIdx + 1];
    final dx = b.$1 - a.$1;
    final dy = b.$2 - a.$2;
    final len = sqrt(dx * dx + dy * dy);
    return len < 0.01 ? 1.0 : len;
  }

  // ─── 성 도달 처리 ────────────────────────────
  void _onMonsterReachedCastle(_Monster m, int idx) {
    castleHp = (castleHp - m.castleDamage).clamp(0, castleMaxHp); // #88: castleHp 범위 제한
    _perfectClearSoFar = false;
    castleFlashTimer = 0.3;
    m.isAlive = false;
    monsters.removeAt(idx);
    escapedCount++;

    vfxEffects.add(_VfxEffect(
      pos: Vector2(195, 790),
      type: VfxType.hit,
      duration: 0.4,
      color: const Color(0xFFFF4444),
      maxRadius: 25,
    ));

    if (castleHp <= 0) {
      _onGameOver();
    }
  }

  // ─── 타워 공격 업데이트 ──────────────────────
  void _updateTowers(double dt) {
    for (final slot in towerSlots) {
      final tower = slot.tower;
      if (tower == null) continue;

      // 스프라이트 애니메이션 업데이트
      final def = tower.charDef;
      final totalFrames = def?.totalFrames ?? 15;
      if (tower.isAttacking) {
        tower.animTimer += dt;
        const double frameInterval = 0.06; // 15프레임 기준 약 0.9초
        if (tower.animTimer >= frameInterval) {
          tower.animTimer = 0.0;
          tower.animFrame++;
          if (tower.animFrame >= totalFrames) {
            tower.animFrame = 0;
            tower.isAttacking = false;
          }
        }
      }

      tower.attackTimer += dt;
      final interval = tower.attackInterval;
      if (tower.attackTimer < interval) continue;

      final target = _findTarget(tower);
      if (target == null) continue;

      // 타겟 방향에 따라 좌우 반전 결정
      tower.faceLeft = target.pos.x < tower.pos.x;

      tower.attackTimer = 0.0;
      tower.isAttacking = true;
      tower.animFrame = 0;
      tower.animTimer = 0.0;
      _fireTowerProjectile(tower, target);
    }
  }

  // ─── 타겟 선정 ───────────────────────────────
  _Monster? _findTarget(_Tower tower) {
    _Monster? best;
    double bestVal = double.negativeInfinity;

    for (final m in monsters) {
      if (!m.isAlive) continue;
      final dx = m.pos.x - tower.pos.x;
      final dy = m.pos.y - tower.pos.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist > tower.range) continue;

      final double val = switch (tower.targetPriority) {
        TargetPriority.first     => m.pathProgress,
        TargetPriority.strongest => m.hp.toDouble(),
        TargetPriority.weakest   => -m.hp.toDouble(),
        TargetPriority.closest   => -dist,
      };

      if (val > bestVal) {
        bestVal = val;
        best = m;
      }
    }
    return best;
  }

  // ─── 투사물 발사 ─────────────────────────────
  void _fireTowerProjectile(_Tower tower, _Monster target) {
    final dx = target.pos.x - tower.pos.x;
    final dy = target.pos.y - tower.pos.y;
    final dist = sqrt(dx * dx + dy * dy).clamp(1.0, double.infinity);

    // 종족 패시브 적용한 최종 데미지
    final dmg = _applyRaceDamageBonus(tower.damage);
    const double projSpeed = 350.0;

    projectiles.add(_Projectile(
      pos: tower.pos.clone(),
      velocity: Vector2(dx / dist * projSpeed, dy / dist * projSpeed),
      damage: dmg,
      sourceTower: tower.type,
      targetMonster: target,
      splashRadius: tower.type == TowerType.cannon
          ? tower.splash * (playerRace == RaceType.machina && tower.level >= 3 ? 1.3 : 1.0)
          : 0.0,
      isSlow: tower.type == TowerType.mage,
    ));
  }

  // ─── 투사물 업데이트 ─────────────────────────
  void _updateProjectiles(double dt) {
    for (var i = projectiles.length - 1; i >= 0; i--) {
      final p = projectiles[i];

      // 유도 미사일: 살아있는 타겟이면 방향 재조정
      if (p.targetMonster != null && p.targetMonster!.isAlive) {
        final dx = p.targetMonster!.pos.x - p.pos.x;
        final dy = p.targetMonster!.pos.y - p.pos.y;
        final dist = sqrt(dx * dx + dy * dy).clamp(1.0, double.infinity);
        const double spd = 350.0;
        p.velocity = Vector2(dx / dist * spd, dy / dist * spd);
      }

      p.pos.x += p.velocity.x * dt;
      p.pos.y += p.velocity.y * dt;

      // 잔상
      if (p.trail.length >= 3) p.trail.removeAt(0);
      p.trail.add(p.pos.clone());

      // 타겟 충돌 체크
      bool hit = false;
      if (p.targetMonster != null && p.targetMonster!.isAlive) {
        final dx = p.targetMonster!.pos.x - p.pos.x;
        final dy = p.targetMonster!.pos.y - p.pos.y;
        if (sqrt(dx * dx + dy * dy) < 16.0) {
          hit = true;
          _onProjectileHit(p);
        }
      } else {
        // 타겟 소실 시 근처 적 충돌
        for (final m in monsters) {
          if (!m.isAlive) continue;
          final dx = m.pos.x - p.pos.x;
          final dy = m.pos.y - p.pos.y;
          if (sqrt(dx * dx + dy * dy) < 16.0) {
            hit = true;
            p.targetMonster = m;
            _onProjectileHit(p);
            break;
          }
        }
      }

      // 화면 밖 제거
      if (hit || p.pos.x < -50 || p.pos.x > 440 || p.pos.y < -50 || p.pos.y > 900) {
        projectiles.removeAt(i);
      }
    }
  }

  // ─── 투사물 명중 처리 ────────────────────────
  void _onProjectileHit(_Projectile p) {
    if (p.splashRadius > 0) {
      // 범위 데미지 (대포)
      for (final m in monsters) {
        if (!m.isAlive) continue;
        final dx = m.pos.x - p.pos.x;
        final dy = m.pos.y - p.pos.y;
        if (sqrt(dx * dx + dy * dy) <= p.splashRadius) {
          _damageMonster(m, p.damage.round());
        }
      }
      vfxEffects.add(_VfxEffect(
        pos: p.pos.clone(),
        type: VfxType.shockwave,
        duration: 0.4,
        color: const Color(0xFFFF8800),
        maxRadius: p.splashRadius,
      ));
    } else {
      // 단일 타겟
      final t = p.targetMonster;
      if (t != null && t.isAlive) {
        _damageMonster(t, p.damage.round());
        // 마법사 타워 슬로우
        if (p.isSlow) {
          final slowDur = playerRace == RaceType.demon ? 2.6 : 2.0;
          t.slowTimer = slowDur;
          t.slowFactor = 0.35;
        }
      }
    }
    vfxEffects.add(_VfxEffect(
      pos: p.pos.clone(),
      type: VfxType.hit,
      duration: 0.2,
      color: const Color(0xFFFFFFAA),
    ));
  }

  // ─── 몬스터 피해 처리 ───────────────────────
  void _damageMonster(_Monster m, int dmg) {
    m.hp -= dmg;
    m.damageFlashTimer = 0.12;
    damageNumbers.add(_DamageNumber(
      pos: m.pos.clone()..y -= 20,
      amount: dmg,
    ));
    if (m.hp <= 0) {
      _killMonster(m);
    }
  }

  void _killMonster(_Monster m) {
    m.isAlive = false;
    defeatedCount++;

    // 골드 지급 (악마족: 마법사 타워 처치 시 +1, 일단 기본 지급)
    playerInGameGold += m.goldReward;

    // 골드 획득 부유 텍스트 표시
    if (m.goldReward > 0) {
      damageNumbers.add(_DamageNumber(
        pos: m.pos.clone()..y -= 10,
        amount: m.goldReward,
        isGold: true,
      ));
    }

    vfxEffects.add(_VfxEffect(
      pos: m.pos.clone(),
      type: VfxType.death,
      duration: 0.35,
      color: const Color(0xFFFF6633),
      maxRadius: 18,
    ));

    // 악마족: 5% 확률 성 HP +1 회복
    if (playerRace == RaceType.demon && _random.nextDouble() < 0.05) {
      castleHp = (castleHp + 1).clamp(0, castleMaxHp);
    }
  }

  // ─── VFX 업데이트 ────────────────────────────
  void _updateVfxEffects(double dt) {
    for (final v in vfxEffects) v.timer += dt;
    vfxEffects.removeWhere((v) => v.isExpired);
    for (final d in damageNumbers) d.timer += dt;
    damageNumbers.removeWhere((d) => d.isExpired);
  }

  // ─── 웨이브 클리어 체크 ──────────────────────
  void _checkWaveClear() {
    if (gameState != GameState.waving) return;
    if (spawnedCount < totalMonstersInWave) return;
    if (monsters.any((m) => m.isAlive)) return;
    _onWaveClear();
  }

  // ─── 종족 패시브: 공격력 보정 ────────────────
  double _applyRaceDamageBonus(double baseDmg) {
    return switch (playerRace) {
      RaceType.orc => baseDmg * 1.20,
      _            => baseDmg,
    };
  }

  // ─── 종족 패시브: 타워 사거리 보정 ───────────
  double getRaceRangeBonus() {
    return switch (playerRace) {
      RaceType.elf => 1.20,
      _            => 1.00,
    };
  }

  // ─── 종족 패시브: 타워 공격속도 보정 ─────────
  double getRaceAttackSpeedBonus() {
    return switch (playerRace) {
      RaceType.elf => 1.10,
      _            => 1.00,
    };
  }

  // ─── 종족 패시브: 업그레이드 비용 할인 ───────
  int getRaceUpgradeCost(_Tower tower) {
    var cost = tower.upgradeCost;
    if (playerRace == RaceType.machina) {
      cost = (cost * 0.75).round();
    } else if (playerRace == RaceType.orc &&
        (tower.type == TowerType.cannon)) {
      cost = (cost * 0.80).round();
    } else if (playerRace == RaceType.elf &&
        (tower.type == TowerType.sniper || tower.type == TowerType.archer)) {
      cost = (cost * 0.80).round();
    }
    return cost;
  }

  // ─── 타워 배치 ───────────────────────────────
  bool placeTower(int slotId, TowerType type, String? characterId) {
    final slot = towerSlots.firstWhere((s) => s.id == slotId);
    if (!slot.isEmpty) return false;

    int cost = kTowerBaseStat[type]!.cost;
    // 인간족: 타워 비용 -5%
    if (playerRace == RaceType.human) cost = (cost * 0.95).round();

    if (playerInGameGold < cost) return false;

    playerInGameGold -= cost;
    slot.tower = _Tower(
      type: type,
      slotId: slotId,
      pos: slot.pos.clone(),
      characterId: characterId,
    );
    return true;
  }

  // 캐릭터 ID로부터 타워 타입 결정
  static TowerType towerTypeFromCharacter(String characterId) {
    final def = CharacterDefinitions.tryById(characterId);
    if (def == null) return TowerType.archer;
    return switch (def.towerType) {
      TowerTypeMapping.archer => TowerType.archer,
      TowerTypeMapping.cannon => TowerType.cannon,
      TowerTypeMapping.mage   => TowerType.mage,
      TowerTypeMapping.sniper => TowerType.sniper,
    };
  }

  // ─── 타워 업그레이드 ─────────────────────────
  bool upgradeTower(_Tower tower) {
    if (tower.level >= 3) return false;
    final cost = getRaceUpgradeCost(tower);
    if (playerInGameGold < cost) return false;
    playerInGameGold -= cost;
    tower.level++;
    return true;
  }

  // ─── 타워 철거 ───────────────────────────────
  void sellTower(int slotId) {
    final slot = towerSlots.firstWhere((s) => s.id == slotId);
    if (slot.tower == null) return;
    playerInGameGold += slot.tower!.sellValue;
    slot.tower = null;
  }

  // ─── 기계족 시너지 체크 (인접 타워 +8%) ───────
  double getMachinaAdjacencyBonus(_Tower tower) {
    if (playerRace != RaceType.machina) return 1.0;
    int adjacentCount = 0;
    for (final slot in towerSlots) {
      if (slot.tower == null || slot.tower == tower) continue;
      final dx = slot.tower!.pos.x - tower.pos.x;
      final dy = slot.tower!.pos.y - tower.pos.y;
      if (sqrt(dx * dx + dy * dy) < 80.0) adjacentCount++;
    }
    return 1.0 + adjacentCount * 0.08;
  }
}
