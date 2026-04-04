// 진행 시스템: 스테이지 보상, 캐릭터 조회 (가챠/카드강화 제거)
part of '../castle_defense_game.dart';

extension ProgressionSystem on CastleDefenseGame {

  // ─── 스테이지 완료 보상 표시용 ────────────────
  String getStageRewardSummary() {
    final cfg = kStageConfigs[stageLevel];
    if (cfg == null) return '';
    final buf = StringBuffer();
    buf.write('⭐ +${cfg.starShardOnStageClear}');
    buf.write('  💎 +${cfg.gemOnStageClear}');
    if (_perfectClearSoFar) buf.write('  (무피해 +⭐5 +💎3)');
    if (!_clearedStages.contains(stageLevel)) buf.write('  (첫 클리어 보너스!)');
    return buf.toString();
  }

  // ─── 배치 가능한 캐릭터 목록 (타워 타입 무관, 전체) ──
  List<CharacterDefinition> getCharactersForTowerType(TowerType type) {
    return CharacterDefinitions.all;
  }
}
