// castle_defense_game.dart
// 파일 분할: 모델/enum/데이터는 part 파일로 분리

import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'models/character_model.dart';
import 'models/character_enums.dart';
import 'data/character_definitions.dart';
import 'systems/gacha_system.dart';

// Part 파일: 모델/enum/데이터 분리
part 'models/game_enums.dart';
part 'models/augment.dart';
part 'models/round_config.dart';
part 'models/game_objects.dart';

// Part 파일: 렌더링 분리 (Designer 전용 편집 영역)
part 'ui/render_game.dart';
part 'ui/render_ui.dart';

// Part 파일: 시스템 로직 분리 (Engineer 전용 편집 영역)
part 'systems/stage_system.dart';
part 'systems/combat_system.dart';
part 'systems/progression_system.dart';

class CastleDefenseGame extends FlameGame with TapCallbacks, DragCallbacks {
  // -----------------------------
  // 기본 설정
  // -----------------------------
  final double castleHeight = 50.0; // 성 크기 축소
  // 리디자인 B-2-16: 성 최대 HP (상점 업그레이드로 증가)
  int get castleMaxHp => 200 + _shopCastleMaxHpCount * 20;
  int castleHp = 200; // 리디자인: 성 현재 HP
  double castleFlashTimer = 0.0; // Designer 요청 D-3-1: 성 피격 점멸 타이머

  // 몬스터 설정
  final double monsterRadius = 16.0;
  // 리디자인: 타입별 이동 속도 (낙하 속도 삭제)
  static const double _normalMonsterSpeed = 25.0; // 속도 감소 (40→25)
  static const double _miniBossSpeed = 18.0; // 속도 감소 (30→18)
  static const double _bossSpeed = 15.0; // 속도 감소 (25→15)

  // 무기 (프로토타입)
  final int weaponDamage = 1; // 기본검 데미지

  // 스테이지 & 라운드 관련
  GameState gameState = GameState.loading;
  int stageLevel = 1;
  int currentRound = 1; // 현재 라운드 (1~10)
  int totalRoundsInStage = 10; // 스테이지당 라운드 수

  // 현재 라운드 스폰 관련
  int totalMonstersInRound = 5; // 현재 라운드의 총 몬스터 수
  int spawnedMonsters = 0; // 현재 라운드에서 스폰된 몬스터 수
  int defeatedMonsters = 0; // 현재 라운드에서 플레이어가 처치한 몬스터 수
  int escapedMonsters = 0; // 현재 라운드에서 성에 도달한 몬스터 수 (미처치)

  int monsterMaxHp = 2; // 현재 라운드 몬스터 최대 HP
  double spawnTimer = 0.0;

  bool bossSpawned = false; // 보스/미니보스가 이미 스폰되었는지 여부
  // 리디자인 B-2-17: 미니보스 스폰 카운터
  int miniBossesSpawned = 0;

  // 라운드 시간 제한
  double roundTimer = 0.0; // 현재 라운드 경과 시간
  double roundTimeLimit = 120.0; // 현재 라운드 제한 시간 (초)
  double gameTime = 0.0; // 전역 게임 시간 (충돌 데미지 쿨다운용)

  // 로딩 화면용
  double _loadingTimer = 0.0;
  final double _loadingDuration = 0.5; // 초 단위

  // 라운드 클리어 대기용
  double _roundClearTimer = 0.0;
  final double _roundClearDuration = 3.0; // 리디자인 B-2-18: 라운드 간 3초 인터벌

  // D-1-6: 라운드 중 획득 XP/골드 추적 (클리어 연출용)
  int _roundXpGained = 0;
  int _roundGoldGained = 0;

  // 라운드 언락 상태
  int unlockedRoundMax = 1; // 처음엔 라운드 1만 선택 가능

  // 스테이지 선택 화면용
  int selectedStageInUI = 1; // 라운드 선택 화면에서 현재 보고 있는 스테이지

  // 하단 메뉴
  BottomMenu currentBottomMenu = BottomMenu.home;

  // 결과 화면용 정보
  bool _lastStageClear = false;

  // 테스트 갓 모드
  bool _godModeEnabled = false;

  // 리디자인 B-2-4: 버추얼 스틱 상태
  bool _stickActive = false;
  Vector2 _stickBasePos = Vector2.zero();
  Vector2 _stickKnobPos = Vector2.zero();
  static const double _stickOuterRadius = 60.0;
  static const double _stickDeadzone = 7.0; // Planner 추천: 외경 12%

  // 리디자인 B-2-5: 메인 캐릭터 이동 속도
  static const double _mainCharSpeed = 150.0;

  // 리디자인 B-2-3: 성직자 성 회복 타이머
  double _priestHealTimer = 0.0;
  static const double _priestHealInterval = 5.0; // 5초마다 회복
  static const int _priestHealAmount = 3; // 1회 회복량

  // 리디자인 B-2-6: 메인 캐릭터 HP
  // 리디자인 B-2-16: 메인 캐릭터 최대 HP (상점 업그레이드로 증가)
  int get _mainCharMaxHp => 50 + _shopMainCharHpCount * 10;
  int _mainCharHp = 50;
  bool _mainCharAlive = true;
  double _mainCharDamageCooldown = 0.0; // 적 접촉 데미지 쿨다운 (0.5초)

  // 리디자인 B-2-7: 복활 시스템
  bool _mainCharRespawning = false; // 복활 카운트다운 중
  double _respawnTimer = 0.0; // 복활 카운트다운 타이머
  double _invincibleTimer = 0.0; // 복활 후 무적 타이머

  // 플레이어 정보 (네비게이션 바용)
  String playerNickname = 'Player';
  int playerLevel = 1;
  int playerGold = 1000;
  // 리디자인 B-2-10: 인게임 캐릭터 XP / 레벨
  int playerXp = 0;
  int playerCharLevel = 1;
  // 리디자인 B-2-11: 바프 스택 카운터 (P-2-1 기준)
  int _atkUpCount = 0;       // 공격력 UP 스택 (최대 5)
  int _spdUpCount = 0;       // 공격속도 UP 스택 (최대 5)
  int _moveUpCount = 0;      // 이동속도 UP 스택 (최대 3)
  int _rangeUpCount = 0;     // 사거리 UP 스택 (최대 3)
  int _towerUpCount = 0;     // 타워강화 스택 (최대 5)
  int _magnetCount = 0;      // XP 자석 스택 (최대 3)
  bool _castleBarrierActive = false; // 성 바리어 활성 여부
  double _castleBarrierTimer = 0.0;  // 바리어 남은 시간
  static const double _castleBarrierDuration = 10.0;
  // 리디자인 B-2-16: 상점 영구 강화 카운터 (스테이지 간 유지)
  int _shopCastleMaxHpCount = 0;    // 성 최대 HP +20 구매 횟수 (최대 10)
  int _shopTowerPowerCount = 0;     // 타워 공격력 +5% 구매 횟수 (최대 10)
  int _shopMainCharHpCount = 0;     // 메인 캐릭터 HP +10 구매 횟수 (최대 5)
  // 속성 시스템: 메인 캐릭터 현재 속성 (바프로 부여, 스테이지 내 유지)
  ElementType _mainCharElement = ElementType.none;
  int _elementMasteryCount = 0; // 속성 마스터리 스택 (최대 3)

  // 증강 시스템 (augment-system.md 참조)
  List<Augment> activeAugments = []; // 현재 스테이지 취득 증강
  List<Augment> _augmentOptions = []; // 현재 선택지 3개
  final Set<String> _acquiredAugmentIds = {}; // 취득한 증강 ID 집합 (중복 방지)
  // 증강별 효과 상태
  bool _augmentL01Used = false;   // L-01 불사의 서약: 1회 사용 여부
  bool _augmentL03Used = false;   // L-03 대지의 수호자: 1회 사용 여부
  bool _augmentR12Used = false;   // R-12 불굴의 성: 1회 발동 여부
  int _augmentR04Stacks = 0;      // R-04 성의 분노: 현재 스택 수
  double _augmentR04Timer = 0.0;  // R-04 타이머
  // TODO: L-07 영혼의 연쇄 - 타워 공격 크리티컬 판정 로직 구현 필요
  bool _augmentL02Active = false;        // L-02 왕의 포효: 타워 강화 활성 여부
  double _augmentL02Timer = 0.0;         // L-02 타이머 (10초)
  bool _augmentL03BarrierActive = false; // L-03 대지의 수호자: 바리어 활성 여부
  double _augmentL03BarrierTimer = 0.0;  // L-03 타이머 (60초)
  final Map<BuffType, int> _buffSelectionCount = {}; // L-08: 바프 선택 횟수 추적

  // 레벨업 바프 선택지 (3장)
  List<BuffType> _buffOptions = [];
  BuffType? _lastChosenBuff; // 직전 선택 바프 (50% 확률 감소용)
  // 리디자인 B-2-12: XP 자석 범위 (레벨업 직후 1초간 전체 흡인)
  double _xpMagnetTimer = 0.0; // 자석 효과 남은 시간
  static const double _xpMagnetDuration = 1.0;
  // D-3-5: 스킬 발동 시 슬로우 모션 타이머 (0.3초)
  double _slowMotionTimer = 0.0;
  int playerGem = 500; // 뽑기 테스트용으로 많이 줌
  int playerEnergy = 50;
  int playerMaxEnergy = 50;
  DateTime _lastEnergyUpdateTime = DateTime.now();

  // 캐릭터 인벤토리
  final List<OwnedCharacter> ownedCharacters = [];
  final GachaSystem gachaSystem = GachaSystem();

  // 뽑기 결과 (애니메이션용)
  List<CharacterDefinition>? gachaResults;
  int gachaResultIndex = 0;

  // 캐릭터 도감 스크롤
  double characterListScrollOffset = 0.0;
  double _dragStartY = 0.0;

  // 파티 설정 (4개 슬롯)
  // 리디자인: 5슬롯 (0=메인캐릭터, 1-4=타워)
  final List<String?> partySlots = [null, null, null, null];
  bool showPartySelectionPopup = false;
  int selectedPartySlotIndex = -1; // 현재 선택 중인 파티 슬롯
  double partyPopupScrollOffset = 0.0; // 파티 팝업 스크롤 오프셋
  double _partyPopupDragStartY = 0.0; // 파티 팝업 드래그 시작 Y

  // 몬스터 리스트
  final List<_Monster> monsters = [];

  // 캐릭터 유닛 (실제 전투 유닛)
  final List<_CharacterUnit> characterUnits = [];

  // 투사물 리스트
  final List<_Projectile> projectiles = [];

  // VFX 이펙트 리스트
  final List<_VfxEffect> vfxEffects = [];

  // 리디자인 B-2-8: XP 젬 리스트
  final List<_XpGem> xpGems = [];

  // 리디자인 B-2-15: 골드 드롭 리스트
  final List<_GoldDrop> goldDrops = [];

  // 리디자인 B-2-13: 스킬 게이지 (0.0~100.0)
  double skillGauge = 0.0;
  bool skillReady = false; // 100%에서 true

  // 캐릭터 슬롯 (5개 - UI용)
  final List<_CharacterSlot> characterSlots = [];

  // 랜덤
  final Random _random = Random();

  // Goblinスプライト
  Image? goblinImage;
  bool goblinImageLoaded = false;

  // D-4-1: 성 스프라이트
  Image? castleImage;
  bool castleImageLoaded = false;

  // D-3-2: XP 젬 스프라이트
  Image? xpGemImage;
  bool xpGemImageLoaded = false;

  // D-3-3: 골드 코인 스프라이트
  Image? goldCoinImage;
  bool goldCoinImageLoaded = false;

  // D-4-3: 보스/미니보스 스프라이트
  Image? bossMonsterImage;
  bool bossMonsterImageLoaded = false;
  Image? minibossMonsterImage;
  bool minibossMonsterImageLoaded = false;

  // 스테이지별 몬스터 스프라이트
  Image? normalGoblinImage;
  Image? normalSkeletonImage;
  Image? normalSlimeImage;
  Image? normalPoisonSkullImage;
  Image? normalGreenGoblinImage;
  // 스테이지별 일반 몬스터 (각 스테이지 3종)
  final Map<String, Image> stageMonsterImages = {};
  // 미니보스 스프라이트
  Image? minibossGoblinWarriorImage;
  Image? minibossSkullWarriorImage;
  Image? minibossSlimeKingImage;
  // 보스 스프라이트
  Image? bossCerberusImage;
  Image? bossPoisonWarriorImage;
  // 속성별 미니보스 스프라이트
  final Map<String, Image> minibossElementImages = {};

  // 캐릭터 스프라이트
  final Map<String, Image> characterImages = {};

  // 성 요새 스프라이트
  Image? castleFortressImage;

  // #34 속성UI: 부유 데미지 숫자 목록
  final List<_DamageNumber> _damageNumbers = [];

  // B-3-2: 몬스터 오브젝트 풀 (GC 압력 감소)
  final List<_Monster> _monsterPool = [];

  // 캐릭터 설정
  final double characterUnitRadius = 12.0; // 캐릭터 크기
  final double projectileSpeed = 200.0; // 투사물 속도
  final double meleeRange = 40.0; // 근거리 공격 범위
  final double rangedRange = 375.0; // 원거리 공격 범위 (250 * 1.5)
  final double physicalDealerRange = 525.0; // 물리 딜러 사거리 (350 * 1.5)
  final double priestRange = 600.0; // 힐러(성직자) 사거리 (400 * 1.5)
  final double topBoundary = 0.0; // 리디자인: 상단 제한 없음

  // 성 중심 좌표 (화면 중앙)
  double get castleCenterX => size.x / 2;
  double get castleCenterY => size.y - castleHeight / 2 - 10; // 화면 맨 아래 배치

  int get killedMonsters => defeatedMonsters;

  // -----------------------------
  // 라이프사이클
  // -----------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 리디자인 B-3-1: 기준 해상도 390×844 (FitWidth 스케일링)
    camera.viewport = FixedResolutionViewport(resolution: Vector2(390, 844));
    _initializeCharacterSlots(); // 캐릭터 슬롯 초기화
    _loadStage(1); // 내부 파라미터 초기화
    gameState = GameState.loading; // GameScreen 진입 즉시 로딩부터 시작
    _loadingTimer = 0.0;

    // 스프라이트 전체 로드
    await Future.wait([
      _loadGoblinSprite(),
      _loadCastleSprite(),
      _loadXpGemSprite(),
      _loadGoldCoinSprite(),
      _loadBossSprites(),
      _loadMonsterSprites(),
      _loadCharacterSprites(),
      _loadCastleFortressSprite(),
    ]);
  }

  // Goblinスプライトをロード
  Future<void> _loadGoblinSprite() async {
    try {
      goblinImage = await images.load('goblin.png');
      goblinImageLoaded = true;
    } catch (e) {
      goblinImageLoaded = false;
    }
  }

  // D-4-1: 성 스프라이트 로드
  Future<void> _loadCastleSprite() async {
    try {
      castleImage = await images.load('castle.png');
      castleImageLoaded = true;
    } catch (e) {
      castleImageLoaded = false;
    }
  }

  // D-3-2: XP 젬 스프라이트 로드
  Future<void> _loadXpGemSprite() async {
    try {
      xpGemImage = await images.load('xp_gem.png');
      xpGemImageLoaded = true;
    } catch (e) {
      xpGemImageLoaded = false;
    }
  }

  // D-3-3: 골드 코인 스프라이트 로드
  Future<void> _loadGoldCoinSprite() async {
    try {
      goldCoinImage = await images.load('gold_coin.png');
      goldCoinImageLoaded = true;
    } catch (e) {
      goldCoinImageLoaded = false;
    }
  }

  // D-4-3/D-4-4: 보스/미니보스 스프라이트 로드
  Future<void> _loadBossSprites() async {
    try {
      bossMonsterImage = await images.load('boss_monster.png');
      bossMonsterImageLoaded = true;
    } catch (e) {
      bossMonsterImageLoaded = false;
    }
    try {
      minibossMonsterImage = await images.load('miniboss_monster.png');
      minibossMonsterImageLoaded = true;
    } catch (e) {
      minibossMonsterImageLoaded = false;
    }
  }

  // 몬스터 스프라이트 일괄 로드 (스테이지별 + 미니보스 + 보스)
  Future<void> _loadMonsterSprites() async {
    // 일반 몬스터 (기본 5종)
    final normalMonsters = {
      'normal_goblin': 'monsters/normal_goblin.png',
      'normal_skeleton': 'monsters/normal_skeleton.png',
      'normal_slime': 'monsters/normal_slime.png',
      'normal_poison_skull': 'monsters/normal_poison_skull.png',
      'normal_green_goblin': 'monsters/normal_green_goblin.png',
    };
    for (final entry in normalMonsters.entries) {
      try {
        final img = await images.load(entry.value);
        switch (entry.key) {
          case 'normal_goblin': normalGoblinImage = img; break;
          case 'normal_skeleton': normalSkeletonImage = img; break;
          case 'normal_slime': normalSlimeImage = img; break;
          case 'normal_poison_skull': normalPoisonSkullImage = img; break;
          case 'normal_green_goblin': normalGreenGoblinImage = img; break;
        }
      } catch (_) {}
    }

    // 스테이지별 몬스터 (각 스테이지 3종)
    final stageFiles = [
      'monsters/monster_stage1_rat.png',
      'monsters/monster_stage1_slime.png',
      'monsters/monster_stage1_worm.png',
      'monsters/monster_stage2_skull.png',
      'monsters/monster_stage2_slime.png',
      'monsters/monster_stage2_spider.png',
      'monsters/monster_stage3_scorpion.png',
      'monsters/monster_stage3_skull.png',
      'monsters/monster_stage3_slime.png',
      'monsters/monster_stage4_skull.png',
      'monsters/monster_stage4_spider.png',
      'monsters/monster_stage4_wolf.png',
      'monsters/monster_stage5_boneworm.png',
      'monsters/monster_stage5_ooze.png',
      'monsters/monster_stage5_wolf.png',
    ];
    for (final path in stageFiles) {
      try {
        final img = await images.load(path);
        // 키: 파일명에서 확장자 제거 (예: monster_stage1_rat)
        final key = path.split('/').last.replaceAll('.png', '');
        stageMonsterImages[key] = img;
      } catch (_) {}
    }

    // 미니보스 스프라이트
    try { minibossGoblinWarriorImage = await images.load('monsters/miniboss_goblin_warrior.png'); } catch (_) {}
    try { minibossSkullWarriorImage = await images.load('monsters/miniboss_skull_warrior.png'); } catch (_) {}
    try { minibossSlimeKingImage = await images.load('monsters/miniboss_slime_king.png'); } catch (_) {}

    // 보스 스프라이트
    try { bossCerberusImage = await images.load('monsters/boss_cerberus.png'); } catch (_) {}
    try { bossPoisonWarriorImage = await images.load('monsters/boss_poison_warrior.png'); } catch (_) {}

    // 속성별 미니보스
    for (final elem in ['fire', 'water', 'earth', 'dark']) {
      try {
        final img = await images.load('monsters/miniboss_cerberus_$elem.png');
        minibossElementImages[elem] = img;
      } catch (_) {}
    }
  }

  // 캐릭터 스프라이트 일괄 로드 (16종 + 메인)
  Future<void> _loadCharacterSprites() async {
    final names = [
      'warrior', 'guardian', 'berserker', 'archer', 'gunslinger', 'rogue',
      'pyromancer', 'cryomancer', 'warlock', 'priest', 'druid', 'paladin',
      'alchemist', 'engineer', 'necromancer', 'summoner', 'main_character',
    ];
    for (final name in names) {
      try {
        characterImages[name] = await images.load('characters/$name.png');
      } catch (_) {}
    }
  }

  // 성 요새 스프라이트 로드
  Future<void> _loadCastleFortressSprite() async {
    try {
      castleFortressImage = await images.load('characters/castle_fortress.png');
    } catch (_) {}
  }

  // 캐릭터 슬롯 초기화 (처음에는 모두 비어있음)
  void _initializeCharacterSlots() {
    characterSlots.clear();
    // 리디자인: 5슬롯 (0=메인, 1-4=타워)
    for (int i = 0; i < 5; i++) {
      characterSlots.add(_CharacterSlot(
        slotIndex: i,
        hasCharacter: false, // 모든 슬롯이 처음엔 비어있음
        characterName: '',
        skillReady: false,
      ));
    }
  }


  // -----------------------------
  // 업데이트 루프
  // -----------------------------
  @override
  void update(double dt) {
    super.update(dt);

    // 에너지 충전 업데이트 (모든 상태에서 지속적으로 실행)
    _updateEnergy();

    switch (gameState) {
      case GameState.loading:
        _updateLoading(dt);
        return;
      case GameState.roundSelect:
        return;
      case GameState.playing:
        _updatePlaying(dt);
        return;
      case GameState.paused:
        // 일시정지 중에는 업데이트 하지 않음
        return;
      case GameState.levelUp:
        // 리디자인 B-2-11/B-2-12: 레벨업 화면 - 젬 자석 타이머만 진행
        if (_xpMagnetTimer > 0) {
          _xpMagnetTimer -= dt;
          _attractAllXpGems();
        }
        return;
      case GameState.roundClear:
        _updateRoundClear(dt);
        return;
      case GameState.augmentSelect:
        // 증강 선택 중 - 업데이트 없음 (탭 입력 대기)
        return;
      case GameState.shopOpen:
        // 리디자인 B-2-16: 상점 화면 - 업데이트 없음
        return;
      case GameState.result:
        return;
    }
  }

  // 에너지 충전 로직 (10분에 1개씩, 최대 50개)
  void _updateEnergy() {
    if (playerEnergy >= playerMaxEnergy) {
      _lastEnergyUpdateTime = DateTime.now();
      return;
    }

    final now = DateTime.now();
    final diff = now.difference(_lastEnergyUpdateTime);

    // 10분마다 1개씩 충전
    final energyToAdd = diff.inMinutes ~/ 10;
    if (energyToAdd > 0) {
      playerEnergy = (playerEnergy + energyToAdd).clamp(0, playerMaxEnergy);
      _lastEnergyUpdateTime = _lastEnergyUpdateTime.add(
        Duration(minutes: energyToAdd * 10),
      );
    }
  }

  void _updateLoading(double dt) {
    _loadingTimer += dt;
    if (_loadingTimer >= _loadingDuration) {
      _loadingTimer = 0.0;
      _goToRoundSelect();
    }
  }

  void _updatePlaying(double dt) {
    if (size.x <= 0 || size.y <= 0) return;

    // 전역 게임 시간 업데이트
    gameTime += dt;

    // 라운드 타이머 업데이트
    roundTimer += dt;

    // 시간 제한 체크
    if (roundTimer >= roundTimeLimit) {
      _onTimeOver();
      return;
    }

    // D-3-5: 슬로우 모션 타이머 감소 (실제 시간 기준)
    if (_slowMotionTimer > 0) _slowMotionTimer = max(0.0, _slowMotionTimer - dt);
    // D-3-5: 슬로우 모션 중 몬스터/투사물 속도를 0.2배로 감소
    final double effectiveDt = _slowMotionTimer > 0 ? dt * 0.2 : dt;
    _updateMonsters(effectiveDt);
    _updateCharacterUnits(effectiveDt); // 캐릭터 유닛 업데이트
    _updateProjectiles(effectiveDt); // 투사물 업데이트
    _updateVfxEffects(dt); // VFX 이펙트 업데이트 (실제 시간 기준)
    _checkCharacterMonsterCollisions(); // 캐릭터-몬스터 충돌 체크
    _updatePriestHeal(dt); // 리디자인 B-2-3: 성직자 성 회복
    _updateMainCharacterDamage(dt); // 리디자인 B-2-6: 메인 캐릭터 피해
    // _updateMainCharacterRespawn(dt); // 복활 시스템 삭제: 사망 시 즉시 게임 오버
    _updateXpGems(dt); // 리디자인 B-2-8/B-2-9: XP 젬 업데이트 & 회수
    _updateGoldDrops(); // 리디자인 B-2-15: 골드 드롭 회수
    // #34: 부유 데미지 숫자 업데이트
    for (final dn in _damageNumbers) { dn.timer += dt; }
    _damageNumbers.removeWhere((dn) => dn.isExpired);
    // D-3-1: 성 피격 점멸 타이머 감소
    if (castleFlashTimer > 0) castleFlashTimer -= dt;
    // 리디자인 B-2-20: 성 바리어 타이머 업데이트
    if (_castleBarrierActive) {
      _castleBarrierTimer -= dt;
      if (_castleBarrierTimer <= 0) {
        _castleBarrierActive = false;
        _castleBarrierTimer = 0.0;
      }
    }
    // 증강 시스템: 타이머 업데이트
    if (_augmentR04Timer > 0) {
      _augmentR04Timer -= dt;
      if (_augmentR04Timer <= 0) { _augmentR04Timer = 0.0; _augmentR04Stacks = 0; }
    }
    if (_augmentL02Active) {
      _augmentL02Timer -= dt;
      if (_augmentL02Timer <= 0) _augmentL02Active = false;
    }
    if (_augmentL03BarrierActive) {
      _augmentL03BarrierTimer -= dt;
      if (_augmentL03BarrierTimer <= 0) _augmentL03BarrierActive = false;
    }
    // 캐릭터 슬롯 스킬 쿨다운 업데이트
    for (final slot in characterSlots) {
      if (slot.skillCooldownRemaining > 0) {
        slot.skillCooldownRemaining -= dt;
        if (slot.skillCooldownRemaining <= 0) {
          slot.skillCooldownRemaining = 0;
          slot.skillReady = true;
        }
      }
    }

    // 현재 라운드의 몬스터 스폰
    if (spawnedMonsters < totalMonstersInRound) {
      spawnTimer += dt;
      final cfg = kStageConfigs[stageLevel];
      if (cfg != null && currentRound <= cfg.rounds.length) {
        final roundCfg = cfg.rounds[currentRound - 1];
        if (spawnTimer >= roundCfg.spawnInterval) {
          spawnTimer = 0.0;
          // 리디자인 B-2-19: 동시 상한 40체 체크
          if (monsters.length < 40) {
            _spawnMonster();
          }
        }
      }
    }

    // 성 HP가 0이면 게임오버
    if (castleHp <= 0 && gameState == GameState.playing) {
      _onGameOver();
      return;
    }

    // 라운드 클리어 체크: 모든 몬스터가 처리되었고 화면에 몬스터가 없을 때
    // (처치된 몬스터 + 성에 도달한 몬스터 = 전체 몬스터)
    if ((defeatedMonsters + escapedMonsters) >= totalMonstersInRound && monsters.isEmpty) {
      _onRoundClear();
    }
  }

  void _updateRoundClear(double dt) {
    _roundClearTimer += dt;
    // L-04: 시간의 가속 - 인터벌 중 XP 자석 상시 발동
    if (_hasAugment('L-04')) _attractAllXpGems();
    if (_roundClearTimer >= _roundClearDuration) {
      _roundClearTimer = 0.0;
      // 증강 시스템: 라운드 2/4/5 클리어 후 증강 선택 화면
      if (currentRound == 2 || currentRound == 4 || currentRound == 5) {
        _triggerAugmentSelection();
        if (gameState == GameState.augmentSelect) return; // 증강 선택 대기
      }
      // C-11 증강: 라운드 시작 시 성 HP +5
      if (_hasAugment('C-11')) {
        castleHp = min(castleMaxHp, castleHp + 5);
      }
      _startNextRound();
    }
  }


  // -----------------------------
  // 입력 처리 (탭)
  // -----------------------------
  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.localPosition;

    switch (gameState) {
      case GameState.loading:
        // 로딩 상태에서는 탭 무시 (자동 진행)
        break;
      case GameState.roundSelect:
        _handleTapInRoundSelect(pos);
        break;
      case GameState.playing:
        _handleTapInPlaying(pos);
        break;
      case GameState.paused:
        _handleTapInPaused(pos);
        break;
      case GameState.levelUp:
        _handleTapInLevelUp(pos);
        break;
      case GameState.shopOpen:
        _handleTapInShop(pos);
        break;
      case GameState.augmentSelect:
        _handleTapInAugmentSelect(pos);
        break;
      case GameState.roundClear:
        // 라운드 클리어 중에는 탭 무시 (자동 진행)
        break;
      case GameState.result:
        _handleTapInResult(pos);
        break;
    }

    super.onTapDown(event);
  }

  @override
  void onDragStart(DragStartEvent event) {
    final pos = Offset(event.localPosition.x, event.localPosition.y);

    // 리디자인 B-2-4: 플레이 중 스틱 입력 (Designerの固定位置型に合わせる: 左下 80, size.y-110)
    if (gameState == GameState.playing) {
      _stickActive = true;
      _stickBasePos = Vector2(80.0, size.y - 110.0);
      _stickKnobPos = _stickBasePos.clone();
      super.onDragStart(event);
      return;
    }

    // 파티 팝업에서 드래그 시작
    if (gameState == GameState.roundSelect && showPartySelectionPopup) {
      const double popupWidth = 350.0;
      const double popupHeight = 500.0;
      final double popupX = (size.x - popupWidth) / 2;
      final double popupY = (size.y - popupHeight) / 2;
      const double listStartY = 60.0;
      const double bottomButtonHeight = 50.0;
      const double listHeight = popupHeight - listStartY - bottomButtonHeight - 10;

      final listRect = Rect.fromLTWH(
        popupX + 15,
        popupY + listStartY,
        popupWidth - 30,
        listHeight,
      );

      if (listRect.contains(pos)) {
        _partyPopupDragStartY = pos.dy;
      }
    }
    // 캐릭터 도감 영역에서 드래그 시작
    else if (gameState == GameState.roundSelect &&
        currentBottomMenu == BottomMenu.gacha &&
        gachaResults == null) {
      const double collectionStartY = 165.0;
      const double listStartY = collectionStartY + 50;
      const double availableHeight = 600.0 - collectionStartY - 70 - 20;

      if (pos.dy >= listStartY && pos.dy <= listStartY + availableHeight) {
        _dragStartY = pos.dy;
      }
    }
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final delta = event.localDelta;

    // 리디자인 B-2-4: 플레이 중 스틱 노브 업데이트
    if (gameState == GameState.playing && _stickActive) {
      final newKnob = Vector2(
        _stickKnobPos.x + delta.x,
        _stickKnobPos.y + delta.y,
      );
      final dx = newKnob.x - _stickBasePos.x;
      final dy = newKnob.y - _stickBasePos.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist <= _stickOuterRadius) {
        _stickKnobPos = newKnob;
      } else {
        // 외부 반경에서 클램프
        _stickKnobPos = Vector2(
          _stickBasePos.x + (dx / dist) * _stickOuterRadius,
          _stickBasePos.y + (dy / dist) * _stickOuterRadius,
        );
      }
      super.onDragUpdate(event);
      return;
    }

    // 파티 팝업 스크롤
    if (gameState == GameState.roundSelect &&
        showPartySelectionPopup &&
        _partyPopupDragStartY > 0) {
      const double cardHeight = 80.0;
      const double cardSpacing = 10.0;
      const int cardsPerRow = 4;
      const double listStartY = 60.0;
      const double bottomButtonHeight = 50.0;
      const double popupHeight = 500.0;
      final double listHeight = popupHeight - listStartY - bottomButtonHeight - 10;

      // 고유 캐릭터 개수 계산 (중복 제거)
      final uniqueCharacterIds = <String>{};
      for (final character in ownedCharacters) {
        uniqueCharacterIds.add(character.characterId);
      }
      final uniqueCount = uniqueCharacterIds.length;

      final totalRows = (uniqueCount / cardsPerRow).ceil();
      final contentHeight = totalRows * (cardHeight + cardSpacing) + 20;
      final maxScroll = (contentHeight - listHeight).clamp(0.0, double.infinity);

      partyPopupScrollOffset =
          (partyPopupScrollOffset - delta.y).clamp(0.0, maxScroll);
    }
    // 캐릭터 도감 스크롤
    else if (gameState == GameState.roundSelect &&
        currentBottomMenu == BottomMenu.gacha &&
        gachaResults == null &&
        _dragStartY > 0) {
      // 최대 스크롤 계산
      const double cardHeight = 80.0;
      const double cardSpacing = 10.0;
      const int cardsPerRow = 5;
      const double availableHeight = 600.0 - 165.0 - 70 - 20 - 50;

      final allCharacters = CharacterDefinitions.all;
      final totalRows = (allCharacters.length / cardsPerRow).ceil();
      final maxScroll =
          (totalRows * (cardHeight + cardSpacing) - availableHeight + 20)
              .clamp(0.0, double.infinity);

      characterListScrollOffset =
          (characterListScrollOffset - delta.y).clamp(0.0, maxScroll);
    }
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    // 리디자인 B-2-4: 스틱 비활성화
    if (_stickActive) {
      _stickActive = false;
      _stickKnobPos = _stickBasePos.clone();
    }
    _dragStartY = 0.0;
    _partyPopupDragStartY = 0.0;
    super.onDragEnd(event);
  }

  // 라운드 선택 화면: 맵 위 라운드 노드 터치
  void _handleTapInRoundSelect(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);
    const int totalRounds = 10;
    final unlocked = unlockedRoundMax.clamp(1, totalRounds);

    // 파티 선택 팝업이 열려있는 경우
    if (showPartySelectionPopup) {
      _handlePartyPopupTap(offset);
      return;
    }

    // 홈 메뉴에서 파티 슬롯 체크
    if (currentBottomMenu == BottomMenu.home) {
      if (_handlePartySlotTap(offset)) {
        return;
      }
    }

    // 하단 메뉴 버튼 체크
    for (int i = 0; i < 5; i++) {
      final rect = _bottomMenuButtonRect(i);
      if (rect.contains(offset)) {
        _handleBottomMenuTap(i);
        return;
      }
    }

    // 뽑기 메뉴에서의 클릭 처리
    if (currentBottomMenu == BottomMenu.gacha) {
      _handleGachaTap(offset);
      return;
    }

    // God Mode 버튼 체크
    final godModeRect = _godModeButtonRect();
    if (godModeRect.contains(offset)) {
      _toggleGodMode();
      return;
    }

    // 왼쪽 스테이지 변경 버튼 체크
    final leftStageButtonRect = _leftStageButtonRect();
    if (leftStageButtonRect.contains(offset)) {
      if (selectedStageInUI > 1) {
        selectedStageInUI--;
      }
      return;
    }

    // 오른쪽 스테이지 변경 버튼 체크
    final rightStageButtonRect = _rightStageButtonRect();
    if (rightStageButtonRect.contains(offset)) {
      if (selectedStageInUI < 8) {
        selectedStageInUI++;
      }
      return;
    }

    for (int i = 1; i <= totalRounds; i++) {
      final rect = _roundNodeRect(i);
      if (rect.contains(offset)) {
        if (i <= unlocked) {
          _startRound(i);
        }
        break;
      }
    }
  }

  // 파티 슬롯 클릭 처리
  bool _handlePartySlotTap(Offset offset) {
    const double bottomMenuHeight = 70.0;
    const double slotSize = 60.0; // 도감과 동일한 크기
    const double slotSpacing = 10.0; // 도감과 동일한 간격
    final double slotY = size.y - bottomMenuHeight - slotSize - 8.0; // 푸터 바로 위

    // 4슬롯 (정사각형 포메이션) 탭 처리
    for (int i = 0; i < 4; i++) {
      final double slotX = (size.x - (slotSize * 4 + slotSpacing * 3)) / 2 + i * (slotSize + slotSpacing);
      final slotRect = Rect.fromLTWH(slotX, slotY, slotSize, slotSize);

      if (slotRect.contains(offset)) {
        // 슬롯을 클릭하면 팝업 열기
        selectedPartySlotIndex = i;
        showPartySelectionPopup = true;
        return true;
      }
    }
    return false;
  }

  // 파티 팝업 클릭 처리 (그리드 레이아웃)
  void _handlePartyPopupTap(Offset offset) {
    const double popupWidth = 350.0;
    const double popupHeight = 500.0;
    final double popupX = (size.x - popupWidth) / 2;
    final double popupY = (size.y - popupHeight) / 2;

    // 닫기 버튼 체크
    final closeButtonRect = Rect.fromLTWH(popupX + popupWidth - 40, popupY + 10, 30, 30);
    if (closeButtonRect.contains(offset)) {
      showPartySelectionPopup = false;
      selectedPartySlotIndex = -1;
      partyPopupScrollOffset = 0.0;
      return;
    }

    // 제거 버튼 체크 (슬롯에 캐릭터가 있는 경우)
    if (selectedPartySlotIndex >= 0 && partySlots[selectedPartySlotIndex] != null) {
      final removeButtonRect = Rect.fromLTWH(
        popupX + 20,
        popupY + popupHeight - 45,
        popupWidth - 40,
        35,
      );

      if (removeButtonRect.contains(offset)) {
        // 파티에서 제거
        partySlots[selectedPartySlotIndex] = null;
        showPartySelectionPopup = false;
        selectedPartySlotIndex = -1;
        partyPopupScrollOffset = 0.0;
        return;
      }
    }

    // 캐릭터 카드 클릭 체크 (그리드) - 중복 제거된 목록
    const double listStartY = 60.0;
    const double cardWidth = 60.0;
    const double cardHeight = 80.0;
    const double cardSpacing = 10.0;
    const int cardsPerRow = 4;

    // 캐릭터별 개수 계산 및 중복 제거
    final characterMap = <String, List<OwnedCharacter>>{};
    for (final character in ownedCharacters) {
      if (!characterMap.containsKey(character.characterId)) {
        characterMap[character.characterId] = [];
      }
      characterMap[character.characterId]!.add(character);
    }

    final uniqueCharacterIds = characterMap.keys.toList();
    for (int i = 0; i < uniqueCharacterIds.length; i++) {
      final characterId = uniqueCharacterIds[i];
      final characterInstances = characterMap[characterId]!;

      final row = i ~/ cardsPerRow;
      final col = i % cardsPerRow;

      final double x = popupX + 20 + col * (cardWidth + cardSpacing);
      final double y = popupY + listStartY + 10 + row * (cardHeight + cardSpacing) - partyPopupScrollOffset;

      final cardRect = Rect.fromLTWH(x, y, cardWidth, cardHeight);

      if (cardRect.contains(offset)) {
        // 이 캐릭터의 인스턴스 중 파티에 없는 것을 찾기
        OwnedCharacter? characterToAdd;
        bool hasInParty = false;

        for (final instance in characterInstances) {
          if (partySlots.contains(instance.instanceId)) {
            hasInParty = true;
            // 이미 파티에 있는 인스턴스를 클릭한 경우 - 슬롯 교체
            final oldIndex = partySlots.indexOf(instance.instanceId);
            if (oldIndex >= 0 && oldIndex != selectedPartySlotIndex) {
              // 슬롯 교체
              final temp = partySlots[selectedPartySlotIndex];
              partySlots[selectedPartySlotIndex] = instance.instanceId;
              partySlots[oldIndex] = temp;
            }
            break;
          } else if (characterToAdd == null) {
            characterToAdd = instance;
          }
        }

        // 파티에 없는 인스턴스가 있으면 추가
        if (!hasInParty && characterToAdd != null) {
          partySlots[selectedPartySlotIndex] = characterToAdd.instanceId;
        }

        showPartySelectionPopup = false;
        selectedPartySlotIndex = -1;
        partyPopupScrollOffset = 0.0;
        return;
      }
    }

    // 팝업 바깥 클릭 시 닫기
    final popupRect = Rect.fromLTWH(popupX, popupY, popupWidth, popupHeight);
    if (!popupRect.contains(offset)) {
      showPartySelectionPopup = false;
      selectedPartySlotIndex = -1;
      partyPopupScrollOffset = 0.0;
    }
  }

  // 하단 메뉴 탭 처리
  void _handleBottomMenuTap(int index) {
    switch (index) {
      case 0: // 상점
        currentBottomMenu = BottomMenu.shop;
        break;
      case 1: // 인벤토리
        currentBottomMenu = BottomMenu.inventory;
        break;
      case 2: // 홈
        currentBottomMenu = BottomMenu.home;
        break;
      case 3: // 뽑기
        currentBottomMenu = BottomMenu.gacha;
        break;
      case 4: // 설정
        currentBottomMenu = BottomMenu.settings;
        break;
    }
  }

  // 뽑기 화면 탭 처리
  void _handleGachaTap(Offset offset) {
    // 뽑기 결과 표시 중이면 다음 캐릭터로 진행
    if (gachaResults != null && gachaResults!.isNotEmpty) {
      gachaResultIndex++;
      if (gachaResultIndex >= gachaResults!.length) {
        // 모든 결과를 확인했으면 인벤토리에 추가하고 초기화
        for (final character in gachaResults!) {
          final instanceId = '${character.id}_${DateTime.now().millisecondsSinceEpoch}';
          ownedCharacters.add(OwnedCharacter(
            instanceId: instanceId,
            characterId: character.id,
          ));
        }
        gachaResults = null;
        gachaResultIndex = 0;
      }
      return;
    }

    // 단일 뽑기 버튼 체크
    final singleButtonRect = _gachaSingleButtonRect();
    if (singleButtonRect.contains(offset)) {
      final cost = gachaSystem.getSingleSummonCost();
      if (playerGem >= cost) {
        playerGem -= cost;
        final result = gachaSystem.summonOne();
        gachaResults = [result];
        gachaResultIndex = 0;
      }
      return;
    }

    // 10연차 뽑기 버튼 체크
    final tenButtonRect = _gachaTenButtonRect();
    if (tenButtonRect.contains(offset)) {
      final cost = gachaSystem.getTenSummonCost();
      if (playerGem >= cost) {
        playerGem -= cost;
        final results = gachaSystem.summonTen();
        gachaResults = results;
        gachaResultIndex = 0;
      }
      return;
    }
  }

  // 특정 라운드부터 시작
  void _startRound(int roundNumber) {
    _loadStage(selectedStageInUI); // 선택된 스테이지 로드
    _loadRound(roundNumber);
    _applyPartyToCharacterSlots(); // 파티 설정 반영
    _spawnCharacterUnits(); // 캐릭터 유닛 생성
    gameState = GameState.playing;
  }

  // 파티 슬롯에서 캐릭터 유닛을 생성 (4인 정사각형 포메이션)
  void _spawnCharacterUnits() {
    characterUnits.clear(); // 기존 유닛 제거

    // 4인 정사각형 포메이션 오프셋 (메인 캐릭터 기준 상대 위치)
    const formationOffsets = [
      [-20.0, -20.0], // 왼쪽 위
      [ 20.0, -20.0], // 오른쪽 위
      [-20.0,  20.0], // 왼쪽 아래
      [ 20.0,  20.0], // 오른쪽 아래
    ];

    for (int i = 0; i < 4; i++) {
      final instanceId = partySlots[i];
      if (instanceId != null) {
        final character = ownedCharacters.firstWhere(
          (c) => c.instanceId == instanceId,
          orElse: () => OwnedCharacter(instanceId: '', characterId: ''),
        );

        if (character.characterId.isNotEmpty) {
          final definition = CharacterDefinitions.byId(character.characterId);
          final maxHp = definition.baseStats.maxHp * (1 + character.level * 0.1);

          // 모든 파티원이 함께 이동 (타워 고정 없음)
          final offset = formationOffsets[i];
          final spawnPos = Vector2(
            castleCenterX + offset[0],
            castleCenterY - castleHeight - 40 + offset[1],
          );

          final unit = _CharacterUnit(
            instanceId: instanceId,
            definition: definition,
            level: character.level,
            pos: spawnPos,
            currentHp: maxHp,
            maxHp: maxHp,
            isTower: false, // 모두 메인캐릭터처럼 이동
            towerFixedPos: null, // 고정 위치 없음
          );

          characterUnits.add(unit);
        }
      }
    }
  }

  // 파티 슬롯 설정을 게임 캐릭터 슬롯에 반영
  void _applyPartyToCharacterSlots() {
    // 4슬롯 (정사각형 포메이션)
    for (int i = 0; i < 4; i++) {
      if (i >= characterSlots.length) break;

      final instanceId = partySlots[i];
      if (instanceId != null) {
        // 파티에 캐릭터가 설정되어 있음
        final character = ownedCharacters.firstWhere(
          (c) => c.instanceId == instanceId,
          orElse: () => ownedCharacters.isNotEmpty ? ownedCharacters.first : OwnedCharacter(instanceId: '', characterId: ''),
        );

        if (character.characterId.isNotEmpty) {
          final definition = CharacterDefinitions.byId(character.characterId);
          characterSlots[i].hasCharacter = true;
          characterSlots[i].characterName = definition.name;
          characterSlots[i].skillReady = true;
        } else {
          // 캐릭터를 찾지 못한 경우
          characterSlots[i].hasCharacter = false;
          characterSlots[i].characterName = '';
          characterSlots[i].skillReady = false;
        }
      } else {
        // 파티에 캐릭터가 설정되지 않음
        characterSlots[i].hasCharacter = false;
        characterSlots[i].characterName = '';
        characterSlots[i].skillReady = false;
      }
    }
  }

  // 플레이 중: 몬스터 공격 또는 일시정지 버튼 또는 캐릭터 스킬
  void _handleTapInPlaying(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);

    // 일시정지 버튼 체크 (우측 상단)
    final pauseButtonRect = _pauseButtonRect();
    if (pauseButtonRect.contains(offset)) {
      gameState = GameState.paused;
      return;
    }

    // 리디자인 B-2-14: 스킬 버튼 체크 (우측 하단 80px 원형)
    if (skillReady) {
      final skillBtnCenter = Offset(size.x - 60, size.y - 110);
      final dist = (tapPos - Vector2(skillBtnCenter.dx, skillBtnCenter.dy)).length;
      if (dist <= 40.0) {
        _fireUltimateSkill();
        return;
      }
    }

    // 캐릭터 슬롯 체크 (스킬 사용)
    for (int i = 0; i < characterSlots.length; i++) {
      final slotRect = _characterSlotRect(i);
      if (slotRect.contains(offset)) {
        _handleCharacterSlotTap(i);
        return;
      }
    }

    // 몬스터 공격
    for (var i = 0; i < monsters.length; i++) {
      final m = monsters[i];
      if (_isPointInsideMonster(m, tapPos)) {
        m.hp = max(0, m.hp - weaponDamage);
        if (m.hp <= 0) {
          _killMonsterAtIndex(i);
        }
        break;
      }
    }
  }

  // 캐릭터 슬롯 클릭 처리 (스킬 사용)
  void _handleCharacterSlotTap(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= characterSlots.length) return;

    final slot = characterSlots[slotIndex];

    // 캐릭터가 있고 스킬이 준비된 경우에만 스킬 사용
    if (slot.hasCharacter && slot.skillReady) {
      _useCharacterSkill(slotIndex);
    }
  }

  // 캐릭터 스킬 사용 (프로토타입: 화면의 모든 몬스터에게 데미지)
  void _useCharacterSkill(int slotIndex) {
    final slot = characterSlots[slotIndex];

    // 스킬 효과: 모든 몬스터에게 3 데미지
    const int skillDamage = 3;

    for (var i = monsters.length - 1; i >= 0; i--) {
      final m = monsters[i];
      m.hp = max(0, m.hp - skillDamage);
      if (m.hp <= 0) {
        _killMonsterAtIndex(i);
      }
    }

    // 스킬 사용 후 쿨다운 세팅 (update 루프에서 dt 기반 감소)
    slot.skillReady = false;
    slot.skillCooldownRemaining = 5.0;
  }

  // 일시정지 화면: "재개 / 라운드 선택 / 재시작"
  // 리디자인 B-2-16: 상점 화면 탭 처리
  // 상점 UI 버튼 위치는 Designer(D-2-2) 구현과 맞춰야 함
  // 임시: 화면 하단 "계속" 영역을 탭하면 상점 종료
  // 증강 선택 화면 탭 처리 - 화면 1/3 영역 분할
  void _handleTapInAugmentSelect(Vector2 tapPos) {
    if (_augmentOptions.isEmpty) {
      // 선택지 없으면 게임 재개
      if (_hasAugment('C-11')) castleHp = min(castleMaxHp, castleHp + 5);
      _startNextRound();
      return;
    }
    final double cardW = size.x / 3;
    final int idx = (tapPos.x / cardW).floor().clamp(0, _augmentOptions.length - 1);
    _applyAugment(_augmentOptions[idx]);
    // 증강 선택 후 라운드 시작
    if (_hasAugment('C-11')) castleHp = min(castleMaxHp, castleHp + 5);
    _startNextRound();
  }

  void _handleTapInShop(Vector2 tapPos) {
    // 계속 버튼 (y > 0.80) 탭 = 상점 나가기
    if (tapPos.y > size.y * 0.8) {
      _leaveShop();
      return;
    }
    // 상점 아이템 탭 영역 (_renderShopOverlay 카드 위치와 동기화)
    // centerYs = [0.40, 0.575, 0.725], cardH = 70
    const double cardH = 70.0;
    final List<double> centerYs = [size.y * 0.40, size.y * 0.575, size.y * 0.725];
    const List<ShopItemType> items = [
      ShopItemType.castleMaxHpUp,
      ShopItemType.towerPowerUp,
      ShopItemType.mainCharHpUp,
    ];
    for (int i = 0; i < 3; i++) {
      if (tapPos.y >= centerYs[i] - cardH / 2 &&
          tapPos.y < centerYs[i] + cardH / 2 &&
          tapPos.x >= 20 && tapPos.x <= size.x - 20) {
        _buyShopItem(items[i]);
        return;
      }
    }
  }

  // 리디자인 B-2-11: 레벨업 화면 탭 처리 - 바프 카드 선택
  // 카드 좌표는 _renderLevelUpUI 와 동기화
  void _handleTapInLevelUp(Vector2 tapPos) {
    if (_buffOptions.isEmpty) return;
    const double cardW = 100.0;
    const double cardH = 150.0;
    const double cardGap = 10.0;
    final double totalW = 3 * cardW + 2 * cardGap;
    final double startX = (size.x - totalW) / 2;
    final double cardY = size.y * 0.30;

    for (int i = 0; i < _buffOptions.length && i < 3; i++) {
      final double cx = startX + i * (cardW + cardGap);
      final cardRect = Rect.fromLTWH(cx, cardY, cardW, cardH);
      if (cardRect.contains(Offset(tapPos.x, tapPos.y))) {
        _applyBuff(_buffOptions[i]);
        return;
      }
    }
  }

  void _handleTapInPaused(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);

    final resumeRect = _pauseResumeButtonRect();
    final roundSelectRect = _pauseRoundSelectButtonRect();
    final retryRect = _pauseRetryButtonRect();

    if (resumeRect.contains(offset)) {
      gameState = GameState.playing;
      return;
    }

    if (roundSelectRect.contains(offset)) {
      _goToRoundSelect();
      return;
    }

    if (retryRect.contains(offset)) {
      _startRound(currentRound);
      return;
    }
  }

  // 결과 화면: "다시하기 / 라운드 선택 / 다음 라운드"
  void _handleTapInResult(Vector2 tapPos) {
    final offset = Offset(tapPos.x, tapPos.y);

    final retryRect = _resultRetryButtonRect();
    final roundSelectRect = _resultRoundSelectButtonRect();
    final nextRect = _resultNextRoundButtonRect();

    if (retryRect.contains(offset)) {
      _startRound(currentRound);
      return;
    }

    if (roundSelectRect.contains(offset)) {
      _goToRoundSelect();
      return;
    }

    final nextRound = currentRound + 1;
    final canGoNext = _lastStageClear && nextRound <= totalRoundsInStage;

    if (canGoNext && nextRect.contains(offset)) {
      if (nextRound > unlockedRoundMax) {
        unlockedRoundMax = nextRound;
      }
      _startRound(nextRound);
    }
  }

  // -----------------------------
  // 버튼 Rect (일시정지 버튼)
  // -----------------------------
  Rect _pauseButtonRect() {
    const double buttonSize = 35.0; // 작은 버튼
    const double marginTop = 15.0;
    const double marginSide = 20.0;

    // 스테이지-라운드 표시 오른쪽에 배치
    // 스테이지-라운드는 (size.x - marginSide - 30)에 위치하므로 그 오른쪽에 배치
    final double x = this.size.x - marginSide - 10;
    final double y = marginTop - (buttonSize / 2); // 중앙 정렬

    return Rect.fromLTWH(x, y, buttonSize, buttonSize);
  }

  // -----------------------------
  // 캐릭터 슬롯 Rect
  // -----------------------------
  Rect _characterSlotRect(int slotIndex) {
    const double slotSize = 50.0;
    const double slotSpacing = 10.0;
    const double slotPadding = 10.0;

    const totalWidth = (slotSize * 4) + (slotSpacing * 3);
    final startX = (size.x - totalWidth) / 2;
    final slotY = _castleRect.top + slotPadding;

    final x = startX + (slotIndex * (slotSize + slotSpacing));
    return Rect.fromLTWH(x, slotY, slotSize, slotSize);
  }

  // -----------------------------
  // 버튼 Rect (일시정지 화면)
  // -----------------------------
  Rect _pauseResumeButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.50;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _pauseRoundSelectButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.50 + 52;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _pauseRetryButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.50 + 52 * 2;
    return Rect.fromLTWH(x, y, width, height);
  }

  // -----------------------------
  // 버튼 Rect (결과 화면)
  // -----------------------------
  Rect _resultRetryButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.55;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _resultRoundSelectButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.55 + 52;
    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _resultNextRoundButtonRect() {
    const double width = 180;
    const double height = 40;
    final double x = (size.x - width) / 2;
    final double y = size.y * 0.55 + 52 * 2;
    return Rect.fromLTWH(x, y, width, height);
  }

  // -----------------------------
  // 캔디크러쉬 사가 스타일: 사각형 타일 배치 (2열)
  // -----------------------------
  Offset _roundNodeCenter(int roundIndex) {
    const double topMargin = 140.0; // 네비게이션 바(60) + 타이틀 박스(50) + 여백(30)
    const double tileSize = 70.0; // 타일 크기
    const double horizontalSpacing = 15.0; // 좌우 간격
    const double verticalSpacing = 15.0; // 상하 간격

    final double centerX = size.x / 2;

    // 보스 라운드(10)는 맨 밑 중앙에 배치
    if (roundIndex == 10) {
      final double y = topMargin + (3 * (tileSize + verticalSpacing)) + tileSize / 2;
      return Offset(centerX, y);
    }

    // 1-9 라운드: 3열 배치 (3x3 그리드)
    final int row = (roundIndex - 1) ~/ 3; // 0, 1, 2 행
    final int col = (roundIndex - 1) % 3; // 0, 1, 2 열

    // 3개 타일의 전체 너비 계산
    final double totalWidth = (tileSize * 3) + (horizontalSpacing * 2);
    final double startX = centerX - totalWidth / 2 + tileSize / 2;

    final double x = startX + (col * (tileSize + horizontalSpacing));
    final double y = topMargin + (row * (tileSize + verticalSpacing)) + tileSize / 2;

    return Offset(x, y);
  }

  Rect _roundNodeRect(int roundIndex) {
    final center = _roundNodeCenter(roundIndex);
    const double tileSize = 70.0;
    return Rect.fromCenter(center: center, width: tileSize, height: tileSize);
  }

  // God Mode 버튼 Rect (우측 하단, 메뉴 바로 위)
  Rect _godModeButtonRect() {
    const double width = 70;
    const double height = 30;
    final double x = size.x - width - 10;
    // 파티 슬롯과 겹치지 않도록 더 위로 올림
    final double y = size.y - _bottomMenuHeight - height - 85; // 85px 여유 (파티 슬롯 높이 + 여유 공간)
    return Rect.fromLTWH(x, y, width, height);
  }

  // 왼쪽 스테이지 변경 버튼 Rect
  Rect _leftStageButtonRect() {
    const double width = 35.0;
    const double height = 35.0;
    const double x = 15.0;
    const double navBarHeight = 60.0;
    const double titleBoxHeight = 50.0;
    final double y = navBarHeight + (titleBoxHeight - height) / 2; // 타이틀 박스 중앙
    return Rect.fromLTWH(x, y, width, height);
  }

  // 오른쪽 스테이지 변경 버튼 Rect
  Rect _rightStageButtonRect() {
    const double width = 35.0;
    const double height = 35.0;
    final double x = size.x - width - 15;
    const double navBarHeight = 60.0;
    const double titleBoxHeight = 50.0;
    final double y = navBarHeight + (titleBoxHeight - height) / 2; // 타이틀 박스 중앙
    return Rect.fromLTWH(x, y, width, height);
  }

  // God Mode 토글 함수
  void _toggleGodMode() {
    _godModeEnabled = !_godModeEnabled;

    if (_godModeEnabled) {
      // 모든 라운드 언락
      unlockedRoundMax = 10;

      // 모든 캐릭터 슬롯 활성화 및 스킬 준비 완료
      for (var slot in characterSlots) {
        slot.hasCharacter = true;
        slot.skillReady = true;
      }

      // 무한 리소스
      playerGold = 999999;
      playerGem = 999999;
      playerEnergy = playerMaxEnergy;
    }
    // God Mode를 끄면 원래 상태로 돌아가는 것은 구현하지 않음
    // (테스트 목적이므로 한번 켜면 계속 유지)
  }

  // -----------------------------
  // 하단 메뉴 버튼 Rect
  // -----------------------------
  static const double _bottomMenuHeight = 70.0;

  Rect _bottomMenuButtonRect(int index) {
    const int totalButtons = 5;
    final buttonWidth = size.x / totalButtons;
    final x = index * buttonWidth;
    final y = size.y - _bottomMenuHeight;
    return Rect.fromLTWH(x, y, buttonWidth, _bottomMenuHeight);
  }

  // -----------------------------
  // 렌더링
  // -----------------------------
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) return;

    // 라운드 선택 맵: 게임 플레이 화면 없이 흰 배경 + 맵만
    if (gameState == GameState.roundSelect) {
      _renderRoundSelectBackground(canvas);
      _renderRoundSelectOverlay(canvas);
      return;
    }

    // 로딩 화면: 순수 검은 배경
    if (gameState == GameState.loading) {
      _renderLoadingScreen(canvas);
      return;
    }

    // 나머지(플레이, 일시정지, 결과)는 게임 배경 + 성/몬스터 + 오버레이
    _renderBackground(canvas);
    _renderCastle(canvas);
    _renderCharacterUnits(canvas); // 캐릭터 유닛 렌더링
    _renderProjectiles(canvas); // 투사물 렌더링
    _renderVfxEffects(canvas); // VFX 이펙트 렌더링
    _renderMonsters(canvas);
    _renderXpGems(canvas);          // D-3-2: XP 젬
    _renderXpMagnetEffect(canvas);  // D-3-4: XP 마그넷 연출
    _renderGoldDrops(canvas);       // D-3-3: 골드 코인
    _renderDamageNumbers(canvas);   // #34: 속성 데미지 숫자
    // D-01: _renderStageProgress 제거 — HUD Row2와 정보 중복 (P-04)
    // _renderStageProgress(canvas);
    // D-02: _renderWeaponInfo 제거 — 디버그 정보, 스틱/스킬 영역과 겹침 (P-06)
    // _renderWeaponInfo(canvas);
    _renderHUD(canvas); // D-1-1: 상단 HUD

    // 플레이/라운드 클리어 중 하단 UI (스틱, 스킬, 골드) 표시
    if (gameState == GameState.playing || gameState == GameState.roundClear) {
      if (gameState == GameState.playing) {
        _renderPauseButton(canvas);
        _renderVirtualStick(canvas); // D-1-3: 버추얼 스틱 UI
      }
      _renderGoldDisplay(canvas);  // D-1-5: 골드 표시 UI
      _renderSkillButton(canvas);  // D-1-4: 스킬 버튼 UI
    }

    // D-2-4: 복활 카운트다운 오버레이 (복활 시스템 삭제됨)
    // if (_mainCharRespawning && _respawnTimer > 0) {
    //   _renderReviveCountdown(canvas, _respawnTimer);
    // }

    // 리디자인 B-2-11: 레벨업 화면 오버레이 (Designer D-2-1 담당)
    if (gameState == GameState.levelUp && _buffOptions.isNotEmpty) {
      _renderLevelUpUI(canvas);
    }

    _renderGameStateOverlay(canvas);
  }
}
