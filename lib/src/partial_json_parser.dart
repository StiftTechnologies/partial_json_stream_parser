import 'dart:convert';

import 'parse_result.dart';

typedef ExtraTokenCallback = void Function(String text, dynamic data, String remaining);

/// A parser for partial and incomplete JSON strings.
/// 
/// This parser can handle JSON that is cut off at any point,
/// making it ideal for streaming scenarios.
class PartialJsonParser {
  /// Whether to use strict mode for string parsing.
  /// In strict mode, newlines in strings must be properly escaped.
  final bool strict;
  
  /// Callback for handling extra tokens after parsing
  ExtraTokenCallback? onExtraToken;
  
  /// The remaining unparsed content from the last parse operation
  String? lastParseRemaining;
  
  /// Map of starting characters to their respective parser functions
  late final Map<String, ParseResult Function(String, Exception)> _parsers;
  
  PartialJsonParser({this.strict = true, this.onExtraToken}) {
    _parsers = {
      ' ': _parseSpace,
      '\r': _parseSpace,
      '\n': _parseSpace,
      '\t': _parseSpace,
      '[': _parseArray,
      '{': _parseObject,
      '"': _parseString,
      't': _parseTrue,
      'f': _parseFalse,
      'n': _parseNull,
    };
    
    // Add number parsers for all digit characters and signs
    for (final c in '0123456789.-'.split('')) {
      _parsers[c] = _parseNumber;
    }
  }
  
  /// Parse a potentially incomplete JSON string.
  /// 
  /// Returns the parsed JSON value, or throws if parsing fails completely.
  dynamic parse(String s) {
    if (s.isEmpty) {
      return {};
    }
    
    try {
      // Try standard JSON parsing first
      return jsonDecode(s);
    } on FormatException catch (e) {
      // Fall back to partial parsing
      final result = _parseAny(s, e);
      lastParseRemaining = result.remaining;
      
      if (onExtraToken != null && result.remaining.isNotEmpty) {
        onExtraToken!(s, result.value, result.remaining);
      }
      
      return result.value;
    }
  }
  
  /// Parse any JSON value from the string.
  ParseResult _parseAny(String s, Exception e) {
    if (s.isEmpty) {
      throw e;
    }
    
    final parser = _parsers[s[0]];
    if (parser == null) {
      throw e;
    }
    
    return parser(s, e);
  }
  
  /// Skip whitespace and parse the remaining content.
  ParseResult _parseSpace(String s, Exception e) {
    return _parseAny(s.trim(), e);
  }
  
  /// Parse a JSON array.
  ParseResult _parseArray(String s, Exception e) {
    s = s.substring(1); // Skip opening '['
    final List<dynamic> acc = [];
    s = s.trim();
    
    while (s.isNotEmpty) {
      if (s[0] == ']') {
        s = s.substring(1); // Skip closing ']'
        break;
      }
      
      final result = _parseAny(s, e);
      acc.add(result.value);
      s = result.remaining.trim();
      
      if (s.startsWith(',')) {
        s = s.substring(1).trim();
      }
    }
    
    return ParseResult(acc, s);
  }
  
  /// Parse a JSON object.
  ParseResult _parseObject(String s, Exception e) {
    s = s.substring(1); // Skip opening '{'
    final Map<String, dynamic> acc = {};
    s = s.trim();
    
    while (s.isNotEmpty) {
      if (s[0] == '}') {
        s = s.substring(1); // Skip closing '}'
        break;
      }
      
      // Parse key
      final keyResult = _parseAny(s, e);
      final key = keyResult.value.toString();
      s = keyResult.remaining.trim();
      
      // Handle missing value cases
      if (s.isEmpty || s[0] == '}') {
        acc[key] = null;
        break;
      }
      
      if (s[0] != ':') {
        throw e; // Missing colon
      }
      
      s = s.substring(1).trim(); // Skip ':'
      
      // Handle missing value after colon
      if (s.isEmpty || s[0] == ',' || s[0] == '}') {
        acc[key] = null;
        if (s.startsWith(',')) {
          s = s.substring(1);
        }
        continue;
      }
      
      // Parse value
      final valueResult = _parseAny(s, e);
      acc[key] = valueResult.value;
      s = valueResult.remaining.trim();
      
      if (s.startsWith(',')) {
        s = s.substring(1).trim();
      }
    }
    
    return ParseResult(acc, s);
  }
  
  /// Parse a JSON string.
  ParseResult _parseString(String s, Exception e) {
    final incompleteEscapeRegex = RegExp(r'^\\(?:u[0-9a-fA-F]{0,3})?$');
    
    // Find the closing quote, handling escaped quotes
    int end = 1;
    while (end < s.length) {
      if (s[end] == '"' && (end == 1 || s[end - 1] != '\\')) {
        break;
      }
      if (s[end] == '"' && s[end - 1] == '\\') {
        // Check if the backslash itself is escaped
        int backslashCount = 0;
        int checkPos = end - 1;
        while (checkPos >= 0 && s[checkPos] == '\\') {
          backslashCount++;
          checkPos--;
        }
        // If even number of backslashes, the quote is not escaped
        if (backslashCount % 2 == 0) {
          break;
        }
      }
      end++;
    }
    
    // Handle incomplete string
    if (end >= s.length) {
      final content = s.substring(1);
      
      if (!strict) {
        // Non-strict mode: return raw content
        if (incompleteEscapeRegex.hasMatch(content)) {
          return ParseResult(content, '');
        }
        return ParseResult(content, '');
      } else {
        // Strict mode: validate escape sequences
        if (incompleteEscapeRegex.hasMatch(content)) {
          return ParseResult('', '');
        }
        try {
          // Try to parse as valid JSON string
          final decoded = jsonDecode('"$content"');
          return ParseResult(decoded, '');
        } catch (_) {
          return ParseResult('', '');
        }
      }
    }
    
    // Complete string found
    final strVal = s.substring(0, end + 1);
    s = s.substring(end + 1);
    
    if (!strict) {
      // Non-strict: return raw content without quotes
      return ParseResult(strVal.substring(1, strVal.length - 1), s);
    }
    
    // Strict: properly decode the JSON string
    try {
      return ParseResult(jsonDecode(strVal), s);
    } catch (_) {
      throw e;
    }
  }
  
  /// Parse a JSON number.
  ParseResult _parseNumber(String s, Exception e) {
    int i = 0;
    bool hasDecimal = false;
    bool hasExponent = false;
    
    // Handle negative sign
    if (i < s.length && s[i] == '-') {
      i++;
    }
    
    // Parse digits before decimal
    while (i < s.length && s[i].codeUnitAt(0) >= 48 && s[i].codeUnitAt(0) <= 57) {
      i++;
    }
    
    // Handle decimal point
    if (i < s.length && s[i] == '.') {
      hasDecimal = true;
      i++;
      // Parse digits after decimal
      while (i < s.length && s[i].codeUnitAt(0) >= 48 && s[i].codeUnitAt(0) <= 57) {
        i++;
      }
    }
    
    // Handle scientific notation
    if (i < s.length && (s[i] == 'e' || s[i] == 'E')) {
      hasExponent = true;
      i++;
      if (i < s.length && (s[i] == '+' || s[i] == '-')) {
        i++;
      }
      while (i < s.length && s[i].codeUnitAt(0) >= 48 && s[i].codeUnitAt(0) <= 57) {
        i++;
      }
    }
    
    final numStr = s.substring(0, i);
    s = s.substring(i);
    
    // Handle incomplete numbers
    if (numStr.isEmpty || numStr == '-' || numStr == '.') {
      return ParseResult(numStr, '');
    }
    
    try {
      // Handle trailing decimal point
      if (numStr.endsWith('.')) {
        final num = int.parse(numStr.substring(0, numStr.length - 1));
        return ParseResult(num, s);
      }
      
      // Parse as int or double
      if (hasDecimal || hasExponent) {
        return ParseResult(double.parse(numStr), s);
      } else {
        return ParseResult(int.parse(numStr), s);
      }
    } on FormatException {
      throw e;
    }
  }
  
  /// Parse boolean true.
  ParseResult _parseTrue(String s, Exception e) {
    if (s.toLowerCase().startsWith('t')) {
      // Handle incomplete 'true'
      if (s.length < 4) {
        return ParseResult(true, '');
      }
      return ParseResult(true, s.substring(4));
    }
    throw e;
  }
  
  /// Parse boolean false.
  ParseResult _parseFalse(String s, Exception e) {
    if (s.toLowerCase().startsWith('f')) {
      // Handle incomplete 'false'
      if (s.length < 5) {
        return ParseResult(false, '');
      }
      return ParseResult(false, s.substring(5));
    }
    throw e;
  }
  
  /// Parse null.
  ParseResult _parseNull(String s, Exception e) {
    if (s.startsWith('n')) {
      // Handle incomplete 'null'
      if (s.length < 4) {
        return ParseResult(null, '');
      }
      return ParseResult(null, s.substring(4));
    }
    throw e;
  }
}
