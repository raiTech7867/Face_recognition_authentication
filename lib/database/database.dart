import 'dart:io';
import 'package:facedetectionattandanceapp/models/user_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final _databaseName = "MyDatabase.db";
  static final _databaseVersion = 1;

  static final table = 'users';
  static final columnId = 'id';
  static final columnUser = 'user';
  static final columnPassword = 'password';
  static final columnModelData = 'model_data';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnUser TEXT NOT NULL,
            $columnPassword TEXT NOT NULL,
            $columnModelData TEXT NOT NULL UNIQUE
          )
          ''');
  }

  Future<int> insert(User user) async {
    Database db = await instance.database;
    print("tableinsertData====${user.toMap()}");
    return await db.insert(table, user.toMap());
  }

  Future<List<User>> queryAllUsers() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> users = await db.query(table);
    return users.map((u) => User.fromMap(u)).toList();
  }
  Future<List> getcount(List predictedData) async {
    Database db = await instance.database;
    var dbclient = await db;
    List?  count = await dbclient.rawQuery("SELECT COUNT(*) FROM $table WHERE $columnModelData=$predictedData");
    return count;
  }
  Future<int> deleteAll() async {
    Database db = await instance.database;
    return await db.delete(table);
  }
}
