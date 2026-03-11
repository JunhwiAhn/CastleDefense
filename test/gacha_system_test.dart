// 가챠 시스템 유닛 테스트

import 'package:flutter_test/flutter_test.dart';
import 'package:castle_defense_proto/systems/gacha_system.dart';
import 'package:castle_defense_proto/models/character_enums.dart';
import 'package:castle_defense_proto/data/character_definitions.dart';

void main() {
  late GachaSystem gacha;

  setUp(() {
    gacha = GachaSystem();
  });

  group('단일 뽑기 (summonOne)', () {
    test('결과가 null이 아닌 유효한 캐릭터 반환', () {
      final result = gacha.summonOne();
      expect(result, isNotNull);
      expect(result.id, isNotEmpty);
      expect(result.name, isNotEmpty);
    });

    test('반환된 캐릭터가 정의 목록에 존재함', () {
      final result = gacha.summonOne();
      final found = CharacterDefinitions.tryById(result.id);
      expect(found, isNotNull);
    });

    test('100회 뽑기 시 모두 유효한 캐릭터', () {
      for (int i = 0; i < 100; i++) {
        final result = gacha.summonOne();
        expect(CharacterDefinitions.tryById(result.id), isNotNull,
            reason: '뽑기 $i번째 결과 유효성');
      }
    });
  });

  group('10연차 뽑기 (summonTen)', () {
    test('정확히 10개 결과 반환', () {
      final results = gacha.summonTen();
      expect(results.length, 10);
    });

    test('마지막 캐릭터가 최소 A랭크 이상 보장', () {
      // 통계적 검증: 여러 번 실행하여 마지막이 항상 A 이상인지 확인
      for (int trial = 0; trial < 50; trial++) {
        final results = gacha.summonTen();
        final lastRank = results.last.rank;
        expect(
          lastRank == RankType.s || lastRank == RankType.a,
          isTrue,
          reason: '시도 $trial: 마지막 캐릭터 랭크=${lastRank.displayName} (A 이상이어야 함)',
        );
      }
    });

    test('모든 결과가 유효한 캐릭터', () {
      final results = gacha.summonTen();
      for (final c in results) {
        expect(CharacterDefinitions.tryById(c.id), isNotNull,
            reason: '${c.id} 유효성');
      }
    });
  });

  group('확률 분포 검증', () {
    test('1000회 뽑기 시 C랭크가 가장 많음', () {
      final counts = <RankType, int>{};
      for (final rank in RankType.values) {
        counts[rank] = 0;
      }

      for (int i = 0; i < 1000; i++) {
        final result = gacha.summonOne();
        counts[result.rank] = counts[result.rank]! + 1;
      }

      // C랭크(50%)가 가장 많아야 함
      expect(counts[RankType.c]!, greaterThan(counts[RankType.s]!));
      expect(counts[RankType.c]!, greaterThan(counts[RankType.a]!));
    });

    test('1000회 뽑기 시 S랭크가 가장 적음', () {
      final counts = <RankType, int>{};
      for (final rank in RankType.values) {
        counts[rank] = 0;
      }

      for (int i = 0; i < 1000; i++) {
        final result = gacha.summonOne();
        counts[result.rank] = counts[result.rank]! + 1;
      }

      // S랭크(3%)가 가장 적어야 함
      expect(counts[RankType.s]!, lessThan(counts[RankType.a]!));
      expect(counts[RankType.s]!, lessThan(counts[RankType.b]!));
      expect(counts[RankType.s]!, lessThan(counts[RankType.c]!));
    });

    test('5000회 뽑기 시 각 랭크 비율이 이론치 ±5% 이내', () {
      final counts = <RankType, int>{};
      for (final rank in RankType.values) {
        counts[rank] = 0;
      }

      const trials = 5000;
      for (int i = 0; i < trials; i++) {
        final result = gacha.summonOne();
        counts[result.rank] = counts[result.rank]! + 1;
      }

      // 허용 오차: ±5% (통계적 변동)
      const tolerance = 0.05;
      for (final rank in RankType.values) {
        final actual = counts[rank]! / trials;
        final expected = rank.summonRate;
        expect(
          actual,
          closeTo(expected, tolerance),
          reason:
              '${rank.displayName}랭크: 실제=${(actual * 100).toStringAsFixed(1)}% 기대=${(expected * 100).toStringAsFixed(1)}%',
        );
      }
    });
  });

  group('비용 계산', () {
    test('단일 뽑기 비용 = 100 젬', () {
      expect(gacha.getSingleSummonCost(), 100);
    });

    test('10연차 비용 = 900 젬 (10% 할인)', () {
      expect(gacha.getTenSummonCost(), 900);
    });

    test('10연차가 단일 10회보다 저렴함', () {
      expect(
        gacha.getTenSummonCost(),
        lessThan(gacha.getSingleSummonCost() * 10),
      );
    });
  });

  group('byRank 캐릭터 후보군 검증', () {
    test('모든 랭크에 최소 1명 이상 캐릭터 존재', () {
      for (final rank in RankType.values) {
        final candidates = CharacterDefinitions.byRank(rank);
        expect(candidates, isNotEmpty,
            reason: '${rank.displayName}랭크 캐릭터 부재');
      }
    });

    test('byRank 결과의 모든 캐릭터가 해당 랭크', () {
      for (final rank in RankType.values) {
        final candidates = CharacterDefinitions.byRank(rank);
        for (final c in candidates) {
          expect(c.rank, rank);
        }
      }
    });
  });

  group('엣지 케이스', () {
    test('연속 뽑기 시 크래시 없음', () {
      // 빠르게 여러 번 연속 호출
      for (int i = 0; i < 500; i++) {
        expect(() => gacha.summonOne(), returnsNormally);
      }
    });

    test('10연차 연속 호출 시 크래시 없음', () {
      for (int i = 0; i < 50; i++) {
        expect(() => gacha.summonTen(), returnsNormally);
      }
    });

    test('GachaSystem 여러 인스턴스 독립 동작', () {
      final gacha1 = GachaSystem();
      final gacha2 = GachaSystem();
      // 각각 독립적으로 동작
      final r1 = gacha1.summonOne();
      final r2 = gacha2.summonOne();
      expect(r1, isNotNull);
      expect(r2, isNotNull);
    });
  });
}
