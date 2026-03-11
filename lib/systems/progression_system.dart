// 진행 시스템: 라운드 클리어, 스테이지 클리어, 상점, 증강, 게임오버
part of '../castle_defense_game.dart';

extension ProgressionSystem on CastleDefenseGame {

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

    // D-1-6: 3초 라운드 클리어 연출 후 자동 진행
    gameState = GameState.roundClear;
    _roundClearTimer = 0.0;
  }

  void _onStageClear() {
    _lastStageClear = true;

    // 라운드 언락: 현재 라운드까지 클리어했으므로 다음 라운드 언락
    if (currentRound >= unlockedRoundMax && currentRound < totalRoundsInStage) {
      unlockedRoundMax = currentRound + 1;
    }

    // 리디자인 B-2-16: 스테이지 클리어 시 성 HP 자동 완전 회복 (무료)
    castleHp = castleMaxHp;

    // 상점 화면으로 전환 (Designer D-2-2에서 UI 구현)
    gameState = GameState.shopOpen;
  }

  // 리디자인 B-2-16: 상점 아이템 구매 로직
  bool _buyShopItem(ShopItemType item) {
    switch (item) {
      case ShopItemType.castleFullRepair:
        castleHp = castleMaxHp; // 무료
        return true;
      case ShopItemType.castleMaxHpUp:
        if (_shopCastleMaxHpCount >= 10) return false; // 상한 초과
        if (playerGold < 50) return false; // 골드 부족
        playerGold -= 50;
        _shopCastleMaxHpCount++;
        castleHp = min(castleMaxHp, castleHp + 20); // HP도 증가분 즉시 반영
        return true;
      case ShopItemType.towerPowerUp:
        if (_shopTowerPowerCount >= 10) return false;
        if (playerGold < 30) return false;
        playerGold -= 30;
        _shopTowerPowerCount++;
        return true;
      case ShopItemType.mainCharHpUp:
        if (_shopMainCharHpCount >= 5) return false;
        if (playerGold < 20) return false;
        playerGold -= 20;
        _shopMainCharHpCount++;
        // 현재 메인 캐릭터에 즉시 반영
        _mainCharHp = min(_mainCharMaxHp, _mainCharHp + 10);
        return true;
    }
  }

  // 상점에서 다음 스테이지로 진행
  void _leaveShop() {
    gameState = GameState.result;
  }

  // ===== 증강 시스템 (augment-system.md) =====

  // 라운드 클리어 시 증강 선택 트리거 (라운드 2/4/5)
  void _triggerAugmentSelection() {
    final tierProbs = {
      2: {AugmentTier.common: 0.60, AugmentTier.rare: 0.35, AugmentTier.legendary: 0.05},
      4: {AugmentTier.common: 0.25, AugmentTier.rare: 0.50, AugmentTier.legendary: 0.25},
      5: {AugmentTier.common: 0.10, AugmentTier.rare: 0.40, AugmentTier.legendary: 0.50},
    };
    final probs = tierProbs[currentRound];
    if (probs == null) return; // 라운드 2/4/5에서만 발동

    _augmentOptions = _generateAugmentChoices(probs);
    if (_augmentOptions.isNotEmpty) {
      gameState = GameState.augmentSelect;
    }
  }

  // 3개의 증강 선택지 생성 (취득 ID 제외, 티어 확률 기반)
  List<Augment> _generateAugmentChoices(Map<AugmentTier, double> tierProbs) {
    // 티어별 후보 풀 (이미 취득한 증강 제외)
    final Map<AugmentTier, List<Augment>> pool = {
      AugmentTier.common: kAllAugments.where((a) =>
          a.tier == AugmentTier.common && !_acquiredAugmentIds.contains(a.id)).toList(),
      AugmentTier.rare: kAllAugments.where((a) =>
          a.tier == AugmentTier.rare && !_acquiredAugmentIds.contains(a.id)).toList(),
      AugmentTier.legendary: kAllAugments.where((a) =>
          a.tier == AugmentTier.legendary && !_acquiredAugmentIds.contains(a.id)).toList(),
    };

    final chosen = <Augment>[];
    int attempts = 0;
    while (chosen.length < 3 && attempts < 50) {
      attempts++;
      // 랜덤 티어 추첨
      final roll = _random.nextDouble();
      AugmentTier tier;
      if (roll < (tierProbs[AugmentTier.legendary] ?? 0)) {
        tier = AugmentTier.legendary;
      } else if (roll < (tierProbs[AugmentTier.legendary] ?? 0) + (tierProbs[AugmentTier.rare] ?? 0)) {
        tier = AugmentTier.rare;
      } else {
        tier = AugmentTier.common;
      }

      final candidates = pool[tier]!;
      if (candidates.isEmpty) continue;

      // 중복 없는 선택
      final aug = candidates[_random.nextInt(candidates.length)];
      if (!chosen.contains(aug)) {
        chosen.add(aug);
      }
    }

    // 최소 1개 보장 (풀이 빈 경우)
    if (chosen.isEmpty) {
      final fallback = kAllAugments.where((a) => !_acquiredAugmentIds.contains(a.id)).toList();
      if (fallback.isNotEmpty) chosen.add(fallback[_random.nextInt(fallback.length)]);
    }
    return chosen;
  }

  // 증강 선택 적용
  void _applyAugment(Augment augment) {
    activeAugments.add(augment);
    _acquiredAugmentIds.add(augment.id);
    _augmentOptions = [];

    switch (augment.id) {
      // Common
      case 'C-01': // 메인 최대 HP +15
        _shopMainCharHpCount = ((_shopMainCharHpCount * 10 + 15) / 10).ceil().clamp(0, 99);
        break;
      case 'C-02': // 메인 이동속도 +25%
        _moveUpCount = (_moveUpCount + 1).clamp(0, 99); // 이동속도 버프와 별도로 처리 (근사치)
        break;
      case 'C-03': // 메인 공격력 +20%
        _atkUpCount = (_atkUpCount + 1).clamp(0, 99);
        break;
      case 'C-04': // 메인 공격속도 +20%
        _spdUpCount = (_spdUpCount + 1).clamp(0, 99);
        break;
      case 'C-05': // 성 최대 HP +25 + 즉시 회복
        _shopCastleMaxHpCount = ((_shopCastleMaxHpCount * 20 + 25) / 20).ceil().clamp(0, 99);
        castleHp = min(castleMaxHp, castleHp + 25);
        break;
      case 'C-06': // 전 타워 공격속도 +20% (속도 버프 근사)
        _towerUpCount = (_towerUpCount + 1).clamp(0, 99);
        break;
      case 'C-07': // XP 회수 반경 +30px
        _magnetCount = (_magnetCount + 2).clamp(0, 99); // +15px × 2 = +30px 근사
        break;
      case 'C-08': // 복활 카운트다운 -2초 (플래그로 처리)
        // _revivalDuration에서 사용 (별도 처리)
        break;
      case 'C-09': // 골드 획득량 +30%
        // _goldMultiplier에서 사용 (별도 처리)
        break;
      case 'C-10': // 격파 시 스플래시 (이미 별도 로직으로 처리)
        break;
      case 'C-11': // 라운드 시작 시 성 HP +5 (라운드 로드 시 적용)
        break;
      case 'C-12': // 전 타워 사거리 +20%
        _rangeUpCount = (_rangeUpCount + 1).clamp(0, 99);
        break;
      case 'C-13': // 복활 무적 +2초 (플래그)
        break;
      case 'C-14': // 속성 마스터리 +10%
        _elementMasteryCount = (_elementMasteryCount + 1).clamp(0, 10);
        break;
      // Rare
      case 'R-06': // 스킬 게이지 축적량 +50%
        break; // 게이지 증가 시 배율 적용 (별도 처리)
      case 'R-12': // 성 HP 50 이하 시 1회 바리어 발동
        _augmentR12Used = false; // 발동 가능 상태로 리셋
        break;
      // Legendary
      case 'L-01': _augmentL01Used = false; break;
      case 'L-03': _augmentL03Used = false; break;
      default: break;
    }

    // 증강 선택 후 게임 재개
    gameState = GameState.playing;
  }

  // 증강 보유 여부 확인 (ID로 조회)
  bool _hasAugment(String id) => _acquiredAugmentIds.contains(id);

  // 증강 시스템: 성이 데미지를 받은 후 트리거 (R-04/R-12/L-03)
  void _onCastleDamaged() {
    // R-04: 성의 분노 - 피격 시 스택 추가 (최대 3), 5초 타이머 리셋
    if (_hasAugment('R-04')) {
      _augmentR04Stacks = min(3, _augmentR04Stacks + 1);
      _augmentR04Timer = 5.0;
    }
    // R-12: 성 HP 50 이하 시 1회 바리어 자동 발동 (10초)
    if (_hasAugment('R-12') && !_augmentR12Used && castleHp <= 50) {
      _augmentR12Used = true;
      _castleBarrierActive = true;
      _castleBarrierTimer = 10.0;
    }
    // L-03: 성 HP 최대값 30% 이하 시 1회 60초 바리어 발동 (데미지 50% 감소)
    if (_hasAugment('L-03') && !_augmentL03Used && castleHp <= castleMaxHp * 0.3) {
      _augmentL03Used = true;
      _augmentL03BarrierActive = true;
      _augmentL03BarrierTimer = 60.0;
    }
  }

  // 증강 효과 배율 계산 (복수 증강 반영)
  double get _augmentGoldMultiplier =>
      _hasAugment('C-09') ? 1.3 : 1.0; // 골드 획득량 +30%

  double get _augmentSkillGaugeMultiplier =>
      _hasAugment('R-06') ? 1.5 : 1.0; // 스킬 게이지 +50%

  // 상점 아이템 가격 조회
  int shopItemPrice(ShopItemType item) {
    switch (item) {
      case ShopItemType.castleFullRepair: return 0;
      case ShopItemType.castleMaxHpUp: return 50;
      case ShopItemType.towerPowerUp: return 30;
      case ShopItemType.mainCharHpUp: return 20;
    }
  }

  // 상점 아이템 구매 가능 여부
  bool canBuyShopItem(ShopItemType item) {
    switch (item) {
      case ShopItemType.castleFullRepair: return true;
      case ShopItemType.castleMaxHpUp:
        return _shopCastleMaxHpCount < 10 && playerGold >= 50;
      case ShopItemType.towerPowerUp:
        return _shopTowerPowerCount < 10 && playerGold >= 30;
      case ShopItemType.mainCharHpUp:
        return _shopMainCharHpCount < 5 && playerGold >= 20;
    }
  }

  void _onGameOver() {
    if (gameState != GameState.playing) return;

    _lastStageClear = false;

    gameState = GameState.result;
  }

  void _onTimeOver() {
    if (gameState != GameState.playing) return;

    _lastStageClear = false;

    gameState = GameState.result;
  }
}
