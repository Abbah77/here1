import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import '../security/encryption_service.dart';

class EncryptedDatabaseConnection {

  static QueryExecutor create(String filename, EncryptionService encryptionService) {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, filename));

      final cachebase = await getTemporaryDirectory();
      sql.sqlite3.tempDirectory = cachebase.path;

      return NativeDatabase.createInBackground(
        file,
        setup: (db) async {
          final dbKey = await encryptionService.getDatabaseKey();

          db.execute("PRAGMA key = '$dbKey'");

          try {
            db.select('SELECT count(*) FROM sqlite_master');
          } catch (e) {
            rethrow;
          }

          db.execute('PRAGMA secure_delete = ON');
          db.execute('PRAGMA cipher_page_size = 4096');
          db.execute('PRAGMA journal_mode = WAL');
        },
      );
    });
  }
}