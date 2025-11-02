import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth/auth_time_enhancement.dart';
import '../../core/services/shared/server_time_service.dart';
import '../../core/services/shared/time_validation_service.dart';

/// Diagnostic page for testing and debugging authentication time issues
/// 
/// Features:
/// - Display current auth state
/// - Show time sync status
/// - Test token refresh
/// - Force time resync
/// - Validate device time
/// - Show comprehensive diagnostics
/// 
/// Usage: Add to router for QA testing
class AuthDiagnosticsPage extends StatefulWidget {
  const AuthDiagnosticsPage({super.key});

  @override
  State<AuthDiagnosticsPage> createState() => _AuthDiagnosticsPageState();
}

class _AuthDiagnosticsPageState extends State<AuthDiagnosticsPage> {
  Map<String, dynamic>? _authDiagnostics;
  Map<String, dynamic>? _serverTimeDiagnostics;
  TimeValidationResult? _timeValidation;
  bool _isLoading = false;
  String? _lastActionResult;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _isLoading = true);
    
    try {
      final authDiag = await AuthTimeEnhancement.getDiagnostics(FirebaseAuth.instance);
      final serverTimeDiag = ServerTimeService.getDiagnostics();
      final timeValidation = await TimeValidationService.validateDeviceTime();
      
      setState(() {
        _authDiagnostics = authDiag;
        _serverTimeDiagnostics = serverTimeDiag;
        _timeValidation = timeValidation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastActionResult = 'Error loading diagnostics: $e';
      });
    }
  }

  Future<void> _refreshToken() async {
    setState(() {
      _lastActionResult = null;
    });
    
    final success = await AuthTimeEnhancement.refreshAuthToken(FirebaseAuth.instance);
    
    setState(() {
      _lastActionResult = success 
        ? '✅ Token refreshed successfully'
        : '❌ Token refresh failed';
    });
    
    await _loadDiagnostics();
  }

  Future<void> _forceTimeResync() async {
    setState(() {
      _lastActionResult = null;
    });
    
    try {
      await ServerTimeService.forceResync();
      setState(() {
        _lastActionResult = '✅ Time resync completed';
      });
    } catch (e) {
      setState(() {
        _lastActionResult = '❌ Time resync failed: $e';
      });
    }
    
    await _loadDiagnostics();
  }

  Future<void> _validateAuthState() async {
    setState(() {
      _lastActionResult = null;
    });
    
    final isValid = await AuthTimeEnhancement.validateAuthState(FirebaseAuth.instance);
    
    setState(() {
      _lastActionResult = isValid
        ? '✅ Auth state is healthy'
        : '❌ Auth state needs attention';
    });
    
    await _loadDiagnostics();
  }

  Future<void> _attemptRecovery() async {
    setState(() {
      _lastActionResult = null;
    });
    
    final success = await AuthTimeEnhancement.attemptAuthRecovery(FirebaseAuth.instance);
    
    setState(() {
      _lastActionResult = success
        ? '✅ Auth recovery successful'
        : '❌ Auth recovery failed';
    });
    
    await _loadDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiagnostics,
            tooltip: 'Refresh diagnostics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                  
                  // Last action result
                  if (_lastActionResult != null)
                    _buildResultCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Time validation
                  _buildTimeValidationCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Server time diagnostics
                  _buildServerTimeCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Auth diagnostics
                  _buildAuthCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Quick tips
                  _buildTipsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshToken,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh Token'),
                ),
                ElevatedButton.icon(
                  onPressed: _forceTimeResync,
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Force Time Sync'),
                ),
                ElevatedButton.icon(
                  onPressed: _validateAuthState,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Validate Auth'),
                ),
                ElevatedButton.icon(
                  onPressed: _attemptRecovery,
                  icon: const Icon(Icons.healing, size: 18),
                  label: const Text('Attempt Recovery'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final isSuccess = _lastActionResult!.startsWith('✅');
    return Card(
      color: isSuccess ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _lastActionResult!,
                style: TextStyle(
                  color: isSuccess ? Colors.green[900] : Colors.red[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeValidationCard() {
    if (_timeValidation == null) return const SizedBox.shrink();
    
    final severity = _timeValidation!.severity;
    Color color;
    IconData icon;
    
    switch (severity) {
      case TimeSkewSeverity.none:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case TimeSkewSeverity.warning:
        color = Colors.orange;
        icon = Icons.warning_amber;
        break;
      case TimeSkewSeverity.moderate:
        color = Colors.deepOrange;
        icon = Icons.error_outline;
        break;
      case TimeSkewSeverity.critical:
        color = Colors.red;
        icon = Icons.error;
        break;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Time Validation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDiagnosticRow('Status', _timeValidation!.description, color),
            _buildDiagnosticRow('Message', _timeValidation!.message),
            _buildDiagnosticRow('Severity', severity.toString().split('.').last),
            _buildDiagnosticRow('Device Time', _formatDateTime(_timeValidation!.deviceTime)),
            _buildDiagnosticRow('Server Time', _formatDateTime(_timeValidation!.serverTime)),
            _buildDiagnosticRow('Skew', '${_timeValidation!.skewDuration.inMinutes} minutes'),
          ],
        ),
      ),
    );
  }

  Widget _buildServerTimeCard() {
    if (_serverTimeDiagnostics == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Server Time Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDiagnosticRow(
              'Initialized',
              _serverTimeDiagnostics!['initialized'].toString(),
            ),
            _buildDiagnosticRow(
              'Offset',
              '${_serverTimeDiagnostics!['offsetMinutes'] ?? '?'} minutes',
            ),
            _buildDiagnosticRow(
              'Last Sync',
              _serverTimeDiagnostics!['lastSyncTime']?.toString() ?? 'Never',
            ),
            _buildDiagnosticRow(
              'Time Since Sync',
              '${_serverTimeDiagnostics!['timeSinceLastSyncMinutes'] ?? '?'} minutes',
            ),
            _buildDiagnosticRow(
              'Device Time',
              _serverTimeDiagnostics!['deviceTime']?.toString() ?? 'Unknown',
            ),
            _buildDiagnosticRow(
              'Server Time',
              _serverTimeDiagnostics!['estimatedServerTime']?.toString() ?? 'Unknown',
            ),
            _buildDiagnosticRow(
              'Is Accurate',
              _serverTimeDiagnostics!['isAccurate']?.toString() ?? 'Unknown',
              _serverTimeDiagnostics!['isAccurate'] == true ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    if (_authDiagnostics == null) return const SizedBox.shrink();
    
    final authState = _authDiagnostics!['authState'] as Map<String, dynamic>?;
    final token = _authDiagnostics!['token'] as Map<String, dynamic>?;
    final monitoring = _authDiagnostics!['monitoring'] as Map<String, dynamic>?;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Authentication State',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (authState != null) ...[
              _buildDiagnosticRow(
                'Signed In',
                authState['isSignedIn'].toString(),
                authState['isSignedIn'] == true ? Colors.green : Colors.red,
              ),
              if (authState['uid'] != null)
                _buildDiagnosticRow('UID', authState['uid']),
              if (authState['email'] != null)
                _buildDiagnosticRow('Email', authState['email']),
              _buildDiagnosticRow(
                'Email Verified',
                authState['emailVerified'].toString(),
              ),
            ],
            if (token != null) ...[
              const Divider(),
              const Text(
                'Token Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildDiagnosticRow(
                'Valid',
                token['isValid'].toString(),
                token['isValid'] == true ? Colors.green : Colors.red,
              ),
              if (token['minutesUntilExpiration'] != null)
                _buildDiagnosticRow(
                  'Expires In',
                  '${token['minutesUntilExpiration']} minutes',
                ),
            ],
            if (monitoring != null) ...[
              const Divider(),
              const Text(
                'Monitoring Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildDiagnosticRow(
                'Active',
                monitoring['isActive'].toString(),
              ),
              _buildDiagnosticRow(
                'Refresh Timer',
                monitoring['hasRefreshTimer'].toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'QA Testing Tips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('1. Change device time forward/backward'),
            const Text('2. Try to sign in (should show time error)'),
            const Text('3. Correct device time'),
            const Text('4. Click "Attempt Recovery"'),
            const Text('5. Try to sign in again (should work)'),
            const SizedBox(height: 8),
            const Text(
              'Expected Behavior:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text('• Critical skew (>1 day): Auth blocked'),
            const Text('• Moderate skew (30min-1day): Warning shown'),
            const Text('• Minor skew (<30min): Allowed with log'),
            const Text('• After time correction: Recovery works'),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
