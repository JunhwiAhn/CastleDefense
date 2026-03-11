// 속성 시스템 유닛 테스트
// castle_defense_game.dart 의 getElementMultiplier() 로직을 검증

import 'package:flutter_test/flutter_test.dart';
import 'package:castle_defense_proto/models/character_enums.dart';

// getElementMultiplier 로직 미러링 (인스턴스 메서드라 직접 호출 불가)
// castle_defense_game.dart:2193-2212 와 동일한 로직
double getElementMultiplier(ElementType attacker, ElementType defender) {
  if (attacker == ElementType.none || defender == ElementType.none) return 1.0;
  // 암흑 공격: 대암흑 x1.0, 나머지 x1.1
  if (attacker == ElementType.dark) {
    return defender == ElementType.dark ? 1.0 : 1.1;
  }
  // 유리 상성: x1.5
  if (attacker == ElementType.fire && defender == ElementType.earth) return 1.5;
  if (attacker == ElementType.water && defender == ElementType.fire) return 1.5;
  if (attacker == ElementType.earth && defender == ElementType.electric) return 1.5;
  if (attacker == ElementType.electric && defender == ElementType.water) return 1.5;
  // 불리 상성: x0.75
  if (attacker == ElementType.fire && defender == ElementType.water) return 0.75;
  if (attacker == ElementType.water && defender == ElementType.earth) return 0.75;
  if (attacker == ElementType.earth && defender == ElementType.fire) return 0.75;
  if (attacker == ElementType.electric && defender == ElementType.earth) return 0.75;
  // 암흑 방어: x1.1
  if (defender == ElementType.dark) return 1.1;
  return 1.0;
}

void main() {
  group('속성 상성 계산 (getElementMultiplier)', () {
    group('유리 상성 (x1.5)', () {
      test('화염 → 대지 = 1.5', () {
        expect(getElementMultiplier(ElementType.fire, ElementType.earth), 1.5);
      });

      test('수빙 → 화염 = 1.5', () {
        expect(getElementMultiplier(ElementType.water, ElementType.fire), 1.5);
      });

      test('대지 → 번개 = 1.5', () {
        expect(
            getElementMultiplier(ElementType.earth, ElementType.electric), 1.5);
      });

      test('번개 → 수빙 = 1.5', () {
        expect(
            getElementMultiplier(ElementType.electric, ElementType.water), 1.5);
      });
    });

    group('불리 상성 (x0.75)', () {
      test('화염 → 수빙 = 0.75', () {
        expect(
            getElementMultiplier(ElementType.fire, ElementType.water), 0.75);
      });

      test('수빙 → 대지 = 0.75', () {
        expect(
            getElementMultiplier(ElementType.water, ElementType.earth), 0.75);
      });

      test('대지 → 화염 = 0.75', () {
        expect(
            getElementMultiplier(ElementType.earth, ElementType.fire), 0.75);
      });

      test('번개 → 대지 = 0.75', () {
        expect(getElementMultiplier(ElementType.electric, ElementType.earth),
            0.75);
      });
    });

    group('암흑 속성', () {
      test('암흑 → 화염 = 1.1', () {
        expect(getElementMultiplier(ElementType.dark, ElementType.fire), 1.1);
      });

      test('암흑 → 수빙 = 1.1', () {
        expect(getElementMultiplier(ElementType.dark, ElementType.water), 1.1);
      });

      test('암흑 → 대지 = 1.1', () {
        expect(getElementMultiplier(ElementType.dark, ElementType.earth), 1.1);
      });

      test('암흑 → 번개 = 1.1', () {
        expect(
            getElementMultiplier(ElementType.dark, ElementType.electric), 1.1);
      });

      test('암흑 → 암흑 = 1.0 (동속성)', () {
        expect(getElementMultiplier(ElementType.dark, ElementType.dark), 1.0);
      });

      test('화염 → 암흑 = 1.1 (암흑 방어 시)', () {
        expect(getElementMultiplier(ElementType.fire, ElementType.dark), 1.1);
      });

      test('수빙 → 암흑 = 1.1', () {
        expect(getElementMultiplier(ElementType.water, ElementType.dark), 1.1);
      });

      test('대지 → 암흑 = 1.1', () {
        expect(getElementMultiplier(ElementType.earth, ElementType.dark), 1.1);
      });

      test('번개 → 암흑 = 1.1', () {
        expect(
            getElementMultiplier(ElementType.electric, ElementType.dark), 1.1);
      });
    });

    group('동속성 (x1.0)', () {
      test('화염 → 화염 = 1.0', () {
        expect(getElementMultiplier(ElementType.fire, ElementType.fire), 1.0);
      });

      test('수빙 → 수빙 = 1.0', () {
        expect(
            getElementMultiplier(ElementType.water, ElementType.water), 1.0);
      });

      test('대지 → 대지 = 1.0', () {
        expect(
            getElementMultiplier(ElementType.earth, ElementType.earth), 1.0);
      });

      test('번개 → 번개 = 1.0', () {
        expect(getElementMultiplier(ElementType.electric, ElementType.electric),
            1.0);
      });
    });

    group('무속성 (none) 처리', () {
      test('무속성 공격 → 화염 = 1.0', () {
        expect(getElementMultiplier(ElementType.none, ElementType.fire), 1.0);
      });

      test('화염 → 무속성 방어 = 1.0', () {
        expect(getElementMultiplier(ElementType.fire, ElementType.none), 1.0);
      });

      test('무속성 → 무속성 = 1.0', () {
        expect(getElementMultiplier(ElementType.none, ElementType.none), 1.0);
      });

      test('암흑 → 무속성 = 1.0', () {
        expect(getElementMultiplier(ElementType.dark, ElementType.none), 1.0);
      });

      test('무속성 → 암흑 = 1.0', () {
        expect(getElementMultiplier(ElementType.none, ElementType.dark), 1.0);
      });
    });

    group('관계 없는 속성 조합 (x1.0)', () {
      test('화염 → 번개 = 1.0', () {
        expect(getElementMultiplier(ElementType.fire, ElementType.electric),
            1.0);
      });

      test('수빙 → 번개 = 1.0', () {
        expect(getElementMultiplier(ElementType.water, ElementType.electric),
            1.0);
      });
    });

    group('상성 순환 검증 (화→지→전→수→화)', () {
      test('전체 순환이 모두 x1.5', () {
        // 화 → 지 → 전 → 수 → 화
        final cycle = [
          [ElementType.fire, ElementType.earth],
          [ElementType.earth, ElementType.electric],
          [ElementType.electric, ElementType.water],
          [ElementType.water, ElementType.fire],
        ];
        for (final pair in cycle) {
          expect(getElementMultiplier(pair[0], pair[1]), 1.5,
              reason: '${pair[0]} → ${pair[1]} 유리 상성');
        }
      });

      test('역순환이 모두 x0.75', () {
        // 화 ← 지 ← 전 ← 수 ← 화  (역방향은 불리)
        final reverseCycle = [
          [ElementType.earth, ElementType.fire],
          [ElementType.electric, ElementType.earth],
          [ElementType.water, ElementType.earth],
          [ElementType.fire, ElementType.water],
        ];
        for (final pair in reverseCycle) {
          expect(getElementMultiplier(pair[0], pair[1]), 0.75,
              reason: '${pair[0]} → ${pair[1]} 불리 상성');
        }
      });
    });
  });

  group('ElementType 확장 속성', () {
    test('모든 ElementType에 색상 값이 있음', () {
      for (final e in ElementType.values) {
        expect(e.color, isNonZero);
      }
    });

    test('화염 색상은 빨간색 계열', () {
      expect(ElementType.fire.color, 0xFFF44336);
    });

    test('무속성 이모지는 빈 문자열', () {
      expect(ElementType.none.emoji, '');
    });

    test('각 속성 이모지가 비어있지 않음 (none 제외)', () {
      for (final e in ElementType.values) {
        if (e == ElementType.none) continue;
        expect(e.emoji, isNotEmpty, reason: '$e 이모지');
      }
    });
  });
}
