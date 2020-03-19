import 'dart:io';
import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my2fa/model.dart';
import 'package:sqflite/sqflite.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();

  Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "TestDB.db");
    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE Code ("
          "id INTEGER PRIMARY KEY,"
          "user TEXT,"
          "site TEXT,"
          "secret TEXT,"
          "digits TEXT,"
          "algorithm TEXT,"
          "issuer TEXT,"
          "period TEXT"
          ")");
    });
  }

  newCode(Code newCode) async {
    final db = await database;
    //get the biggest id in the table
    var table = await db.rawQuery("SELECT MAX(id)+1 as id FROM Code");
    int id = table.first["id"];
    //insert to the table using the new id
    var raw = await db.rawInsert(
        "INSERT Into Code (id,user,site,secret,digits,algorithm,issuer,period)"
        " VALUES (?,?,?,?,?,?,?,?)",
        [id, newCode.user, newCode.site, newCode.secret, newCode.digits, newCode.algorithm, newCode.issuer, newCode.period]);
    return raw;
  }

  updateCode(Code newCode) async {
    final db = await database;
    var res = await db.update("Code", newCode.toMap(),
        where: "id = ?", whereArgs: [newCode.id]);
    return res;
  }

  getCode(int id) async {
    final db = await database;
    var res = await db.query("Code", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? Code.fromMap(res.first) : null;
  }

  Future<List<Code>> getAllCodes() async {
    final db = await database;
    var res = await db.query("Code");
    List<Code> list =
        res.isNotEmpty ? res.map((c) => Code.fromMap(c)).toList() : [];
    return list;
  }

  deleteCode(int id) async {
    final db = await database;
    return db.delete("Code", where: "id = ?", whereArgs: [id]);
  }

  deleteAll() async {
    final db = await database;
    db.rawDelete("Delete * from Code");
  }
}
