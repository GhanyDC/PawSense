import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentResult {
  final String? id;
  final String userId;
  final String petId;
  final String petName;
  final String petType;
  final String petBreed;
  final int petAge;
  final double petWeight;
  final List<String> symptoms;
  final List<String> imageUrls;
  final String notes;
  final String duration;
  final List<DetectionResult> detectionResults;
  final List<AnalysisResultData> analysisResults;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssessmentResult({
    this.id,
    required this.userId,
    required this.petId,
    required this.petName,
    required this.petType,
    required this.petBreed,
    required this.petAge,
    required this.petWeight,
    required this.symptoms,
    required this.imageUrls,
    required this.notes,
    required this.duration,
    required this.detectionResults,
    required this.analysisResults,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert AssessmentResult to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'petId': petId,
      'petName': petName,
      'petType': petType,
      'petBreed': petBreed,
      'petAge': petAge,
      'petWeight': petWeight,
      'symptoms': symptoms,
      'imageUrls': imageUrls,
      'notes': notes,
      'duration': duration,
      'detectionResults': detectionResults.map((result) => result.toMap()).toList(),
      'analysisResults': analysisResults.map((result) => result.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create AssessmentResult from Firestore document
  factory AssessmentResult.fromMap(Map<String, dynamic> map, String documentId) {
    return AssessmentResult(
      id: documentId,
      userId: map['userId'] ?? '',
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? '',
      petType: map['petType'] ?? '',
      petBreed: map['petBreed'] ?? '',
      petAge: map['petAge']?.toInt() ?? 0,
      petWeight: map['petWeight']?.toDouble() ?? 0.0,
      symptoms: List<String>.from(map['symptoms'] ?? []),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      notes: map['notes'] ?? '',
      duration: map['duration'] ?? '',
      detectionResults: (map['detectionResults'] as List<dynamic>? ?? [])
          .map((result) => DetectionResult.fromMap(result))
          .toList(),
      analysisResults: (map['analysisResults'] as List<dynamic>? ?? [])
          .map((result) => AnalysisResultData.fromMap(result))
          .toList(),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create a copy with updated fields
  AssessmentResult copyWith({
    String? id,
    String? userId,
    String? petId,
    String? petName,
    String? petType,
    String? petBreed,
    int? petAge,
    double? petWeight,
    List<String>? symptoms,
    List<String>? imageUrls,
    String? notes,
    String? duration,
    List<DetectionResult>? detectionResults,
    List<AnalysisResultData>? analysisResults,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssessmentResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      petBreed: petBreed ?? this.petBreed,
      petAge: petAge ?? this.petAge,
      petWeight: petWeight ?? this.petWeight,
      symptoms: symptoms ?? this.symptoms,
      imageUrls: imageUrls ?? this.imageUrls,
      notes: notes ?? this.notes,
      duration: duration ?? this.duration,
      detectionResults: detectionResults ?? this.detectionResults,
      analysisResults: analysisResults ?? this.analysisResults,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DetectionResult {
  final String imageUrl;
  final List<Detection> detections;

  DetectionResult({
    required this.imageUrl,
    required this.detections,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'detections': detections.map((detection) => detection.toMap()).toList(),
    };
  }

  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    return DetectionResult(
      imageUrl: map['imageUrl'] ?? '',
      detections: (map['detections'] as List<dynamic>? ?? [])
          .map((detection) => Detection.fromMap(detection))
          .toList(),
    );
  }
}

class Detection {
  final String label;
  final double confidence;
  final List<double>? boundingBox;

  Detection({
    required this.label,
    required this.confidence,
    this.boundingBox,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
      'boundingBox': boundingBox,
    };
  }

  factory Detection.fromMap(Map<String, dynamic> map) {
    return Detection(
      label: map['label'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
      boundingBox: map['boundingBox'] != null 
          ? List<double>.from(map['boundingBox'])
          : null,
    );
  }
}

class AnalysisResultData {
  final String condition;
  final double percentage;
  final String colorHex;

  AnalysisResultData({
    required this.condition,
    required this.percentage,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'percentage': percentage,
      'colorHex': colorHex,
    };
  }

  factory AnalysisResultData.fromMap(Map<String, dynamic> map) {
    return AnalysisResultData(
      condition: map['condition'] ?? '',
      percentage: map['percentage']?.toDouble() ?? 0.0,
      colorHex: map['colorHex'] ?? '#000000',
    );
  }
}