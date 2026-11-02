import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/core/utils/recurrence.dart';
import 'package:trackify/data/models/recurring_model.dart';
import 'package:trackify/data/models/transaction_model.dart';

void main() {
  group('Recurrence.occurrence', () {
    test('monthly on the 31st clamps to month end and comes back', () {
      final start = DateTime(2026, 1, 31, 9, 30);
      DateTime at(int i) =>
          Recurrence.occurrence(start, RecurrenceFrequency.monthly, i);
      expect(at(1), DateTime(2026, 2, 28, 9, 30));
      expect(at(2), DateTime(2026, 3, 31, 9, 30));
      expect(at(3), DateTime(2026, 4, 30, 9, 30));
      expect(at(12), DateTime(2027, 1, 31, 9, 30));
    });

    test('yearly on 29 Feb falls back to 28 Feb', () {
      final start = DateTime(2028, 2, 29);
      expect(Recurrence.occurrence(start, RecurrenceFrequency.yearly, 1),
          DateTime(2029, 2, 28));
      expect(Recurrence.occurrence(start, RecurrenceFrequency.yearly, 4),
          DateTime(2032, 2, 29));
    });

    test('weekly and daily with interval', () {
      final start = DateTime(2026, 12, 28, 8);
      expect(
          Recurrence.occurrence(start, RecurrenceFrequency.weekly, 1,
              interval: 2),
          DateTime(2027, 1, 11, 8));
      expect(Recurrence.occurrence(start, RecurrenceFrequency.daily, 5),
          DateTime(2027, 1, 2, 8));
    });
  });

  group('Recurrence.dueIndexes', () {
    final start = DateTime(2026, 8, 1, 10);

    test('catches up every missed occurrence up to now', () {
      final due = Recurrence.dueIndexes(
        start: start,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        fromIndex: 0,
        now: DateTime(2026, 11, 2),
      );
      expect(due, [0, 1, 2, 3]); // Aug, Sep, Oct, Nov 1
    });

    test('resumes from postedCount and respects the end date', () {
      final due = Recurrence.dueIndexes(
        start: start,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        fromIndex: 2,
        now: DateTime(2027, 6, 1),
        end: DateTime(2026, 12, 15),
      );
      expect(due, [2, 3, 4]); // Oct, Nov, Dec
    });

    test('future start posts nothing', () {
      expect(
        Recurrence.dueIndexes(
          start: DateTime(2026, 12, 1),
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          fromIndex: 0,
          now: DateTime(2026, 11, 2),
        ),
        isEmpty,
      );
    });

    test('is capped', () {
      final due = Recurrence.dueIndexes(
        start: DateTime(2020, 1, 1),
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        fromIndex: 0,
        now: DateTime(2026, 1, 1),
        max: 50,
      );
      expect(due.length, 50);
    });

    test('firstIndexAfter skips periods missed while paused', () {
      expect(
        Recurrence.firstIndexAfter(
          start: start,
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          fromIndex: 1,
          now: DateTime(2026, 11, 2),
        ),
        4, // Dec 1
      );
    });
  });

  group('RecurringModel', () {
    RecurringModel rule() => RecurringModel(
          id: 'r1',
          amount: 12000,
          type: TransactionType.expense,
          categoryId: 'rent',
          note: 'Rent',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 10, 5, 9),
          createdAt: DateTime(2026, 10, 1),
          updatedAt: DateTime(2026, 10, 1),
        );

    test('builds stable, dated transactions per occurrence', () {
      final r = rule();
      final tx = r.buildTransaction(1);
      expect(tx.id, 'rec_r1_1');
      expect(tx.date, DateTime(2026, 11, 5, 9));
      expect(tx.amount, 12000);
      expect(tx.toAccountId, isNull);
    });

    test('JSON round trip', () {
      final r = rule()
        ..postedCount = 3
        ..active = false
        ..endDate = DateTime(2027, 1, 1);
      final back = RecurringModel.fromJson(r.toJson());
      expect(back.toJson(), r.toJson());
    });
  });
}
