/// Parses Indian bank / UPI / card alert SMS into amount, direction and
/// counterparty. Formats covered are taken from real alerts (SBI UPI, SBI
/// CBS, SBI ATM, SBI Card, HDFC multi-line UPI, HDFC card, ICICI, Kotak,
/// PhonePe); see test/sms_parser_test.dart.
class SmsParser {
  static const _num = r'([0-9][0-9,]*(?:\.[0-9]{1,2})?)';

  /// Amount written with a currency marker: Rs.450, Rs 450, INR 1,200.50,
  /// ₹99, Rs: 10.
  static final _currencyAmount = RegExp(
    r'(?:\brs\.?|\binr|₹)\s*:?\s*' + _num,
    caseSensitive: false,
  );

  /// Amount right after the verb, with or without a currency marker. SBI UPI
  /// alerts say "debited by 75.00" with no Rs at all.
  static final _verbAmount = RegExp(
    r'\b(?:debited|credited|withdrawn|spent|paid|sent|received)\s+'
    r'(?:by|with|for|of)?\s*(?:rs\.?|inr|₹)?\s*:?\s*'
    '$_num',
    caseSensitive: false,
  );

  /// Text just before an amount that marks it as a balance or limit.
  static final _balanceContext = RegExp(
    r'(?:bal(?:ance)?|limit|lmt|avl|available)[\s.:]*$',
    caseSensitive: false,
  );

  // "credit card" / "debit card" are product names, not directions.
  static final _strongDebit = RegExp(
    r'\b(?:debited|debit(?!\s*card)|spent|withdrawn|sent|purchase[d]?)\b|'
    r"\byou(?:'ve| have)? paid\b",
    caseSensitive: false,
  );
  static final _strongCredit = RegExp(
    r'\b(?:credited|credit(?!\s*card)|received|deposited|deposit|refund(?:ed)?|reversed|reversal)\b',
    caseSensitive: false,
  );
  static final _weakDebit = RegExp(
    r'\b(?:paid|payment|dr)\b',
    caseSensitive: false,
  );
  static final _weakCredit = RegExp(r'\bcr\b', caseSensitive: false);

  /// Messages that mention money and a direction but are not a completed
  /// transaction: OTPs, dues, collect requests, declines, mandates.
  static final _notATransaction = RegExp(
    [
      r'\botp\b',
      r'one[- ]time password',
      r'verification code',
      r'\b(?:is|are|amount|amt|payment|bill)\s+due\b',
      r'\bdue (?:on|by|date)\b',
      r'\boverdue\b',
      r'\bmin(?:imum)?\.? (?:amount|amt)\b',
      r'\bwill be (?:debited|credited|deducted)\b',
      r'\b(?:is|been) scheduled\b',
      // Card bill payment confirmations: a transfer, the spends were
      // already counted when the card was used.
      r'\bpayment of (?:rs|inr|₹)[\s\S]{0,80}?\bcredit card\b[\s\S]{0,40}?\b(?:processed|received)\b',
      r'\breceived (?:your )?payment\b[\s\S]{0,120}?\bcredit card\b',
      r'\bhas requested\b',
      r'\brequested (?:rs|inr|₹)',
      r'\bcollect request\b',
      r'\bdeclined\b',
      r'\bfailed\b',
      r'\bunsuccessful\b',
      r"\bcould ?n[o']?t be (?:completed|processed)\b",
      r'\bavg\.? bal',
      r'\bautopay active\b',
      // Registration notices, not the "debited ... against e-mandate" alert.
      r'\bmandate\b[^.]*\bhas been (?:registered|created|set up)\b',
      r'\bpre-?approved\b',
      r'\beligible\b',
    ].join('|'),
    caseSensitive: false,
  );

  /// Bank-alert verbs and account references, both required for senders not
  /// on the trusted list so promotions and merchant receipts are skipped.
  static final _bankVerb = RegExp(
    r'\b(?:debited|credited|withdrawn|spent)\b',
    caseSensitive: false,
  );

  static final _accountMarker = RegExp(
    r'\b(?:a/?c|acct|account|card|upi|vpa|wallet|bank|neft|imps|rtgs|atm)\b',
    caseSensitive: false,
  );

  static const _stop =
      r'(?=\s+(?:on|ref|refno|ref\s*no|upi|bal|avl|from|via|using|txn|if|not|info)\b|\.(?:\s|$)|[;(\n]|$)';

  /// Ordered from most to least specific; the first usable hit wins.
  static final _merchantPatterns = <RegExp>[
    // SBI UPI: "trf to SHYLAJA T Refno", SBI credit: "transfer from X Ref No"
    RegExp(r'\b(?:trf|transfer(?:red)?)\s+(?:to|from)\s+(.+?)' + _stop,
        caseSensitive: false),
    // ICICI debit: "...; SWIGGY credited."
    RegExp(r';\s*([^;.\n]+?)\s+credited\b', caseSensitive: false),
    // SBI CBS: "has credit for BY SALARY of Rs", "a debit by transfer of Rs"
    RegExp(r'\b(?:credit|debit)\s+(?:for|by)\s+(.+?)\s+of\s+(?:rs|inr|₹)',
        caseSensitive: false),
    // SBI Card mandate: "Merchant: OPENAICHATGPTSUBSCR SiHub ID"
    RegExp(
        r'\bmerchant\s*:\s*(.+?)(?=\s+(?:sihub|si-hub|trxn|description)\b|[,\n]|$)',
        caseSensitive: false),
    // UPI handle
    RegExp(r'\bvpa\s+([\w.\-]+@[\w.\-]+)', caseSensitive: false),
    // Card spend / ATM: "At ANTHROPIC* CLAUDE SUB On", "withdrawn at PNB ATM"
    RegExp(r'\bat\s+(.+?)' + _stop, caseSensitive: false),
    // HDFC multi-line UPI: a line that starts with "To NAME"
    RegExp(r'^\s*to\s+(.+?)\s*$', caseSensitive: false, multiLine: true),
    // "paid Rs.62 ... to NAME on", "Sent Rs.20 ... to merchant@upi on"
    RegExp(r'\bto\s+(.+?)' + _stop, caseSensitive: false),
    // "received from NAME", "from VPA" handled above
    RegExp(r'\bfrom\s+(.+?)' + _stop, caseSensitive: false),
    // Axis: "UPI/P2M/123456/SWIGGY"
    RegExp(r'\bUPI/P2[AM]/\d+/([^/\s]+)', caseSensitive: false),
    // HDFC "Info: ... NAME."
    RegExp(r'\binfo\s*:\s*(.+?)(?=\.\s|\.$|\n|$)', caseSensitive: false),
  ];

  /// Words that mean the capture is our own account, not a counterparty.
  static final _selfReference = RegExp(
    r'\b(?:a/?c|acct|account|your|ur|you|bank card|debit card|credit card|card)\b',
    caseSensitive: false,
  );

  /// Parse a raw SMS body and return structured data.
  static ParsedSms parse(String body) {
    return ParsedSms(
      amount: _extractAmount(body),
      type: _extractType(body),
      merchant: _extractMerchant(body),
    );
  }

  static double? _toAmount(String raw) =>
      double.tryParse(raw.replaceAll(',', ''));

  static double? _extractAmount(String body) {
    final verb = _verbAmount.firstMatch(body);
    if (verb != null) {
      final v = _toAmount(verb.group(1)!);
      if (v != null && v > 0) return v;
    }
    double? first;
    for (final m in _currencyAmount.allMatches(body)) {
      final v = _toAmount(m.group(1)!);
      if (v == null || v <= 0) continue;
      first ??= v;
      final before = body.substring(m.start < 24 ? 0 : m.start - 24, m.start);
      if (!_balanceContext.hasMatch(before)) return v;
    }
    return first;
  }

  static int? _firstIndex(RegExp re, String body) => re.firstMatch(body)?.start;

  static String? _extractType(String body) {
    final d = _firstIndex(_strongDebit, body);
    final c = _firstIndex(_strongCredit, body);
    if (d != null && c != null) return d <= c ? 'debit' : 'credit';
    if (d != null) return 'debit';
    if (c != null) return 'credit';
    if (_weakDebit.hasMatch(body)) return 'debit';
    if (_weakCredit.hasMatch(body)) return 'credit';
    return null;
  }

  static String? _extractMerchant(String body) {
    for (final pattern in _merchantPatterns) {
      for (final match in pattern.allMatches(body)) {
        final cleaned = _cleanMerchant(match.group(1) ?? '');
        if (cleaned != null) return cleaned;
      }
    }
    return null;
  }

  static String? _cleanMerchant(String raw) {
    if (_selfReference.hasMatch(raw)) return null;
    // "at 6:32:59 PM", "on 12/03/26" are times and dates, not payees.
    if (RegExp(r'^\s*\d{1,4}[:/\-]\d{1,2}').hasMatch(raw)) return null;
    var tokens = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        // Drop reference numbers and masked account tokens.
        .where((t) => !RegExp(r'\d{4,}|[xX*]{2,}\d|#').hasMatch(t))
        .toList();
    if (tokens.isNotEmpty && tokens.first.toUpperCase() == 'BY') {
      tokens = tokens.sublist(1);
    }
    var s = tokens.join(' ').replaceAll(RegExp(r'^[\s\-:*]+|[\s\-:*.,]+$'), '');
    if (s.length < 2) return null;
    if (s.length > 40) s = s.substring(0, 40).trim();
    // Title-case shouty names, leave UPI handles and mixed case alone.
    if (s == s.toUpperCase() && !s.contains('@')) {
      s = s
          .toLowerCase()
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    return s;
  }

  /// True when [body] reads as a completed debit or credit. Messages from
  /// senders outside the trusted list must also name an account, card or
  /// wallet and use a bank verb, which keeps promotions and merchant
  /// receipts out.
  static bool isBankTransactionSms(String body, {bool trustedSender = true}) {
    if (_notATransaction.hasMatch(body)) return false;
    if (_extractAmount(body) == null || _extractType(body) == null) {
      return false;
    }
    if (trustedSender) return true;
    // Unknown senders must read like a bank alert: a bank verb plus an
    // account reference. Merchant receipts ("payment ... received") fail.
    return _bankVerb.hasMatch(body) && _accountMarker.hasMatch(body);
  }

  static final _cashWithdrawal = RegExp(
    r'\batm\b|\bcash\s*(?:withdrawal|withdrawn|wdl)\b|\batm\s*wdl\b|'
    r'\bwithdrawn\s+(?:at|from)\b',
    caseSensitive: false,
  );

  /// True when a debit [body] is a cash withdrawal (ATM, cash WDL). That
  /// money moves to cash in hand; it is not spent yet.
  static bool isCashWithdrawal(String body) => _cashWithdrawal.hasMatch(body);
}

class ParsedSms {
  final double? amount;
  final String? type; // 'debit' | 'credit'
  final String? merchant;

  const ParsedSms({this.amount, this.type, this.merchant});
}

/// Classifies SMS sender addresses. Indian commercial SMS arrive from DLT
/// headers such as "JX-SBIUPI-S" or "AD-HDFCBK"; personal numbers are digits.
class SmsSender {
  static final _dlt =
      RegExp(r'^[A-Z]{2}-([A-Z0-9]{3,9})(?:-([A-Z]))?$', caseSensitive: false);
  static final _phone = RegExp(r'^\+?[0-9][0-9 \-]{5,}$');

  /// The brand part of a header ("SBIUPI" for "JX-SBIUPI-S").
  static String core(String address) {
    final m = _dlt.firstMatch(address.trim());
    return (m?.group(1) ?? address.trim()).toUpperCase();
  }

  /// Personal numbers can't send genuine bank alerts in India and are a
  /// common source of fake "credited" texts, so they are skipped.
  static bool isPersonalNumber(String address) =>
      _phone.hasMatch(address.trim());

  /// DLT "-P" suffix marks promotional traffic.
  static bool isPromotional(String address) =>
      _dlt.firstMatch(address.trim())?.group(2)?.toUpperCase() == 'P';

  static bool isTrusted(String address, Iterable<String> trustedIds) {
    final c = core(address);
    final upper = address.toUpperCase();
    return trustedIds.any((id) {
      final i = id.trim().toUpperCase();
      return i.isNotEmpty && (c.contains(i) || upper.contains(i));
    });
  }
}
