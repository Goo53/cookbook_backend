import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'db.dart';
import 'models/meal.dart';
import 'models/meal_mapper.dart';

class MealApi {
  Router get router {
    final router = Router();
    router.get('/meals', _getMeals);
    router.get('/meals/filter', _filterMeals);
    router.get('/meals/<id>', _selectMeal);
    router.get('/favorites', _getFavorite);
    router.post('/meals', _createMeal);
    router.post('/favorites/<id>', _addFavorite);
    router.put('/meals/<id>', _editMeal);
    router.delete('/meals/<id>', _deleteMeal);
    router.delete('/favorites/<id>', _deleteFavorite);
    return router;
  }

  Future<Response> _getMeals(Request request) async {
    try {
      // Fetch all meals
      final result = await Db.connection.mappedResultsQuery(
        'SELECT * FROM meals',
      );

      // Filter out empty rows and map each row to Meal
      final meals = result
          .where((row) => row.values.isNotEmpty)
          .map((row) => mapRowToMeal(row.values.first))
          .toList();

      // Return JSON
      return Response.ok(
        jsonEncode(meals.map((m) => mealToJson(m)).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, s) {
      print('Error fetching meals: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _selectMeal(Request request, String id) async {
    try {
      final result = await Db.connection.mappedResultsQuery(
        'SELECT * FROM meals WHERE id = @id',
        substitutionValues: {'id': id.toString()},
      );
      if (result.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Meal not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final rowMap = result.firstWhere(
        (row) => row.isNotEmpty,
        orElse: () => {},
      );
      if (rowMap.isEmpty) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Invalid DB row structure'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final meal = mapRowToMeal(rowMap.values.first);

      return Response.ok(
        jsonEncode(mealToJson(meal)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, s) {
      print('Error fetching meal: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Server error'}),
      );
    }
  }
  //values.first won't crash; empty DB throws 500; fields parsed; JSON Arrays converted to List<String> (categories, steps, indgredients)

  Future<Response> _filterMeals(Request request) async {
    try {
      final parameters = request.url.queryParameters;
      final whereClauses = <String>[];
      final values = <String, dynamic>{};

      //filter via Category
      if (parameters.containsKey('category')) {
        whereClauses.add('categories ? @category');
        values['category'] = parameters['category'];
      }
      //filter via bool
      if (parameters.containsKey('vegetarian')) {
        whereClauses.add('is_vegetarian = @vegetarian');
        values['vegetarian'] =
            parameters['vegetarian']?.toLowerCase() == 'true';
      }
      if (parameters.containsKey('meat')) {
        whereClauses.add('is_meat = @meat');
        values['meat'] = parameters['meat']?.toLowerCase() == 'true';
      }
      //filter via time
      if (parameters.containsKey('maxDuration')) {
        whereClauses.add('duration <= @maxDuration');
        values['maxDuration'] = int.parse(parameters['maxDuration']!);
      }

      final whereSql = whereClauses.isNotEmpty
          ? 'WHERE ${whereClauses.join(' AND ')}'
          : '';
      final query = 'SELECT * FROM meals $whereSql';

      final result = await Db.connection.mappedResultsQuery(
        query,
        substitutionValues: values,
      );
      final meals = result
          .where((row) => row.values.isNotEmpty)
          .map((row) => mapRowToMeal(row.values.first))
          .toList();

      return Response.ok(
        jsonEncode(meals.map((m) => mealToJson(m)).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, s) {
      print('Error filtering meals: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getFavorite(Request request) async {
    try {
      final result = await Db.connection.query('SELECT meal_id FROM favorites');
      final ids = result.map((r) => r[0] as String).toList();
      return Response.ok(
        jsonEncode(ids),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, s) {
      print('Error fetching favorites: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _createMeal(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Extract booleans safely and enforce default
      final isMeat = data['isMeat'] ?? false;
      final isVegetarian = data['isVegetarian'] ?? !isMeat;

      // Validate combination
      if (isMeat && isVegetarian) {
        return Response(
          400,
          body: jsonEncode({
            'error': 'Meal cannot be both meat and vegetarian',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final meal = Meal(
        id: data['id'],
        title: data['title'],
        imageUrl: data['imageUrl'],
        duration: data['duration'] is int
            ? data['duration']
            : int.parse(data['duration'].toString()),
        complexity: Complexity.values.firstWhere(
          (e) => e.name == data['complexity'],
        ),
        affordability: Affordability.values.firstWhere(
          (e) => e.name == data['affordability'],
        ),
        isMeat: isMeat,
        isVegetarian: isVegetarian,
        categories: List<String>.from(data['categories'] ?? []),
        ingredients: List<String>.from(data['ingredients'] ?? []),
        steps: List<String>.from(data['steps'] ?? []),
      );
      await Db.connection.query(
        '''
      INSERT INTO meals (
        id, title, image_url, duration,
        complexity, affordability,
        is_meat, is_vegetarian,
        categories, ingredients, steps
      ) VALUES (
        @id, @title, @image_url, @duration,
        @complexity, @affordability,
        @is_meat, @is_vegetarian,
        @categories, @ingredients, @steps
      )
      ''',
        substitutionValues: {
          'id': meal.id,
          'title': meal.title,
          'image_url': meal.imageUrl,
          'duration': meal.duration,
          'complexity': meal.complexity.name,
          'affordability': meal.affordability.name,
          'is_meat': meal.isMeat,
          'is_vegetarian': meal.isVegetarian,
          'categories': jsonEncode(meal.categories),
          'ingredients': jsonEncode(meal.ingredients),
          'steps': jsonEncode(meal.steps),
        },
      );
      return Response(
        201,
        body: jsonEncode({'message': 'Meal created'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, s) {
      print('Create error: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _addFavorite(Request request, String id) async {
    try {
      await Db.connection.query(
        'INSERT INTO favorites (meal_id) VALUES (@id) ON CONFLICT DO NOTHING',
        substitutionValues: {'id': id},
      );
      return Response.ok(
        jsonEncode({'message': 'added'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, s) {
      print('Error adding favorite: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _editMeal(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final existing = await Db.connection.query(
        'SELECT id FROM meals WHERE id=@id',
        substitutionValues: {'id': id},
      );

      if (existing.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Meal not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final isMeat = data['isMeat'] ?? false;
      final isVegetarian = data['isVegetarian'] ?? !isMeat;
      if (isMeat && isVegetarian) {
        return Response(
          400,
          body: jsonEncode({
            'error': 'Meal cannot be both meat and vegetarian',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      await Db.connection.query(
        '''
        UPDATE meals SET
        title =@title,
        image_url = @image_url,
        duration = @duration,
        complexity = @complexity,
        affordability = @affordability,
        is_meat = @is_meat,
        is_vegetarian = @is_vegetarian,
        categories = @categories,
        ingredients = @ingredients,
        steps = @steps
      WHERE id = @id
      ''',
        substitutionValues: {
          'id': id,
          'title': data['title'],
          'image_url': data['imageUrl'],
          'duration': data['duration'] is int
              ? data['duration']
              : int.parse(data['duration'].toString()),
          'complexity': data['complexity'],
          'affordability': data['affordability'],
          'is_meat': isMeat,
          'is_vegetarian': isVegetarian,
          'categories': jsonEncode(data['categories'] ?? []),
          'ingredients': jsonEncode(data['ingredients'] ?? []),
          'steps': jsonEncode(data['steps'] ?? []),
        },
      );

      return Response.ok(
        jsonEncode({'message': 'Meal updated'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, s) {
      print('Update error: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteMeal(Request request, String id) async {
    final result = await Db.connection.query(
      'DELETE FROM meals WHERE id = @id',
      substitutionValues: {'id': id},
    );
    if (result.affectedRowCount == 0) {
      return Response.notFound("Meal not found");
    }
    return Response.ok(
      jsonEncode({'message': 'Meal deleted'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _deleteFavorite(Request request, String id) async {
    try {
      await Db.connection.query(
        'DELETE FROM favorites WHERE meal_id=@id',
        substitutionValues: {'id': id},
      );
      return Response.ok(
        jsonEncode({'message': 'removed'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, s) {
      print('Error removing favorite: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
