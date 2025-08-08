/// Exception thrown when partial JSON parsing fails.
class PartialJsonException implements Exception {
  final String message;
  final String? input;
  final int? position;
  
  const PartialJsonException(this.message, {this.input, this.position});
  
  @override
  String toString() {
    final buffer = StringBuffer('PartialJsonException: $message');
    if (input != null) {
      buffer.write(' in "$input"');
    }
    if (position != null) {
      buffer.write(' at position $position');
    }
    return buffer.toString();
  }
}
