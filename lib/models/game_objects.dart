// 게임 오브젝트 클래스 (타워, 슬롯, 몬스터, 투사물, VFX)
part of '../castle_defense_game.dart';

// ─────────────────────────────────────────
// 경로 웨이포인트 상수 (S자 경로, 390×844)
// ─────────────────────────────────────────
// index 0 = 스폰 (화면 밖), index 마지막 = 성 위치
const List<(double, double)> kPathWaypointDefs = [
  (195,   0),   // 0: 스폰 포인트 (화면 위 바깥)
  (195, 170),   // 1: 직진
  ( 65, 170),   // 2: 좌회전
  ( 65, 340),   // 3: 직진
  (325, 340),   // 4: 우회전
  (325, 510),   // 5: 직진
  ( 65, 510),   // 6: 좌회전
  ( 65, 680),   // 7: 직진
  (325, 680),   // 8: 우회전
  (325, 790),   // 9: 직진
  (195, 790),   // 10: 성 도착
];

// ─────────────────────────────────────────
// 타워 슬롯 정의 (22개, 경로 비점유 위치)
// ─────────────────────────────────────────
const List<(int, double, double)> kTowerSlotDefs = [
  ( 1, 290,  80), ( 2, 290, 130),
  ( 3, 155,  80), ( 4, 155, 130),
  ( 5, 175, 240), ( 6, 175, 290),
  ( 7, 215, 240), ( 8, 215, 290),
  ( 9, 160, 420), (10, 240, 420),
  (11, 160, 460), (12, 240, 460),
  (13, 175, 595), (14, 215, 595),
  (15, 175, 640), (16, 215, 640),
  (17, 155, 730), (18, 155, 770),
  (19, 290, 730), (20, 290, 770),
  (21,  40, 100), (22,  40, 200),
];

// ─────────────────────────────────────────
// 타워 기본 스탯 테이블
// ─────────────────────────────────────────
class _TowerStats {
  final double damage;
  final double attackSpeed; // 초당 공격 횟수
  final double range;       // 사거리 px
  final double splash;      // 범위 데미지 반경 (0=단일)
  final int cost;           // 구매 비용(골드)
  const _TowerStats({
    required this.damage,
    required this.attackSpeed,
    required this.range,
    required this.splash,
    required this.cost,
  });
}

// 레벨별 스탯 배율 (Lv1=1.0, Lv2=1.6, Lv3=2.3)
const List<double> kTowerLevelMult = [0.0, 1.0, 1.6, 2.3];

// 업그레이드 비용 배율 (Lv1→2: ×1.5, Lv2→3: ×2.5)
const List<double> kTowerUpgradeCostMult = [0.0, 0.0, 1.5, 2.5];

const Map<TowerType, _TowerStats> kTowerBaseStat = {
  TowerType.archer: _TowerStats(damage: 8,  attackSpeed: 1.5, range: 110, splash:  0, cost:  50),
  TowerType.cannon: _TowerStats(damage: 40, attackSpeed: 0.6, range:  90, splash: 45, cost: 120),
  TowerType.mage:   _TowerStats(damage: 18, attackSpeed: 0.9, range: 130, splash:  0, cost:  90),
  TowerType.sniper: _TowerStats(damage: 80, attackSpeed: 0.3, range: 220, splash:  0, cost: 150),
};

// ─────────────────────────────────────────
// Tower 클래스
// ─────────────────────────────────────────
class _Tower {
  final TowerType type;
  final int slotId;
  Vector2 pos;
  int level;                  // 인게임 업그레이드 레벨 (1~3)
  String? characterId;        // 배치된 캐릭터 카드 ID (null = 기본)
  double cardGradeBonus;      // 카드 등급+레벨 보정 (0.0 ~ 0.35)
  double attackTimer;         // 공격 쿨다운 누적
  TargetPriority targetPriority;
  bool showRange;             // 사거리 원 표시 여부

  _Tower({
    required this.type,
    required this.slotId,
    required this.pos,
    this.level = 1,
    this.characterId,
    this.cardGradeBonus = 0.0,
    this.attackTimer = 0.0,
    this.targetPriority = TargetPriority.first,
    this.showRange = false,
  });

  _TowerStats get _base => kTowerBaseStat[type]!;
  double get levelMult => kTowerLevelMult[level];

  // 실제 스탯 (레벨 × 카드 보정 × 종족 패시브는 외부에서 곱함)
  double get damage      => _base.damage * levelMult * (1 + cardGradeBonus);
  double get attackSpeed => _base.attackSpeed * levelMult;
  double get range       => _base.range;
  double get splash      => _base.splash;

  // 업그레이드 비용
  int get upgradeCost {
    if (level >= 3) return 0;
    return (_base.cost * kTowerUpgradeCostMult[level + 1]).round();
  }

  // 철거 환급 (구매가의 50%)
  int get sellValue => (_base.cost * 0.5).round();

  // 공격 간격(초)
  double get attackInterval => 1.0 / attackSpeed;

  // 타워 표시 이름
  String get displayName {
    final typeName = switch (type) {
      TowerType.archer => '궁수',
      TowerType.cannon => '대포',
      TowerType.mage   => '마법사',
      TowerType.sniper => '저격',
    };
    return characterId != null ? '$typeName의 진지' : '$typeName 타워';
  }
}

// ─────────────────────────────────────────
// TowerSlot 클래스
// ─────────────────────────────────────────
class _TowerSlot {
  final int id;
  final Vector2 pos;
  _Tower? tower;

  _TowerSlot({required this.id, required this.pos, this.tower});

  bool get isEmpty => tower == null;
}

// ─────────────────────────────────────────
// Monster 클래스 (웨이포인트 이동)
// ─────────────────────────────────────────
class _Monster {
  Vector2 pos;
  int hp;
  int maxHp;
  EnemyType enemyType;
  double speed;         // 현재 이동 속도 (슬로우 적용 전 기준)
  int waypointIndex;    // 현재 목표 웨이포인트 인덱스 (0→1→…)
  double pathProgress;  // 경로 진행도 (First 우선순위용, 높을수록 앞)
  int castleDamage;     // 성 도착 시 성 HP 감소량
  int goldReward;       // 처치 시 골드

  // 슬로우 (마법사 타워)
  double slowTimer;     // 슬로우 남은 시간
  double slowFactor;    // 슬로우 배율 (0.35 = 35% 속도 감소)

  // 렌더링
  double damageFlashTimer;
  double animTimer;
  int animFrame;
  bool isAlive;

  _Monster({
    required this.pos,
    required this.hp,
    required this.maxHp,
    required this.enemyType,
    required this.speed,
    required this.castleDamage,
    required this.goldReward,
    this.waypointIndex = 0,
    this.pathProgress = 0.0,
    this.slowTimer = 0.0,
    this.slowFactor = 0.0,
    this.damageFlashTimer = 0.0,
    this.animTimer = 0.0,
    this.animFrame = 0,
    this.isAlive = true,
  });

  // 실제 이동 속도 (슬로우 적용)
  double get effectiveSpeed =>
      slowTimer > 0 ? speed * (1.0 - slowFactor) : speed;
}

// ─────────────────────────────────────────
// 투사물
// ─────────────────────────────────────────
class _Projectile {
  Vector2 pos;
  Vector2 velocity;
  double damage;
  TowerType sourceTower;
  _Monster? targetMonster; // 유도형
  double splashRadius;
  bool isSlow;             // 마법사 타워: 슬로우 부여
  List<Vector2> trail;

  _Projectile({
    required this.pos,
    required this.velocity,
    required this.damage,
    required this.sourceTower,
    this.targetMonster,
    this.splashRadius = 0.0,
    this.isSlow = false,
  }) : trail = [];
}

// ─────────────────────────────────────────
// VFX 이펙트
// ─────────────────────────────────────────
class _VfxEffect {
  Vector2 pos;
  double timer;
  double duration;
  VfxType type;
  double maxRadius;
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

// ─────────────────────────────────────────
// 부유 데미지 숫자
// ─────────────────────────────────────────
class _DamageNumber {
  Vector2 pos;
  double timer;
  final int amount;
  final bool isCrit;

  _DamageNumber({
    required this.pos,
    required this.amount,
    this.isCrit = false,
  }) : timer = 0.0;

  static const double duration = 1.0;
  bool get isExpired => timer >= duration;
}

