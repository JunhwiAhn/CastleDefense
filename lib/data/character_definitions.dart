// character_definitions.dart

import '../models/character_model.dart';
import '../models/character_enums.dart';

class CharacterDefinitions {
  static final List<CharacterDefinition> all = [
    // ========== S 랭크 ==========
    // 🛡 S 탱커 - 강철의 수호자 바르그 (전사)
    CharacterDefinition(
      id: 'tank_s_varg',
      name: '강철의 수호자 바르그',
      role: RoleType.tanker,
      classType: ClassType.warrior,
      rank: RankType.s,
      baseStats: const CharacterBaseStats(
        maxHp: 5000,
        attack: 150,
        defense: 250,
        attackSpeed: 0.8,
        moveSpeed: 120,
      ),
      skillId: 'skill_iron_fortress',
      description: '방어력과 체력이 매우 높은 최전선 수호자',
    ),

    // 🩸 S 탱커 - 뱀파이어 로드 블라디미르 (흡혈귀)
    CharacterDefinition(
      id: 'tank_s_vladimir',
      name: '불멸의 블라디미르',
      role: RoleType.tanker,
      classType: ClassType.vampire,
      rank: RankType.s,
      baseStats: const CharacterBaseStats(
        maxHp: 4200,
        attack: 190,
        defense: 180,
        attackSpeed: 1.0,
        moveSpeed: 85,
      ),
      skillId: 'skill_blood_pact',
      description: '흡혈로 생존력을 극대화하는 불멸의 전사',
    ),

    // ⚔️ S 물리딜러 - 궁수 아르테미스 (궁수)
    CharacterDefinition(
      id: 'pdeal_s_artemis',
      name: '바람의 사냥꾼 아르테미스',
      role: RoleType.physicalDealer,
      classType: ClassType.archer,
      rank: RankType.s,
      baseStats: const CharacterBaseStats(
        maxHp: 2800,
        attack: 380,
        defense: 90,
        attackSpeed: 1.5,
        moveSpeed: 95,
      ),
      skillId: 'skill_arrow_rain',
      description: '빠른 공격 속도로 적을 압도하는 궁수',
    ),

    // 🔫 S 물리딜러 - 건슬링어 카산드라 (총잡이)
    CharacterDefinition(
      id: 'pdeal_s_cassandra',
      name: '질풍의 총잡이 카산드라',
      role: RoleType.physicalDealer,
      classType: ClassType.gunslinger,
      rank: RankType.s,
      baseStats: const CharacterBaseStats(
        maxHp: 2600,
        attack: 400,
        defense: 85,
        attackSpeed: 1.8,
        moveSpeed: 100,
      ),
      skillId: 'skill_bullet_storm',
      description: '연속 사격으로 적을 제압하는 총잡이',
    ),

    // 🔥 S 마법딜러 - 화염 군주 이그니스 (불법사)
    CharacterDefinition(
      id: 'mdeal_s_ignis',
      name: '화염 군주 이그니스',
      role: RoleType.magicDealer,
      classType: ClassType.pyromancer,
      rank: RankType.s,
      baseStats: const CharacterBaseStats(
        maxHp: 2600,
        attack: 420,
        defense: 80,
        attackSpeed: 0.7,
        moveSpeed: 70,
      ),
      skillId: 'skill_meteor_buster',
      description: '강력한 화염 마법으로 적을 소각하는 마법사',
    ),

    // ❄️ S 마법딜러 - 얼음 마녀 프로스티아 (빙법사)
    CharacterDefinition(
      id: 'mdeal_s_frostia',
      name: '극한의 얼음마녀 프로스티아',
      role: RoleType.magicDealer,
      classType: ClassType.cryomancer,
      rank: RankType.s,
      baseStats: const CharacterBaseStats(
        maxHp: 2700,
        attack: 390,
        defense: 95,
        attackSpeed: 0.8,
        moveSpeed: 75,
      ),
      skillId: 'skill_ice_prison',
      description: '적을 얼려 무력화시키는 빙결의 마법사',
    ),

    // ✝ S 성직자 - 크루세이더 아르테르
    CharacterDefinition(
      id: 'priest_s_arter',
      name: '성전의 불꽃 아르테르',
      role: RoleType.priest,
      classType: ClassType.crusader,
      rank: RankType.s,
      baseStats: const CharacterBaseStats(
        maxHp: 3200,
        attack: 210,
        defense: 160,
        attackSpeed: 1.0,
        moveSpeed: 85,
      ),
      skillId: 'skill_holy_judgment',
      description: '아군을 강화하고 언데드를 심판하는 성전사',
    ),

    // 🛠 S 유틸 - 엔지니어 오르빗
    CharacterDefinition(
      id: 'util_s_orbit',
      name: '기계 공학자 오르빗',
      role: RoleType.utility,
      classType: ClassType.engineer,
      rank: RankType.s,
      baseStats: const CharacterBaseStats(
        maxHp: 2800,
        attack: 180,
        defense: 120,
        attackSpeed: 0.9,
        moveSpeed: 75,
      ),
      skillId: 'skill_auto_turret',
      description: '자동 포탑으로 지속적인 화력을 제공하는 엔지니어',
    ),

    // ========== A 랭크 ==========
    // 🛡 A 탱커 - 전사 레오나르드
    CharacterDefinition(
      id: 'tank_a_leonard',
      name: '강철 방패 레오나르드',
      role: RoleType.tanker,
      classType: ClassType.warrior,
      rank: RankType.a,
      baseStats: const CharacterBaseStats(
        maxHp: 3800,
        attack: 120,
        defense: 200,
        attackSpeed: 0.8,
        moveSpeed: 110,
      ),
      skillId: 'skill_shield_bash',
      description: '견고한 방어로 아군을 지키는 전사',
    ),

    // ⚔️ A 물리딜러 - 궁수 로빈
    CharacterDefinition(
      id: 'pdeal_a_robin',
      name: '의적 로빈',
      role: RoleType.physicalDealer,
      classType: ClassType.archer,
      rank: RankType.a,
      baseStats: const CharacterBaseStats(
        maxHp: 2200,
        attack: 280,
        defense: 70,
        attackSpeed: 1.3,
        moveSpeed: 90,
      ),
      skillId: 'skill_multishot',
      description: '정확한 화살로 적을 관통하는 궁수',
    ),

    // 🔥 A 마법딜러 - 불법사 파이로
    CharacterDefinition(
      id: 'mdeal_a_pyro',
      name: '화염술사 파이로',
      role: RoleType.magicDealer,
      classType: ClassType.pyromancer,
      rank: RankType.a,
      baseStats: const CharacterBaseStats(
        maxHp: 2000,
        attack: 310,
        defense: 60,
        attackSpeed: 0.7,
        moveSpeed: 65,
      ),
      skillId: 'skill_fireball',
      description: '불꽃으로 적을 태우는 화염 마법사',
    ),

    // ✝ A 성직자 - 프리스트 힐다
    CharacterDefinition(
      id: 'priest_a_hilda',
      name: '치유의 성녀 힐다',
      role: RoleType.priest,
      classType: ClassType.priestClass,
      rank: RankType.a,
      baseStats: const CharacterBaseStats(
        maxHp: 2500,
        attack: 150,
        defense: 120,
        attackSpeed: 0.9,
        moveSpeed: 80,
      ),
      skillId: 'skill_holy_heal',
      description: '강력한 치유로 아군을 회복시키는 성직자',
    ),

    // ========== B 랭크 ==========
    // 🛡 B 탱커 - 전사 브루투스
    CharacterDefinition(
      id: 'tank_b_brutus',
      name: '철벽 브루투스',
      role: RoleType.tanker,
      classType: ClassType.warrior,
      rank: RankType.b,
      baseStats: const CharacterBaseStats(
        maxHp: 2800,
        attack: 90,
        defense: 150,
        attackSpeed: 0.7,
        moveSpeed: 100,
      ),
      skillId: 'skill_taunt',
      description: '단단한 방어로 전선을 지키는 전사',
    ),

    // ⚔️ B 물리딜러 - 궁수 엘라
    CharacterDefinition(
      id: 'pdeal_b_ella',
      name: '숲의 엘라',
      role: RoleType.physicalDealer,
      classType: ClassType.archer,
      rank: RankType.b,
      baseStats: const CharacterBaseStats(
        maxHp: 1800,
        attack: 200,
        defense: 50,
        attackSpeed: 1.2,
        moveSpeed: 85,
      ),
      skillId: 'skill_aimed_shot',
      description: '날렵한 움직임으로 적을 공격하는 궁수',
    ),

    // 🔥 B 마법딜러 - 불법사 플레임
    CharacterDefinition(
      id: 'mdeal_b_flame',
      name: '견습 화염사 플레임',
      role: RoleType.magicDealer,
      classType: ClassType.pyromancer,
      rank: RankType.b,
      baseStats: const CharacterBaseStats(
        maxHp: 1600,
        attack: 220,
        defense: 45,
        attackSpeed: 0.6,
        moveSpeed: 60,
      ),
      skillId: 'skill_fire_blast',
      description: '화염 마법을 연마 중인 견습 마법사',
    ),

    // ========== C 랭크 ==========
    // 🛡 C 탱커 - 전사 가드
    CharacterDefinition(
      id: 'tank_c_guard',
      name: '신참 가드',
      role: RoleType.tanker,
      classType: ClassType.warrior,
      rank: RankType.c,
      baseStats: const CharacterBaseStats(
        maxHp: 2000,
        attack: 60,
        defense: 100,
        attackSpeed: 0.6,
        moveSpeed: 90,
      ),
      skillId: 'skill_basic_shield',
      description: '기본적인 방어 기술을 가진 신참 전사',
    ),

    // ⚔️ C 물리딜러 - 궁수 루키
    CharacterDefinition(
      id: 'pdeal_c_rookie',
      name: '신참 루키',
      role: RoleType.physicalDealer,
      classType: ClassType.archer,
      rank: RankType.c,
      baseStats: const CharacterBaseStats(
        maxHp: 1400,
        attack: 140,
        defense: 35,
        attackSpeed: 1.0,
        moveSpeed: 80,
      ),
      skillId: 'skill_basic_shot',
      description: '활을 배우기 시작한 신참 궁수',
    ),
  ];

  static CharacterDefinition byId(String id) =>
      all.firstWhere((c) => c.id == id);

  static List<CharacterDefinition> byRank(RankType rank) =>
      all.where((c) => c.rank == rank).toList();

  static CharacterDefinition? tryById(String id) {
    try {
      return byId(id);
    } catch (e) {
      return null;
    }
  }
}
