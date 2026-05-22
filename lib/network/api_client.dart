import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:skillforgeapp/models/shared/api_error.dart';

import '../config/app_config.dart';

class ApiClient {
  ApiClient(this._getToken);

  final Future<String?> Function() _getToken;

  String _formatErrorMessage(dynamic value) {
    if (value == null) return 'An error occurred';
    if (value is String) return value;
    if (value is List) {
      final parts = value
          .map((e) => _formatErrorMessage(e))
          .where((e) => e.isNotEmpty && e != 'An error occurred')
          .toList();
      if (parts.isEmpty) return 'An error occurred';
      return parts.join('\n');
    }
    if (value is Map<String, dynamic>) {
      final nested = value['message'] ?? value['error'] ?? value['detail'];
      if (nested != null) return _formatErrorMessage(nested);
    }
    return value.toString();
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(AppConfig.baseApiUrl);
    return base.replace(
      path: '${base.path}$path',
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool jsonHeader = true,
  }) async {
    final uri = _uri(path, query);
    final headers = await _headers(json: jsonHeader);
    final upperMethod = method.toUpperCase();

    developer.log(
      '[API REQUEST] $upperMethod $path | body=${body ?? 'null'}',
      name: 'ApiClient',
    );

    late http.Response response;
    try {
      switch (upperMethod) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: body);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: body);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers, body: body);
          break;
        default:
          throw ApiError(message: 'Unsupported method: $method');
      }
    } catch (error, stackTrace) {
      developer.log(
        '[API RESPONSE] $upperMethod $path | transport_error=$error',
        name: 'ApiClient',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    if (response.statusCode == 204 || response.body.isEmpty) {
      developer.log(
        '[API RESPONSE] $upperMethod $path | status=${response.statusCode} | response=null',
        name: 'ApiClient',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
    }

    dynamic parsed;
    try {
      parsed = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      developer.log(
        '[API RESPONSE] $upperMethod $path | status=${response.statusCode} | response=${response.body}',
        name: 'ApiClient',
      );
      throw ApiError(
        message: 'Network error or invalid server response',
        statusCode: response.statusCode,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    developer.log(
      '[API RESPONSE] $upperMethod $path | status=${response.statusCode} | response=$parsed',
      name: 'ApiClient',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = parsed is Map<String, dynamic>
          ? _formatErrorMessage(
              parsed['message'] ?? parsed['error'] ?? parsed['detail'],
            )
          : _formatErrorMessage(parsed);
      throw ApiError(
        message: message,
        statusCode: response.statusCode,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    return parsed;
  }

  Future<dynamic> requestMultipart(
    String method,
    String path, {
    Map<String, dynamic>? query,
    required String fileField,
    required String fileName,
    required Uint8List fileBytes,
    String? contentType,
    Map<String, String>? fields,
  }) async {
    final uri = _uri(path, query);
    final headers = await _headers(json: false);
    final upperMethod = method.toUpperCase();

    developer.log(
      '[API REQUEST] $upperMethod $path | multipart_file=$fileName',
      name: 'ApiClient',
    );

    final request = http.MultipartRequest(upperMethod, uri);
    request.headers.addAll(headers);
    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
        contentType: contentType == null
            ? null
            : _mediaTypeFromString(contentType),
      ),
    );

    late http.StreamedResponse streamed;
    try {
      streamed = await request.send();
    } catch (error, stackTrace) {
      developer.log(
        '[API RESPONSE] $upperMethod $path | transport_error=$error',
        name: 'ApiClient',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 204 || response.body.isEmpty) {
      developer.log(
        '[API RESPONSE] $upperMethod $path | status=${response.statusCode} | response=null',
        name: 'ApiClient',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
    }

    dynamic parsed;
    try {
      parsed = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      developer.log(
        '[API RESPONSE] $upperMethod $path | status=${response.statusCode} | response=${response.body}',
        name: 'ApiClient',
      );
      throw ApiError(
        message: 'Network error or invalid server response',
        statusCode: response.statusCode,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    developer.log(
      '[API RESPONSE] $upperMethod $path | status=${response.statusCode} | response=$parsed',
      name: 'ApiClient',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = parsed is Map<String, dynamic>
          ? _formatErrorMessage(
              parsed['message'] ?? parsed['error'] ?? parsed['detail'],
            )
          : _formatErrorMessage(parsed);
      throw ApiError(
        message: message,
        statusCode: response.statusCode,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    return parsed;
  }

  String toJson(Object value) => jsonEncode(value);
}

http_parser.MediaType _mediaTypeFromString(String value) {
  final parts = value.split('/');
  if (parts.length != 2) {
    return http_parser.MediaType('application', 'octet-stream');
  }
  return http_parser.MediaType(parts[0], parts[1]);
}
