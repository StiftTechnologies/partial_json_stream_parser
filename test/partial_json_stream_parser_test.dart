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

    group('ParseResult and Exception Classes', () {
      test('ParseResult toString works correctly', () {
        final result = ParseResult({'key': 'value'}, ' remaining');
        final toString = result.toString();
        expect(toString, contains('ParseResult'));
        expect(toString, contains('key'));
        expect(toString, contains('remaining'));
      });

      test('PartialJsonException with all parameters', () {
        final exception = PartialJsonException(
          'Test error',
          input: '{"invalid": json}',
          position: 10,
        );
        
        final toString = exception.toString();
        expect(toString, contains('PartialJsonException'));
        expect(toString, contains('Test error'));
        expect(toString, contains('{"invalid": json}'));
        expect(toString, contains('position 10'));
      });

      test('PartialJsonException with minimal parameters', () {
        final exception = PartialJsonException('Simple error');
        final toString = exception.toString();
        expect(toString, equals('PartialJsonException: Simple error'));
      });
    });

    group('Advanced Error Handling', () {
      test('handles malformed JSON with invalid characters', () {
        final json = '{"key": "val@#\$%^&*()ue"}';
        final result = strictParser.parse(json);
        expect(result, equals({'key': 'val@#\$%^&*()ue'}));
      });

      test('handles JSON with control characters in strings', () {
        final json = '{"text": "Line1\u0001\u0002Line2"}';
        final result = strictParser.parse(json);
        expect(result, containsPair('text', contains('Line')));
      });

      test('handles deeply nested structures exceeding typical limits', () {
        var json = '{"level0": {"level1": {"level2": {"level3": {"level4": {"level5": "deep"';
        final result = strictParser.parse(json);
        expect(result['level0']['level1']['level2']['level3']['level4']['level5'], equals('deep'));
      });

      test('handles mixed quotes in string values', () {
        final json = r'''{"message": "He said 'Hello' and \"Goodbye\""}''';
        final result = strictParser.parse(json);
        expect(result['message'], equals('He said \'Hello\' and "Goodbye"'));
      });

      test('handles invalid JSON starting characters', () {
        final json = 'invalid{"key": "value"}';
        expect(() => strictParser.parse(json), throwsA(isA<FormatException>()));
      });

      test('handles missing colon in object properties', () {
        final json = '{"key" "value"}';
        expect(() => strictParser.parse(json), throwsA(isA<FormatException>()));
      });
    });

    group('Unicode and Special Characters', () {
      test('handles emoji in JSON strings', () {
        final json = '{"message": "Hello 👋 World 🌍"}';
        final result = strictParser.parse(json);
        expect(result, equals({'message': 'Hello 👋 World 🌍'}));
      });

      test('handles unicode escape sequences', () {
        final json = r'{"unicode": "\u0048\u0065\u006C\u006C\u006F"}';
        final result = strictParser.parse(json);
        expect(result, equals({'unicode': 'Hello'}));
      });

      test('handles incomplete unicode escape sequence', () {
        final json = r'{"unicode": "\u004';
        final result = strictParser.parse(json);
        expect(result, equals({'unicode': ''}));
      });

      test('handles mixed character encodings', () {
        final json = '{"text": "Café naïve résumé"}';
        final result = strictParser.parse(json);
        expect(result, equals({'text': 'Café naïve résumé'}));
      });

      test('handles null bytes in JSON', () {
        final json = '{"data": "before\u0000after"}';
        final result = strictParser.parse(json);
        expect(result['data'], contains('before'));
      });

      test('handles various unicode escape patterns', () {
        final json = r'{"test": "\u00A9\u00AE\u2122"}';
        final result = strictParser.parse(json);
        expect(result['test'], equals('©®™'));
      });
    });

    group('Performance and Memory Tests', () {
      test('handles very large string values', () {
        final largeString = 'x' * 10000;
        final json = '{"large": "$largeString"';
        final result = strictParser.parse(json);
        expect(result['large'], equals(largeString));
        expect(result['large'].length, equals(10000));
      });

      test('handles arrays with many elements', () {
        final elements = List.generate(1000, (i) => i).join(', ');
        final json = '{"numbers": [$elements';
        final result = strictParser.parse(json);
        expect(result['numbers'], hasLength(1000));
        expect(result['numbers'][999], equals(999));
      });

      test('handles objects with many keys', () {
        final pairs = List.generate(100, (i) => '"key$i": $i').join(', ');
        final json = '{$pairs';
        final result = strictParser.parse(json);
        expect(result, hasLength(100));
        expect(result['key99'], equals(99));
      });

      test('handles deeply nested arrays', () {
        var json = '[' * 50 + '42' + ']' * 49; // 49 closing brackets (incomplete)
        final result = strictParser.parse(json);
        
        var current = result;
        for (int i = 0; i < 49; i++) {
          expect(current, isA<List>());
          current = current[0];
        }
        expect(current, equals(42));
      });
    });

    group('Streaming Simulation Tests', () {
      test('simulates incremental JSON building - object', () {
        final chunks = [
          '{',
          '"name":',
          '"John",',
          '"age":',
          '30,',
          '"active":',
          'true'
        ];
        
        for (int i = 1; i <= chunks.length; i++) {
          final partial = chunks.take(i).join();
          final result = strictParser.parse(partial);
          expect(result, isA<Map>());
        }
        
        final complete = chunks.join();
        final finalResult = strictParser.parse(complete);
        expect(finalResult, equals({'name': 'John', 'age': 30, 'active': true}));
      });

      test('simulates incremental JSON building - array', () {
        final chunks = [
          '[',
          '1,',
          '2,',
          '3,',
          '"test",',
          'true,',
          'null'
        ];
        
        for (int i = 1; i <= chunks.length; i++) {
          final partial = chunks.take(i).join();
          final result = strictParser.parse(partial);
          expect(result, isA<List>());
        }
        
        final complete = chunks.join();
        final finalResult = strictParser.parse(complete);
        expect(finalResult, equals([1, 2, 3, 'test', true, null]));
      });

      test('simulates real-world streaming with random cuts', () {
        final completeJson = '{"users":[{"name":"Alice","age":30,"skills":["dart","flutter"]},{"name":"Bob","age":25,"active":true}],"total":2}';
        
        // Test at various cut points
        final cutPoints = [10, 25, 50, 75, 100, completeJson.length - 10];
        
        for (final cutPoint in cutPoints) {
          if (cutPoint < completeJson.length) {
            final partial = completeJson.substring(0, cutPoint);
            final result = strictParser.parse(partial);
            expect(result, isA<Map>());
            expect(result, containsPair('users', isA<List>()));
          }
        }
      });
    });

    group('Strict vs Non-Strict Mode Differences', () {
      test('compares string handling between modes', () {
        final jsonWithUnescapedChars = '{"text": "Line 1\nLine 2\tTabbed"}';
        
        final strictResult = strictParser.parse(jsonWithUnescapedChars);
        final nonStrictResult = nonStrictParser.parse(jsonWithUnescapedChars);
        
        expect(strictResult, isA<Map>());
        expect(nonStrictResult, isA<Map>());
        expect(strictResult.containsKey('text'), isTrue);
        expect(nonStrictResult.containsKey('text'), isTrue);
      });

      test('handles incomplete escape sequences differently', () {
        final jsonWithIncompleteEscape = r'{"path": "C:\Program Files\App\"';
        
        final strictResult = strictParser.parse(jsonWithIncompleteEscape);
        final nonStrictResult = nonStrictParser.parse(jsonWithIncompleteEscape);
        
        expect(strictResult, containsPair('path', isA<String>()));
        expect(nonStrictResult, containsPair('path', isA<String>()));
      });

      test('validates both modes handle numbers consistently', () {
        final numberTests = [
          '{"int": 42',
          '{"float": 3.14159',
          '{"scientific": 1.23e-4',
          '{"negative": -999',
          '{"zero": 0',
        ];
        
        for (final json in numberTests) {
          final strictResult = strictParser.parse(json);
          final nonStrictResult = nonStrictParser.parse(json);
          
          expect(strictResult.values.first, equals(nonStrictResult.values.first));
        }
      });

      test('non-strict mode handles raw content without escape processing', () {
        final json = r'{"path": "C:\test\file"';
        final nonStrictResult = nonStrictParser.parse(json);
        expect(nonStrictResult['path'], contains('\\'));
      });
    });

    group('Boundary Value Tests', () {
      test('handles maximum safe integer values', () {
        final json = '{"maxSafe": 9007199254740991';
        final result = strictParser.parse(json);
        expect(result['maxSafe'], isA<num>());
      });

      test('handles minimum safe integer values', () {
        final json = '{"minSafe": -9007199254740991';
        final result = strictParser.parse(json);
        expect(result['minSafe'], isA<num>());
      });

      test('handles very small decimal numbers', () {
        final json = '{"tiny": 0.000000000001';
        final result = strictParser.parse(json);
        expect(result['tiny'], isA<num>());
        expect(result['tiny'], greaterThan(0));
      });

      test('handles zero in various formats', () {
        final zeroFormats = [
          '{"zero1": 0',
          '{"zero2": 0.0',
          '{"zero3": -0',
          '{"zero4": 0e0',
        ];
        
        for (final json in zeroFormats) {
          final result = strictParser.parse(json);
          expect(result.values.first, equals(0));
        }
      });

      test('handles scientific notation edge cases', () {
        final scientificNumbers = [
          '{"sci1": 1e10',
          '{"sci2": 1E-10',
          '{"sci3": 1.5e+20',
          '{"sci4": -2.3E-15',
        ];
        
        for (final json in scientificNumbers) {
          final result = strictParser.parse(json);
          expect(result.values.first, isA<num>());
        }
      });
    });

    group('Complex Real-World Scenarios', () {
      test('handles OpenAI API response structure', () {
        final openAiResponse = '''
        {
          "id": "chatcmpl-7QyqpwdfhqwajicIEznoc6Q47XAyW",
          "object": "chat.completion",
          "created": 1677649420,
          "model": "gpt-3.5-turbo",
          "usage": {"prompt_tokens": 56, "completion_tokens": 31, "total_tokens": 87},
          "choices": [{
            "message": {
              "role": "assistant",
              "content": "The 2020 World Series was played in Arlington, Texas at the Globe Life Field, which was the new home of the Texas Rangers."
            },
            "finish_reason": "stop",
            "index": 0
        ''';
        
        final result = strictParser.parse(openAiResponse);
        expect(result['id'], isA<String>());
        expect(result['choices'], isA<List>());
        expect(result['choices'][0]['message']['role'], equals('assistant'));
        expect(result['usage']['total_tokens'], equals(87));
      });

      test('handles GitHub API response structure', () {
        final githubResponse = '''
        {
          "login": "octocat",
          "id": 1,
          "node_id": "MDQ6VXNlcjE=",
          "avatar_url": "https://github.com/images/error/octocat_happy.gif",
          "gravatar_id": "",
          "url": "https://api.github.com/users/octocat",
          "html_url": "https://github.com/octocat",
          "followers_url": "https://api.github.com/users/octocat/followers",
          "following_url": "https://api.github.com/users/octocat/following{/other_user}",
          "type": "User",
          "site_admin": false,
          "name": "monalisa octocat",
          "company": "GitHub",
          "blog": "https://github.com/blog",
          "location": "San Francisco",
          "email": "octocat@github.com",
          "hireable": false,
          "bio": "There once was...",
          "public_repos": 2,
          "public_gists": 1,
          "followers": 20,
          "following": 0,
          "created_at": "2008-01-14T04:33:35Z",
          "updated_at": "2008-01-14T04:33:35Z"
        ''';
        
        final result = strictParser.parse(githubResponse);
        expect(result['login'], equals('octocat'));
        expect(result['public_repos'], equals(2));
        expect(result['site_admin'], equals(false));
        expect(result['avatar_url'], startsWith('https://'));
      });

      test('handles complex nested configuration', () {
        final configJson = '''
        {
          "database": {
            "host": "localhost",
            "port": 5432,
            "credentials": {
              "username": "admin",
              "password": "secret123"
            },
            "pools": {
              "read": {"min": 1, "max": 10},
              "write": {"min": 2, "max": 5}
            }
          },
          "cache": {
            "redis": {
              "cluster": ["redis1:6379", "redis2:6379", "redis3:6379"],
              "timeout": 5000,
              "retry_attempts": 3
            }
          },
          "features": {
            "auth_enabled": true,
            "rate_limiting": {"requests_per_minute": 1000},
            "logging": {"level": "INFO", "format": "json"}
        ''';
        
        final result = strictParser.parse(configJson);
        expect(result['database']['port'], equals(5432));
        expect(result['cache']['redis']['cluster'], hasLength(3));
        expect(result['features']['rate_limiting']['requests_per_minute'], equals(1000));
      });

      test('handles JSON-RPC response structure', () {
        final jsonRpcResponse = '''
        {
          "jsonrpc": "2.0",
          "result": {
            "data": [
              {"id": 1, "name": "Item 1", "active": true},
              {"id": 2, "name": "Item 2", "active": false}
            ],
            "pagination": {
              "page": 1,
              "per_page": 10,
              "total": 2,
              "has_more": false
            }
          },
          "id": "req-123"
        ''';
        
        final result = strictParser.parse(jsonRpcResponse);
        expect(result['jsonrpc'], equals('2.0'));
        expect(result['result']['data'], hasLength(2));
        expect(result['result']['pagination']['total'], equals(2));
      });
    });

    group('Error Recovery and Resilience', () {
      test('recovers from malformed arrays within objects', () {
        final json = '{"data": [1, 2, invalid, 3], "status": "ok"';
        expect(() => strictParser.parse(json), throwsA(isA<FormatException>()));
      });

      test('handles mixed valid and invalid tokens', () {
        final json = '{"valid": "data", invalid_key: "value"';
        expect(() => strictParser.parse(json), throwsA(isA<FormatException>()));
      });

      test('recovers from unexpected end in various contexts', () {
        final incompleteContexts = [
          '{"key": "val',           // Incomplete string
          '{"key": [1, 2',         // Incomplete array
          '{"key": {"nested"',     // Incomplete nested object
          '{"key": tr',            // Incomplete boolean
          '{"key": nu',            // Incomplete null
          '{"key": -',             // Incomplete number
        ];
        
        for (final json in incompleteContexts) {
          final result = strictParser.parse(json);
          expect(result, isA<Map>());
          expect(result, containsKey('key'));
        }
      });

      test('handles parser state consistency after errors', () {
        // Test that parser can handle subsequent valid JSON after error
        final validJson = '{"name": "test", "value": 42}';
        
        try {
          strictParser.parse('invalid json');
        } catch (e) {
          // Expected to fail
        }
        
        // Parser should still work for valid JSON
        final result = strictParser.parse(validJson);
        expect(result, equals({'name': 'test', 'value': 42}));
      });

      test('handles incomplete object keys gracefully', () {
        final json = '{"incomplete_key';
        final result = strictParser.parse(json);
        expect(result, equals({'incomplete_key': null}));
      });

      test('handles trailing commas in objects and arrays', () {
        final objectWithComma = '{"key": "value",';
        final arrayWithComma = '[1, 2, 3,';
        
        final objResult = strictParser.parse(objectWithComma);
        final arrResult = strictParser.parse(arrayWithComma);
        
        expect(objResult, equals({'key': 'value'}));
        expect(arrResult, equals([1, 2, 3]));
      });
    });

    group('Callback and Hook Tests', () {
      test('extra token callback provides correct context', () {
        var callbackCount = 0;
        String? lastText;
        dynamic lastData;
        String? lastRemaining;
        
        final parser = PartialJsonParser(
          onExtraToken: (text, data, remaining) {
            callbackCount++;
            lastText = text;
            lastData = data;
            lastRemaining = remaining;
          },
        );
        
        final json = '{"parsed": true}{"extra": "object"} more text';
        final result = parser.parse(json);
        
        expect(callbackCount, equals(1));
        expect(result, equals({'parsed': true}));
        expect(lastText, equals(json));
        expect(lastData, equals({'parsed': true}));
        expect(lastRemaining, startsWith('{"extra"'));
      });

      test('callback with multiple extra objects', () {
        var callbackCount = 0;
        final capturedRemaining = <String>[];
        
        final parser = PartialJsonParser(
          onExtraToken: (text, data, remaining) {
            callbackCount++;
            capturedRemaining.add(remaining);
          },
        );
        
        final json = '{"first": 1} {"second": 2} {"third": 3}';
        parser.parse(json);
        
        expect(callbackCount, equals(1));
        expect(capturedRemaining.first, contains('{"second"'));
      });

      test('callback handles null and empty remaining text', () {
        String? capturedRemaining;
        
        final parser = PartialJsonParser(
          onExtraToken: (text, data, remaining) {
            capturedRemaining = remaining;
          },
        );
        
        // This should not trigger callback (no extra tokens)
        parser.parse('{"clean": "json"}');
        expect(capturedRemaining, isNull);
        
        // This should trigger callback with empty remaining
        parser.parse('{"with": "space"} ');
        expect(capturedRemaining, equals(' '));
      });

      test('lastParseRemaining property tracks remaining content', () {
        final parser = PartialJsonParser();
        
        parser.parse('{"complete": "json"}');
        expect(parser.lastParseRemaining, isEmpty);
        
        parser.parse('{"incomplete": "json"} extra content');
        expect(parser.lastParseRemaining, equals(' extra content'));
      });
    });

    group('Memory and Performance Edge Cases', () {
      test('handles deeply nested structures without stack overflow', () {
        const depth = 100;
        final openBraces = '{' + '"a":' * depth;
        final closeBraces = '}' * (depth - 1); // Incomplete nesting
        final json = openBraces + '"value"' + closeBraces;
        
        final result = strictParser.parse(json);
        expect(result, isA<Map>());
        
        // Navigate to the deepest level
        var current = result;
        for (int i = 0; i < depth - 1; i++) {
          current = current['a'];
        }
        expect(current, equals('value'));
      });

      test('handles alternating object and array nesting', () {
        final json = '{"a": [{"b": [{"c": {"d": [1, 2';
        final result = strictParser.parse(json);
        
        expect(result['a'][0]['b'][0]['c']['d'], equals([1, 2]));
      });

      test('parser maintains performance with repeated parsing', () {
        final json = '{"repeated": "parsing", "test": true}';
        
        // Parse the same JSON multiple times to check for memory leaks
        for (int i = 0; i < 100; i++) {
          final result = strictParser.parse(json);
          expect(result['repeated'], equals('parsing'));
          expect(result['test'], equals(true));
        }
      });

      test('handles mixed data types in large structures', () {
        final mixed = '''
        {
          "strings": ["short", "medium length string", "${'very long string ' * 100}"],
          "numbers": [0, -1, 1, 3.14159, 1e10, -2.5e-8],
          "booleans": [true, false, true],
          "nulls": [null, null],
          "nested": {
            "level1": {
              "level2": {
                "level3": "deep value"
              }
            }
          }
        ''';
        
        final result = strictParser.parse(mixed);
        expect(result['strings'], hasLength(3));
        expect(result['numbers'], hasLength(6));
        expect(result['nested']['level1']['level2']['level3'], equals('deep value'));
      });
    });

    group('String Parsing Edge Cases', () {
      test('handles strings with escaped backslashes', () {
        final json = r'{"path": "C:\\Program Files\\App\\"}';
        final result = strictParser.parse(json);
        expect(result['path'], equals('C:\\Program Files\\App\\'));
      });

      test('handles strings with mixed escape sequences', () {
        final json = r'{"mixed": "Line1\nTab\tQuote\"Backslash\\End"}';
        final result = strictParser.parse(json);
        expect(result['mixed'], equals('Line1\nTab\tQuote"Backslash\\End'));
      });

      test('handles incomplete strings with various endings', () {
        final incompleteStrings = [
          '{"key": "value without quote',
          '{"key": "value with backslash\\',
          '{"key": "value with escape \\n',
          '{"key": "value with unicode \\u0041',
        ];
        
        for (final json in incompleteStrings) {
          final result = strictParser.parse(json);
          expect(result, containsKey('key'));
          expect(result['key'], isA<String>());
        }
      });

      test('handles consecutive backslashes correctly', () {
        final json = r'{"test": "\\\\"}';
        final result = strictParser.parse(json);
        expect(result['test'], equals('\\\\'));
      });
    });

    group('Number Parsing Edge Cases', () {
      test('handles incomplete exponential notation', () {
        final incompleteExponents = [
          '{"num": 1e',
          '{"num": 1E',
          '{"num": 1e+',
          '{"num": 1e-',
          '{"num": 1.5e',
        ];
        
        for (final json in incompleteExponents) {
          final result = strictParser.parse(json);
          expect(result, containsKey('num'));
        }
      });

      test('handles numbers with leading zeros', () {
        final json = '{"num": 00123';
        final result = strictParser.parse(json);
        expect(result['num'], isA<num>());
      });

      test('handles decimal numbers without leading digit', () {
        final json = '{"num": .123';
        final result = strictParser.parse(json);
        expect(result['num'], equals('.123')); // Should be treated as string due to invalid format
      });

      test('handles numbers followed by non-numeric characters', () {
        final json = '{"num": 123abc';
        final result = strictParser.parse(json);
        expect(result['num'], equals(123));
      });
    });

    group('Array Parsing Edge Cases', () {
      test('handles arrays with mixed incomplete elements', () {
        final json = '[1, "incomplete string, true, {"key":';
        final result = strictParser.parse(json);
        expect(result, isA<List>());
        expect(result, hasLength(4));
      });

      test('handles nested arrays with various levels of completeness', () {
        final json = '[[[1, 2]], [[3, 4], [5';
        final result = strictParser.parse(json);
        expect(result, isA<List>());
        expect(result[0][0], equals([1, 2]));
        expect(result[1][1], equals([5]));
      });

      test('handles empty arrays at different nesting levels', () {
        final json = '[[], [[], []]';
        final result = strictParser.parse(json);
        expect(result, hasLength(2));
        expect(result[0], isEmpty);
        expect(result[1], hasLength(2));
      });
    });
