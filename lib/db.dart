// lib/db.dart
import 'package:cookbook_backend/config.dart';
import 'package:postgres/postgres.dart';

class Db {
  static late PostgreSQLConnection connection;

  /// Initialize the database connection
  static Future<void> init(AppConfig config) async {
    connection = PostgreSQLConnection(
      config.dbHost,
      config.dbPort,
      config.dbName,
      username: config.dbUser,
      password: config.dbPassword,
    );

    try {
      await connection.open();
      print(
        'DB connected: ${config.dbUser}@${config.dbHost}:${config.dbPort}/${config.dbName}',
      );
    } catch (e, s) {
      print('DB connection failed: $e\n$s');
      rethrow;
    }
  }
}
