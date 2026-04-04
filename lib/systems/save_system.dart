// 게임 데이터 저장/불러오기 시스템 (SharedPreferences 기반)
part of '../castle_defense_game.dart';

extension SaveSystem on CastleDefenseGame {

  // ─── 저장 키 상수 ─────────────────────────────
  static const String _keyPlayerRace = 'playerRace';
  static const String _keyRaceSelected = 'raceSelected';
  static const String _keyUnlockedStageMax = 'unlockedStageMax';
  static const String _keyClearedStages = 'clearedStages';
  static const String _keyPlayerGem = 'playerGem';
  static const String _keyPlayerStarShards = 'playerStarShards';

  // ─── 게임 데이터 저장 ─────────────────────────
  Future<void> _saveGameData() async {
    final prefs = await SharedPreferences.getInstance();

    // 종족 (enum index로 저장)
    await prefs.setInt(_keyPlayerRace, playerRace.index);
    // 종족 선택 여부
    await prefs.setBool(_keyRaceSelected, raceSelected);
    // 해금된 최대 스테이지
    await prefs.setInt(_keyUnlockedStageMax, unlockedStageMax);
    // 클리어한 스테이지 목록 (쉼표 구분 문자열)
    await prefs.setString(
      _keyClearedStages,
      _clearedStages.join(','),
    );
    // 보유 젬
    await prefs.setInt(_keyPlayerGem, playerGem);
    // 보유 별조각
    await prefs.setInt(_keyPlayerStarShards, playerStarShards);
  }

  // ─── 게임 데이터 불러오기 ─────────────────────
  Future<void> _loadSaveData() async {
    final prefs = await SharedPreferences.getInstance();

    // 종족 선택 여부 (저장된 값이 없으면 기본값 유지)
    if (prefs.containsKey(_keyRaceSelected)) {
      raceSelected = prefs.getBool(_keyRaceSelected) ?? true;
    }

    // 종족 (index → enum 변환)
    if (prefs.containsKey(_keyPlayerRace)) {
      final raceIndex = prefs.getInt(_keyPlayerRace) ?? 0;
      if (raceIndex >= 0 && raceIndex < RaceType.values.length) {
        playerRace = RaceType.values[raceIndex];
      }
    }

    // 해금된 최대 스테이지
    if (prefs.containsKey(_keyUnlockedStageMax)) {
      unlockedStageMax = prefs.getInt(_keyUnlockedStageMax) ?? 1;
    }

    // 클리어한 스테이지 목록 (쉼표 구분 문자열 → Set<int>)
    if (prefs.containsKey(_keyClearedStages)) {
      final raw = prefs.getString(_keyClearedStages) ?? '';
      _clearedStages.clear();
      if (raw.isNotEmpty) {
        for (final s in raw.split(',')) {
          final parsed = int.tryParse(s.trim());
          if (parsed != null) _clearedStages.add(parsed);
        }
      }
    }

    // 보유 젬
    if (prefs.containsKey(_keyPlayerGem)) {
      playerGem = prefs.getInt(_keyPlayerGem) ?? 300;
    }

    // 보유 별조각
    if (prefs.containsKey(_keyPlayerStarShards)) {
      playerStarShards = prefs.getInt(_keyPlayerStarShards) ?? 0;
    }
  }
}
