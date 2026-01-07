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
  final String instanceId; // 고유 ID (같은 캐릭터를 여러 개 가질 수 있음)
  final String characterId; // CharacterDefinition의 id
  int level;
  int exp;

  OwnedCharacter({
    required this.instanceId,
    required this.characterId,
    this.level = 1,
    this.exp = 0,
  });

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'characterId': characterId,
        'level': level,
        'exp': exp,
      };

  factory OwnedCharacter.fromJson(Map<String, dynamic> json) => OwnedCharacter(
        instanceId: json['instanceId'],
        characterId: json['characterId'],
        level: json['level'] ?? 1,
        exp: json['exp'] ?? 0,
      );
}
