import 'package:flutter/material.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class DebugClinicIdWidget extends StatefulWidget {
  const DebugClinicIdWidget({super.key});

  @override
  State<DebugClinicIdWidget> createState() => _DebugClinicIdWidgetState();
}

class _DebugClinicIdWidgetState extends State<DebugClinicIdWidget> {
  String? _clinicId;
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      setState(() {
        _clinicId = currentUser?.uid;
        _userEmail = currentUser?.email;
        _isLoading = false;
      });
      
      print('DEBUG: Current user UID (clinic ID): $_clinicId');
      print('DEBUG: Current user email: $_userEmail');
    } catch (e) {
      print('DEBUG: Error loading user info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 12),
              Text('Loading clinic ID...'),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Debug Info',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('Clinic ID: ${_clinicId ?? "Not found"}'),
            Text('User Email: ${_userEmail ?? "Not found"}'),
            SizedBox(height: 8),
            Text(
              'This clinic ID will be used for schedule storage in Firestore',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}