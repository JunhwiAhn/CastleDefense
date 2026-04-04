// gacha_system.dart — 가챠 시스템 (추후 재구현 예정, 현재 스텁)

import '../models/character_model.dart';
import '../data/character_definitions.dart';

class GachaSystem {
  // 추후 가챠 재구현 시 사용
  // 현재는 모든 캐릭터가 기본 해금 상태
  List<CharacterDefinition> get allUnlocked => CharacterDefinitions.all;
}
