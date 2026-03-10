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

// 속성 시스템 (element-system.md 참조)
enum ElementType {
  fire,     // 화염
  water,    // 수빙
  earth,    // 대지
  electric, // 번개
  dark,     // 암흑
  none,     // 무속성
}

extension ElementTypeExtension on ElementType {
  // 표시 색상 (0xAARRGGBB)
  int get color {
    switch (this) {
      case ElementType.fire: return 0xFFF44336;
      case ElementType.water: return 0xFF2196F3;
      case ElementType.earth: return 0xFF8BC34A;
      case ElementType.electric: return 0xFFFFD700;
      case ElementType.dark: return 0xFF9C27B0;
      case ElementType.none: return 0xFF9E9E9E;
    }
  }

  String get emoji {
    switch (this) {
      case ElementType.fire: return '🔥';
      case ElementType.water: return '💧';
      case ElementType.earth: return '🌿';
      case ElementType.electric: return '⚡';
      case ElementType.dark: return '🌑';
      case ElementType.none: return '';
    }
  }
}

extension ClassTypeElementExtension on ClassType {
  // ClassType → 기본 속성 매핑 (element-system.md 기준)
  ElementType get defaultElement {
    switch (this) {
      case ClassType.pyromancer: return ElementType.fire;
      case ClassType.cryomancer: return ElementType.water;
      case ClassType.druid: return ElementType.earth;
      case ClassType.alchemist: return ElementType.earth;
      case ClassType.engineer: return ElementType.electric;
      case ClassType.trickster: return ElementType.electric;
      case ClassType.necromancer: return ElementType.dark;
      case ClassType.summoner: return ElementType.dark;
      case ClassType.vampire: return ElementType.dark;
      default: return ElementType.none;
    }
  }
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
