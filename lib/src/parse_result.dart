/// Result of a partial JSON parse operation.
class ParseResult {
  /// The parsed value (can be any JSON type: null, bool, num, String, List, Map)
  final dynamic value;
  
  /// The remaining unparsed string
  final String remaining;
  
  const ParseResult(this.value, this.remaining);
  
  @override
  String toString() => 'ParseResult(value: $value, remaining: "$remaining")';
}
