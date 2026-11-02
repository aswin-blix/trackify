import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/bank_sms_message.dart';
import '../../data/repositories/sms_repository.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/sms_parser.dart';

/// Result of one inbox scan.
class SmsSyncResult {
  final int scanned;
  final int added;
  final String? error;

  const SmsSyncResult({this.scanned = 0, this.added = 0, this.error});
}

class SmsService {
  static const _channel = MethodChannel('com.blixcode.trackify/sms');

  /// How far back a scan looks. Already-seen messages are skipped by id, so
  /// rescanning the window is cheap and catches anything missed earlier.
  static const scanWindow = Duration(days: 90);

  final SmsRepository _repo;

  SmsService(this._repo);

  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    return Permission.sms.isGranted;
  }

  /// Reads recent inbox SMS and stores new bank transaction messages.
  /// [senderIds] are extra trusted headers on top of [kDefaultBankSenders].
  Future<SmsSyncResult> syncSms(List<String> senderIds) async {
    if (!await hasPermission()) {
      return const SmsSyncResult(error: 'SMS permission not granted');
    }

    final trusted = {...kDefaultBankSenders, ...senderIds};
    final since = DateTime.now().subtract(scanWindow).millisecondsSinceEpoch;

    List<Map<Object?, Object?>> rows;
    try {
      final raw = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'queryInbox',
        {'sinceMillis': since, 'limit': 5000},
      );
      rows = raw ?? const [];
    } on PlatformException catch (e, stack) {
      AppLogger.e('SmsService', 'Inbox query failed: ${e.code}', e, stack);
      return SmsSyncResult(error: e.message ?? e.code);
    }

    await _reparsePending(trusted);

    var added = 0;
    for (final row in rows) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty || _repo.exists(id)) continue;

      final address = (row['address'] as String?) ?? '';
      final body = (row['body'] as String?) ?? '';
      if (address.isEmpty || body.isEmpty) continue;
      if (SmsSender.isPersonalNumber(address)) continue;
      if (SmsSender.isPromotional(address)) continue;

      final isTrusted = SmsSender.isTrusted(address, trusted);
      if (!SmsParser.isBankTransactionSms(body, trustedSender: isTrusted)) {
        continue;
      }

      final date = DateTime.fromMillisecondsSinceEpoch(
          (row['date'] as num?)?.toInt() ?? 0);
      final parsed = SmsParser.parse(body);
      await _repo.save(BankSmsMessage(
        id: id,
        sender: address,
        rawBody: body,
        parsedAmount: parsed.amount,
        parsedType: parsed.type,
        parsedMerchant: parsed.merchant,
        parsedDate: date,
        receivedAt: date,
      ));
      added++;
    }

    AppLogger.i('SmsService', 'Scanned ${rows.length} SMS, added $added');
    return SmsSyncResult(scanned: rows.length, added: added);
  }

  /// Re-runs the current parser over messages still waiting for review, so
  /// entries stored by an older parser get fixed amounts and merchants, and
  /// ones that turn out not to be transactions (OTPs, dues) are dropped.
  Future<void> _reparsePending(Set<String> trusted) async {
    for (final msg in _repo.getPending()) {
      final ok = SmsParser.isBankTransactionSms(
        msg.rawBody,
        trustedSender: SmsSender.isTrusted(msg.sender, trusted),
      );
      if (!ok) {
        await _repo.delete(msg.id);
        continue;
      }
      final p = SmsParser.parse(msg.rawBody);
      msg
        ..parsedAmount = p.amount
        ..parsedType = p.type
        ..parsedMerchant = p.merchant;
      await msg.save();
    }
  }
}
