import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../models/local_song.dart';

class MusicDatabase {
  static final MusicDatabase instance = MusicDatabase._init();
  static Database? _database;

  MusicDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('music.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        artist TEXT,
        coverPath TEXT
      )
    ''');
  }

  Future<void> insertSong(LocalSong song) async {
    final db = await instance.database;
    await db.insert(
      'local_songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }


  Future<List<LocalSong>> fetchSongs({int? limit, int? offset}) async {
    final db = await instance.database;
    final result = await db.query(
      'local_songs',
      limit: limit,
      offset: offset,
      orderBy: 'LOWER(title) ASC',
    );
    return result.map((json) => LocalSong.fromMap(json)).toList();
  }

  Future<int> deleteAllSongs() async{
    final db=await instance.database;
    return await db.delete('local_songs');
  }

  Future<int> getTotalSongCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM local_songs');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}