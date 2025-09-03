/// Text formatting utilities
class TextUtils {
  /// Capitalizes the first letter of each word in a string
  /// 
  /// Examples:
  /// - "john doe" -> "John Doe"
  /// - "mary jane watson" -> "Mary Jane Watson" 
  /// - "drix narciso" -> "Drix Narciso"
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  /// Creates a formatted full name from first and last name
  /// 
  /// Both names are capitalized properly and joined with a space
  /// 
  /// Examples:
  /// - ("drix", "narciso") -> "Drix Narciso"
  /// - ("mary jane", "watson") -> "Mary Jane Watson"
  static String formatFullName(String firstName, String lastName) {
    final capitalizedFirst = capitalizeWords(firstName);
    final capitalizedLast = capitalizeWords(lastName);
    return '$capitalizedFirst $capitalizedLast';
  }
}
