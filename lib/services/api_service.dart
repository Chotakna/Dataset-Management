import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static const String _baseUrl = AppConfig.apiBaseUrl;
  final String _sessionId;

  ApiService(this._sessionId);

  Future<Map<String, dynamic>> health() async {
    final res = await http.get(Uri.parse('$_baseUrl/health'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> uploadFile({
    required List<int> bytes,
    required String filename,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
    req.fields['session_id'] = _sessionId;
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final res = await req.send();
    final body = await res.stream.bytesToString();
    return jsonDecode(body);
  }

  Future<Map<String, dynamic>> getDataInfo() async {
    final res = await http.get(Uri.parse('$_baseUrl/data/info?session_id=$_sessionId'));
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getDataPreview({int rows = 10}) async {
    final res = await http.get(Uri.parse('$_baseUrl/data/preview?session_id=$_sessionId&rows=$rows'));
    final body = jsonDecode(res.body);
    return body['data'];
  }

  Future<Map<String, dynamic>> getColumns() async {
    final res = await http.get(Uri.parse('$_baseUrl/data/columns?session_id=$_sessionId'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> cleanData() async {
    final res = await http.post(Uri.parse('$_baseUrl/data/clean?session_id=$_sessionId'), headers: {});
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getChart({
    required String chartType,
    required String xAxis,
    required String yAxis,
  }) async {
    final res = await http.get(Uri.parse(
      '$_baseUrl/visualization/chart'
      '?session_id=$_sessionId&chart_type=$chartType&x_axis=$xAxis&y_axis=$yAxis',
    ));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getCorrelation() async {
    final res = await http.get(Uri.parse('$_baseUrl/visualization/correlation?session_id=$_sessionId'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> trainModel({
    required String target,
    required List<String> features,
    required String modelName,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/model/train'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': _sessionId,
        'target': target,
        'features': features,
        'model_name': modelName,
      }),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> predict(Map<String, dynamic> inputData) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': _sessionId,
        'input_data': inputData,
      }),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getModels() async {
    final res = await http.get(Uri.parse('$_baseUrl/models'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getHistory() async {
    final res = await http.get(Uri.parse('$_baseUrl/history'));
    return jsonDecode(res.body);
  }

  Future<void> deleteHistory(String sessionId) async {
    final res = await http.delete(Uri.parse('$_baseUrl/history/$sessionId'));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['detail'] ?? 'Delete failed');
    }
  }

  Future<Map<String, dynamic>> loadSession() async {
    final res = await http.get(Uri.parse('$_baseUrl/data/load?session_id=$_sessionId'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getSamples() async {
    final res = await http.get(Uri.parse('$_baseUrl/samples'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> loadSample(String filename) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/data/load-sample'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'filename': filename}),
    );
    return jsonDecode(res.body);
  }
}
