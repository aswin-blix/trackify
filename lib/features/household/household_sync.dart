import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/providers/app_providers.dart';
import 'firebase_bootstrap.dart';
import 'household_models.dart';

const _tag = 'HouseholdSync';

/// Last-write-wins: a cloud copy replaces the local one only when it is newer.
bool shouldApplyCloudCopy(DateTime cloudUpdatedAt, DateTime? localUpdatedAt) {
  if (localUpdatedAt == null) return true;
  return cloudUpdatedAt.isAfter(localUpdatedAt);
}

/// Strips device-only fields before a transaction goes to Firestore.
/// Receipt images stay on the phone that took them.
Map<String, dynamic> transactionToCloud(TransactionModel t) {
  final m = t.toJson();
  m.remove('receiptImagePath');
  return m;
}

enum SyncStatus { off, connecting, live, error }

/// Two-way mirror between the local Hive boxes and the household's Firestore
/// collections.
///
/// Hive stays the source of truth for every screen. Local writes go through
/// the notifiers in `app_providers.dart`, which call the `push*` methods here;
/// Firestore's own offline queue delivers them when the phone is online.
/// Cloud changes arrive through snapshot listeners and are written into Hive,
/// after which the notifiers refresh.
///
/// Writes are deliberately not awaited: with offline persistence a Firestore
/// write only completes once the server acknowledges it, which would hang the
/// UI while offline.
class HouseholdSync {
  final Ref _ref;

  HouseholdSync(this._ref);

  String? _hid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _txSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _catSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _hhSub;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = SyncStatus.off;

  bool get active => _hid != null;
  String? get householdId => _hid;
  SyncStatus get status => _status;
  Stream<SyncStatus> get statusStream => _statusController.stream;

  String? get uid => FirebaseBootstrap.available
      ? FirebaseAuth.instance.currentUser?.uid
      : null;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _hhDoc(String hid) =>
      _db.collection('households').doc(hid);
  CollectionReference<Map<String, dynamic>> _txCol(String hid) =>
      _hhDoc(hid).collection('transactions');
  CollectionReference<Map<String, dynamic>> _catCol(String hid) =>
      _hhDoc(hid).collection('categories');

  void _setStatus(SyncStatus s) {
    if (_status == s) return;
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  void dispose() {
    stop();
    _statusController.close();
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  /// Starts syncing when the device is linked to a household and signed in.
  /// Safe to call repeatedly (app start, resume, after sign-in).
  void ensureStarted() {
    if (!FirebaseBootstrap.available) return;
    final hid = _ref.read(settingsProvider).householdId;
    if (hid == null || uid == null) {
      stop();
      return;
    }
    if (_hid == hid) return;
    start(hid);
  }

  void start(String hid) {
    stop();
    _hid = hid;
    _setStatus(SyncStatus.connecting);
    AppLogger.i(_tag, 'Starting sync for household $hid');
    _hhSub = _hhDoc(hid).snapshots().listen(_onHousehold, onError: _onError);
    _txSub = _txCol(hid).snapshots().listen(_onTransactions, onError: _onError);
    _catSub = _catCol(hid).snapshots().listen(_onCategories, onError: _onError);
  }

  void stop() {
    _txSub?.cancel();
    _catSub?.cancel();
    _hhSub?.cancel();
    _txSub = null;
    _catSub = null;
    _hhSub = null;
    if (_hid != null) AppLogger.i(_tag, 'Sync stopped');
    _hid = null;
    _setStatus(SyncStatus.off);
  }

  Future<void> _unlink(String reason) async {
    AppLogger.w(_tag, 'Unlinking household: $reason');
    stop();
    await _ref
        .read(settingsProvider.notifier)
        .update((s) => s.householdId = null);
  }

  void _onError(Object e, StackTrace s) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      // Removed from the household, or it was deleted.
      unawaited(_unlink('no longer a member'));
      return;
    }
    AppLogger.e(_tag, 'Sync listener failed', e, s);
    _setStatus(SyncStatus.error);
  }

  // ─── Cloud → local ─────────────────────────────────────────────────────────

  Future<void> _onHousehold(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final data = snap.data();
    if (!snap.exists || data == null) {
      if (!snap.metadata.isFromCache) await _unlink('household deleted');
      return;
    }
    final hh = Household.fromDoc(snap.id, data);
    final me = uid;
    if (me != null && !hh.memberIds.contains(me)) {
      await _unlink('removed from household');
      return;
    }

    // Budget and currency are household-level: the shared copy wins.
    final settings = _ref.read(settingsProvider);
    final budgetChanged = hh.monthlyBudget != settings.monthlyBudget;
    final currencyChanged =
        hh.currency != null && hh.currency != settings.currency;
    if (budgetChanged || currencyChanged) {
      await _ref.read(settingsProvider.notifier).update((s) {
        if (budgetChanged) s.monthlyBudget = hh.monthlyBudget;
        if (currencyChanged) {
          s.currency = hh.currency!;
          s.currencySymbol = hh.currencySymbol ?? s.currencySymbol;
        }
      });
    }
  }

  Future<void> _onTransactions(QuerySnapshot<Map<String, dynamic>> snap) async {
    final repo = _ref.read(transactionRepoProvider);
    var changed = false;
    for (final change in snap.docChanges) {
      try {
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final data = change.doc.data();
            if (data == null) break;
            final cloud = TransactionModel.fromJson(data);
            final local = repo.getById(cloud.id);
            if (!shouldApplyCloudCopy(cloud.updatedAt, local?.updatedAt)) {
              break;
            }
            cloud.receiptImagePath = local?.receiptImagePath;
            await repo.update(cloud);
            changed = true;
          case DocumentChangeType.removed:
            if (repo.getById(change.doc.id) != null) {
              await repo.delete(change.doc.id);
              changed = true;
            }
        }
      } catch (e, s) {
        AppLogger.e(_tag, 'Bad transaction doc ${change.doc.id}', e, s);
      }
    }
    if (changed) _ref.read(transactionProvider.notifier).refresh();
    if (!snap.metadata.isFromCache) _setStatus(SyncStatus.live);
  }

  Future<void> _onCategories(QuerySnapshot<Map<String, dynamic>> snap) async {
    final repo = _ref.read(categoryRepoProvider);
    var changed = false;
    for (final change in snap.docChanges) {
      try {
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final data = change.doc.data();
            if (data == null) break;
            // Categories carry no timestamp; the shared copy always wins.
            await repo.update(CategoryModel.fromJson(data));
            changed = true;
          case DocumentChangeType.removed:
            if (repo.getById(change.doc.id) != null) {
              await repo.delete(change.doc.id);
              changed = true;
            }
        }
      } catch (e, s) {
        AppLogger.e(_tag, 'Bad category doc ${change.doc.id}', e, s);
      }
    }
    if (changed) _ref.read(categoryProvider.notifier).refresh();
  }

  // ─── Local → cloud ─────────────────────────────────────────────────────────

  void _fire(Future<void> f, String what) {
    f.catchError((Object e, StackTrace s) {
      AppLogger.e(_tag, 'Failed to $what', e, s);
      _setStatus(SyncStatus.error);
    });
  }

  /// Tags a new entry with the current member when sharing is active.
  TransactionModel stamp(TransactionModel tx) {
    if (!active || tx.addedBy != null) return tx;
    final me = uid;
    if (me != null) tx.addedBy = me;
    return tx;
  }

  void pushTransaction(TransactionModel tx) {
    final hid = _hid;
    if (hid == null) return;
    _fire(_txCol(hid).doc(tx.id).set(transactionToCloud(tx)),
        'push transaction ${tx.id}');
  }

  void deleteTransaction(String id) {
    final hid = _hid;
    if (hid == null) return;
    _fire(_txCol(hid).doc(id).delete(), 'delete transaction $id');
  }

  void pushCategory(CategoryModel cat) {
    final hid = _hid;
    if (hid == null) return;
    _fire(
        _catCol(hid).doc(cat.id).set(cat.toJson()), 'push category ${cat.id}');
  }

  void pushCategories(List<CategoryModel> cats) {
    final hid = _hid;
    if (hid == null || cats.isEmpty) return;
    final batch = _db.batch();
    for (final c in cats) {
      batch.set(_catCol(hid).doc(c.id), c.toJson());
    }
    _fire(batch.commit(), 'push ${cats.length} categories');
  }

  void deleteCategory(String id) {
    final hid = _hid;
    if (hid == null) return;
    _fire(_catCol(hid).doc(id).delete(), 'delete category $id');
  }

  void pushBudget(double? budget) {
    final hid = _hid;
    if (hid == null) return;
    _fire(
      _hhDoc(hid).update({
        'monthlyBudget': budget,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
      'push budget',
    );
  }

  void pushCurrency(String code, String symbol) {
    final hid = _hid;
    if (hid == null) return;
    _fire(
      _hhDoc(hid).update({
        'currency': code,
        'currencySymbol': symbol,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
      'push currency',
    );
  }

  void pushMemberName(String name) {
    final hid = _hid;
    final me = uid;
    if (hid == null || me == null || name.trim().isEmpty) return;
    _fire(_hhDoc(hid).update({'members.$me.name': name.trim()}),
        'push member name');
  }

  /// Uploads every local entry the household does not have yet. Used right
  /// after creating or joining a household, and after a backup restore, so
  /// data that existed on this phone before sharing is not lost.
  Future<void> mergeLocalIntoHousehold() async {
    final hid = _hid;
    final me = uid;
    if (hid == null || me == null) return;
    final txRepo = _ref.read(transactionRepoProvider);
    final catRepo = _ref.read(categoryRepoProvider);

    final Set<String> cloudTxIds;
    final Set<String> cloudCatIds;
    try {
      cloudTxIds = (await _txCol(hid).get()).docs.map((d) => d.id).toSet();
      cloudCatIds = (await _catCol(hid).get()).docs.map((d) => d.id).toSet();
    } catch (e, s) {
      AppLogger.e(_tag, 'Could not read household before merge', e, s);
      return;
    }

    var batch = _db.batch();
    var pending = 0;
    var total = 0;
    void flush() {
      if (pending == 0) return;
      _fire(batch.commit(), 'merge batch');
      batch = _db.batch();
      total += pending;
      pending = 0;
    }

    for (final c in catRepo.getAll()) {
      if (cloudCatIds.contains(c.id)) continue;
      batch.set(_catCol(hid).doc(c.id), c.toJson());
      if (++pending >= 400) flush();
    }

    var stamped = false;
    for (final t in txRepo.getAll()) {
      if (t.addedBy == null) {
        t.addedBy = me;
        await txRepo.update(t);
        stamped = true;
      }
      if (cloudTxIds.contains(t.id)) continue;
      batch.set(_txCol(hid).doc(t.id), transactionToCloud(t));
      if (++pending >= 400) flush();
    }
    flush();

    if (stamped) _ref.read(transactionProvider.notifier).refresh();
    AppLogger.i(_tag, 'Merged $total local records into household $hid');
  }
}

final householdSyncProvider = Provider<HouseholdSync>((ref) {
  final sync = HouseholdSync(ref);
  ref.onDispose(sync.dispose);
  return sync;
});
