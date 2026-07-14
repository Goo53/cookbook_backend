import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'db.dart';
import 'meal_api.dart';
import 'auth_middleware.dart';
import 'config.dart';

void main() async {
  final config = AppConfig.load();
  try {
    await Db.init(config);
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
    ..mount('/api', mealRouter.call)
    ..get('/test', (Request request) => Response.ok('Test OK'));

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(authMiddleware(config.apiToken)) //global authorization
      .addHandler(app.call);

  final server = await io.serve(handler, '0.0.0.0', config.port);

  print('Server running on http://${server.address.host}:${server.port}');
}
