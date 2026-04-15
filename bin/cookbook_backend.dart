import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'package:cookbook_backend/db.dart';
import 'package:cookbook_backend/meal_api.dart';

void main() async {
  await Db.init();

  final api = MealApi();

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(api.router.call);

  final server = await io.serve(handler, '0.0.0.0', 8080);

  print('🚀 Server running on port ${server.port}');
}
