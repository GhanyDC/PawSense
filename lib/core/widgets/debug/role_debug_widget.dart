import 'package:flutter/material.dart';
import 'package:pawsense/core/services/auth/auth_service.dart';

/// Debug widget to check current user's role
/// Add this to any screen temporarily to debug auth issues
class RoleDebugWidget extends StatefulWidget {
  const RoleDebugWidget({super.key});

  @override
  State<RoleDebugWidget> createState() => _RoleDebugWidgetState();
}

class _RoleDebugWidgetState extends State<RoleDebugWidget> {
  String _userInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      
      if (user == null) {
        setState(() => _userInfo = '❌ No user logged in');
        return;
      }

      setState(() {
        _userInfo = '''
✅ User: ${user.email}
👤 Name: ${user.firstName} ${user.lastName}
🎭 Role: ${user.role}
🆔 UID: ${user.uid}

${user.role == 'super_admin' ? '✅ Has Super Admin Access' : '❌ NOT Super Admin!'}
        ''';
      });
    } catch (e) {
      setState(() => _userInfo = '❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🐛 DEBUG: Current User Info',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _userInfo,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _loadUserInfo,
                  child: Text('Refresh'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Show role debug dialog
void showRoleDebug(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.all(16),
      content: RoleDebugWidget(),
    ),
  );
}
