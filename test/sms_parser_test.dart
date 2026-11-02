import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/core/utils/sms_parser.dart';

/// Formats below are real Indian bank alerts with names, account numbers
/// and references replaced.
void main() {
  void expectTxn(
    String body, {
    required double amount,
    required String type,
    String? merchant,
    bool trusted = true,
  }) {
    expect(SmsParser.isBankTransactionSms(body, trustedSender: trusted), isTrue,
        reason: body);
    final p = SmsParser.parse(body);
    expect(p.amount, amount, reason: body);
    expect(p.type, type, reason: body);
    if (merchant != null) expect(p.merchant, merchant, reason: body);
  }

  void expectIgnored(String body) {
    expect(SmsParser.isBankTransactionSms(body), isFalse, reason: body);
  }

  group('transactions', () {
    test('SBI UPI debit has no currency marker', () {
      expectTxn(
        'Dear UPI user A/C X1234 debited by 75.00 on date 02Nov26 trf to '
        'SHYLAJA T Refno 612345678901 If not u? call-1800111109 for other '
        'services-18001234-SBI',
        amount: 75,
        type: 'debit',
        merchant: 'Shylaja T',
      );
    });

    test('SBI UPI credit', () {
      expectTxn(
        'Dear SBI User, your A/c X1234-credited by Rs.2500 on 19Oct26 '
        'transfer from SELVA RAJ N Ref No 612345678901 -SBI',
        amount: 2500,
        type: 'credit',
        merchant: 'Selva Raj N',
      );
    });

    test('HDFC multi-line UPI send', () {
      expectTxn(
        'Sent Rs.652.00\nFrom HDFC Bank A/C *1234\nTo ONE STOP SUPER MARKET '
        'PVT\nOn 07/10/26\nRef 612345678901\nNot You?\nCall 18002586161/SMS '
        'BLOCK UPI to 7308080808',
        amount: 652,
        type: 'debit',
        merchant: 'One Stop Super Market Pvt',
      );
    });

    test('HDFC credit alert with VPA', () {
      expectTxn(
        'Credit Alert!\nRs.774.00 credited to HDFC Bank A/c XX1234 on '
        '05-09-26 from VPA someone-2@okaxis (UPI 612345678901)',
        amount: 774,
        type: 'credit',
        merchant: 'someone-2@okaxis',
      );
    });

    test('HDFC card spend ignores the balance amount', () {
      expectTxn(
        'Spent Rs.9441.94 From HDFC Bank Card x1234 At ANTHROPIC* CLAUDE SUB '
        'On 2026-06-27:11:34:43 Bal Rs.3794.63 Not You? Call 18002586161',
        amount: 9441.94,
        type: 'debit',
        merchant: 'Anthropic* Claude Sub',
      );
    });

    test('SBI CBS salary credit picks the credit, not Avl Bal', () {
      expectTxn(
        'Your A/C XXXXX123456 has credit for BY SALARY of Rs 40,950.00 on '
        '02/09/26. Avl Bal Rs 41,301.68.-SBI',
        amount: 40950,
        type: 'credit',
        merchant: 'Salary',
      );
    });

    test('SBI CBS debit by transfer', () {
      expectTxn(
        'Dear Customer, Your A/C XXXXX123456 has a debit by transfer of Rs '
        '2,287.85 on 14/05/26. Avl Bal Rs 7,046.79.-SBI',
        amount: 2287.85,
        type: 'debit',
      );
    });

    test('SBI ATM withdrawal', () {
      expectTxn(
        'Dear SBI Customer, Rs.500 withdrawn at ICI ATM 1234SRY from A/cX1234 '
        'on 08Aug25 Transaction Number 1234. Available Balance Rs.5432.85. If '
        'not withdrawn by you, forward this SMS',
        amount: 500,
        type: 'debit',
      );
    });

    test('SBI Card e-mandate debit is a transaction', () {
      expectTxn(
        'Transaction Successful! Rs.10,699.00 has been debited to your SBI '
        'Credit Card XX1234 against recurring e-mandate registered by you at '
        'merchant site. Details: Merchant: OPENAICHATGPTSUBSCR SiHub ID: '
        'YfnPmWCAEi Trxn. Ref. No.: 1234 Date: 28-Sep-2026.',
        amount: 10699,
        type: 'debit',
        merchant: 'Openaichatgptsubscr',
      );
    });

    test('ICICI debit names the payee before "credited"', () {
      expectTxn(
        'ICICI Bank Acct XX123 debited for Rs 500.00 on 01-Nov-26; SWIGGY '
        'credited. UPI:612345678901. Call 18002662 for dispute.',
        amount: 500,
        type: 'debit',
        merchant: 'Swiggy',
      );
    });

    test('PhonePe payment keeps dotted names', () {
      expectTxn(
        "You've paid Rs.62 via PhonePe gift card to A.S.S NATTU MARANTHU "
        'KADAI on Oct 22, 2026 at 6:32:59 PM. Not you? Call us.',
        amount: 62,
        type: 'debit',
        merchant: 'A.s.s Nattu Maranthu Kadai',
      );
    });

    test('Indian grouping and INR prefix', () {
      expectTxn(
        'INR 1,25,000.50 credited to your account. Salary from ACME CORP '
        'Ref 998877',
        amount: 125000.50,
        type: 'credit',
      );
    });

    test('UPI handle merchant', () {
      final p = SmsParser.parse(
        'Rs.450.00 debited from A/c XX1234 on 12-03-26 to VPA swiggy@ybl '
        'Ref 123456. -HDFC Bank',
      );
      expect(p.amount, 450.0);
      expect(p.type, 'debit');
      expect(p.merchant, 'swiggy@ybl');
    });
  });

  group('not transactions', () {
    test('OTP for a card transaction', () {
      expectIgnored('OTP is 123456 for txn of INR 9441.64 at ANTHROPIC on '
          'HDFC Bank card ending 1234. Valid till 08:53. Do not share OTP');
    });
    test('declined card transaction', () {
      expectIgnored('TXN DECLINED: Rs.9441.64 on 27-07-26 at 20:50 on HDFC '
          'Bank Debit Card xx1234. Reason: Intl Online Limit Exceeded.');
    });
    test('upcoming EMI debit', () {
      expectIgnored('Rs 6,563.47 due on ICICI Bank Debit Card EMI Account '
          'XX1234 will be debited from the Account on or before 03-NOV-26.');
    });
    test('UPI collect request', () {
      expectIgnored('cardspay has requested Rs1234 frm u on Google Pay app. '
          'Once approved, money will be debited frm ur a/c -SBI');
    });
    test('card bill due', () {
      expectIgnored('Total of Rs 1234.47 & min of Rs 123.47 is due on ICICI '
          'Bank Credit Card XX1234. Pay at https://icici.co/x');
    });
    test('mandate registration notice', () {
      expectIgnored('Dear Cardholder, your payment e-Mandate set at merchant '
          'platform with your credit card ending 1234 has been registered. '
          'e-Mandate Limit Amount (INR): 12000.00, Frequency: monthly');
    });
    test('average balance notice', () {
      expectIgnored('Alert! HDFC Bank A/c XXXX1234 Avg. bal. maintained as on '
          '25-AUG-26: Rs 1234.23 Avoid non-maintenance charges');
    });
    test('scheduled AutoPay pre-debit notice', () {
      expectIgnored('Dear UPI User, UPI AutoPay for Google Play debit of '
          'Rs.3250.00 is scheduled on .07/09/26, abc@oksbi. Please ensure');
    });
    test('credit card bill payment confirmations', () {
      expectIgnored('Dear SBI Cardholder, payment of Rs. 10699.00 for your '
          'SBI Credit Card has been successfully processed. ref no : EKT5H.');
      expectIgnored('We have received payment of Rs.10,699.00 via UPI & the '
          'same has been credited to your SBI Credit Card.');
    });
    test('merchant receipt from an unknown sender', () {
      expect(
        SmsParser.isBankTransactionSms(
            'Payment of Rs. 706.82 for your JioHome connection through UPI '
            'Payments has been received',
            trustedSender: false),
        isFalse,
      );
    });
    test('plain OTP', () {
      expectIgnored('Your OTP is 482913. Do not share it.');
      expect(SmsParser.parse('Your OTP is 482913.').amount, isNull);
    });
    test('needs both amount and direction', () {
      expect(SmsParser.isBankTransactionSms('Rs 200 debited'), isTrue);
      expect(SmsParser.isBankTransactionSms('Rs 200 is your bill'), isFalse);
      expect(SmsParser.isBankTransactionSms('Payment debited today'), isFalse);
    });
    test('untrusted sender must name an account or card', () {
      expect(
        SmsParser.isBankTransactionSms('Rs 100 cashback credited!',
            trustedSender: false),
        isFalse,
      );
      expect(
        SmsParser.isBankTransactionSms('Rs 100 credited to your wallet balance',
            trustedSender: false),
        isTrue,
      );
    });
  });

  group('SmsSender', () {
    test('DLT header core and suffixes', () {
      expect(SmsSender.core('JX-SBIUPI-S'), 'SBIUPI');
      expect(SmsSender.core('AD-HDFCBK'), 'HDFCBK');
      expect(SmsSender.isPromotional('VM-HDFCBK-P'), isTrue);
      expect(SmsSender.isPromotional('VM-HDFCBK-S'), isFalse);
      expect(SmsSender.isPersonalNumber('+919876543210'), isTrue);
      expect(SmsSender.isPersonalNumber('JD-SBIUPI-S'), isFalse);
    });
    test('trusted match is by brand', () {
      expect(SmsSender.isTrusted('JX-SBIUPI-S', ['SBIUPI']), isTrue);
      expect(SmsSender.isTrusted('JM-JIONET-S', ['SBIUPI', 'HDFCBK']), isFalse);
    });
  });
}
