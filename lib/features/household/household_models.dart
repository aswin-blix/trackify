import 'package:cloud_firestore/cloud_firestore.dart';

/// One person in a shared household.
class HouseholdMember {
  final String uid;
  final String name;
  final String? photoUrl;
  final DateTime? joinedAt;

  const HouseholdMember({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.joinedAt,
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  Map<String, dynamic> toMap() => {
        'name': name,
        'photoUrl': photoUrl,
        'joinedAt': joinedAt?.toIso8601String(),
      };

  factory HouseholdMember.fromMap(String uid, Map<String, dynamic> m) {
    final rawName = (m['name'] as String?)?.trim() ?? '';
    return HouseholdMember(
      uid: uid,
      name: rawName.isEmpty ? 'Member' : rawName,
      photoUrl: m['photoUrl'] as String?,
      joinedAt: parseCloudDate(m['joinedAt']),
    );
  }
}

/// A shared ledger: one income, one budget, several people adding entries.
///
/// Firestore layout:
/// ```
/// households/{id}                 this document
/// households/{id}/transactions/*  TransactionModel.toJson minus receipt path
/// households/{id}/categories/*    CategoryModel.toJson
/// invites/{code}                  { householdId }
/// ```
class Household {
  final String id;
  final String name;
  final String inviteCode;
  final String ownerUid;
  final List<String> memberIds;
  final List<HouseholdMember> members;
  final double? monthlyBudget;
  final String? currency;
  final String? currencySymbol;

  const Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerUid,
    required this.memberIds,
    required this.members,
    this.monthlyBudget,
    this.currency,
    this.currencySymbol,
  });

  factory Household.fromDoc(String id, Map<String, dynamic> d) {
    final ids = (d['memberIds'] as List?)?.cast<String>() ?? const <String>[];
    final rawMembers = d['members'];
    final members = <HouseholdMember>[];
    for (final uid in ids) {
      final m = rawMembers is Map ? rawMembers[uid] : null;
      members.add(m is Map
          ? HouseholdMember.fromMap(uid, Map<String, dynamic>.from(m))
          : HouseholdMember(uid: uid, name: 'Member'));
    }
    members.sort((a, b) {
      final x = a.joinedAt, y = b.joinedAt;
      if (x == null || y == null) return 0;
      return x.compareTo(y);
    });
    return Household(
      id: id,
      name: (d['name'] as String?)?.trim().isNotEmpty == true
          ? (d['name'] as String).trim()
          : 'Our Household',
      inviteCode: d['inviteCode'] as String? ?? '',
      ownerUid: d['ownerUid'] as String? ?? '',
      memberIds: ids,
      members: members,
      monthlyBudget: (d['monthlyBudget'] as num?)?.toDouble(),
      currency: d['currency'] as String?,
      currencySymbol: d['currencySymbol'] as String?,
    );
  }

  bool get isShared => memberIds.length > 1;

  HouseholdMember? member(String? uid) {
    if (uid == null) return null;
    for (final m in members) {
      if (m.uid == uid) return m;
    }
    return null;
  }

  String nameOf(String? uid, {String fallback = 'Unknown'}) =>
      member(uid)?.name ?? fallback;
}

DateTime? parseCloudDate(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  return null;
}
