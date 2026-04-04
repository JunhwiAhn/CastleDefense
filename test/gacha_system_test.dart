// 가챠 시스템 유닛 테스트 (가챠 시스템 재구현 시 업데이트 필요)

import 'package:flutter_test/flutter_test.dart';
import 'package:castle_defense_proto/systems/gacha_system.dart';
import 'package:castle_defense_proto/data/character_definitions.dart';

void main() {
  late GachaSystem gacha;

  setUp(() {
    gacha = GachaSystem();
  });

  test('모든 캐릭터가 해금 상태여야 한다', () {
    final unlocked = gacha.allUnlocked;
    expect(unlocked.length, CharacterDefinitions.all.length);
  });

  test('캐릭터 정의에 10개 캐릭터가 있어야 한다', () {
    expect(CharacterDefinitions.all.length, 10);
  });

  test('byId로 캐릭터를 찾을 수 있어야 한다', () {
    final archer = CharacterDefinitions.byId('archer');
    expect(archer.name, '엘프 궁수');
  });

  test('tryById로 존재하지 않는 캐릭터는 null을 반환해야 한다', () {
    final notFound = CharacterDefinitions.tryById('nonexistent');
    expect(notFound, isNull);
  });
}
