import 'dart:convert';
import 'package:shelf/shelf.dart';

//checking for a valid authorization header

Middleware authMiddleware(String expectedToken) {
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
      if (token != expectedToken) {
        return Response.forbidden(
          jsonEncode({'error': 'Invalid token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      return innerHandler(request);
    };
  };
}
