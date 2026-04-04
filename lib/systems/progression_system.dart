// 진행 시스템: 카드 업그레이드, 컬렉션 관련 로직
part of '../castle_defense_game.dart';

extension ProgressionSystem on CastleDefenseGame {

  // ─── 카드 업그레이드 ─────────────────────────
  // 반환값: 성공 여부
  bool upgradeCard(String characterId) {
    // 같은 characterId를 가진 카드 중 cardLevel이 가장 낮은 것을 선택
    OwnedCharacter? target;
    for (final c in ownedCharacters) {
      if (c.characterId != characterId) continue;
      if (c.cardLevel >= 5) continue;
      if (target == null || c.cardLevel < target.cardLevel) target = c;
    }
    if (target == null) return false;

    final needShards = OwnedCharacter.kStarShardsRequired[target.cardLevel];
    final needDupes  = OwnedCharacter.kDuplicatesRequired[target.cardLevel];

    if (playerStarShards < needShards) return false;
    if (target.duplicateCount < needDupes) return false;

    playerStarShards -= needShards;
    target.duplicateCount -= needDupes;
    target.cardLevel++;
    return true;
  }

  // ─── 중복본 구매 (별조각 → 중복본) ─────────
  // 등급별 비용: C=30, B=60, A=90, S=120
  bool buyDuplicate(String characterId) {
    final def = CharacterDefinitions.byId(characterId);
    final cost = switch (def.rank) {
      RankType.s => 120,
      RankType.a =>  90,
      RankType.b =>  60,
      _          =>  30,
    };
    if (playerStarShards < cost) return false;

    // 해당 캐릭터가 있어야 구매 가능
    final owned = ownedCharacters.where((c) => c.characterId == characterId).toList();
    if (owned.isEmpty) return false;

    playerStarShards -= cost;
    // 카드 레벨이 가장 낮은 인스턴스에 중복본 추가
    owned.sort((a, b) => a.cardLevel.compareTo(b.cardLevel));
    owned.first.duplicateCount++;
    return true;
  }

  // ─── 가챠 결과 처리 ──────────────────────────
  // 이미 보유한 캐릭터면 duplicateCount 증가, 없으면 신규 해금
  void _processGachaResult(CharacterDefinition def) {
    final existing = ownedCharacters.where((c) => c.characterId == def.id).toList();
    if (existing.isNotEmpty) {
      // 중복: duplicateCount +1 (카드 레벨 최저 인스턴스에)
      existing.sort((a, b) => a.cardLevel.compareTo(b.cardLevel));
      existing.first.duplicateCount++;
    } else {
      // 신규 해금
      final instanceId = '${def.id}_${DateTime.now().millisecondsSinceEpoch}';
      ownedCharacters.add(OwnedCharacter(
        instanceId: instanceId,
        characterId: def.id,
      ));
    }
  }

  // ─── 스테이지 완료 보상 표시용 데이터 ────────
  String getStageRewardSummary() {
    final cfg = kStageConfigs[stageLevel];
    if (cfg == null) return '';
    final buf = StringBuffer();
    buf.write('⭐ +${cfg.starShardOnStageClear}');
    buf.write('  💎 +${cfg.gemOnStageClear}');
    if (_perfectClearSoFar) buf.write('  (무피해 +⭐5 +💎3)');
    if (!_clearedStages.contains(stageLevel)) buf.write('  (첫 클리어 보너스!)');
    return buf.toString();
  }

  // ─── 보유 캐릭터 카드 정보 조회 ──────────────
  OwnedCharacter? getOwnedCard(String characterId) {
    try {
      return ownedCharacters.firstWhere((c) => c.characterId == characterId);
    } catch (_) {
      return null;
    }
  }

  // ─── 타워에 캐릭터 배치 가능 여부 ────────────
  // 해당 타입에 맞는 해금 캐릭터가 1명 이상 있어야 배치 가능
  bool canPlaceTowerType(TowerType type) {
    if (ownedCharacters.isEmpty) return true; // 캐릭터 없어도 기본 타워 배치 가능
    return true; // 기본 타워는 항상 배치 가능, 캐릭터 선택은 선택 사항
  }

  // ─── 특정 타워 타입에 맞는 해금 캐릭터 목록 ──
  List<OwnedCharacter> getCharactersForTowerType(TowerType type) {
    // 역할 매핑: archer/cannon/mage/sniper → 역할 타입
    final roles = switch (type) {
      TowerType.archer => [RoleType.physicalDealer, RoleType.utility],
      TowerType.cannon => [RoleType.tanker, RoleType.physicalDealer],
      TowerType.mage   => [RoleType.magicDealer, RoleType.priest],
      TowerType.sniper => [RoleType.physicalDealer, RoleType.utility],
    };

    // 중복 제거 (characterId 기준 유일한 목록)
    final seen = <String>{};
    final result = <OwnedCharacter>[];
    for (final c in ownedCharacters) {
      if (seen.contains(c.characterId)) continue;
      final def = CharacterDefinitions.byId(c.characterId);
      if (roles.contains(def.role)) {
        seen.add(c.characterId);
        result.add(c);
      }
    }
    return result;
  }
}
