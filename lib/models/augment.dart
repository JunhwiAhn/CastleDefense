// 증강 시스템 (augment-system.md 참조)
part of '../castle_defense_game.dart';

enum AugmentTier { common, rare, legendary }
enum AugmentCategory { main, tower, castle, utility, economy, elemental, special, synergy }

class Augment {
  final String id;
  final String nameJp;
  final AugmentTier tier;
  final AugmentCategory category;
  final String description;
  final bool carryOverToNextStage;

  const Augment({
    required this.id,
    required this.nameJp,
    required this.tier,
    required this.category,
    required this.description,
    this.carryOverToNextStage = false,
  });
}

// 전체 34종 증강 정의
const List<Augment> kAllAugments = [
  // === Common (14종) ===
  Augment(id:'C-01', nameJp:'鋼の意志', tier:AugmentTier.common, category:AugmentCategory.main, description:'メイン最大HP +15'),
  Augment(id:'C-02', nameJp:'迅速の加護', tier:AugmentTier.common, category:AugmentCategory.main, description:'メイン移動速度 +25%'),
  Augment(id:'C-03', nameJp:'鋭利な刃', tier:AugmentTier.common, category:AugmentCategory.main, description:'メイン攻撃力 +20%'),
  Augment(id:'C-04', nameJp:'連射の才', tier:AugmentTier.common, category:AugmentCategory.main, description:'メイン攻撃速度 +20%'),
  Augment(id:'C-05', nameJp:'城壁修復', tier:AugmentTier.common, category:AugmentCategory.castle, description:'城最大HP +25 & 即時25回復'),
  Augment(id:'C-06', nameJp:'タワー油断', tier:AugmentTier.common, category:AugmentCategory.tower, description:'全タワー攻撃速度 +20%'),
  Augment(id:'C-07', nameJp:'巨大磁石', tier:AugmentTier.common, category:AugmentCategory.utility, description:'XP回収半径 +30px'),
  Augment(id:'C-08', nameJp:'速成復活', tier:AugmentTier.common, category:AugmentCategory.utility, description:'復活カウントダウン -2秒'),
  Augment(id:'C-09', nameJp:'金の手', tier:AugmentTier.common, category:AugmentCategory.economy, description:'ゴールド獲得量 +30%'),
  Augment(id:'C-10', nameJp:'余波', tier:AugmentTier.common, category:AugmentCategory.main, description:'メイン撃破時 周囲30pxスプラッシュ'),
  Augment(id:'C-11', nameJp:'守護の炎', tier:AugmentTier.common, category:AugmentCategory.castle, description:'ラウンド開始時 城HP +5回復'),
  Augment(id:'C-12', nameJp:'タワー補給', tier:AugmentTier.common, category:AugmentCategory.tower, description:'全タワー射程 +20%'),
  Augment(id:'C-13', nameJp:'疾風迅雷', tier:AugmentTier.common, category:AugmentCategory.utility, description:'復活無敵時間 +2秒'),
  Augment(id:'C-14', nameJp:'属性目覚め', tier:AugmentTier.common, category:AugmentCategory.elemental, description:'属性ダメージボーナス +10%'),
  // === Rare (12종) ===
  Augment(id:'R-01', nameJp:'連鎖弾', tier:AugmentTier.rare, category:AugmentCategory.main, description:'投射物着弾後 最寄りの敵に60%連鎖'),
  Augment(id:'R-02', nameJp:'吸血衝動', tier:AugmentTier.rare, category:AugmentCategory.main, description:'攻撃ダメージの20%をHPに吸収'),
  Augment(id:'R-03', nameJp:'爆発弾頭', tier:AugmentTier.rare, category:AugmentCategory.tower, description:'投射物着弾時 35px範囲50%スプラッシュ'),
  Augment(id:'R-04', nameJp:'城の怒り', tier:AugmentTier.rare, category:AugmentCategory.castle, description:'城被弾時 タワー攻撃力+15% (5秒,最大3重)'),
  Augment(id:'R-05', nameJp:'超集中砲火', tier:AugmentTier.rare, category:AugmentCategory.tower, description:'タワー集中攻撃時 ダメージ+30%'),
  Augment(id:'R-06', nameJp:'緊急発動', tier:AugmentTier.rare, category:AugmentCategory.special, description:'スキルゲージ蓄積量 +50%'),
  Augment(id:'R-07', nameJp:'元素爆発', tier:AugmentTier.rare, category:AugmentCategory.elemental, description:'通常攻撃に属性状態異常15%発動'),
  Augment(id:'R-08', nameJp:'鉄壁の城', tier:AugmentTier.rare, category:AugmentCategory.castle, description:'城接触ダメージ -30%'),
  Augment(id:'R-09', nameJp:'宝の山', tier:AugmentTier.rare, category:AugmentCategory.utility, description:'XPジェム/ゴールド消滅時間 +15秒'),
  Augment(id:'R-10', nameJp:'二段蓄積', tier:AugmentTier.rare, category:AugmentCategory.utility, description:'レベルアップ時 XP磁石2連続発動'),
  Augment(id:'R-11', nameJp:'タワー連携', tier:AugmentTier.rare, category:AugmentCategory.tower, description:'同一ターゲット2連続攻撃後 3回目自動クリティカル'),
  Augment(id:'R-12', nameJp:'不屈の城', tier:AugmentTier.rare, category:AugmentCategory.castle, description:'城HP50以下時 1回10秒バリア発動'),
  // === Legendary (8종) ===
  Augment(id:'L-01', nameJp:'不死の誓い', tier:AugmentTier.legendary, category:AugmentCategory.main, description:'HP0時 1回HP1生存+3秒無敵(ステージ1回)', carryOverToNextStage:true),
  Augment(id:'L-02', nameJp:'王の咆哮', tier:AugmentTier.legendary, category:AugmentCategory.special, description:'必殺技発動時 10秒間タワー攻撃力+60% 攻速+40%', carryOverToNextStage:true),
  Augment(id:'L-03', nameJp:'大地の守護者', tier:AugmentTier.legendary, category:AugmentCategory.castle, description:'城HP30%以下時 60秒バリア(城ダメージ50%減)1回'),
  Augment(id:'L-04', nameJp:'時の加速', tier:AugmentTier.legendary, category:AugmentCategory.utility, description:'ラウンドインターバル中 移動速度400%+XP磁石常時発動'),
  Augment(id:'L-05', nameJp:'元素の嵐', tier:AugmentTier.legendary, category:AugmentCategory.elemental, description:'3属性以上時 全攻撃にランダム属性状態異常30%'),
  Augment(id:'L-06', nameJp:'究極砲台', tier:AugmentTier.legendary, category:AugmentCategory.tower, description:'タワー投射物数+1(タワー1基ずつ順次適用)', carryOverToNextStage:true),
  Augment(id:'L-07', nameJp:'魂の連鎖', tier:AugmentTier.legendary, category:AugmentCategory.synergy, description:'メイン敵撃破時 全タワー次攻撃がクリティカル'),
  Augment(id:'L-08', nameJp:'永遠の契約', tier:AugmentTier.legendary, category:AugmentCategory.synergy, description:'同効果バフ2回以上取得時 +1スタック追加'),
];
