import 'package:catapush_flutter_sdk_example/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRepository {
  static const spKey = 'user';
  User? _user;

  Future<User?> getUser() async {
    if (_user == null) {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(spKey);
      if (json != null) {
        _user = User.fromJson(json);
      }
    }
    return _user;
  }

  Future<bool> setUser(User user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(spKey, user.toJson());
  }

  Future<bool> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(spKey);
  }
}