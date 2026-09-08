import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import 'local_storage.dart';

class ApiService {
  static final http.Client _client = http.Client();

  static Map<String, String> _getHeaders() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = LocalStorage.getString('jwt_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static dynamic _processResponse(http.Response response) {
    final int code = response.statusCode;
    final body = response.body;
    
    // Check if JSON response
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      decoded = body;
    }

    if (code >= 200 && code < 300) {
      return decoded;
    } else {
      String errMsg = "Request failed with code $code";
      if (decoded is Map && decoded.containsKey('message')) {
        errMsg = decoded['message'].toString();
      }
      throw Exception(errMsg);
    }
  }

  static Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await _client.get(uri, headers: _getHeaders());
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final Uri uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    try {
      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final Uri uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    try {
      final response = await _client.put(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<dynamic> delete(String endpoint, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await _client.delete(uri, headers: _getHeaders());
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Multi-part file upload for Excel/CSV bulk import
  static Future<dynamic> uploadMultipart(String endpoint, String filePath, Map<String, String> fields) async {
    final Uri uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    try {
      final request = http.MultipartRequest('POST', uri);
      
      // Headers
      final token = LocalStorage.getString('jwt_token');
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Fields
      request.fields.addAll(fields);
      
      // File
      final multipartFile = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}
