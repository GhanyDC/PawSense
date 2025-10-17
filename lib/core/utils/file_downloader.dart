/// Universal file download utility with conditional exports
/// Automatically selects the correct implementation based on platform
export 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart'
    if (dart.library.io) 'file_download_mobile.dart';
