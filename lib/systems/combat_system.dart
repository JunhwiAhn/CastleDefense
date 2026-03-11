// 전투 시스템: 몬스터, 캐릭터, 투사물, VFX 업데이트
part of '../castle_defense_game.dart';

extension CombatSystem on CastleDefenseGame {
  // -----------------------------
  // 몬스터 업데이트 / 스폰
  // -----------------------------
  void _updateMonsters(double dt) {
    // 리디자인: groundY, monsterFallSpeed 삭제 (낙하 로직 제거)
    // 리디자인: 성 접촉 반경 50px (2D 거리 체크)
    const double castleContactRadius = 50.0;

    for (var i = monsters.length - 1; i >= 0; i--) {
      final m = monsters[i];

      // 데미지 플래시 타이머 감소
      if (m.damageFlashTimer > 0) {
        m.damageFlashTimer -= dt;
      }

      // 스프라이트 애니메이션 업데이트 (이동 중에만)
      if (m.walking) {
        m.animationTimer += dt;
        const double frameTime = 0.15; // 각 프레임 0.15초
        if (m.animationTimer >= frameTime) {
          m.animationTimer = 0.0;
          m.currentFrame = (m.currentFrame + 1) % 4; // 4프레임 순환
        }
      }

      // 표시용 HP를 실제 HP로 부드럽게 감소 (롤 스타일)
      if (m.displayHp > m.hp) {
        m.displayHp -= dt * 100.0; // 초당 100 HP씩 감소
        if (m.displayHp < m.hp) {
          m.displayHp = m.hp.toDouble();
        }
      }

      // 속성 시스템: 상태이상 타이머 업데이트 (element-system.md)
      if (m.burnTimer > 0) {
        m.burnTimer -= dt;
        m.burnTickTimer -= dt;
        if (m.burnTickTimer <= 0) {
          m.burnTickTimer = 0.5; // 0.5초마다 틱
          final int burnDmg = max(1, (m.maxHp * 0.05).round());
          _damageMonster(m, burnDmg);
          if (i >= monsters.length) break; // 죽은 경우 중단
        }
      }
      if (m.freezeTimer > 0) m.freezeTimer -= dt;
      if (m.bindTimer > 0) m.bindTimer -= dt;
      if (m.shockTimer > 0) m.shockTimer -= dt;
      if (m.curseTimer > 0) m.curseTimer -= dt;

      // 리디자인: falling 로직 삭제, walking만 존재
      if (m.walking) {
        // 어그로 타겟 설정 (탱커 우선)
        _updateMonsterAggro(m);

        // 이동 목표: 어그로 타겟이 있으면 그쪽, 없으면 성 중심
        double targetX;
        double targetY;
        if (m.aggroTarget != null && characterUnits.contains(m.aggroTarget)) {
          targetX = m.aggroTarget!.pos.x;
          targetY = m.aggroTarget!.pos.y;
        } else {
          targetX = castleCenterX;
          targetY = castleCenterY;
        }

        final dx = targetX - m.pos.x;
        final dy = targetY - m.pos.y;
        final dist = sqrt(dx * dx + dy * dy);

        // 성에 도달 체크 (어그로 없을 때만, 2D 거리)
        if (m.aggroTarget == null && dist < castleContactRadius) {
          // 보스/미니보스: 지속 데미지
          if (m.type == MonsterType.boss || m.type == MonsterType.miniBoss) {
            m.attackingCastle = true;
            m.castleAttackTimer += dt;

            // 리디자인: 보스 1초마다 3데미지, 미니보스 1.5초마다 2데미지
            final attackInterval = m.type == MonsterType.boss ? 1.0 : 1.5;
            final damage = m.type == MonsterType.boss ? 3 : 2;

            if (m.castleAttackTimer >= attackInterval) {
              m.castleAttackTimer = 0.0;
              if (!_castleBarrierActive) { // 리디자인 B-2-20: 바리어 무적
                // R-08: 성 접촉 데미지 30% 감소, 최소 1
                final int reducedDmg = _hasAugment('R-08') ? max(1, (damage * 0.7).floor()) : damage;
                // L-03: 대지의 수호자 바리어 활성 시 50% 추가 감소
                final int actualDmg = _augmentL03BarrierActive ? max(1, (reducedDmg * 0.5).floor()) : reducedDmg;
                castleHp = max(0, castleHp - actualDmg);
                castleFlashTimer = 0.2; // D-3-1: 성 피격 점멸
                _onCastleDamaged();
              }
            }
            continue; // 성 공격 중에는 이동 안 함
          }

          // 일반 몬스터: 1데미지 후 소멸 (바리어 활성 시 무적)
          if (!_castleBarrierActive) { // 리디자인 B-2-20
            // R-08: 성 접촉 데미지 30% 감소 (1*0.7=0.7→절사=0)
            final int normalDmg = _hasAugment('R-08') ? (1 * 0.7).floor() : 1;
            // L-03: 대지의 수호자 바리어 활성 시 50% 추가 감소
            final int actualDmg = _augmentL03BarrierActive ? max(0, (normalDmg * 0.5).floor()) : normalDmg;
            if (actualDmg > 0) {
              castleHp = max(0, castleHp - actualDmg);
              castleFlashTimer = 0.2;
              _onCastleDamaged();
            }
          }
          _releaseMonster(monsters[i]); // B-3-2: 풀로 반환
          monsters.removeAt(i);
          escapedMonsters++;
          continue;
        } else {
          m.attackingCastle = false;
          m.castleAttackTimer = 0.0;
        }

        // 리디자인: 2D 직선 이동, 타입별 속도
        // 속성 시스템: 속박 중에는 이동 정지, 빙결 중에는 50% 감소
        if (m.bindTimer > 0) continue; // 속박: 완전 정지
        if (dist > 0) {
          double speed = m.type == MonsterType.boss
              ? CastleDefenseGame._bossSpeed
              : m.type == MonsterType.miniBoss
                  ? CastleDefenseGame._miniBossSpeed
                  : CastleDefenseGame._normalMonsterSpeed;
          if (m.freezeTimer > 0) speed *= 0.5; // 빙결: 이동속도 50% 감소
          m.pos.x += (dx / dist) * speed * dt;
          m.pos.y += (dy / dist) * speed * dt;
        }
      }
    }
  }

  // 몬스터 어그로 업데이트 (탱커에게 끌림)
  void _updateMonsterAggro(_Monster monster) {
    const double aggroRange = 200.0; // 어그로 범위 (전사가 더 넓게 어그로 끌기)

    // 가장 가까운 탱커 찾기
    _CharacterUnit? nearestTanker;
    double minDistance = double.infinity;

    for (final unit in characterUnits) {
      if (unit.definition.role == RoleType.tanker) {
        final distance = (unit.pos - monster.pos).length;
        if (distance < aggroRange && distance < minDistance) {
          minDistance = distance;
          nearestTanker = unit;
        }
      }
    }

    // 범위 내에 탱커가 있으면 어그로 설정, 없으면 해제
    if (nearestTanker != null) {
      monster.aggroTarget = nearestTanker;
    } else {
      monster.aggroTarget = null;
    }
  }

  // 리디자인: 4방향 스폰 (화면 외곽 20px 위치에서 랜덤 스폰)
  Vector2 _randomEdgeSpawnPos() {
    final side = _random.nextInt(4); // 0=위, 1=아래, 2=왼쪽, 3=오른쪽
    switch (side) {
      case 0: // 위
        return Vector2(_random.nextDouble() * size.x, -monsterRadius * 2);
      case 1: // 아래
        return Vector2(_random.nextDouble() * size.x, size.y + monsterRadius * 2);
      case 2: // 왼쪽
        return Vector2(-monsterRadius * 2, _random.nextDouble() * size.y);
      case 3: // 오른쪽
        return Vector2(size.x + monsterRadius * 2, _random.nextDouble() * size.y);
      default:
        return Vector2(_random.nextDouble() * size.x, -monsterRadius * 2);
    }
  }

  // B-3-2: 오브젝트 풀에서 몬스터 획득 (없으면 새로 생성)
  _Monster _acquireMonster({
    required Vector2 pos,
    required int hp,
    required int maxHp,
    required MonsterType type,
  }) {
    if (_monsterPool.isNotEmpty) {
      final m = _monsterPool.removeLast();
      m.pos.setFrom(pos);
      m.hp = hp;
      m.maxHp = maxHp;
      m.type = type;
      m.walking = true;
      m.damageFlashTimer = 0.0;
      m.displayHp = hp.toDouble();
      m.lastHitTime = 0.0;
      m.aggroTarget = null;
      m.attackingCastle = false;
      m.castleAttackTimer = 0.0;
      m.animationTimer = 0.0;
      m.currentFrame = 0;
      // 속성 시스템 리셋
      m.element = ElementType.none;
      m.burnTimer = 0.0; m.burnTickTimer = 0.0;
      m.freezeTimer = 0.0; m.bindTimer = 0.0;
      m.shockTimer = 0.0; m.curseTimer = 0.0;
      return m;
    }
    return _Monster(pos: pos, hp: hp, maxHp: maxHp, walking: true, type: type);
  }

  // B-3-2: 몬스터를 풀로 반환
  void _releaseMonster(_Monster m) {
    m.aggroTarget = null; // 참조 해제로 GC 도움
    _monsterPool.add(m);
  }

  void _spawnMonster() {
    if (size.x <= 0 || size.y <= 0) return;

    final cfg = kStageConfigs[stageLevel];
    if (cfg == null || currentRound < 1 || currentRound > cfg.rounds.length) {
      return;
    }

    final roundCfg = cfg.rounds[currentRound - 1];

    // 리디자인: 4방향 랜덤 스폰
    final spawnPos = _randomEdgeSpawnPos();

    // B-3-2: 오브젝트 풀에서 획득
    // 속성 시스템: 스테이지별 속성 80%, 무속성 20%
    final ElementType spawnElement = _random.nextDouble() < 0.8
        ? _getStageElement(stageLevel) : ElementType.none;
    final mon = _acquireMonster(
      pos: spawnPos,
      hp: monsterMaxHp,
      maxHp: monsterMaxHp,
      type: MonsterType.normal,
    );
    mon.element = spawnElement;
    monsters.add(mon);
    spawnedMonsters++;

    // 리디자인 B-2-17: 모든 일반 몬스터 스폰 후 보스/미니보스 스폰
    if (spawnedMonsters >= totalMonstersInRound) {
      if (!bossSpawned && roundCfg.monsterType == MonsterType.boss) {
        _spawnBoss(MonsterType.boss);
      } else if (miniBossesSpawned < roundCfg.miniBossCount) {
        _spawnBoss(MonsterType.miniBoss);
      }
    }
  }

  void _spawnBoss(MonsterType bossType) {
    if (size.x <= 0 || size.y <= 0) return;
    if (bossType == MonsterType.boss && bossSpawned) return;

    // 리디자인: 보스도 4방향 랜덤 스폰
    final spawnPos = _randomEdgeSpawnPos();

    // 보스 HP 결정
    int bossHp;
    if (bossType == MonsterType.boss) {
      bossHp = _getBossHp(stageLevel);
    } else {
      bossHp = _getMiniBossHp(stageLevel);
    }

    // B-3-2: 오브젝트 풀에서 획득
    // 속성 시스템: 보스/미니보스는 스테이지 속성 고정
    final ElementType bossElement = _getStageElement(stageLevel);
    final bossMonster = _acquireMonster(
      pos: spawnPos,
      hp: bossHp,
      maxHp: bossHp,
      type: bossType,
    );
    bossMonster.element = bossElement;
    monsters.add(bossMonster);

    if (bossType == MonsterType.boss) {
      bossSpawned = true;
    } else {
      miniBossesSpawned++;
    }
    totalMonstersInRound++;
  }

  void _killMonsterAtIndex(int index) {
    if (index < 0 || index >= monsters.length) return;
    final m = monsters[index];
    final dropPos = m.pos.clone();
    final mType = m.type;
    monsters.removeAt(index);
    _releaseMonster(m); // B-3-2: 풀로 반환
    defeatedMonsters++;

    // 리디자인 B-2-8: XP 젬 드롭
    final xpValue = mType == MonsterType.boss ? 50
        : mType == MonsterType.miniBoss ? 10 : 1;
    xpGems.add(_XpGem(pos: dropPos.clone(), xpValue: xpValue));
    // R-09: 소멸 시간 +15초
    if (_hasAugment('R-09') && xpGems.isNotEmpty) xpGems.last.lifeTimer += 15.0;

    // 골드 자동 회수: 드롭 없이 즉시 소지금에 가산
    final int baseGold = mType == MonsterType.boss ? 20
        : mType == MonsterType.miniBoss ? 5 : 1;
    final int goldValue = (_augmentGoldMultiplier * baseGold).round();
    playerGold += goldValue;
    _roundGoldGained += goldValue;

    // 리디자인 B-2-13: 스킬 게이지 충전 (R-06 증강: +50% 게이지)
    final double baseGauge = mType == MonsterType.boss ? 50.0
        : mType == MonsterType.miniBoss ? 15.0 : 3.0;
    final double gaugeIncrease = baseGauge * _augmentSkillGaugeMultiplier;
    skillGauge = min(100.0, skillGauge + gaugeIncrease);
    if (skillGauge >= 100.0) skillReady = true;
    // TODO: L-07 영혼의 연쇄 - 격파 시 크리티컬 예약 (타워 공격 판정에서 사용)
    // C-10: 여파 - 격파 시 주위 30px 스플래시 데미지
    if (_hasAugment('C-10')) {
      const double splashRadius = 30.0;
      final int splashDmg = max(1, _buffedMainAtkMultiplier.round());
      for (int j = monsters.length - 1; j >= 0; j--) {
        if ((dropPos - monsters[j].pos).length <= splashRadius) {
          _damageMonster(monsters[j], splashDmg);
        }
      }
    }
  }

  // 리디자인 B-2-10: 다음 레벨에 필요한 XP (10 + Level * 5)
  int _xpToNextLevel() => 10 + playerCharLevel * 5;

  // 리디자인 B-2-10: 레벨업 체크 및 처리
  void _checkLevelUp() {
    if (playerXp >= _xpToNextLevel()) {
      playerXp -= _xpToNextLevel();
      playerCharLevel++;
      // 리디자인 B-2-11: 레벨업 바프 카드 선택 화면으로 전환
      _generateBuffOptions();
      // R-10: 이단 축적 - 레벨업 시 XP 자석 2연속 발동 (2초)
      _xpMagnetTimer = _hasAugment('R-10') ? CastleDefenseGame._xpMagnetDuration * 2 : CastleDefenseGame._xpMagnetDuration;
      gameState = GameState.levelUp;
    }
  }

  // 리디자인 B-2-11: 바프 선택지 3장 생성 (P-2-1 추첨 로직)
  void _generateBuffOptions() {
    final allBuffs = BuffType.values.toList();
    // 최대 중복 제한에 걸린 바프 제외
    final maxCounts = {
      BuffType.attackUp: 5,
      BuffType.attackSpdUp: 5,
      BuffType.moveSpeedUp: 3,
      BuffType.rangeUp: 3,
      BuffType.castleRepair: 999,
      BuffType.towerPowerUp: 5,
      BuffType.xpMagnetUp: 3,
      BuffType.castleBarrier: 999,
      // 속성 시스템: 속성 부여 1회, 속성 마스터리 3회
      BuffType.elementFireGrant: 1,
      BuffType.elementWaterGrant: 1,
      BuffType.elementEarthGrant: 1,
      BuffType.elementElectricGrant: 1,
      BuffType.elementDarkGrant: 1,
      BuffType.elementMastery: 3,
    };
    // 속성 부여 바프: 다른 속성 부여도 1번만 → 현재 속성이 같으면 이미 취득으로 간주
    final bool hasFireGrant = _mainCharElement == ElementType.fire;
    final bool hasWaterGrant = _mainCharElement == ElementType.water;
    final bool hasEarthGrant = _mainCharElement == ElementType.earth;
    final bool hasElectricGrant = _mainCharElement == ElementType.electric;
    final bool hasDarkGrant = _mainCharElement == ElementType.dark;
    final currentCounts = {
      BuffType.attackUp: _atkUpCount,
      BuffType.attackSpdUp: _spdUpCount,
      BuffType.moveSpeedUp: _moveUpCount,
      BuffType.rangeUp: _rangeUpCount,
      BuffType.castleRepair: 0,
      BuffType.towerPowerUp: _towerUpCount,
      BuffType.xpMagnetUp: _magnetCount,
      BuffType.castleBarrier: 0,
      BuffType.elementFireGrant: hasFireGrant ? 1 : 0,
      BuffType.elementWaterGrant: hasWaterGrant ? 1 : 0,
      BuffType.elementEarthGrant: hasEarthGrant ? 1 : 0,
      BuffType.elementElectricGrant: hasElectricGrant ? 1 : 0,
      BuffType.elementDarkGrant: hasDarkGrant ? 1 : 0,
      BuffType.elementMastery: _elementMasteryCount,
    };

    // 중복 가능한 바프만 후보에 포함
    final candidates = allBuffs.where((b) =>
        (currentCounts[b] ?? 0) < (maxCounts[b] ?? 0)
    ).toList();

    // 후보가 3개 미만이면 무제한 바프를 강제 추가
    if (candidates.length < 3) {
      if (!candidates.contains(BuffType.castleRepair)) {
        candidates.add(BuffType.castleRepair);
      }
      if (candidates.length < 3 && !candidates.contains(BuffType.castleBarrier)) {
        candidates.add(BuffType.castleBarrier);
      }
    }

    // 직전 선택 바프를 50% 확률로 제외 (연속 방지)
    List<BuffType> weighted = [];
    for (final b in candidates) {
      weighted.add(b);
      if (b != _lastChosenBuff) weighted.add(b); // 2배 가중치
    }
    weighted.shuffle(_random);

    // 중복 없이 3개 선택
    final chosen = <BuffType>[];
    for (final b in weighted) {
      if (!chosen.contains(b)) chosen.add(b);
      if (chosen.length >= 3) break;
    }
    // 혹시 3개 미만이면 castleRepair로 채움
    while (chosen.length < 3) {
      chosen.add(BuffType.castleRepair);
    }
    _buffOptions = chosen;
  }

  // 리디자인 B-2-11: 바프 선택 적용
  void _applyBuff(BuffType buff) {
    // L-08: 영원의 계약 - 같은 효과 2회 이상 취득 시 +1스택 추가
    final bool l08Bonus = _hasAugment('L-08') && (_buffSelectionCount[buff] ?? 0) >= 1;
    _buffSelectionCount[buff] = (_buffSelectionCount[buff] ?? 0) + 1;
    switch (buff) {
      case BuffType.attackUp:
        if (_atkUpCount < 5) _atkUpCount++;
        if (l08Bonus && _atkUpCount < 5) _atkUpCount++; // L-08 보너스
        break;
      case BuffType.attackSpdUp:
        if (_spdUpCount < 5) _spdUpCount++;
        if (l08Bonus && _spdUpCount < 5) _spdUpCount++; // L-08 보너스
        break;
      case BuffType.moveSpeedUp:
        if (_moveUpCount < 3) _moveUpCount++;
        if (l08Bonus && _moveUpCount < 3) _moveUpCount++; // L-08 보너스
        break;
      case BuffType.rangeUp:
        if (_rangeUpCount < 3) _rangeUpCount++;
        if (l08Bonus && _rangeUpCount < 3) _rangeUpCount++; // L-08 보너스
        break;
      case BuffType.castleRepair:
        castleHp = min(castleMaxHp, castleHp + 20);
        break;
      case BuffType.towerPowerUp:
        if (_towerUpCount < 5) _towerUpCount++;
        if (l08Bonus && _towerUpCount < 5) _towerUpCount++; // L-08 보너스
        break;
      case BuffType.xpMagnetUp:
        if (_magnetCount < 3) _magnetCount++;
        if (l08Bonus && _magnetCount < 3) _magnetCount++; // L-08 보너스
        break;
      case BuffType.castleBarrier:
        _castleBarrierActive = true;
        _castleBarrierTimer = CastleDefenseGame._castleBarrierDuration;
        // D-3-7: 기존 배리어 VFX 제거 후 새 VFX 추가 (중복 방지)
        vfxEffects.removeWhere((v) => v.type == VfxType.barrier);
        vfxEffects.add(_VfxEffect(
          pos: Vector2(castleCenterX, castleCenterY),
          type: VfxType.barrier,
          duration: CastleDefenseGame._castleBarrierDuration,
          color: const Color(0x6600BCD4), // barrierCyan
          maxRadius: 70.0, // 타워 배치 범위와 동일
        ));
        break;
      // 속성 시스템: 속성 부여 바프 (element-system.md)
      case BuffType.elementFireGrant:
        _mainCharElement = ElementType.fire;
        break;
      case BuffType.elementWaterGrant:
        _mainCharElement = ElementType.water;
        break;
      case BuffType.elementEarthGrant:
        _mainCharElement = ElementType.earth;
        break;
      case BuffType.elementElectricGrant:
        _mainCharElement = ElementType.electric;
        break;
      case BuffType.elementDarkGrant:
        _mainCharElement = ElementType.dark;
        break;
      case BuffType.elementMastery:
        if (_elementMasteryCount < 3) _elementMasteryCount++;
        if (l08Bonus && _elementMasteryCount < 3) _elementMasteryCount++; // L-08 보너스
        break;
    }
    _lastChosenBuff = buff;
    _buffOptions = [];
    gameState = GameState.playing;
  }

  // 리디자인 B-2-11: 바프 적용 후 캐릭터 스탯 가져오기 (공격력 보정)
  double get _buffedMainAtkMultiplier => pow(1.15, _atkUpCount).toDouble();
  // L-04: 라운드 인터벌 중 이동속도 400%
  double get _buffedMoveSpeed {
    double speed = CastleDefenseGame._mainCharSpeed * pow(1.20, _moveUpCount).toDouble();
    if (_hasAugment('L-04') && gameState == GameState.roundClear) speed *= 4.0;
    return speed;
  }
  double get _buffedRangeMultiplier => pow(1.15, _rangeUpCount).toDouble();
  // 리디자인 B-2-16: 타워 공격력 배율 (바프 + 상점 영구 강화 + 증강 합산)
  double get _buffedTowerAtkMultiplier =>
      pow(1.10, _towerUpCount).toDouble() * pow(1.05, _shopTowerPowerCount).toDouble() *
      pow(1.15, _augmentR04Stacks).toDouble() * // R-04: 성 분노 스택당 +15%
      (_augmentL02Active ? 1.6 : 1.0); // L-02: 필살기 후 10초 타워 공격력 +60%
  // 리디자인 B-2-12: XP 자석 반경 (기본 20px + 스택당 +15px)
  double get _xpCollectRadius => 20.0 + 15.0 * _magnetCount;
  // C-08: 복활 대기시간 (기본 5초 → 3초), C-13: 복활 무적시간 (기본 2초 → 4초)
  double get _effectiveRespawnDuration => _hasAugment('C-08') ? 3.0 : 5.0;
  double get _effectiveInvincibleDuration => _hasAugment('C-13') ? 4.0 : 2.0;

  // 리디자인 B-2-14: 필살기 발동 (스킬 게이지 100% 시 전체 화면 999 데미지)
  void _fireUltimateSkill() {
    if (!skillReady) return;
    // D-3-5: 슬로우 모션 0.3초 발동
    _slowMotionTimer = 0.3;
    // D-3-5: 화면 중앙에서 충격파 VFX 추가
    final maxDim = max(size.x, size.y) * 0.75;
    vfxEffects.add(_VfxEffect(
      pos: Vector2(castleCenterX, castleCenterY),
      type: VfxType.shockwave,
      duration: 0.5,
      color: const Color(0xCCFFFFFF), // shockwaveWhite
      maxRadius: maxDim,
    ));
    // 모든 몬스터에게 999 데미지 (즉사)
    for (int i = monsters.length - 1; i >= 0; i--) {
      _killMonsterAtIndex(i);
    }
    skillGauge = 0.0;
    skillReady = false;
    // L-02: 왕의 포효 - 필살기 발동 후 10초 타워 공격력 +60%
    if (_hasAugment('L-02')) {
      _augmentL02Active = true;
      _augmentL02Timer = 10.0;
    }
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
  // 캐릭터 유닛 업데이트
  // -----------------------------
  void _updateCharacterUnits(double dt) {
    // 힐러 버프 계산 (모든 유닛에게 공격속도 10%, 이동속도 10% 증가)
    int healerCount = 0;
    for (final unit in characterUnits) {
      if (unit.definition.role == RoleType.priest) {
        healerCount++;
      }
    }
    final bool hasBuff = healerCount > 0;
    final double attackSpeedBuff = 1.0 + (healerCount * 0.1); // 힐러당 10%
    final double moveSpeedBuff = 1.0 + (healerCount * 0.1); // 힐러당 10%

    for (final unit in characterUnits) {
      // 버프 상태 업데이트 (시각 효과용)
      unit.hasAttackSpeedBuff = hasBuff;
      unit.hasMoveSpeedBuff = hasBuff;

      // 공격 쿨다운 감소 (힐러 버프 적용)
      if (unit.attackCooldown > 0) {
        unit.attackCooldown -= dt * attackSpeedBuff;
      }

      // 리디자인 B-1-7/B-1-8: 타워와 메인캐릭터의 타겟 우선도 분리
      if (unit.targetMonster == null || !monsters.contains(unit.targetMonster)) {
        if (unit.isTower) {
          // 타워: 성에 가장 가까운 적 우선 (B-1-8)
          unit.targetMonster = _findMonsterNearestToCastle();
        } else {
          // 메인 캐릭터: 자신에게 가장 가까운 적 우선 (B-1-8)
          unit.targetMonster = _findNearestMonster(unit.pos);
        }
        unit.movingTowardsTarget = false;
      }

      if (unit.targetMonster != null) {
        final target = unit.targetMonster!;
        final distance = (target.pos - unit.pos).length;

        // 리디자인 B-2-11: 바프 배율 계산 (메인=공격/사거리 바프, 타워=타워강화 바프)
        final double atkMult = unit.isTower
            ? _buffedTowerAtkMultiplier
            : _buffedMainAtkMultiplier;
        final double rangeMult = unit.isTower ? 1.0 : _buffedRangeMultiplier;

        // 역할에 따른 행동
        switch (unit.definition.role) {
          case RoleType.tanker:
            // 탱커: 근거리 공격 (1 데미지)
            _handleMeleeUnit(unit, target, distance, dt, 1.0 * atkMult, moveSpeedBuff);
            break;

          case RoleType.physicalDealer:
            // 물리딜러: 클래스에 따라 다른 공격 방식 (증가된 사거리 적용)
            if (unit.definition.classType == ClassType.archer) {
              // 궁수: 3발 동시 발사
              _handleArcherUnit(unit, target, distance, dt, 1.0 * atkMult, physicalDealerRange * rangeMult, moveSpeedBuff);
            } else if (unit.definition.classType == ClassType.gunslinger) {
              // 총잡이: 연속 발사 (두두두)
              _handleGunslingerUnit(unit, target, distance, dt, 1.0 * atkMult, physicalDealerRange * rangeMult, moveSpeedBuff);
            } else {
              _handleRangedUnit(unit, target, distance, dt, 1.0 * atkMult, physicalDealerRange * rangeMult, 3.0, moveSpeedBuff);
            }
            break;

          case RoleType.magicDealer:
            // 마법딜러: 스플래시 데미지
            _handleMagicUnit(unit, target, distance, dt, 1.0 * atkMult, rangedRange * 1.5 * rangeMult, moveSpeedBuff);
            break;

          case RoleType.priest:
            // 성직자: 원거리 공격 (1 데미지, 증가된 사거리, 느린 공격속도)
            _handleRangedUnit(unit, target, distance, dt, 1.0 * atkMult, priestRange * rangeMult, 1.5, moveSpeedBuff);
            break;

          case RoleType.utility:
            // 유틸리티: 원거리 투사물 공격
            _handleRangedUnit(unit, target, distance, dt, 1.0 * atkMult, rangedRange * rangeMult, 2.0, moveSpeedBuff);
            break;
        }

        // 전체 파티원: 스틱으로 함께 이동 (정사각형 포메이션)
        _applyMainCharacterMovement(unit, dt);
      }
    }
  }

  // 리디자인 B-2-5: 메인 캐릭터 스틱 이동
  void _applyMainCharacterMovement(_CharacterUnit unit, double dt) {
    if (!_stickActive) return;

    final dx = _stickKnobPos.x - _stickBasePos.x;
    final dy = _stickKnobPos.y - _stickBasePos.y;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist <= CastleDefenseGame._stickDeadzone) return;

    // 정규화된 방향으로 150px/s 이동
    unit.pos.x += (dx / dist) * _buffedMoveSpeed * dt; // 리디자인 B-2-11: 이동속도 바프 적용
    unit.pos.y += (dy / dist) * _buffedMoveSpeed * dt;

    // 화면 내 클램프
    unit.pos.x = unit.pos.x.clamp(characterUnitRadius, size.x - characterUnitRadius);
    unit.pos.y = unit.pos.y.clamp(characterUnitRadius, size.y - characterUnitRadius);
  }

  // 가장 가까운 몬스터 찾기 (메인 캐릭터용)
  _Monster? _findNearestMonster(Vector2 pos) {
    if (monsters.isEmpty) return null;

    _Monster? nearest;
    double minDist = double.infinity;

    for (final monster in monsters) {
      final dist = (monster.pos - pos).length;
      if (dist < minDist) {
        minDist = dist;
        nearest = monster;
      }
    }

    return nearest;
  }

  // 리디자인 B-1-8: 성에 가장 가까운 몬스터 찾기 (타워용)
  _Monster? _findMonsterNearestToCastle() {
    if (monsters.isEmpty) return null;

    _Monster? nearest;
    double minDist = double.infinity;

    for (final monster in monsters) {
      final dx = monster.pos.x - castleCenterX;
      final dy = monster.pos.y - castleCenterY;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < minDist) {
        minDist = dist;
        nearest = monster;
      }
    }

    return nearest;
  }

  // 리디자인 B-2-3: 성직자가 타워 슬롯에 있으면 5초마다 성 HP +3 회복
  void _updatePriestHeal(double dt) {
    bool hasPriestTower = false;
    for (final unit in characterUnits) {
      if (unit.isTower && unit.definition.role == RoleType.priest) {
        hasPriestTower = true;
        break;
      }
    }
    if (!hasPriestTower) {
      _priestHealTimer = 0.0;
      return;
    }
    _priestHealTimer += dt;
    if (_priestHealTimer >= CastleDefenseGame._priestHealInterval) {
      _priestHealTimer = 0.0;
      castleHp = min(castleMaxHp, castleHp + CastleDefenseGame._priestHealAmount);
    }
  }

  // 리디자인 B-2-6: 메인 캐릭터가 몬스터와 접촉 시 0.5초마다 1데미지
  void _updateMainCharacterDamage(double dt) {
    if (!_mainCharAlive) return;
    if (_invincibleTimer > 0) return; // B-2-7: 무적 중에는 피해 없음
    final mainUnit = characterUnits.where((u) => !u.isTower).firstOrNull;
    if (mainUnit == null) return;

    if (_mainCharDamageCooldown > 0) {
      _mainCharDamageCooldown -= dt;
    }
    if (_mainCharDamageCooldown > 0) return;

    for (final m in monsters) {
      final dist = (m.pos - mainUnit.pos).length;
      final hitRadius = monsterRadius + characterUnitRadius;
      if (dist <= hitRadius) {
        _mainCharDamageCooldown = 0.5;
        _mainCharHp -= 1;
        if (_mainCharHp <= 0) {
          // L-01: 불사의 서약 - 1회 HP=1 생존 + 3초 무적
          if (_hasAugment('L-01') && !_augmentL01Used) {
            _augmentL01Used = true;
            _mainCharHp = 1;
            _invincibleTimer = 3.0;
            break;
          }
          _mainCharHp = 0;
          _mainCharAlive = false;
          _stickActive = false; // 사망 시 스틱 비활성화
          // 메인 캐릭터 사망 = 즉시 게임 오버
          _onGameOver();
          return;
        }
        break;
      }
    }
  }

  // 리디자인 B-2-7: 메인 캐릭터 복활 처리
  void _updateMainCharacterRespawn(double dt) {
    // 무적 타이머 감소
    if (_invincibleTimer > 0) {
      _invincibleTimer -= dt;
      if (_invincibleTimer < 0) _invincibleTimer = 0.0;
    }

    if (!_mainCharRespawning) return;

    _respawnTimer -= dt;
    if (_respawnTimer <= 0) {
      // 복활: 성 오른쪽에 스폰, 최대 HP 회복, 2초 무적
      _mainCharAlive = true;
      _mainCharRespawning = false;
      _mainCharHp = _mainCharMaxHp;
      _invincibleTimer = _effectiveInvincibleDuration; // C-13: 동적 무적시간

      // 메인 유닛 위치를 성 옆으로 이동
      final mainUnit = characterUnits.where((u) => !u.isTower).firstOrNull;
      if (mainUnit != null) {
        mainUnit.pos = Vector2(castleCenterX + 60.0, castleCenterY);
      }
    }
  }

  // 리디자인 B-2-8/B-2-9: XP 젬 수명 감소 + 메인 캐릭터 회수
  void _updateXpGems(double dt) {
    final mainUnit = _mainCharAlive
        ? characterUnits.where((u) => !u.isTower).firstOrNull
        : null;
    final double collectRadius = _xpCollectRadius; // 리디자인 B-2-12: 자석 반경 포함

    for (int i = xpGems.length - 1; i >= 0; i--) {
      final gem = xpGems[i];
      gem.lifeTimer -= dt;

      // B-3-3: dist² 비교 (sqrt 없는 최적화)
      if (mainUnit != null) {
        final dx = gem.pos.x - mainUnit.pos.x;
        final dy = gem.pos.y - mainUnit.pos.y;
        if (dx * dx + dy * dy <= collectRadius * collectRadius) {
          // 리디자인 B-2-10: XP 가산 및 레벨업 체크
          playerXp += gem.xpValue;
          _roundXpGained += gem.xpValue; // D-1-6: 라운드 XP 추적
          _checkLevelUp();
          xpGems.removeAt(i);
          continue;
        }
      }

      // 수명 종료
      if (gem.isExpired) {
        xpGems.removeAt(i);
      }
    }
  }

  // 리디자인 B-2-15: 골드 드롭 회수 (메인 캐릭터 접촉)
  void _updateGoldDrops() {
    final mainUnit = _mainCharAlive
        ? characterUnits.where((u) => !u.isTower).firstOrNull
        : null;
    if (mainUnit == null) return;
    const double collectRadius = 24.0;

    // B-3-3: dist² 비교 (sqrt 없는 최적화)
    final double collectRadiusSq = collectRadius * collectRadius;
    for (int i = goldDrops.length - 1; i >= 0; i--) {
      final drop = goldDrops[i];
      final dx = drop.pos.x - mainUnit.pos.x;
      final dy = drop.pos.y - mainUnit.pos.y;
      if (dx * dx + dy * dy <= collectRadiusSq) {
        playerGold += drop.goldValue;
        _roundGoldGained += drop.goldValue; // D-1-6: 라운드 골드 추적
        goldDrops.removeAt(i);
      }
    }
  }

  // 리디자인 B-2-12: 레벨업 시 전체 XP 젬을 메인 캐릭터 쪽으로 끌어당김
  void _attractAllXpGems() {
    final mainUnit = _mainCharAlive
        ? characterUnits.where((u) => !u.isTower).firstOrNull
        : null;
    if (mainUnit == null) return;
    // 모든 젬을 즉시 수집
    for (int i = xpGems.length - 1; i >= 0; i--) {
      playerXp += xpGems[i].xpValue;
      xpGems.removeAt(i);
    }
  }

  // 근거리 유닛 처리 (전사: 범위 검 휘두르기)
  void _handleMeleeUnit(_CharacterUnit unit, _Monster target, double distance, double dt, double damage, double moveSpeedBuff) {
    final double swordRange = 60.0; // 검 휘두르기 범위
    final double swingDuration = 0.4; // 휘두르기 시간 (초)

    // 검 휘두르기 애니메이션 업데이트
    if (unit.isSwinging) {
      unit.swingProgress += dt / swingDuration;

      // 반시계방향으로 검 회전 (0도에서 -270도까지)
      unit.swordSwingAngle = -unit.swingProgress * 4.71239; // -270도 (라디안)

      // 휘두르기 진행 중 범위 내 모든 적에게 데미지
      if (unit.swingProgress >= 0.25 && unit.swingProgress < 0.75) {
        // 휘두르기 중간 지점에서 범위 내 모든 몬스터에게 데미지
        for (final monster in monsters) {
          final monsterDist = (monster.pos - unit.pos).length;
          if (monsterDist <= swordRange && monster.lastHitTime < unit.swingProgress - 0.1) {
            // 검이 지나가는 각도에 있는 몬스터만 타격
            final dx = monster.pos.x - unit.pos.x;
            final dy = monster.pos.y - unit.pos.y;
            final monsterAngle = atan2(dy, dx);

            // 현재 검 각도 범위 내에 있는지 확인
            final angleDiff = (monsterAngle - unit.swordSwingAngle).abs();
            if (angleDiff < 1.0 || angleDiff > 5.28) {
              // 약 60도 범위 또는 360도 넘어간 경우
              _damageMonster(monster, damage.toInt());
              monster.lastHitTime = unit.swingProgress;
            }
          }
        }
      }

      // 휘두르기 완료
      if (unit.swingProgress >= 1.0) {
        unit.isSwinging = false;
        unit.swingProgress = 0.0;
        unit.swordSwingAngle = 0.0;
        // 쿨다운 설정
        unit.attackCooldown = 1.0 / (unit.attackSpeed * 1.5);
      }
      return;
    }

    // 적을 향해 이동 (타워만 — 메인캐릭터는 스틱으로 조작)
    if (distance > swordRange * 0.7) {
      if (unit.isTower) {
        final dir = (target.pos - unit.pos).normalized();
        unit.pos += dir * unit.moveSpeed * moveSpeedBuff * dt;
        // 상단 경계 제한 적용
        unit.pos.y = unit.pos.y.clamp(topBoundary, size.y);
      }
      unit.movingTowardsTarget = unit.isTower;
    } else {
      // 사거리 내: 검 휘두르기 시작
      unit.movingTowardsTarget = false;
      if (unit.attackCooldown <= 0 && !unit.isSwinging) {
        unit.isSwinging = true;
        unit.swingProgress = 0.0;
        unit.swordSwingAngle = 0.0;
      }
    }
  }

  // 원거리 유닛 처리
  void _handleRangedUnit(
    _CharacterUnit unit,
    _Monster target,
    double distance,
    double dt,
    double damage,
    double attackRange,
    double attackSpeedMultiplier,
    double moveSpeedBuff,
  ) {
    if (distance > attackRange) {
      // 타겟까지 이동 (타워만 — 메인캐릭터는 스틱으로 조작)
      if (unit.isTower) {
        final dir = (target.pos - unit.pos).normalized();
        unit.pos += dir * unit.moveSpeed * moveSpeedBuff * dt;
        // 상단 경계 제한 적용
        unit.pos.y = unit.pos.y.clamp(topBoundary, size.y);
      }
      unit.movingTowardsTarget = unit.isTower;
    } else {
      // 사거리 내: 정지하고 공격
      unit.movingTowardsTarget = false;
      if (unit.attackCooldown <= 0) {
        // 투사물 발사
        _fireProjectile(unit, target, damage);
        // 쿨다운 설정 (역할별 공격속도 배율 적용)
        unit.attackCooldown = 1.0 / (unit.attackSpeed * attackSpeedMultiplier);
      }
    }
  }

  // 궁수 유닛 처리 (3발 동시 발사)
  void _handleArcherUnit(
    _CharacterUnit unit,
    _Monster target,
    double distance,
    double dt,
    double damage,
    double attackRange,
    double moveSpeedBuff,
  ) {
    if (distance > attackRange) {
      // 타워만 이동 (메인캐릭터는 스틱으로 조작)
      if (unit.isTower) {
        final dir = (target.pos - unit.pos).normalized();
        unit.pos += dir * unit.moveSpeed * moveSpeedBuff * dt;
        // 상단 경계 제한 적용
        unit.pos.y = unit.pos.y.clamp(topBoundary, size.y);
      }
      unit.movingTowardsTarget = unit.isTower;
    } else {
      unit.movingTowardsTarget = false;
      if (unit.attackCooldown <= 0) {
        // 3발 동시 발사 (부채꼴 모양)
        final baseDirection = (target.pos - unit.pos).normalized();
        const double spreadAngle = 0.25; // 약 15도

        for (int i = -1; i <= 1; i++) {
          final angle = atan2(baseDirection.y, baseDirection.x) + (i * spreadAngle);
          final direction = Vector2(cos(angle), sin(angle));
          final velocity = direction * projectileSpeed;

          projectiles.add(_Projectile(
            pos: Vector2(unit.pos.x, unit.pos.y),
            velocity: velocity,
            damage: damage,
            sourceRole: unit.definition.role,
            sourceClass: unit.definition.classType,
            targetMonster: i == 0 ? target : null, // 중앙 화살만 유도
          ));
        }
        unit.attackCooldown = 1.0 / (unit.attackSpeed * 2.0);
      }
    }
  }

  // 총잡이 유닛 처리 (연속 발사)
  void _handleGunslingerUnit(
    _CharacterUnit unit,
    _Monster target,
    double distance,
    double dt,
    double damage,
    double attackRange,
    double moveSpeedBuff,
  ) {
    // 연속 발사 처리
    if (unit.burstShotsRemaining > 0) {
      unit.burstTimer -= dt;
      if (unit.burstTimer <= 0) {
        // 연속 발사 중 한 발 발사
        _fireProjectile(unit, target, damage);
        unit.burstShotsRemaining--;
        unit.burstTimer = 0.08; // 0.08초 간격으로 발사
      }
      return;
    }

    if (distance > attackRange) {
      // 타워만 이동 (메인캐릭터는 스틱으로 조작)
      if (unit.isTower) {
        final dir = (target.pos - unit.pos).normalized();
        unit.pos += dir * unit.moveSpeed * moveSpeedBuff * dt;
        // 상단 경계 제한 적용
        unit.pos.y = unit.pos.y.clamp(topBoundary, size.y);
      }
      unit.movingTowardsTarget = unit.isTower;
    } else {
      unit.movingTowardsTarget = false;
      if (unit.attackCooldown <= 0) {
        // 연속 발사 시작 (5발)
        unit.burstShotsRemaining = 5;
        unit.burstTimer = 0.0;
        unit.attackCooldown = 1.0 / (unit.attackSpeed * 1.5);
      }
    }
  }

  // 마법사 유닛 처리 (스플래시 데미지)
  void _handleMagicUnit(
    _CharacterUnit unit,
    _Monster target,
    double distance,
    double dt,
    double damage,
    double attackRange,
    double moveSpeedBuff,
  ) {
    if (distance > attackRange) {
      // 타워만 이동 (메인캐릭터는 스틱으로 조작)
      if (unit.isTower) {
        final dir = (target.pos - unit.pos).normalized();
        unit.pos += dir * unit.moveSpeed * moveSpeedBuff * dt;
        // 상단 경계 제한 적용
        unit.pos.y = unit.pos.y.clamp(topBoundary, size.y);
      }
      unit.movingTowardsTarget = unit.isTower;
    } else {
      unit.movingTowardsTarget = false;
      if (unit.attackCooldown <= 0) {
        // 스플래시 마법 투사물 발사
        final direction = (target.pos - unit.pos).normalized();
        final velocity = direction * (projectileSpeed * 0.7); // 약간 느린 속도

        projectiles.add(_Projectile(
          pos: Vector2(unit.pos.x, unit.pos.y),
          velocity: velocity,
          damage: damage,
          sourceRole: unit.definition.role,
          sourceClass: unit.definition.classType,
          targetMonster: target,
          splashRadius: 50.0, // 스플래시 범위
          isMagic: true,
        ));
        unit.attackCooldown = 1.0 / (unit.attackSpeed * 1.5);
      }
    }
  }

  // 투사물 발사 (유도 미사일)
  void _fireProjectile(_CharacterUnit unit, _Monster target, double damage) {
    final direction = (target.pos - unit.pos).normalized();
    final velocity = direction * projectileSpeed;

    projectiles.add(_Projectile(
      pos: Vector2(unit.pos.x, unit.pos.y),
      velocity: velocity,
      damage: damage,
      sourceRole: unit.definition.role,
      sourceClass: unit.definition.classType,
      targetMonster: target, // 유도 미사일용 타겟 설정
    ));
  }

  // 몬스터에게 데미지 (플래시 효과 포함)
  // 속성 시스템: 스테이지별 기본 몬스터 속성 (element-system.md)
  ElementType _getStageElement(int stage) {
    switch (stage) {
      case 1: return ElementType.earth;    // 숲 고블린
      case 2: return ElementType.fire;     // 화산
      case 3: return ElementType.water;    // 해안/동굴
      case 4: return ElementType.electric; // 폭풍의 탑
      case 5: return ElementType.dark;     // 암흑성
      default: return ElementType.earth;
    }
  }

  // 속성 상성 배율 (element-system.md 상성표)
  double getElementMultiplier(ElementType attacker, ElementType defender) {
    if (attacker == ElementType.none || defender == ElementType.none) return 1.0;
    // 闇속성: 모든 속성에 x1.1 (대闇은 x1.0)
    if (attacker == ElementType.dark) {
      return defender == ElementType.dark ? 1.0 : 1.1;
    }
    // 상성 유리: x1.5
    if (attacker == ElementType.fire && defender == ElementType.earth) return 1.5;
    if (attacker == ElementType.water && defender == ElementType.fire) return 1.5;
    if (attacker == ElementType.earth && defender == ElementType.electric) return 1.5;
    if (attacker == ElementType.electric && defender == ElementType.water) return 1.5;
    // 상성 불리: x0.75
    if (attacker == ElementType.fire && defender == ElementType.water) return 0.75;
    if (attacker == ElementType.water && defender == ElementType.earth) return 0.75;
    if (attacker == ElementType.earth && defender == ElementType.fire) return 0.75;
    if (attacker == ElementType.electric && defender == ElementType.earth) return 0.75;
    // 闇속성을 공격받는 경우 x1.1
    if (defender == ElementType.dark) return 1.1;
    return 1.0;
  }

  void _damageMonster(_Monster monster, int damage) {
    monster.hp -= damage;
    monster.damageFlashTimer = 0.15; // 0.15초 동안 빨간색 점멸

    // 히트 스파크 VFX
    vfxEffects.add(_VfxEffect(
      pos: Vector2(monster.pos.x, monster.pos.y),
      type: VfxType.hit,
      duration: 0.2,
      color: const Color(0xFFFFFFFF),
    ));

    if (monster.hp <= 0) {
      // 죽음 파프 VFX
      Color deathColor;
      switch (monster.type) {
        case MonsterType.boss:
          deathColor = const Color(0xFFFF5252);
          break;
        case MonsterType.miniBoss:
          deathColor = const Color(0xFFFF9800);
          break;
        case MonsterType.normal:
        default:
          deathColor = const Color(0xFFFFEB3B);
          break;
      }
      vfxEffects.add(_VfxEffect(
        pos: Vector2(monster.pos.x, monster.pos.y),
        type: VfxType.death,
        duration: 0.4,
        color: deathColor,
      ));

      final index = monsters.indexOf(monster);
      if (index != -1) {
        _killMonsterAtIndex(index);
      }
    }
  }

  // 캐릭터-몬스터 충돌 체크 (뱀파이어 서바이버 스타일)
  void _checkCharacterMonsterCollisions() {
    const double collisionDamage = 1; // 충돌 데미지
    const double hitCooldown = 0.2; // 0.2초 쿨다운

    for (final unit in characterUnits) {
      for (final monster in monsters) {
        // B-3-3: sqrt 없이 dist² 비교 (성능 최적화)
        final dx = unit.pos.x - monster.pos.x;
        final dy = unit.pos.y - monster.pos.y;
        final distSq = dx * dx + dy * dy;
        final collisionRadius = characterUnitRadius + _getMonsterRadius(monster);
        final collisionRadiusSq = collisionRadius * collisionRadius;

        if (distSq < collisionRadiusSq) {
          // 충돌 발생! 쿨다운 체크
          if (gameTime - monster.lastHitTime >= hitCooldown) {
            // 데미지 적용
            _damageMonster(monster, collisionDamage.toInt());
            monster.lastHitTime = gameTime; // 마지막 피격 시간 갱신
          }
        }
      }
    }
  }

  // 몬스터 반지름 가져오기
  double _getMonsterRadius(_Monster monster) {
    switch (monster.type) {
      case MonsterType.boss:
        return monsterRadius * 2.0;
      case MonsterType.miniBoss:
        return monsterRadius * 1.5;
      case MonsterType.normal:
      default:
        return monsterRadius;
    }
  }

  // -----------------------------
  // 투사물 업데이트 (유도 미사일)
  // -----------------------------
  void _updateProjectiles(double dt) {
    for (int i = projectiles.length - 1; i >= 0; i--) {
      final proj = projectiles[i];

      // 타겟이 살아있으면 유도
      if (proj.targetMonster != null && monsters.contains(proj.targetMonster)) {
        final target = proj.targetMonster!;
        final direction = (target.pos - proj.pos).normalized();

        // 유도 미사일: 타겟 방향으로 속도 벡터 갱신 (부드러운 회전)
        final currentDir = proj.velocity.normalized();
        final targetDir = direction;

        // 회전 속도 (높을수록 빠르게 회전)
        const double turnSpeed = 8.0;
        final newDir = (currentDir + targetDir * turnSpeed * dt).normalized();
        proj.velocity = newDir * projectileSpeed;
      }

      // 잔상 위치 기록 (총잡이용)
      if (proj.sourceClass == ClassType.gunslinger) {
        proj.trail.insert(0, Vector2(proj.pos.x, proj.pos.y));
        if (proj.trail.length > 3) proj.trail.removeLast();
      }

      // 투사물 이동
      proj.pos += proj.velocity * dt;

      // 화면 밖으로 나가면 제거
      if (proj.pos.x < 0 || proj.pos.x > size.x || proj.pos.y < 0 || proj.pos.y > size.y) {
        projectiles.removeAt(i);
        continue;
      }

      // 몬스터와 충돌 체크
      bool hit = false;
      for (int j = monsters.length - 1; j >= 0; j--) {
        final monster = monsters[j];
        final dist = (proj.pos - monster.pos).length;

        // 몬스터 타입별 히트박스
        double hitRadius;
        switch (monster.type) {
          case MonsterType.boss:
            hitRadius = monsterRadius * 2.0;
            break;
          case MonsterType.miniBoss:
            hitRadius = monsterRadius * 1.5;
            break;
          case MonsterType.normal:
          default:
            hitRadius = monsterRadius;
            break;
        }

        // 충돌 판정을 더 관대하게 (히트박스 +8)
        if (dist <= hitRadius + 8.0) {
          // 스플래시 데미지 처리
          if (proj.isMagic && proj.splashRadius > 0) {
            // 마법 투사물: 범위 내 모든 몬스터에게 데미지
            for (final splashTarget in monsters) {
              final splashDist = (proj.pos - splashTarget.pos).length;
              if (splashDist <= proj.splashRadius) {
                _damageMonster(splashTarget, proj.damage.toInt());
              }
            }
          } else {
            // 일반 투사물: 단일 타겟 데미지
            _damageMonster(monster, proj.damage.toInt());
          }
          hit = true;
          break;
        }
      }

      if (hit) {
        projectiles.removeAt(i);
      }
    }
  }

  // VFX 이펙트 업데이트
  void _updateVfxEffects(double dt) {
    for (int i = vfxEffects.length - 1; i >= 0; i--) {
      vfxEffects[i].timer += dt;
      if (vfxEffects[i].isExpired) {
        vfxEffects.removeAt(i);
      }
    }
  }
}
