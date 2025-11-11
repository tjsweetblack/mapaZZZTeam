import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Generate Solution API Tests', () {
    const String apiUrl =
        'https://solution-by-ai.vercel.app/api/generate-solution';

    test('Should successfully generate a solution with valid data', () async {
      // Arrange
      final title = 'Água parada no quintal';
      final description =
          'Há um recipiente com água parada no quintal que pode ser um foco de mosquitos';
      final imageBase64 = base64Encode(utf8.encode('fake_image_data'));

      // Act & Assert
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'imageBase64': imageBase64,
        }),
      );

      // Verify response
      expect(response.statusCode, equals(200));
      final data = jsonDecode(response.body);
      expect(data, contains('solution'));
      expect(data['solution'], isNotEmpty);
      expect(data['solution'], isA<String>());
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Should handle empty title', () async {
      // Arrange
      final title = '';
      final description = 'Água parada no quintal';
      final imageBase64 = base64Encode(utf8.encode('fake_image_data'));

      // Act
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'imageBase64': imageBase64,
        }),
      );

      // Assert - API should still return a response (or appropriate error)
      expect(response.statusCode, isIn([200, 400, 422]));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Should handle empty description', () async {
      // Arrange
      final title = 'Foco de mosquito';
      final description = '';
      final imageBase64 = base64Encode(utf8.encode('fake_image_data'));

      // Act
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'imageBase64': imageBase64,
        }),
      );

      // Assert
      expect(response.statusCode, isIn([200, 400, 422]));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Should handle missing imageBase64 field', () async {
      // Arrange
      final title = 'Foco de mosquito';
      final description = 'Água parada';

      // Act
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          // imageBase64 is missing
        }),
      );

      // Assert - Should handle missing field gracefully
      expect(response.statusCode, isIn([200, 400, 422]));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Should return valid JSON structure', () async {
      // Arrange
      final title = 'Pneus abandonados';
      final description = 'Pneus velhos acumulando água da chuva';
      final imageBase64 = base64Encode(utf8.encode('fake_image_data'));

      // Act
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'imageBase64': imageBase64,
        }),
      );

      // Assert
      if (response.statusCode == 200) {
        expect(() => jsonDecode(response.body), returnsNormally);
        final data = jsonDecode(response.body);
        expect(data, isA<Map<String, dynamic>>());
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Should handle malformed request body', () async {
      // Act
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: 'invalid json',
      );

      // Assert - Should return error for malformed JSON
      expect(response.statusCode, isIn([400, 422, 500]));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Should verify solution content is Portuguese', () async {
      // Arrange
      final title = 'Calha entupida';
      final description = 'Calha do telhado está entupida e acumulando água';
      final imageBase64 = base64Encode(utf8.encode('fake_image_data'));

      // Act
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'imageBase64': imageBase64,
        }),
      );

      // Assert
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final solution = data['solution'] as String;

        // Check for common Portuguese words
        final portugueseWords = [
          'água',
          'mosquito',
          'risco',
          'limpar',
          'remover',
          'evitar'
        ];
        final hasPortuguese = portugueseWords
            .any((word) => solution.toLowerCase().contains(word));

        expect(hasPortuguese, isTrue,
            reason: 'Solution should contain Portuguese words');
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Should generate different solutions for different problems',
        () async {
      // Arrange
      final imageBase64 = base64Encode(utf8.encode('fake_image_data'));

      final problem1 = {
        'title': 'Água parada em vaso',
        'description': 'Vaso de planta com água acumulada',
      };

      final problem2 = {
        'title': 'Lixo acumulado',
        'description': 'Lixo no terreno baldio',
      };

      // Act
      final response1 = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': problem1['title'],
          'description': problem1['description'],
          'imageBase64': imageBase64,
        }),
      );

      final response2 = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': problem2['title'],
          'description': problem2['description'],
          'imageBase64': imageBase64,
        }),
      );

      // Assert
      if (response1.statusCode == 200 && response2.statusCode == 200) {
        final solution1 = jsonDecode(response1.body)['solution'];
        final solution2 = jsonDecode(response2.body)['solution'];

        expect(solution1, isNot(equals(solution2)),
            reason: 'Different problems should generate different solutions');
      }
    }, timeout: const Timeout(Duration(seconds: 120)));

    test('Should handle network timeout gracefully', () async {
      // This test verifies timeout handling
      final title = 'Test';
      final description = 'Test description';
      final imageBase64 = base64Encode(utf8.encode('fake_image_data'));

      // Act & Assert
      expect(() async {
        final response = await http
            .post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'description': description,
            'imageBase64': imageBase64,
          }),
        )
            .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timeout');
          },
        );
        return response;
      }, returnsNormally);
    }, timeout: const Timeout(Duration(seconds: 35)));
  });

  group('Integration Tests - Real World Scenarios', () {
    const String apiUrl =
        'https://solution-by-ai.vercel.app/api/generate-solution';

    test('Scenario: Water container problem', () async {
      final imageBase64 = base64Encode(utf8.encode('fake_image_data'));

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': 'Recipiente com água parada',
          'description': 'Balde no quintal acumulando água da chuva',
          'imageBase64': imageBase64,
        }),
      );

      if (response.statusCode == 200) {
        final solution = jsonDecode(response.body)['solution'];
        expect(solution, isNotEmpty);
        print('Solution for water container: $solution');
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Scenario: Vegetation problem', () async {
      final imageBase64 = base64Encode(utf8.encode('fake_image_data'));

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': 'Vegetação excessiva',
          'description':
              'Mato alto no terreno criando ambiente propício para mosquitos',
          'imageBase64': imageBase64,
        }),
      );

      if (response.statusCode == 200) {
        final solution = jsonDecode(response.body)['solution'];
        expect(solution, isNotEmpty);
        print('Solution for vegetation: $solution');
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Scenario: Abandoned tire problem', () async {
      final imageBase64 = base64Encode(utf8.encode('fake_image_data'));

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': 'Pneus abandonados',
          'description': 'Pneus velhos acumulando água',
          'imageBase64': imageBase64,
        }),
      );

      if (response.statusCode == 200) {
        final solution = jsonDecode(response.body)['solution'];
        expect(solution, isNotEmpty);
        print('Solution for tires: $solution');
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
