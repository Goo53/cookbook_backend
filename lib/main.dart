import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'db.dart';
import 'meal_api.dart';
import 'auth_middleware.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

void main() async {
  final env = dotenv.DotEnv()..load();
  final port = int.tryParse(env['PORT'] ?? '8080') ?? 8080;
  try {
    await Db.init();
  } catch (e) {
    print('Database init failed: $e');
    rethrow;
  }

  print('Creating MealApi...');
  final mealApi = MealApi();
  print('MealApi created, getting router...');
  final mealRouter = mealApi.router;
  print('Router created with routes');

  final app = Router()
    ..mount('/api', mealRouter)
    ..get('/test', (Request request) => Response.ok('Test OK'));

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(authMiddleware()) //global authorization
      .addHandler(app.call);

  final server = await io.serve(handler, '0.0.0.0', port);

  print('Server running on http://${server.address.host}:${server.port}');
}
