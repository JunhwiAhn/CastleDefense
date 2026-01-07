// character_enums.dart

enum RoleType {
  tanker,
  physicalDealer,
  magicDealer,
  priest,
  utility,
}

enum ClassType {
  warrior,
  druid,
  vampire,
  archer,
  gunslinger,
  pyromancer,
  cryomancer,
  summoner,
  necromancer,
  crusader,
  priestClass,
  pastor,
  engineer,
  alchemist,
  trickster,
  assistant,
}

enum RankType { s, a, b, c }

enum SkillTargetType {
  self,
  singleEnemy,
  areaEnemy,
  allAllies,
  allEnemies,
}

enum DamageType {
  physical,
  magical,
  trueDamage,
  heal,
  buff,
  debuff,
}

extension RankTypeExtension on RankType {
  String get displayName {
    switch (this) {
      case RankType.s:
        return 'S';
      case RankType.a:
        return 'A';
      case RankType.b:
        return 'B';
      case RankType.c:
        return 'C';
    }
  }

  int get color {
    switch (this) {
      case RankType.s:
        return 0xFFFFD700; // 금색
      case RankType.a:
        return 0xFFC0C0C0; // 은색
      case RankType.b:
        return 0xFFCD7F32; // 동색
      case RankType.c:
        return 0xFF808080; // 회색
    }
  }

  double get summonRate {
    switch (this) {
      case RankType.s:
        return 0.03; // 3%
      case RankType.a:
        return 0.12; // 12%
      case RankType.b:
        return 0.35; // 35%
      case RankType.c:
        return 0.50; // 50%
    }
  }
}

extension RoleTypeExtension on RoleType {
  String get displayName {
    switch (this) {
      case RoleType.tanker:
        return '탱커';
      case RoleType.physicalDealer:
        return '물리딜러';
      case RoleType.magicDealer:
        return '마법딜러';
      case RoleType.priest:
        return '성직자';
      case RoleType.utility:
        return '유틸리티';
    }
  }

  String get emoji {
    switch (this) {
      case RoleType.tanker:
        return '🛡️';
      case RoleType.physicalDealer:
        return '⚔️';
      case RoleType.magicDealer:
        return '🔮';
      case RoleType.priest:
        return '✝️';
      case RoleType.utility:
        return '🛠️';
    }
  }
}
