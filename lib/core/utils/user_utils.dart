import 'package:pawsense/core/models/user/user_model.dart';

class UserUtils {
  /// Extracts initials from user's first and last name
  /// Returns up to 2 characters (first letter of first name and first letter of last name)
  static String getUserInitials(UserModel? user) {
    if (user == null) return 'U';
    
    String initials = '';
    
    // Get first name initial
    if (user.firstName?.isNotEmpty == true) {
      initials += user.firstName!.trim()[0].toUpperCase();
    }
    
    // Get last name initial
    if (user.lastName?.isNotEmpty == true && initials.length < 2) {
      initials += user.lastName!.trim()[0].toUpperCase();
    }
    
    // Fallback: use email initial if no name is available
    if (initials.isEmpty && user.email.isNotEmpty) {
      initials = user.email[0].toUpperCase();
    }
    
    // Final fallback
    if (initials.isEmpty) {
      initials = 'U';
    }
    
    return initials;
  }
  
  /// Extracts initials from a full name string
  static String getInitialsFromFullName(String? fullName) {
    if (fullName?.isEmpty != false) return 'U';
    
    final nameParts = fullName!.trim().split(' ');
    String initials = '';
    
    // Take first letter of first two words
    for (int i = 0; i < nameParts.length && initials.length < 2; i++) {
      if (nameParts[i].isNotEmpty) {
        initials += nameParts[i][0].toUpperCase();
      }
    }
    
    return initials.isEmpty ? 'U' : initials;
  }
  
  /// Gets display name for user (firstName lastName or email)
  static String getDisplayName(UserModel? user) {
    if (user == null) return 'User';
    
    String displayName = '';
    
    if (user.firstName?.isNotEmpty == true) {
      displayName = user.firstName!;
      if (user.lastName?.isNotEmpty == true) {
        displayName += ' ${user.lastName!}';
      }
    } else if (user.email.isNotEmpty) {
      // Use part before @ as display name
      displayName = user.email.split('@')[0];
    } else {
      displayName = 'User';
    }
    
    return displayName;
  }
}
