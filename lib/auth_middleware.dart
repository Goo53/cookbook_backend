import 'dart:convert';
import 'package:shelf/shelf.dart';

//checking for a valid authorization header

Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.forbidden(
          jsonEncode({'error': 'Missing or invalid token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      final token = authHeader.substring(7);

      //validate token
      if (token != 'my-secret-token') {
        return Response.forbidden(
          jsonEncode({'error': 'Invalid token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      return innerHandler(request);
    };
  };
}
