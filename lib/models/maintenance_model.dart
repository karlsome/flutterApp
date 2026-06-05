import 'dart:convert';
import 'dart:io';

class MaintenancePhoto {
  final String id;
  final String localPath;
  final String timestamp;

  MaintenancePhoto({
    required this.id,
    required this.localPath,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      'timestamp': timestamp,
    };
  }

  factory MaintenancePhoto.fromJson(Map<String, dynamic> json) {
    return MaintenancePhoto(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  Future<String> toBase64() async {
    final file = File(localPath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }
    return '';
  }
}

class MaintenanceRecord {
  final String id;
  final String startTime;
  final String endTime;
  final String comment;
  final String timestamp;
  final List<MaintenancePhoto> photos;

  MaintenanceRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.comment,
    required this.timestamp,
    required this.photos,
  });

  int get durationMinutes {
    if (startTime.isEmpty || endTime.isEmpty) return 0;
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      if (startParts.length < 2 || endParts.length < 2) return 0;
      
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      
      // If end time is before start time, assume it spans to next day (or return difference)
      if (endMin >= startMin) {
        return endMin - startMin;
      } else {
        // Crosses midnight
        return (24 * 60 - startMin) + endMin;
      }
    } catch (e) {
      return 0;
    }
  }

  double get durationHours => durationMinutes / 60.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'comment': comment,
      'timestamp': timestamp,
      'photos': photos.map((p) => p.toJson()).toList(),
    };
  }

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    var rawPhotos = json['photos'] as List? ?? [];
    List<MaintenancePhoto> photoList = rawPhotos
        .map((p) => MaintenancePhoto.fromJson(p as Map<String, dynamic>))
        .toList();

    return MaintenanceRecord(
      id: json['id'] as String,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      photos: photoList,
    );
  }
}
