import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'app_logger.dart';

/// Copies images picked from the gallery into the app's documents directory.
///
/// `image_picker` returns paths inside a cache directory that the OS may purge
/// at any time, so storing those paths directly leaves dangling references.
class ImageStore {
  const ImageStore._();

  /// Copies [sourcePath] into `<documents>/<subdir>/` and returns the new path.
  /// Returns null if the copy fails.
  static Future<String?> persist(String sourcePath,
      {required String subdir}) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/$subdir');
      if (!await dir.exists()) await dir.create(recursive: true);

      final ext = _extension(sourcePath);
      final dest = File('${dir.path}/${const Uuid().v4()}$ext');
      await File(sourcePath).copy(dest.path);
      return dest.path;
    } catch (e, stack) {
      AppLogger.e('ImageStore', 'Failed to persist image', e, stack);
      return null;
    }
  }

  /// Deletes a previously persisted file, ignoring errors.
  static Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Best effort cleanup of a stale copy.
    }
  }

  /// True if [path] points at a readable file.
  static bool exists(String? path) {
    if (path == null || path.isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  static String _extension(String path) {
    final name = path.split('/').last.split('\\').last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '.jpg';
    final ext = name.substring(dot).toLowerCase();
    return ext.length <= 5 ? ext : '.jpg';
  }
}
