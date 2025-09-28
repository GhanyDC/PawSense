import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

/// Service for communicating with YOLO detection backend API
class PetDetectionService {
  static final PetDetectionService _instance = PetDetectionService._internal();
  factory PetDetectionService() => _instance;
  PetDetectionService._internal();

  // API Configuration - Railway backend server
  static const String baseUrl = 'https://pawsensebackend-production.up.railway.app';
  static const int timeoutSeconds = 30;
  
  // Supported pet types for API endpoints
  static const String CATS = 'cats';
  static const String DOGS = 'dogs';

  /// Health check to verify backend connectivity
  Future<HealthStatus> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HealthStatus.fromMap(data);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Health check failed: $e');
      return HealthStatus(status: 'error', message: e.toString());
    }
  }

  /// Detect skin conditions for pets using the backend API
  Future<DetectionResult> detectConditions({
    required File imageFile,
    required String petType, // 'cats' or 'dogs'
  }) async {
    if (petType != CATS && petType != DOGS) {
      throw ArgumentError('Pet type must be "cats" or "dogs"');
    }

    try {
      print('🔍 Sending detection request for $petType...');
      print('📁 Image file: ${imageFile.path}');
      
      // Validate file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }
      
      final int fileSize = await imageFile.length();
      print('📊 Image size: ${_formatFileSize(fileSize)}');
      
      // Check file size (limit to 10MB)
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSizeBytes) {
        throw Exception('Image file too large. Maximum size: ${_formatFileSize(maxSizeBytes)}');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/detect/$petType'),
      );
      
      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );
      
      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
      });
      
      print('🚀 Sending request to: $baseUrl/detect/$petType');
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: timeoutSeconds),
      );
      
      // Get response
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('✅ Detection successful: ${responseData['total_detections']} detections found');
        
        return DetectionResult.fromMap(responseData);
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw Exception('Detection failed (${response.statusCode}): $errorMessage');
      }
      
    } on TimeoutException {
      throw Exception('Request timed out after $timeoutSeconds seconds. Please check your internet connection.');
    } on SocketException {
      throw Exception('Unable to connect to detection server. Please ensure the server is running and accessible.');
    } on HttpException {
      throw Exception('HTTP error occurred. Please check your network connection.');
    } catch (e) {
      print('❌ Detection error: $e');
      rethrow;
    }
  }
  
  /// Parse error message from response
  String _parseErrorMessage(http.Response response) {
    try {
      final Map<String, dynamic> errorData = json.decode(response.body);
      return errorData['detail'] ?? errorData['message'] ?? 'Unknown error';
    } catch (e) {
      return response.body.isNotEmpty ? response.body : 'Unknown error';
    }
  }
  
  /// Format file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Health status response model
class HealthStatus {
  final String status;
  final String message;
  final String? version;
  final DateTime? timestamp;

  HealthStatus({
    required this.status,
    required this.message,
    this.version,
    this.timestamp,
  });

  factory HealthStatus.fromMap(Map<String, dynamic> map) {
    return HealthStatus(
      status: map['status'] ?? 'unknown',
      message: map['message'] ?? '',
      version: map['version'],
      timestamp: map['timestamp'] != null 
          ? DateTime.tryParse(map['timestamp']) 
          : null,
    );
  }

  bool get isHealthy => status == 'healthy' || status == 'ok';
}

/// Detection result model matching the FastAPI backend response
class DetectionResult {
  final String filename;
  final ModelInfo modelInfo;
  final List<Detection> detections;
  final int totalDetections;

  DetectionResult({
    required this.filename,
    required this.modelInfo,
    required this.detections,
    required this.totalDetections,
  });

  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    return DetectionResult(
      filename: map['filename'] ?? '',
      modelInfo: ModelInfo.fromMap(map['model_info'] ?? {}),
      detections: (map['detections'] as List<dynamic>? ?? [])
          .map((detection) => Detection.fromMap(detection))
          .toList(),
      totalDetections: map['total_detections'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'filename': filename,
      'model_info': modelInfo.toMap(),
      'detections': detections.map((detection) => detection.toMap()).toList(),
      'total_detections': totalDetections,
    };
  }
}

/// Model information from the backend
class ModelInfo {
  final String description;
  final String author;
  final String version;
  final String task;
  final Map<String, String> names;

  ModelInfo({
    required this.description,
    required this.author,
    required this.version,
    required this.task,
    required this.names,
  });

  factory ModelInfo.fromMap(Map<String, dynamic> map) {
    final namesMap = <String, String>{};
    final names = map['names'] ?? {};
    if (names is Map) {
      names.forEach((key, value) {
        namesMap[key.toString()] = value.toString();
      });
    }

    return ModelInfo(
      description: map['description'] ?? '',
      author: map['author'] ?? '',
      version: map['version'] ?? '',
      task: map['task'] ?? '',
      names: namesMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'author': author,
      'version': version,
      'task': task,
      'names': names,
    };
  }
}

/// Individual detection result
class Detection {
  final int classId;
  final String label;
  final double confidence;
  final List<double> bbox; // [x1, y1, x2, y2]

  Detection({
    required this.classId,
    required this.label,
    required this.confidence,
    required this.bbox,
  });

  factory Detection.fromMap(Map<String, dynamic> map) {
    final bboxList = (map['bbox'] as List<dynamic>? ?? [])
        .map((coord) => coord.toDouble())
        .toList()
        .cast<double>();
    
    return Detection(
      classId: map['class_id'] ?? 0,
      label: map['label'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      bbox: bboxList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'label': label,
      'confidence': confidence,
      'bbox': bbox,
    };
  }

  /// Convert to the format expected by the existing codebase
  Map<String, dynamic> toYoloFormat() {
    return {
      'label': label,
      'confidence': confidence,
      'classId': classId,
      'box': bbox, // [x1, y1, x2, y2]
      'rect': {
        'left': bbox[0],
        'top': bbox[1],
        'width': bbox[2] - bbox[0],
        'height': bbox[3] - bbox[1],
      },
    };
  }
}

/// Pet assessment data model
class PetAssessment {
  final String petName;
  final String petType;
  final int petAge;
  final String breed;
  final String gender;
  final String ownerName;
  final DateTime assessmentDate;
  final List<File> images;
  final DetectionResult? result;
  final DateTime createdAt;
  
  // Optional fields
  final String? petWeight;
  final String? medicalHistory;
  final String? currentSymptoms;

  PetAssessment({
    required this.petName,
    required this.petType,
    required this.petAge,
    required this.breed,
    required this.gender,
    required this.ownerName,
    required this.assessmentDate,
    required this.images,
    this.result,
    required this.createdAt,
    this.petWeight,
    this.medicalHistory,
    this.currentSymptoms,
  });

  Map<String, dynamic> toMap() {
    return {
      'petName': petName,
      'petType': petType,
      'petAge': petAge,
      'breed': breed,
      'gender': gender,
      'ownerName': ownerName,
      'assessmentDate': assessmentDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'petWeight': petWeight,
      'medicalHistory': medicalHistory,
      'currentSymptoms': currentSymptoms,
      'result': result?.toMap(),
    };
  }
}

/// Configuration class for API settings
class AppConfig {
  static const String apiBaseUrl = 'https://pawsensebackend-production.up.railway.app';
  static const int maxImagesPerAssessment = 5;
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> supportedPetTypes = ['cats', 'dogs'];
}