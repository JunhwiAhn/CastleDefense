// 캐릭터 모델 테스트 (TD 리디자인 후 업데이트)

import 'package:flutter_test/flutter_test.dart';
import 'package:castle_defense_proto/models/character_model.dart';
import 'package:castle_defense_proto/data/character_definitions.dart';

void main() {
  test('모든 캐릭터에 towerType이 할당되어야 한다', () {
    for (final def in CharacterDefinitions.all) {
      expect(TowerTypeMapping.values.contains(def.towerType), isTrue,
          reason: '${def.id}에 towerType이 없음');
    }
  });

  test('모든 캐릭터에 spriteSheet 경로가 있어야 한다', () {
    for (final def in CharacterDefinitions.all) {
      expect(def.spriteSheet.isNotEmpty, isTrue,
          reason: '${def.id}에 spriteSheet가 없음');
    }
  });

  test('각 타워 타입별로 최소 2명 이상의 캐릭터가 있어야 한다', () {
    for (final type in TowerTypeMapping.values) {
      final chars = CharacterDefinitions.byTowerType(type);
      expect(chars.length, greaterThanOrEqualTo(2),
          reason: '$type에 캐릭터가 2명 미만');
    }
  });
}
