import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';

/// Information about a single stored backup file.
class BackupInfo {
  final String path;
  final String name;
  final DateTime modified;
  final int sizeBytes;

  BackupInfo({
    required this.path,
    required this.name,
    required this.modified,
    required this.sizeBytes,
  });

  /// Human readable size, e.g. "1.4 MB".
  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Handles reliable database backups: automatic twice-daily snapshots kept in
/// the app folder, plus manual export to a user-chosen folder.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Keep ~7 days of automatic backups (2 per day).
  static const int _maxAutoBackups = 14;

  String _pad(int v) => v.toString().padLeft(2, '0');

  /// Two slots per day: morning (before 13:00) and evening.
  String _slotKey(DateTime now) => now.hour < 13 ? 'AM' : 'PM';

  String _autoFileName(DateTime now) {
    final date = '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
    return 'auto_${date}_${_slotKey(now)}.db';
  }

  /// Folder inside the app's support directory where auto backups live.
  /// Always writable without any OS permission prompt.
  Future<Directory> autoBackupDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Flushes the WAL then copies the database file to [destPath].
  Future<void> _copyDatabaseTo(String destPath) async {
    await _db.checkpoint();
    final dbPath = await _db.getDatabasePath();
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('Database file not found at $dbPath');
    }
    await dbFile.copy(destPath);
  }

  /// Creates an automatic backup if one hasn't been made for the current
  /// half-day slot yet. Safe to call repeatedly (on launch + on a timer).
  Future<bool> runAutoBackupIfDue() async {
    try {
      final dir = await autoBackupDir();
      final now = DateTime.now();
      final file = File(p.join(dir.path, _autoFileName(now)));
      if (await file.exists()) return false; // Already backed up this slot.

      await _copyDatabaseTo(file.path);
      await _pruneOldBackups();
      debugPrint('Auto backup created: ${file.path}');
      return true;
    } catch (e) {
      debugPrint('Auto backup error: $e');
      return false;
    }
  }

  Future<void> _pruneOldBackups() async {
    try {
      final dir = await autoBackupDir();
      final files = (await dir.list().toList())
          .whereType<File>()
          .where((f) =>
              p.basename(f.path).startsWith('auto_') &&
              f.path.endsWith('.db'))
          .toList();
      // File names sort chronologically, so oldest are first.
      files.sort((a, b) => a.path.compareTo(b.path));
      while (files.length > _maxAutoBackups) {
        final old = files.removeAt(0);
        try {
          await old.delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Prune backups error: $e');
    }
  }

  /// All stored auto backups, newest first.
  Future<List<BackupInfo>> listAutoBackups() async {
    try {
      final dir = await autoBackupDir();
      final files = (await dir.list().toList())
          .whereType<File>()
          .where((f) => f.path.endsWith('.db'))
          .toList();

      final infos = <BackupInfo>[];
      for (final f in files) {
        final stat = await f.stat();
        infos.add(BackupInfo(
          path: f.path,
          name: p.basename(f.path),
          modified: stat.modified,
          sizeBytes: stat.size,
        ));
      }
      infos.sort((a, b) => b.modified.compareTo(a.modified));
      return infos;
    } catch (e) {
      debugPrint('List backups error: $e');
      return [];
    }
  }

  /// Manual export to a user-chosen folder. Returns the created file path.
  Future<String> backupToDirectory(String directoryPath) async {
    final now = DateTime.now();
    final name =
        'mini_market_backup_${now.year}-${_pad(now.month)}-${_pad(now.day)}'
        '_${_pad(now.hour)}${_pad(now.minute)}.db';
    final dest = p.join(directoryPath, name);
    await _copyDatabaseTo(dest);
    return dest;
  }
}
