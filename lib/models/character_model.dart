// character_model.dart

import 'character_enums.dart';

class CharacterBaseStats {
  final double maxHp;
  final double attack;
  final double defense;
  final double attackSpeed; // 초당 공격 횟수
  final double moveSpeed;

  const CharacterBaseStats({
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.attackSpeed,
    required this.moveSpeed,
  });
}

class CharacterDefinition {
  final String id;
  final String name;
  final RoleType role;
  final ClassType classType;
  final RankType rank;
  final CharacterBaseStats baseStats;
  final String skillId;
  final String description;
  // 속성 시스템: ClassType 기본 속성 자동 할당
  ElementType get element => classType.defaultElement;

  const CharacterDefinition({
    required this.id,
    required this.name,
    required this.role,
    required this.classType,
    required this.rank,
    required this.baseStats,
    required this.skillId,
    required this.description,
  });
}

// 플레이어가 보유한 캐릭터 인스턴스
class OwnedCharacter {
  final String instanceId; // 고유 ID
  final String characterId; // CharacterDefinition의 id
  int level;
  int exp;
  int cardLevel;       // 카드 강화 레벨 (1~5)
  int duplicateCount;  // 중복 획득 횟수 (강화 재료)

  OwnedCharacter({
    required this.instanceId,
    required this.characterId,
    this.level = 1,
    this.exp = 0,
    this.cardLevel = 1,
    this.duplicateCount = 0,
  });

  // 카드 레벨별 필요 별조각
  static const List<int> kStarShardsRequired = [0, 10, 25, 50, 100];
  // 카드 레벨별 필요 중복본
  static const List<int> kDuplicatesRequired = [0, 1, 2, 3, 5];

  bool canUpgradeCard(int playerStarShards) {
    if (cardLevel >= 5) return false;
    final needShards = kStarShardsRequired[cardLevel];
    final needDupes = kDuplicatesRequired[cardLevel];
    return playerStarShards >= needShards && duplicateCount >= needDupes;
  }

  // 카드 레벨 보정치 (0.0 ~ 0.16)
  double get cardLevelBonus => (cardLevel - 1) * 0.04;

  Map<String, dynamic> toJson() => {
    'instanceId': instanceId,
    'characterId': characterId,
    'level': level,
    'exp': exp,
    'cardLevel': cardLevel,
    'duplicateCount': duplicateCount,
  };

  factory OwnedCharacter.fromJson(Map<String, dynamic> json) => OwnedCharacter(
    instanceId: json['instanceId'],
    characterId: json['characterId'],
    level: json['level'] ?? 1,
    exp: json['exp'] ?? 0,
    cardLevel: json['cardLevel'] ?? 1,
    duplicateCount: json['duplicateCount'] ?? 0,
  );
}
