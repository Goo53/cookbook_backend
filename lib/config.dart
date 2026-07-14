//to load all settings once

import 'dart:io';
import 'package:dotenv/dotenv.dart' as dotenv;

class AppConfig {
  const AppConfig({
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUser,
    required this.dbPassword,
    required this.port,
    required this.apiToken,
  });

  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUser;
  final String dbPassword;
  final int port;
  final String apiToken;

  static AppConfig load() {
    final env = dotenv.DotEnv();

    if (File('.env').existsSync()) {
      env.load();
    }

    String? read(String key) => Platform.environment[key] ?? env[key];

    String requiredValue(String key) {
      final value = read(key);
      if (value == null || value.trim().isEmpty) {
        throw StateError('$key is required');
      }
      return value;
    }

    return AppConfig(
      dbHost: read('DB_HOST') ?? '127.0.0.1',
      dbPort: int.tryParse(read('DB_PORT') ?? '') ?? 5432,
      dbName: read('DB_NAME') ?? 'cookbook',
      dbUser: requiredValue('DB_USER'),
      dbPassword: requiredValue('DB_PASSWORD'),
      port: int.tryParse(read('PORT') ?? '') ?? 8080,
      apiToken: requiredValue('API_TOKEN'),
    );
  }
}
