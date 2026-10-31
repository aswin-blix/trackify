import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/core/utils/sms_parser.dart';

void main() {
  group('SmsParser.parse', () {
    test('extracts amount, debit type and UPI merchant', () {
      final parsed = SmsParser.parse(
        'Rs.450.00 debited from A/c XX1234 on 12-03-26 to VPA swiggy@ybl '
        'Ref 123456. -HDFC Bank',
      );
      expect(parsed.amount, 450.0);
      expect(parsed.type, 'debit');
      expect(parsed.merchant, isNotNull);
      expect(parsed.merchant!.toLowerCase(), contains('swiggy'));
    });

    test('handles Indian comma grouping and INR prefix', () {
      final parsed = SmsParser.parse(
        'INR 1,25,000.50 credited to your account. Salary from ACME CORP '
        'Ref 998877',
      );
      expect(parsed.amount, 125000.50);
      expect(parsed.type, 'credit');
    });

    test('returns nulls for unrelated messages', () {
      final parsed = SmsParser.parse('Your OTP is 482913. Do not share it.');
      expect(parsed.amount, isNull);
      expect(parsed.type, isNull);
    });
  });

  group('SmsParser.isBankTransactionSms', () {
    test('requires both an amount and a debit/credit keyword', () {
      expect(SmsParser.isBankTransactionSms('Rs 200 debited'), isTrue);
      expect(SmsParser.isBankTransactionSms('Rs 200 is your bill'), isFalse);
      expect(SmsParser.isBankTransactionSms('Payment debited today'), isFalse);
    });
  });
}
