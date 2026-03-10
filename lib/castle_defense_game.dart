// castle_defense_game.dart

import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'models/character_model.dart';
import 'models/character_enums.dart';
import 'data/character_definitions.dart';
import 'systems/gacha_system.dart';

enum GameState {
  loading, // 로딩(0.5초 게이지)
  roundSelect, // 라운드 선택 (맵 스타일)
  playing, // 실제 전투
  paused, // 일시정지
  levelUp, // 리디자인 B-2-11: 레벨업 바프 카드 선택 (게임 일시정지)
  roundClear, // 라운드 클리어 (잠깐 멈춤)
  augmentSelect, // 증강 선택 (라운드 2/4/5 클리어 후)
  shopOpen, // 리디자인 B-2-16: 스테이지 클리어 후 상점 화면
  result, // 결과 화면 (클리어 or 실패)
}

// 리디자인 B-2-16: 상점 아이템 종류
enum ShopItemType {
  castleFullRepair,  // 성 HP 완전 회복 (무료, 스테이지 클리어 시 자동)
  castleMaxHpUp,    // 성 최대 HP +20 (50G, 최대 10회)
  towerPowerUp,     // 전체 타워 공격력 +5% (30G, 최대 10회)
  mainCharHpUp,     // 메인 캐릭터 최대 HP +10 (20G, 최대 5회)
}

// 증강 시스템 (augment-system.md 참조)
enum AugmentTier { common, rare, legendary }
enum AugmentCategory { main, tower, castle, utility, economy, elemental, special, synergy }

class Augment {
  final String id;
  final String nameJp;
  final AugmentTier tier;
  final AugmentCategory category;
  final String description;
  final bool carryOverToNextStage;

  const Augment({
    required this.id,
    required this.nameJp,
    required this.tier,
    required this.category,
    required this.description,
    this.carryOverToNextStage = false,
  });
}

// 전체 34종 증강 정의
const List<Augment> kAllAugments = [
  // === Common (14종) ===
  Augment(id:'C-01', nameJp:'鋼の意志', tier:AugmentTier.common, category:AugmentCategory.main, description:'메인 최대 HP +15'),
  Augment(id:'C-02', nameJp:'迅速の加護', tier:AugmentTier.common, category:AugmentCategory.main, description:'메인 이동속도 +25%'),
  Augment(id:'C-03', nameJp:'鋭利な刃', tier:AugmentTier.common, category:AugmentCategory.main, description:'메인 공격력 +20%'),
  Augment(id:'C-04', nameJp:'連射の才', tier:AugmentTier.common, category:AugmentCategory.main, description:'메인 공격속도 +20%'),
  Augment(id:'C-05', nameJp:'城壁修復', tier:AugmentTier.common, category:AugmentCategory.castle, description:'성 최대 HP +25 및 즉시 25 회복'),
  Augment(id:'C-06', nameJp:'タワー油断', tier:AugmentTier.common, category:AugmentCategory.tower, description:'전 타워 공격속도 +20%'),
  Augment(id:'C-07', nameJp:'巨大磁石', tier:AugmentTier.common, category:AugmentCategory.utility, description:'XP 회수 반경 +30px'),
  Augment(id:'C-08', nameJp:'速成復活', tier:AugmentTier.common, category:AugmentCategory.utility, description:'복활 카운트다운 -2초'),
  Augment(id:'C-09', nameJp:'金の手', tier:AugmentTier.common, category:AugmentCategory.economy, description:'골드 획득량 +30%'),
  Augment(id:'C-10', nameJp:'余波', tier:AugmentTier.common, category:AugmentCategory.main, description:'메인 격파 시 주위 30px 스플래시'),
  Augment(id:'C-11', nameJp:'守護の炎', tier:AugmentTier.common, category:AugmentCategory.castle, description:'라운드 시작 시 성 HP +5 회복'),
  Augment(id:'C-12', nameJp:'タワー補給', tier:AugmentTier.common, category:AugmentCategory.tower, description:'전 타워 사거리 +20%'),
  Augment(id:'C-13', nameJp:'疾風迅雷', tier:AugmentTier.common, category:AugmentCategory.utility, description:'복활 무적시간 +2초'),
  Augment(id:'C-14', nameJp:'属性目覚め', tier:AugmentTier.common, category:AugmentCategory.elemental, description:'속성 데미지 보너스 +10%'),
  // === Rare (12종) ===
  Augment(id:'R-01', nameJp:'連鎖弾', tier:AugmentTier.rare, category:AugmentCategory.main, description:'투사물 착탄 후 최근 적에게 60% 연쇄'),
  Augment(id:'R-02', nameJp:'吸血衝動', tier:AugmentTier.rare, category:AugmentCategory.main, description:'공격 데미지의 20%를 HP로 흡수'),
  Augment(id:'R-03', nameJp:'爆発弾頭', tier:AugmentTier.rare, category:AugmentCategory.tower, description:'투사물 착탄 시 35px 범위 50% 스플래시'),
  Augment(id:'R-04', nameJp:'城の怒り', tier:AugmentTier.rare, category:AugmentCategory.castle, description:'성 피격 시 타워 공격력 +15% (5초, 최대3스택)'),
  Augment(id:'R-05', nameJp:'超集中砲火', tier:AugmentTier.rare, category:AugmentCategory.tower, description:'타워 집중 공격 시 데미지 +30%'),
  Augment(id:'R-06', nameJp:'緊急発動', tier:AugmentTier.rare, category:AugmentCategory.special, description:'스킬 게이지 축적량 +50%'),
  Augment(id:'R-07', nameJp:'元素爆発', tier:AugmentTier.rare, category:AugmentCategory.elemental, description:'통상 공격에 속성 상태이상 15% 발동'),
  Augment(id:'R-08', nameJp:'鉄壁の城', tier:AugmentTier.rare, category:AugmentCategory.castle, description:'성 접촉 데미지 -30%'),
  Augment(id:'R-09', nameJp:'宝の山', tier:AugmentTier.rare, category:AugmentCategory.utility, description:'XP젬/골드 소멸시간 +15초'),
  Augment(id:'R-10', nameJp:'二段蓄積', tier:AugmentTier.rare, category:AugmentCategory.utility, description:'레벨업 XP 자석 2연속 발동'),
  Augment(id:'R-11', nameJp:'タワー連携', tier:AugmentTier.rare, category:AugmentCategory.tower, description:'동일 타겟 2연속 공격 후 3회째 자동 크리티컬'),
  Augment(id:'R-12', nameJp:'不屈の城', tier:AugmentTier.rare, category:AugmentCategory.castle, description:'성 HP 50이하 시 1회 10초 바리어 발동'),
  // === Legendary (8종) ===
  Augment(id:'L-01', nameJp:'不死の誓い', tier:AugmentTier.legendary, category:AugmentCategory.main, description:'HP0 시 1회 HP1 생존 + 3초 무적 (스테이지 1회)', carryOverToNextStage:true),
  Augment(id:'L-02', nameJp:'王の咆哮', tier:AugmentTier.legendary, category:AugmentCategory.special, description:'필살기 발동 시 10초간 타워 공격력+60% 공속+40%', carryOverToNextStage:true),
  Augment(id:'L-03', nameJp:'大地の守護者', tier:AugmentTier.legendary, category:AugmentCategory.castle, description:'성 HP 30%이하 시 60초 바리어 (성 데미지 50%감소) 1회'),
  Augment(id:'L-04', nameJp:'時の加速', tier:AugmentTier.legendary, category:AugmentCategory.utility, description:'라운드 인터벌 중 이동속도 400% + XP 자석 상시 발동'),
  Augment(id:'L-05', nameJp:'元素の嵐', tier:AugmentTier.legendary, category:AugmentCategory.elemental, description:'3속성 이상 시 전 공격에 랜덤 속성 상태이상 30%'),
  Augment(id:'L-06', nameJp:'究極砲台', tier:AugmentTier.legendary, category:AugmentCategory.tower, description:'타워 투사물 수 +1 (타워 1기씩 순서대로 적용)', carryOverToNextStage:true),
  Augment(id:'L-07', nameJp:'魂の連鎖', tier:AugmentTier.legendary, category:AugmentCategory.synergy, description:'메인이 적 격파 시 전 타워 다음 공격이 크리티컬'),
  Augment(id:'L-08', nameJp:'永遠の契約', tier:AugmentTier.legendary, category:AugmentCategory.synergy, description:'같은 효과 바프 2회 이상 취득 시 +1스택 추가'),
];

// 리디자인 B-2-11: 바프 타입 (P-2-1 기준 8종)
enum BuffType {
  attackUp,    // 공격력 +15% (최대 5회)
  attackSpdUp, // 공격 간격 -10% (최대 5회)
  moveSpeedUp, // 이동속도 +20% (최대 3회)
  rangeUp,     // 사거리 +15% (최대 3회)
  castleRepair, // 성 HP +20 (무제한)
  towerPowerUp, // 전체 타워 공격력 +10% (최대 5회)
  xpMagnetUp,  // 젬 회수 반경 +15px (최대 3회)
  castleBarrier, // 10초 성 무적 (무제한)
  // 속성 시스템: 속성 부여 바프 (최대 1회, 상덮어쓰기)
  elementFireGrant,     // 화염 속성 부여
  elementWaterGrant,    // 수빙 속성 부여
  elementEarthGrant,    // 대지 속성 부여
  elementElectricGrant, // 번개 속성 부여
  elementDarkGrant,     // 암흑 속성 부여
  elementMastery,       // 속성 데미지 보너스 +10% (최대 3회)
}

enum BottomMenu {
  shop, // 상점
  inventory, // 인벤토리
  home, // 홈 (라운드 선택)
  gacha, // 뽑기
  settings, // 설정
}

enum MonsterType {
  normal, // 일반 몬스터
  miniBoss, // 부보스 (라운드 5)
  boss, // 보스 (라운드 10)
}

class RoundConfig {
  final int roundNumber;
  final int totalMonsters;
  final int monsterMaxHp;
  final double spawnInterval;
  final MonsterType monsterType;
  // 리디자인 B-2-17: 미니보스 수 (라운드 내 스폰할 미니보스 수)
  final int miniBossCount;

  const RoundConfig({
    required this.roundNumber,
    required this.totalMonsters,
    required this.monsterMaxHp,
    required this.spawnInterval,
    this.monsterType = MonsterType.normal,
    this.miniBossCount = 0,
  });
}

class StageConfig {
  final int stageLevel;
  final List<RoundConfig> rounds;

  const StageConfig({
    required this.stageLevel,
    required this.rounds,
  });
}

// 리디자인 B-2-17: P-2-2 라운드 테이블 기반 스테이지 설정
// Stage 1 = Global R1~R10, Stage 2 = Global R11~R20
List<RoundConfig> _createStageRounds(int stageLevel) {
  final rounds = <RoundConfig>[];
  final int globalOffset = (stageLevel - 1) * 10;
  for (int i = 1; i <= 10; i++) {
    rounds.add(_buildRoundConfig(i, globalOffset + i));
  }
  return rounds;
}

// P-2-2 테이블에서 글로벌 라운드 번호로 라운드 설정 생성
RoundConfig _buildRoundConfig(int roundNumber, int globalR) {
  // P-2-3: 글로벌 라운드별 HP 스케일링
  int normalHp;
  if (globalR <= 5) {
    normalHp = 5;
  } else if (globalR <= 10) {
    normalHp = 7;
  } else if (globalR <= 15) {
    normalHp = 10;
  } else if (globalR <= 20) {
    normalHp = 13;
  } else {
    normalHp = 13 + 2 * (globalR - 20);
  }

  // P-2-2 테이블: 라운드별 일반 몬스터 수, 스폰 간격, 미니보스 수, 보스 여부
  int normalCount;
  double spawnInterval;
  int miniBossCount;
  bool isBossRound;

  if (globalR == 1) {
    normalCount = 8; spawnInterval = 2.0; miniBossCount = 0; isBossRound = false;
  } else if (globalR == 2) {
    normalCount = 12; spawnInterval = 1.8; miniBossCount = 0; isBossRound = false;
  } else if (globalR == 3) {
    normalCount = 15; spawnInterval = 1.5; miniBossCount = 1; isBossRound = false;
  } else if (globalR == 4) {
    normalCount = 18; spawnInterval = 1.3; miniBossCount = 1; isBossRound = false;
  } else if (globalR == 5) {
    normalCount = 20; spawnInterval = 1.0; miniBossCount = 0; isBossRound = true;
  } else if (globalR == 6) {
    normalCount = 23; spawnInterval = 0.9; miniBossCount = 1; isBossRound = false;
  } else if (globalR == 7) {
    normalCount = 26; spawnInterval = 0.8; miniBossCount = 1; isBossRound = false;
  } else if (globalR == 8) {
    normalCount = 29; spawnInterval = 0.7; miniBossCount = 2; isBossRound = false;
  } else if (globalR == 9) {
    normalCount = 32; spawnInterval = 0.6; miniBossCount = 2; isBossRound = false;
  } else if (globalR == 10) {
    normalCount = 35; spawnInterval = 0.5; miniBossCount = 0; isBossRound = true;
  } else if (globalR == 11) {
    normalCount = 38; spawnInterval = 0.5; miniBossCount = 2; isBossRound = false;
  } else if (globalR == 12) {
    normalCount = 41; spawnInterval = 0.5; miniBossCount = 2; isBossRound = false;
  } else if (globalR == 13) {
    normalCount = 44; spawnInterval = 0.5; miniBossCount = 3; isBossRound = false;
  } else if (globalR == 14) {
    normalCount = 47; spawnInterval = 0.5; miniBossCount = 3; isBossRound = false;
  } else if (globalR == 15) {
    normalCount = 50; spawnInterval = 0.5; miniBossCount = 0; isBossRound = true;
  } else if (globalR == 16) {
    normalCount = 53; spawnInterval = 0.5; miniBossCount = 3; isBossRound = false;
  } else if (globalR == 17) {
    normalCount = 56; spawnInterval = 0.5; miniBossCount = 3; isBossRound = false;
  } else if (globalR == 18) {
    normalCount = 59; spawnInterval = 0.5; miniBossCount = 4; isBossRound = false;
  } else if (globalR == 19) {
    normalCount = 62; spawnInterval = 0.5; miniBossCount = 4; isBossRound = false;
  } else if (globalR == 20) {
    normalCount = 65; spawnInterval = 0.5; miniBossCount = 0; isBossRound = true;
  } else {
    // R21+: 매 라운드 +3 일반, 4 미니보스 상한, 5라운드마다 보스
    normalCount = 65 + 3 * (globalR - 20);
    spawnInterval = 0.5;
    miniBossCount = 4;
    isBossRound = (globalR % 5 == 0);
  }

  final MonsterType roundType = isBossRound
      ? MonsterType.boss
      : (miniBossCount > 0 ? MonsterType.miniBoss : MonsterType.normal);

  return RoundConfig(
    roundNumber: roundNumber,
    totalMonsters: normalCount,
    monsterMaxHp: normalHp,
    spawnInterval: spawnInterval,
    monsterType: roundType,
    miniBossCount: isBossRound ? 0 : miniBossCount,
  );
}

// 스테이지별 미니보스 HP (글로벌 라운드 기반 HP 계산)
int _getMiniBossHp(int stageLevel) {
  final int midR = (stageLevel - 1) * 10 + 5;
  if (midR <= 5) return 40;
  if (midR <= 10) return 55;
  if (midR <= 15) return 75;
  if (midR <= 20) return 100;
  return 100 + 10 * (midR - 20);
}

// 스테이지별 보스 HP
int _getBossHp(int stageLevel) {
  final int midR = (stageLevel - 1) * 10 + 5;
  if (midR <= 5) return 200;
  if (midR <= 10) return 250;
  if (midR <= 15) return 320;
  if (midR <= 20) return 400;
  return 400 + 30 * (midR - 20);
}

// 리디자인 B-2-17: P-2-2 기반 스테이지 설정 맵
final Map<int, StageConfig> kStageConfigs = {
  1: StageConfig(stageLevel: 1, rounds: _createStageRounds(1)),
  2: StageConfig(stageLevel: 2, rounds: _createStageRounds(2)),
  3: StageConfig(stageLevel: 3, rounds: _createStageRounds(3)),
  4: StageConfig(stageLevel: 4, rounds: _createStageRounds(4)),
  5: StageConfig(stageLevel: 5, rounds: _createStageRounds(5)),
  6: StageConfig(stageLevel: 6, rounds: _createStageRounds(6)),
  7: StageConfig(stageLevel: 7, rounds: _createStageRounds(7)),
  8: StageConfig(stageLevel: 8, rounds: _createStageRounds(8)),
};

class _Monster {
  Vector2 pos;
  int hp;
  int maxHp;
  // 리디자인: falling 필드 삭제 (낙하 로직 제거)
  bool walking;
  MonsterType type;
  double damageFlashTimer = 0.0; // 데미지 점멸 타이머
  double displayHp; // 표시용 HP (부드러운 감소용)
  double lastHitTime = 0.0; // 마지막 피격 시간 (중복 데미지 방지용)
  _CharacterUnit? aggroTarget; // 어그로 타겟 (탱커에게 끌림)
  bool attackingCastle = false; // 성을 공격 중인지 여부
  double castleAttackTimer = 0.0; // 성 공격 타이머

  // スプライトアニメーション用
  double animationTimer = 0.0; // アニメーションタイマー
  int currentFrame = 0; // 現在のフレーム (0-3)

  // 속성 시스템: 몬스터 속성 및 상태이상 (element-system.md)
  ElementType element = ElementType.none;
  double burnTimer = 0.0;     // 화상: 3초간 0.5초마다 5% 지속 데미지
  double burnTickTimer = 0.0; // 화상 틱 카운터
  double freezeTimer = 0.0;   // 빙결: 2초간 이동속도 50% 감소
  double bindTimer = 0.0;     // 속박: 1.5초간 완전 정지
  double shockTimer = 0.0;    // 감전: 3초간 공격속도 30% 감소
  double curseTimer = 0.0;    // 저주: 4초간 피격 데미지 20% 증가

  _Monster({
    required this.pos,
    required this.hp,
    required this.maxHp,
    required this.walking,
    this.type = MonsterType.normal,
    this.element = ElementType.none,
  }) : displayHp = hp.toDouble();
}

// 투사물 (원거리 공격용)
class _Projectile {
  Vector2 pos;
  Vector2 velocity; // 속도 벡터
  double damage;
  RoleType sourceRole; // 발사한 캐릭터의 역할 (이펙트 색상용)
  ClassType? sourceClass; // 발사한 캐릭터의 클래스 (궁수/총잡이 구분용)
  _Monster? targetMonster; // 유도 미사일용 타겟
  double splashRadius; // 스플래시 데미지 범위 (0이면 단일 타겟)
  bool isMagic; // 마법 투사물 여부 (스플래시 효과용)
  List<Vector2> trail; // 잔상 위치 (최대 3개)

  _Projectile({
    required this.pos,
    required this.velocity,
    required this.damage,
    required this.sourceRole,
    this.sourceClass,
    this.targetMonster,
    this.splashRadius = 0.0,
    this.isMagic = false,
  }) : trail = [];
}

// VFX 이펙트 종류
enum VfxType { hit, death, shockwave, barrier }

// VFX 이펙트
class _VfxEffect {
  Vector2 pos;
  double timer; // 경과 시간
  double duration; // 지속 시간
  VfxType type;
  double maxRadius; // 최대 반경 (충격파/죽음용)
  Color color;

  _VfxEffect({
    required this.pos,
    required this.type,
    required this.duration,
    required this.color,
    this.maxRadius = 15.0,
  }) : timer = 0.0;

  bool get isExpired => timer >= duration;
  double get progress => (timer / duration).clamp(0.0, 1.0);
}

// #34 속성UI: 부유 데미지 숫자
class _DamageNumber {
  Vector2 pos;
  double timer;
  final int amount;
  final double elementMult; // 1.5=유리/0.75=불리/기타=보통
  final ElementType element;

  _DamageNumber({
    required this.pos,
    required this.amount,
    required this.elementMult,
    required this.element,
  }) : timer = 0.0;

  static const double duration = 1.2;
  bool get isExpired => timer >= duration;
}

// 리디자인 B-2-8: XP 젬 오브젝트
class _XpGem {
  Vector2 pos;
  int xpValue;
  double lifeTimer; // 남은 수명 (30초)
  static const double maxLife = 30.0;

  _XpGem({required this.pos, required this.xpValue}) : lifeTimer = maxLife;
  bool get isExpired => lifeTimer <= 0;
  bool get isBlinking => lifeTimer <= 5.0; // 5초 이하면 깜빡임
}

// 리디자인 B-2-15: 골드 오브젝트
class _GoldDrop {
  Vector2 pos;
  int goldValue;

  _GoldDrop({required this.pos, required this.goldValue});
}

// 캐릭터 유닛 (실제 전투 유닛)
class _CharacterUnit {
  final String instanceId; // OwnedCharacter의 instanceId
  final CharacterDefinition definition;
  final int level;
  Vector2 pos;
  double currentHp;
  double maxHp;
  double attackCooldown; // 공격 쿨타임
  _Monster? targetMonster; // 현재 타겟 몬스터
  bool movingTowardsTarget; // 타겟을 향해 이동 중인지
  bool hasAttackSpeedBuff = false; // 공격속도 버프 보유 여부
  bool hasMoveSpeedBuff = false; // 이동속도 버프 보유 여부

  // 리디자인: 타워 유닛 여부 (partySlots 인덱스 1-4)
  bool isTower;
  Vector2? towerFixedPos; // 타워 고정 좌표

  // 전사 검 휘두르기 애니메이션
  double swordSwingAngle = 0.0; // 현재 검 각도 (라디안)
  bool isSwinging = false; // 검을 휘두르는 중인지
  double swingProgress = 0.0; // 휘두르기 진행도 (0.0 ~ 1.0)

  // 총잡이 연속 발사
  int burstShotsRemaining = 0; // 남은 연속 발사 수
  double burstTimer = 0.0; // 연속 발사 타이머

  _CharacterUnit({
    required this.instanceId,
    required this.definition,
    required this.level,
    required this.pos,
    required this.currentHp,
    required this.maxHp,
    this.attackCooldown = 0.0,
    this.targetMonster,
    this.movingTowardsTarget = false,
    this.isTower = false,
    this.towerFixedPos,
  });

  // 레벨에 따른 스탯 계산
  double get attack => definition.baseStats.attack * (1 + level * 0.1);
  double get defense => definition.baseStats.defense * (1 + level * 0.1);
  double get attackSpeed => definition.baseStats.attackSpeed;
  double get moveSpeed => definition.baseStats.moveSpeed;
}

// 캐릭터 슬롯 (UI 표시용)
class _CharacterSlot {
  final int slotIndex; // 0~3
  bool hasCharacter; // 캐릭터가 배치되어 있는지
  String characterName; // 캐릭터 이름 (프로토타입용)
  bool skillReady; // 스킬 사용 가능 여부

  _CharacterSlot({
    required this.slotIndex,
    this.hasCharacter = false,
    this.characterName = '',
    this.skillReady = false,
  });
}

class CastleDefenseGame extends FlameGame with TapCallbacks, DragCallbacks {
  // -----------------------------
  // 기본 설정
  // -----------------------------
  final double castleHeight = 80.0; // 2배로 확대
  // 리디자인 B-2-16: 성 최대 HP (상점 업그레이드로 증가)
  int get castleMaxHp => 200 + _shopCastleMaxHpCount * 20;
  int castleHp = 200; // 리디자인: 성 현재 HP
  double castleFlashTimer = 0.0; // Designer 요청 D-3-1: 성 피격 점멸 타이머

  // 몬스터 설정
  final double monsterRadius = 16.0;
  // 리디자인: 타입별 이동 속도 (낙하 속도 삭제)
  static const double _normalMonsterSpeed = 40.0;
  static const double _miniBossSpeed = 30.0;
  static const double _bossSpeed = 25.0;

  // 무기 (프로토타입)
  final int weaponDamage = 1; // 기본검 데미지

  // 스테이지 & 라운드 관련
  GameState gameState = GameState.loading;
  int stageLevel = 1;
  int currentRound = 1; // 현재 라운드 (1~10)
  int totalRoundsInStage = 10; // 스테이지당 라운드 수

  // 현재 라운드 스폰 관련
  int totalMonstersInRound = 5; // 현재 라운드의 총 몬스터 수
  int spawnedMonsters = 0; // 현재 라운드에서 스폰된 몬스터 수
  int defeatedMonsters = 0; // 현재 라운드에서 플레이어가 처치한 몬스터 수
  int escapedMonsters = 0; // 현재 라운드에서 성에 도달한 몬스터 수 (미처치)

  int monsterMaxHp = 2; // 현재 라운드 몬스터 최대 HP
  double spawnTimer = 0.0;

  bool bossSpawned = false; // 보스/미니보스가 이미 스폰되었는지 여부
  // 리디자인 B-2-17: 미니보스 스폰 카운터
  int miniBossesSpawned = 0;

  // 라운드 시간 제한
  double roundTimer = 0.0; // 현재 라운드 경과 시간
  double roundTimeLimit = 120.0; // 현재 라운드 제한 시간 (초)
  double gameTime = 0.0; // 전역 게임 시간 (충돌 데미지 쿨다운용)

  // 로딩 화면용
  double _loadingTimer = 0.0;
  final double _loadingDuration = 0.5; // 초 단위

  // 라운드 클리어 대기용
  double _roundClearTimer = 0.0;
  final double _roundClearDuration = 3.0; // 리디자인 B-2-18: 라운드 간 3초 인터벌

  // D-1-6: 라운드 중 획득 XP/골드 추적 (클리어 연출용)
  int _roundXpGained = 0;
  int _roundGoldGained = 0;

  // 라운드 언락 상태
  int unlockedRoundMax = 1; // 처음엔 라운드 1만 선택 가능

  // 스테이지 선택 화면용
  int selectedStageInUI = 1; // 라운드 선택 화면에서 현재 보고 있는 스테이지

  // 하단 메뉴
  BottomMenu currentBottomMenu = BottomMenu.home;

  // 결과 화면용 정보
  bool _lastStageClear = false;

  // 테스트 갓 모드
  bool _godModeEnabled = false;

  // 리디자인 B-2-4: 버추얼 스틱 상태
  bool _stickActive = false;
  Vector2 _stickBasePos = Vector2.zero();
  Vector2 _stickKnobPos = Vector2.zero();
  static const double _stickOuterRadius = 60.0;
  static const double _stickKnobRadius = 25.0;
  static const double _stickDeadzone = 7.0; // Planner 추천: 외경 12%

  // 리디자인 B-2-5: 메인 캐릭터 이동 속도
  static const double _mainCharSpeed = 150.0;

  // 리디자인 B-2-3: 성직자 성 회복 타이머
  double _priestHealTimer = 0.0;
  static const double _priestHealInterval = 5.0; // 5초마다 회복
  static const int _priestHealAmount = 3; // 1회 회복량

  // 리디자인 B-2-6: 메인 캐릭터 HP
  // 리디자인 B-2-16: 메인 캐릭터 최대 HP (상점 업그레이드로 증가)
  int get _mainCharMaxHp => 50 + _shopMainCharHpCount * 10;
  int _mainCharHp = 50;
  bool _mainCharAlive = true;
  double _mainCharDamageCooldown = 0.0; // 적 접촉 데미지 쿨다운 (0.5초)

  // 리디자인 B-2-7: 복활 시스템
  bool _mainCharRespawning = false; // 복활 카운트다운 중
  double _respawnTimer = 0.0; // 복활 카운트다운 타이머
  static const double _respawnDuration = 5.0; // 5초 카운트다운
  double _invincibleTimer = 0.0; // 복활 후 무적 타이머
  static const double _invincibleDuration = 2.0; // 2초 무적

  // 플레이어 정보 (네비게이션 바용)
  String playerNickname = 'Player';
  int playerLevel = 1;
  int playerGold = 1000;
  // 리디자인 B-2-10: 인게임 캐릭터 XP / 레벨
  int playerXp = 0;
  int playerCharLevel = 1;
  bool _pendingLevelUp = false; // 레벨업 대기 (버프 카드 표시 트리거)
  // 리디자인 B-2-11: 바프 스택 카운터 (P-2-1 기준)
  int _atkUpCount = 0;       // 공격력 UP 스택 (최대 5)
  int _spdUpCount = 0;       // 공격속도 UP 스택 (최대 5)
  int _moveUpCount = 0;      // 이동속도 UP 스택 (최대 3)
  int _rangeUpCount = 0;     // 사거리 UP 스택 (최대 3)
  int _towerUpCount = 0;     // 타워강화 스택 (최대 5)
  int _magnetCount = 0;      // XP 자석 스택 (최대 3)
  bool _castleBarrierActive = false; // 성 바리어 활성 여부
  double _castleBarrierTimer = 0.0;  // 바리어 남은 시간
  static const double _castleBarrierDuration = 10.0;
  // 리디자인 B-2-16: 상점 영구 강화 카운터 (스테이지 간 유지)
  int _shopCastleMaxHpCount = 0;    // 성 최대 HP +20 구매 횟수 (최대 10)
  int _shopTowerPowerCount = 0;     // 타워 공격력 +5% 구매 횟수 (최대 10)
  int _shopMainCharHpCount = 0;     // 메인 캐릭터 HP +10 구매 횟수 (최대 5)
  // 속성 시스템: 메인 캐릭터 현재 속성 (바프로 부여, 스테이지 내 유지)
  ElementType _mainCharElement = ElementType.none;
  int _elementMasteryCount = 0; // 속성 마스터리 스택 (최대 3)

  // 증강 시스템 (augment-system.md 참조)
  List<Augment> activeAugments = []; // 현재 스테이지 취득 증강
  List<Augment> _augmentOptions = []; // 현재 선택지 3개
  final Set<String> _acquiredAugmentIds = {}; // 취득한 증강 ID 집합 (중복 방지)
  // 증강별 효과 상태
  bool _augmentL01Used = false;   // L-01 불사의 서약: 1회 사용 여부
  bool _augmentL03Used = false;   // L-03 대지의 수호자: 1회 사용 여부
  bool _augmentR12Used = false;   // R-12 불굴의 성: 1회 발동 여부
  int _augmentR04Stacks = 0;      // R-04 성의 분노: 현재 스택 수
  double _augmentR04Timer = 0.0;  // R-04 타이머
  bool _augmentL07NextCrit = false; // L-07 영혼의 연쇄: 다음 타워 공격 크리티컬 여부
  bool _augmentL02Active = false;        // L-02 왕의 포효: 타워 강화 활성 여부
  double _augmentL02Timer = 0.0;         // L-02 타이머 (10초)
  bool _augmentL03BarrierActive = false; // L-03 대지의 수호자: 바리어 활성 여부
  double _augmentL03BarrierTimer = 0.0;  // L-03 타이머 (60초)
  final Map<BuffType, int> _buffSelectionCount = {}; // L-08: 바프 선택 횟수 추적

  // 레벨업 바프 선택지 (3장)
  List<BuffType> _buffOptions = [];
  BuffType? _lastChosenBuff; // 직전 선택 바프 (50% 확률 감소용)
  // 리디자인 B-2-12: XP 자석 범위 (레벨업 직후 1초간 전체 흡인)
  double _xpMagnetTimer = 0.0; // 자석 효과 남은 시간
  static const double _xpMagnetDuration = 1.0;
  // D-3-5: 스킬 발동 시 슬로우 모션 타이머 (0.3초)
  double _slowMotionTimer = 0.0;
  int playerGem = 500; // 뽑기 테스트용으로 많이 줌
  int playerEnergy = 50;
  int playerMaxEnergy = 50;
  DateTime _lastEnergyUpdateTime = DateTime.now();

  // 캐릭터 인벤토리
  final List<OwnedCharacter> ownedCharacters = [];
  final GachaSystem gachaSystem = GachaSystem();

  // 뽑기 결과 (애니메이션용)
  List<CharacterDefinition>? gachaResults;
  int gachaResultIndex = 0;

  // 캐릭터 도감 스크롤
  double characterListScrollOffset = 0.0;
  double _dragStartY = 0.0;

  // 파티 설정 (4개 슬롯)
  // 리디자인: 5슬롯 (0=메인캐릭터, 1-4=타워)
  final List<String?> partySlots = [null, null, null, null, null];
  bool showPartySelectionPopup = false;
  int selectedPartySlotIndex = -1; // 현재 선택 중인 파티 슬롯
  double partyPopupScrollOffset = 0.0; // 파티 팝업 스크롤 오프셋
  double _partyPopupDragStartY = 0.0; // 파티 팝업 드래그 시작 Y

  // 몬스터 리스트
  final List<_Monster> monsters = [];

  // 캐릭터 유닛 (실제 전투 유닛)
  final List<_CharacterUnit> characterUnits = [];

  // 투사물 리스트
  final List<_Projectile> projectiles = [];

  // VFX 이펙트 리스트
  final List<_VfxEffect> vfxEffects = [];

  // 리디자인 B-2-8: XP 젬 리스트
  final List<_XpGem> xpGems = [];

  // 리디자인 B-2-15: 골드 드롭 리스트
  final List<_GoldDrop> goldDrops = [];

  // 리디자인 B-2-13: 스킬 게이지 (0.0~100.0)
  double skillGauge = 0.0;
  bool skillReady = false; // 100%에서 true

  // 캐릭터 슬롯 (5개 - UI용)
  final List<_CharacterSlot> characterSlots = [];

  // 랜덤
  final Random _random = Random();

  // Goblinスプライト
  Image? goblinImage;
  bool goblinImageLoaded = false;

  // D-4-1: 성 스프라이트
  Image? castleImage;
  bool castleImageLoaded = false;

  // D-3-2: XP 젬 스프라이트
  Image? xpGemImage;
  bool xpGemImageLoaded = false;

  // D-3-3: 골드 코인 스프라이트
  Image? goldCoinImage;
  bool goldCoinImageLoaded = false;

  // D-4-3: 보스/미니보스 스프라이트
  Image? bossMonsterImage;
  bool bossMonsterImageLoaded = false;
  Image? minibossMonsterImage;
  bool minibossMonsterImageLoaded = false;

  // B-3-2: 몬스터 오브젝트 풀 (GC 압력 감소)
  final List<_Monster> _monsterPool = [];

  // 캐릭터 설정
  final double characterUnitRadius = 12.0; // 캐릭터 크기
  final double projectileSpeed = 200.0; // 투사물 속도
  final double meleeRange = 40.0; // 근거리 공격 범위
  final double rangedRange = 375.0; // 원거리 공격 범위 (250 * 1.5)
  final double physicalDealerRange = 525.0; // 물리 딜러 사거리 (350 * 1.5)
  final double priestRange = 600.0; // 힐러(성직자) 사거리 (400 * 1.5)
  final double topBoundary = 0.0; // 리디자인: 상단 제한 없음

  // 성 중심 좌표 (화면 중앙)
  double get castleCenterX => size.x / 2;
  double get castleCenterY => size.y / 2;

  int get killedMonsters => defeatedMonsters;

  // -----------------------------
  // 라이프사이클
  // -----------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 리디자인 B-3-1: 기준 해상도 390×844 (FitWidth 스케일링)
    camera.viewport = FixedResolutionViewport(resolution: Vector2(390, 844));
    _initializeCharacterSlots(); // 캐릭터 슬롯 초기화
    _loadStage(1); // 내부 파라미터 초기화
    gameState = GameState.loading; // GameScreen 진입 즉시 로딩부터 시작
    _loadingTimer = 0.0;

    // 스프라이트 전체 로드
    await Future.wait([
      _loadGoblinSprite(),
      _loadCastleSprite(),
      _loadXpGemSprite(),
      _loadGoldCoinSprite(),
      _loadBossSprites(),
    ]);
  }

  // Goblinスプライトをロード
  Future<void> _loadGoblinSprite() async {
    try {
      goblinImage = await images.load('goblin.png');
      goblinImageLoaded = true;
    } catch (e) {
      goblinImageLoaded = false;
    }
  }

  // D-4-1: 성 스프라이트 로드
  Future<void> _loadCastleSprite() async {
    try {
      castleImage = await images.load('castle.png');
      castleImageLoaded = true;
    } catch (e) {
      castleImageLoaded = false;
    }
  }

  // D-3-2: XP 젬 스프라이트 로드
  Future<void> _loadXpGemSprite() async {
    try {
      xpGemImage = await images.load('xp_gem.png');
      xpGemImageLoaded = true;
    } catch (e) {
      xpGemImageLoaded = false;
    }
  }

  // D-3-3: 골드 코인 스프라이트 로드
  Future<void> _loadGoldCoinSprite() async {
    try {
      goldCoinImage = await images.load('gold_coin.png');
      goldCoinImageLoaded = true;
    } catch (e) {
      goldCoinImageLoaded = false;
    }
  }

  // D-4-3/D-4-4: 보스/미니보스 스프라이트 로드
  Future<void> _loadBossSprites() async {
    try {
      bossMonsterImage = await images.load('boss_monster.png');
      bossMonsterImageLoaded = true;
    } catch (e) {
      bossMonsterImageLoaded = false;
    }
    try {
      minibossMonsterImage = await images.load('miniboss_monster.png');
      minibossMonsterImageLoaded = true;
    } catch (e) {
      minibossMonsterImageLoaded = false;
    }
  }

  // 캐릭터 슬롯 초기화 (처음에는 모두 비어있음)
  void _initializeCharacterSlots() {
    characterSlots.clear();
    // 리디자인: 5슬롯 (0=메인, 1-4=타워)
    for (int i = 0; i < 5; i++) {
      characterSlots.add(_CharacterSlot(
        slotIndex: i,
        hasCharacter: false, // 모든 슬롯이 처음엔 비어있음
        characterName: '',
        skillReady: false,
      ));
    }
  }

  // -----------------------------
  // 스테이지 로딩 / 시작 / 전환
  // -----------------------------
  void _loadStage(int level) {
    final cfg = kStageConfigs[level] ?? kStageConfigs[1]!;

    stageLevel = cfg.stageLevel;
    currentRound = 1; // 첫 번째 라운드부터 시작
    totalRoundsInStage = cfg.rounds.length;

    castleHp = castleMaxHp;
    monsters.clear();
    // 리디자인 B-2-10: 인게임 XP 초기화
    playerXp = 0;
    playerCharLevel = 1;
    _pendingLevelUp = false;
    // 속성 시스템: 스테이지 시작 시 속성 리셋 (바프로 재부여)
    _mainCharElement = ElementType.none;
    _elementMasteryCount = 0;
    // 증강 시스템: 스테이지 시작 시 비전설 증강 리셋, 전설은 carryOver 유지
    activeAugments = activeAugments.where((a) => a.carryOverToNextStage).toList();
    _acquiredAugmentIds.clear();
    for (final a in activeAugments) { _acquiredAugmentIds.add(a.id); }
    _augmentOptions = [];
    _augmentL01Used = false;
    _augmentL03Used = false;
    _augmentR12Used = false;
    _augmentR04Stacks = 0;
    _augmentR04Timer = 0.0;
    _augmentL07NextCrit = false;
    _augmentL02Active = false;
    _augmentL02Timer = 0.0;
    _augmentL03BarrierActive = false;
    _augmentL03BarrierTimer = 0.0;
    _buffSelectionCount.clear();

    _loadRound(1); // 첫 번째 라운드 로딩
  }

  void _loadRound(int roundNumber) {
    final cfg = kStageConfigs[stageLevel];
    if (cfg == null || roundNumber < 1 || roundNumber > cfg.rounds.length) {
      return;
    }

    final roundCfg = cfg.rounds[roundNumber - 1];
    currentRound = roundNumber;
    totalMonstersInRound = roundCfg.totalMonsters;
    monsterMaxHp = roundCfg.monsterMaxHp;

    spawnedMonsters = 0;
    defeatedMonsters = 0;
    escapedMonsters = 0;
    spawnTimer = 0.0;
    bossSpawned = false;
    miniBossesSpawned = 0; // 리디자인 B-2-17

    // D-1-6: 라운드 시작 시 XP/골드 추적 초기화
    _roundXpGained = 0;
    _roundGoldGained = 0;

    // 라운드 타입에 따라 시간 제한 설정
    roundTimer = 0.0;
    if (roundCfg.monsterType == MonsterType.boss) {
      roundTimeLimit = 300.0; // 보스: 5분
    } else if (roundCfg.monsterType == MonsterType.miniBoss) {
      roundTimeLimit = 180.0; // 미니보스: 3분
    } else {
      roundTimeLimit = 120.0; // 일반: 2분
    }

    monsters.clear();
  }

  void _goToRoundSelect() {
    monsters.clear();
    gameState = GameState.roundSelect;
  }

  void _startNextRound() {
    if (currentRound < totalRoundsInStage) {
      _loadRound(currentRound + 1);
      gameState = GameState.playing;
    } else {
      // 모든 라운드 클리어 (스테이지 클리어)
      _onStageClear();
    }
  }

  // -----------------------------
  // 업데이트 루프
  // -----------------------------
  @override
  void update(double dt) {
    super.update(dt);

    // 에너지 충전 업데이트 (모든 상태에서 지속적으로 실행)
    _updateEnergy();

    switch (gameState) {
      case GameState.loading:
        _updateLoading(dt);
        return;
      case GameState.roundSelect:
        return;
      case GameState.playing:
        _updatePlaying(dt);
        return;
      case GameState.paused:
        // 일시정지 중에는 업데이트 하지 않음
        return;
      case GameState.levelUp:
        // 리디자인 B-2-11/B-2-12: 레벨업 화면 - 젬 자석 타이머만 진행
        if (_xpMagnetTimer > 0) {
          _xpMagnetTimer -= dt;
          _attractAllXpGems();
        }
        return;
      case GameState.roundClear:
        _updateRoundClear(dt);
        return;
      case GameState.augmentSelect:
        // 증강 선택 중 - 업데이트 없음 (탭 입력 대기)
        return;
      case GameState.shopOpen:
        // 리디자인 B-2-16: 상점 화면 - 업데이트 없음
        return;
      case GameState.result:
        return;
    }
  }

  // 에너지 충전 로직 (10분에 1개씩, 최대 50개)
  void _updateEnergy() {
    if (playerEnergy >= playerMaxEnergy) {
      _lastEnergyUpdateTime = DateTime.now();
      return;
    }

    final now = DateTime.now();
    final diff = now.difference(_lastEnergyUpdateTime);

    // 10분마다 1개씩 충전
    final energyToAdd = diff.inMinutes ~/ 10;
    if (energyToAdd > 0) {
      playerEnergy = (playerEnergy + energyToAdd).clamp(0, playerMaxEnergy);
      _lastEnergyUpdateTime = _lastEnergyUpdateTime.add(
        Duration(minutes: energyToAdd * 10),
      );
    }
  }

  void _updateLoading(double dt) {
    _loadingTimer += dt;
    if (_loadingTimer >= _loadingDuration) {
      _loadingTimer = 0.0;
      _goToRoundSelect();
    }
  }

  void _updatePlaying(double dt) {
    if (size.x <= 0 || size.y <= 0) return;

    // 전역 게임 시간 업데이트
    gameTime += dt;

    // 라운드 타이머 업데이트
    roundTimer += dt;

    // 시간 제한 체크
    if (roundTimer >= roundTimeLimit) {
      _onTimeOver();
      return;
    }

    // D-3-5: 슬로우 모션 타이머 감소 (실제 시간 기준)
    if (_slowMotionTimer > 0) _slowMotionTimer = max(0.0, _slowMotionTimer - dt);
    // D-3-5: 슬로우 모션 중 몬스터/투사물 속도를 0.2배로 감소
    final double effectiveDt = _slowMotionTimer > 0 ? dt * 0.2 : dt;
    _updateMonsters(effectiveDt);
    _updateCharacterUnits(effectiveDt); // 캐릭터 유닛 업데이트
    _updateProjectiles(effectiveDt); // 투사물 업데이트
    _updateVfxEffects(dt); // VFX 이펙트 업데이트 (실제 시간 기준)
    _checkCharacterMonsterCollisions(); // 캐릭터-몬스터 충돌 체크
    _updatePriestHeal(dt); // 리디자인 B-2-3: 성직자 성 회복
    _updateMainCharacterDamage(dt); // 리디자인 B-2-6: 메인 캐릭터 피해
    _updateMainCharacterRespawn(dt); // 리디자인 B-2-7: 메인 캐릭터 복활
    _updateXpGems(dt); // 리디자인 B-2-8/B-2-9: XP 젬 업데이트 & 회수
    _updateGoldDrops(); // 리디자인 B-2-15: 골드 드롭 회수
    // D-3-1: 성 피격 점멸 타이머 감소
    if (castleFlashTimer > 0) castleFlashTimer -= dt;
    // 리디자인 B-2-20: 성 바리어 타이머 업데이트
    if (_castleBarrierActive) {
      _castleBarrierTimer -= dt;
      if (_castleBarrierTimer <= 0) {
        _castleBarrierActive = false;
        _castleBarrierTimer = 0.0;
      }
    }
    // 증강 시스템: 타이머 업데이트
    if (_augmentR04Timer > 0) {
      _augmentR04Timer -= dt;
      if (_augmentR04Timer <= 0) { _augmentR04Timer = 0.0; _augmentR04Stacks = 0; }
    }
    if (_augmentL02Active) {
      _augmentL02Timer -= dt;
      if (_augmentL02Timer <= 0) _augmentL02Active = false;
    }
    if (_augmentL03BarrierActive) {
      _augmentL03BarrierTimer -= dt;
      if (_augmentL03BarrierTimer <= 0) _augmentL03BarrierActive = false;
    }

    // 현재 라운드의 몬스터 스폰
    if (spawnedMonsters < totalMonstersInRound) {
      spawnTimer += dt;
      final cfg = kStageConfigs[stageLevel];
      if (cfg != null && currentRound <= cfg.rounds.length) {
        final roundCfg = cfg.rounds[currentRound - 1];
        if (spawnTimer >= roundCfg.spawnInterval) {
          spawnTimer = 0.0;
          // 리디자인 B-2-19: 동시 상한 40체 체크
          if (monsters.length < 40) {
            _spawnMonster();
          }
        }
      }
    }

    // 성 HP가 0이면 게임오버
    if (castleHp <= 0 && gameState == GameState.playing) {
      _onGameOver();
      return;
    }

    // 라운드 클리어 체크: 모든 몬스터가 처리되었고 화면에 몬스터가 없을 때
    // (처치된 몬스터 + 성에 도달한 몬스터 = 전체 몬스터)
    if ((defeatedMonsters + escapedMonsters) >= totalMonstersInRound && monsters.isEmpty) {
      _onRoundClear();
    }
  }

  void _updateRoundClear(double dt) {
    _roundClearTimer += dt;
    // L-04: 시간의 가속 - 인터벌 중 XP 자석 상시 발동
    if (_hasAugment('L-04')) _attractAllXpGems();
    if (_roundClearTimer >= _roundClearDuration) {
      _roundClearTimer = 0.0;
      // 증강 시스템: 라운드 2/4/5 클리어 후 증강 선택 화면
      if (currentRound == 2 || currentRound == 4 || currentRound == 5) {
        _triggerAugmentSelection();
        if (gameState == GameState.augmentSelect) return; // 증강 선택 대기
      }
      // C-11 증강: 라운드 시작 시 성 HP +5
      if (_hasAugment('C-11')) {
        castleHp = min(castleMaxHp, castleHp + 5);
      }
      _startNextRound();
    }
  }

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
              ? _bossSpeed
              : m.type == MonsterType.miniBoss
                  ? _miniBossSpeed
                  : _normalMonsterSpeed;
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

    // 리디자인 B-2-15: 골드 드롭 (C-09 증강: +30% 골드)
    final int baseGold = mType == MonsterType.boss ? 20
        : mType == MonsterType.miniBoss ? 5 : 1;
    final int goldValue = (_augmentGoldMultiplier * baseGold).round();
    goldDrops.add(_GoldDrop(pos: dropPos, goldValue: goldValue));

    // 리디자인 B-2-13: 스킬 게이지 충전 (R-06 증강: +50% 게이지)
    final double baseGauge = mType == MonsterType.boss ? 50.0
        : mType == MonsterType.miniBoss ? 15.0 : 3.0;
    final double gaugeIncrease = baseGauge * _augmentSkillGaugeMultiplier;
    skillGauge = min(100.0, skillGauge + gaugeIncrease);
    if (skillGauge >= 100.0) skillReady = true;
    // L-07: 영혼의 연쇄 - 격파 시 다음 타워 공격 크리티컬 예약
    if (_hasAugment('L-07')) _augmentL07NextCrit = true;
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
      _pendingLevelUp = true;
      // 리디자인 B-2-11: 레벨업 바프 카드 선택 화면으로 전환
      _generateBuffOptions();
      // R-10: 이단 축적 - 레벨업 시 XP 자석 2연속 발동 (2초)
      _xpMagnetTimer = _hasAugment('R-10') ? _xpMagnetDuration * 2 : _xpMagnetDuration;
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
        _castleBarrierTimer = _castleBarrierDuration;
        // D-3-7: 기존 배리어 VFX 제거 후 새 VFX 추가 (중복 방지)
        vfxEffects.removeWhere((v) => v.type == VfxType.barrier);
        vfxEffects.add(_VfxEffect(
          pos: Vector2(castleCenterX, castleCenterY),
          type: VfxType.barrier,
          duration: _castleBarrierDuration,
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
    _pendingLevelUp = false;
    gameState = GameState.playing;
  }

  // 리디자인 B-2-11: 바프 적용 후 캐릭터 스탯 가져오기 (공격력 보정)
  double get _buffedMainAtkMultiplier => pow(1.15, _atkUpCount).toDouble();
  double get _buffedMainAtkIntervalMultiplier => pow(0.90, _spdUpCount).toDouble();
  // L-04: 라운드 인터벌 중 이동속도 400%
  double get _buffedMoveSpeed {
    double speed = _mainCharSpeed * pow(1.20, _moveUpCount).toDouble();
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
  // 속성 시스템: 속성 마스터리 배율 (기본 x1.0, 스택당 +10%)
  double get _elementMasteryMultiplier => 1.0 + 0.1 * _elementMasteryCount;
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

        // 리디자인 B-1-7: 타워 유닛은 고정 위치로 복원 (핸들러가 이동시키므로)
        if (unit.isTower && unit.towerFixedPos != null) {
          unit.pos.setFrom(unit.towerFixedPos!);
        }

        // 리디자인 B-2-5: 메인 캐릭터는 핸들러 이동 취소 후 스틱 이동 적용
        // (핸들러의 공격 처리만 활용, 이동은 스틱으로 덮어씀)
        if (!unit.isTower) {
          _applyMainCharacterMovement(unit, dt);
        }
      }
    }
  }

  // 리디자인 B-2-5: 메인 캐릭터 스틱 이동
  void _applyMainCharacterMovement(_CharacterUnit unit, double dt) {
    if (!_stickActive) return;

    final dx = _stickKnobPos.x - _stickBasePos.x;
    final dy = _stickKnobPos.y - _stickBasePos.y;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist <= _stickDeadzone) return;

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
    if (_priestHealTimer >= _priestHealInterval) {
      _priestHealTimer = 0.0;
      castleHp = min(castleMaxHp, castleHp + _priestHealAmount);
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
          _mainCharRespawning = true; // B-2-7: 복활 카운트다운 시작
          _respawnTimer = _effectiveRespawnDuration; // C-08: 동적 대기시간
          _stickActive = false; // 사망 중 스틱 비활성화
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

    // 적을 향해 이동
    if (distance > swordRange * 0.7) {
      final dir = (target.pos - unit.pos).normalized();
      unit.pos += dir * unit.moveSpeed * moveSpeedBuff * dt;
      // 상단 경계 제한 적용
      unit.pos.y = unit.pos.y.clamp(topBoundary, size.y);
      unit.movingTowardsTarget = true;
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
      // 타겟까지 이동 (사거리 내로, 이동속도 버프 적용)
      final dir = (target.pos - unit.pos).normalized();
      unit.pos += dir * unit.moveSpeed * moveSpeedBuff * dt;
      // 상단 경계 제한 적용
      unit.pos.y = unit.pos.y.clamp(topBoundary, size.y);
      unit.movingTowardsTarget = true;
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
      final dir = (target.pos - unit.pos).normalized();
      unit.pos += dir * unit.moveSpeed * moveSpeedBuff * dt;
      // 상단 경계 제한 적용
      unit.pos.y = unit.pos.y.clamp(topBoundary, size.y);
      unit.movingTowardsTarget = true;
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
      final dir = (target.pos - unit.pos).normalized();
      unit.pos += dir * unit.moveSpeed * moveSpeedBuff * dt;
      // 상단 경계 제한 적용
      unit.pos.y = unit.pos.y.clamp(topBoundary, size.y);
      unit.movingTowardsTarget = true;
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
      final dir = (target.pos - unit.pos).normalized();
      unit.pos += dir * unit.moveSpeed * moveSpeedBuff * dt;
      // 상단 경계 제한 적용
      unit.pos.y = unit.pos.y.clamp(topBoundary, size.y);
      unit.movingTowardsTarget = true;
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

  // 속성 데미지 적용 (_damageMonsterWithElement 사용 권장)
  void _damageMonsterWithElement(_Monster monster, int baseDamage, ElementType attackerElement) {
    final double elementMult = getElementMultiplier(attackerElement, monster.element);
    // 저주 상태이상: 피격 데미지 20% 증가
    final double curseMult = monster.curseTimer > 0 ? 1.2 : 1.0;
    final int finalDamage = (baseDamage * elementMult * curseMult).round();
    _damageMonster(monster, finalDamage);
    // #34 속성UI: 부유 데미지 숫자 생성
    _damageNumbers.add(_DamageNumber(
      pos: Vector2(monster.pos.x, monster.pos.y - 20),
      amount: finalDamage,
      elementMult: elementMult,
      element: attackerElement,
    ));
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

  // -----------------------------
  // 입력 처리 (탭)
  // -----------------------------
  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.localPosition;

    switch (gameState) {
      case GameState.loading:
        // 로딩 상태에서는 탭 무시 (자동 진행)
        break;
      case GameState.roundSelect:
        _handleTapInRoundSelect(pos);
        break;
      case GameState.playing:
        _handleTapInPlaying(pos);
        break;
      case GameState.paused:
        _handleTapInPaused(pos);
        break;
      case GameState.levelUp:
        _handleTapInLevelUp(pos);
        break;
      case GameState.shopOpen:
        _handleTapInShop(pos);
        break;
      case GameState.augmentSelect:
        _handleTapInAugmentSelect(pos);
        break;
      case GameState.roundClear:
        // 라운드 클리어 중에는 탭 무시 (자동 진행)
        break;
      case GameState.result:
        _handleTapInResult(pos);
        break;
    }

    super.onTapDown(event);
  }

  @override
  void onDragStart(DragStartEvent event) {
    final pos = Offset(event.localPosition.x, event.localPosition.y);

    // 리디자인 B-2-4: 플레이 중 스틱 입력 (Designerの固定位置型に合わせる: 左下 80, size.y-110)
    if (gameState == GameState.playing) {
      _stickActive = true;
      _stickBasePos = Vector2(80.0, size.y - 110.0);
      _stickKnobPos = _stickBasePos.clone();
      super.onDragStart(event);
      return;
    }

    // 파티 팝업에서 드래그 시작
    if (gameState == GameState.roundSelect && showPartySelectionPopup) {
      const double popupWidth = 350.0;
      const double popupHeight = 500.0;
      final double popupX = (size.x - popupWidth) / 2;
      final double popupY = (size.y - popupHeight) / 2;
      const double listStartY = 60.0;
      const double bottomButtonHeight = 50.0;
      const double listHeight = popupHeight - listStartY - bottomButtonHeight - 10;

      final listRect = Rect.fromLTWH(
        popupX + 15,
        popupY + listStartY,
        popupWidth - 30,
        listHeight,
      );

      if (listRect.contains(pos)) {
        _partyPopupDragStartY = pos.dy;
      }
    }
    // 캐릭터 도감 영역에서 드래그 시작
    else if (gameState == GameState.roundSelect &&
        currentBottomMenu == BottomMenu.gacha &&
        gachaResults == null) {
      const double collectionStartY = 165.0;
      const double listStartY = collectionStartY + 50;
      const double availableHeight = 600.0 - collectionStartY - 70 - 20;

      if (pos.dy >= listStartY && pos.dy <= listStartY + availableHeight) {
        _dragStartY = pos.dy;
      }
    }
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final delta = event.localDelta;

    // 리디자인 B-2-4: 플레이 중 스틱 노브 업데이트
    if (gameState == GameState.playing && _stickActive) {
      final newKnob = Vector2(
        _stickKnobPos.x + delta.x,
        _stickKnobPos.y + delta.y,
      );
      final dx = newKnob.x - _stickBasePos.x;
      final dy = newKnob.y - _stickBasePos.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist <= _stickOuterRadius) {
        _stickKnobPos = newKnob;
      } else {
        // 외부 반경에서 클램프
        _stickKnobPos = Vector2(
          _stickBasePos.x + (dx / dist) * _stickOuterRadius,
          _stickBasePos.y + (dy / dist) * _stickOuterRadius,
        );
      }
      super.onDragUpdate(event);
      return;
    }

    // 파티 팝업 스크롤
    if (gameState == GameState.roundSelect &&
        showPartySelectionPopup &&
        _partyPopupDragStartY > 0) {
      const double cardHeight = 80.0;
      const double cardSpacing = 10.0;
      const int cardsPerRow = 4;
      const double listStartY = 60.0;
      const double bottomButtonHeight = 50.0;
      const double popupHeight = 500.0;
      final double listHeight = popupHeight - listStartY - bottomButtonHeight - 10;

      // 고유 캐릭터 개수 계산 (중복 제거)
      final uniqueCharacterIds = <String>{};
      for (final character in ownedCharacters) {
        uniqueCharacterIds.add(character.characterId);
      }
      final uniqueCount = uniqueCharacterIds.length;

      final totalRows = (uniqueCount / cardsPerRow).ceil();
      final contentHeight = totalRows * (cardHeight + cardSpacing) + 20;
      final maxScroll = (contentHeight - listHeight).clamp(0.0, double.infinity);

      partyPopupScrollOffset =
          (partyPopupScrollOffset - delta.y).clamp(0.0, maxScroll);
    }
    // 캐릭터 도감 스크롤
    else if (gameState == GameState.roundSelect &&
        currentBottomMenu == BottomMenu.gacha &&
        gachaResults == null &&
        _dragStartY > 0) {
      // 최대 스크롤 계산
      const double cardHeight = 80.0;
      const double cardSpacing = 10.0;
      const int cardsPerRow = 5;
      const double availableHeight = 600.0 - 165.0 - 70 - 20 - 50;

      final allCharacters = CharacterDefinitions.all;
      final totalRows = (allCharacters.length / cardsPerRow).ceil();
      final maxScroll =
          (totalRows * (cardHeight + cardSpacing) - availableHeight + 20)
              .clamp(0.0, double.infinity);

      characterListScrollOffset =
          (characterListScrollOffset - delta.y).clamp(0.0, maxScroll);
    }
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    // 리디자인 B-2-4: 스틱 비활성화
    if (_stickActive) {
      _stickActive = false;
      _stickKnobPos = _stickBasePos.clone();
    }
    _dragStartY = 0.0;
    _partyPopupDragStartY = 0.0;
    super.onDragEnd(event);
  }

  // 라운드 선택 화면: 맵 위 라운드 노드 터치
  void _handleTapInRoundSelect(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);
    const int totalRounds = 10;
    final unlocked = unlockedRoundMax.clamp(1, totalRounds);

    // 파티 선택 팝업이 열려있는 경우
    if (showPartySelectionPopup) {
      _handlePartyPopupTap(offset);
      return;
    }

    // 홈 메뉴에서 파티 슬롯 체크
    if (currentBottomMenu == BottomMenu.home) {
      if (_handlePartySlotTap(offset)) {
        return;
      }
    }

    // 하단 메뉴 버튼 체크
    for (int i = 0; i < 5; i++) {
      final rect = _bottomMenuButtonRect(i);
      if (rect.contains(offset)) {
        _handleBottomMenuTap(i);
        return;
      }
    }

    // 뽑기 메뉴에서의 클릭 처리
    if (currentBottomMenu == BottomMenu.gacha) {
      _handleGachaTap(offset);
      return;
    }

    // God Mode 버튼 체크
    final godModeRect = _godModeButtonRect();
    if (godModeRect.contains(offset)) {
      _toggleGodMode();
      return;
    }

    // 왼쪽 스테이지 변경 버튼 체크
    final leftStageButtonRect = _leftStageButtonRect();
    if (leftStageButtonRect.contains(offset)) {
      if (selectedStageInUI > 1) {
        selectedStageInUI--;
      }
      return;
    }

    // 오른쪽 스테이지 변경 버튼 체크
    final rightStageButtonRect = _rightStageButtonRect();
    if (rightStageButtonRect.contains(offset)) {
      if (selectedStageInUI < 8) {
        selectedStageInUI++;
      }
      return;
    }

    for (int i = 1; i <= totalRounds; i++) {
      final rect = _roundNodeRect(i);
      if (rect.contains(offset)) {
        if (i <= unlocked) {
          _startRound(i);
        }
        break;
      }
    }
  }

  // 파티 슬롯 클릭 처리
  bool _handlePartySlotTap(Offset offset) {
    const double bottomMenuHeight = 70.0;
    const double slotSize = 60.0; // 도감과 동일한 크기
    const double slotSpacing = 10.0; // 도감과 동일한 간격
    final double slotY = size.y - bottomMenuHeight - slotSize - 8.0; // 푸터 바로 위

    for (int i = 0; i < 4; i++) {
      final double slotX = (size.x - (slotSize * 4 + slotSpacing * 3)) / 2 + i * (slotSize + slotSpacing);
      final slotRect = Rect.fromLTWH(slotX, slotY, slotSize, slotSize);

      if (slotRect.contains(offset)) {
        // 슬롯을 클릭하면 팝업 열기
        selectedPartySlotIndex = i;
        showPartySelectionPopup = true;
        return true;
      }
    }
    return false;
  }

  // 파티 팝업 클릭 처리 (그리드 레이아웃)
  void _handlePartyPopupTap(Offset offset) {
    const double popupWidth = 350.0;
    const double popupHeight = 500.0;
    final double popupX = (size.x - popupWidth) / 2;
    final double popupY = (size.y - popupHeight) / 2;

    // 닫기 버튼 체크
    final closeButtonRect = Rect.fromLTWH(popupX + popupWidth - 40, popupY + 10, 30, 30);
    if (closeButtonRect.contains(offset)) {
      showPartySelectionPopup = false;
      selectedPartySlotIndex = -1;
      partyPopupScrollOffset = 0.0;
      return;
    }

    // 제거 버튼 체크 (슬롯에 캐릭터가 있는 경우)
    if (selectedPartySlotIndex >= 0 && partySlots[selectedPartySlotIndex] != null) {
      final removeButtonRect = Rect.fromLTWH(
        popupX + 20,
        popupY + popupHeight - 45,
        popupWidth - 40,
        35,
      );

      if (removeButtonRect.contains(offset)) {
        // 파티에서 제거
        partySlots[selectedPartySlotIndex] = null;
        showPartySelectionPopup = false;
        selectedPartySlotIndex = -1;
        partyPopupScrollOffset = 0.0;
        return;
      }
    }

    // 캐릭터 카드 클릭 체크 (그리드) - 중복 제거된 목록
    const double listStartY = 60.0;
    const double cardWidth = 60.0;
    const double cardHeight = 80.0;
    const double cardSpacing = 10.0;
    const int cardsPerRow = 4;

    // 캐릭터별 개수 계산 및 중복 제거
    final characterMap = <String, List<OwnedCharacter>>{};
    for (final character in ownedCharacters) {
      if (!characterMap.containsKey(character.characterId)) {
        characterMap[character.characterId] = [];
      }
      characterMap[character.characterId]!.add(character);
    }

    final uniqueCharacterIds = characterMap.keys.toList();
    for (int i = 0; i < uniqueCharacterIds.length; i++) {
      final characterId = uniqueCharacterIds[i];
      final characterInstances = characterMap[characterId]!;

      final row = i ~/ cardsPerRow;
      final col = i % cardsPerRow;

      final double x = popupX + 20 + col * (cardWidth + cardSpacing);
      final double y = popupY + listStartY + 10 + row * (cardHeight + cardSpacing) - partyPopupScrollOffset;

      final cardRect = Rect.fromLTWH(x, y, cardWidth, cardHeight);

      if (cardRect.contains(offset)) {
        // 이 캐릭터의 인스턴스 중 파티에 없는 것을 찾기
        OwnedCharacter? characterToAdd;
        bool hasInParty = false;

        for (final instance in characterInstances) {
          if (partySlots.contains(instance.instanceId)) {
            hasInParty = true;
            // 이미 파티에 있는 인스턴스를 클릭한 경우 - 슬롯 교체
            final oldIndex = partySlots.indexOf(instance.instanceId);
            if (oldIndex >= 0 && oldIndex != selectedPartySlotIndex) {
              // 슬롯 교체
              final temp = partySlots[selectedPartySlotIndex];
              partySlots[selectedPartySlotIndex] = instance.instanceId;
              partySlots[oldIndex] = temp;
            }
            break;
          } else if (characterToAdd == null) {
            characterToAdd = instance;
          }
        }

        // 파티에 없는 인스턴스가 있으면 추가
        if (!hasInParty && characterToAdd != null) {
          partySlots[selectedPartySlotIndex] = characterToAdd.instanceId;
        }

        showPartySelectionPopup = false;
        selectedPartySlotIndex = -1;
        partyPopupScrollOffset = 0.0;
        return;
      }
    }

    // 팝업 바깥 클릭 시 닫기
    final popupRect = Rect.fromLTWH(popupX, popupY, popupWidth, popupHeight);
    if (!popupRect.contains(offset)) {
      showPartySelectionPopup = false;
      selectedPartySlotIndex = -1;
      partyPopupScrollOffset = 0.0;
    }
  }

  // 하단 메뉴 탭 처리
  void _handleBottomMenuTap(int index) {
    switch (index) {
      case 0: // 상점
        currentBottomMenu = BottomMenu.shop;
        break;
      case 1: // 인벤토리
        currentBottomMenu = BottomMenu.inventory;
        break;
      case 2: // 홈
        currentBottomMenu = BottomMenu.home;
        break;
      case 3: // 뽑기
        currentBottomMenu = BottomMenu.gacha;
        break;
      case 4: // 설정
        currentBottomMenu = BottomMenu.settings;
        break;
    }
  }

  // 뽑기 화면 탭 처리
  void _handleGachaTap(Offset offset) {
    // 뽑기 결과 표시 중이면 다음 캐릭터로 진행
    if (gachaResults != null && gachaResults!.isNotEmpty) {
      gachaResultIndex++;
      if (gachaResultIndex >= gachaResults!.length) {
        // 모든 결과를 확인했으면 인벤토리에 추가하고 초기화
        for (final character in gachaResults!) {
          final instanceId = '${character.id}_${DateTime.now().millisecondsSinceEpoch}';
          ownedCharacters.add(OwnedCharacter(
            instanceId: instanceId,
            characterId: character.id,
          ));
        }
        gachaResults = null;
        gachaResultIndex = 0;
      }
      return;
    }

    // 단일 뽑기 버튼 체크
    final singleButtonRect = _gachaSingleButtonRect();
    if (singleButtonRect.contains(offset)) {
      final cost = gachaSystem.getSingleSummonCost();
      if (playerGem >= cost) {
        playerGem -= cost;
        final result = gachaSystem.summonOne();
        gachaResults = [result];
        gachaResultIndex = 0;
      }
      return;
    }

    // 10연차 뽑기 버튼 체크
    final tenButtonRect = _gachaTenButtonRect();
    if (tenButtonRect.contains(offset)) {
      final cost = gachaSystem.getTenSummonCost();
      if (playerGem >= cost) {
        playerGem -= cost;
        final results = gachaSystem.summonTen();
        gachaResults = results;
        gachaResultIndex = 0;
      }
      return;
    }
  }

  // 특정 라운드부터 시작
  void _startRound(int roundNumber) {
    _loadStage(selectedStageInUI); // 선택된 스테이지 로드
    _loadRound(roundNumber);
    _applyPartyToCharacterSlots(); // 파티 설정 반영
    _spawnCharacterUnits(); // 캐릭터 유닛 생성
    gameState = GameState.playing;
  }

  // 파티 슬롯에서 캐릭터 유닛을 생성
  void _spawnCharacterUnits() {
    characterUnits.clear(); // 기존 유닛 제거

    // 리디자인: 타워 고정 위치 (성 중심 ±70px 대각선 4곳)
    const towerOffsets = [
      [-70.0, -70.0], // T1: 왼쪽 위
      [ 70.0, -70.0], // T2: 오른쪽 위
      [-70.0,  70.0], // T3: 왼쪽 아래
      [ 70.0,  70.0], // T4: 오른쪽 아래
    ];

    for (int i = 0; i < 5; i++) {
      final instanceId = partySlots[i];
      if (instanceId != null) {
        final character = ownedCharacters.firstWhere(
          (c) => c.instanceId == instanceId,
          orElse: () => OwnedCharacter(instanceId: '', characterId: ''),
        );

        if (character.characterId.isNotEmpty) {
          final definition = CharacterDefinitions.byId(character.characterId);
          final maxHp = definition.baseStats.maxHp * (1 + character.level * 0.1);

          final bool isTower = i > 0;
          Vector2 spawnPos;
          Vector2? fixedPos;

          if (isTower) {
            // 타워: 성 중심에서 ±70px 대각선 고정 위치
            final offset = towerOffsets[i - 1];
            spawnPos = Vector2(castleCenterX + offset[0], castleCenterY + offset[1]);
            fixedPos = spawnPos.clone();
          } else {
            // 메인 캐릭터: 성 오른쪽 옆에서 시작
            spawnPos = Vector2(castleCenterX + 60.0, castleCenterY);
            fixedPos = null;
          }

          final unit = _CharacterUnit(
            instanceId: instanceId,
            definition: definition,
            level: character.level,
            pos: spawnPos,
            currentHp: maxHp,
            maxHp: maxHp,
            isTower: isTower,
            towerFixedPos: fixedPos,
          );

          characterUnits.add(unit);
        }
      }
    }
  }

  // 파티 슬롯 설정을 게임 캐릭터 슬롯에 반영
  void _applyPartyToCharacterSlots() {
    // 리디자인: 5슬롯 (0=메인, 1-4=타워)
    for (int i = 0; i < 5; i++) {
      if (i >= characterSlots.length) break;

      final instanceId = partySlots[i];
      if (instanceId != null) {
        // 파티에 캐릭터가 설정되어 있음
        final character = ownedCharacters.firstWhere(
          (c) => c.instanceId == instanceId,
          orElse: () => ownedCharacters.isNotEmpty ? ownedCharacters.first : OwnedCharacter(instanceId: '', characterId: ''),
        );

        if (character.characterId.isNotEmpty) {
          final definition = CharacterDefinitions.byId(character.characterId);
          characterSlots[i].hasCharacter = true;
          characterSlots[i].characterName = definition.name;
          characterSlots[i].skillReady = true;
        } else {
          // 캐릭터를 찾지 못한 경우
          characterSlots[i].hasCharacter = false;
          characterSlots[i].characterName = '';
          characterSlots[i].skillReady = false;
        }
      } else {
        // 파티에 캐릭터가 설정되지 않음
        characterSlots[i].hasCharacter = false;
        characterSlots[i].characterName = '';
        characterSlots[i].skillReady = false;
      }
    }
  }

  // 플레이 중: 몬스터 공격 또는 일시정지 버튼 또는 캐릭터 스킬
  void _handleTapInPlaying(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);

    // 일시정지 버튼 체크 (우측 상단)
    final pauseButtonRect = _pauseButtonRect();
    if (pauseButtonRect.contains(offset)) {
      gameState = GameState.paused;
      return;
    }

    // 리디자인 B-2-14: 스킬 버튼 체크 (우측 하단 80px 원형)
    if (skillReady) {
      final skillBtnCenter = Offset(size.x - 60, size.y - 110);
      final dist = (tapPos - Vector2(skillBtnCenter.dx, skillBtnCenter.dy)).length;
      if (dist <= 40.0) {
        _fireUltimateSkill();
        return;
      }
    }

    // 캐릭터 슬롯 체크 (스킬 사용)
    for (int i = 0; i < characterSlots.length; i++) {
      final slotRect = _characterSlotRect(i);
      if (slotRect.contains(offset)) {
        _handleCharacterSlotTap(i);
        return;
      }
    }

    // 몬스터 공격
    for (var i = 0; i < monsters.length; i++) {
      final m = monsters[i];
      if (_isPointInsideMonster(m, tapPos)) {
        m.hp = max(0, m.hp - weaponDamage);
        if (m.hp <= 0) {
          _killMonsterAtIndex(i);
        }
        break;
      }
    }
  }

  // 캐릭터 슬롯 클릭 처리 (스킬 사용)
  void _handleCharacterSlotTap(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= characterSlots.length) return;

    final slot = characterSlots[slotIndex];

    // 캐릭터가 있고 스킬이 준비된 경우에만 스킬 사용
    if (slot.hasCharacter && slot.skillReady) {
      _useCharacterSkill(slotIndex);
    }
  }

  // 캐릭터 스킬 사용 (프로토타입: 화면의 모든 몬스터에게 데미지)
  void _useCharacterSkill(int slotIndex) {
    final slot = characterSlots[slotIndex];

    // 스킬 효과: 모든 몬스터에게 3 데미지
    const int skillDamage = 3;
    int damageCount = 0;

    for (var i = monsters.length - 1; i >= 0; i--) {
      final m = monsters[i];
      m.hp = max(0, m.hp - skillDamage);
      if (m.hp <= 0) {
        _killMonsterAtIndex(i);
      }
      damageCount++;
    }

    // 스킬 사용 후 쿨다운 (프로토타입: 즉시 재사용 불가)
    slot.skillReady = false;

    // 5초 후 스킬 재사용 가능 (실제로는 타이머 필요, 지금은 간단히 표시만)
    // TODO: 실제 쿨다운 타이머 구현
    Future.delayed(const Duration(seconds: 5), () {
      if (slotIndex < characterSlots.length) {
        characterSlots[slotIndex].skillReady = true;
      }
    });

    print('캐릭터 ${slotIndex + 1} 스킬 사용! $damageCount 마리의 몬스터에게 데미지');
  }

  // 일시정지 화면: "재개 / 라운드 선택 / 재시작"
  // 리디자인 B-2-16: 상점 화면 탭 처리
  // 상점 UI 버튼 위치는 Designer(D-2-2) 구현과 맞춰야 함
  // 임시: 화면 하단 "계속" 영역을 탭하면 상점 종료
  // 증강 선택 화면 탭 처리 - 화면 1/3 영역 분할
  void _handleTapInAugmentSelect(Vector2 tapPos) {
    if (_augmentOptions.isEmpty) {
      // 선택지 없으면 게임 재개
      if (_hasAugment('C-11')) castleHp = min(castleMaxHp, castleHp + 5);
      _startNextRound();
      return;
    }
    final double cardW = size.x / 3;
    final int idx = (tapPos.x / cardW).floor().clamp(0, _augmentOptions.length - 1);
    _applyAugment(_augmentOptions[idx]);
    // 증강 선택 후 라운드 시작
    if (_hasAugment('C-11')) castleHp = min(castleMaxHp, castleHp + 5);
    _startNextRound();
  }

  void _handleTapInShop(Vector2 tapPos) {
    // 화면 하단 20% 탭 = 상점 나가기 (계속 버튼 임시 위치)
    if (tapPos.y > size.y * 0.8) {
      _leaveShop();
    }
    // 상점 아이템 탭 영역 (Designer D-2-2에서 정확한 위치 구현)
    // 임시 구현: 화면 Y 위치에 따라 아이템 선택
    else if (tapPos.y > size.y * 0.3 && tapPos.y < size.y * 0.5) {
      _buyShopItem(ShopItemType.castleMaxHpUp);
    } else if (tapPos.y > size.y * 0.5 && tapPos.y < size.y * 0.65) {
      _buyShopItem(ShopItemType.towerPowerUp);
    } else if (tapPos.y > size.y * 0.65 && tapPos.y < size.y * 0.8) {
      _buyShopItem(ShopItemType.mainCharHpUp);
    }
  }

  // 리디자인 B-2-11: 레벨업 화면 탭 처리 - 바프 카드 선택
  // 카드 좌표는 _renderLevelUpUI 와 동기화
  void _handleTapInLevelUp(Vector2 tapPos) {
    if (_buffOptions.isEmpty) return;
    const double cardW = 100.0;
    const double cardH = 150.0;
    const double cardGap = 10.0;
    final double totalW = 3 * cardW + 2 * cardGap;
    final double startX = (size.x - totalW) / 2;
    final double cardY = size.y * 0.30;

    for (int i = 0; i < _buffOptions.length && i < 3; i++) {
      final double cx = startX + i * (cardW + cardGap);
      final cardRect = Rect.fromLTWH(cx, cardY, cardW, cardH);
      if (cardRect.contains(Offset(tapPos.x, tapPos.y))) {
        _applyBuff(_buffOptions[i]);
        return;
      }
    }
  }

  void _handleTapInPaused(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);

    final resumeRect = _pauseResumeButtonRect();
    final roundSelectRect = _pauseRoundSelectButtonRect();
    final retryRect = _pauseRetryButtonRect();

    if (resumeRect.contains(offset)) {
      gameState = GameState.playing;
      return;
    }

    if (roundSelectRect.contains(offset)) {
      _goToRoundSelect();
      return;
    }

    if (retryRect.contains(offset)) {
      _startRound(currentRound);
      return;
    }
  }

  // 결과 화면: "다시하기 / 라운드 선택 / 다음 라운드"
  void _handleTapInResult(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);

    final retryRect = _resultRetryButtonRect();
    final roundSelectRect = _resultRoundSelectButtonRect();
    final nextRect = _resultNextRoundButtonRect();

    if (retryRect.contains(offset)) {
      _startRound(currentRound);
      return;
    }

    if (roundSelectRect.contains(offset)) {
      _goToRoundSelect();
      return;
    }

    final nextRound = currentRound + 1;
    final canGoNext = _lastStageClear && nextRound <= totalRoundsInStage;

    if (canGoNext && nextRect.contains(offset)) {
      if (nextRound > unlockedRoundMax) {
        unlockedRoundMax = nextRound;
      }
      _startRound(nextRound);
    }
  }

  // -----------------------------
  // 버튼 Rect (일시정지 버튼)
  // -----------------------------
  Rect _pauseButtonRect() {
    const double buttonSize = 35.0; // 작은 버튼
    const double marginTop = 15.0;
    const double marginSide = 20.0;

    // 스테이지-라운드 표시 오른쪽에 배치
    // 스테이지-라운드는 (size.x - marginSide - 30)에 위치하므로 그 오른쪽에 배치
    final double x = this.size.x - marginSide - 10;
    final double y = marginTop - (buttonSize / 2); // 중앙 정렬

    return Rect.fromLTWH(x, y, buttonSize, buttonSize);
  }

  // -----------------------------
  // 캐릭터 슬롯 Rect
  // -----------------------------
  Rect _characterSlotRect(int slotIndex) {
    const double slotSize = 50.0;
    const double slotSpacing = 10.0;
    const double slotPadding = 10.0;

    const totalWidth = (slotSize * 4) + (slotSpacing * 3);
    final startX = (size.x - totalWidth) / 2;
    final slotY = _castleRect.top + slotPadding;

    final x = startX + (slotIndex * (slotSize + slotSpacing));
    return Rect.fromLTWH(x, slotY, slotSize, slotSize);
  }

  // -----------------------------
  // 버튼 Rect (일시정지 화면)
  // -----------------------------
  Rect _pauseResumeButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.50;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _pauseRoundSelectButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.50 + 52;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _pauseRetryButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.50 + 52 * 2;
    return Rect.fromLTWH(x, y, width, height);
  }

  // -----------------------------
  // 버튼 Rect (결과 화면)
  // -----------------------------
  Rect _resultRetryButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.55;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _resultRoundSelectButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.55 + 52;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _resultNextRoundButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.55 + 52 * 2;
    return Rect.fromLTWH(x, y, width, height);
  }

  // -----------------------------
  // 캔디크러쉬 사가 스타일: 사각형 타일 배치 (2열)
  // -----------------------------
  Offset _roundNodeCenter(int roundIndex) {
    const double topMargin = 140.0; // 네비게이션 바(60) + 타이틀 박스(50) + 여백(30)
    const double tileSize = 70.0; // 타일 크기
    const double horizontalSpacing = 15.0; // 좌우 간격
    const double verticalSpacing = 15.0; // 상하 간격

    final double centerX = size.x / 2;

    // 보스 라운드(10)는 맨 밑 중앙에 배치
    if (roundIndex == 10) {
      final double y = topMargin + (3 * (tileSize + verticalSpacing)) + tileSize / 2;
      return Offset(centerX, y);
    }

    // 1-9 라운드: 3열 배치 (3x3 그리드)
    final int row = (roundIndex - 1) ~/ 3; // 0, 1, 2 행
    final int col = (roundIndex - 1) % 3; // 0, 1, 2 열

    // 3개 타일의 전체 너비 계산
    final double totalWidth = (tileSize * 3) + (horizontalSpacing * 2);
    final double startX = centerX - totalWidth / 2 + tileSize / 2;

    final double x = startX + (col * (tileSize + horizontalSpacing));
    final double y = topMargin + (row * (tileSize + verticalSpacing)) + tileSize / 2;

    return Offset(x, y);
  }

  Rect _roundNodeRect(int roundIndex) {
    final center = _roundNodeCenter(roundIndex);
    const double tileSize = 70.0;
    return Rect.fromCenter(center: center, width: tileSize, height: tileSize);
  }

  // God Mode 버튼 Rect (우측 하단, 메뉴 바로 위)
  Rect _godModeButtonRect() {
    const double width = 70;
    const double height = 30;
    final double x = size.x - width - 10;
    // 파티 슬롯과 겹치지 않도록 더 위로 올림
    final double y = size.y - _bottomMenuHeight - height - 85; // 85px 여유 (파티 슬롯 높이 + 여유 공간)
    return Rect.fromLTWH(x, y, width, height);
  }

  // 왼쪽 스테이지 변경 버튼 Rect
  Rect _leftStageButtonRect() {
    const double width = 35.0;
    const double height = 35.0;
    const double x = 15.0;
    const double navBarHeight = 60.0;
    const double titleBoxHeight = 50.0;
    final double y = navBarHeight + (titleBoxHeight - height) / 2; // 타이틀 박스 중앙
    return Rect.fromLTWH(x, y, width, height);
  }

  // 오른쪽 스테이지 변경 버튼 Rect
  Rect _rightStageButtonRect() {
    const double width = 35.0;
    const double height = 35.0;
    final double x = size.x - width - 15;
    const double navBarHeight = 60.0;
    const double titleBoxHeight = 50.0;
    final double y = navBarHeight + (titleBoxHeight - height) / 2; // 타이틀 박스 중앙
    return Rect.fromLTWH(x, y, width, height);
  }

  // God Mode 토글 함수
  void _toggleGodMode() {
    _godModeEnabled = !_godModeEnabled;

    if (_godModeEnabled) {
      // 모든 라운드 언락
      unlockedRoundMax = 10;

      // 모든 캐릭터 슬롯 활성화 및 스킬 준비 완료
      for (var slot in characterSlots) {
        slot.hasCharacter = true;
        slot.skillReady = true;
      }

      // 무한 리소스
      playerGold = 999999;
      playerGem = 999999;
      playerEnergy = playerMaxEnergy;
    }
    // God Mode를 끄면 원래 상태로 돌아가는 것은 구현하지 않음
    // (테스트 목적이므로 한번 켜면 계속 유지)
  }

  // -----------------------------
  // 하단 메뉴 버튼 Rect
  // -----------------------------
  static const double _bottomMenuHeight = 70.0;
  static const double _bottomMenuIconSize = 30.0;

  Rect _bottomMenuRect() {
    return Rect.fromLTWH(0, size.y - _bottomMenuHeight, size.x, _bottomMenuHeight);
  }

  Rect _bottomMenuButtonRect(int index) {
    const int totalButtons = 5;
    final buttonWidth = size.x / totalButtons;
    final x = index * buttonWidth;
    final y = size.y - _bottomMenuHeight;
    return Rect.fromLTWH(x, y, buttonWidth, _bottomMenuHeight);
  }

  // -----------------------------
  // 렌더링
  // -----------------------------
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) return;

    // 라운드 선택 맵: 게임 플레이 화면 없이 흰 배경 + 맵만
    if (gameState == GameState.roundSelect) {
      _renderRoundSelectBackground(canvas);
      _renderRoundSelectOverlay(canvas);
      return;
    }

    // 로딩 화면: 순수 검은 배경
    if (gameState == GameState.loading) {
      _renderLoadingScreen(canvas);
      return;
    }

    // 나머지(플레이, 일시정지, 결과)는 게임 배경 + 성/몬스터 + 오버레이
    _renderBackground(canvas);
    _renderCastle(canvas);
    _renderCharacterUnits(canvas); // 캐릭터 유닛 렌더링
    _renderProjectiles(canvas); // 투사물 렌더링
    _renderVfxEffects(canvas); // VFX 이펙트 렌더링
    _renderMonsters(canvas);
    _renderXpGems(canvas);          // D-3-2: XP 젬
    _renderXpMagnetEffect(canvas);  // D-3-4: XP 마그넷 연출
    _renderGoldDrops(canvas);       // D-3-3: 골드 코인
    _renderStageProgress(canvas);
    _renderWeaponInfo(canvas);
    _renderHUD(canvas); // D-1-1: 상단 HUD

    // 플레이/라운드 클리어 중 하단 UI (스틱, 스킬, 골드) 표시
    if (gameState == GameState.playing || gameState == GameState.roundClear) {
      if (gameState == GameState.playing) {
        _renderPauseButton(canvas);
        _renderVirtualStick(canvas); // D-1-3: 버추얼 스틱 UI
      }
      _renderGoldDisplay(canvas);  // D-1-5: 골드 표시 UI
      _renderSkillButton(canvas);  // D-1-4: 스킬 버튼 UI
    }

    // D-2-4: 복활 카운트다운 오버레이
    if (_mainCharRespawning && _respawnTimer > 0) {
      _renderReviveCountdown(canvas, _respawnTimer);
    }

    // 리디자인 B-2-11: 레벨업 화면 오버레이 (Designer D-2-1 담당)
    if (gameState == GameState.levelUp && _buffOptions.isNotEmpty) {
      _renderLevelUpUI(canvas);
    }

    _renderGameStateOverlay(canvas);
  }

  // D-2-1: 레벨업 바프 카드 UI (Violet Theme)
  // 카드 좌표는 _handleTapInLevelUp 과 동기화 (cardW=100, cardH=150, gap=10, cardY=0.30)
  void _renderLevelUpUI(Canvas canvas) {
    // 반투명 보라색 배경 오버레이
    final bgPaint = Paint()..color = const Color(0xDD0A0014);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // 상단 장식 바 (바이올렛)
    final decorPaint = Paint()..color = const Color(0xFF7C3AED);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 4), decorPaint);

    // "LEVEL UP!" 제목
    _drawCenteredText(
      canvas,
      'LEVEL UP!',
      Offset(size.x / 2, size.y * 0.14),
      fontSize: 30,
      color: const Color(0xFFFFD700),
    );

    // 레벨 표시
    _drawCenteredText(
      canvas,
      'Lv.$playerCharLevel',
      Offset(size.x / 2, size.y * 0.22),
      fontSize: 17,
      color: const Color(0xFFE0CCFF),
    );

    // 바프 카드 3장 — _handleTapInLevelUp 좌표와 동기화
    const double cardW = 100.0;
    const double cardH = 150.0;
    const double cardGap = 10.0;
    final double totalW = 3 * cardW + 2 * cardGap;
    final double startX = (size.x - totalW) / 2;
    final double cardY = size.y * 0.30;

    for (int i = 0; i < _buffOptions.length && i < 3; i++) {
      final buff = _buffOptions[i];
      final double cx = startX + i * (cardW + cardGap);
      final cardRect = Rect.fromLTWH(cx, cardY, cardW, cardH);

      // 카드 배경 (다크 바이올렛)
      final cardPaint = Paint()..color = const Color(0xFF1E1040);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(12)),
        cardPaint,
      );

      // 카드 테두리 (보라색 글로우)
      final borderPaint = Paint()
        ..color = const Color(0xFF9B59F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(12)),
        borderPaint,
      );

      // 상단 색상 헤더 바
      final headerRect = Rect.fromLTWH(cx, cardY, cardW, 26);
      final headerPaint = Paint()..color = const Color(0xFF7C3AED);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          headerRect,
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
        ),
        headerPaint,
      );

      // 헤더 아이콘
      _drawCenteredText(
        canvas,
        _buffTypeIcon(buff),
        Offset(cx + cardW / 2, cardY + 13),
        fontSize: 14,
      );

      // 바프 이름
      _drawCenteredText(
        canvas,
        _buffTypeName(buff),
        Offset(cx + cardW / 2, cardY + 48),
        fontSize: 11,
        color: const Color(0xFFFFFFFF),
      );

      // 구분선
      final divPaint = Paint()
        ..color = const Color(0xFF4A3A6A)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(cx + 10, cardY + 62),
        Offset(cx + cardW - 10, cardY + 62),
        divPaint,
      );

      // 바프 설명
      _drawCenteredText(
        canvas,
        _buffTypeDesc(buff),
        Offset(cx + cardW / 2, cardY + 84),
        fontSize: 9,
        color: const Color(0xFFBBAEFF),
        multiLine: true,
      );

      // 스택 카운트 배지
      final stackTxt = _buffStackText(buff);
      if (stackTxt.isNotEmpty) {
        final stackBgPaint = Paint()..color = const Color(0xFF3D1F6E);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + cardW / 2 - 22, cardY + 129, 44, 14),
            const Radius.circular(7),
          ),
          stackBgPaint,
        );
        _drawCenteredText(
          canvas,
          stackTxt,
          Offset(cx + cardW / 2, cardY + 136),
          fontSize: 9,
          color: const Color(0xFFFFD700),
        );
      }
    }

    // 탭 안내 (하단)
    _drawCenteredText(
      canvas,
      'カードをタップして選択',
      Offset(size.x / 2, size.y * 0.85),
      fontSize: 13,
      color: const Color(0x99CCAAFF),
    );
  }

  // D-2-1 헬퍼: 바프 타입 아이콘
  String _buffTypeIcon(BuffType buff) {
    switch (buff) {
      case BuffType.attackUp:             return '⚔';
      case BuffType.attackSpdUp:          return '⚡';
      case BuffType.moveSpeedUp:          return '💨';
      case BuffType.rangeUp:              return '🎯';
      case BuffType.castleRepair:         return '🏰';
      case BuffType.towerPowerUp:         return '🗼';
      case BuffType.xpMagnetUp:           return '🧲';
      case BuffType.castleBarrier:        return '🛡';
      case BuffType.elementFireGrant:     return '🔥';
      case BuffType.elementWaterGrant:    return '💧';
      case BuffType.elementEarthGrant:    return '🌿';
      case BuffType.elementElectricGrant: return '⚡';
      case BuffType.elementDarkGrant:     return '🌑';
      case BuffType.elementMastery:       return '✨';
    }
  }

  // D-2-1 헬퍼: 스택 카운트 텍스트 (무제한 바프는 빈 문자열)
  String _buffStackText(BuffType buff) {
    switch (buff) {
      case BuffType.attackUp:       return '$_atkUpCount / 5';
      case BuffType.attackSpdUp:    return '$_spdUpCount / 5';
      case BuffType.moveSpeedUp:    return '$_moveUpCount / 3';
      case BuffType.rangeUp:        return '$_rangeUpCount / 3';
      case BuffType.towerPowerUp:   return '$_towerUpCount / 5';
      case BuffType.xpMagnetUp:     return '$_magnetCount / 3';
      case BuffType.elementMastery: return '$_elementMasteryCount / 3';
      default:                      return '';
    }
  }

  // 바프 이름 표시
  String _buffTypeName(BuffType buff) {
    switch (buff) {
      case BuffType.attackUp: return 'ATK UP';
      case BuffType.attackSpdUp: return 'SPD UP';
      case BuffType.moveSpeedUp: return 'MOVE UP';
      case BuffType.rangeUp: return 'RANGE UP';
      case BuffType.castleRepair: return 'REPAIR';
      case BuffType.towerPowerUp: return 'TOWER UP';
      case BuffType.xpMagnetUp: return 'MAGNET';
      case BuffType.castleBarrier: return 'BARRIER';
      case BuffType.elementFireGrant: return '🔥 FIRE';
      case BuffType.elementWaterGrant: return '💧 WATER';
      case BuffType.elementEarthGrant: return '🌿 EARTH';
      case BuffType.elementElectricGrant: return '⚡ ELECTRIC';
      case BuffType.elementDarkGrant: return '🌑 DARK';
      case BuffType.elementMastery: return 'ELEM MASTERY';
    }
  }

  // 바프 설명 표시
  String _buffTypeDesc(BuffType buff) {
    switch (buff) {
      case BuffType.attackUp: return 'ATK +15%\n(max 5)';
      case BuffType.attackSpdUp: return 'Interval -10%\n(max 5)';
      case BuffType.moveSpeedUp: return 'Speed +20%\n(max 3)';
      case BuffType.rangeUp: return 'Range +15%\n(max 3)';
      case BuffType.castleRepair: return 'Castle HP +20';
      case BuffType.towerPowerUp: return 'Tower ATK +10%\n(max 5)';
      case BuffType.xpMagnetUp: return 'XP Radius +15px\n(max 3)';
      case BuffType.castleBarrier: return '10s Barrier';
      case BuffType.elementFireGrant: return '화염 속성 부여\n(상덮어쓰기)';
      case BuffType.elementWaterGrant: return '수빙 속성 부여\n(상덮어쓰기)';
      case BuffType.elementEarthGrant: return '대지 속성 부여\n(상덮어쓰기)';
      case BuffType.elementElectricGrant: return '번개 속성 부여\n(상덮어쓰기)';
      case BuffType.elementDarkGrant: return '암흑 속성 부여\n(상덮어쓰기)';
      case BuffType.elementMastery: return '속성 보너스\n+10% (max 3)';
    }
  }

  void _renderBackground(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF202020);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
  }

  void _renderRoundSelectBackground(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
  }

  void _renderLoadingScreen(Canvas canvas) {
    // 완전 검은 배경
    final paint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
    _renderLoadingOverlay(canvas);
  }

  // 리디자인: 성을 화면 중앙 80×80px 정사각형으로 변경
  Rect get _castleRect => Rect.fromCenter(
    center: Offset(size.x / 2, size.y / 2),
    width: castleHeight,
    height: castleHeight,
  );

  // D-4-1: 새 디자인 — 화면 중앙 80×80px 성 스프라이트 (HP 3단계 시각 변화)
  void _renderCastle(Canvas canvas) {
    final double cx = castleCenterX;
    final double cy = castleCenterY;

    // HP 비율에 따른 3단계 색상
    final double hpRatio =
        castleMaxHp == 0 ? 0 : (castleHp / castleMaxHp).clamp(0.0, 1.0);
    final Color castleBaseColor;
    final Color castleRoofColor;
    if (hpRatio > 0.66) {
      castleBaseColor = const Color(0xFF546E7A); // 양호: 블루그레이
      castleRoofColor = const Color(0xFF37474F);
    } else if (hpRatio > 0.33) {
      castleBaseColor = const Color(0xFF6D4C41); // 손상: 갈색
      castleRoofColor = const Color(0xFF4E342E);
    } else {
      castleBaseColor = const Color(0xFF7B3535); // 위기: 어두운 빨강
      castleRoofColor = const Color(0xFF5D2626);
    }

    if (castleImageLoaded && castleImage != null) {
      // D-4-1: 참조 에셋 스프라이트로 성 렌더링
      final srcRect = Rect.fromLTWH(
        0, 0,
        castleImage!.width.toDouble(),
        castleImage!.height.toDouble(),
      );
      // HP 비율에 따른 색조 오버레이 알파
      final double tintAlpha = hpRatio > 0.66
          ? 0.0    // 양호: 틴트 없음
          : hpRatio > 0.33
              ? 0.2  // 손상: 갈색 틴트
              : 0.4; // 위기: 빨간 틴트
      canvas.drawImageRect(castleImage!, srcRect, _castleRect, Paint());
      if (tintAlpha > 0) {
        final tintColor = hpRatio > 0.33
            ? Color.fromRGBO(109, 76, 65, tintAlpha)    // 갈색
            : Color.fromRGBO(123, 53, 53, tintAlpha);   // 어두운 빨강
        canvas.drawRRect(
          RRect.fromRectAndRadius(_castleRect, const Radius.circular(4)),
          Paint()..color = tintColor,
        );
      }
    } else {
      // 폴백: Canvas 절차적 드로잉
      final castleBodyPaint = Paint()..color = castleBaseColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(_castleRect, const Radius.circular(6)),
        castleBodyPaint,
      );

      // 성문 (하단 중앙 아치형)
      const double gateW = 20.0;
      const double gateH = 26.0;
      final gatePaint = Paint()..color = const Color(0xFF1A1A1A);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - gateW / 2, _castleRect.bottom - gateH, gateW, gateH),
          topLeft: const Radius.circular(10),
          topRight: const Radius.circular(10),
        ),
        gatePaint,
      );

      // 흉벽 (상단 4개 돌출부)
      final crenelPaint = Paint()..color = castleRoofColor;
      for (final xPos in [
        _castleRect.left + 4.0,
        _castleRect.left + 18.0,
        _castleRect.right - 28.0,
        _castleRect.right - 12.0,
      ]) {
        canvas.drawRect(
          Rect.fromLTWH(xPos, _castleRect.top - 9, 8, 11),
          crenelPaint,
        );
      }

      // 창문 (좌우, 황금색 반투명)
      final windowPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6);
      for (final wc in [Offset(cx - 18, cy - 10), Offset(cx + 18, cy - 10)]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: wc, width: 10, height: 12),
            const Radius.circular(5),
          ),
          windowPaint,
        );
      }

      // 외곽 테두리
      final borderPaint = Paint()
        ..color = const Color(0x88FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(_castleRect, const Radius.circular(6)),
        borderPaint,
      );
    }

    // 위기 상태 균열
    if (hpRatio <= 0.33 && castleHp > 0) {
      final crackPaint = Paint()
        ..color = const Color(0xAAFF5252)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(cx - 15, _castleRect.top + 10),
        Offset(cx - 5, _castleRect.top + 30),
        crackPaint,
      );
      canvas.drawLine(
        Offset(cx + 10, _castleRect.top + 15),
        Offset(cx + 20, _castleRect.top + 35),
        crackPaint,
      );
    }

    // D-3-1: 성 피격 점멸 연출 (castleFlashTimer > 0일 때 빨간 오버레이)
    if (castleFlashTimer > 0) {
      // 0.2초 동안 알파가 점진적으로 줄어드는 빨간 점멸
      final double flashAlpha = (castleFlashTimer / 0.2).clamp(0.0, 1.0) * 0.6;
      final flashPaint = Paint()
        ..color = Color.fromRGBO(244, 67, 54, flashAlpha); // hpRed
      canvas.drawRRect(
        RRect.fromRectAndRadius(_castleRect, const Radius.circular(6)),
        flashPaint,
      );
    }

    // 타워 슬롯 렌더링 (D-4-2)
    _renderTowerSlots(canvas);

    // 성 HP 바 렌더링 (D-1-2)
    _renderCastleHP(canvas);
  }

  // 캐릭터 슬롯 렌더링
  void _renderCharacterSlots(Canvas canvas) {
    for (int i = 0; i < characterSlots.length; i++) {
      final slot = characterSlots[i];
      final rect = _characterSlotRect(i);

      if (slot.hasCharacter && i < partySlots.length && partySlots[i] != null) {
        // 파티에서 캐릭터 정보 가져오기
        final instanceId = partySlots[i]!;
        final character = ownedCharacters.firstWhere(
          (c) => c.instanceId == instanceId,
          orElse: () => ownedCharacters.isNotEmpty
              ? ownedCharacters.first
              : OwnedCharacter(instanceId: '', characterId: ''),
        );

        if (character.characterId.isNotEmpty) {
          final definition = CharacterDefinitions.byId(character.characterId);

          // 랭크 색상 배경 (30% 투명도)
          final bgColor = Color(definition.rank.color).withOpacity(0.3);
          final bgPaint = Paint()..color = bgColor;

          // 테두리 색상 (스킬 준비 상태에 따라)
          final borderColor = slot.skillReady
              ? const Color(0xFF00E676) // 스킬 준비: 초록색
              : Color(definition.rank.color); // 기본: 랭크 색상
          final borderPaint = Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

          final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
          canvas.drawRRect(rrect, bgPaint);
          canvas.drawRRect(rrect, borderPaint);

          // 역할 이모지 중앙에 크게 표시
          _drawCenteredText(
            canvas,
            definition.role.emoji,
            Offset(rect.center.dx, rect.center.dy - 2),
            fontSize: 28,
            color: const Color(0xFFFFFFFF),
          );

          // 랭크 배지 (좌측 상단)
          final rankBadgeRect = Rect.fromLTWH(rect.left + 2, rect.top + 2, 16, 12);
          final rankBadgePaint = Paint()..color = Color(definition.rank.color);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rankBadgeRect, const Radius.circular(2)),
            rankBadgePaint,
          );
          _drawCenteredText(
            canvas,
            definition.rank.displayName,
            Offset(rankBadgeRect.center.dx, rankBadgeRect.center.dy),
            fontSize: 8,
            color: const Color(0xFFFFFFFF),
          );

          // 레벨 배지 (우측 하단)
          final levelText = 'Lv.${character.level}';
          final levelBadgeWidth = levelText.length * 5.0 + 4;
          final levelBadgeRect = Rect.fromLTWH(
            rect.right - levelBadgeWidth - 2,
            rect.bottom - 14,
            levelBadgeWidth,
            12,
          );
          final levelBadgePaint = Paint()..color = const Color(0xCC000000);
          canvas.drawRRect(
            RRect.fromRectAndRadius(levelBadgeRect, const Radius.circular(2)),
            levelBadgePaint,
          );
          _drawCenteredText(
            canvas,
            levelText,
            Offset(levelBadgeRect.center.dx, levelBadgeRect.center.dy),
            fontSize: 8,
            color: const Color(0xFFFFFFFF),
          );

          // 스킬 준비 표시 (준비되면 테두리가 초록색으로 변경됨)
          if (slot.skillReady) {
            _drawCenteredText(
              canvas,
              '✨',
              Offset(rect.left + 10, rect.top + 10),
              fontSize: 12,
              color: const Color(0xFF00E676),
            );
          }
        }
      } else if (slot.hasCharacter) {
        // 파티 슬롯에 없지만 hasCharacter가 true인 경우 (기본 표시)
        final bgPaint = Paint()..color = const Color(0xFF37474F);
        final borderPaint = Paint()
          ..color = slot.skillReady
              ? const Color(0xFF00E676)
              : const Color(0xFF90A4AE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawRect(rect, bgPaint);
        canvas.drawRect(rect, borderPaint);

        _drawCenteredText(
          canvas,
          '🛡️',
          Offset(rect.center.dx, rect.center.dy - 8),
          fontSize: 24,
          color: const Color(0xFFFFFFFF),
        );

        if (slot.skillReady) {
          _drawCenteredText(
            canvas,
            '✨',
            Offset(rect.center.dx, rect.bottom - 12),
            fontSize: 12,
            color: const Color(0xFF00E676),
          );
        }
      } else {
        // 캐릭터 없음: 자물쇠 아이콘 (잠금 상태)
        final bgPaint = Paint()..color = const Color(0xFF212121);
        final borderPaint = Paint()
          ..color = const Color(0xFF424242)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawRect(rect, bgPaint);
        canvas.drawRect(rect, borderPaint);

        _drawCenteredText(
          canvas,
          '🔒',
          Offset(rect.center.dx, rect.center.dy),
          fontSize: 20,
          color: const Color(0xFF616161),
        );
      }
    }
  }

  void _renderMonsters(Canvas canvas) {
    const double hpBarWidth = 24.0;
    const double hpBarHeight = 4.0;
    const double hpBarMargin = 4.0;

    for (final m in monsters) {
      final center = Offset(m.pos.x, m.pos.y);

      // 몬스터 타입별 색상 및 크기
      Color monsterColor;
      double radius;
      switch (m.type) {
        case MonsterType.boss:
          monsterColor = const Color(0xFFFF5252); // 빨강 (보스)
          radius = monsterRadius * 2.0;
          break;
        case MonsterType.miniBoss:
          monsterColor = const Color(0xFFFF6E40); // 주황 (부보스)
          radius = monsterRadius * 1.5;
          break;
        case MonsterType.normal:
        default:
          monsterColor = const Color(0xFFFFD54F); // 노랑 (일반)
          radius = monsterRadius;
          break;
      }

      // 몬스터 타입별 스프라이트 또는 폴백 드로잉
      if (m.type == MonsterType.normal && goblinImageLoaded && goblinImage != null && stageLevel == 1) {
        // 일반 몬스터 (Stage1): Goblin 스프라이트
        _renderGoblinSprite(canvas, m, radius);
      } else if (m.type == MonsterType.boss && bossMonsterImageLoaded && bossMonsterImage != null) {
        // D-4-3: 보스 스프라이트 (통상 Goblin의 2배 크기 + 발광 오라)
        _renderBossAura(canvas, center, radius, isBoss: true);
        final srcRect = Rect.fromLTWH(0, 0, bossMonsterImage!.width.toDouble(), bossMonsterImage!.height.toDouble());
        final dstRect = Rect.fromCenter(center: center, width: radius * 2.2, height: radius * 2.2);
        final spritePaint = Paint()
          ..color = m.damageFlashTimer > 0
              ? const Color(0xFFFF5252)
              : const Color(0xFFFFFFFF);
        canvas.drawImageRect(bossMonsterImage!, srcRect, dstRect, spritePaint);
        _renderBossCrown(canvas, center, radius, isGold: true);
      } else if (m.type == MonsterType.miniBoss && minibossMonsterImageLoaded && minibossMonsterImage != null) {
        // D-4-4: 미니보스 스프라이트 (통상의 1.5배 크기 + 주황 오라)
        _renderBossAura(canvas, center, radius, isBoss: false);
        final srcRect = Rect.fromLTWH(0, 0, minibossMonsterImage!.width.toDouble(), minibossMonsterImage!.height.toDouble());
        final dstRect = Rect.fromCenter(center: center, width: radius * 2.2, height: radius * 2.2);
        final spritePaint = Paint()
          ..color = m.damageFlashTimer > 0
              ? const Color(0xFFFF5252)
              : const Color(0xFFFFFFFF);
        canvas.drawImageRect(minibossMonsterImage!, srcRect, dstRect, spritePaint);
        _renderBossCrown(canvas, center, radius, isGold: false);
      } else if (m.type == MonsterType.boss || m.type == MonsterType.miniBoss) {
        // D-4-3/D-4-4: 스프라이트 미로드 시 Canvas 폴백 드로잉
        _renderBossAura(canvas, center, radius, isBoss: m.type == MonsterType.boss);
        _renderBossMonsterFallback(canvas, center, radius,
            isBoss: m.type == MonsterType.boss, isDamaged: m.damageFlashTimer > 0);
        _renderBossCrown(canvas, center, radius, isGold: m.type == MonsterType.boss);
      } else {
        // 폴백: 원형 드로잉
        if (m.damageFlashTimer > 0) {
          final flashPaint = Paint()..color = const Color(0xFFFF0000);
          canvas.drawCircle(center, radius, flashPaint);
        } else {
          final monsterPaint = Paint()..color = monsterColor;
          canvas.drawCircle(center, radius, monsterPaint);
        }
      }

      // 보스/미니보스가 성을 공격 중일 때 효과
      if (m.attackingCastle && (m.type == MonsterType.boss || m.type == MonsterType.miniBoss)) {
        // 공격 표시 (빨간색 펄스 링)
        final attackPaint = Paint()
          ..color = const Color(0xFFFF0000).withValues(alpha: 0.5 + 0.5 * (m.castleAttackTimer % 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawCircle(center, radius + 5, attackPaint);

        // "공격 중!" 텍스트
        _drawCenteredText(
          canvas,
          '⚔️',
          Offset(center.dx, center.dy - radius - 15),
          fontSize: 16,
          color: const Color(0xFFFF0000),
        );
      }

      // 보스/미니보스가 아닌 경우 기존 HP 바
      if (m.type != MonsterType.boss && m.type != MonsterType.miniBoss) {
        final ratio = m.maxHp == 0 ? 0 : m.hp / m.maxHp;

        final hpBarX = center.dx - hpBarWidth / 2;
        final hpBarY = center.dy - radius - hpBarHeight - hpBarMargin;

        final bgPaint = Paint()..color = const Color(0xFF555555);
        final fgPaint = Paint()..color = const Color(0xFFEF5350);

        final bgRect = Rect.fromLTWH(hpBarX, hpBarY, hpBarWidth, hpBarHeight);
        canvas.drawRect(bgRect, bgPaint);

        final fgRect = Rect.fromLTWH(
          hpBarX,
          hpBarY,
          hpBarWidth * ratio.clamp(0.0, 1.0),
          hpBarHeight,
        );
        canvas.drawRect(fgRect, fgPaint);

        _drawCenteredText(
          canvas,
          '${m.hp}/${m.maxHp}',
          Offset(center.dx, hpBarY - 10),
          fontSize: 10,
          color: const Color(0xFFFFFFFF),
        );
      }

      // 속성 시스템: 상태이상 아이콘 표시 (몬스터 위)
      _renderMonsterStatusIcons(canvas, m, center, radius);
    }

    // 보스/미니보스 HP 바 (화면 상단에 크게)
    _renderBossHealthBar(canvas);
  }

  // 상태이상 아이콘 렌더링 (몬스터 위)
  void _renderMonsterStatusIcons(Canvas canvas, _Monster m, Offset center, double radius) {
    final List<String> icons = [];
    if (m.burnTimer > 0) icons.add('🔥');
    if (m.freezeTimer > 0) icons.add('❄️');
    if (m.bindTimer > 0) icons.add('🌿');
    if (m.shockTimer > 0) icons.add('⚡');
    if (m.curseTimer > 0) icons.add('🌑');
    if (icons.isEmpty) return;

    // 아이콘을 몬스터 위에 가로 나열
    const double iconSize = 9.0;
    const double spacing = 10.0;
    final double totalW = icons.length * spacing - 2;
    final double startX = center.dx - totalW / 2;
    final double iconY = center.dy - radius - 18;

    for (int i = 0; i < icons.length; i++) {
      _drawCenteredText(
        canvas,
        icons[i],
        Offset(startX + i * spacing, iconY),
        fontSize: iconSize,
      );
    }
  }

  // Goblinスプライトレンダリング
  void _renderGoblinSprite(Canvas canvas, _Monster m, double radius) {
    if (goblinImage == null) return;

    // 歩行アニメーション効果 (上下に軽く揺れる)
    final bounceOffset = [0.0, -2.0, 0.0, 2.0][m.currentFrame];
    final center = Offset(m.pos.x, m.pos.y + bounceOffset);

    // スプライトシートのフレームサイズ (画像は1枚のみなので全体を使用)
    final imgWidth = goblinImage!.width.toDouble();
    final imgHeight = goblinImage!.height.toDouble();

    // 描画サイズ (radiusの2.5倍で表示)
    final drawSize = radius * 2.5;

    // ソース矩形 (画像全体)
    final srcRect = Rect.fromLTWH(0, 0, imgWidth, imgHeight);

    // 目標矩形 (中心に描画)
    final dstRect = Rect.fromCenter(
      center: center,
      width: drawSize,
      height: drawSize,
    );

    // ダメージフラッシュ時は赤いオーバーレイ
    if (m.damageFlashTimer > 0) {
      // 赤く染めるためにColorFilterを使用
      final flashPaint = Paint()
        ..colorFilter = const ColorFilter.mode(Color(0xFFFF0000), BlendMode.srcATop);
      canvas.drawImageRect(goblinImage!, srcRect, dstRect, flashPaint);
    } else {
      canvas.drawImageRect(goblinImage!, srcRect, dstRect, Paint());
    }
  }

  // D-4-3: 보스/미니보스 발광 오라 렌더링
  void _renderBossAura(Canvas canvas, Offset center, double radius, {required bool isBoss}) {
    // 오라 색상: 보스=빨강, 미니보스=주황
    final Color auraColor = isBoss ? const Color(0xFFFF3030) : const Color(0xFFFF8C00);

    // 다층 반투명 원형 오라
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        center,
        radius + (i * 5.0),
        Paint()..color = auraColor.withValues(alpha: 0.07 * i),
      );
    }

    // 외부 발광 링
    canvas.drawCircle(
      center,
      radius + 5,
      Paint()
        ..color = auraColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // 보스 전용: 황금 이중 링
    if (isBoss) {
      canvas.drawCircle(
        center,
        radius + 10,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  // D-4-3/D-4-4: 보스/미니보스 왕관 오버레이
  void _renderBossCrown(Canvas canvas, Offset center, double radius, {required bool isGold}) {
    final Color crownColor = isGold ? const Color(0xFFFFD700) : const Color(0xFFFF8C00);
    final double crownBaseY = center.dy - radius - 2;
    final double halfW = radius * 0.38;

    // 왕관 패스 (5점형 간략 왕관)
    final path = Path();
    path.moveTo(center.dx - halfW, crownBaseY);
    path.lineTo(center.dx - halfW, crownBaseY - radius * 0.28);
    path.lineTo(center.dx - halfW * 0.4, crownBaseY - radius * 0.15);
    path.lineTo(center.dx, crownBaseY - radius * 0.4);
    path.lineTo(center.dx + halfW * 0.4, crownBaseY - radius * 0.15);
    path.lineTo(center.dx + halfW, crownBaseY - radius * 0.28);
    path.lineTo(center.dx + halfW, crownBaseY);
    path.close();

    canvas.drawPath(path, Paint()..color = crownColor.withValues(alpha: 0.85));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  // D-4-3/D-4-4: 보스/미니보스 Canvas 폴백 (스프라이트 미로드 시)
  void _renderBossMonsterFallback(Canvas canvas, Offset center, double radius,
      {required bool isBoss, required bool isDamaged}) {
    final Color baseColor = isBoss ? const Color(0xFFCC2200) : const Color(0xFFCC5500);
    final Color hlColor = isBoss ? const Color(0xFFFF7777) : const Color(0xFFFFAA44);

    // 메인 바디
    canvas.drawCircle(center, radius, Paint()..color = isDamaged ? const Color(0xFFFF2222) : baseColor);

    // 상단 하이라이트
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.25),
      radius * 0.45,
      Paint()..color = hlColor.withValues(alpha: 0.55),
    );

    // 빛나는 눈
    final eyeR = radius * (isBoss ? 0.16 : 0.13);
    final eyeOffX = radius * 0.3;
    final eyeOffY = radius * 0.1;
    canvas.drawCircle(
      Offset(center.dx - eyeOffX, center.dy - eyeOffY),
      eyeR,
      Paint()..color = const Color(0xFFFFFF00),
    );
    canvas.drawCircle(
      Offset(center.dx + eyeOffX, center.dy - eyeOffY),
      eyeR,
      Paint()..color = const Color(0xFFFFFF00),
    );

    // 보스 전용: 이마 문양 (마름모)
    if (isBoss) {
      final markPath = Path();
      final mx = center.dx;
      final my = center.dy - radius * 0.55;
      final ms = radius * 0.12;
      markPath.moveTo(mx, my - ms);
      markPath.lineTo(mx + ms, my);
      markPath.lineTo(mx, my + ms);
      markPath.lineTo(mx - ms, my);
      markPath.close();
      canvas.drawPath(markPath, Paint()..color = const Color(0xFFFFD700));
    }
  }

  // 보스 HP 바 렌더링 (화면 상단)
  void _renderBossHealthBar(Canvas canvas) {
    // 보스나 미니보스 찾기
    _Monster? boss;
    for (final m in monsters) {
      if (m.type == MonsterType.boss || m.type == MonsterType.miniBoss) {
        boss = m;
        break;
      }
    }

    if (boss == null) return;

    // 화면 상단 중앙에 큰 HP 바
    const double barHeight = 20.0;
    final double barWidth = size.x * 0.8; // 화면의 80%
    final double barX = (size.x - barWidth) / 2;
    const double barY = 50.0;

    // 배경
    final bgPaint = Paint()..color = const Color(0xFF333333);
    final bgRect = Rect.fromLTWH(barX, barY, barWidth, barHeight);
    canvas.drawRect(bgRect, bgPaint);

    // 테두리
    final borderPaint = Paint()
      ..color = boss.type == MonsterType.boss
          ? const Color(0xFFFF5252) // 보스: 빨강
          : const Color(0xFFFF6E40) // 미니보스: 주황
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(bgRect, borderPaint);

    // 실제 HP (빨간색)
    final hpRatio = boss.maxHp == 0 ? 0 : boss.hp / boss.maxHp;
    final hpPaint = Paint()..color = const Color(0xFFEF5350);
    final hpRect = Rect.fromLTWH(
      barX,
      barY,
      barWidth * hpRatio.clamp(0.0, 1.0),
      barHeight,
    );
    canvas.drawRect(hpRect, hpPaint);

    // 표시용 HP (롤 스타일 - 회색으로 천천히 감소)
    if (boss.displayHp > boss.hp) {
      final displayRatio = boss.maxHp == 0 ? 0 : boss.displayHp / boss.maxHp;
      final displayPaint = Paint()..color = const Color(0xFF757575); // 회색
      final displayRect = Rect.fromLTWH(
        barX,
        barY,
        barWidth * displayRatio.clamp(0.0, 1.0),
        barHeight,
      );
      canvas.drawRect(displayRect, displayPaint);
    }

    // HP 텍스트
    final bossName = boss.type == MonsterType.boss ? 'BOSS' : 'MINI BOSS';
    _drawCenteredText(
      canvas,
      '$bossName  ${boss.hp} / ${boss.maxHp}',
      Offset(size.x / 2, barY + barHeight / 2),
      fontSize: 14,
      color: const Color(0xFFFFFFFF),
    );
  }

  // 캐릭터 유닛 렌더링
  void _renderCharacterUnits(Canvas canvas) {
    for (final unit in characterUnits) {
      final center = Offset(unit.pos.x, unit.pos.y);

      // 역할별 색상 (이모지 배경)
      Color unitColor;
      switch (unit.definition.role) {
        case RoleType.tanker:
          unitColor = const Color(0xFF5C6BC0); // 파랑 (탱커)
          break;
        case RoleType.physicalDealer:
          unitColor = const Color(0xFFEF5350); // 빨강 (물리딜러)
          break;
        case RoleType.magicDealer:
          unitColor = const Color(0xFFAB47BC); // 보라 (마법딜러)
          break;
        case RoleType.priest:
          unitColor = const Color(0xFFFFA726); // 주황 (성직자)
          break;
        case RoleType.utility:
          unitColor = const Color(0xFF26A69A); // 청록 (유틸리티)
          break;
      }

      // 버프 효과 (외곽 링)
      if (unit.hasAttackSpeedBuff || unit.hasMoveSpeedBuff) {
        final buffPaint = Paint()
          ..color = const Color(0xFFFFD700) // 금색
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(center, characterUnitRadius + 2.0, buffPaint);
      }

      // D-3-6: 무적 중 반투명 점멸 (메인 캐릭터만)
      final bool isMainUnit = !unit.isTower;
      final double unitAlpha = (isMainUnit && _invincibleTimer > 0)
          ? (0.4 + 0.4 * sin(gameTime * 12)).clamp(0.15, 0.85) // 점멸: sin 파형
          : 1.0;
      final unitPaint = Paint()
        ..color = unitColor.withValues(alpha: unitAlpha);
      canvas.drawCircle(center, characterUnitRadius, unitPaint);

      // 전사 검 휘두르기 효과 렌더링
      if (unit.definition.role == RoleType.tanker && unit.isSwinging) {
        const double swordLength = 50.0;
        const double swordWidth = 6.0;
        const double arcRadius = 55.0;

        // 검 휘두르기 궤적 (반시계방향 호)
        final arcPaint = Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0;

        // 휘두르기 진행에 따른 호 그리기
        final sweepAngle = -unit.swingProgress * 4.71239; // 반시계방향
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: arcRadius),
          0, // 시작 각도 (오른쪽부터)
          sweepAngle,
          false,
          arcPaint,
        );

        // 검 그리기
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(unit.swordSwingAngle);

        // 검 몸통 (흰색)
        final swordPaint = Paint()
          ..color = const Color(0xFFE0E0E0)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(characterUnitRadius, -swordWidth / 2, swordLength, swordWidth),
          swordPaint,
        );

        // 검 테두리 (어두운 색)
        final swordBorderPaint = Paint()
          ..color = const Color(0xFF616161)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRect(
          Rect.fromLTWH(characterUnitRadius, -swordWidth / 2, swordLength, swordWidth),
          swordBorderPaint,
        );

        // 검 끝부분 (삼각형)
        final tipPath = Path()
          ..moveTo(characterUnitRadius + swordLength, -swordWidth / 2)
          ..lineTo(characterUnitRadius + swordLength + 10, 0)
          ..lineTo(characterUnitRadius + swordLength, swordWidth / 2)
          ..close();
        canvas.drawPath(tipPath, swordPaint);
        canvas.drawPath(tipPath, swordBorderPaint);

        // 검 손잡이 (갈색)
        final handlePaint = Paint()..color = const Color(0xFF8D6E63);
        canvas.drawRect(
          Rect.fromLTWH(characterUnitRadius - 5, -swordWidth / 2 - 2, 8, swordWidth + 4),
          handlePaint,
        );

        canvas.restore();

        // 휘두르기 범위 표시 (반투명 원)
        final rangePaint = Paint()
          ..color = const Color(0xFFFF5722).withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 60.0, rangePaint);
      }

      // 역할 이모지 표시
      _drawCenteredText(
        canvas,
        unit.definition.role.emoji,
        center,
        fontSize: 16,
        color: const Color(0xFFFFFFFF),
      );

      // HP 바 (크고 명확하게)
      const double hpBarWidth = 32.0;
      const double hpBarHeight = 4.0;
      const double hpBarMargin = 3.0;

      final hpRatio = unit.maxHp == 0 ? 0 : unit.currentHp / unit.maxHp;
      final hpBarX = center.dx - hpBarWidth / 2;
      final hpBarY = center.dy - characterUnitRadius - hpBarHeight - hpBarMargin;

      // HP 바 배경 (검은색)
      final hpBgPaint = Paint()..color = const Color(0xFF000000);
      final hpBgRect = Rect.fromLTWH(hpBarX, hpBarY, hpBarWidth, hpBarHeight);
      canvas.drawRect(hpBgRect, hpBgPaint);

      // HP 바 전경 (초록색)
      final hpFgPaint = Paint()..color = const Color(0xFF4CAF50);
      final hpFgRect = Rect.fromLTWH(
        hpBarX,
        hpBarY,
        hpBarWidth * hpRatio.clamp(0.0, 1.0),
        hpBarHeight,
      );
      canvas.drawRect(hpFgRect, hpFgPaint);

      // HP 바 테두리 (흰색)
      final hpBorderPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(hpBgRect, hpBorderPaint);

      // 버프 아이콘 표시 (우측 상단)
      if (unit.hasAttackSpeedBuff) {
        _drawCenteredText(
          canvas,
          '⚡', // 번개 = 공격속도
          Offset(center.dx + characterUnitRadius - 4, center.dy - characterUnitRadius + 4),
          fontSize: 10,
          color: const Color(0xFFFFD700), // 금색
        );
      }
      if (unit.hasMoveSpeedBuff) {
        _drawCenteredText(
          canvas,
          '💨', // 바람 = 이동속도
          Offset(center.dx - characterUnitRadius + 4, center.dy - characterUnitRadius + 4),
          fontSize: 10,
          color: const Color(0xFFFFD700), // 금색
        );
      }
    }
  }

  // 투사물 렌더링 (역할별 비주얼)
  void _renderProjectiles(Canvas canvas) {
    for (final proj in projectiles) {
      final center = Offset(proj.pos.x, proj.pos.y);

      // 마법 투사물 (마법사) — 펄스하는 광구 + 스파크 파티클
      if (proj.isMagic) {
        const projColor = Color(0xFFCE93D8);
        // 스플래시 범위 표시
        canvas.drawCircle(
          center,
          proj.splashRadius * 0.5,
          Paint()..color = projColor.withValues(alpha: 0.15),
        );
        // 펄스하는 중심 구체
        final pulseR = 6.0 + sin(gameTime * 10) * 2.0;
        canvas.drawCircle(center, pulseR, Paint()..color = projColor);
        // 글로우
        canvas.drawCircle(
          center,
          pulseR * 1.8,
          Paint()..color = projColor.withValues(alpha: 0.25),
        );
        // 주변 파티클 (2개가 회전)
        for (int i = 0; i < 2; i++) {
          final angle = gameTime * 8 + i * 3.14;
          final px = proj.pos.x + cos(angle) * (pulseR + 5);
          final py = proj.pos.y + sin(angle) * (pulseR + 5);
          canvas.drawCircle(
            Offset(px, py),
            1.5,
            Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7),
          );
        }
        continue;
      }

      // 궁수 — 삼각형 화살 + 짧은 몸통
      if (proj.sourceClass == ClassType.archer) {
        const projColor = Color(0xFFFF8A80);
        final angle = atan2(proj.velocity.y, proj.velocity.x);
        canvas.save();
        canvas.translate(proj.pos.x, proj.pos.y);
        canvas.rotate(angle);
        // 삼각형 화살촉
        final arrowHead = Path()
          ..moveTo(6, 0)
          ..lineTo(-4, -3.5)
          ..lineTo(-4, 3.5)
          ..close();
        canvas.drawPath(arrowHead, Paint()..color = projColor);
        // 몸통 선
        canvas.drawLine(
          const Offset(-4, 0),
          const Offset(-12, 0),
          Paint()
            ..color = projColor.withValues(alpha: 0.6)
            ..strokeWidth = 1.5,
        );
        canvas.restore();
        continue;
      }

      // 총잡이 — 작은 원 + 잔상 트레일
      if (proj.sourceClass == ClassType.gunslinger) {
        const projColor = Color(0xFFFFE082);
        // 잔상 (alpha 감소)
        for (int t = 0; t < proj.trail.length; t++) {
          final alpha = 0.5 - (t * 0.15);
          final r = 2.5 - (t * 0.5);
          canvas.drawCircle(
            Offset(proj.trail[t].x, proj.trail[t].y),
            r.clamp(1.0, 3.0),
            Paint()..color = projColor.withValues(alpha: alpha.clamp(0.1, 0.5)),
          );
        }
        // 선두 탄환
        canvas.drawCircle(center, 3.0, Paint()..color = projColor);
        continue;
      }

      // 성직자 — 떠오르는 십자가
      if (proj.sourceRole == RoleType.priest) {
        const projColor = Color(0xFF81C784);
        final crossPaint = Paint()
          ..color = projColor.withValues(alpha: 0.8)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(proj.pos.x - 4, proj.pos.y),
          Offset(proj.pos.x + 4, proj.pos.y),
          crossPaint,
        );
        canvas.drawLine(
          Offset(proj.pos.x, proj.pos.y - 4),
          Offset(proj.pos.x, proj.pos.y + 4),
          crossPaint,
        );
        continue;
      }

      // 기본 투사물 (fallback)
      Color projColor;
      switch (proj.sourceRole) {
        case RoleType.physicalDealer:
          projColor = const Color(0xFFFF8A80);
          break;
        case RoleType.magicDealer:
          projColor = const Color(0xFFCE93D8);
          break;
        case RoleType.utility:
          projColor = const Color(0xFF80CBC4);
          break;
        default:
          projColor = const Color(0xFFFFFFFF);
          break;
      }
      canvas.drawCircle(center, 4.0, Paint()..color = projColor);
      final tailStart = Offset(
        proj.pos.x - proj.velocity.x * 0.05,
        proj.pos.y - proj.velocity.y * 0.05,
      );
      canvas.drawLine(
        tailStart,
        center,
        Paint()
          ..color = projColor.withValues(alpha: 0.5)
          ..strokeWidth = 2.0,
      );
    }
  }

  // VFX 이펙트 렌더링
  void _renderVfxEffects(Canvas canvas) {
    for (final vfx in vfxEffects) {
      final center = Offset(vfx.pos.x, vfx.pos.y);
      final p = vfx.progress;

      switch (vfx.type) {
        // 히트 스파크: 방사형 선이 퍼지며 사라짐
        case VfxType.hit:
          const sparkCount = 5;
          final radius = 5.0 + p * 12.0;
          final alpha = (1.0 - p).clamp(0.0, 1.0);
          final paint = Paint()
            ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round;
          for (int i = 0; i < sparkCount; i++) {
            final angle = (i / sparkCount) * 3.14159 * 2 + 0.3;
            final dx = cos(angle) * radius;
            final dy = sin(angle) * radius;
            canvas.drawLine(
              Offset(center.dx + dx * 0.3, center.dy + dy * 0.3),
              Offset(center.dx + dx, center.dy + dy),
              paint,
            );
          }
          break;

        // 죽음 파프: 팽창하는 원 + 흩어지는 파티클
        case VfxType.death:
          if (p < 0.4) {
            // Phase 1: 원 팽창
            final phase1 = p / 0.4;
            final radius = 8.0 + phase1 * 18.0;
            final alpha = (1.0 - phase1 * 0.6).clamp(0.0, 1.0);
            canvas.drawCircle(
              center,
              radius,
              Paint()..color = vfx.color.withValues(alpha: alpha),
            );
          } else {
            // Phase 2: 파티클 흩어짐
            final phase2 = (p - 0.4) / 0.6;
            final alpha = (1.0 - phase2).clamp(0.0, 1.0);
            for (int i = 0; i < 6; i++) {
              final angle = (i / 6) * 3.14159 * 2;
              final dist = 10.0 + phase2 * 25.0;
              final px = center.dx + cos(angle) * dist;
              final py = center.dy + sin(angle) * dist;
              canvas.drawCircle(
                Offset(px, py),
                2.5 - phase2 * 1.5,
                Paint()..color = vfx.color.withValues(alpha: alpha),
              );
            }
          }
          break;

        // 충격파: 확대되는 링
        case VfxType.shockwave:
          final maxR = vfx.maxRadius;
          final radius = p * maxR;
          final alpha = (1.0 - p).clamp(0.0, 1.0);
          final strokeW = 20.0 - p * 18.0;
          canvas.drawCircle(
            center,
            radius,
            Paint()
              ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeW.clamp(2.0, 20.0),
          );
          // 중앙 플래시 (처음 0.1초만)
          if (vfx.timer < 0.1) {
            final flashAlpha = (1.0 - vfx.timer / 0.1).clamp(0.0, 1.0);
            canvas.drawRect(
              Rect.fromLTWH(0, 0, size.x, size.y),
              Paint()..color = Color.fromRGBO(255, 255, 255, flashAlpha * 0.3),
            );
          }
          break;

        // 배리어: 회전하는 6각형
        case VfxType.barrier:
          final barrierAlpha = vfx.duration - vfx.timer < 3.0
              ? (sin(vfx.timer * 8) * 0.5 + 0.5).clamp(0.0, 1.0)
              : 0.6;
          final angle = vfx.timer * 0.5;
          final r = vfx.maxRadius;
          final hexPath = Path();
          for (int i = 0; i < 6; i++) {
            final a = angle + (i / 6) * 3.14159 * 2;
            final hx = center.dx + cos(a) * r;
            final hy = center.dy + sin(a) * r;
            if (i == 0) {
              hexPath.moveTo(hx, hy);
            } else {
              hexPath.lineTo(hx, hy);
            }
          }
          hexPath.close();
          canvas.drawPath(
            hexPath,
            Paint()
              ..color = const Color(0xFF00BCD4).withValues(alpha: barrierAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
          break;
      }
    }
  }

  void _renderStageProgress(Canvas canvas) {
    const double marginTop = 15.0;
    const double marginSide = 20.0;

    final total = totalMonstersInRound;
    final remaining = total - (defeatedMonsters + escapedMonsters);

    // 왼쪽: 남은 적 카운트 (숫자만)
    final monsterColor = remaining <= 3
        ? const Color(0xFFFF5252) // 3마리 이하면 빨간색
        : const Color(0xFFFFFFFF);

    _drawCenteredText(
      canvas,
      '👾 $remaining',
      Offset(marginSide + 30, marginTop),
      fontSize: 20,
      color: monsterColor,
    );

    // 중앙: 카운트다운 타이머
    final remainingTime = (roundTimeLimit - roundTimer).clamp(0.0, roundTimeLimit);
    final minutes = (remainingTime ~/ 60);
    final seconds = (remainingTime % 60).toInt();
    final timeText = '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';

    final timeColor = remainingTime <= 30
        ? const Color(0xFFFF5252) // 30초 이하면 빨간색
        : const Color(0xFFFFFFFF);

    _drawCenteredText(
      canvas,
      timeText,
      Offset(size.x / 2, marginTop),
      fontSize: 24,
      color: timeColor,
    );

    // 오른쪽: 스테이지-라운드 표시
    _drawCenteredText(
      canvas,
      '$stageLevel-$currentRound',
      Offset(size.x - marginSide - 30, marginTop),
      fontSize: 20,
      color: const Color(0xFFFFFFFF),
    );

    // 보스 라운드 알림 (상단 정보 아래)
    final cfg = kStageConfigs[stageLevel];
    if (cfg != null && currentRound <= cfg.rounds.length) {
      final roundCfg = cfg.rounds[currentRound - 1];
      if (roundCfg.monsterType == MonsterType.boss) {
        _drawCenteredText(
          canvas,
          '⚔️ BOSS ROUND ⚔️',
          Offset(size.x / 2, marginTop + 30),
          fontSize: 16,
          color: const Color(0xFFFF5252),
        );
      } else if (roundCfg.monsterType == MonsterType.miniBoss) {
        _drawCenteredText(
          canvas,
          '⚡ MINI BOSS ⚡',
          Offset(size.x / 2, marginTop + 30),
          fontSize: 16,
          color: const Color(0xFFFF6E40),
        );
      }
    }
  }

  void _renderWeaponInfo(Canvas canvas) {
    const padding = 8.0;
    const panelWidth = 120.0;
    const panelHeight = 40.0;

    final rect = Rect.fromLTWH(
      padding,
      size.y - castleHeight + padding,
      panelWidth,
      panelHeight,
    );

    final bgPaint = Paint()..color = const Color(0x80212121);
    final borderPaint = Paint()
      ..color = const Color(0x80FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(rect, bgPaint);
    canvas.drawRect(rect, borderPaint);

    final textOffset = Offset(
      rect.left + 8,
      rect.top + 10,
    );

    _drawText(
      canvas,
      '기본검 (DMG: $weaponDamage)',
      textOffset,
      fontSize: 12,
      alignCenter: false,
    );
  }

  void _renderPauseButton(Canvas canvas) {
    final rect = _pauseButtonRect();

    // 배경
    final bgPaint = Paint()..color = const Color(0x80212121);
    final borderPaint = Paint()
      ..color = const Color(0x80FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(6),
    );

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // 일시정지 아이콘 (두 개의 세로 막대) - 작게 조정
    final iconPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    const double barWidth = 4.0;
    const double barHeight = 14.0;
    const double barGap = 4.0;

    final centerX = rect.center.dx;
    final centerY = rect.center.dy;

    // 왼쪽 막대
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - barWidth - barGap / 2,
        centerY - barHeight / 2,
        barWidth,
        barHeight,
      ),
      iconPaint,
    );

    // 오른쪽 막대
    canvas.drawRect(
      Rect.fromLTWH(
        centerX + barGap / 2,
        centerY - barHeight / 2,
        barWidth,
        barHeight,
      ),
      iconPaint,
    );
  }




  // -----------------------------
  // 상태별 오버레이
  // -----------------------------
  void _renderGameStateOverlay(Canvas canvas) {
    if (gameState == GameState.roundClear) {
      _renderRoundClearOverlay(canvas);
    } else if (gameState == GameState.paused) {
      _renderPausedOverlay(canvas);
    } else if (gameState == GameState.augmentSelect) {
      _renderAugmentSelectionUI(canvas); // 증강 선택 화면
    } else if (gameState == GameState.shopOpen) {
      _renderShopOverlay(canvas); // 리디자인 B-2-16: 상점 화면
    } else if (gameState == GameState.result) {
      _renderResultOverlay(canvas);
    }
  }

  // #37 증강 선택 UI (스펙 준수: 티어별 색상 카드, 전설 글로우 연출)
  void _renderAugmentSelectionUI(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xF00A0A1A));

    // 타이틀 (금색 펄스)
    final double tp = 0.9 + 0.1 * sin(gameTime * 2.5);
    _drawCenteredText(canvas, '⚡ 증강 선택 ⚡',
        Offset(size.x / 2, size.y * 0.06),
        fontSize: 22,
        color: Color.fromRGBO(255, (215 * tp).toInt(), 0, 1.0));
    _drawCenteredText(canvas, 'Round \$currentRound — 1개를 선택하세요',
        Offset(size.x / 2, size.y * 0.13),
        fontSize: 11, color: const Color(0xFF888888));

    if (_augmentOptions.isEmpty) {
      _drawCenteredText(canvas, '증강 없음', Offset(size.x / 2, size.y / 2),
          fontSize: 16, color: const Color(0xFF555555));
      return;
    }

    final double cW = size.x / 3 - 10;
    final double cH = size.y * 0.52;
    final double cY = size.y * 0.19;

    for (int i = 0; i < _augmentOptions.length; i++) {
      final aug = _augmentOptions[i];
      final double cX = i * (size.x / 3) + 5;
      final cRect = Rect.fromLTWH(cX, cY, cW, cH);

      Color bg, brd, lblC;
      String lbl;
      switch (aug.tier) {
        case AugmentTier.legendary:
          bg = const Color(0xCC3D2B00); brd = const Color(0xFFFFD700);
          lblC = const Color(0xFFFFD700); lbl = '✨ 伝説'; break;
        case AugmentTier.rare:
          bg = const Color(0xCC0D1F3C); brd = const Color(0xFF2196F3);
          lblC = const Color(0xFF64B5F6); lbl = '💎 希少'; break;
        default:
          bg = const Color(0xCC1C1C1C); brd = const Color(0xFF9E9E9E);
          lblC = const Color(0xFFBBBBBB); lbl = '⬜ 一般';
      }

      // 전설 글로우 링
      if (aug.tier == AugmentTier.legendary) {
        final double ga = 0.15 + 0.1 * sin(gameTime * 3 + i * 1.2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(cRect.inflate(3), const Radius.circular(13)),
          Paint()..color = Color.fromRGBO(255, 215, 0, ga));
      }

      // 카드 배경 + 테두리
      canvas.drawRRect(RRect.fromRectAndRadius(cRect, const Radius.circular(10)),
          Paint()..color = bg);
      canvas.drawRRect(RRect.fromRectAndRadius(cRect, const Radius.circular(10)),
          Paint()
            ..color = brd
            ..style = PaintingStyle.stroke
            ..strokeWidth = aug.tier == AugmentTier.legendary ? 2.5 : 1.5);

      // 티어 레이블
      _drawCenteredText(canvas, lbl, Offset(cX + cW / 2, cY + 16),
          fontSize: 10, color: lblC);

      // 구분선
      canvas.drawLine(Offset(cX + 8, cY + 29), Offset(cX + cW - 8, cY + 29),
          Paint()..color = brd.withValues(alpha: 0.4)..strokeWidth = 0.8);

      // 카테고리 아이콘 + 이름 + 설명
      _drawCenteredText(canvas, _augmentCategoryIcon(aug.category),
          Offset(cX + cW / 2, cY + 52), fontSize: 24);
      _drawCenteredText(canvas, aug.nameJp,
          Offset(cX + cW / 2, cY + 82), fontSize: 13, color: const Color(0xFFFFFFFF));
      _drawCenteredText(canvas, aug.description,
          Offset(cX + cW / 2, cY + 108), fontSize: 8.5, color: const Color(0xFFBBBBBB));
    }

    // 하단 안내 점멸
    _drawCenteredText(canvas, '카드를 탭해서 선택',
        Offset(size.x / 2, size.y * 0.84),
        fontSize: 12,
        color: Color.fromRGBO(200, 200, 200, 0.6 + 0.4 * sin(gameTime * 2)));
  }

  // 증강 카테고리 아이콘 헬퍼
  String _augmentCategoryIcon(AugmentCategory cat) {
    switch (cat) {
      case AugmentCategory.main:      return '⚔️';
      case AugmentCategory.tower:     return '🏹';
      case AugmentCategory.castle:    return '🏰';
      case AugmentCategory.utility:   return '🔧';
      case AugmentCategory.economy:   return '💰';
      case AugmentCategory.elemental: return '🌟';
      case AugmentCategory.special:   return '✨';
      case AugmentCategory.synergy:   return '🔗';
    }
  }

  // D-2-2: 스테이지 클리어 후 상점 UI (Violet Theme)
  // 탭 영역은 _handleTapInShop 과 동기화:
  //   castleMaxHpUp: y in [0.30, 0.50), towerPowerUp: y in [0.50, 0.65), mainCharHpUp: y in [0.65, 0.80)
  //   계속 버튼: y > 0.80
  void _renderShopOverlay(Canvas canvas) {
    // 배경 오버레이
    final bgPaint = Paint()..color = const Color(0xEE0A0A20);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // 상단 장식 바 (골드)
    final topBarPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 4), topBarPaint);

    // "STAGE CLEAR!" 제목
    _drawCenteredText(
      canvas,
      'STAGE CLEAR!',
      Offset(size.x / 2, size.y * 0.07),
      fontSize: 26,
      color: const Color(0xFFFFD700),
    );

    // 성 수리 완료 알림
    _drawCenteredText(
      canvas,
      '🏰  城 HP が完全回復しました',
      Offset(size.x / 2, size.y * 0.14),
      fontSize: 13,
      color: const Color(0xFF4CAF50),
    );

    // 골드 표시 패널
    final goldPanelRect = Rect.fromLTWH(size.x / 2 - 70, size.y * 0.19, 140, 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(goldPanelRect, const Radius.circular(14)),
      Paint()..color = const Color(0xFF2A1C00),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(goldPanelRect, const Radius.circular(14)),
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _drawCenteredText(
      canvas,
      '🪙  $playerGold G',
      Offset(size.x / 2, size.y * 0.19 + 14),
      fontSize: 14,
      color: const Color(0xFFFFD700),
    );

    // 상점 아이템 3개
    const List<String> names  = ['城 最大HP +20', 'タワー 攻撃力 +5%', 'メインHP +10'];
    const List<String> icons  = ['🏰', '🗼', '🧑'];
    const List<int>    prices = [50, 30, 20];
    final List<int> counts    = [_shopCastleMaxHpCount, _shopTowerPowerCount, _shopMainCharHpCount];
    const List<int> maxes     = [10, 10, 5];
    // 탭 존 중앙 Y 좌표
    final List<double> centerYs = [
      size.y * 0.40,
      size.y * 0.575,
      size.y * 0.725,
    ];

    for (int i = 0; i < 3; i++) {
      final bool maxed       = counts[i] >= maxes[i];
      final bool affordable  = !maxed && playerGold >= prices[i];
      final Color bgColor    = maxed ? const Color(0xFF1A1A1A)
          : affordable ? const Color(0xFF1A1040)
          : const Color(0xFF151515);
      final Color borderColor = maxed ? const Color(0xFF444444)
          : affordable ? const Color(0xFF7C3AED)
          : const Color(0xFF555555);
      final Color textColor  = maxed ? const Color(0xFF666666)
          : affordable ? const Color(0xFFFFFFFF)
          : const Color(0xFF888888);

      final double cardH = 70.0;
      final cardRect = Rect.fromLTWH(20, centerYs[i] - cardH / 2, size.x - 40, cardH);

      // 카드 배경
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(10)),
        Paint()..color = bgColor,
      );
      // 카드 테두리
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(10)),
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // 아이콘
      _drawCenteredText(
        canvas,
        icons[i],
        Offset(cardRect.left + 35, centerYs[i]),
        fontSize: 22,
      );

      // 아이템 이름
      _drawCenteredText(
        canvas,
        names[i],
        Offset(cardRect.left + 110, centerYs[i] - 10),
        fontSize: 13,
        color: textColor,
      );

      // 구매 횟수 표시
      _drawCenteredText(
        canvas,
        maxed ? 'MAX' : '${counts[i]} / ${maxes[i]}',
        Offset(cardRect.left + 110, centerYs[i] + 10),
        fontSize: 11,
        color: maxed ? const Color(0xFF888888) : const Color(0xFFAAAAAA),
      );

      // 가격 배지
      final priceColor = affordable ? const Color(0xFFFFD700) : const Color(0xFF888888);
      final priceBgRect = Rect.fromLTWH(
        cardRect.right - 62, centerYs[i] - 14, 54, 28,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(priceBgRect, const Radius.circular(8)),
        Paint()..color = maxed ? const Color(0xFF222222) : const Color(0xFF2A1C00),
      );
      _drawCenteredText(
        canvas,
        maxed ? 'MAX' : '${prices[i]}G',
        Offset(priceBgRect.center.dx, priceBgRect.center.dy),
        fontSize: 13,
        color: priceColor,
      );
    }

    // 계속 버튼 (y > 0.80)
    final continueRect = Rect.fromLTWH(
      (size.x - 200) / 2, size.y * 0.84, 200, 44,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(continueRect, const Radius.circular(22)),
      Paint()..color = const Color(0xFF5B21B6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(continueRect, const Radius.circular(22)),
      Paint()
        ..color = const Color(0xFFD946EF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    _drawCenteredText(
      canvas,
      '続ける  →',
      continueRect.center,
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );
  }

  void _renderLoadingOverlay(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '준비 중...',
      Offset(size.x / 2, size.y * 0.4),
      fontSize: 20,
      color: const Color(0xFFFFFFFF),
    );

    // 게이지 바
    const double barHeight = 12.0;
    final double barWidth = size.x * 0.6;
    final double barX = (size.x - barWidth) / 2;
    final double barY = size.y * 0.5;

    final double progress = (_loadingTimer / _loadingDuration).clamp(0.0, 1.0);

    final bgPaint = Paint()..color = const Color(0xFF424242);
    final fgPaint = Paint()..color = const Color(0xFF42A5F5);

    final bgRect = Rect.fromLTWH(barX, barY, barWidth, barHeight);
    canvas.drawRect(bgRect, bgPaint);

    final fgRect = Rect.fromLTWH(
      barX,
      barY,
      barWidth * progress,
      barHeight,
    );
    canvas.drawRect(fgRect, fgPaint);
  }

  // 네비게이션 바 렌더링
  void _renderNavigationBar(Canvas canvas) {
    const double navBarHeight = 60.0;
    const double padding = 10.0;

    // 네비게이션 바 배경
    final navBarBg = Paint()..color = const Color(0xFFF5F5F5);
    final navBarRect = Rect.fromLTWH(0, 0, size.x, navBarHeight);
    canvas.drawRect(navBarRect, navBarBg);

    // 하단 경계선
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, navBarHeight),
      Offset(size.x, navBarHeight),
      borderPaint,
    );

    // 왼쪽: 프로필 영역
    const double profileIconSize = 40.0;
    final profileIconRect = Rect.fromLTWH(
      padding,
      (navBarHeight - profileIconSize) / 2,
      profileIconSize,
      profileIconSize,
    );

    // 프로필 아이콘 배경 (원형)
    final profileBgPaint = Paint()..color = const Color(0xFF42A5F5);
    canvas.drawCircle(
      profileIconRect.center,
      profileIconSize / 2,
      profileBgPaint,
    );

    // 프로필 아이콘 (이모지)
    _drawCenteredText(
      canvas,
      '👤',
      profileIconRect.center,
      fontSize: 24,
      color: const Color(0xFFFFFFFF),
    );

    // 닉네임과 레벨을 프로필 오른쪽에 세로로 배치
    final nameX = profileIconRect.right + 8;

    // 닉네임 (위)
    _drawText(
      canvas,
      playerNickname,
      Offset(nameX, navBarHeight / 2 - 14),
      fontSize: 13,
      color: const Color(0xFF000000),
      alignCenter: false,
    );

    // 레벨 (아래)
    _drawText(
      canvas,
      'Lv.$playerLevel',
      Offset(nameX, navBarHeight / 2 + 2),
      fontSize: 11,
      color: const Color(0xFF666666),
      alignCenter: false,
    );

    // 오른쪽: 리소스 영역 (골드, 젬, 에너지를 가로로 나열)
    const double resourceSpacing = 70.0;
    final resourceStartX = size.x - padding - (resourceSpacing * 3) + 10;

    // 골드
    _renderResourceHorizontal(
      canvas,
      Offset(resourceStartX, navBarHeight / 2),
      '💰',
      _formatNumber(playerGold),
    );

    // 젬
    _renderResourceHorizontal(
      canvas,
      Offset(resourceStartX + resourceSpacing, navBarHeight / 2),
      '💎',
      _formatNumber(playerGem),
    );

    // 에너지 (배터리)
    _renderResourceHorizontal(
      canvas,
      Offset(resourceStartX + resourceSpacing * 2, navBarHeight / 2),
      '🔋',
      '$playerEnergy',
    );
  }

  // 숫자 포맷팅 (1000 -> 1K)
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  // 개별 리소스 렌더링 헬퍼 (가로 정렬)
  void _renderResourceHorizontal(
    Canvas canvas,
    Offset position,
    String icon,
    String value,
  ) {
    // 아이콘
    _drawCenteredText(
      canvas,
      icon,
      Offset(position.dx, position.dy - 8),
      fontSize: 16,
      color: const Color(0xFF000000),
    );

    // 값
    _drawCenteredText(
      canvas,
      value,
      Offset(position.dx, position.dy + 8),
      fontSize: 11,
      color: const Color(0xFF424242),
    );
  }

  // 스테이지별 배경 렌더링
  void _renderStageBackground(Canvas canvas, int stage) {
    // 네비게이션 바와 하단 메뉴를 제외한 영역에만 배경 렌더링
    const double navBarHeight = 60.0;
    const double titleBoxHeight = 50.0;
    const double topMargin = navBarHeight + titleBoxHeight; // 110px
    final double backgroundHeight = size.y - topMargin - _bottomMenuHeight;

    final backgroundRect = Rect.fromLTWH(0, topMargin, size.x, backgroundHeight);

    Paint bgPaint;
    String emoji1 = '';
    String emoji2 = '';

    switch (stage) {
      case 1: // 초원 & 산
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF87CEEB), // 하늘색
              const Color(0xFF90EE90), // 연한 초록
            ],
          ).createShader(backgroundRect);
        emoji1 = '🏔️'; // 산
        emoji2 = '🌳'; // 나무
        break;

      case 2: // 협곡
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8B7355), // 갈색
              const Color(0xFF654321), // 어두운 갈색
            ],
          ).createShader(backgroundRect);
        emoji1 = '⛰️'; // 산
        emoji2 = '🪨'; // 바위
        break;

      case 3: // 사막
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFA500), // 주황색
              const Color(0xFFEDC9AF), // 모래색
            ],
          ).createShader(backgroundRect);
        emoji1 = '🏜️'; // 사막
        emoji2 = '🌵'; // 선인장
        break;

      case 4: // 바다
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E90FF), // 파란색
              const Color(0xFF006994), // 진한 파란색
            ],
          ).createShader(backgroundRect);
        emoji1 = '🌊'; // 파도
        emoji2 = '🐚'; // 조개
        break;

      case 5: // 화산
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8B0000), // 어두운 빨강
              const Color(0xFFFF4500), // 주황빨강
            ],
          ).createShader(backgroundRect);
        emoji1 = '🌋'; // 화산
        emoji2 = '🔥'; // 불
        break;

      case 6: // 얼음 성
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFB0E0E6), // 파우더 블루
              const Color(0xFFE0FFFF), // 밝은 청록
            ],
          ).createShader(backgroundRect);
        emoji1 = '🏰'; // 성
        emoji2 = '❄️'; // 눈송이
        break;

      case 7: // 천국
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF), // 흰색
              const Color(0xFFFFD700), // 금색
            ],
          ).createShader(backgroundRect);
        emoji1 = '☁️'; // 구름
        emoji2 = '✨'; // 반짝임
        break;

      case 8: // 지옥
        bgPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2B0000), // 매우 어두운 빨강
              const Color(0xFF8B0000), // 어두운 빨강
            ],
          ).createShader(backgroundRect);
        emoji1 = '🔥'; // 불
        emoji2 = '💀'; // 해골
        break;

      default:
        bgPaint = Paint()..color = const Color(0xFFE0E0E0);
        break;
    }

    // 배경 그라데이션 그리기
    canvas.drawRect(backgroundRect, bgPaint);

    // 배경 장식 이모지 그리기 (여러 개 배치)
    if (emoji1.isNotEmpty && emoji2.isNotEmpty) {
      final random = Random(stage); // 스테이지별로 같은 패턴

      // 상단에 이모지1 배치 (타이틀 박스 아래부터)
      for (int i = 0; i < 5; i++) {
        final x = random.nextDouble() * size.x;
        final y = topMargin + 50 + random.nextDouble() * 150;
        _drawCenteredText(
          canvas,
          emoji1,
          Offset(x, y),
          fontSize: 32,
        );
      }

      // 하단에 이모지2 배치 (하단 메뉴 위까지)
      for (int i = 0; i < 5; i++) {
        final x = random.nextDouble() * size.x;
        final y = size.y - _bottomMenuHeight - 150 + random.nextDouble() * 100;
        _drawCenteredText(
          canvas,
          emoji2,
          Offset(x, y),
          fontSize: 28,
        );
      }
    }
  }

  void _renderRoundSelectOverlay(Canvas canvas) {
    // 네비게이션 바 렌더링
    _renderNavigationBar(canvas);

    // 현재 선택된 메뉴에 따라 다른 콘텐츠 렌더링
    switch (currentBottomMenu) {
      case BottomMenu.home:
        _renderHomeContent(canvas);
        break;
      case BottomMenu.shop:
        _renderShopContent(canvas);
        break;
      case BottomMenu.inventory:
        _renderInventoryContent(canvas);
        break;
      case BottomMenu.gacha:
        _renderGachaContent(canvas);
        break;
      case BottomMenu.settings:
        _renderSettingsContent(canvas);
        break;
    }

    // 하단 메뉴 렌더링 (항상 표시)
    _renderBottomMenu(canvas);

    // 파티 슬롯 렌더링 (홈 화면에서만 표시)
    if (currentBottomMenu == BottomMenu.home) {
      _renderPartySlots(canvas);
    }

    // 파티 선택 팝업 (최상단)
    if (showPartySelectionPopup) {
      _renderPartySelectionPopup(canvas);
    }
  }

  // 홈 콘텐츠 (라운드 선택)
  void _renderHomeContent(Canvas canvas) {
    // 스테이지별 배경 렌더링
    _renderStageBackground(canvas, selectedStageInUI);

    // 스테이지 타이틀 박스 (표 형식)
    const double navBarHeight = 60.0;
    const double titleBoxY = navBarHeight; // 네비게이션 바 바로 아래
    const double titleBoxHeight = 50.0;
    final titleBoxRect = Rect.fromLTWH(0, titleBoxY, size.x, titleBoxHeight);

    // 타이틀 박스 배경 (그라데이션 효과)
    final titleBoxPaint = Paint()..color = const Color(0xFF1976D2);
    canvas.drawRect(titleBoxRect, titleBoxPaint);

    // 타이틀 박스 하단 경계선
    final borderPaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(0, titleBoxY + titleBoxHeight),
      Offset(size.x, titleBoxY + titleBoxHeight),
      borderPaint,
    );

    // 스테이지 정보 텍스트
    _drawCenteredText(
      canvas,
      'STAGE $selectedStageInUI',
      Offset(size.x / 2, titleBoxY + titleBoxHeight / 2 - 2),
      fontSize: 20,
      color: const Color(0xFFFFFFFF),
    );

    // 왼쪽 스테이지 변경 버튼 (화살표 버튼)
    final leftButtonRect = _leftStageButtonRect();
    final leftActive = selectedStageInUI > 1;

    final leftButtonPaint = Paint()
      ..color = leftActive
          ? const Color(0xFFFFFFFF)
          : const Color(0xFFBDBDBD);

    canvas.drawRRect(
      RRect.fromRectAndRadius(leftButtonRect, const Radius.circular(6)),
      leftButtonPaint,
    );

    _drawCenteredText(
      canvas,
      '◀',
      leftButtonRect.center,
      fontSize: 18,
      color: leftActive
          ? const Color(0xFF1976D2)
          : const Color(0xFF757575),
    );

    // 오른쪽 스테이지 변경 버튼
    final rightButtonRect = _rightStageButtonRect();
    final rightActive = selectedStageInUI < 8; // 최대 스테이지 8까지

    final rightButtonPaint = Paint()
      ..color = rightActive
          ? const Color(0xFFFFFFFF)
          : const Color(0xFFBDBDBD);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rightButtonRect, const Radius.circular(6)),
      rightButtonPaint,
    );

    _drawCenteredText(
      canvas,
      '▶',
      rightButtonRect.center,
      fontSize: 18,
      color: rightActive
          ? const Color(0xFF1976D2)
          : const Color(0xFF757575),
    );

    const int total = 10; // 라운드 10개
    final unlocked = unlockedRoundMax.clamp(1, total);

    // 캔디크러쉬 사가 스타일: 사각형 타일 렌더링
    for (int i = 1; i <= total; i++) {
      final rect = _roundNodeRect(i);
      final bool isUnlocked = i <= unlocked;
      final bool isCurrent = i == unlocked;
      final bool isBossRound = i == 10;
      final bool isMiniBossRound = i == 5;

      // 타일 배경색
      Color bgColor;
      if (!isUnlocked) {
        bgColor = const Color(0xFFE0E0E0); // 잠금: 회색
      } else if (isBossRound) {
        bgColor = const Color(0xFFE53935); // 보스: 빨강
      } else if (isMiniBossRound) {
        bgColor = const Color(0xFFFB8C00); // 미니보스: 주황
      } else if (isCurrent) {
        bgColor = const Color(0xFF43A047); // 현재: 초록
      } else {
        bgColor = const Color(0xFF42A5F5); // 완료: 파랑
      }

      // 타일 배경
      final bgPaint = Paint()..color = bgColor;
      final tileBorder = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        bgPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        tileBorder,
      );

      // 타일 내용
      if (isUnlocked) {
        if (isBossRound) {
          // 보스 라운드 (라운드 10): 작은 악마 2개 + 큰 악마 머리 1개
          // 왼쪽 작은 악마
          _drawCenteredText(
            canvas,
            '👿',
            Offset(rect.center.dx - 20, rect.center.dy - 8),
            fontSize: 18,
            color: const Color(0xFFFFFFFF),
          );
          // 중앙 큰 악마 머리
          _drawCenteredText(
            canvas,
            '😈',
            Offset(rect.center.dx, rect.center.dy - 8),
            fontSize: 26,
            color: const Color(0xFFFFFFFF),
          );
          // 오른쪽 작은 악마
          _drawCenteredText(
            canvas,
            '👿',
            Offset(rect.center.dx + 20, rect.center.dy - 8),
            fontSize: 18,
            color: const Color(0xFFFFFFFF),
          );
          // 라운드 번호
          _drawCenteredText(
            canvas,
            '$i',
            Offset(rect.center.dx, rect.center.dy + 18),
            fontSize: 14,
            color: const Color(0xFFFFFFFF),
          );
        } else if (isMiniBossRound) {
          // 미니보스 라운드 (라운드 5): 작은 악마 1개
          _drawCenteredText(
            canvas,
            '👿',
            Offset(rect.center.dx, rect.center.dy - 12),
            fontSize: 28,
            color: const Color(0xFFFFFFFF),
          );
          _drawCenteredText(
            canvas,
            '$i',
            Offset(rect.center.dx, rect.center.dy + 14),
            fontSize: 16,
            color: const Color(0xFFFFFFFF),
          );
        } else {
          // 일반 라운드
          _drawCenteredText(
            canvas,
            '$i',
            rect.center,
            fontSize: 32,
            color: const Color(0xFFFFFFFF),
          );

          // 현재 라운드 표시
          if (isCurrent) {
            // 별 표시 (타일 우측 상단)
            _drawCenteredText(
              canvas,
              '★',
              Offset(rect.right - 12, rect.top + 12),
              fontSize: 14,
              color: const Color(0xFFFFD700),
            );
          }
        }
      } else {
        // 잠금 타일
        _drawCenteredText(
          canvas,
          '🔒',
          rect.center,
          fontSize: 28,
          color: const Color(0xFF9E9E9E),
        );
      }
    }

    // God Mode 버튼 (우측 하단, 메뉴 위)
    final godModeRect = _godModeButtonRect();
    final godModeBgPaint = Paint()
      ..color = _godModeEnabled
          ? const Color(0xFFFFD700) // 활성화: 금색
          : const Color(0xFF757575); // 비활성화: 회색

    canvas.drawRRect(
      RRect.fromRectAndRadius(godModeRect, const Radius.circular(8)),
      godModeBgPaint,
    );

    _drawCenteredText(
      canvas,
      _godModeEnabled ? 'GOD ✓' : 'TEST',
      godModeRect.center,
      fontSize: 12,
      color: _godModeEnabled
          ? const Color(0xFF000000) // 활성화: 검은색 텍스트
          : const Color(0xFFFFFFFF), // 비활성화: 흰색 텍스트
    );
  }

  // 파티 선택 팝업 렌더링 (그리드 레이아웃)
  void _renderPartySelectionPopup(Canvas canvas) {
    // 반투명 배경 (전체 화면)
    final overlayPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlayPaint);

    // 팝업 박스
    const double popupWidth = 350.0;
    const double popupHeight = 500.0;
    final double popupX = (size.x - popupWidth) / 2;
    final double popupY = (size.y - popupHeight) / 2;
    final popupRect = Rect.fromLTWH(popupX, popupY, popupWidth, popupHeight);

    // 팝업 배경
    final popupBgPaint = Paint()..color = const Color(0xFF2C2C2C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(popupRect, const Radius.circular(16)),
      popupBgPaint,
    );

    // 팝업 테두리
    final popupBorderPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(popupRect, const Radius.circular(16)),
      popupBorderPaint,
    );

    // 헤더
    _drawCenteredText(
      canvas,
      '캐릭터 선택',
      Offset(popupRect.center.dx, popupY + 25),
      fontSize: 18,
      color: const Color(0xFFFFFFFF),
    );

    // 닫기 버튼 (X)
    final closeButtonRect = Rect.fromLTWH(popupX + popupWidth - 40, popupY + 10, 30, 30);
    final closeButtonPaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(closeButtonRect.center, 15, closeButtonPaint);
    _drawCenteredText(
      canvas,
      '✕',
      closeButtonRect.center,
      fontSize: 18,
      color: const Color(0xFFFFFFFF),
    );

    // 보유 캐릭터가 없는 경우
    if (ownedCharacters.isEmpty) {
      _drawCenteredText(
        canvas,
        '보유한 캐릭터가 없습니다',
        Offset(popupRect.center.dx, popupRect.center.dy),
        fontSize: 16,
        color: const Color(0xFF999999),
      );
      return;
    }

    // 캐릭터 목록 영역 (그리드)
    const double listStartY = 60.0;
    const double bottomButtonHeight = 50.0;
    final double listHeight = popupHeight - listStartY - bottomButtonHeight - 10;

    const double cardWidth = 60.0;
    const double cardHeight = 80.0;
    const double cardSpacing = 10.0;
    const int cardsPerRow = 4;

    // 스크롤 영역 클리핑
    canvas.save();
    final clipRect = Rect.fromLTWH(
      popupX + 15,
      popupY + listStartY,
      popupWidth - 30,
      listHeight,
    );
    canvas.clipRect(clipRect);

    // 배경
    final listBgPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(clipRect, const Radius.circular(8)),
      listBgPaint,
    );

    // 캐릭터별 개수 계산 및 중복 제거
    final characterMap = <String, List<OwnedCharacter>>{};
    for (final character in ownedCharacters) {
      if (!characterMap.containsKey(character.characterId)) {
        characterMap[character.characterId] = [];
      }
      characterMap[character.characterId]!.add(character);
    }

    // 고유 캐릭터 목록으로 렌더링
    final uniqueCharacterIds = characterMap.keys.toList();
    for (int i = 0; i < uniqueCharacterIds.length; i++) {
      final characterId = uniqueCharacterIds[i];
      final characterInstances = characterMap[characterId]!;
      final character = characterInstances.first; // 첫 번째 인스턴스 사용
      final definition = CharacterDefinitions.byId(character.characterId);
      final count = characterInstances.length;

      final row = i ~/ cardsPerRow;
      final col = i % cardsPerRow;

      final double x = popupX + 20 + col * (cardWidth + cardSpacing);
      final double y = popupY + listStartY + 10 + row * (cardHeight + cardSpacing) - partyPopupScrollOffset;

      // 화면 밖이면 스킵
      if (y + cardHeight < popupY + listStartY || y > popupY + listStartY + listHeight) {
        continue;
      }

      final cardRect = Rect.fromLTWH(x, y, cardWidth, cardHeight);

      // 이 캐릭터의 어떤 인스턴스라도 파티에 있는지 확인
      final isInParty = characterInstances.any((c) => partySlots.contains(c.instanceId));

      // 카드 배경
      final cardBgPaint = Paint()..color = isInParty
          ? const Color(0xFF1B5E20) // 파티에 있으면 어두운 초록
          : const Color(0xFF424242);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
        cardBgPaint,
      );

      // 카드 테두리 (랭크 색상)
      Color rankColor;
      switch (definition.rank) {
        case RankType.s:
          rankColor = const Color(0xFFFFD700);
          break;
        case RankType.a:
          rankColor = const Color(0xFFFF6B6B);
          break;
        case RankType.b:
          rankColor = const Color(0xFF4ECDC4);
          break;
        case RankType.c:
          rankColor = const Color(0xFFBDBDBD);
          break;
      }

      final cardBorderPaint = Paint()
        ..color = rankColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
        cardBorderPaint,
      );

      // 랭크 표시 (좌측 상단)
      _drawText(
        canvas,
        definition.rank.displayName,
        Offset(x + 4, y + 4),
        fontSize: 10,
        color: rankColor,
      );

      // 캐릭터 이름 (중앙)
      _drawCenteredText(
        canvas,
        definition.name,
        Offset(cardRect.center.dx, y + cardHeight / 2),
        fontSize: 10,
        color: const Color(0xFFFFFFFF),
      );

      // 레벨 (하단)
      _drawCenteredText(
        canvas,
        'Lv.${character.level}',
        Offset(cardRect.center.dx, y + cardHeight - 12),
        fontSize: 9,
        color: const Color(0xFFBDBDBD),
      );

      // 파티에 있으면 체크 표시
      if (isInParty) {
        _drawText(
          canvas,
          '✓',
          Offset(x + cardWidth - 15, y + 4),
          fontSize: 12,
          color: const Color(0xFF4CAF50),
        );
      }

      // 개수 표시 (우측 하단, 2개 이상일 때만)
      if (count > 1) {
        // 배경 원
        final countBgPaint = Paint()..color = const Color(0xCC000000);
        canvas.drawCircle(
          Offset(x + cardWidth - 12, y + cardHeight - 12),
          10,
          countBgPaint,
        );

        // 개수 텍스트
        _drawCenteredText(
          canvas,
          'x$count',
          Offset(x + cardWidth - 12, y + cardHeight - 12),
          fontSize: 8,
          color: const Color(0xFFFFFFFF),
        );
      }
    }

    canvas.restore();

    // "제거" 버튼 (슬롯에 캐릭터가 있는 경우만)
    if (selectedPartySlotIndex >= 0 && partySlots[selectedPartySlotIndex] != null) {
      final removeButtonRect = Rect.fromLTWH(
        popupX + 20,
        popupY + popupHeight - 45,
        popupWidth - 40,
        35,
      );

      final removeButtonPaint = Paint()..color = const Color(0xFFFF5252);
      canvas.drawRRect(
        RRect.fromRectAndRadius(removeButtonRect, const Radius.circular(8)),
        removeButtonPaint,
      );

      _drawCenteredText(
        canvas,
        '파티에서 제거',
        removeButtonRect.center,
        fontSize: 14,
        color: const Color(0xFFFFFFFF),
      );
    }
  }

  // 파티 슬롯 렌더링 (도감 스타일)
  void _renderPartySlots(Canvas canvas) {
    const double bottomMenuHeight = 70.0;
    const double slotSize = 60.0; // 도감과 동일한 크기
    const double slotSpacing = 10.0; // 도감과 동일한 간격
    final double slotY = size.y - bottomMenuHeight - slotSize - 8.0; // 푸터 바로 위

    // 파티 설정 배경 (반투명 회색)
    const double bgPadding = 10.0;
    final double bgWidth = (slotSize * 4) + (slotSpacing * 3) + (bgPadding * 2);
    final double bgX = (size.x - bgWidth) / 2;
    final bgRect = Rect.fromLTWH(bgX, slotY - bgPadding - 15, bgWidth, slotSize + bgPadding * 2 + 15);

    final bgPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
      bgPaint,
    );

    // "PARTY" 라벨 (위쪽에 배치)
    _drawCenteredText(
      canvas,
      'PARTY',
      Offset(bgRect.center.dx, bgRect.top + 10),
      fontSize: 10,
      color: const Color(0xFFFFFFFF),
    );

    // 4개의 슬롯 렌더링 (도감 스타일)
    for (int i = 0; i < 4; i++) {
      final double slotX = (size.x - (slotSize * 4 + slotSpacing * 3)) / 2 + i * (slotSize + slotSpacing);
      final slotRect = Rect.fromLTWH(slotX, slotY, slotSize, slotSize);

      final instanceId = partySlots[i];

      if (instanceId != null) {
        // 캐릭터가 설정된 경우
        final character = ownedCharacters.firstWhere(
          (c) => c.instanceId == instanceId,
          orElse: () => ownedCharacters.first,
        );
        final definition = CharacterDefinitions.byId(character.characterId);

        // 카드 배경 (랭크 색상 + 반투명)
        final bgColor = Color(definition.rank.color).withOpacity(0.3);
        final cardPaint = Paint()..color = bgColor;
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(8)),
          cardPaint,
        );

        // 테두리 (랭크 색상)
        final borderPaint = Paint()
          ..color = Color(definition.rank.color)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(8)),
          borderPaint,
        );

        // 랭크 표시 (상단)
        _drawCenteredText(
          canvas,
          definition.rank.displayName,
          Offset(slotRect.center.dx, slotY + 12),
          fontSize: 10,
          color: Color(definition.rank.color),
        );

        // 역할 이모지 (중앙)
        _drawCenteredText(
          canvas,
          definition.role.emoji,
          Offset(slotRect.center.dx, slotRect.center.dy - 2),
          fontSize: 22,
        );

        // 캐릭터 이름 (하단, 짧게)
        final shortName = definition.name.length > 5
            ? '${definition.name.substring(0, 5)}..'
            : definition.name;
        _drawCenteredText(
          canvas,
          shortName,
          Offset(slotRect.center.dx, slotY + slotSize - 12),
          fontSize: 8,
          color: const Color(0xFF000000),
        );

        // 레벨 배지 (우측 하단)
        final levelBadgeRect = Rect.fromLTWH(
          slotX + slotSize - 22,
          slotY + slotSize - 18,
          20,
          14,
        );
        final levelBadgePaint = Paint()..color = const Color(0xFF4CAF50);
        canvas.drawRRect(
          RRect.fromRectAndRadius(levelBadgeRect, const Radius.circular(7)),
          levelBadgePaint,
        );
        _drawCenteredText(
          canvas,
          'L${character.level}',
          levelBadgeRect.center,
          fontSize: 8,
          color: const Color(0xFFFFFFFF),
        );
      } else {
        // 빈 슬롯 (도감 스타일)
        final slotBgPaint = Paint()..color = const Color(0xFFBDBDBD);
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(8)),
          slotBgPaint,
        );

        // 테두리
        final slotBorderPaint = Paint()
          ..color = const Color(0xFF757575)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(8)),
          slotBorderPaint,
        );

        // 빈 슬롯 표시
        _drawCenteredText(
          canvas,
          '+',
          slotRect.center,
          fontSize: 28,
          color: const Color(0xFF757575),
        );
      }
    }
  }

  // 상점 콘텐츠 (플레이스홀더)
  void _renderShopContent(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '🏪 상점',
      Offset(size.x / 2, size.y * 0.4),
      fontSize: 32,
      color: const Color(0xFF000000),
    );

    _drawCenteredText(
      canvas,
      '준비 중...',
      Offset(size.x / 2, size.y * 0.5),
      fontSize: 18,
      color: const Color(0xFF666666),
    );
  }

  // 인벤토리 콘텐츠 (플레이스홀더)
  void _renderInventoryContent(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '🎒 인벤토리',
      Offset(size.x / 2, size.y * 0.4),
      fontSize: 32,
      color: const Color(0xFF000000),
    );

    _drawCenteredText(
      canvas,
      '준비 중...',
      Offset(size.x / 2, size.y * 0.5),
      fontSize: 18,
      color: const Color(0xFF666666),
    );
  }

  // 뽑기 콘텐츠 (플레이스홀더)
  void _renderGachaContent(Canvas canvas) {
    const double navBarHeight = 60.0;
    const double contentStartY = navBarHeight + 10;

    // 뽑기 결과 표시 중이면 결과 화면
    if (gachaResults != null && gachaResults!.isNotEmpty) {
      _renderGachaResults(canvas);
      return;
    }

    // 타이틀 & 젬 표시 (한 줄로 압축)
    _drawCenteredText(
      canvas,
      '🎰 소환  |  💎 $playerGem',
      Offset(size.x / 2, contentStartY + 15),
      fontSize: 18,
      color: const Color(0xFF000000),
    );

    // 단일 뽑기 버튼
    final singleButtonRect = _gachaSingleButtonRect();
    final singleCost = gachaSystem.getSingleSummonCost();
    final canAffordSingle = playerGem >= singleCost;

    final singleBgPaint = Paint()
      ..color = canAffordSingle
          ? const Color(0xFF4CAF50)
          : const Color(0xFFBDBDBD);

    canvas.drawRRect(
      RRect.fromRectAndRadius(singleButtonRect, const Radius.circular(12)),
      singleBgPaint,
    );

    _drawCenteredText(
      canvas,
      '단일 소환',
      Offset(singleButtonRect.center.dx, singleButtonRect.center.dy - 15),
      fontSize: 20,
      color: const Color(0xFFFFFFFF),
    );

    _drawCenteredText(
      canvas,
      '💎 $singleCost',
      Offset(singleButtonRect.center.dx, singleButtonRect.center.dy + 10),
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );

    // 10연차 뽑기 버튼
    final tenButtonRect = _gachaTenButtonRect();
    final tenCost = gachaSystem.getTenSummonCost();
    final canAffordTen = playerGem >= tenCost;

    final tenBgPaint = Paint()
      ..color = canAffordTen ? const Color(0xFFFF9800) : const Color(0xFFBDBDBD);

    canvas.drawRRect(
      RRect.fromRectAndRadius(tenButtonRect, const Radius.circular(12)),
      tenBgPaint,
    );

    _drawCenteredText(
      canvas,
      '10연차 소환',
      Offset(tenButtonRect.center.dx, tenButtonRect.center.dy - 25),
      fontSize: 20,
      color: const Color(0xFFFFFFFF),
    );

    _drawCenteredText(
      canvas,
      '💎 $tenCost',
      Offset(tenButtonRect.center.dx, tenButtonRect.center.dy),
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );

    _drawCenteredText(
      canvas,
      '(A랭크 이상 1개 보장)',
      Offset(tenButtonRect.center.dx, tenButtonRect.center.dy + 20),
      fontSize: 12,
      color: const Color(0xFFFFFFFF),
    );

    // 확률 안내
    const infoStartY = 135.0;
    _drawCenteredText(
      canvas,
      'S: 3% | A: 12% | B: 35% | C: 50%',
      Offset(size.x / 2, infoStartY),
      fontSize: 11,
      color: const Color(0xFF666666),
    );

    // 캐릭터 도감 영역
    _renderCharacterCollection(canvas);
  }

  Rect _gachaSingleButtonRect() {
    const double navBarHeight = 60.0;
    const double buttonWidth = 140.0;
    const double buttonHeight = 70.0;
    const double buttonSpacing = 10.0;
    const double topMargin = 15.0;

    final double centerX = size.x / 2;
    final double y = navBarHeight + topMargin;

    return Rect.fromLTWH(centerX - buttonWidth - buttonSpacing / 2, y, buttonWidth, buttonHeight);
  }

  Rect _gachaTenButtonRect() {
    const double navBarHeight = 60.0;
    const double buttonWidth = 140.0;
    const double buttonHeight = 70.0;
    const double buttonSpacing = 10.0;
    const double topMargin = 15.0;

    final double centerX = size.x / 2;
    final double y = navBarHeight + topMargin;

    return Rect.fromLTWH(centerX + buttonSpacing / 2, y, buttonWidth, buttonHeight);
  }

  void _renderCharacterCollection(Canvas canvas) {
    const double navBarHeight = 60.0;
    const double collectionStartY = 165.0;
    const double bottomMenuHeight = 70.0;
    const double availableHeight = 600.0 - collectionStartY - bottomMenuHeight - 20;

    // 타이틀
    _drawCenteredText(
      canvas,
      '📖 캐릭터 도감',
      Offset(size.x / 2, collectionStartY),
      fontSize: 16,
      color: const Color(0xFF000000),
    );

    // 보유/전체 표시 및 중복 개수 계산
    final ownedCountMap = <String, int>{};
    for (final owned in ownedCharacters) {
      ownedCountMap[owned.characterId] =
          (ownedCountMap[owned.characterId] ?? 0) + 1;
    }
    final totalCharacters = CharacterDefinitions.all.length;
    final ownedCount = ownedCountMap.keys.length;

    _drawCenteredText(
      canvas,
      '보유: $ownedCount / $totalCharacters',
      Offset(size.x / 2, collectionStartY + 25),
      fontSize: 12,
      color: const Color(0xFF666666),
    );

    // 캐릭터 리스트 영역
    const double listStartY = collectionStartY + 50;
    const double cardWidth = 60.0;
    const double cardHeight = 80.0;
    const double cardSpacing = 10.0;
    const int cardsPerRow = 5;

    // 스크롤 영역 클리핑
    canvas.save();
    final clipRect = Rect.fromLTWH(
      10,
      listStartY,
      size.x - 20,
      availableHeight,
    );
    canvas.clipRect(clipRect);

    // 배경
    final bgPaint = Paint()..color = const Color(0xFFF5F5F5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(clipRect, const Radius.circular(8)),
      bgPaint,
    );

    // 캐릭터 카드 렌더링
    final allCharacters = CharacterDefinitions.all;
    final totalRows = (allCharacters.length / cardsPerRow).ceil();

    for (int i = 0; i < allCharacters.length; i++) {
      final character = allCharacters[i];
      final row = i ~/ cardsPerRow;
      final col = i % cardsPerRow;

      final count = ownedCountMap[character.id] ?? 0;
      final isOwned = count > 0;

      final double x = 15 + col * (cardWidth + cardSpacing);
      final double y = listStartY + 10 + row * (cardHeight + cardSpacing) -
          characterListScrollOffset;

      // 화면 밖이면 스킵
      if (y + cardHeight < listStartY || y > listStartY + availableHeight) {
        continue;
      }

      _renderCharacterCard(
        canvas,
        character,
        Offset(x, y),
        cardWidth,
        cardHeight,
        isOwned,
        count,
      );
    }

    canvas.restore();

    // 스크롤 인디케이터
    if (totalRows * (cardHeight + cardSpacing) > availableHeight) {
      final scrollBarHeight = availableHeight * 0.3;
      final maxScroll =
          totalRows * (cardHeight + cardSpacing) - availableHeight + 20;
      final scrollRatio = characterListScrollOffset / maxScroll;

      final indicatorY =
          listStartY + scrollRatio * (availableHeight - scrollBarHeight);

      final scrollBarPaint = Paint()..color = const Color(0x80000000);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.x - 15, indicatorY, 5, scrollBarHeight),
          const Radius.circular(2.5),
        ),
        scrollBarPaint,
      );
    }
  }

  void _renderCharacterCard(
    Canvas canvas,
    CharacterDefinition character,
    Offset position,
    double width,
    double height,
    bool isOwned,
    int count,
  ) {
    final cardRect = Rect.fromLTWH(position.dx, position.dy, width, height);

    // 카드 배경
    final bgColor = isOwned
        ? Color(character.rank.color).withOpacity(0.3)
        : const Color(0xFFBDBDBD);

    final cardPaint = Paint()..color = bgColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
      cardPaint,
    );

    // 테두리
    final borderPaint = Paint()
      ..color = isOwned ? Color(character.rank.color) : const Color(0xFF757575)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
      borderPaint,
    );

    if (isOwned) {
      // 랭크 표시
      _drawCenteredText(
        canvas,
        character.rank.displayName,
        Offset(cardRect.center.dx, cardRect.top + 12),
        fontSize: 10,
        color: Color(character.rank.color),
      );

      // 역할 이모지
      _drawCenteredText(
        canvas,
        character.role.emoji,
        Offset(cardRect.center.dx, cardRect.center.dy - 5),
        fontSize: 24,
      );

      // 캐릭터 이름 (짧게)
      final shortName = character.name.length > 6
          ? '${character.name.substring(0, 6)}..'
          : character.name;

      _drawCenteredText(
        canvas,
        shortName,
        Offset(cardRect.center.dx, cardRect.bottom - 15),
        fontSize: 9,
        color: const Color(0xFF000000),
      );

      // 중복 보유 개수 표시 (2개 이상일 때만)
      if (count > 1) {
        // 우측 상단에 배지 형태로 표시
        final badgeRect = Rect.fromLTWH(
          cardRect.right - 20,
          cardRect.top + 2,
          18,
          12,
        );

        final badgePaint = Paint()..color = const Color(0xFFFF5252);
        canvas.drawRRect(
          RRect.fromRectAndRadius(badgeRect, const Radius.circular(6)),
          badgePaint,
        );

        _drawCenteredText(
          canvas,
          'x$count',
          Offset(badgeRect.center.dx, badgeRect.center.dy),
          fontSize: 8,
          color: const Color(0xFFFFFFFF),
        );
      }
    } else {
      // 잠김 아이콘
      _drawCenteredText(
        canvas,
        '🔒',
        Offset(cardRect.center.dx, cardRect.center.dy - 10),
        fontSize: 20,
        color: const Color(0xFF757575),
      );

      // ???
      _drawCenteredText(
        canvas,
        '???',
        Offset(cardRect.center.dx, cardRect.bottom - 15),
        fontSize: 10,
        color: const Color(0xFF757575),
      );
    }
  }

  void _renderGachaResults(Canvas canvas) {
    if (gachaResults == null || gachaResults!.isEmpty) return;

    const double navBarHeight = 60.0;
    const double startY = navBarHeight + 40;

    // 배경 어둡게
    final dimPaint = Paint()..color = const Color(0xDD000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), dimPaint);

    // 타이틀
    _drawCenteredText(
      canvas,
      '✨ 소환 결과 ✨',
      Offset(size.x / 2, startY),
      fontSize: 26,
      color: const Color(0xFFFFFFFF),
    );

    // 현재 표시 중인 캐릭터
    if (gachaResultIndex < gachaResults!.length) {
      final character = gachaResults![gachaResultIndex];
      final cardY = startY + 80;

      // 카드 배경
      final cardRect = Rect.fromCenter(
        center: Offset(size.x / 2, cardY + 100),
        width: 280,
        height: 200,
      );

      final cardPaint = Paint()..color = Color(character.rank.color);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(16)),
        cardPaint,
      );

      // 랭크 표시
      _drawCenteredText(
        canvas,
        '${character.rank.displayName} 랭크',
        Offset(size.x / 2, cardY + 20),
        fontSize: 20,
        color: const Color(0xFFFFFFFF),
      );

      // 역할 이모지
      _drawCenteredText(
        canvas,
        character.role.emoji,
        Offset(size.x / 2, cardY + 60),
        fontSize: 40,
      );

      // 캐릭터 이름
      _drawCenteredText(
        canvas,
        character.name,
        Offset(size.x / 2, cardY + 120),
        fontSize: 18,
        color: const Color(0xFFFFFFFF),
      );

      // 역할
      _drawCenteredText(
        canvas,
        character.role.displayName,
        Offset(size.x / 2, cardY + 145),
        fontSize: 14,
        color: const Color(0xFFE0E0E0),
      );

      // 진행 상황
      _drawCenteredText(
        canvas,
        '${gachaResultIndex + 1} / ${gachaResults!.length}',
        Offset(size.x / 2, cardY + 180),
        fontSize: 14,
        color: const Color(0xFFFFFFFF),
      );

      // 안내 메시지
      _drawCenteredText(
        canvas,
        '화면을 터치하여 계속',
        Offset(size.x / 2, size.y - 120),
        fontSize: 16,
        color: const Color(0xFFFFFFFF),
      );
    }
  }

  // 설정 콘텐츠 (플레이스홀더)
  void _renderSettingsContent(Canvas canvas) {
    _drawCenteredText(
      canvas,
      '⚙️ 설정',
      Offset(size.x / 2, size.y * 0.4),
      fontSize: 32,
      color: const Color(0xFF000000),
    );

    _drawCenteredText(
      canvas,
      '준비 중...',
      Offset(size.x / 2, size.y * 0.5),
      fontSize: 18,
      color: const Color(0xFF666666),
    );
  }

  // 하단 메뉴 렌더링
  void _renderBottomMenu(Canvas canvas) {
    // 메뉴 배경
    final menuBgPaint = Paint()..color = const Color(0xFFFFFFFF);
    final menuRect = Rect.fromLTWH(0, size.y - _bottomMenuHeight, size.x, _bottomMenuHeight);
    canvas.drawRect(menuRect, menuBgPaint);

    // 상단 경계선
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.y - _bottomMenuHeight),
      Offset(size.x, size.y - _bottomMenuHeight),
      borderPaint,
    );

    // 메뉴 아이템들
    final menuItems = [
      {'icon': '🏪', 'label': '상점', 'menu': BottomMenu.shop},
      {'icon': '🎒', 'label': '인벤토리', 'menu': BottomMenu.inventory},
      {'icon': '🏠', 'label': '홈', 'menu': BottomMenu.home},
      {'icon': '🎰', 'label': '뽑기', 'menu': BottomMenu.gacha},
      {'icon': '⚙️', 'label': '설정', 'menu': BottomMenu.settings},
    ];

    for (int i = 0; i < menuItems.length; i++) {
      final item = menuItems[i];
      final rect = _bottomMenuButtonRect(i);
      final isSelected = currentBottomMenu == item['menu'];

      // 선택된 메뉴 배경
      if (isSelected) {
        final selectedBgPaint = Paint()..color = const Color(0xFFE3F2FD);
        canvas.drawRect(rect, selectedBgPaint);
      }

      // 아이콘
      _drawCenteredText(
        canvas,
        item['icon'] as String,
        Offset(rect.center.dx, rect.center.dy - 12),
        fontSize: 24,
        color: isSelected ? const Color(0xFF1976D2) : const Color(0xFF666666),
      );

      // 라벨
      _drawCenteredText(
        canvas,
        item['label'] as String,
        Offset(rect.center.dx, rect.center.dy + 12),
        fontSize: 11,
        color: isSelected ? const Color(0xFF1976D2) : const Color(0xFF666666),
      );
    }
  }

  // D-1-6: 라운드 클리어 연출 (강화)
  void _renderRoundClearOverlay(Canvas canvas) {
    // 반투명 오버레이 (그라디언트 느낌)
    final overlayPaint = Paint()..color = const Color(0xA0000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlayPaint);

    String title = 'Round $currentRound Clear!';
    Color titleColor = const Color(0xFF00E676);
    bool isBoss = false;
    bool isMiniBoss = false;

    final cfg = kStageConfigs[stageLevel];
    if (cfg != null && currentRound <= cfg.rounds.length) {
      final roundCfg = cfg.rounds[currentRound - 1];
      if (roundCfg.monsterType == MonsterType.boss) {
        title = '🎉 BOSS DEFEATED! 🎉';
        titleColor = const Color(0xFFFFD700);
        isBoss = true;
      } else if (roundCfg.monsterType == MonsterType.miniBoss) {
        title = '⚡ MINI BOSS DEFEATED! ⚡';
        titleColor = const Color(0xFFFF6E40);
        isMiniBoss = true;
      }
    }

    // 보스/미니보스 클리어 시: 배경 광채 펄스
    if (isBoss || isMiniBoss) {
      final double pulseAlpha = 0.08 + 0.07 * sin(gameTime * 4);
      final glowColor = isBoss ? const Color(0xFFFFD700) : const Color(0xFFFF6E40);
      final glowPaint = Paint()
        ..color = Color.fromRGBO(
          glowColor.red, glowColor.green, glowColor.blue, pulseAlpha);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), glowPaint);
    }

    // 제목 (펄스 크기 효과: sin으로 폰트 크기 미세 변동은 Canvas로 불가 → 색상 밝기로 대신)
    final double textBrightness = 0.85 + 0.15 * sin(gameTime * 3);
    final r = (titleColor.red * textBrightness).clamp(0.0, 255.0).toInt();
    final g = (titleColor.green * textBrightness).clamp(0.0, 255.0).toInt();
    final b = (titleColor.blue * textBrightness).clamp(0.0, 255.0).toInt();
    _drawCenteredText(
      canvas, title,
      Offset(size.x / 2, size.y * 0.38),
      fontSize: isBoss ? 26 : 24,
      color: Color.fromRGBO(r, g, b, 1.0),
    );

    // 스테이지 표시
    _drawCenteredText(
      canvas, 'Stage $stageLevel',
      Offset(size.x / 2, size.y * 0.48),
      fontSize: 13,
      color: const Color(0xFFAAAAAA),
    );

    // D-1-6: 획득 XP/골드 플라이인 애니메이션
    // t=0~0.5s: 슬라이드업+페이드인 / t=0.5~2.5s: 유지 / t=2.5~3.0s: 페이드아웃
    if (_roundXpGained > 0 || _roundGoldGained > 0) {
      final double t = _roundClearTimer.clamp(0.0, _roundClearDuration);
      final double flyAlpha;
      final double slideY;
      if (t < 0.5) {
        final double p = t / 0.5;
        flyAlpha = p;
        slideY = 20.0 * (1.0 - p);
      } else if (t < 2.5) {
        flyAlpha = 1.0;
        slideY = 0.0;
      } else {
        final double p = (t - 2.5) / 0.5;
        flyAlpha = (1.0 - p).clamp(0.0, 1.0);
        slideY = 0.0;
      }
      // XP 획득 표시 (파란색, 좌측)
      if (_roundXpGained > 0) {
        _drawCenteredText(
          canvas,
          '+$_roundXpGained XP',
          Offset(size.x * 0.35, size.y * 0.57 + slideY),
          fontSize: 18,
          color: Color.fromRGBO(33, 150, 243, flyAlpha),
        );
      }
      // 골드 획득 표시 (금색, 우측)
      if (_roundGoldGained > 0) {
        _drawCenteredText(
          canvas,
          '+${_roundGoldGained}G',
          Offset(size.x * 0.65, size.y * 0.57 + slideY),
          fontSize: 18,
          color: Color.fromRGBO(255, 215, 0, flyAlpha),
        );
      }
    }

    // 다음 라운드 카운트다운 바
    final double progressRatio = _roundClearDuration > 0
        ? (1.0 - _roundClearTimer / _roundClearDuration).clamp(0.0, 1.0)
        : 0.0;
    const double barW = 160.0;
    const double barH = 6.0;
    final double barX = size.x / 2 - barW / 2;
    final double barY = size.y * 0.64;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(3)),
      Paint()..color = const Color(0xFF333333),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW * progressRatio, barH), const Radius.circular(3)),
      Paint()..color = const Color(0xFF4CAF50),
    );

    _drawCenteredText(
      canvas, '다음 라운드 준비 중...',
      Offset(size.x / 2, size.y * 0.59),
      fontSize: 13,
      color: const Color(0xFF888888),
    );
  }

  void _renderPausedOverlay(Canvas canvas) {
    // 반투명 어두운 배경
    final overlayPaint = Paint()..color = const Color(0xC0000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      overlayPaint,
    );

    // 제목
    _drawCenteredText(
      canvas,
      '일시정지',
      Offset(size.x / 2, size.y * 0.35),
      fontSize: 32,
      color: const Color(0xFFFFFFFF),
    );

    // 버튼 그리기
    final resumeRect = _pauseResumeButtonRect();
    final roundSelectRect = _pauseRoundSelectButtonRect();
    final retryRect = _pauseRetryButtonRect();

    final buttonPaint = Paint()..color = const Color(0xFF424242);
    final buttonTextColor = const Color(0xFFFFFFFF);

    // 재개 버튼
    canvas.drawRect(resumeRect, buttonPaint);
    _drawCenteredText(
      canvas,
      '재개',
      Offset(
        resumeRect.left + resumeRect.width / 2,
        resumeRect.top + resumeRect.height / 2 - 8,
      ),
      fontSize: 18,
      color: buttonTextColor,
    );

    // 라운드 선택 버튼
    canvas.drawRect(roundSelectRect, buttonPaint);
    _drawCenteredText(
      canvas,
      '라운드 선택',
      Offset(
        roundSelectRect.left + roundSelectRect.width / 2,
        roundSelectRect.top + roundSelectRect.height / 2 - 8,
      ),
      fontSize: 18,
      color: buttonTextColor,
    );

    // 재시작 버튼
    canvas.drawRect(retryRect, buttonPaint);
    _drawCenteredText(
      canvas,
      '재시작',
      Offset(
        retryRect.left + retryRect.width / 2,
        retryRect.top + retryRect.height / 2 - 8,
      ),
      fontSize: 18,
      color: buttonTextColor,
    );
  }

  void _renderResultOverlay(Canvas canvas) {
    // 게임 오버 (성 HP=0) 는 전용 화면으로
    if (!_lastStageClear) {
      _renderGameOver(canvas);
      return;
    }

    final overlayPaint = Paint()..color = const Color(0xC0000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      overlayPaint,
    );

    // 클리어 제목
    _drawCenteredText(
      canvas,
      'Round $currentRound クリア!',
      Offset(size.x / 2, size.y * 0.25),
      fontSize: 28,
      color: const Color(0xFF00E676),
    );

    // 별점 표시
    final stars = _calculateStars();
    _renderStars(canvas, stars, Offset(size.x / 2, size.y * 0.35));

    // 무찌른 적 수
    _drawCenteredText(
      canvas,
      '討伐: $defeatedMonsters / $totalMonstersInRound',
      Offset(size.x / 2, size.y * 0.45),
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );

    final retryRect = _resultRetryButtonRect();
    final roundSelectRect = _resultRoundSelectButtonRect();
    final nextRect = _resultNextRoundButtonRect();

    _drawButton(canvas, retryRect, 'もう一度');
    _drawButton(canvas, roundSelectRect, 'ステージ選択');

    final nextRound = currentRound + 1;
    if (nextRound <= totalRoundsInStage) {
      _drawButton(canvas, nextRect, '次のラウンド', enabled: true);
    }
  }

  // 별점 계산 (처치한 몬스터 비율 기준)
  int _calculateStars() {
    if (totalMonstersInRound == 0) return 0;

    final ratio = defeatedMonsters / totalMonstersInRound;

    if (ratio >= 1.0) {
      return 3; // 100%: 별 3개
    } else if (ratio >= 0.7) {
      return 2; // 70% 이상: 별 2개
    } else if (ratio >= 0.4) {
      return 1; // 40% 이상: 별 1개
    } else {
      return 0; // 40% 미만: 별 0개
    }
  }

  // D-2-3: 게임 오버 화면 (성 HP=0, 성 붕괴 연출 → 리저트)
  void _renderGameOver(Canvas canvas) {
    // 완전 어두운 배경
    final bgPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // 화면 주변 붉은 비네트 효과
    final vignettePaint = Paint()
      ..color = const Color(0x88EF1515)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), vignettePaint);

    // 성 붕괴 그래픽 (파편 표현)
    final ruinPaint = Paint()..color = const Color(0xFF444444);
    final ruinBroken = Paint()..color = const Color(0xFF2A2A2A);
    // 성터 기반부
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 40, size.y * 0.28, 80, 60),
      ruinPaint,
    );
    // 부서진 파편 (좌상)
    canvas.save();
    canvas.translate(size.x / 2 - 55, size.y * 0.22);
    canvas.rotate(0.3);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 28, 18), ruinBroken);
    canvas.restore();
    // 부서진 파편 (우)
    canvas.save();
    canvas.translate(size.x / 2 + 35, size.y * 0.24);
    canvas.rotate(-0.2);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 22, 14), ruinBroken);
    canvas.restore();
    // 파편 작은 것들
    for (int k = 0; k < 5; k++) {
      final double px = size.x / 2 - 50 + k * 22.0;
      final double py = size.y * 0.30 + (k.isEven ? -8.0 : 0.0);
      canvas.drawRect(Rect.fromLTWH(px, py, 8, 8), ruinBroken);
    }
    // 균열 라인
    final crackPaint = Paint()
      ..color = const Color(0xFFEF5350)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.x / 2 - 20, size.y * 0.28),
      Offset(size.x / 2 + 10, size.y * 0.35),
      crackPaint,
    );
    canvas.drawLine(
      Offset(size.x / 2 + 10, size.y * 0.35),
      Offset(size.x / 2, size.y * 0.38),
      crackPaint,
    );

    // "GAME OVER" 타이틀
    _drawCenteredText(
      canvas,
      'GAME OVER',
      Offset(size.x / 2, size.y * 0.47),
      fontSize: 34,
      color: const Color(0xFFEF5350),
    );

    // 서브 타이틀
    _drawCenteredText(
      canvas,
      '城が陥落しました',
      Offset(size.x / 2, size.y * 0.555),
      fontSize: 16,
      color: const Color(0xFFBBBBBB),
    );

    // 통계 구분선
    final statLinePaint = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(size.x * 0.2, size.y * 0.60),
      Offset(size.x * 0.8, size.y * 0.60),
      statLinePaint,
    );

    // 통계: 라운드 & 처치 수
    _drawCenteredText(
      canvas,
      'ラウンド $currentRound  |  討伐 $defeatedMonsters',
      Offset(size.x / 2, size.y * 0.635),
      fontSize: 14,
      color: const Color(0xFF888888),
    );

    // 버튼 (재시도 / 스테이지 선택)
    final retryRect  = _resultRetryButtonRect();
    final selectRect = _resultRoundSelectButtonRect();

    // 재시도 버튼 (레드 테마)
    canvas.drawRRect(
      RRect.fromRectAndRadius(retryRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFFB71C1C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(retryRect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFFEF5350)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _drawCenteredText(
      canvas,
      'もう一度',
      retryRect.center,
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );

    // 스테이지 선택 버튼
    _drawButton(canvas, selectRect, 'ステージ選択');
  }

  // 별 렌더링
  void _renderStars(Canvas canvas, int starCount, Offset center) {
    const double starSize = 30.0;
    const double starSpacing = 45.0;

    final startX = center.dx - starSpacing;

    for (int i = 0; i < 3; i++) {
      final x = startX + (i * starSpacing);
      final starCenter = Offset(x, center.dy);

      if (i < starCount) {
        // 획득한 별 (노란색)
        _drawCenteredText(
          canvas,
          '★',
          starCenter,
          fontSize: starSize,
          color: const Color(0xFFFFD700),
        );
      } else {
        // 획득하지 못한 별 (회색)
        _drawCenteredText(
          canvas,
          '☆',
          starCenter,
          fontSize: starSize,
          color: const Color(0xFF757575),
        );
      }
    }
  }

  // -----------------------------
  // 버튼 / 텍스트 헬퍼
  // -----------------------------
  void _drawButton(
    Canvas canvas,
    Rect rect,
    String label, {
    bool enabled = true,
  }) {
    final bgColor = enabled ? const Color(0xFF3949AB) : const Color(0xFFB0BEC5);

    final bgPaint = Paint()..color = bgColor;
    final borderPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    _drawCenteredText(
      canvas,
      label,
      rect.center,
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
    );
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center, {
    double fontSize = 16,
    bool multiLine = false,
    Color color = const Color(0xFFFFFFFF),
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: multiLine ? null : 3,
    )..layout();

    final offset = Offset(center.dx - tp.width / 2, center.dy - tp.height / 2);
    tp.paint(canvas, offset);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    double fontSize = 14,
    bool alignCenter = false,
    Color color = const Color(0xFFFFFFFF),
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: alignCenter ? TextAlign.center : TextAlign.left,
      maxLines: 2,
    )..layout();

    Offset drawOffset = offset;
    if (alignCenter) {
      drawOffset = Offset(
        offset.dx - tp.width / 2,
        offset.dy - tp.height / 2,
      );
    }

    tp.paint(canvas, drawOffset);
  }

  // ============================================================
  // D-1-3: 버추얼 스틱 UI (화면 좌측 하단, 외경 60px, 노브 25px)
  // ============================================================
  void _renderVirtualStick(Canvas canvas) {
    const double outerRadius = 60.0;
    const double knobRadius = 25.0;
    const double marginLeft = 80.0;
    const double marginBottom = 110.0;
    final Offset baseCenter = Offset(marginLeft, size.y - marginBottom);

    // 외부 링 (반투명 흰색 채우기)
    final outerFillPaint = Paint()..color = const Color(0x22FFFFFF);
    canvas.drawCircle(baseCenter, outerRadius, outerFillPaint);

    // 외부 링 테두리
    final outerBorderPaint = Paint()
      ..color = const Color(0x88FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(baseCenter, outerRadius, outerBorderPaint);

    // 십자 가이드 선
    final guidePaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(baseCenter.dx - outerRadius + 10, baseCenter.dy),
      Offset(baseCenter.dx + outerRadius - 10, baseCenter.dy),
      guidePaint,
    );
    canvas.drawLine(
      Offset(baseCenter.dx, baseCenter.dy - outerRadius + 10),
      Offset(baseCenter.dx, baseCenter.dy + outerRadius - 10),
      guidePaint,
    );

    // 노브 (반투명 흰색)
    final knobFillPaint = Paint()..color = const Color(0xAAFFFFFF);
    canvas.drawCircle(baseCenter, knobRadius, knobFillPaint);

    // 노브 테두리
    final knobBorderPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(baseCenter, knobRadius, knobBorderPaint);

    // 노브 중앙 점
    final knobDotPaint = Paint()..color = const Color(0x88333333);
    canvas.drawCircle(baseCenter, 5.0, knobDotPaint);
  }

  // ============================================================
  // D-1-4: 스킬 버튼 UI (화면 우측 하단, 원형 게이지)
  // ============================================================
  void _renderSkillButton(Canvas canvas) {
    const double btnRadius = 38.0;
    const double gaugeStroke = 6.0;
    const double marginRight = 55.0;
    const double marginBottom = 90.0;
    final Offset center = Offset(size.x - marginRight, size.y - marginBottom);

    // 버튼 배경 (반투명 검정)
    final bgPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawCircle(center, btnRadius, bgPaint);

    // 게이지 트랙 (어두운 회색)
    final trackPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = gaugeStroke;
    canvas.drawCircle(center, btnRadius - gaugeStroke / 2, trackPaint);

    // 원형 게이지 (skillGauge 0~100 → 호 각도)
    if (skillGauge > 0) {
      final gaugeColor = skillReady
          ? const Color(0xFFFF6E40) // 준비 완료: 주황-빨강
          : const Color(0xFF2196F3); // 충전 중: 파랑
      final gaugePaint = Paint()
        ..color = gaugeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = gaugeStroke
        ..strokeCap = StrokeCap.round;
      const double startAngle = -3.14159265 / 2; // 12시 방향
      final double sweepAngle = 2 * 3.14159265 * (skillGauge / 100.0);
      canvas.drawArc(
        Rect.fromCircle(
            center: center, radius: btnRadius - gaugeStroke / 2),
        startAngle,
        sweepAngle,
        false,
        gaugePaint,
      );
    }

    // 스킬 아이콘 이모지 (준비 완료 시 밝게)
    final iconColor = skillReady
        ? const Color(0xFFFFFFFF)
        : const Color(0xAAFFFFFF);
    _drawCenteredText(
      canvas,
      skillReady ? '💥' : '⚡',
      Offset(center.dx, center.dy - 6),
      fontSize: 20,
      color: iconColor,
    );

    // 게이지 퍼센트 텍스트
    _drawCenteredText(
      canvas,
      skillReady ? 'READY' : '${skillGauge.toInt()}%',
      Offset(center.dx, center.dy + 14),
      fontSize: 9,
      color: skillReady ? const Color(0xFFFF6E40) : const Color(0xAAFFFFFF),
    );

    // 준비 완료 시 외곽 발광 링
    if (skillReady) {
      final glowPaint = Paint()
        ..color = const Color(0x44FF6E40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawCircle(center, btnRadius + 6, glowPaint);
    }
  }

  // ============================================================
  // D-1-5: 골드 표시 UI (화면 우측 하단, 스킬 버튼 왼쪽)
  // ============================================================
  void _renderGoldDisplay(Canvas canvas) {
    const double marginRight = 110.0;
    const double marginBottom = 78.0;
    const double bgW = 72.0;
    const double bgH = 28.0;
    final double x = size.x - marginRight - bgW / 2;
    final double y = size.y - marginBottom;

    // 반투명 배경 박스
    final bgPaint = Paint()..color = const Color(0x80000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: bgW, height: bgH),
        const Radius.circular(14),
      ),
      bgPaint,
    );

    // 테두리
    final borderPaint = Paint()
      ..color = const Color(0x88FFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: bgW, height: bgH),
        const Radius.circular(14),
      ),
      borderPaint,
    );

    // 코인 이모지 + 골드 수치
    _drawCenteredText(
      canvas,
      '🪙${playerGold}G',
      Offset(x, y),
      fontSize: 13,
      color: const Color(0xFFFFD700),
    );
  }

  // ============================================================
  // D-4-2: 타워 슬롯 프레임 (성 중심 ±70px 대각선 4곳)
  // ============================================================
  void _renderTowerSlots(Canvas canvas) {
    const double slotSize = 40.0;
    final double cx = size.x / 2;
    final double cy = size.y / 2;
    const double towerOffset = 70.0;

    // T1~T4 슬롯 중심 좌표
    final List<Offset> slotCenters = [
      Offset(cx - towerOffset, cy - towerOffset), // T1: 좌상
      Offset(cx + towerOffset, cy - towerOffset), // T2: 우상
      Offset(cx - towerOffset, cy + towerOffset), // T3: 좌하
      Offset(cx + towerOffset, cy + towerOffset), // T4: 우하
    ];

    for (int i = 0; i < slotCenters.length; i++) {
      final center = slotCenters[i];
      final Rect slotRect =
          Rect.fromCenter(center: center, width: slotSize, height: slotSize);

      // partySlots 인덱스: 0=메인, 1~4=타워
      final int towerSlotIndex = i + 1;
      final bool hasTower = towerSlotIndex < partySlots.length &&
          partySlots[towerSlotIndex] != null;

      if (hasTower) {
        // 배치된 타워: 랭크 색상 배경 + 역할 이모지
        final instanceId = partySlots[towerSlotIndex]!;
        final character = ownedCharacters.firstWhere(
          (c) => c.instanceId == instanceId,
          orElse: () => ownedCharacters.isNotEmpty
              ? ownedCharacters.first
              : OwnedCharacter(instanceId: '', characterId: ''),
        );

        if (character.characterId.isNotEmpty) {
          final definition = CharacterDefinitions.byId(character.characterId);

          // 랭크 색상 반투명 배경
          final bgPaint = Paint()
            ..color = Color(definition.rank.color).withValues(alpha: 0.35);
          canvas.drawRRect(
            RRect.fromRectAndRadius(slotRect, const Radius.circular(6)),
            bgPaint,
          );

          // 스킬 준비 여부에 따른 테두리 색상
          final bool skillReady = towerSlotIndex < characterSlots.length &&
              characterSlots[towerSlotIndex].skillReady;
          final borderPaint = Paint()
            ..color = skillReady
                ? const Color(0xFF00E676)
                : Color(definition.rank.color)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(slotRect, const Radius.circular(6)),
            borderPaint,
          );

          // 역할 이모지
          _drawCenteredText(canvas, definition.role.emoji, center, fontSize: 22);

          // 스킬 준비 표시
          if (skillReady) {
            _drawCenteredText(
              canvas,
              '✨',
              Offset(slotRect.right - 8, slotRect.top + 8),
              fontSize: 10,
            );
          }
        }
      } else {
        // 빈 슬롯: 반투명 배경 + 점선 프레임 + 슬롯 번호
        final emptyBgPaint = Paint()..color = const Color(0x22FFFFFF);
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(6)),
          emptyBgPaint,
        );

        final dashBorderPaint = Paint()
          ..color = const Color(0x66FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(slotRect, const Radius.circular(6)),
          dashBorderPaint,
        );

        // 슬롯 번호
        _drawCenteredText(
          canvas,
          'T${i + 1}',
          center,
          fontSize: 13,
          color: const Color(0x99FFFFFF),
        );
      }
    }
  }

  // ============================================================
  // D-1-2: 성 HP 바 (성 스프라이트 바로 위, 80×6px, 녹→황→적)
  // ============================================================
  void _renderCastleHP(Canvas canvas) {
    const double barWidth = 80.0;
    const double barHeight = 6.0;
    const double barMargin = 6.0;
    final double cx = size.x / 2;
    final double castleTop = size.y / 2 - 40.0; // 80px 높이의 절반
    final double hpRatio =
        castleMaxHp == 0 ? 0 : (castleHp / castleMaxHp).clamp(0.0, 1.0);
    final double barX = cx - barWidth / 2;
    final double barY = castleTop - barHeight - barMargin;

    // 배경 바
    final bgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(3),
      ),
      bgPaint,
    );

    // HP 색상: hpGreen → hpYellow → hpRed
    final Color barColor;
    if (hpRatio > 0.66) {
      barColor = const Color(0xFF4CAF50);
    } else if (hpRatio > 0.33) {
      barColor = const Color(0xFFFFEB3B);
    } else {
      barColor = const Color(0xFFF44336);
    }

    final fgPaint = Paint()..color = barColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth * hpRatio, barHeight),
        const Radius.circular(3),
      ),
      fgPaint,
    );

    // HP 수치 텍스트
    _drawCenteredText(
      canvas,
      '🏰 $castleHp / $castleMaxHp',
      Offset(cx, barY - 10),
      fontSize: 11,
      color: const Color(0xFFFFFFFF),
    );
  }

  // ============================================================
  // D-1-1: 게임 화면 HUD (상단 UI)
  // 레이아웃:
  //   [1행] 캐릭터 아이콘 + HP바  |  Lv.X  |  XP바 (플레이스홀더)
  //   [2행] 👾몬스터수  |  ⏱타이머  |  Stage X-Y
  // ============================================================
  void _renderHUD(Canvas canvas) {
    const double topPad = 8.0;
    const double leftPad = 12.0;
    const double barHeight = 7.0;

    // ── 반투명 HUD 배경 ──
    final bgPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 60), bgPaint);

    // ── 1행: HP바 ──
    final _CharacterUnit? mainUnit = () {
      final filtered = characterUnits.where((u) => !u.isTower).toList();
      return filtered.isEmpty ? null : filtered.first;
    }();

    const double hpBarW = 100.0;
    const double row1Y = topPad + 6;

    // 캐릭터 아이콘 (메인 유닛 역할 이모지)
    if (mainUnit != null) {
      _drawCenteredText(
        canvas,
        mainUnit.definition.role.emoji,
        Offset(leftPad + 10, row1Y + 4),
        fontSize: 16,
      );
    } else {
      _drawCenteredText(
        canvas,
        '🏃',
        Offset(leftPad + 10, row1Y + 4),
        fontSize: 16,
      );
    }

    // HP 바 (_mainCharHp/_mainCharMaxHp 사용 - B-2-6 실제 HP 상태 반영)
    final double hpRatio =
        (_mainCharHp / _mainCharMaxHp).clamp(0.0, 1.0);
    final double hpBarX = leftPad + 24;

    final hpBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hpBarX, row1Y, hpBarW, barHeight),
        const Radius.circular(3),
      ),
      hpBgPaint,
    );

    final Color hpColor;
    if (hpRatio > 0.66) {
      hpColor = const Color(0xFF4CAF50);
    } else if (hpRatio > 0.33) {
      hpColor = const Color(0xFFFFEB3B);
    } else {
      hpColor = const Color(0xFFF44336);
    }

    final hpFgPaint = Paint()..color = hpColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hpBarX, row1Y, hpBarW * hpRatio, barHeight),
        const Radius.circular(3),
      ),
      hpFgPaint,
    );

    // HP 수치 (_mainCharHp 실제 값 사용)
    final String hpText = '$_mainCharHp/$_mainCharMaxHp';
    _drawText(
      canvas,
      hpText,
      Offset(hpBarX + 2, row1Y + 9),
      fontSize: 8,
      color: const Color(0xFFFFFFFF),
    );

    // 속성 아이콘 (HP 바 오른쪽)
    if (_mainCharElement != ElementType.none) {
      _drawCenteredText(
        canvas,
        _mainCharElement.emoji,
        Offset(hpBarX + hpBarW + 12, row1Y + 4),
        fontSize: 14,
      );
    }

    // Lv 표시 (중앙 상단)
    _drawCenteredText(
      canvas,
      'Lv.$playerLevel',
      Offset(size.x / 2, row1Y + 4),
      fontSize: 13,
      color: const Color(0xFFFFD700),
    );

    // XP 바 (우측, 플레이스홀더)
    const double xpBarW = 90.0;
    final double xpBarX = size.x - leftPad - xpBarW;
    final xpBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(xpBarX, row1Y, xpBarW, barHeight),
        const Radius.circular(3),
      ),
      xpBgPaint,
    );
    // 리디자인 B-2-10: XP 바 (실제 playerXp/playerCharLevel 연결)
    final double xpRatio = _xpToNextLevel() > 0
        ? (playerXp / _xpToNextLevel()).clamp(0.0, 1.0)
        : 0.0;
    final xpFgPaint = Paint()..color = const Color(0xFF2196F3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(xpBarX, row1Y, xpBarW * xpRatio, barHeight),
        const Radius.circular(3),
      ),
      xpFgPaint,
    );
    _drawText(
      canvas,
      'Lv.$playerCharLevel XP',
      Offset(xpBarX + 2, row1Y + 9),
      fontSize: 8,
      color: const Color(0xAAFFFFFF),
    );

    // ── 2행: 몬스터수 | 타이머 | 스테이지 ──
    const double row2Y = topPad + 24;

    // 좌측: 몬스터 수 (처치/총수)
    final int remaining = totalMonstersInRound - defeatedMonsters;
    _drawText(
      canvas,
      '👾 $remaining',
      Offset(leftPad, row2Y + 4),
      fontSize: 12,
      color: const Color(0xFFFFFFFF),
    );

    // 중앙: 경과 타이머 (M:SS)
    final int totalSec = roundTimer.toInt();
    final int minutes = totalSec ~/ 60;
    final int seconds = totalSec % 60;
    final String timerText = '⏱ $minutes:${seconds.toString().padLeft(2, '0')}';
    _drawCenteredText(
      canvas,
      timerText,
      Offset(size.x / 2, row2Y + 4),
      fontSize: 12,
      color: const Color(0xFFFFFFFF),
    );

    // 우측: 스테이지 표시
    _drawText(
      canvas,
      'Stage $stageLevel-$currentRound',
      Offset(size.x - leftPad - 80, row2Y + 4),
      fontSize: 12,
      color: const Color(0xFFAAAAAA),
    );

    // ── D-1-5: 골드 표시 (HUD 하단, 좌측) ──
    const double row3Y = topPad + 42;
    final bgPaint2 = Paint()..color = const Color(0xCC000000);
    canvas.drawRect(Rect.fromLTWH(0, 57, size.x, 18), bgPaint2);
    _drawText(
      canvas,
      '🪙 ${_formatNumber(playerGold)}G',
      Offset(leftPad, row3Y + 2),
      fontSize: 11,
      color: const Color(0xFFFFD700),
    );

    // D-1-5: 속성 아이콘 표시 (메인 캐릭터 속성, HUD row3 우측)
    final String elemIcon = _elementIcon(_mainCharElement);
    if (elemIcon.isNotEmpty) {
      _drawText(
        canvas,
        elemIcon,
        Offset(size.x - leftPad - 20, row3Y + 2),
        fontSize: 12,
      );
    }
  }

  // D-1-5: 속성 이모지 헬퍼
  String _elementIcon(ElementType e) {
    switch (e) {
      case ElementType.fire:     return '🔥';
      case ElementType.water:    return '💧';
      case ElementType.earth:    return '🌿';
      case ElementType.electric: return '⚡';
      case ElementType.dark:     return '🌑';
      case ElementType.none:     return '';
    }
  }

  // D-1-5: 속성 색상 헬퍼
  Color _elementColor(ElementType e) {
    switch (e) {
      case ElementType.fire:     return const Color(0xFFF44336);
      case ElementType.water:    return const Color(0xFF2196F3);
      case ElementType.earth:    return const Color(0xFF8BC34A);
      case ElementType.electric: return const Color(0xFFFFD700);
      case ElementType.dark:     return const Color(0xFF9C27B0);
      case ElementType.none:     return const Color(0xFFFFFFFF);
    }
  }

  // ============================================================
  // D-2-4: 메인 캐릭터 사망 카운트다운 UI
  // - 화면 중앙에 큰 숫자 표시 (5→4→3→2→1)
  // - 사용법: Engineer가 mainCharReviveCountdown 변수 추가 후 아래 메서드를 render()에서 호출
  //   if (mainCharReviveCountdown > 0) _renderReviveCountdown(canvas, mainCharReviveCountdown);
  // ============================================================
  void _renderReviveCountdown(Canvas canvas, double countdown) {
    // 반투명 오버레이
    final overlayPaint = Paint()..color = const Color(0x80000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlayPaint);

    // 카운트다운 숫자 (올림 처리: 0.1초 남아도 "1"로 표시)
    final int countInt = countdown.ceil().clamp(1, 5);

    // 숫자 색상: 빨간→주황→노랑 (시간이 줄수록 다급해지는 느낌)
    final Color countColor;
    if (countInt >= 4) {
      countColor = const Color(0xFFFF5252); // 빨강
    } else if (countInt >= 2) {
      countColor = const Color(0xFFFF6E40); // 주황
    } else {
      countColor = const Color(0xFFFFEB3B); // 노랑
    }

    // 큰 숫자
    _drawCenteredText(
      canvas,
      '$countInt',
      Offset(size.x / 2, size.y / 2 - 20),
      fontSize: 80,
      color: countColor,
    );

    // "REVIVING..." 서브텍스트 (점멸: sin 파형으로 알파 제어)
    final double alpha = (0.5 + 0.5 * sin(gameTime * 6)).clamp(0.3, 1.0);
    _drawCenteredText(
      canvas,
      'REVIVING...',
      Offset(size.x / 2, size.y / 2 + 50),
      fontSize: 16,
      color: Color.fromRGBO(255, 255, 255, alpha),
    );
  }

  // ============================================================
  // D-3-2: XP 젬 묘사 (파란 마름모, 소멸 전 점멸)
  // ============================================================
  void _renderXpGems(Canvas canvas) {
    const double gemSize = 7.0;

    for (final gem in xpGems) {
      final cx = gem.pos.x;
      final cy = gem.pos.y;

      // 소멸 전 5초 이하: sin 파형 점멸
      final double gemAlpha =
          gem.isBlinking ? (0.4 + 0.6 * sin(gameTime * 8)).clamp(0.1, 1.0) : 1.0;

      if (xpGemImageLoaded && xpGemImage != null) {
        // D-3-2: 참조 에셋 스프라이트로 XP 젬 렌더링
        final srcRect = Rect.fromLTWH(
          0, 0,
          xpGemImage!.width.toDouble(),
          xpGemImage!.height.toDouble(),
        );
        final dstRect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: gemSize * 2.0,
          height: gemSize * 2.0,
        );
        final spritePaint = Paint()
          ..color = Color.fromRGBO(255, 255, 255, gemAlpha);
        canvas.drawImageRect(xpGemImage!, srcRect, dstRect, spritePaint);
      } else {
        // 폴백: Canvas 절차적 드로잉
        final path = Path()
          ..moveTo(cx, cy - gemSize)
          ..lineTo(cx + gemSize * 0.6, cy)
          ..lineTo(cx, cy + gemSize)
          ..lineTo(cx - gemSize * 0.6, cy)
          ..close();
        final fillPaint = Paint()
          ..color = Color.fromRGBO(21, 101, 192, gemAlpha);
        canvas.drawPath(path, fillPaint);
        final hlPath = Path()
          ..moveTo(cx, cy - gemSize)
          ..lineTo(cx + gemSize * 0.6, cy)
          ..lineTo(cx, cy)
          ..close();
        final hlPaint = Paint()
          ..color = Color.fromRGBO(100, 181, 246, gemAlpha * 0.7);
        canvas.drawPath(hlPath, hlPaint);
        final borderPaint = Paint()
          ..color = Color.fromRGBO(33, 150, 243, gemAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawPath(path, borderPaint);
      }

      // 고가치 젬 (10XP 이상) 수치 표시
      if (gem.xpValue >= 10) {
        _drawCenteredText(
          canvas,
          '${gem.xpValue}',
          Offset(cx, cy + gemSize + 8),
          fontSize: 8,
          color: Color.fromRGBO(144, 202, 249, gemAlpha),
        );
      }
    }
  }

  // ============================================================
  // D-3-4: XP 마그넷 연출 (레벨업 직후 1초간 메인 캐릭터 주위 파란 링 펄스)
  // ============================================================
  void _renderXpMagnetEffect(Canvas canvas) {
    if (_xpMagnetTimer <= 0) return;
    // 메인 캐릭터 위치 취득
    final mainUnit = _mainCharAlive
        ? characterUnits.where((u) => !u.isTower).firstOrNull
        : null;
    if (mainUnit == null) return;

    final cx = mainUnit.pos.x;
    final cy = mainUnit.pos.y;
    // 진행률 (0.0=시작, 1.0=종료)
    final progress = 1.0 - (_xpMagnetTimer / _xpMagnetDuration);

    // 외부 링: 확대되며 사라짐
    final outerRadius = 20.0 + progress * 60.0;
    final outerAlpha = (1.0 - progress).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(cx, cy),
      outerRadius,
      Paint()
        ..color = const Color(0xFF1565C0).withValues(alpha: outerAlpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // 내부 펄스 링: sin 파형으로 깜빡임
    final innerPulse = (sin(gameTime * 15) * 0.3 + 0.7).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(cx, cy),
      _xpCollectRadius,
      Paint()
        ..color = const Color(0xFF1565C0).withValues(alpha: innerPulse * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ============================================================
  // D-3-3: 골드 코인 묘사 (금색 원형, goldYellow #FFD700)
  // ============================================================
  void _renderGoldDrops(Canvas canvas) {
    const double coinRadius = 6.0;

    for (final gold in goldDrops) {
      final cx = gold.pos.x;
      final cy = gold.pos.y;

      if (goldCoinImageLoaded && goldCoinImage != null) {
        // D-3-3: 참조 에셋 스프라이트로 코인 렌더링
        final srcRect = Rect.fromLTWH(
          0, 0,
          goldCoinImage!.width.toDouble(),
          goldCoinImage!.height.toDouble(),
        );
        final dstRect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: coinRadius * 2.5,
          height: coinRadius * 2.5,
        );
        canvas.drawImageRect(goldCoinImage!, srcRect, dstRect, Paint());
      } else {
        // 폴백: Canvas 절차적 드로잉
        final coinPaint = Paint()..color = const Color(0xFFFFD700);
        canvas.drawCircle(Offset(cx, cy), coinRadius, coinPaint);
        final hlPaint = Paint()..color = const Color(0xFFFFF9C4);
        canvas.drawCircle(Offset(cx - 1.5, cy - 1.5), coinRadius * 0.4, hlPaint);
        final borderPaint = Paint()
          ..color = const Color(0xFFFF8F00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(Offset(cx, cy), coinRadius, borderPaint);
      }

      // 고액 골드 수치 표시
      if (gold.goldValue >= 5) {
        _drawCenteredText(
          canvas,
          '${gold.goldValue}',
          Offset(cx, cy + coinRadius + 8),
          fontSize: 8,
          color: const Color(0xFFFFD700),
        );
      }
    }
  }
}
