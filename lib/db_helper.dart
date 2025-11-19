import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;
  static Future<Database> get db async => _db ??= await initDB();

  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'SafeTravel_DBV2.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
        CREATE TABLE vehicletype (
          TypeID TEXT PRIMARY KEY,
          Type TEXT NOT NULL,
          Image TEXT
        );
      ''');
        await db.execute('''
        CREATE TABLE vehicles (
          vehicle_id TEXT PRIMARY KEY,
          uid TEXT NOT NULL,
          TypeID TEXT NOT NULL,
          vehicle_number TEXT NOT NULL,
          vehicle_name TEXT,
          description TEXT,
          created_at TEXT,
          sync_status TEXT,
          deleted INTEGER DEFAULT 0
        );
      ''');
        await db.execute('''
        CREATE TABLE travels (
          travel_id TEXT PRIMARY KEY,
          vehicle_id TEXT NOT NULL,
          travel_from TEXT,
          travel_to TEXT,
          price REAL,
          travel_time TEXT,
          created_at TEXT,
          sync_status TEXT,
          deleted INTEGER DEFAULT 0
        );
      ''');
      },
    );
  }

  // ---------- vehicletype ----------
  static Future<void> upsertVehicleTypes(List<dynamic> rows) async {
    final d = await db;
    final batch = d.batch();
    for (final r in rows) {
      batch.insert('vehicletype', {
        'TypeID': r['TypeID'].toString(),
        'Type': r['Type']?.toString(),
        'Image': r['Image']?.toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getAllTypes() async {
    final d = await db;
    return d.query('vehicletype', orderBy: 'TypeID');
  }

  // ---------- vehicles ----------
  static Future<Map<String, dynamic>?> findVehicleByNumber(
    String number,
    String uid,
  ) async {
    final d = await db;
    final res = await d.query(
      'vehicles',
      where: 'vehicle_number = ? AND uid = ?',
      whereArgs: [number, uid],
      limit: 1,
    );
    return res.isEmpty ? null : res.first;
  }

  static Future<void> insertVehicle(Map<String, dynamic> v) async {
    final d = await db;
    await d.insert('vehicles', v, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getUserVehicles(String uid) async {
    final d = await db;
    return d.query(
      'vehicles',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'created_at DESC',
    );
  }

  static void strg() async {
    final d = await db;
    final schema = await d.rawQuery('PRAGMA table_info(vehicles)');
    print(schema);
  }

  // ---------- travels ----------
  static Future<void> insertTravel(Map<String, dynamic> t) async {
    final d = await db;
    await d.insert('travels', t, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getTravelsForUser(
    String uid,
  ) async {
    final d = await db;
    return d.rawQuery(
      '''
      SELECT *,v.deleted as VeDelete
      FROM (
          SELECT *
          FROM travels
      ) AS t
      INNER JOIN vehicles v  ON t.vehicle_id = v.vehicle_id
      INNER JOIN vehicletype vt ON v.TypeID = vt.TypeID
      WHERE v.uid = ?
      AND t.travel_time = (
          SELECT MAX(travel_time)
          FROM travels t2
          WHERE t2.vehicle_id = t.vehicle_id and t2.deleted=0
      )
      AND v.deleted=0 AND vt.TypeID!='ZOther'
      ORDER BY t.created_at DESC;

    ''',
      [uid],
    );
  }

  static Future<List<Map<String, dynamic>>> OtherVehiclesForUser(
    String uid,
  ) async {
    final d = await db;
    return d.rawQuery(
      '''
      SELECT *,v.deleted as VeDelete
      FROM (
          SELECT *
          FROM travels
      ) AS t
      INNER JOIN vehicles v  ON t.vehicle_id = v.vehicle_id
      INNER JOIN vehicletype vt ON v.TypeID = vt.TypeID
      WHERE v.uid = ?
      AND t.travel_time = (
          SELECT MAX(travel_time)
          FROM travels t2
          WHERE t2.vehicle_id = t.vehicle_id and t2.deleted=0
      )
      AND v.deleted=0 AND vt.TypeID='ZOther'
      ORDER BY t.created_at DESC;

    ''',
      [uid],
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingTravels() async {
    final d = await db;
    return d.query('travels', where: 'sync_status != ?', whereArgs: ['synced']);
  }

  static Future<void> markTravelSynced(String id) async {
    final d = await db;
    await d.update(
      'travels',
      {'sync_status': 'synced'},
      where: 'travel_id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingVehicles() async {
    final d = await db;
    return d.query(
      'vehicles',
      where: 'sync_status != ?',
      whereArgs: ['synced'],
    );
  }

  static Future<void> markVehicleSynced(String id) async {
    final d = await db;
    await d.update(
      'vehicles',
      {'sync_status': 'synced'},
      where: 'vehicle_id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> upsertVehicleList(List<dynamic> rows) async {
    final d = await db;
    final batch = d.batch();
    for (final r in rows) {
      batch.insert('vehicles', {
        'vehicle_id': r['vehicle_id'],
        'uid': r['uid'],
        'TypeID': r['TypeID'],
        'vehicle_number': r['vehicle_number'],
        'vehicle_name': r['vehicle_name'],
        'description': r['description'],
        'created_at': r['created_at'],
        'sync_status': 'synced',
        'deleted': r['deleted'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> upsertTravelList(List<dynamic> rows) async {
    final d = await db;
    final batch = d.batch();
    for (final r in rows) {
      batch.insert('travels', {
        'travel_id': r['travel_id'],
        'vehicle_id': r['vehicle_id'],
        'travel_from': r['travel_from'],
        'travel_to': r['travel_to'],
        'price': r['price'],
        'travel_time': r['travel_time'],
        'created_at': r['created_at'],
        'sync_status': 'synced',
        'deleted': r['deleted'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
