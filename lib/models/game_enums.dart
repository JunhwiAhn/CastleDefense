// 게임 상태 및 타입 enum 모음
part of '../castle_defense_game.dart';

// 게임 전체 상태 머신
enum GameState {
  loading,      // 초기 로딩
  raceSelect,   // 최초 1회: 종족 선택
  home,         // 홈화면 (가챠·컬렉션·설정)
  prep,         // 웨이브 전 타워 배치 단계
  waving,       // 웨이브 진행 중
  waveCleared,  // 웨이브 클리어 인터벌 (2초)
  stageClear,   // 스테이지 전 라운드 클리어
  gameOver,     // 성 HP = 0
}

// 종족 (최초 1회 선택, 이후 고정)
enum RaceType {
  human,   // 인간족: 골드 수입+15%, 타워 비용-5%
  orc,     // 오크족: 타워 공격력+20%, 사거리-10%, 대포/근접 업그레이드-20%
  elf,     // 엘프족: 타워 사거리+20%, 공격속도+10%, 저격/궁수 업그레이드-20%
  machina, // 기계족: 업그레이드 비용-25%, Lv3 타워 소형 AOE 추가
  demon,   // 악마족: 처치시 5% 확률 성HP+1, 디버프 지속+30%, 마법 타워 추가 골드
}

// 타워 타입 4종
enum TowerType {
  archer,  // 궁수: 단일·빠른 연사
  cannon,  // 대포: 범위 데미지
  mage,    // 마법사: 명중 시 슬로우
  sniper,  // 저격: 단일·고데미지·긴 사거리
}

// 적 타입
enum EnemyType {
  normal,   // 기본
  fast,     // 빠름 (R3~)
  tank,     // 느리고 단단 (R4~)
  miniBoss, // 미니보스
  boss,     // 보스
}

// 타워 타겟 우선순위
enum TargetPriority {
  first,     // 경로 진행도 높은 순 (기본)
  strongest, // 현재 HP 높은 순
  weakest,   // 현재 HP 낮은 순
  closest,   // 타워 거리 가까운 순
}

// 카드 등급 (가챠 결과)
enum CardGrade { c, b, a, s }

// 홈화면 하단 메뉴
enum BottomMenu {
  home,       // 홈 (스테이지 선택)
  collection, // 컬렉션 (카드 업그레이드)
  gacha,      // 뽑기
  settings,   // 설정
}

// VFX 이펙트 종류 (일부 유지)
enum VfxType { hit, death, shockwave }
