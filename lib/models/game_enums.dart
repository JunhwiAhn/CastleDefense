// 게임 상태 및 타입 enum 모음
part of '../castle_defense_game.dart';

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

// VFX 이펙트 종류
enum VfxType { hit, death, shockwave, barrier }
