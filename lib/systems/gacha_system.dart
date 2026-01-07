// gacha_system.dart

import 'dart:math';
import '../models/character_model.dart';
import '../models/character_enums.dart';
import '../data/character_definitions.dart';

class GachaSystem {
  final Random _random = Random();

  // 단일 뽑기
  CharacterDefinition summonOne() {
    final rank = _determineRank();
    final candidates = CharacterDefinitions.byRank(rank);
    return candidates[_random.nextInt(candidates.length)];
  }

  // 10연차 뽑기 (보장: 최소 1개 A랭크 이상)
  List<CharacterDefinition> summonTen() {
    final results = <CharacterDefinition>[];

    // 9개 일반 뽑기
    for (int i = 0; i < 9; i++) {
      results.add(summonOne());
    }

    // 마지막 1개는 최소 A랭크 보장
    final lastRank = _determineRank();
    final guaranteedRank = lastRank == RankType.c || lastRank == RankType.b
        ? RankType.a
        : lastRank;

    final candidates = CharacterDefinitions.byRank(guaranteedRank);
    results.add(candidates[_random.nextInt(candidates.length)]);

    return results;
  }

  // 확률에 따른 랭크 결정
  RankType _determineRank() {
    final roll = _random.nextDouble();
    double cumulative = 0.0;

    // S: 3%, A: 12%, B: 35%, C: 50%
    for (final rank in [RankType.s, RankType.a, RankType.b, RankType.c]) {
      cumulative += rank.summonRate;
      if (roll < cumulative) {
        return rank;
      }
    }

    return RankType.c; // 폴백
  }

  // 뽑기 비용
  int getSingleSummonCost() => 100; // 젬 100개
  int getTenSummonCost() => 900; // 젬 900개 (10% 할인)
}
