import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One account that has previously signed into MyRSU on this device.
/// Only email/name/photo are stored — never a password or token.
class AccountHistoryEntry {
  final String email;
  final String name;
  final String? photoUrl;
  final String lastUsedIso;

  AccountHistoryEntry({
    required this.email,
    required this.name,
    this.photoUrl,
    required this.lastUsedIso,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'lastUsedIso': lastUsedIso,
      };

  factory AccountHistoryEntry.fromJson(Map<String, dynamic> json) => AccountHistoryEntry(
        email: json['email'] ?? '',
        name: json['name'] ?? '',
        photoUrl: json['photoUrl'],
        lastUsedIso: json['lastUsedIso'] ?? '',
      );
}

/// Powers the "switch account" dropdown under the profile avatar.
///
/// A web app has no way to read the browser's actual signed-in Google
/// account list — that's locked down for privacy. This is MyRSU's own
/// lightweight equivalent: a short list of accounts that have
/// previously signed into *this app*, on *this device*, stored in
/// SharedPreferences (browser localStorage under the hood). Tapping one
/// doesn't skip the password — it just pre-fills the email on the
/// login screen so switching is a two-tap flow instead of retyping
/// everything.
class AccountHistoryService {
  AccountHistoryService._internal();
  static final AccountHistoryService instance = AccountHistoryService._internal();

  static const _key = 'myrsu_account_history';
  static const _maxEntries = 5;

  Future<List<AccountHistoryEntry>> getRecentAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(AccountHistoryEntry.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  /// Call after any successful sign-in. Moves [email] to the front of
  /// the list (deduping) and caps the history at [_maxEntries].
  Future<void> recordSignIn({
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    if (email.isEmpty) return;
    final existing = await getRecentAccounts();
    existing.removeWhere((a) => a.email == email);
    existing.insert(
      0,
      AccountHistoryEntry(
        email: email,
        name: name.isEmpty ? email : name,
        photoUrl: photoUrl,
        lastUsedIso: DateTime.now().toIso8601String(),
      ),
    );
    final trimmed = existing.take(_maxEntries).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(trimmed.map((a) => a.toJson()).toList()));
  }

  Future<void> removeAccount(String email) async {
    final existing = await getRecentAccounts();
    existing.removeWhere((a) => a.email == email);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(existing.map((a) => a.toJson()).toList()));
  }
}
