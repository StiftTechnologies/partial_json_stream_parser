import 'package:partial_json_stream_parser/partial_json_stream_parser.dart';

void main() {
  // Example 1: Basic usage with incomplete JSON
  print('=== Example 1: Basic Incomplete JSON ===');
  final parser = PartialJsonParser();
  
  final incompleteJson = '{"name": "John Doe", "age": 30, "is_student": false, "courses": ["Math", "Science"';
  final result = parser.parse(incompleteJson);
  print('Input: $incompleteJson');
  print('Parsed: $result');
  print('');

  // Example 2: Strict vs Non-strict mode for newlines
  print('=== Example 2: Strict vs Non-Strict Mode ===');
  final strictParser = PartialJsonParser(strict: true);
  final nonStrictParser = PartialJsonParser(strict: false);
  
  final jsonWithNewline = '{"text": "Line 1\\nLine 2"}';
  print('Input: $jsonWithNewline');
  print('Strict mode result: ${strictParser.parse(jsonWithNewline)}');
  
  final rawNewlineJson = '{"text": "Line 1\nLine 2"}';
  print('Non-strict with raw newline: ${nonStrictParser.parse(rawNewlineJson)}');
  print('');

  // Example 3: Streaming simulation (like from an LLM)
  print('=== Example 3: Simulated Streaming Response ===');
  final streamingChunks = [
    '{"resp',
    '{"response": "Hello',
    '{"response": "Hello, how can I',
    '{"response": "Hello, how can I help',
    '{"response": "Hello, how can I help you',
    '{"response": "Hello, how can I help you today?',
    '{"response": "Hello, how can I help you today?"',
    '{"response": "Hello, how can I help you today?"}',
  ];

  for (final chunk in streamingChunks) {
    final parsed = parser.parse(chunk);
    print('Chunk: ${chunk.padRight(50)} => $parsed');
  }
  print('');

  // Example 4: Complex nested structure
  print('=== Example 4: Complex Nested Structure ===');
  final complexJson = '''
  {
    "web-app": {
      "servlet": [
        {
          "servlet-name": "cofaxCDS",
          "servlet-class": "org.cofax.cds.CDSServlet",
          "init-param": {
            "configGlossary:installationAt": "Philadelphia, PA",
            "configGlossary:adminEmail": "ksm@pobox.com",
            "configGlossary:poweredBy": "Cofax",
            "dataStoreConnUsageLimit": 100,
            "dataStoreLogLevel": "debug"
  ''';
  
  final complexResult = parser.parse(complexJson);
  print('Complex nested JSON parsed successfully:');
  _printJson(complexResult);
  print('');

  // Example 5: Handling various incomplete types
  print('=== Example 5: Various Incomplete Types ===');
  final testCases = [
    '{"value": 42.',           // Trailing decimal
    '{"active": t',             // Incomplete true
    '{"data": n',               // Incomplete null
    '{"items": [1, 2, 3',       // Incomplete array
    '{"user": {"name": "Alice"', // Nested incomplete object
    '{"text": "test\\u00',      // Incomplete escape sequence
  ];

  for (final testCase in testCases) {
    final result = parser.parse(testCase);
    print('Input: ${testCase.padRight(30)} => $result');
  }
  print('');

  // Example 6: Extra token callback
  print('=== Example 6: Extra Token Callback ===');
  final parserWithCallback = PartialJsonParser(
    onExtraToken: (text, data, remaining) {
      print('Extra tokens detected!');
      print('  Original text: $text');
      print('  Parsed data: $data');
      print('  Remaining: "$remaining"');
    },
  );

  final jsonWithExtra = '{"key": "value"} some extra text';
  final resultWithExtra = parserWithCallback.parse(jsonWithExtra);
  print('Result: $resultWithExtra');
  print('');

  // Example 7: Real-world use case - parsing LLM tool calls
  print('=== Example 7: LLM Tool Call Response ===');
  final llmResponse = '''
  {
    "id": "call_abc123",
    "type": "function",
    "function": {
      "name": "get_weather",
      "arguments": "{\\"location\\": \\"San Francisco\\", \\"unit\\": \\"celsius\\"
  ''';

  final llmResult = parser.parse(llmResponse);
  print('LLM tool call parsed:');
  _printJson(llmResult);
  print('');

  // Example 8: Progressive parsing demonstration
  print('=== Example 8: Progressive Parsing ===');
  final progressiveJson = '{"users": [{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}, {"name": "Charlie"';
  
  // Simulate receiving data progressively
  String accumulated = '';
  for (int i = 0; i < progressiveJson.length; i += 10) {
    final end = (i + 10 > progressiveJson.length) ? progressiveJson.length : i + 10;
    accumulated = progressiveJson.substring(0, end);
    
    try {
      final result = parser.parse(accumulated);
      print('After ${accumulated.length} chars: ${_summarizeResult(result)}');
    } catch (e) {
      print('After ${accumulated.length} chars: Cannot parse yet');
    }
  }
}

// Helper function to pretty print JSON
void _printJson(dynamic json, {String indent = '  '}) {
  if (json is Map) {
    print('{');
    json.forEach((key, value) {
      if (value is Map || value is List) {
        print('$indent"$key": ');
        _printJson(value, indent: '$indent  ');
      } else {
        print('$indent"$key": ${_formatValue(value)}');
      }
    });
    print('${indent.substring(2)}}');
  } else if (json is List) {
    print('[');
    for (var item in json) {
      if (item is Map || item is List) {
        _printJson(item, indent: '$indent  ');
      } else {
        print('$indent${_formatValue(item)}');
      }
    }
    print('${indent.substring(2)}]');
  } else {
    print(_formatValue(json));
  }
}

String _formatValue(dynamic value) {
  if (value is String) return '"$value"';
  return value.toString();
}

String _summarizeResult(dynamic result) {
  if (result is Map) {
    final keys = result.keys.join(', ');
    return 'Object with keys: [$keys]';
  } else if (result is List) {
    return 'Array with ${result.length} items';
  } else {
    return result.toString();
  }
}
