// 게임 오브젝트 클래스 (몬스터, 투사물, 캐릭터 유닛 등)
part of '../castle_defense_game.dart';

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
  double attackCooldown = 0.0; // 공격 쿨타임
  _Monster? targetMonster; // 현재 타겟 몬스터
  bool movingTowardsTarget = false; // 타겟을 향해 이동 중인지
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
  double skillCooldownRemaining = 0.0; // 스킬 쿨다운 남은 시간 (초)

  _CharacterSlot({
    required this.slotIndex,
    this.hasCharacter = false,
    this.characterName = '',
    this.skillReady = false,
  });
}
