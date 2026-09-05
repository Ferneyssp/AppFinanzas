import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/movimiento.dart';

/// Servicio de persistencia local basado en SQLite (sqflite).
///
/// Se eligió SQLite sobre Hive/SharedPreferences para los movimientos
/// porque el modelo es relacional (filtros por tipo, categoría y fecha,
/// ordenamientos y agregaciones) y SQLite ofrece consultas SQL nativas
/// eficientes para ese propósito. Las preferencias simples (tema,
/// paleta, alias) se manejan aparte con SharedPreferences, ver
/// [PreferenciasService].
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static const _dbName = 'finanzas_student.db';
  static const _dbVersion = 1;
  static const tableMovimientos = 'movimientos';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableMovimientos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tipo TEXT NOT NULL,
            descripcion TEXT NOT NULL,
            categoria TEXT NOT NULL,
            monto REAL NOT NULL,
            fecha TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertarMovimiento(Movimiento movimiento) async {
    final db = await database;
    return db.insert(
      tableMovimientos,
      movimiento.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> actualizarMovimiento(Movimiento movimiento) async {
    final db = await database;
    return db.update(
      tableMovimientos,
      movimiento.toMap(),
      where: 'id = ?',
      whereArgs: [movimiento.id],
    );
  }

  Future<int> eliminarMovimiento(int id) async {
    final db = await database;
    return db.delete(tableMovimientos, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Movimiento>> obtenerTodos() async {
    final db = await database;
    final rows = await db.query(tableMovimientos, orderBy: 'fecha DESC, id DESC');
    return rows.map(Movimiento.fromMap).toList();
  }

  /// Elimina todos los movimientos. Utilizado para "limpiar datos de
  /// demostración" o reiniciar la aplicación desde Ajustes.
  Future<void> eliminarTodos() async {
    final db = await database;
    await db.delete(tableMovimientos);
  }

  Future<void> cerrar() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
