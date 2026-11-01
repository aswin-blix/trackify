import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/providers/app_providers.dart';
import 'firebase_bootstrap.dart';
import 'household_models.dart';
import 'household_sync.dart';

const _tag = 'HouseholdService';
const _netTimeout = Duration(seconds: 20);

/// Characters used in invite codes: no 0/O/1/I so they cannot be misread.
const kInviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const kInviteCodeLength = 6;

String generateInviteCode(Random rng) => List.generate(
      kInviteCodeLength,
      (_) => kInviteAlphabet[rng.nextInt(kInviteAlphabet.length)],
    ).join();

/// Upper-cases and strips spaces/dashes so "ab-c 12d" becomes "ABC12D".
String normalizeInviteCode(String raw) =>
    raw.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

/// A user-facing failure from the household flows.
class HouseholdException implements Exception {
  final String message;
  const HouseholdException(this.message);

  @override
  String toString() => message;
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authUserProvider = StreamProvider<User?>((ref) {
  if (!FirebaseBootstrap.available) return Stream.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

final currentUidProvider =
    Provider<String?>((ref) => ref.watch(authUserProvider).value?.uid);

/// The household this device is linked to, kept live from Firestore
/// (served from the local cache while offline). Null when not sharing.
final householdProvider = StreamProvider<Household?>((ref) {
  if (!FirebaseBootstrap.available) return Stream.value(null);
  final hid = ref.watch(settingsProvider.select((s) => s.householdId));
  final user = ref.watch(authUserProvider).value;
  if (hid == null || user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('households')
      .doc(hid)
      .snapshots()
      .map((d) {
    final data = d.data();
    return d.exists && data != null ? Household.fromDoc(d.id, data) : null;
  }).handleError((Object e, StackTrace s) {
    AppLogger.e(_tag, 'Household stream failed', e, s);
  });
});

/// uid → display name for the current household; empty when not sharing or
/// when the household has a single member (nothing worth labelling).
final householdMembersProvider = Provider<Map<String, String>>((ref) {
  final hh = ref.watch(householdProvider).value;
  if (hh == null || !hh.isShared) return const {};
  return {for (final m in hh.members) m.uid: m.name};
});

final householdServiceProvider =
    Provider<HouseholdService>((ref) => HouseholdService(ref));

// ─── Service ──────────────────────────────────────────────────────────────────

class HouseholdService {
  final Ref _ref;

  HouseholdService(this._ref);

  static bool _googleInitialized = false;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  HouseholdSync get _sync => _ref.read(householdSyncProvider);

  void _requireFirebase() {
    if (!FirebaseBootstrap.available) {
      throw const HouseholdException(
          'Shared tracking is not configured in this build.');
    }
  }

  User _requireUser() {
    final u = _auth.currentUser;
    if (u == null) {
      throw const HouseholdException('Sign in with Google first.');
    }
    return u;
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<User> signInWithGoogle() async {
    _requireFirebase();
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await google.initialize();
      _googleInitialized = true;
    }

    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const HouseholdException('Sign-in cancelled.');
      }
      AppLogger.e(_tag, 'Google sign-in failed', e);
      throw HouseholdException(
          'Google sign-in failed: ${e.description ?? e.code.name}');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const HouseholdException(
          'Google did not return an ID token. Check the SHA-1 fingerprint and web client in Firebase.');
    }

    final UserCredential cred;
    try {
      cred = await _auth
          .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken))
          .timeout(_netTimeout);
    } catch (e, s) {
      AppLogger.e(_tag, 'Firebase sign-in failed', e, s);
      throw HouseholdException(_describe(e));
    }
    final user = cred.user;
    if (user == null) throw const HouseholdException('Sign-in failed.');

    await _relinkExisting(user.uid);
    return user;
  }

  /// If this account already belongs to a household (reinstall, cleared data,
  /// second device) link to it again automatically.
  Future<Household?> _relinkExisting(String uid) async {
    if (_ref.read(settingsProvider).householdId != null) {
      _sync.ensureStarted();
      return null;
    }
    try {
      final q = await _db
          .collection('households')
          .where('memberIds', arrayContains: uid)
          .limit(1)
          .get()
          .timeout(_netTimeout);
      if (q.docs.isEmpty) return null;
      final doc = q.docs.first;
      final hh = Household.fromDoc(doc.id, doc.data());
      AppLogger.i(_tag, 'Relinking to existing household ${hh.id}');
      await _link(hh.id);
      return hh;
    } catch (e, s) {
      AppLogger.e(_tag, 'Household lookup failed', e, s);
      return null;
    }
  }

  Future<void> signOut() async {
    _requireFirebase();
    _sync.stop();
    await _ref
        .read(settingsProvider.notifier)
        .update((s) => s.householdId = null);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      AppLogger.w(_tag, 'Google sign-out failed: $e');
    }
    await _auth.signOut();
  }

  // ─── Household ─────────────────────────────────────────────────────────────

  Future<void> _link(String hid) async {
    await _ref
        .read(settingsProvider.notifier)
        .update((s) => s.householdId = hid);
    _sync.start(hid);
    await _sync.mergeLocalIntoHousehold();
  }

  String _memberName(User user) {
    final local = _ref.read(settingsProvider).userName.trim();
    if (local.isNotEmpty) return local;
    final google = user.displayName?.trim() ?? '';
    return google.isNotEmpty ? google : 'Partner';
  }

  Map<String, dynamic> _memberEntry(User user) => HouseholdMember(
        uid: user.uid,
        name: _memberName(user),
        photoUrl: user.photoURL,
        joinedAt: DateTime.now(),
      ).toMap();

  Future<String> createHousehold(String name) async {
    _requireFirebase();
    final user = _requireUser();
    final settings = _ref.read(settingsProvider);
    if (settings.householdId != null) {
      throw const HouseholdException('This device is already in a household.');
    }

    final code = await _uniqueInviteCode();
    final hhRef = _db.collection('households').doc();
    final now = DateTime.now().toIso8601String();
    final trimmed = name.trim();

    final batch = _db.batch();
    batch.set(hhRef, {
      'name': trimmed.isEmpty ? 'Our Household' : trimmed,
      'inviteCode': code,
      'ownerUid': user.uid,
      'memberIds': [user.uid],
      'members': {user.uid: _memberEntry(user)},
      'monthlyBudget': settings.monthlyBudget,
      'currency': settings.currency,
      'currencySymbol': settings.currencySymbol,
      'createdAt': now,
      'updatedAt': now,
    });
    batch.set(_db.collection('invites').doc(code), {
      'householdId': hhRef.id,
      'createdAt': now,
    });
    try {
      await batch.commit().timeout(_netTimeout);
    } catch (e, s) {
      AppLogger.e(_tag, 'Create household failed', e, s);
      throw HouseholdException(_describe(e));
    }

    await _link(hhRef.id);
    return hhRef.id;
  }

  Future<String> joinHousehold(String rawCode) async {
    _requireFirebase();
    final user = _requireUser();
    if (_ref.read(settingsProvider).householdId != null) {
      throw const HouseholdException('This device is already in a household.');
    }
    final code = normalizeInviteCode(rawCode);
    if (code.length != kInviteCodeLength) {
      throw const HouseholdException('Invite codes are 6 characters long.');
    }

    final String hid;
    try {
      final invite = await _db
          .collection('invites')
          .doc(code)
          .get(const GetOptions(source: Source.server))
          .timeout(_netTimeout);
      final id = invite.data()?['householdId'];
      if (!invite.exists || id is! String) {
        throw const HouseholdException('No household found for that code.');
      }
      hid = id;
      await _db.collection('households').doc(hid).update({
        'memberIds': FieldValue.arrayUnion([user.uid]),
        'members.${user.uid}': _memberEntry(user),
        'updatedAt': DateTime.now().toIso8601String(),
      }).timeout(_netTimeout);
    } on HouseholdException {
      rethrow;
    } catch (e, s) {
      AppLogger.e(_tag, 'Join household failed', e, s);
      throw HouseholdException(_describe(e));
    }

    await _link(hid);
    return hid;
  }

  /// Removes this account from the household. Local data is kept; the other
  /// members keep the shared copy.
  Future<void> leaveHousehold() async {
    _requireFirebase();
    final user = _requireUser();
    final hid = _ref.read(settingsProvider).householdId;
    if (hid == null) return;
    _sync.stop();
    try {
      await _db.collection('households').doc(hid).update({
        'memberIds': FieldValue.arrayRemove([user.uid]),
        'members.${user.uid}': FieldValue.delete(),
        'updatedAt': DateTime.now().toIso8601String(),
      }).timeout(_netTimeout);
    } catch (e) {
      // The write stays queued in Firestore and lands when online.
      AppLogger.w(_tag, 'Leave household will complete when online: $e');
    }
    await _ref
        .read(settingsProvider.notifier)
        .update((s) => s.householdId = null);
  }

  Future<String> _uniqueInviteCode() async {
    final rng = Random.secure();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = generateInviteCode(rng);
      final DocumentSnapshot<Map<String, dynamic>> existing;
      try {
        existing = await _db
            .collection('invites')
            .doc(code)
            .get(const GetOptions(source: Source.server))
            .timeout(_netTimeout);
      } catch (e) {
        throw HouseholdException(_describe(e));
      }
      if (!existing.exists) return code;
    }
    throw const HouseholdException(
        'Could not generate an invite code. Please try again.');
  }

  String _describe(Object e) {
    if (e is TimeoutException) {
      return 'No connection. Try again when you are online.';
    }
    if (e is FirebaseAuthException) {
      return e.message ?? 'Authentication failed (${e.code}).';
    }
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'Not allowed. The household may be full, or the code is no longer valid.';
        case 'unavailable':
          return 'No connection. Try again when you are online.';
        case 'not-found':
          return 'That household no longer exists.';
        default:
          return e.message ?? 'Firebase error (${e.code}).';
      }
    }
    return 'Something went wrong: $e';
  }
}
