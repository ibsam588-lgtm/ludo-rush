import 'package:shared_preferences/shared_preferences.dart';
import '../data/economy.dart';
import 'soundtrack_service.dart';

class PrefsService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? get playerId => _prefs?.getString('player_id');
  set playerId(String? v) {
    if (v == null) {
      _prefs?.remove('player_id');
    } else {
      _prefs?.setString('player_id', v);
    }
  }

  String? get authToken => _prefs?.getString('auth_token');
  set authToken(String? v) {
    if (v == null || v.isEmpty) {
      _prefs?.remove('auth_token');
    } else {
      _prefs?.setString('auth_token', v);
    }
  }

  String get displayName => _prefs?.getString('display_name') ?? 'Ludo Player';
  set displayName(String v) => _prefs?.setString('display_name', v);

  String get countryCode => _prefs?.getString('country_code') ?? 'US';
  set countryCode(String v) => _prefs?.setString('country_code', v);

  int get avatarPreset => _prefs?.getInt('avatar_preset') ?? 0;
  set avatarPreset(int v) => _prefs?.setInt('avatar_preset', v);

  int get age => _prefs?.getInt('age') ?? 0;
  set age(int v) => _prefs?.setInt('age', v);

  String? get avatarImagePath => _prefs?.getString('avatar_image_path');
  set avatarImagePath(String? v) {
    if (v == null || v.isEmpty) {
      _prefs?.remove('avatar_image_path');
    } else {
      _prefs?.setString('avatar_image_path', v);
    }
  }

  int get coins => _prefs?.getInt('coins') ?? GameEconomy.startingCoins;
  set coins(int v) => _prefs?.setInt('coins', v);

  int get energy => _prefs?.getInt('energy') ?? GameEconomy.startingEnergy;
  set energy(int v) => _prefs?.setInt('energy', v);

  int get rating => _prefs?.getInt('rating') ?? 1000;
  set rating(int v) => _prefs?.setInt('rating', v);

  int get gamesPlayed => _prefs?.getInt('games_played') ?? 0;
  set gamesPlayed(int v) => _prefs?.setInt('games_played', v);

  int get wins => _prefs?.getInt('wins') ?? 0;
  set wins(int v) => _prefs?.setInt('wins', v);

  int get claimedGoldChests => _prefs?.getInt('claimed_gold_chests') ?? 0;
  set claimedGoldChests(int v) => _prefs?.setInt('claimed_gold_chests', v);

  bool get isDarkMode => _prefs?.getBool('dark_mode') ?? true;
  set isDarkMode(bool v) => _prefs?.setBool('dark_mode', v);

  String get matchDifficulty =>
      _prefs?.getString('match_difficulty') ?? 'medium';
  set matchDifficulty(String v) => _prefs?.setString('match_difficulty', v);

  String get snakesBoardTheme =>
      _prefs?.getString('snakes_board_theme') ?? 'carnival';
  set snakesBoardTheme(String v) => _prefs?.setString('snakes_board_theme', v);

  String get ludoBoardTheme =>
      _prefs?.getString('ludo_board_theme') ?? 'carnival';
  set ludoBoardTheme(String v) => _prefs?.setString('ludo_board_theme', v);

  String get diceSkin => _prefs?.getString('dice_skin') ?? 'classic';
  set diceSkin(String v) => _prefs?.setString('dice_skin', v);

  bool get autoRollEnabled => _prefs?.getBool('auto_roll_enabled') ?? false;
  set autoRollEnabled(bool v) => _prefs?.setBool('auto_roll_enabled', v);

  String get soundtrackId =>
      _prefs?.getString('soundtrack_id') ?? SoundtrackCatalog.defaultId;
  set soundtrackId(String v) => _prefs?.setString('soundtrack_id', v);

  bool get musicEnabled => _prefs?.getBool('music_enabled') ?? true;
  set musicEnabled(bool v) => _prefs?.setBool('music_enabled', v);

  bool get soundEffectsEnabled =>
      _prefs?.getBool('sound_effects_enabled') ?? true;
  set soundEffectsEnabled(bool v) =>
      _prefs?.setBool('sound_effects_enabled', v);

  bool get hapticsEnabled => _prefs?.getBool('haptics_enabled') ?? true;
  set hapticsEnabled(bool v) => _prefs?.setBool('haptics_enabled', v);

  bool get reducedMotionEnabled =>
      _prefs?.getBool('reduced_motion_enabled') ?? false;
  set reducedMotionEnabled(bool v) =>
      _prefs?.setBool('reduced_motion_enabled', v);

  bool get highContrastEnabled =>
      _prefs?.getBool('high_contrast_enabled') ?? false;
  set highContrastEnabled(bool v) =>
      _prefs?.setBool('high_contrast_enabled', v);

  bool get largeTextEnabled => _prefs?.getBool('large_text_enabled') ?? false;
  set largeTextEnabled(bool v) => _prefs?.setBool('large_text_enabled', v);

  bool get gameTutorialSeen => _prefs?.getBool('game_tutorial_seen') ?? false;
  set gameTutorialSeen(bool v) => _prefs?.setBool('game_tutorial_seen', v);

  String get matchHistoryJson =>
      _prefs?.getString('match_history_json') ?? '[]';
  set matchHistoryJson(String v) => _prefs?.setString('match_history_json', v);

  String? get activeRoomSocketPath =>
      _prefs?.getString('active_room_socket_path');
  set activeRoomSocketPath(String? v) {
    if (v == null || v.isEmpty) {
      _prefs?.remove('active_room_socket_path');
    } else {
      _prefs?.setString('active_room_socket_path', v);
    }
  }

  String? get activeRoomMode => _prefs?.getString('active_room_mode');
  set activeRoomMode(String? v) {
    if (v == null || v.isEmpty) {
      _prefs?.remove('active_room_mode');
    } else {
      _prefs?.setString('active_room_mode', v);
    }
  }

  String? get activeRoomCode => _prefs?.getString('active_room_code');
  set activeRoomCode(String? v) {
    if (v == null || v.isEmpty) {
      _prefs?.remove('active_room_code');
    } else {
      _prefs?.setString('active_room_code', v);
    }
  }

  bool get activeRoomSpectator =>
      _prefs?.getBool('active_room_spectator') ?? false;
  set activeRoomSpectator(bool v) =>
      _prefs?.setBool('active_room_spectator', v);

  String get lastDailyRewardDate =>
      _prefs?.getString('last_daily_reward_date') ?? '';
  set lastDailyRewardDate(String v) =>
      _prefs?.setString('last_daily_reward_date', v);

  bool get startChoiceSeen => _prefs?.getBool('start_choice_seen') ?? false;
  set startChoiceSeen(bool v) => _prefs?.setBool('start_choice_seen', v);
}
