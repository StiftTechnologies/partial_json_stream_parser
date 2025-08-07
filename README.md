# Partial JSON Stream Parser

A Dart library for parsing partial and incomplete JSON strings, perfect for handling streaming JSON responses from Large Language Models (LLMs) and real-time APIs.

## Features

- ✅ **Parse incomplete JSON** - Handle JSON that's not fully received.
- ✅ **Streaming support** - Process JSON as it arrives, character by character, ensuring you get values as soon as possible
- ✅ **Flexible string handling** - Strict and non-strict modes for newline handling
- ✅ **Zero dependencies** - Only uses Dart's built-in libraries
- ✅ **Type-safe** - Full Dart null-safety support
- ✅ **Well-tested** - Comprehensive test coverage for edge cases

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  partial_json_stream_parser: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Usage

```dart
import 'package:partial_json_stream_parser/partial_json_stream_parser.dart';

void main() {
  final parser = PartialJsonParser();
  
  // Parse incomplete JSON
  final incomplete = '{"name": "John", "age": 30, "active": tr';
  final result = parser.parse(incomplete);
  print(result); // {name: John, age: 30, active: true}
}
```

### Streaming Response Simulation

```dart
// Simulate receiving JSON in chunks (like from an LLM)
final chunks = [
  '{"message": "Hello',
  '{"message": "Hello, how',
  '{"message": "Hello, how can I help',
  '{"message": "Hello, how can I help you?"}'
];

final parser = PartialJsonParser();
for (final chunk in chunks) {
  final result = parser.parse(chunk);
  print('Current message: ${result['message']}');
}
```

### Strict vs Non-Strict Mode

```dart
// Strict mode (default) - properly handles escape sequences
final strictParser = PartialJsonParser(strict: true);
final json1 = r'{"text": "Line 1\nLine 2"}';  // Escaped newline
print(strictParser.parse(json1)); // {text: Line 1\nLine 2}

// Non-strict mode - allows raw newlines in strings
final nonStrictParser = PartialJsonParser(strict: false);
final json2 = '{"text": "Line 1\nLine 2"}';  // Raw newline
print(nonStrictParser.parse(json2)); // {text: Line 1\nLine 2}
```

### Handling Various Incomplete Scenarios

```dart
final parser = PartialJsonParser();

// Incomplete object
parser.parse('{"key": "value"');      // {key: value}

// Missing values
parser.parse('{"key":');              // {key: null}

// Incomplete array
parser.parse('[1, 2, 3');             // [1, 2, 3]

// Trailing decimal
parser.parse('{"price": 19.');        // {price: 19}

// Incomplete boolean
parser.parse('{"active": t');         // {active: true}

// Incomplete null
parser.parse('{"data": n');           // {data: null}
```

### Extra Token Callback

Handle cases where there's extra content after valid JSON:

```dart
final parser = PartialJsonParser(
  onExtraToken: (text, data, remaining) {
    print('Parsed: $data');
    print('Extra content: $remaining');
  },
);

parser.parse('{"valid": "json"} extra text');
// Parsed: {valid: json}
// Extra content: extra text
```

## Real-World Use Cases

### 1. LLM Streaming Responses

Perfect for parsing responses from OpenAI, Anthropic, or other LLM APIs:

```dart
Stream<String> llmStream = getLLMResponseStream();
final parser = PartialJsonParser();

await for (final chunk in llmStream) {
  final parsed = parser.parse(chunk);
  // Update UI with partial response
  updateUI(parsed['content']);
}
```

### 2. Real-time WebSocket Data

Handle incomplete JSON frames from WebSocket connections:

```dart
webSocket.stream.listen((data) {
  try {
    final parsed = parser.parse(data);
    processMessage(parsed);
  } catch (e) {
    // Handle completely malformed JSON
    print('Invalid JSON received: $e');
  }
});
```

### 3. Progressive UI Rendering

Render UI elements as soon as their data is available:

```dart
// As JSON streams in, render what's available
String buffer = '';
streamController.stream.listen((chunk) {
  buffer += chunk;
  final parsed = parser.parse(buffer);
  
  // Render available fields immediately
  if (parsed['title'] != null) showTitle(parsed['title']);
  if (parsed['items'] != null) showItems(parsed['items']);
});
```

## API Reference

### PartialJsonParser

The main parser class.

#### Constructor

```dart
PartialJsonParser({
  bool strict = true,
  ExtraTokenCallback? onExtraToken,
})
```

- `strict`: Whether to use strict mode for string parsing (default: true)
- `onExtraToken`: Optional callback for handling extra tokens after valid JSON

#### Methods

```dart
dynamic parse(String input)
```

Parses a potentially incomplete JSON string and returns the parsed value.

### ParseResult

Result object containing the parsed value and remaining unparsed string.

```dart
class ParseResult {
  final dynamic value;
  final String remaining;
}
```

## How It Works

The parser uses a recursive descent approach with the following strategy:

1. **Attempts standard JSON parsing first** - If the input is valid JSON, it uses Dart's built-in parser
2. **Falls back to partial parsing** - On failure, it identifies the JSON type and parses incrementally
3. **Handles incomplete tokens** - Recognizes partial keywords (true, false, null) and incomplete strings
4. **Preserves parsed state** - Returns the successfully parsed portion even if the input is incomplete

## Comparison with Standard JSON Parsing

| Scenario | Standard `jsonDecode` | PartialJsonParser |
|----------|----------------------|-------------------|
| Complete valid JSON | ✅ Works | ✅ Works |
| Missing closing brackets | ❌ Throws | ✅ Returns partial |
| Incomplete strings | ❌ Throws | ✅ Returns partial |
| Trailing content | ❌ Throws | ✅ Handles with callback |
| Streaming data | ❌ Not supported | ✅ Designed for it |

## What it doesn't do

- It doesn't recover or correct malformed or unordered JSON. You should ensure your JSON is passed with chars in the correct order to the parser, otherwise inconsistent results may be returned.
- It doesn't handle JSON with comments. You should ensure your JSON is passed without comments to the parser, otherwise an error will be thrown.
- It doesn't handle JSON with unquoted keys or unquoted string values. You should ensure your JSON is passed with quoted keys and string values to the parser, otherwise an error will be thrown.

## Contributing

Contributions are welcome! Feel free to submit a Pull Request.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Credits

This Dart implementation is inspired by the Python [partialjson](https://github.com/iw4p/partialjson) library.
