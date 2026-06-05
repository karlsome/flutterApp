import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/product_model.dart';

class ApiService {
  final http.Client _client = http.Client();

  // Fetch Setsubi/Machine names list
  Future<List<String>> fetchSetsubiList(String factory) async {
    try {
      final uri = Uri.parse('${AppConfig.serverUrl}/getSetsubiList').replace(
        queryParameters: {'factory': factory},
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<String> uniqueSetsubi = data
            .map((item) => item['設備']?.toString() ?? '')
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
        uniqueSetsubi.sort((a, b) => a.compareTo(b));
        return uniqueSetsubi;
      } else {
        throw Exception('Failed to load setsubi. HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetchSetsubiList: $e');
      return [];
    }
  }

  // Fetch Sebanggo/Uniform numbers list
  Future<List<String>> fetchSebanggoList(String factory, String machine) async {
    try {
      List<String> list = [];
      
      // OZMANAS query pattern
      if (machine.toUpperCase() == 'OZMANAS') {
        final uri = Uri.parse('${AppConfig.serverUrl}/queries');
        final response = await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'dbName': 'Sasaki_Coating_MasterDB',
            'collectionName': 'masterDB',
            'query': {
              '加工設備': 'OZMANAS',
              '工場': factory,
            }
          }),
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          list = data
              .map((item) => item['背番号']?.toString()?.trim() ?? '')
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList();
        }
      } else {
        // Default behavior
        final uri = Uri.parse('${AppConfig.serverUrl}/getSeBanggoListPress').replace(
          queryParameters: {'工場': factory},
        );
        final response = await _client.get(uri).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          list = data.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
        }
      }
      
      list.sort((a, b) => a.compareTo(b));
      return list;
    } catch (e) {
      print('Error fetchSebanggoList: $e');
      return [];
    }
  }

  // Fetch product specifications from database
  Future<Product?> fetchProductDetails(String sebanggo, String factory) async {
    if (sebanggo.isEmpty) return null;
    
    try {
      // Step 1: Try query by 背番号
      final uri = Uri.parse('${AppConfig.serverUrl}/queries');
      var response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'dbName': 'Sasaki_Coating_MasterDB',
          'collectionName': 'masterDB',
          'query': {'背番号': sebanggo}
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }

      List<dynamic> result = json.decode(response.body);
      
      // Step 2: Fallback query by 品番
      if (result.isEmpty) {
        response = await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'dbName': 'Sasaki_Coating_MasterDB',
            'collectionName': 'masterDB',
            'query': {'品番': sebanggo}
          }),
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          result = json.decode(response.body);
        }
      }

      if (result.isNotEmpty) {
        return Product.fromJson(result[0] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetchProductDetails: $e');
      rethrow;
    }
  }

  // Fetch Operator/Inspector worker names list
  Future<List<String>> fetchWorkerNames(String factory) async {
    try {
      final uri = Uri.parse('${AppConfig.serverUrl}/getWorkerNames').replace(
        queryParameters: {'selectedFactory': factory},
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<String> list = data.map((item) => item.toString()).toList();
        list.sort((a, b) => a.compareTo(b));
        return list;
      } else {
        throw Exception('Failed to load worker names');
      }
    } catch (e) {
      print('Error fetchWorkerNames: $e');
      return [];
    }
  }

  // Leader QR Verification
  Future<Map<String, dynamic>> verifyLeader(String username) async {
    try {
      final uri = Uri.parse('${AppConfig.serverUrl}/verifyLeader');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {'authorized': false, 'error': 'Server returned HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'authorized': false, 'error': e.toString()};
    }
  }

  // Generate Session ID from Backend
  Future<String?> generateSessionID(String sebanggo, String machine, String factory, String date) async {
    try {
      final uri = Uri.parse('${AppConfig.serverUrl}/api/generate-session-id').replace(
        queryParameters: {
          '背番号': sebanggo,
          '設備': machine,
          '工場': factory,
          'Date': date,
        },
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['sessionID']?.toString();
        }
      }
      return null;
    } catch (e) {
      print('Error generateSessionID: $e');
      return null;
    }
  }

  // Post Tablet Activity Log
  Future<bool> postTabletLog(Map<String, dynamic> logPayload) async {
    try {
      final uri = Uri.parse('${AppConfig.serverUrl}/api/tablet-log');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(logPayload),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error postTabletLog: $e');
      return false;
    }
  }

  // Submit Completed Daily Report atomically
  Future<Map<String, dynamic>> submitToDCP(Map<String, dynamic> submissionData) async {
    try {
      final uri = Uri.parse('${AppConfig.serverUrl}/submitToDCP');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(submissionData),
      ).timeout(const Duration(seconds: 60)); // Long timeout for large image uploads

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': decoded};
      } else {
        return {'success': false, 'error': decoded['message'] ?? 'Failed submission'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Resolve equipment printer IP via Apps Script
  Future<String> resolveEquipmentPrinterIP(String machine) async {
    try {
      final uri = Uri.parse(AppConfig.ipUrl).replace(
        queryParameters: {'filter': machine},
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final cleanIP = response.body.replaceAll('"', '').trim();
        return cleanIP;
      }
      throw Exception('Failed to resolve printer IP');
    } catch (e) {
      print('Error resolveEquipmentPrinterIP: $e');
      rethrow;
    }
  }

  // Trigger auto print request for 047J model
  Future<bool> request047JAutoPrint(String printerIP, String sebanggo, int copies) async {
    try {
      final requestUri = Uri.parse('http://$printerIP:5001/request').replace(
        queryParameters: {
          'filename': sebanggo,
          'qty': copies.toString(),
        },
      );
      final response = await _client.get(requestUri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final payload = json.decode(response.body);
        return payload['success'] != false;
      }
      return false;
    } catch (e) {
      print('Error request047JAutoPrint: $e');
      return false;
    }
  }

  // Update Google Sheet active status of machine/tablet
  Future<void> updateGoogleSheetStatus(String sebanggo, String machine) async {
    try {
      final uri = Uri.parse(AppConfig.googleSheetLiveStatusUrl);
      await _client.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'sebanggo': sebanggo,
          'machine': machine,
          'status': 'active',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Quiet fail on updateGoogleSheetStatus: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
