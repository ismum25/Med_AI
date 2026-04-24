import 'dart:convert';

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

  /// Best-effort secure-storage write. Swallows exceptions so a broken Android
  /// keystore can never block durable persistence via [SharedPreferences].
  static Future<void> _trySecureWrite(String key, String value) async {
    try {
      await _secure.write(key: key, value: value);
    } catch (_) {}
  }

  static Future<void> saveAfterLogin({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String userId,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final remember = rememberMe ? 'true' : 'false';
    // Durable store first — guaranteed to persist across app exits.
    await prefs.setString(SessionKeys.accessToken, accessToken);
    await prefs.setString(SessionKeys.refreshToken, refreshToken);
    await prefs.setString(SessionKeys.userRole, role);
    await prefs.setString(SessionKeys.userId, userId);
    await prefs.setString(SessionKeys.rememberMe, remember);
    await prefs.setString(SessionKeys.welcomeSeen, 'true');
    // Encrypted mirror — best-effort; keystore issues must not break login.
    await _trySecureWrite(SessionKeys.accessToken, accessToken);
    await _trySecureWrite(SessionKeys.refreshToken, refreshToken);
    await _trySecureWrite(SessionKeys.userRole, role);
    await _trySecureWrite(SessionKeys.userId, userId);
    await _trySecureWrite(SessionKeys.rememberMe, remember);
    await _trySecureWrite(SessionKeys.welcomeSeen, 'true');
  }

  static Future<void> saveTokensAfterRefresh({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SessionKeys.accessToken, accessToken);
    await prefs.setString(SessionKeys.refreshToken, refreshToken);
    await _trySecureWrite(SessionKeys.accessToken, accessToken);
    await _trySecureWrite(SessionKeys.refreshToken, refreshToken);
  }

  static Future<void> setWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SessionKeys.welcomeSeen, 'true');
    await _trySecureWrite(SessionKeys.welcomeSeen, 'true');
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

  static Future<String?> _trySecureRead(String key) async {
    try {
      return await _secure.read(key: key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _rehydrateSecureFromPrefs(SharedPreferences prefs) async {
    final access = prefs.getString(SessionKeys.accessToken);
    final refresh = prefs.getString(SessionKeys.refreshToken);
    final role = prefs.getString(SessionKeys.userRole);
    final uid = prefs.getString(SessionKeys.userId);
    if (access == null) return;
    await _trySecureWrite(SessionKeys.accessToken, access);
    if (refresh != null) await _trySecureWrite(SessionKeys.refreshToken, refresh);
    if (role != null) await _trySecureWrite(SessionKeys.userRole, role);
    if (uid != null) await _trySecureWrite(SessionKeys.userId, uid);
  }

  static Future<void> _syncPrefsFromSecure(SharedPreferences prefs) async {
    final access = await _trySecureRead(SessionKeys.accessToken);
    if (access == null) return;
    final refresh = await _trySecureRead(SessionKeys.refreshToken);
    final role = await _trySecureRead(SessionKeys.userRole);
    final uid = await _trySecureRead(SessionKeys.userId);
    final remember = await _trySecureRead(SessionKeys.rememberMe);
    final welcome = await _trySecureRead(SessionKeys.welcomeSeen);
    await prefs.setString(SessionKeys.accessToken, access);
    if (refresh != null) await prefs.setString(SessionKeys.refreshToken, refresh);
    if (role != null) await prefs.setString(SessionKeys.userRole, role);
    if (uid != null) await prefs.setString(SessionKeys.userId, uid);
    if (remember != null) await prefs.setString(SessionKeys.rememberMe, remember);
    if (welcome != null) await prefs.setString(SessionKeys.welcomeSeen, welcome);
  }

  static String? _extractRoleFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded);
      if (map is Map<String, dynamic>) {
        final role = map['role'];
        if (role is String && role.trim().isNotEmpty) {
          return role.trim();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
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
    // Prefs is the source of truth; secure storage is a best-effort mirror.
    final remember = prefs.getString(SessionKeys.rememberMe) ??
        await _trySecureRead(SessionKeys.rememberMe);

    var token = prefs.getString(SessionKeys.accessToken) ??
        await _trySecureRead(SessionKeys.accessToken);
    var role = prefs.getString(SessionKeys.userRole) ??
        await _trySecureRead(SessionKeys.userRole);

    if (token != null &&
        await _trySecureRead(SessionKeys.accessToken) == null) {
      await _rehydrateSecureFromPrefs(prefs);
    } else if (token != null &&
        prefs.getString(SessionKeys.accessToken) == null) {
      await _syncPrefsFromSecure(prefs);
    }

    token = prefs.getString(SessionKeys.accessToken) ??
        await _trySecureRead(SessionKeys.accessToken);
    role = prefs.getString(SessionKeys.userRole) ??
        await _trySecureRead(SessionKeys.userRole);
    if (token != null && (role == null || role.trim().isEmpty)) {
      final extractedRole = _extractRoleFromJwt(token);
      if (extractedRole != null) {
        role = extractedRole;
        await prefs.setString(SessionKeys.userRole, extractedRole);
        await _trySecureWrite(SessionKeys.userRole, extractedRole);
      }
    }

    var welcomeSeen = prefs.getString(SessionKeys.welcomeSeen) ??
        await _trySecureRead(SessionKeys.welcomeSeen);
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
