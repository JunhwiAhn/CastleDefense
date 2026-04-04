// character_model.dart — 캐릭터 정의 (애셋 기반, 가챠/등급 시스템 제거)

// 타워 타입 매핑용 (game_enums.dart의 TowerType과 1:1 대응)
enum TowerTypeMapping { archer, cannon, mage, sniper }

class CharacterDefinition {
  final String id;            // 고유 ID (= 파일명)
  final String name;          // 표시 이름
  final TowerTypeMapping towerType; // 배치 가능한 타워 타입
  final String spriteSheet;   // 스프라이트 시트 경로 (assets/images/ 기준)
  final int frameColumns;     // 시트 열 수
  final int frameRows;        // 시트 행 수
  final int totalFrames;      // 총 프레임 수

  const CharacterDefinition({
    required this.id,
    required this.name,
    required this.towerType,
    required this.spriteSheet,
    this.frameColumns = 5,
    this.frameRows = 3,
    this.totalFrames = 15,
  });
}
