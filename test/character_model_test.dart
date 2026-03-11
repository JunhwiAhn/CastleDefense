// 캐릭터 모델 및 속성 매핑 유닛 테스트

import 'package:flutter_test/flutter_test.dart';
import 'package:castle_defense_proto/models/character_enums.dart';
import 'package:castle_defense_proto/models/character_model.dart';
import 'package:castle_defense_proto/data/character_definitions.dart';

void main() {
  group('ClassType.defaultElement 매핑', () {
    // 속성 보유 클래스 (element-system.md 기준)
    test('pyromancer → fire', () {
      expect(ClassType.pyromancer.defaultElement, ElementType.fire);
    });

    test('cryomancer → water', () {
      expect(ClassType.cryomancer.defaultElement, ElementType.water);
    });

    test('druid → earth', () {
      expect(ClassType.druid.defaultElement, ElementType.earth);
    });

    test('alchemist → earth', () {
      expect(ClassType.alchemist.defaultElement, ElementType.earth);
    });

    test('engineer → electric', () {
      expect(ClassType.engineer.defaultElement, ElementType.electric);
    });

    test('trickster → electric', () {
      expect(ClassType.trickster.defaultElement, ElementType.electric);
    });

    test('necromancer → dark', () {
      expect(ClassType.necromancer.defaultElement, ElementType.dark);
    });

    test('summoner → dark', () {
      expect(ClassType.summoner.defaultElement, ElementType.dark);
    });

    test('vampire → dark', () {
      expect(ClassType.vampire.defaultElement, ElementType.dark);
    });

    // 무속성 클래스
    test('warrior → none', () {
      expect(ClassType.warrior.defaultElement, ElementType.none);
    });

    test('archer → none', () {
      expect(ClassType.archer.defaultElement, ElementType.none);
    });

    test('gunslinger → none', () {
      expect(ClassType.gunslinger.defaultElement, ElementType.none);
    });

    test('crusader → none', () {
      expect(ClassType.crusader.defaultElement, ElementType.none);
    });

    test('priestClass → none', () {
      expect(ClassType.priestClass.defaultElement, ElementType.none);
    });

    test('pastor → none', () {
      expect(ClassType.pastor.defaultElement, ElementType.none);
    });

    test('assistant → none', () {
      expect(ClassType.assistant.defaultElement, ElementType.none);
    });

    test('전체 16 클래스 매핑이 모두 유효한 ElementType 반환', () {
      for (final ct in ClassType.values) {
        expect(ElementType.values.contains(ct.defaultElement), isTrue,
            reason: '$ct 의 defaultElement 유효성');
      }
    });
  });

  group('CharacterDefinition.element getter', () {
    test('화염 군주 이그니스 (pyromancer) → fire', () {
      final ignis = CharacterDefinitions.byId('mdeal_s_ignis');
      expect(ignis.element, ElementType.fire);
      expect(ignis.classType, ClassType.pyromancer);
    });

    test('프로스티아 (cryomancer) → water', () {
      final frostia = CharacterDefinitions.byId('mdeal_s_frostia');
      expect(frostia.element, ElementType.water);
    });

    test('블라디미르 (vampire) → dark', () {
      final vladimir = CharacterDefinitions.byId('tank_s_vladimir');
      expect(vladimir.element, ElementType.dark);
    });

    test('오르빗 (engineer) → electric', () {
      final orbit = CharacterDefinitions.byId('util_s_orbit');
      expect(orbit.element, ElementType.electric);
    });

    test('바르그 (warrior) → none', () {
      final varg = CharacterDefinitions.byId('tank_s_varg');
      expect(varg.element, ElementType.none);
    });

    test('아르테미스 (archer) → none', () {
      final artemis = CharacterDefinitions.byId('pdeal_s_artemis');
      expect(artemis.element, ElementType.none);
    });

    test('카산드라 (gunslinger) → none', () {
      final cassandra = CharacterDefinitions.byId('pdeal_s_cassandra');
      expect(cassandra.element, ElementType.none);
    });

    test('아르테르 (crusader) → none', () {
      final arter = CharacterDefinitions.byId('priest_s_arter');
      expect(arter.element, ElementType.none);
    });

    test('힐다 (priestClass) → none', () {
      final hilda = CharacterDefinitions.byId('priest_a_hilda');
      expect(hilda.element, ElementType.none);
    });
  });

  group('CharacterDefinitions 데이터 무결성', () {
    test('전체 캐릭터 수 확인', () {
      expect(CharacterDefinitions.all.length, greaterThan(0));
    });

    test('모든 캐릭터 ID가 고유함', () {
      final ids = CharacterDefinitions.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('모든 캐릭터에 이름이 있음', () {
      for (final c in CharacterDefinitions.all) {
        expect(c.name, isNotEmpty, reason: '${c.id} 이름 확인');
      }
    });

    test('모든 캐릭터에 skillId가 있음', () {
      for (final c in CharacterDefinitions.all) {
        expect(c.skillId, isNotEmpty, reason: '${c.id} skillId 확인');
      }
    });

    test('byId로 존재하지 않는 ID 조회 시 예외 발생', () {
      expect(() => CharacterDefinitions.byId('nonexistent'),
          throwsStateError);
    });

    test('tryById로 존재하지 않는 ID 조회 시 null 반환', () {
      expect(CharacterDefinitions.tryById('nonexistent'), isNull);
    });

    test('byRank로 각 랭크별 캐릭터 조회', () {
      for (final rank in RankType.values) {
        final chars = CharacterDefinitions.byRank(rank);
        // 모든 결과가 해당 랭크인지 확인
        for (final c in chars) {
          expect(c.rank, rank, reason: '${c.id} 랭크 불일치');
        }
      }
    });

    test('S랭크 캐릭터가 존재함', () {
      expect(CharacterDefinitions.byRank(RankType.s), isNotEmpty);
    });

    test('C랭크 캐릭터가 존재함', () {
      expect(CharacterDefinitions.byRank(RankType.c), isNotEmpty);
    });
  });

  group('CharacterBaseStats 값 범위 검증', () {
    test('모든 캐릭터의 HP > 0', () {
      for (final c in CharacterDefinitions.all) {
        expect(c.baseStats.maxHp, greaterThan(0),
            reason: '${c.id} HP');
      }
    });

    test('모든 캐릭터의 공격력 > 0', () {
      for (final c in CharacterDefinitions.all) {
        expect(c.baseStats.attack, greaterThan(0),
            reason: '${c.id} 공격력');
      }
    });

    test('모든 캐릭터의 방어력 >= 0', () {
      for (final c in CharacterDefinitions.all) {
        expect(c.baseStats.defense, greaterThanOrEqualTo(0),
            reason: '${c.id} 방어력');
      }
    });

    test('모든 캐릭터의 공격속도 > 0', () {
      for (final c in CharacterDefinitions.all) {
        expect(c.baseStats.attackSpeed, greaterThan(0),
            reason: '${c.id} 공격속도');
      }
    });

    test('모든 캐릭터의 이동속도 > 0', () {
      for (final c in CharacterDefinitions.all) {
        expect(c.baseStats.moveSpeed, greaterThan(0),
            reason: '${c.id} 이동속도');
      }
    });

    test('S랭크 캐릭터의 기본 스탯이 C랭크보다 높음 (HP 기준)', () {
      final sChars = CharacterDefinitions.byRank(RankType.s);
      final cChars = CharacterDefinitions.byRank(RankType.c);
      final sAvgHp =
          sChars.map((c) => c.baseStats.maxHp).reduce((a, b) => a + b) /
              sChars.length;
      final cAvgHp =
          cChars.map((c) => c.baseStats.maxHp).reduce((a, b) => a + b) /
              cChars.length;
      expect(sAvgHp, greaterThan(cAvgHp));
    });
  });

  group('OwnedCharacter', () {
    test('기본값으로 레벨 1, 경험치 0', () {
      final owned = OwnedCharacter(
        instanceId: 'inst_001',
        characterId: 'tank_s_varg',
      );
      expect(owned.level, 1);
      expect(owned.exp, 0);
    });

    test('toJson/fromJson 라운드트립', () {
      final owned = OwnedCharacter(
        instanceId: 'inst_002',
        characterId: 'mdeal_s_ignis',
        level: 5,
        exp: 120,
      );
      final json = owned.toJson();
      final restored = OwnedCharacter.fromJson(json);

      expect(restored.instanceId, owned.instanceId);
      expect(restored.characterId, owned.characterId);
      expect(restored.level, owned.level);
      expect(restored.exp, owned.exp);
    });

    test('fromJson에서 level/exp 누락 시 기본값 사용', () {
      final json = {
        'instanceId': 'inst_003',
        'characterId': 'tank_c_guard',
      };
      final restored = OwnedCharacter.fromJson(json);
      expect(restored.level, 1);
      expect(restored.exp, 0);
    });
  });

  group('RankType 확장 속성', () {
    test('소환 확률 합계가 1.0', () {
      double total = 0;
      for (final rank in RankType.values) {
        total += rank.summonRate;
      }
      expect(total, closeTo(1.0, 0.001));
    });

    test('S랭크 확률이 가장 낮음 (3%)', () {
      expect(RankType.s.summonRate, 0.03);
    });

    test('C랭크 확률이 가장 높음 (50%)', () {
      expect(RankType.c.summonRate, 0.50);
    });

    test('모든 랭크에 displayName 존재', () {
      for (final rank in RankType.values) {
        expect(rank.displayName, isNotEmpty);
      }
    });
  });
}
