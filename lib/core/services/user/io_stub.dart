import 'dart:typed_data';

// Stub implementations for web platform
class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
}

class File {
  File(String path);
  
  Future<bool> exists() async => false;
  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Future<void> writeAsBytes(List<int> bytes) async {}
  String get path => '';
}

class Directory {
  Directory(String path);
  
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  String get path => '';
}

Future<Directory> getExternalStorageDirectory() async => Directory('');
Future<Directory> getApplicationDocumentsDirectory() async => Directory('');