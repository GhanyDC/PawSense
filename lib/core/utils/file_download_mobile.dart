/// Mobile/Desktop implementation for file downloads
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> downloadFile(String fileName, List<int> bytes) async {
  try {
    // Get the downloads directory
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    
    // Write the file
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    
    print('✅ File saved to: $filePath');
  } catch (e) {
    print('❌ Error saving file: $e');
    rethrow;
  }
}
