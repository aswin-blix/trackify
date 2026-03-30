import 'package:hive_flutter/hive_flutter.dart';
import '../models/bank_sms_message.dart';
import '../../core/constants/app_constants.dart';

class SmsRepository {
  Box<BankSmsMessage> get _box => Hive.box<BankSmsMessage>(kSmsMessagesBox);

  List<BankSmsMessage> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return list;
  }

  List<BankSmsMessage> getPending() {
    final list =
        _box.values.where((m) => m.status == SmsStatus.pending).toList();
    list.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return list;
  }

  Future<void> save(BankSmsMessage msg) async {
    await _box.put(msg.id, msg);
  }

  Future<void> updateStatus(String id, SmsStatus status) async {
    final msg = _box.get(id);
    if (msg != null) {
      msg.status = status;
      await msg.save();
    }
  }

  bool exists(String id) => _box.containsKey(id);

  Future<void> deleteAll() async => _box.clear();
}
