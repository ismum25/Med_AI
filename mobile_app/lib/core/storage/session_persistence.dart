import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth/session fields to both [SharedPreferences] and
/// [FlutterSecureStorage] so cold start / reload keeps the user signed in
/// even when secure storage reads fail or lag behind.
abstract final class SessionKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const userRole = 'user_role';
  static const userId = 'user_id';
  static const rememberMe = 'remember_me';
  static const welcomeSeen = 'welcome_seen';
}

final class SessionPersistence {
  SessionPersistence._();

  static const _secure = FlutterSecureStorage();

  static Future<void> saveAfterLogin({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String userId,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final remember = rememberMe ? 'true' : 'false';
    await Future.wait([
      _secure.write(key: SessionKeys.accessToken, value: accessToken),
      _secure.write(key: SessionKeys.refreshToken, value: refreshToken),
      _secure.write(key: SessionKeys.userRole, value: role),
      _secure.write(key: SessionKeys.userId, value: userId),
      _secure.write(key: SessionKeys.rememberMe, value: remember),
      _secure.write(key: SessionKeys.welcomeSeen, value: 'true'),
      prefs.setString(SessionKeys.accessToken, accessToken),
      prefs.setString(SessionKeys.refreshToken, refreshToken),
      prefs.setString(SessionKeys.userRole, role),
      prefs.setString(SessionKeys.userId, userId),
      prefs.setString(SessionKeys.rememberMe, remember),
      prefs.setString(SessionKeys.welcomeSeen, 'true'),
    ]);
  }

  static Future<void> saveTokensAfterRefresh({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      _secure.write(key: SessionKeys.accessToken, value: accessToken),
      _secure.write(key: SessionKeys.refreshToken, value: refreshToken),
      prefs.setString(SessionKeys.accessToken, accessToken),
      prefs.setString(SessionKeys.refreshToken, refreshToken),
    ]);
  }

  static Future<void> setWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      _secure.write(key: SessionKeys.welcomeSeen, value: 'true'),
      prefs.setString(SessionKeys.welcomeSeen, 'true'),
    ]);
  }

  /// Clears auth credentials but keeps welcome flow state (matches profile sign-out).
  static Future<void> clearAuthKeepWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [
      SessionKeys.accessToken,
      SessionKeys.refreshToken,
      SessionKeys.userRole,
      SessionKeys.userId,
      SessionKeys.rememberMe,
    ]) {
      await _secure.delete(key: k);
      await prefs.remove(k);
    }
  }

  /// Full sign-out: all session keys in prefs + secure storage.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await _secure.deleteAll();
    for (final k in [
      SessionKeys.accessToken,
      SessionKeys.refreshToken,
      SessionKeys.userRole,
      SessionKeys.userId,
      SessionKeys.rememberMe,
      SessionKeys.welcomeSeen,
    ]) {
      await prefs.remove(k);
    }
  }

  static Future<void> _clearTokensOnly() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [
      SessionKeys.accessToken,
      SessionKeys.refreshToken,
      SessionKeys.userRole,
      SessionKeys.userId,
    ]) {
      await _secure.delete(key: k);
      await prefs.remove(k);
    }
  }

  static Future<void> _rehydrateSecureFromPrefs(SharedPreferences prefs) async {
    final access = prefs.getString(SessionKeys.accessToken);
    final refresh = prefs.getString(SessionKeys.refreshToken);
    final role = prefs.getString(SessionKeys.userRole);
    final uid = prefs.getString(SessionKeys.userId);
    if (access == null) return;
    await Future.wait([
      _secure.write(key: SessionKeys.accessToken, value: access),
      if (refresh != null)
        _secure.write(key: SessionKeys.refreshToken, value: refresh),
      if (role != null) _secure.write(key: SessionKeys.userRole, value: role),
      if (uid != null) _secure.write(key: SessionKeys.userId, value: uid),
    ]);
  }

  static Future<void> _syncPrefsFromSecure(SharedPreferences prefs) async {
    final access = await _secure.read(key: SessionKeys.accessToken);
    if (access == null) return;
    final refresh = await _secure.read(key: SessionKeys.refreshToken);
    final role = await _secure.read(key: SessionKeys.userRole);
    final uid = await _secure.read(key: SessionKeys.userId);
    final remember = await _secure.read(key: SessionKeys.rememberMe);
    final welcome = await _secure.read(key: SessionKeys.welcomeSeen);
    await Future.wait([
      prefs.setString(SessionKeys.accessToken, access),
      if (refresh != null)
        prefs.setString(SessionKeys.refreshToken, refresh),
      if (role != null) prefs.setString(SessionKeys.userRole, role),
      if (uid != null) prefs.setString(SessionKeys.userId, uid),
      if (remember != null) prefs.setString(SessionKeys.rememberMe, remember),
      if (welcome != null) prefs.setString(SessionKeys.welcomeSeen, welcome),
    ]);
  }

  /// Call from [main] before [runApp]. Applies remember-me policy, then ensures
  /// secure storage has tokens if prefs still has them.
  static Future<
      ({
        String? token,
        String? role,
        String? welcomeSeen,
        String? remember,
      })> loadForStartup() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getString(SessionKeys.rememberMe) ??
        await _secure.read(key: SessionKeys.rememberMe);

    if (remember == 'false') {
      await _clearTokensOnly();
    }

    var token = await _secure.read(key: SessionKeys.accessToken) ??
        prefs.getString(SessionKeys.accessToken);
    var role = await _secure.read(key: SessionKeys.userRole) ??
        prefs.getString(SessionKeys.userRole);

    if (token != null &&
        await _secure.read(key: SessionKeys.accessToken) == null) {
      await _rehydrateSecureFromPrefs(prefs);
    } else if (token != null &&
        prefs.getString(SessionKeys.accessToken) == null) {
      await _syncPrefsFromSecure(prefs);
    }

    token = await _secure.read(key: SessionKeys.accessToken) ??
        prefs.getString(SessionKeys.accessToken);
    role = await _secure.read(key: SessionKeys.userRole) ??
        prefs.getString(SessionKeys.userRole);

    var welcomeSeen = prefs.getString(SessionKeys.welcomeSeen) ??
        await _secure.read(key: SessionKeys.welcomeSeen);
    if (welcomeSeen != null &&
        prefs.getString(SessionKeys.welcomeSeen) == null) {
      await prefs.setString(SessionKeys.welcomeSeen, welcomeSeen);
    }

    return (
      token: token,
      role: role,
      welcomeSeen: welcomeSeen,
      remember: remember,
    );
  }
}
