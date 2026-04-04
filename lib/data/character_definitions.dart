// character_definitions.dart — 실제 애셋 기반 캐릭터 정의
// 모든 캐릭터는 characters/ 폴더의 스프라이트 시트에 대응

import '../models/character_model.dart';

class CharacterDefinitions {
  static final List<CharacterDefinition> all = [
    // ─── 궁수 타워용 (archer) ─────────────────────
    // 빠른 연사, 단일 타겟
    CharacterDefinition(
      id: 'archer',
      name: '엘프 궁수',
      towerType: TowerTypeMapping.archer,
      spriteSheet: 'characters/archer.png',
      frameColumns: 5,
      frameRows: 3,
      totalFrames: 15,
    ),
    CharacterDefinition(
      id: 'gunslinger',
      name: '총잡이',
      towerType: TowerTypeMapping.archer,
      spriteSheet: 'characters/gunslinger.png',
      frameColumns: 5,
      frameRows: 3,
      totalFrames: 15,
    ),
    CharacterDefinition(
      id: 'dual_blade',
      name: '쌍검사',
      towerType: TowerTypeMapping.archer,
      spriteSheet: 'characters/dual_blade.png',
      frameColumns: 5,
      frameRows: 3,
      totalFrames: 15,
    ),

    // ─── 대포 타워용 (cannon) ─────────────────────
    // 느린 공속, 범위 데미지
    CharacterDefinition(
      id: 'swordsman',
      name: '검객',
      towerType: TowerTypeMapping.cannon,
      spriteSheet: 'characters/swordsman.png',
      frameColumns: 5,
      frameRows: 3,
      totalFrames: 15,
    ),
    CharacterDefinition(
      id: 'cannon',
      name: '미치광이 포격수',
      towerType: TowerTypeMapping.cannon,
      spriteSheet: 'characters/cannon.png',
      frameColumns: 5,
      frameRows: 3,
      totalFrames: 15,
    ),
    CharacterDefinition(
      id: 'brawler',
      name: '브롤러',
      towerType: TowerTypeMapping.cannon,
      spriteSheet: 'characters/brawler.png',
      frameColumns: 5,
      frameRows: 2,
      totalFrames: 10,
    ),

    // ─── 마법사 타워용 (mage) ─────────────────────
    // 명중 시 감속, 마법 데미지
    CharacterDefinition(
      id: 'energy_mage',
      name: '에너지 메이지',
      towerType: TowerTypeMapping.mage,
      spriteSheet: 'characters/energy_mage.png',
      frameColumns: 5,
      frameRows: 3,
      totalFrames: 15,
    ),
    CharacterDefinition(
      id: 'demon_girl',
      name: '악마 소녀',
      towerType: TowerTypeMapping.mage,
      spriteSheet: 'characters/demon_girl.png',
      frameColumns: 5,
      frameRows: 3,
      totalFrames: 15,
    ),

    // ─── 저격 타워용 (sniper) ─────────────────────
    // 최고 사거리, 단일 고데미지
    CharacterDefinition(
      id: 'mech_soldier',
      name: '메카 솔저',
      towerType: TowerTypeMapping.sniper,
      spriteSheet: 'characters/mech_soldier.png',
      frameColumns: 5,
      frameRows: 3,
      totalFrames: 15,
    ),
    CharacterDefinition(
      id: 'cyborg',
      name: '사이보그',
      towerType: TowerTypeMapping.sniper,
      spriteSheet: 'characters/cyborg.png',
      frameColumns: 5,
      frameRows: 3,
      totalFrames: 15,
    ),
  ];

  static CharacterDefinition byId(String id) =>
      all.firstWhere((c) => c.id == id);

  static List<CharacterDefinition> byTowerType(TowerTypeMapping type) =>
      all.where((c) => c.towerType == type).toList();

  static CharacterDefinition? tryById(String id) {
    try {
      return byId(id);
    } catch (e) {
      return null;
    }
  }
}
