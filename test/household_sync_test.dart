import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/data/models/transaction_model.dart';
import 'package:trackify/features/household/household_models.dart';
import 'package:trackify/features/household/household_service.dart';
import 'package:trackify/features/household/household_sync.dart';

void main() {
  group('shouldApplyCloudCopy', () {
    final t0 = DateTime(2026, 1, 1, 12);
    final t1 = DateTime(2026, 1, 1, 13);

    test('applies when there is no local copy', () {
      expect(shouldApplyCloudCopy(t0, null), isTrue);
    });

    test('applies only a strictly newer cloud copy', () {
      expect(shouldApplyCloudCopy(t1, t0), isTrue);
      expect(shouldApplyCloudCopy(t0, t1), isFalse);
      expect(shouldApplyCloudCopy(t0, t0), isFalse,
          reason: 'our own echoed write must not re-apply');
    });
  });

  group('transactionToCloud', () {
    test('drops the receipt path and keeps addedBy', () {
      final tx = TransactionModel(
        id: 'a',
        amount: 10,
        type: TransactionType.expense,
        categoryId: 'food',
        date: DateTime(2026, 1, 1),
        receiptImagePath: '/data/receipt.jpg',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        addedBy: 'uid-1',
      );
      final m = transactionToCloud(tx);
      expect(m.containsKey('receiptImagePath'), isFalse);
      expect(m['addedBy'], 'uid-1');
      expect(TransactionModel.fromJson(m).addedBy, 'uid-1');
    });
  });

  group('invite codes', () {
    test('are 6 characters from the unambiguous alphabet', () {
      final rng = Random(42);
      for (var i = 0; i < 200; i++) {
        final code = generateInviteCode(rng);
        expect(code.length, kInviteCodeLength);
        expect(code.split('').every(kInviteAlphabet.contains), isTrue);
        expect(code, isNot(contains(RegExp('[0O1I]'))));
      }
    });

    test('normalise user input', () {
      expect(normalizeInviteCode(' ab-c 12d '), 'ABC12D');
      expect(normalizeInviteCode('XYZ789'), 'XYZ789');
    });
  });

  group('Household.fromDoc', () {
    test('orders members by join time and resolves names', () {
      final hh = Household.fromDoc('h1', {
        'name': 'Home',
        'inviteCode': 'ABC234',
        'ownerUid': 'u1',
        'memberIds': ['u2', 'u1'],
        'members': {
          'u1': {'name': 'Asha', 'joinedAt': '2026-01-01T00:00:00.000'},
          'u2': {'name': 'Ravi', 'joinedAt': '2026-01-02T00:00:00.000'},
        },
        'monthlyBudget': 50000,
        'currency': 'INR',
        'currencySymbol': '₹',
      });
      expect(hh.isShared, isTrue);
      expect(hh.members.map((m) => m.name), ['Asha', 'Ravi']);
      expect(hh.nameOf('u2'), 'Ravi');
      expect(hh.nameOf('nobody', fallback: '?'), '?');
      expect(hh.monthlyBudget, 50000.0);
    });

    test('tolerates missing member entries', () {
      final hh = Household.fromDoc('h1', {
        'memberIds': ['u1'],
      });
      expect(hh.name, 'Our Household');
      expect(hh.isShared, isFalse);
      expect(hh.members.single.name, 'Member');
    });
  });
}
