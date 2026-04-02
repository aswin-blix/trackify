class SmsParser {
  static final _amountRegex = RegExp(
    r'(?:rs\.?|inr|₹)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final _debitPatterns = [
    RegExp(r'\b(?:debited|debit|spent|paid|payment|withdrawn|purchase|sent)\b',
        caseSensitive: false),
    RegExp(r'\bdr\b', caseSensitive: false),
  ];

  static final _creditPatterns = [
    RegExp(r'\b(?:credited|credit|received|deposited|refund)\b',
        caseSensitive: false),
    RegExp(r'\bcr\b', caseSensitive: false),
  ];

  static final _merchantPatterns = [
    // VPA matches (UPI)
    RegExp(r'(?:VPA|vpa)\s+([A-Za-z0-9@\.\-_]+)', caseSensitive: false),

    // Transfer/Trf to/from
    RegExp(
        r'(?:transfer from|trf from|received from)\s+([^\r\n]+?)\s+(?:Ref|ref|Refno|Ref No|Ref No\.|\-)',
        caseSensitive: false),
    RegExp(
        r'(?:transfer to|trf to|sent to)\s+([^\r\n]+?)\s+(?:Ref|ref|Refno|Ref No|Ref No\.|\-)',
        caseSensitive: false),

    // Specific location "At ... On/Bal"
    RegExp(r'\b(?:at|At)\s+([^\r\n]+?)\s+(?:On|on|Bal|bal|Ref|ref|\.)\b',
        caseSensitive: false),

    // Specific recipient "To ... On/Ref"
    RegExp(r'\b(?:to|To|TO)\s+([^\r\n]+?)\s+(?:On|on|Bal|bal|Ref|ref|\.)\b',
        caseSensitive: false),

    // Generic fallbacks
    RegExp(r'(?:at|to|from|for|via)\s+([A-Z][A-Za-z0-9\s&\-\.]{2,30})',
        caseSensitive: false),
    RegExp(r'(?:merchant|shop|store)[\s:]+([A-Za-z0-9\s&\-\.]{2,30})',
        caseSensitive: false),
  ];

  /// Parse a raw SMS body and return structured data
  static ParsedSms parse(String body) {
    final amount = _extractAmount(body);
    final type = _extractType(body);
    final merchant = _extractMerchant(body);

    return ParsedSms(
      amount: amount,
      type: type,
      merchant: merchant,
    );
  }

  static double? _extractAmount(String body) {
    final match = _amountRegex.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll(',', '');
      return double.tryParse(raw);
    }
    return null;
  }

  static String? _extractType(String body) {
    for (final pattern in _debitPatterns) {
      if (pattern.hasMatch(body)) return 'debit';
    }
    for (final pattern in _creditPatterns) {
      if (pattern.hasMatch(body)) return 'credit';
    }
    return null;
  }

  static String? _extractMerchant(String body) {
    for (final pattern in _merchantPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final raw = match.group(1)?.trim() ?? '';
        if (raw.length > 2 && raw.length < 40) {
          // Capitalize nicely
          return raw
              .split(' ')
              .map((w) => w.isEmpty
                  ? w
                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
              .join(' ');
        }
      }
    }
    return null;
  }

  /// Check if a message looks like a bank transaction SMS
  static bool isBankTransactionSms(String body) {
    final hasAmount = _amountRegex.hasMatch(body);
    final hasType = _debitPatterns.any((p) => p.hasMatch(body)) ||
        _creditPatterns.any((p) => p.hasMatch(body));
    return hasAmount && hasType;
  }
}

class ParsedSms {
  final double? amount;
  final String? type; // 'debit' | 'credit'
  final String? merchant;

  const ParsedSms({this.amount, this.type, this.merchant});
}
