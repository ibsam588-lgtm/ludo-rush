import 'package:shared_preferences/shared_preferences.dart';

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

  String get displayName => _prefs?.getString('display_name') ?? 'Ludo Player';
  set displayName(String v) => _prefs?.setString('display_name', v);

  String get countryCode => _prefs?.getString('country_code') ?? 'US';
  set countryCode(String v) => _prefs?.setString('country_code', v);

  int get avatarPreset => _prefs?.getInt('avatar_preset') ?? 0;
  set avatarPreset(int v) => _prefs?.setInt('avatar_preset', v);

  String? get avatarImagePath => _prefs?.getString('avatar_image_path');
  set avatarImagePath(String? v) {
    if (v == null || v.isEmpty) {
      _prefs?.remove('avatar_image_path');
    } else {
      _prefs?.setString('avatar_image_path', v);
    }
  }

  int get coins => _prefs?.getInt('coins') ?? 500;
  set coins(int v) => _prefs?.setInt('coins', v);

  int get rating => _prefs?.getInt('rating') ?? 1000;
  set rating(int v) => _prefs?.setInt('rating', v);

  int get gamesPlayed => _prefs?.getInt('games_played') ?? 0;
  set gamesPlayed(int v) => _prefs?.setInt('games_played', v);

  int get wins => _prefs?.getInt('wins') ?? 0;
  set wins(int v) => _prefs?.setInt('wins', v);

  bool get isDarkMode => _prefs?.getBool('dark_mode') ?? true;
  set isDarkMode(bool v) => _prefs?.setBool('dark_mode', v);

  String get matchDifficulty =>
      _prefs?.getString('match_difficulty') ?? 'medium';
  set matchDifficulty(String v) => _prefs?.setString('match_difficulty', v);
}
