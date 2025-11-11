# Generate Solution API Tests

This directory contains tests for the `generate-solution` API endpoint.

## API Endpoint
- **URL**: `https://solution-by-ai.vercel.app/api/generate-solution`
- **Method**: POST
- **Content-Type**: application/json

## Request Body Format
```json
{
  "title": "Problem title",
  "description": "Detailed description of the problem",
  "imageBase64": "base64_encoded_image_string"
}
```

## Expected Response Format
```json
{
  "solution": "AI-generated solution in Portuguese"
}
```

## Running the Tests

### Run all API tests
```bash
flutter test test/api/generate_solution_api_test.dart
```

### Run with verbose output
```bash
flutter test test/api/generate_solution_api_test.dart --reporter expanded
```

### Run a specific test
```bash
flutter test test/api/generate_solution_api_test.dart --name "Should successfully generate a solution"
```

## Test Coverage

### Unit Tests
1. ✅ Successfully generate solution with valid data
2. ✅ Handle empty title
3. ✅ Handle empty description
4. ✅ Handle missing imageBase64 field
5. ✅ Return valid JSON structure
6. ✅ Handle malformed request body
7. ✅ Verify solution content is in Portuguese
8. ✅ Generate different solutions for different problems
9. ✅ Handle network timeout gracefully

### Integration Tests (Real World Scenarios)
1. ✅ Water container problem
2. ✅ Vegetation problem
3. ✅ Abandoned tire problem

## Test Scenarios

### Scenario 1: Valid Request
- **Input**: Title, description, and base64 image
- **Expected**: 200 status code with valid solution text

### Scenario 2: Empty Fields
- **Input**: Empty title or description
- **Expected**: Appropriate error handling (400/422) or default behavior

### Scenario 3: Missing Fields
- **Input**: Request without imageBase64
- **Expected**: Graceful error handling

### Scenario 4: Invalid JSON
- **Input**: Malformed JSON body
- **Expected**: 400/422 error status

### Scenario 5: Portuguese Language Check
- **Input**: Valid request
- **Expected**: Solution contains Portuguese words related to mosquito prevention

## Important Notes

⚠️ **These are integration tests** that make real HTTP requests to the API endpoint. They require:
- Active internet connection
- API endpoint to be accessible
- May take longer to execute (timeouts set to 60 seconds)

## Troubleshooting

### Tests timing out
If tests are timing out, it may indicate:
- Network connectivity issues
- API server is down or slow
- Firewall blocking requests

Solution: Increase timeout duration or check network connection

### API returning errors
Check:
- API endpoint URL is correct
- Request format matches API expectations
- API service is operational

## Dependencies Required

Make sure these are in your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  http: ^1.3.0
```

## CI/CD Integration

To skip these tests in CI/CD (if you don't want to hit the live API):

```bash
# Run only unit tests, excluding API integration tests
flutter test --exclude-tags=integration
```

To enable this, add tags to test groups:
```dart
group('Generate Solution API Tests', tags: ['integration'], () {
  // tests here
});
```

## Performance Expectations

- **Average response time**: 5-15 seconds
- **Timeout threshold**: 60 seconds
- **Success rate**: Should be >95% with stable internet

## Contact

For API-specific issues, contact the MapaZZZ backend team.
