import 'dart:io';

void main() async {
  final file = File('errors.log');
  if (await file.exists()) {
    // Try reading as lines, if encoding fails fallback
    try {
      final lines = await file.readAsLines();
      for (var i = 0; i < lines.length && i < 20; i++) {
        print(lines[i]);
      }
    } catch (e) {
      print('Error reading file: $e');
      // basic ascii fallback
      final bytes = await file.readAsBytes();
      print(String.fromCharCodes(bytes).substring(0, 500));
    }
  } else {
    print('File not found');
  }
}
