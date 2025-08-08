import 'package:partial_json_stream_parser/partial_json_stream_parser.dart';
import 'package:test/test.dart';

void main() {
  group('PartialJsonParser', () {
    late PartialJsonParser strictParser;
    late PartialJsonParser nonStrictParser;

    setUp(() {
      strictParser = PartialJsonParser(strict: true);
      nonStrictParser = PartialJsonParser(strict: false);
    });

    group('Complete JSON', () {
      test('parses complete objects', () {
        final json = '{"name": "John", "age": 30, "active": true}';
        final result = strictParser.parse(json);
        expect(result, equals({
          'name': 'John',
          'age': 30,
          'active': true,
        }));
      });

      test('parses complete arrays', () {
        final json = '[1, 2, 3, "test", true, null]';
        final result = strictParser.parse(json);
        expect(result, equals([1, 2, 3, 'test', true, null]));
      });

      test('parses nested structures', () {
        final json = '{"user": {"name": "Alice", "scores": [95, 87, 92]}}';
        final result = strictParser.parse(json);
        expect(result, equals({
          'user': {
            'name': 'Alice',
            'scores': [95, 87, 92],
          }
        }));
      });
    });

    group('Incomplete Objects', () {
      test('handles missing closing brace', () {
        final json = '{"name": "John", "age": 30';
        final result = strictParser.parse(json);
        expect(result, equals({'name': 'John', 'age': 30}));
      });

      test('handles missing value', () {
        final json = '{"name": "John", "age":';
        final result = strictParser.parse(json);
        expect(result, equals({'name': 'John', 'age': null}));
      });

      test('handles missing value and closing brace', () {
        final json = '{"name": "John", "age"';
        final result = strictParser.parse(json);
        expect(result, equals({'name': 'John', 'age': null}));
      });

      test('handles only key without colon', () {
        final json = '{"name"';
        final result = strictParser.parse(json);
        expect(result, equals({'name': null}));
      });

      test('handles empty incomplete object', () {
        final json = '{';
        final result = strictParser.parse(json);
        expect(result, equals({}));
      });
    });

    group('Incomplete Arrays', () {
      test('handles missing closing bracket', () {
        final json = '[1, 2, 3';
        final result = strictParser.parse(json);
        expect(result, equals([1, 2, 3]));
      });

      test('handles array with trailing comma', () {
        final json = '[1, 2, 3,';
        final result = strictParser.parse(json);
        expect(result, equals([1, 2, 3]));
      });

      test('handles empty incomplete array', () {
        final json = '[';
        final result = strictParser.parse(json);
        expect(result, equals([]));
      });

      test('handles nested incomplete arrays', () {
        final json = '[[1, 2], [3, 4';
        final result = strictParser.parse(json);
        expect(result, equals([[1, 2], [3, 4]]));
      });
    });

    group('Incomplete Strings', () {
      test('handles incomplete string in strict mode', () {
        final json = '{"name": "John';
        final result = strictParser.parse(json);
        expect(result, equals({'name': 'John'}));
      });

      test('handles incomplete string in non-strict mode', () {
        final json = '{"name": "John';
        final result = nonStrictParser.parse(json);
        expect(result, equals({'name': 'John'}));
      });

      test('handles newline in string - strict mode', () {
        final json = r'{"text": "Line 1\nLine 2"}';
        final result = strictParser.parse(json);
        expect(result, equals({'text': 'Line 1\nLine 2'}));
      });

      test('handles newline in string - non-strict mode', () {
        final json = '{"text": "Line 1\nLine 2"}';
        final result = nonStrictParser.parse(json);
        expect(result['text'], contains('Line'));
      });

      test('handles incomplete escape sequence', () {
        final json = r'{"text": "test\u00';
        final result = strictParser.parse(json);
        expect(result, equals({'text': ''}));
      });

      test('handles escaped quotes', () {
        final json = r'{"text": "She said \"Hello\""}';
        final result = strictParser.parse(json);
        expect(result, equals({'text': 'She said "Hello"'}));
      });
    });

    group('Incomplete Numbers', () {
      test('handles integer', () {
        final json = '{"value": 42';
        final result = strictParser.parse(json);
        expect(result, equals({'value': 42}));
      });

      test('handles negative number', () {
        final json = '{"value": -42';
        final result = strictParser.parse(json);
        expect(result, equals({'value': -42}));
      });

      test('handles floating point', () {
        final json = '{"value": 3.14';
        final result = strictParser.parse(json);
        expect(result, equals({'value': 3.14}));
      });

      test('handles trailing decimal point', () {
        final json = '{"value": 42.';
        final result = strictParser.parse(json);
        expect(result, equals({'value': 42}));
      });

      test('handles scientific notation', () {
        final json = '{"value": 1.5e10';
        final result = strictParser.parse(json);
        expect(result, equals({'value': 1.5e10}));
      });

      test('handles incomplete negative', () {
        final json = '{"value": -';
        final result = strictParser.parse(json);
        expect(result, equals({'value': '-'}));
      });
    });

    group('Incomplete Booleans', () {
      test('handles incomplete true', () {
        final json = '{"active": t';
        final result = strictParser.parse(json);
        expect(result, equals({'active': true}));
      });

      test('handles incomplete false', () {
        final json = '{"active": f';
        final result = strictParser.parse(json);
        expect(result, equals({'active': false}));
      });

      test('handles complete true', () {
        final json = '{"active": true';
        final result = strictParser.parse(json);
        expect(result, equals({'active': true}));
      });

      test('handles complete false', () {
        final json = '{"active": false';
        final result = strictParser.parse(json);
        expect(result, equals({'active': false}));
      });
    });

    group('Incomplete Null', () {
      test('handles incomplete null', () {
        final json = '{"value": n';
        final result = strictParser.parse(json);
        expect(result, equals({'value': null}));
      });

      test('handles complete null', () {
        final json = '{"value": null';
        final result = strictParser.parse(json);
        expect(result, equals({'value': null}));
      });
    });

    group('Complex Nested Structures', () {
      test('handles deeply nested incomplete structure', () {
        final json = '{"a": {"b": {"c": [1, 2, {"d": "test"';
        final result = strictParser.parse(json);
        expect(result, equals({
          'a': {
            'b': {
              'c': [1, 2, {'d': 'test'}]
            }
          }
        }));
      });

      test('handles mixed complete and incomplete elements', () {
        final json = '''
        {
          "users": [
            {"name": "Alice", "age": 30},
            {"name": "Bob", "age": 25},
            {"name": "Charlie"
        ''';
        final result = strictParser.parse(json);
        expect(result['users'], hasLength(3));
        expect(result['users'][0], equals({'name': 'Alice', 'age': 30}));
        expect(result['users'][1], equals({'name': 'Bob', 'age': 25}));
        expect(result['users'][2], equals({'name': 'Charlie'}));
      });
    });

    group('Whitespace Handling', () {
      test('handles leading whitespace', () {
        final json = '   {"key": "value"}';
        final result = strictParser.parse(json);
        expect(result, equals({'key': 'value'}));
      });

      test('handles whitespace between tokens', () {
        final json = '{ "key" : "value" , "num" : 42 }';
        final result = strictParser.parse(json);
        expect(result, equals({'key': 'value', 'num': 42}));
      });

      test('handles newlines and tabs', () {
        final json = '{\n\t"key": "value",\n\t"num": 42\n}';
        final result = strictParser.parse(json);
        expect(result, equals({'key': 'value', 'num': 42}));
      });
    });

    group('Edge Cases', () {
      test('handles empty string', () {
        final result = strictParser.parse('');
        expect(result, equals({}));
      });

      test('handles single opening brace', () {
        final result = strictParser.parse('{');
        expect(result, equals({}));
      });

      test('handles single opening bracket', () {
        final result = strictParser.parse('[');
        expect(result, equals([]));
      });

      test('handles array of objects with missing values', () {
        final json = '[{"a": 1}, {"b":';
        final result = strictParser.parse(json);
        expect(result, equals([{'a': 1}, {'b': null}]));
      });

      test('handles object with array value incomplete', () {
        final json = '{"items": [1, 2, 3';
        final result = strictParser.parse(json);
        expect(result, equals({'items': [1, 2, 3]}));
      });
    });

    group('Extra Token Callback', () {
      test('calls callback with remaining tokens', () {
        String? capturedText;
        dynamic capturedData;
        String? capturedRemaining;

        final parser = PartialJsonParser(
          onExtraToken: (text, data, remaining) {
            capturedText = text;
            capturedData = data;
            capturedRemaining = remaining;
          },
        );

        final json = '{"key": "value"} extra tokens';
        final result = parser.parse(json);

        expect(result, equals({'key': 'value'}));
        expect(capturedText, equals(json));
        expect(capturedData, equals({'key': 'value'}));
        expect(capturedRemaining, equals(' extra tokens'));
      });
    });

    group('Real-world LLM Response Examples', () {
      test('handles streaming response chunk 1', () {
        final chunk1 = '{"response": "Hello';
        final result = strictParser.parse(chunk1);
        expect(result, equals({'response': 'Hello'}));
      });

      test('handles streaming response chunk 2', () {
        final chunk2 = '{"response": "Hello, how can I';
        final result = strictParser.parse(chunk2);
        expect(result, equals({'response': 'Hello, how can I'}));
      });

      test('handles complex LLM response structure', () {
        final json = '''
        {
          "id": "chatcmpl-123",
          "object": "chat.completion",
          "created": 1677652288,
          "choices": [{
            "index": 0,
            "message": {
              "role": "assistant",
              "content": "Hello! How can I help you today?
        ''';
        final result = strictParser.parse(json);
        expect(result['id'], equals('chatcmpl-123'));
        expect(result['choices'][0]['message']['content'], 
               contains('Hello! How can I help you today?'));
      });
    });
  });
}
