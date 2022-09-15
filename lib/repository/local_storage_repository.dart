import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageRepository {
  void setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_Keys.token, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_Keys.token);
  }
}

abstract class _Keys {
  static const token = 'x-auth-token';
}
