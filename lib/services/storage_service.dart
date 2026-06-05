import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFactory = 'kurachi_selected_factory';
  static const String _keyMachine = 'kurachi_selected_machine';
  static const String _keyDraftPrefix = 'kurachi_draft_';
  static const String _keyRecentWorkers = 'kurachi_recent_workers_';
  static const String _keyLogQueue = 'kurachi_log_queue_';

  // Load selected factory setting
  Future<String> getSelectedFactory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFactory) ?? '小瀬';
  }

  // Save selected factory setting
  Future<void> setSelectedFactory(String factory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFactory, factory);
  }

  // Load selected machine setting
  Future<String> getSelectedMachine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMachine) ?? 'OZNC01';
  }

  // Save selected machine setting
  Future<void> setSelectedMachine(String machine) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMachine, machine);
  }

  // Get unique prefix based on factory and machine context
  String _getUniquePrefix(String factory, String machine) {
    return '${factory}_${machine}_';
  }

  // Load report draft map
  Future<Map<String, dynamic>> loadDraft(String factory, String machine) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyDraftPrefix${_getUniquePrefix(factory, machine)}';
      final draftString = prefs.getString(key);
      if (draftString != null && draftString.isNotEmpty) {
        return json.decode(draftString) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error loadDraft: $e');
    }
    return {};
  }

  // Save report draft map
  Future<void> saveDraft(String factory, String machine, Map<String, dynamic> draftData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyDraftPrefix${_getUniquePrefix(factory, machine)}';
      await prefs.setString(key, json.encode(draftData));
    } catch (e) {
      print('Error saveDraft: $e');
    }
  }

  // Clear draft
  Future<void> clearDraft(String factory, String machine) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyDraftPrefix${_getUniquePrefix(factory, machine)}';
      await prefs.remove(key);
    } catch (e) {
      print('Error clearDraft: $e');
    }
  }

  // Load recently selected workers list (limit to 5)
  Future<List<String>> getRecentWorkers(String factory, String role) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyRecentWorkers${factory}_$role';
    return prefs.getStringList(key) ?? [];
  }

  // Cache recently selected worker
  Future<void> addRecentWorker(String factory, String role, String workerName) async {
    if (workerName.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyRecentWorkers${factory}_$role';
    final currentList = prefs.getStringList(key) ?? [];
    
    // Remove if already exists and add to top
    currentList.remove(workerName);
    currentList.insert(0, workerName);
    
    // Keep max 5 recent names
    if (currentList.length > 5) {
      currentList.removeLast();
    }
    
    await prefs.setStringList(key, currentList);
  }

  // Remove a worker from recent cache
  Future<void> deleteRecentWorker(String factory, String role, String workerName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyRecentWorkers${factory}_$role';
    final currentList = prefs.getStringList(key) ?? [];
    if (currentList.remove(workerName)) {
      await prefs.setStringList(key, currentList);
    }
  }

  // Load offline log queue
  Future<List<Map<String, dynamic>>> getLogQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString(_keyLogQueue);
      if (queueString != null && queueString.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(queueString);
        return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      print('Error getLogQueue: $e');
    }
    return [];
  }

  // Save log queue
  Future<void> saveLogQueue(List<Map<String, dynamic>> queue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLogQueue, json.encode(queue));
    } catch (e) {
      print('Error saveLogQueue: $e');
    }
  }
}
