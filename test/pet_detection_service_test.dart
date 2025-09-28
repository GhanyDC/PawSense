import 'package:flutter_test/flutter_test.dart';
import 'package:pawsense/core/services/pet_detection_service.dart';

void main() {
  group('PetDetectionService Railway Backend Tests', () {
    late PetDetectionService service;

    setUp(() {
      service = PetDetectionService();
    });

    test('Health check should return healthy status', () async {
      final health = await service.checkServerHealth();
      
      expect(health.status, equals('healthy'));
      expect(health.modelsLoaded, contains('cats'));
      expect(health.modelsLoaded, contains('dogs'));
      expect(health.availableModels, contains('cats'));
      expect(health.availableModels, contains('dogs'));
      expect(health.isHealthy, isTrue);
    });

    test('Should validate pet type correctly', () {
      expect(
        () => service.detectConditions(
          imageFile: null as dynamic,
          petType: 'invalid_type',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Constants should match backend endpoints', () {
      expect(PetDetectionService.CATS, equals('cats'));
      expect(PetDetectionService.DOGS, equals('dogs'));
      expect(PetDetectionService.baseUrl, 
             equals('https://pawsensebackend-production.up.railway.app'));
    });

    test('AppConfig should have correct values', () {
      expect(AppConfig.maxImageSizeBytes, equals(10 * 1024 * 1024));
      expect(AppConfig.supportedImageTypes, 
             containsAll(['jpg', 'jpeg', 'png', 'bmp', 'tiff']));
      expect(AppConfig.supportedPetTypes, containsAll(['cats', 'dogs']));
    });
  });
}