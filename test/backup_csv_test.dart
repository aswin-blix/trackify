import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/data/repositories/backup_repository.dart';

void main() {
  group('BackupRepository.csvEscape', () {
    test('wraps values in quotes', () {
      expect(BackupRepository.csvEscape('Food'), '"Food"');
    });

    test('keeps commas and newlines inside the field', () {
      expect(
        BackupRepository.csvEscape('Bills, Utilities\nand more'),
        '"Bills, Utilities\nand more"',
      );
    });

    test('doubles embedded quotes', () {
      expect(BackupRepository.csvEscape('say "hi"'), '"say ""hi"""');
    });

    test('neutralises spreadsheet formula injection', () {
      expect(BackupRepository.csvEscape('=SUM(A1:A9)'), '"\'=SUM(A1:A9)"');
      expect(BackupRepository.csvEscape('+cmd'), '"\'+cmd"');
      expect(BackupRepository.csvEscape('-5 coffee'), '"\'-5 coffee"');
      expect(BackupRepository.csvEscape('@user'), '"\'@user"');
    });

    test('leaves empty strings as an empty quoted field', () {
      expect(BackupRepository.csvEscape(''), '""');
    });
  });

  test('BackupRepository.fileName strips directories on both separators', () {
    expect(BackupRepository.fileName('/a/b/backup_1.json'), 'backup_1.json');
    expect(BackupRepository.fileName(r'C:\a\b\backup_1.json'), 'backup_1.json');
  });
}
