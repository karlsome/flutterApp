import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../models/product_model.dart';
import '../models/maintenance_model.dart';
import '../models/equipment_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AppStage { setup, scan, production, quality, submit }

class ReportProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Active Environment Context
  String _selectedFactory = '小瀬';
  String _selectedMachine = 'OZNC01';
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isSendingToNC = false;
  bool _ncSendSuccess = false;
  String? _ncSendError;

  AppStage _appStage = AppStage.scan;
  List<String> _factories = [];
  List<Equipment> _equipments = [];
  Equipment _activeEquipment = Equipment.empty();
  Map<String, int> _groupedShots = {};

  // Worker registry names list
  List<String> _workers = [];

  // Available product uniform numbers (sebanggos) list
  List<String> _sebanggoList = [];

  // Setup Scan Wizard Step (1: Scan Kanban, 2: Scan Material, 3: Send to Machine/Thomson Board, 0: Completed/Ready)
  int _setupStep = 1;

  // Form State Properties
  String _sessionID = '';
  String _sebanggo = '';
  Product _activeProduct = Product.empty();

  // DCP Process Form Inputs
  String _workerName = '';
  int _processQuantity = 0;
  DateTime _workDate = DateTime.now();
  String _labelExtension = '';
  String _startTime = '';
  String _endTime = '';
  int _shotCount = 0;
  List<String> _materialLots = [];
  
  // Defect counters for DCP
  int _defectPull = 0; // counter-18
  int _processingDefect = 0; // counter-19
  int _otherDefect = 0; // counter-20
  String _commentsDcp = '';

  // Cycle check photos
  String _hatsumonoPhotoPath = '';
  bool _hatsumonoChecked = false;
  String _atomonoPhotoPath = '';
  bool _atomonoChecked = false;
  
  // Material label photo paths
  List<String> _materialLabelPhotos = [];
  Map<String, String> _lotToPhotoMap = {};

  // Kensa Form Toggles & Inputs
  bool _isKensaEnabled = false;
  String _kensaName = '';
  DateTime _kensaDate = DateTime.now();
  String _kensaStartTime = '';
  String _kensaEndTime = '';
  List<int> _kensaCounters = List.filled(12, 0); // counters 1 to 12
  int _spare = 0;
  String _commentsKensa = '';

  // Break Times
  final List<Map<String, String>> _breaks = List.generate(
    4,
    (index) => {'start': '', 'end': ''},
  );

  // Maintenance Records
  List<MaintenanceRecord> _maintenanceRecords = [];

  // Network Offline logging queue properties
  List<Map<String, dynamic>> _logQueue = [];
  bool _isSyncingLogs = false;
  Timer? _logSyncTimer;

  // Getters
  String get selectedFactory => _selectedFactory;
  String get selectedMachine => _selectedMachine;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isSendingToNC => _isSendingToNC;
  bool get ncSendSuccess => _ncSendSuccess;
  String? get ncSendError => _ncSendError;
  List<String> get workers => _workers;
  List<String> get sebanggoList => _sebanggoList;

  AppStage get appStage => _appStage;
  List<String> get factories => _factories;
  List<Equipment> get equipments => _equipments;
  Equipment get activeEquipment => _activeEquipment;
  Map<String, int> get groupedShots => _groupedShots;
  bool get isGroupedMachine => _selectedMachine.contains(',');

  void setAppStage(AppStage stage) {
    if (_appStage == stage) return;
    _appStage = stage;
    saveDraft();
    notifyListeners();
  }

  void setGroupedShot(String machine, int count) {
    _groupedShots[machine] = count;
    notifyListeners();
    saveDraft();
  }

  void clearNcSendStatus() {
    _ncSendSuccess = false;
    _ncSendError = null;
    notifyListeners();
  }
  int get setupStep => _setupStep;
  bool get isSetupComplete => _setupStep == 0 && _sebanggo.isNotEmpty;
  String get sessionID => _sessionID;
  String get sebanggo => _sebanggo;

  void setSetupStep(int step) {
    _setupStep = step;
    saveDraft();
    notifyListeners();
  }

  void resetSetupWorkflow() {
    _resetFormFields();
    _setupStep = 1;
    saveDraft();
    notifyListeners();
  }
  Product get activeProduct => _activeProduct;
  
  String get workerName => _workerName;
  int get processQuantity => _processQuantity;
  DateTime get workDate => _workDate;
  String get labelExtension => _labelExtension;
  String get startTime => _startTime;
  String get endTime => _endTime;
  int get shotCount {
    if (isGroupedMachine) {
      return _groupedShots.values.fold(0, (sum, val) => sum + val);
    }
    return _shotCount;
  }
  List<String> get materialLots => _materialLots;
  int get defectPull => _defectPull;
  int get processingDefect => _processingDefect;
  int get otherDefect => _otherDefect;
  String get commentsDcp => _commentsDcp;

  String get hatsumonoPhotoPath => _hatsumonoPhotoPath;
  bool get hatsumonoChecked => _hatsumonoChecked;
  String get atomonoPhotoPath => _atomonoPhotoPath;
  bool get atomonoChecked => _atomonoChecked;
  List<String> get materialLabelPhotos => _materialLabelPhotos;
  Map<String, String> get lotToPhotoMap => _lotToPhotoMap;

  bool get isKensaEnabled => _isKensaEnabled;
  String get kensaName => _kensaName;
  DateTime get kensaDate => _kensaDate;
  String get kensaStartTime => _kensaStartTime;
  String get kensaEndTime => _kensaEndTime;
  List<int> get kensaCounters => _kensaCounters;
  int get spare => _spare;
  String get commentsKensa => _commentsKensa;

  List<Map<String, String>> get breaks => _breaks;
  List<MaintenanceRecord> get maintenanceRecords => _maintenanceRecords;
  List<Map<String, dynamic>> get logQueue => _logQueue;

  // Time conversion helpers
  String formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  // Real-time Calculated Properties
  int get totalNG {
    int total = 0;
    // Sum kensa counters
    for (var count in _kensaCounters) {
      total += count;
    }
    // Sum DCP defect counters
    total += _defectPull + _processingDefect + _otherDefect;
    return total;
  }

  int get finalGoodQuantity {
    return _processQuantity - totalNG;
  }

  int get totalBreakMinutes {
    int total = 0;
    for (var b in _breaks) {
      final start = b['start'] ?? '';
      final end = b['end'] ?? '';
      if (start.isEmpty || end.isEmpty) continue;
      
      try {
        final startParts = start.split(':');
        final endParts = end.split(':');
        final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        
        if (endMin >= startMin) {
          total += (endMin - startMin);
        } else {
          total += ((24 * 60 - startMin) + endMin);
        }
      } catch (_) {}
    }
    return total;
  }

  double get totalBreakHours => totalBreakMinutes / 60.0;

  int get totalTroubleMinutes {
    int total = 0;
    for (var r in _maintenanceRecords) {
      total += r.durationMinutes;
    }
    return total;
  }

  double get totalTroubleHours => totalTroubleMinutes / 60.0;

  double get totalWorkHours {
    if (_startTime.isEmpty || _endTime.isEmpty) return 0.0;
    try {
      final startParts = _startTime.split(':');
      final endParts = _endTime.split(':');
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      
      double diffHours = 0.0;
      if (endMin >= startMin) {
        diffHours = (endMin - startMin) / 60.0;
      } else {
        diffHours = ((24 * 60 - startMin) + endMin) / 60.0;
      }
      
      final netWorkTime = diffHours - totalBreakHours - totalTroubleHours;
      return netWorkTime < 0.0 ? 0.0 : netWorkTime;
    } catch (_) {
      return 0.0;
    }
  }

  // Setters & Actions
  Future<void> initEnvironment(String factory, String machine) async {
    _isLoading = true;
    notifyListeners();

    _selectedFactory = factory;
    _selectedMachine = machine;

    // Load active equipment from database setsubiDB if not a group
    try {
      _equipments = await _apiService.fetchEquipmentList(factory);
      final match = _equipments.firstWhere(
        (eq) => eq.name == machine,
        orElse: () => Equipment.empty(),
      );
      _activeEquipment = match;
    } catch (e) {
      print('Error loading active equipment details: $e');
      _activeEquipment = Equipment.empty();
    }

    // Determine if environment is a single or grouped machine
    final bool grouped = _selectedMachine.contains(',');
    if (grouped) {
      _isKensaEnabled = false;
      _groupedShots = {};
      final list = _selectedMachine.split(',');
      for (var m in list) {
        _groupedShots[m] = 0;
      }
    } else {
      _groupedShots = {};
    }

    // Load draft
    final draft = await _storageService.loadDraft(factory, machine);
    if (draft.isNotEmpty) {
      _restoreFromDraftMap(draft);
    } else {
      _resetFormFields();
    }

    // Load log queue
    _logQueue = await _storageService.getLogQueue();

    // Fetch worker names registry and sebanggo list
    try {
      _workers = await _apiService.fetchWorkerNames(factory);
      _sebanggoList = await _apiService.fetchSebanggoList(factory, machine);
    } catch (e) {
      print('Error fetching environment data: $e');
      _workers = [];
      _sebanggoList = [];
    }

    _isLoading = false;
    notifyListeners();

    // Start sync timer
    _logSyncTimer?.cancel();
    _logSyncTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      syncOfflineLogs();
    });
  }

  Future<void> changeEnvironment(String factory, String machine) async {
    await _storageService.setSelectedFactory(factory);
    await _storageService.setSelectedMachine(machine);
    await initEnvironment(factory, machine);
  }

  void setSebanggo(String val) {
    if (_sebanggo == val) return;
    _sebanggo = val;
    NCPresstoFalse();
    _fetchProductInfo();
    saveDraft();
  }

  void NCPresstoFalse() {
    _sessionID = '';
    saveDraft();
  }

  Future<void> _fetchProductInfo() async {
    if (_sebanggo.isEmpty) {
      _activeProduct = Product.empty();
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final details = await _apiService.fetchProductDetails(_sebanggo, _selectedFactory);
      if (details != null) {
        _activeProduct = details;
        _apiService.updateGoogleSheetStatus(_sebanggo, _selectedMachine);
        
        // Fallback to Google Apps Script if imageURL is empty in MongoDB
        if (_activeProduct.imageUrl.isEmpty) {
          try {
            final key = _activeProduct.productNumber.isNotEmpty ? _activeProduct.productNumber : _sebanggo;
            final fallbackUrl = await _fetchFallbackProductImageUrl(key);
            if (fallbackUrl.isNotEmpty) {
              _activeProduct = Product(
                sebanggo: _activeProduct.sebanggo,
                productNumber: _activeProduct.productNumber,
                model: _activeProduct.model,
                shape: _activeProduct.shape,
                rl: _activeProduct.rl,
                material: _activeProduct.material,
                materialCode: _activeProduct.materialCode,
                materialColor: _activeProduct.materialColor,
                kataban: _activeProduct.kataban,
                capacity: _activeProduct.capacity,
                feedPitch: _activeProduct.feedPitch,
                releasePaper: _activeProduct.releasePaper,
                srs: _activeProduct.srs,
                imageUrl: fallbackUrl,
              );
            }
          } catch (err) {
            print('Failed to load fallback product image: $err');
          }
        }
      } else {
        _activeProduct = Product.empty();
      }
    } catch (e) {
      print('Failed to fetch product details: $e');
    }
    _isLoading = false;
    notifyListeners();
    saveDraft();
  }

  Future<String> _fetchFallbackProductImageUrl(String key) async {
    const String picURL = 'https://script.google.com/macros/s/AKfycbwHUW1ia8hNZG-ljsguNq8K4LTPVnB6Ng_GLXIHmtJTdUgGGd2WoiQo9ToF-7PvcJh9bA/exec';
    try {
      final response = await http.get(Uri.parse('$picURL?link=$key')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final cleaned = response.body.replaceAll('"', '').trim();
        if (cleaned.isNotEmpty && (cleaned.startsWith('http://') || cleaned.startsWith('https://'))) {
          return '$cleaned&sz=s4000';
        }
      }
    } catch (e) {
      print('Error fetching fallback product image: $e');
    }
    return '';
  }

  void setWorkerName(String name) {
    _workerName = name;
    _storageService.addRecentWorker(_selectedFactory, 'worker', name);
    logTabletAction('Worker name selected', 'in-progress', {'workerName': name});
    saveDraft();
  }

  void setKensaName(String name) {
    _kensaName = name;
    _storageService.addRecentWorker(_selectedFactory, 'kensa', name);
    logTabletAction('Kensa inspector selected', 'in-progress', {'kensaName': name});
    saveDraft();
  }

  void setProcessQuantity(int qty) {
    _processQuantity = qty;
    saveDraft();
  }

  void setWorkDate(DateTime dt) {
    _workDate = dt;
    saveDraft();
  }

  void setLabelExtension(String ext) {
    _labelExtension = ext;
    saveDraft();
  }

  void setStartTime(String time) {
    _startTime = time;
    saveDraft();
  }

  void setEndTime(String time) {
    _endTime = time;
    saveDraft();
  }

  void setShotCount(int count) {
    _shotCount = count;
    saveDraft();
  }

  void addMaterialLot(String lot) {
    if (lot.isEmpty || _materialLots.contains(lot)) return;
    _materialLots.add(lot);
    saveDraft();
  }

  void addMaterialLotWithPhoto(String lot, String photoPath) {
    if (lot.isEmpty || _materialLots.contains(lot)) return;
    _materialLots.add(lot);
    _materialLabelPhotos.add(photoPath);
    _lotToPhotoMap[lot] = photoPath;
    saveDraft();
  }

  void removeMaterialLot(String lot) {
    if (_materialLots.contains(lot)) {
      _materialLots.remove(lot);
      final photoPath = _lotToPhotoMap[lot];
      if (photoPath != null) {
        _materialLabelPhotos.remove(photoPath);
        _lotToPhotoMap.remove(lot);
      }
      saveDraft();
    }
  }

  void incrementDcpCounter(int counterId) {
    if (counterId == 18) {
      _defectPull++;
      logTabletAction('Counter 18 incremented', 'in-progress', {'newValue': _defectPull});
    } else if (counterId == 19) {
      _processingDefect++;
      logTabletAction('Counter 19 incremented', 'in-progress', {'newValue': _processingDefect});
    } else if (counterId == 20) {
      _otherDefect++;
      logTabletAction('Counter 20 incremented', 'in-progress', {'newValue': _otherDefect});
    }
    saveDraft();
  }

  void decrementDcpCounter(int counterId) {
    if (counterId == 18 && _defectPull > 0) {
      _defectPull--;
    } else if (counterId == 19 && _processingDefect > 0) {
      _processingDefect--;
    } else if (counterId == 20 && _otherDefect > 0) {
      _otherDefect--;
    }
    saveDraft();
  }

  void setCommentsDcp(String text) {
    _commentsDcp = text;
    saveDraft();
  }

  void setHatsumonoPhoto(String path, bool checked) {
    _hatsumonoPhotoPath = path;
    _hatsumonoChecked = checked;
    saveDraft();
  }

  void setAtomonoPhoto(String path, bool checked) {
    _atomonoPhotoPath = path;
    _atomonoChecked = checked;
    saveDraft();
  }

  void addMaterialLabelPhoto(String path) {
    _materialLabelPhotos.add(path);
    saveDraft();
  }

  void removeMaterialLabelPhoto(int index) {
    if (index >= 0 && index < _materialLabelPhotos.length) {
      final path = _materialLabelPhotos.removeAt(index);
      String? lotToRemove;
      _lotToPhotoMap.forEach((lot, photo) {
        if (photo == path) {
          lotToRemove = lot;
        }
      });
      if (lotToRemove != null) {
        _materialLots.remove(lotToRemove);
        _lotToPhotoMap.remove(lotToRemove);
      }
      saveDraft();
    }
  }

  void toggleKensaMode(bool? enabled) {
    _isKensaEnabled = enabled ?? false;
    logTabletAction('Kensa mode checkbox toggled', _isKensaEnabled ? 'Completed' : 'Reset', {'kensaEnabled': _isKensaEnabled});
    saveDraft();
  }

  void incrementKensaCounter(int counterIndex) {
    if (counterIndex >= 0 && counterIndex < 12) {
      _kensaCounters[counterIndex]++;
      logTabletAction('Kensa Counter ${counterIndex + 1} incremented', 'in-progress', {'newValue': _kensaCounters[counterIndex]});
      saveDraft();
    }
  }

  void decrementKensaCounter(int counterIndex) {
    if (counterIndex >= 0 && counterIndex < 12 && _kensaCounters[counterIndex] > 0) {
      _kensaCounters[counterIndex]--;
      saveDraft();
    }
  }

  void setSpare(int val) {
    _spare = val;
    saveDraft();
  }

  void setKensaStartTime(String time) {
    _kensaStartTime = time;
    saveDraft();
  }

  void setKensaEndTime(String time) {
    _kensaEndTime = time;
    saveDraft();
  }

  void setCommentsKensa(String text) {
    _commentsKensa = text;
    saveDraft();
  }

  void updateBreak(int index, String field, String value) {
    if (index >= 0 && index < 4) {
      _breaks[index][field] = value;
      logTabletAction('Break time', 'in-progress', {'index': index, 'field': field, 'value': value});
      saveDraft();
    }
  }

  void addMaintenanceRecord(String start, String end, String comment, List<String> localPaths) {
    final record = MaintenanceRecord(
      id: const Uuid().v4(),
      startTime: start,
      endTime: end,
      comment: comment,
      timestamp: DateTime.now().toIso8601String(),
      photos: localPaths
          .map((path) => MaintenancePhoto(
                id: const Uuid().v4(),
                localPath: path,
                timestamp: DateTime.now().toIso8601String(),
              ))
          .toList(),
    );
    _maintenanceRecords.add(record);
    logTabletAction('Maintenance record added', 'in-progress', {'recordId': record.id});
    saveDraft();
  }

  void deleteMaintenanceRecord(int index) {
    if (index >= 0 && index < _maintenanceRecords.length) {
      final rec = _maintenanceRecords.removeAt(index);
      logTabletAction('Maintenance record deleted', 'in-progress', {'recordId': rec.id});
      saveDraft();
    }
  }

  // Print Deep Link Redirection
  Future<void> triggerPrint(BuildContext context, {int? chosenCapacity}) async {
    if (_sebanggo.isEmpty) {
      throw Exception('背番号が必要です / Sebanggo is required');
    }

    final List<String> specialSebanggos = [
      "P05K", "P06K", "P07K", "P08K", "P13K", "P14K", "P15K", "P16K",
      "UFS5", "UFS6", "UFS7", "UFS8", "URB5", "URB6", "URB7", "URB8"
    ];

    if (specialSebanggos.contains(_sebanggo) && chosenCapacity == null) {
      final int? capacity = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppConfig.cardColor,
            shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
            title: Text(
              '収容数を選択してください\nSelect Capacity',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppConfig.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [50, 100, 200].map((cap) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
                      ),
                      onPressed: () => Navigator.of(context).pop(cap),
                      child: Text(
                        '$cap',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      );

      if (capacity == null) return;
      return triggerPrint(context, chosenCapacity: capacity);
    }

    final String machine = _selectedMachine;
    final String productNum = _activeProduct.productNumber;
    final String carType = _activeProduct.model;
    final String rlVal = _activeProduct.rl;
    final String mat = _activeProduct.material;
    final String color = _activeProduct.materialColor;
    final String srsVal = _activeProduct.srs;

    // Handle 047J model laptop print redirect
    if (carType == '047J') {
      _isLoading = true;
      notifyListeners();
      try {
        final printerIP = await _apiService.resolveEquipmentPrinterIP(machine);
        final success = await _apiService.request047JAutoPrint(printerIP, _sebanggo, 1);
        
        logTabletAction('047J laptop auto-print ' + (success ? 'success' : 'failed'), success ? 'Completed' : 'in-progress', {
          'machine': machine,
          'sebanggo': _sebanggo,
          'copies': 1,
          'printerIP': printerIP
        });
      } catch (e) {
        print('047J printing error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Default Deep Linking Print Redirect
    final int capacity = chosenCapacity ?? _activeProduct.capacity;
    final String timeStr = DateFormat('HH:mm').format(DateTime.now());
    final String lotDate = DateFormat('yyyy-MM-dd').format(_workDate);
    final String workDateFull = _labelExtension.isNotEmpty 
        ? '$lotDate - $_labelExtension - $timeStr' 
        : '$lotDate - $timeStr';

    String filename = 'sample6.lbx';
    if (srsVal == '有り') {
      filename = 'SRS3.lbx';
    } else if (_sebanggo == 'NC2') {
      filename = 'NC21.lbx';
    } else if (_sebanggo == 'RA01' || _sebanggo == 'RA02') {
      if (chosenCapacity != null) {
        filename = '311BPlr3.lbx';
      } else {
        filename = '311BPlr2.lbx';
      }
    }

    final String printParams = 'filename=${Uri.encodeComponent(filename)}' +
        '&size=RollW62&copies=1' +
        '&text_品番=${Uri.encodeComponent(productNum)}' +
        '&text_車型=${Uri.encodeComponent(carType)}' +
        '&text_収容数=${Uri.encodeComponent(capacity.toString())}' +
        '&text_背番号=${Uri.encodeComponent(_sebanggo)}' +
        '&text_RL=${Uri.encodeComponent(rlVal)}' +
        '&text_材料=${Uri.encodeComponent(mat)}' +
        '&text_色=${Uri.encodeComponent(color)}' +
        '&text_DateT=${Uri.encodeComponent(workDateFull)}' +
        '&text_setsubi=${Uri.encodeComponent(machine)}' +
        '&barcode_barcode=${Uri.encodeComponent("$productNum,$capacity")}';

    if (Platform.isIOS) {
      final String printPayload = 'brotherwebprint://print?$printParams';
      final uri = Uri.parse(printPayload);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('Launched print URL successfully: $printPayload');
        } else {
          throw Exception('iOS Brother Print scheme could not be launched / 印刷アプリを起動できませんでした');
        }
      } catch (e) {
        throw Exception('Error launching print: $e');
      }
    } else {
      // Android / Desktop / other platforms: local HTTP request to port 8088
      final String printPayload = 'http://localhost:8088/print?$printParams';
      _isLoading = true;
      notifyListeners();
      try {
        final response = await http.get(Uri.parse(printPayload)).timeout(const Duration(seconds: 7));
        if (response.statusCode == 200 && response.body.contains('<result>SUCCESS</result>')) {
          print('Print success on local printer server');
        } else {
          throw Exception('Printing failed. Check printer status / 印刷に失敗しました。プリンターのステータスを確認してください。');
        }
      } catch (e) {
        print('HTTP print failed: $e. Attempting fallback launchUrl...');
        final fallbackUri = Uri.parse(printPayload);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Local printer server error / プリンターサーバー通信エラー: $e');
        }
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> sendToNC() async {
    if (_sebanggo.isEmpty) {
      throw Exception('背番号が必要です / Sebanggo is required');
    }

    _isSendingToNC = true;
    _ncSendSuccess = false;
    _ncSendError = null;
    notifyListeners();

    final List<String> machines = _selectedMachine.split(',');
    logTabletAction('Send to machine pressed (Background/Main)', 'in-progress', {
      'sebanggo': _sebanggo,
      'source': 'Send to Machine',
      'machines': machines,
    });

    final List<Future<void>> futures = [];
    final List<String> errors = [];

    for (final m in machines) {
      futures.add(() async {
        final machineName = m.trim();
        if (machineName.isEmpty) return;
        try {
          final ipAddress = await _apiService.resolveEquipmentPrinterIP(machineName);
          if (ipAddress.isEmpty) {
            throw Exception('IP address is empty / IPアドレスを取得できませんでした');
          }

          final url = 'http://$ipAddress:5000/request?filename=$_sebanggo.pce';
          print('Sending command to machine $machineName: $url');

          final uri = Uri.parse(url);
          final response = await http.get(uri).timeout(const Duration(seconds: 10));
          if (response.statusCode != 200) {
            throw Exception('Server returned status code ${response.statusCode}');
          }
          logTabletAction('Send to machine success for $machineName', 'Completed', {
            'machine': machineName,
            'sebanggo': _sebanggo,
            'ipAddress': ipAddress,
            'status': response.statusCode
          });
        } catch (e) {
          print('HTTP request to machine $machineName failed: $e. Attempting fallback via url_launcher...');
          try {
            final ipAddress = await _apiService.resolveEquipmentPrinterIP(machineName);
            final url = 'http://$ipAddress:5000/request?filename=$_sebanggo.pce';
            final uri = Uri.parse(url);
            
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              logTabletAction('Send to machine success (fallback launch) for $machineName', 'Completed', {
                'machine': machineName,
                'sebanggo': _sebanggo,
                'ipAddress': ipAddress,
              });
            } else {
              throw Exception('Cannot launch URL: $url');
            }
          } catch (fallbackErr) {
            logTabletAction('Send to machine failed for $machineName', 'failed', {
              'machine': machineName,
              'sebanggo': _sebanggo,
              'error': fallbackErr.toString(),
            });
            errors.add('$machineName: ${fallbackErr.toString()}');
          }
        }
      }());
    }

    try {
      await Future.wait(futures);
      if (errors.isNotEmpty) {
        throw Exception(errors.join('\n'));
      }
      _setupStep = 0;
      _ncSendSuccess = true;
      _ncSendError = null;
    } catch (e) {
      _ncSendSuccess = false;
      _ncSendError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSendingToNC = false;
      notifyListeners();
      saveDraft();
    }
  }

  // Offline retry logging logic
  void logTabletAction(String action, String status, Map<String, dynamic> details) async {
    final now = DateTime.now();
    
    // Generate new SessionID if empty and we have a selected sebanggo
    if (_sessionID.isEmpty && _sebanggo.isNotEmpty) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_workDate);
      final ses = await _apiService.generateSessionID(_sebanggo, _selectedMachine, _selectedFactory, dateStr);
      if (ses != null) {
        _sessionID = ses;
        saveDraft();
      }
    }

    final logItem = {
      'id': const Uuid().v4(),
      'timestamp': now.toIso8601String(),
      'logData': {
        'SessionID': _sessionID,
        'Date': DateFormat('yyyy-MM-dd').format(now),
        'Time': DateFormat('HH:mm:ss').format(now),
        'Action': action,
        'Status': status,
        'Details': details,
      },
      'attempts': 0,
      'nextRetryTime': now.millisecondsSinceEpoch,
    };

    _logQueue.add(logItem);
    await _storageService.saveLogQueue(_logQueue);
    syncOfflineLogs();
  }

  Future<void> syncOfflineLogs() async {
    if (_isSyncingLogs || _logQueue.isEmpty) return;
    _isSyncingLogs = true;
    notifyListeners();

    final now = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, dynamic>> failedItems = [];

    for (var log in _logQueue) {
      if (log['nextRetryTime'] > now) {
        failedItems.add(log);
        continue;
      }

      int attempts = log['attempts'] as int? ?? 0;
      final success = await _apiService.postTabletLog(log['logData'] as Map<String, dynamic>);
      
      if (!success) {
        attempts++;
        if (attempts < 5) {
          log['attempts'] = attempts;
          // Exponential backoff retry delay (2s, 4s, 8s, 16s...)
          log['nextRetryTime'] = now + (2000 * (1 << attempts));
          failedItems.add(log);
        } else {
          // Drop log after 5 failed retries
          print('Dropping log after 5 failures: ${log['id']}');
        }
      }
    }

    _logQueue = failedItems;
    await _storageService.saveLogQueue(_logQueue);
    _isSyncingLogs = false;
    notifyListeners();
  }

  // Validation Check before form Submission
  String? validateForm() {
    if (_sebanggo.isEmpty) return '背番号を選択してください / Please select sebanggo';
    if (_workerName.isEmpty) return '作業者名を選択または入力してください / Please select worker';
    
    if (_startTime.isEmpty || _endTime.isEmpty) return '加工開始・終了時間を入力してください / Start/end times required';
    if (_startTime == _endTime) {
      return '加工開始時間と加工終了時間は同じにできません\nStart Time and End Time cannot be the same';
    }
    try {
      final startParts = _startTime.split(':');
      final endParts = _endTime.split(':');
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      if (startMin >= endMin) {
        return '加工開始時間は加工終了時間より前である必要があります\nStart Time must be before End Time';
      }
    } catch (_) {
      return '加工時間の形式が正しくありません / Invalid work time format';
    }

    if (_materialLots.isEmpty) return '材料ロットを入力してください / Material lot number required';
    
    if (_materialLabelPhotos.length < _materialLots.length) {
      return '材料ラベルの写真が不足しています。ロット数: ${_materialLots.length}個、写真数: ${_materialLabelPhotos.length}枚\n'
             'Please capture a material label photo for each lot (Lots: ${_materialLots.length}, Photos: ${_materialLabelPhotos.length})';
    }

    if (!_hatsumonoChecked) return '初物チェックを完了してください / Please complete Hatsumono check';
    
    if (_isKensaEnabled) {
      if (_kensaName.isEmpty) return '検査者を選択または入力してください / Inspector name required';
      if (_kensaStartTime.isEmpty || _kensaEndTime.isEmpty) return '検査開始・終了時間を入力してください / Inspection times required';
      if (_kensaStartTime == _kensaEndTime) {
        return '検査開始時間と検査終了時間は同じにできません\nInspection Start and End Time cannot be the same';
      }
      try {
        final startParts = _kensaStartTime.split(':');
        final endParts = _kensaEndTime.split(':');
        final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        if (startMin >= endMin) {
          return '検査開始時間は検査終了時間より前である必要があります\nInspection Start Time must be before End Time';
        }
      } catch (_) {
        return '検査時間の形式が正しくありません / Invalid inspection time format';
      }
    }
    
    return null;
  }

  // Submit report to server
  Future<bool> submitReport() async {
    final validationError = validateForm();
    if (validationError != null) {
      throw Exception(validationError);
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      // Step 1: Read files and convert to base64
      String hatsumonoB64 = '';
      if (_hatsumonoPhotoPath.isNotEmpty) {
        final bytes = await _readFileBytes(_hatsumonoPhotoPath);
        if (bytes != null) hatsumonoB64 = base64Encode(bytes);
      }

      String atomonoB64 = '';
      if (_atomonoPhotoPath.isNotEmpty) {
        final bytes = await _readFileBytes(_atomonoPhotoPath);
        if (bytes != null) atomonoB64 = base64Encode(bytes);
      }

      final List<Map<String, dynamic>> cycleImages = [];
      if (hatsumonoB64.isNotEmpty) {
        cycleImages.add({
          'id': 'hatsumonoPic',
          'base64': hatsumonoB64,
          'description': 'Hatsumono Photo',
        });
      }
      if (atomonoB64.isNotEmpty) {
        cycleImages.add({
          'id': 'atomonoPic',
          'base64': atomonoB64,
          'description': 'Atomono Photo',
        });
      }

      // Read material label photos
      final List<Map<String, dynamic>> materialImages = [];
      for (int i = 0; i < _materialLabelPhotos.length; i++) {
        final bytes = await _readFileBytes(_materialLabelPhotos[i]);
        if (bytes != null) {
          materialImages.add({
            'id': 'materialLabelPic_$i',
            'base64': base64Encode(bytes),
            'description': 'Material Label Photo $i',
          });
        }
      }

      // Read maintenance trouble photos
      final List<Map<String, dynamic>> maintImages = [];
      final List<Map<String, dynamic>> maintRecords = [];

      for (var record in _maintenanceRecords) {
        maintRecords.add({
          'id': record.id,
          'startTime': record.startTime,
          'endTime': record.endTime,
          'comment': record.comment,
          'timestamp': record.timestamp,
        });

        for (var photo in record.photos) {
          final bytes = await _readFileBytes(photo.localPath);
          if (bytes != null) {
            maintImages.add({
              'id': photo.id,
              'base64': base64Encode(bytes),
              'timestamp': photo.timestamp,
              'maintenanceRecordId': record.id,
            });
          }
        }
      }

      // Step 2: Build submission payload
      final dateStr = DateFormat('yyyy-MM-dd').format(_workDate);
      final payload = {
        '品番': _activeProduct.productNumber,
        '背番号': _sebanggo,
        '設備': _selectedMachine,
        'Total': finalGoodQuantity,
        '工場': _selectedFactory,
        'Worker_Name': _workerName,
        'Process_Quantity': _processQuantity,
        'Date': dateStr,
        'Time_start': _startTime,
        'Time_end': _endTime,
        '材料ロット': _materialLots.join(','),
        '疵引不良': _defectPull,
        '加工不良': _processingDefect,
        'その他': _otherDefect,
        'Total_NG': totalNG,
        'Spare': _spare,
        'Comment': _commentsDcp,
        'Cycle_Time': '',
        'ショット数': _shotCount,
        'Break_Time_Data': _breaks,
        'Total_Break_Minutes': totalBreakMinutes,
        'Total_Break_Hours': double.parse(totalBreakHours.toStringAsFixed(2)),
        'Maintenance_Data': {
          'records': maintRecords,
          'totalMinutes': totalTroubleMinutes,
          'totalHours': double.parse(totalTroubleHours.toStringAsFixed(2)),
        },
        'Total_Trouble_Minutes': totalTroubleMinutes,
        'Total_Trouble_Hours': double.parse(totalTroubleHours.toStringAsFixed(2)),
        'Total_Work_Hours': double.parse(totalWorkHours.toStringAsFixed(2)),
        'images': cycleImages,
        'maintenanceImages': maintImages,
        'materialLabelImages': materialImages,
        'isToggleChecked': _isKensaEnabled,
      };

      if (_isKensaEnabled) {
        payload['Counters'] = {
          for (int i = 0; i < 12; i++) 'counter-${i + 1}': _kensaCounters[i]
        };
        payload['Inspector_Name'] = _kensaName;
        payload['Inspection_Date'] = DateFormat('yyyy-MM-dd').format(_kensaDate);
        payload['Inspection_Time_start'] = _kensaStartTime;
        payload['Inspection_Time_end'] = _kensaEndTime;
        payload['Inspection_Comment'] = _commentsKensa;
        payload['Inspection_Spare'] = _spare;
        
        int kensaNG = 0;
        for (var count in _kensaCounters) {
          kensaNG += count;
        }
        payload['Inspection_Total_NG'] = kensaNG;
        payload['Inspection_Good_Total'] = finalGoodQuantity;
      }

      final result = await _apiService.submitToDCP(payload);
      if (result['success'] == true) {
        logTabletAction('Submit button pressed', 'Completed', {
          'shotCount': _shotCount,
          '品番': _activeProduct.productNumber,
          '背番号': _sebanggo,
          '工場': _selectedFactory,
          '設備': _selectedMachine,
          'processQuantity': _processQuantity,
          'totalNG': totalNG,
        });

        // Clean up
        await _storageService.clearDraft(_selectedFactory, _selectedMachine);
        _resetFormFields();
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(result['error'] ?? 'Network Error');
      }
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<int>?> _readFileBytes(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return bytes.toList();
      }
    } catch (e) {
      // ignore read errors
    }
    return null;
  }

  // Load and save drafts JSON methods
  void saveDraft() async {
    final draftMap = {
      'sebanggo': _sebanggo,
      'sessionID': _sessionID,
      'workerName': _workerName,
      'processQuantity': _processQuantity,
      'workDate': _workDate.toIso8601String(),
      'labelExtension': _labelExtension,
      'startTime': _startTime,
      'endTime': _endTime,
      'shotCount': _shotCount,
      'materialLots': _materialLots,
      'defectPull': _defectPull,
      'processingDefect': _processingDefect,
      'otherDefect': _otherDefect,
      'commentsDcp': _commentsDcp,
      'hatsumonoPhotoPath': _hatsumonoPhotoPath,
      'hatsumonoChecked': _hatsumonoChecked,
      'atomonoPhotoPath': _atomonoPhotoPath,
      'atomonoChecked': _atomonoChecked,
      'materialLabelPhotos': _materialLabelPhotos,
      'lotToPhotoMap': _lotToPhotoMap,
      'isKensaEnabled': _isKensaEnabled,
      'kensaName': _kensaName,
      'kensaDate': _kensaDate.toIso8601String(),
      'kensaStartTime': _kensaStartTime,
      'kensaEndTime': _kensaEndTime,
      'kensaCounters': _kensaCounters,
      'spare': _spare,
      'commentsKensa': _commentsKensa,
      'breaks': _breaks,
      'maintenanceRecords': _maintenanceRecords.map((r) => r.toJson()).toList(),
      'setupStep': _setupStep,
      'appStage': _appStage.name,
      'groupedShots': _groupedShots,
    };
    notifyListeners();
    await _storageService.saveDraft(_selectedFactory, _selectedMachine, draftMap);
  }

  void _restoreFromDraftMap(Map<String, dynamic> draft) {
    _sebanggo = draft['sebanggo'] ?? '';
    _sessionID = draft['sessionID'] ?? '';
    _workerName = draft['workerName'] ?? '';
    _processQuantity = draft['processQuantity'] ?? 0;
    _workDate = draft['workDate'] != null ? DateTime.parse(draft['workDate']) : DateTime.now();
    _labelExtension = draft['labelExtension'] ?? '';
    _startTime = draft['startTime'] ?? '';
    _endTime = draft['endTime'] ?? '';
    _shotCount = draft['shotCount'] ?? 0;
    _materialLots = List<String>.from(draft['materialLots'] ?? []);
    _setupStep = draft['setupStep'] ?? 1;
    _defectPull = draft['defectPull'] ?? 0;
    _processingDefect = draft['processingDefect'] ?? 0;
    _otherDefect = draft['otherDefect'] ?? 0;
    _commentsDcp = draft['commentsDcp'] ?? '';
    
    _hatsumonoPhotoPath = draft['hatsumonoPhotoPath'] ?? '';
    _hatsumonoChecked = draft['hatsumonoChecked'] ?? false;
    _atomonoPhotoPath = draft['atomonoPhotoPath'] ?? '';
    _atomonoChecked = draft['atomonoChecked'] ?? false;
    _materialLabelPhotos = List<String>.from(draft['materialLabelPhotos'] ?? []);
    final Map<String, dynamic>? lotToPhotoMapData = draft['lotToPhotoMap'] != null
        ? Map<String, dynamic>.from(draft['lotToPhotoMap'])
        : null;
    if (lotToPhotoMapData != null) {
      _lotToPhotoMap = lotToPhotoMapData.map((k, v) => MapEntry(k, v as String));
    } else {
      _lotToPhotoMap = {};
    }

    _isKensaEnabled = draft['isKensaEnabled'] ?? false;
    _kensaName = draft['kensaName'] ?? '';
    _kensaDate = draft['kensaDate'] != null ? DateTime.parse(draft['kensaDate']) : DateTime.now();
    _kensaStartTime = draft['kensaStartTime'] ?? '';
    _kensaEndTime = draft['kensaEndTime'] ?? '';
    _kensaCounters = List<int>.from(draft['kensaCounters'] ?? List.filled(12, 0));
    _spare = draft['spare'] ?? 0;
    _commentsKensa = draft['commentsKensa'] ?? '';

    var breaksList = draft['breaks'] as List? ?? [];
    for (int i = 0; i < breaksList.length && i < 4; i++) {
      _breaks[i]['start'] = breaksList[i]['start'] ?? '';
      _breaks[i]['end'] = breaksList[i]['end'] ?? '';
    }

    var maintList = draft['maintenanceRecords'] as List? ?? [];
    _maintenanceRecords = maintList.map((r) => MaintenanceRecord.fromJson(r as Map<String, dynamic>)).toList();

    final String stageName = draft['appStage'] ?? 'scan';
    _appStage = AppStage.values.firstWhere(
      (e) => e.name == stageName,
      orElse: () => AppStage.scan,
    );

    final Map<String, dynamic>? groupedMap = draft['groupedShots'] != null 
        ? Map<String, dynamic>.from(draft['groupedShots']) 
        : null;
    if (groupedMap != null) {
      _groupedShots = groupedMap.map((k, v) => MapEntry(k, v as int));
    } else {
      _groupedShots = {};
      if (_selectedMachine.contains(',')) {
        final list = _selectedMachine.split(',');
        for (var m in list) {
          _groupedShots[m] = 0;
        }
      }
    }

    if (_sebanggo.isNotEmpty) {
      _fetchProductInfo();
    }
  }

  void resetForm() async {
    _resetFormFields();
    await _storageService.clearDraft(_selectedFactory, _selectedMachine);
    NCPresstoFalse();
    logTabletAction('Reset', 'Completed', {});
    notifyListeners();
  }

  void _resetFormFields() {
    _sebanggo = '';
    _sessionID = '';
    _activeProduct = Product.empty();
    _setupStep = 1;
    _appStage = AppStage.scan;
    _workerName = '';
    _processQuantity = 0;
    _workDate = DateTime.now();
    _labelExtension = '';
    _startTime = '';
    _endTime = '';
    _shotCount = 0;
    _materialLots = [];
    _defectPull = 0;
    _processingDefect = 0;
    _otherDefect = 0;
    _commentsDcp = '';
    
    _hatsumonoPhotoPath = '';
    _hatsumonoChecked = false;
    _atomonoPhotoPath = '';
    _atomonoChecked = false;
    _materialLabelPhotos = [];
    _lotToPhotoMap = {};

    _isKensaEnabled = false;
    _kensaName = '';
    _kensaDate = DateTime.now();
    _kensaStartTime = '';
    _kensaEndTime = '';
    _kensaCounters = List.filled(12, 0);
    _spare = 0;
    _commentsKensa = '';

    _groupedShots = {};
    if (_selectedMachine.contains(',')) {
      final list = _selectedMachine.split(',');
      for (var m in list) {
        _groupedShots[m] = 0;
      }
    }

    for (var b in _breaks) {
      b['start'] = '';
      b['end'] = '';
    }
    _maintenanceRecords = [];
  }

  @override
  void dispose() {
    _logSyncTimer?.cancel();
    _apiService.dispose();
    super.dispose();
  }
}
