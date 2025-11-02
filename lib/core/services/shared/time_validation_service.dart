import 'package:flutter/material.dart';
import 'package:pawsense/core/services/shared/server_time_service.dart';

/// Result of time validation check
class TimeValidationResult {
  final bool isValid;
  final Duration skewDuration;
  final DateTime serverTime;
  final DateTime deviceTime;
  final String message;
  final TimeSkewSeverity severity;

  TimeValidationResult({
    required this.isValid,
    required this.skewDuration,
    required this.serverTime,
    required this.deviceTime,
    required this.message,
    required this.severity,
  });

  /// Get user-friendly description of the time skew
  String get description {
    if (isValid) {
      return 'Device time is accurate';
    }
    
    final absSkew = skewDuration.abs();
    final direction = skewDuration.isNegative ? 'behind' : 'ahead';
    
    if (absSkew.inDays > 0) {
      return 'Device time is ${absSkew.inDays} days $direction';
    } else if (absSkew.inHours > 0) {
      return 'Device time is ${absSkew.inHours} hours $direction';
    } else {
      return 'Device time is ${absSkew.inMinutes} minutes $direction';
    }
  }
}

/// Severity levels for time skew
enum TimeSkewSeverity {
  none,     // No skew or within acceptable range
  warning,  // Minor skew (5-30 minutes)
  moderate, // Moderate skew (30 minutes - 1 day)
  critical, // Critical skew (>1 day) - likely to cause auth failures
}

/// Service for validating device time against server time
/// 
/// Features:
/// - Detects device time skew
/// - Provides severity classification
/// - Shows user-friendly warning dialogs
/// - Offers guidance for fixing time issues
class TimeValidationService {
  /// Maximum acceptable time skew (5 minutes)
  static const Duration maxAllowedSkew = Duration(minutes: 5);
  
  /// Warning threshold (30 minutes)
  static const Duration warningThreshold = Duration(minutes: 30);
  
  /// Moderate threshold (1 day)
  static const Duration moderateThreshold = Duration(days: 1);
  
  /// Validate device time against server time
  static Future<TimeValidationResult> validateDeviceTime() async {
    try {
      // Ensure server time is synced
      final serverTime = await ServerTimeService.getServerTime();
      final deviceTime = DateTime.now();
      final skew = deviceTime.difference(serverTime);
      final absSkew = skew.abs();
      
      // Determine severity
      final severity = _determineSeverity(absSkew);
      final isValid = absSkew <= maxAllowedSkew;
      
      // Generate message
      final message = _generateMessage(skew, severity);
      
      return TimeValidationResult(
        isValid: isValid,
        skewDuration: skew,
        serverTime: serverTime,
        deviceTime: deviceTime,
        message: message,
        severity: severity,
      );
    } catch (e) {
      debugPrint('⚠️ Time validation failed: $e');
      
      // Return a result indicating validation failure
      final now = DateTime.now();
      return TimeValidationResult(
        isValid: true, // Assume valid if we can't validate
        skewDuration: Duration.zero,
        serverTime: now,
        deviceTime: now,
        message: 'Unable to validate device time',
        severity: TimeSkewSeverity.none,
      );
    }
  }
  
  /// Determine severity level of time skew
  static TimeSkewSeverity _determineSeverity(Duration absSkew) {
    if (absSkew <= maxAllowedSkew) {
      return TimeSkewSeverity.none;
    } else if (absSkew <= warningThreshold) {
      return TimeSkewSeverity.warning;
    } else if (absSkew <= moderateThreshold) {
      return TimeSkewSeverity.moderate;
    } else {
      return TimeSkewSeverity.critical;
    }
  }
  
  /// Generate user-friendly message based on skew
  static String _generateMessage(Duration skew, TimeSkewSeverity severity) {
    switch (severity) {
      case TimeSkewSeverity.none:
        return 'Your device time is accurate.';
      
      case TimeSkewSeverity.warning:
        return 'Your device time is slightly off. This might cause minor issues.';
      
      case TimeSkewSeverity.moderate:
        return 'Your device time is significantly off. Some features may not work correctly.';
      
      case TimeSkewSeverity.critical:
        return 'Your device time is critically off. Sign-in and other features will not work.';
    }
  }
  
  /// Show time skew warning dialog to user
  static Future<void> showTimeSkewWarning(
    BuildContext context,
    TimeValidationResult result,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: result.severity != TimeSkewSeverity.critical,
      builder: (context) => AlertDialog(
        icon: Icon(
          _getIconForSeverity(result.severity),
          color: _getColorForSeverity(result.severity),
          size: 48,
        ),
        title: Text(_getTitleForSeverity(result.severity)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message),
            const SizedBox(height: 16),
            Text(result.description, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTimeComparison(result),
            const SizedBox(height: 16),
            _buildFixInstructions(result.severity),
          ],
        ),
        actions: [
          if (result.severity != TimeSkewSeverity.critical)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue Anyway'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open device settings (platform-specific)
              _openDeviceSettings(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Build time comparison widget
  static Widget _buildTimeComparison(TimeValidationResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Device Time:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(_formatDateTime(result.deviceTime)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Correct Time:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(_formatDateTime(result.serverTime)),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build fix instructions widget
  static Widget _buildFixInstructions(TimeSkewSeverity severity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'How to Fix:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('1. Open your device Settings'),
          const Text('2. Go to "Date & Time"'),
          const Text('3. Enable "Automatic date & time"'),
          const Text('4. Restart PawSense'),
        ],
      ),
    );
  }
  
  /// Format DateTime for display
  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  
  /// Get icon for severity level
  static IconData _getIconForSeverity(TimeSkewSeverity severity) {
    switch (severity) {
      case TimeSkewSeverity.none:
        return Icons.check_circle;
      case TimeSkewSeverity.warning:
        return Icons.warning_amber;
      case TimeSkewSeverity.moderate:
        return Icons.error_outline;
      case TimeSkewSeverity.critical:
        return Icons.error;
    }
  }
  
  /// Get color for severity level
  static Color _getColorForSeverity(TimeSkewSeverity severity) {
    switch (severity) {
      case TimeSkewSeverity.none:
        return Colors.green;
      case TimeSkewSeverity.warning:
        return Colors.orange;
      case TimeSkewSeverity.moderate:
        return Colors.deepOrange;
      case TimeSkewSeverity.critical:
        return Colors.red;
    }
  }
  
  /// Get title for severity level
  static String _getTitleForSeverity(TimeSkewSeverity severity) {
    switch (severity) {
      case TimeSkewSeverity.none:
        return 'Time is Accurate';
      case TimeSkewSeverity.warning:
        return 'Time Slightly Off';
      case TimeSkewSeverity.moderate:
        return 'Time Significantly Off';
      case TimeSkewSeverity.critical:
        return 'Critical Time Error';
    }
  }
  
  /// Open device settings (platform-specific implementation would go here)
  static void _openDeviceSettings(BuildContext context) {
    // This would use platform-specific code to open settings
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please manually open your device Settings to fix the time'),
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  /// Check if auth operations should be blocked due to time skew
  static Future<bool> shouldBlockAuth() async {
    final result = await validateDeviceTime();
    return result.severity == TimeSkewSeverity.critical;
  }
  
  /// Check if warning should be shown (but not block)
  static Future<bool> shouldShowWarning() async {
    final result = await validateDeviceTime();
    return result.severity == TimeSkewSeverity.moderate || 
           result.severity == TimeSkewSeverity.warning;
  }
  
  /// Validate and show warning if needed
  /// Returns true if validation passed or user chose to continue
  static Future<bool> validateAndWarn(BuildContext context) async {
    final result = await validateDeviceTime();
    
    if (result.isValid) {
      return true; // All good
    }
    
    if (result.severity == TimeSkewSeverity.warning) {
      // Just log warning, don't show dialog
      debugPrint('⚠️ Minor time skew detected: ${result.description}');
      return true;
    }
    
    // Show warning dialog for moderate/critical
    await showTimeSkewWarning(context, result);
    
    // Block if critical, otherwise allow continue
    return result.severity != TimeSkewSeverity.critical;
  }
  
  /// Show a simple snackbar warning
  static void showSnackbarWarning(BuildContext context, TimeValidationResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForSeverity(result.severity),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(result.message),
            ),
          ],
        ),
        backgroundColor: _getColorForSeverity(result.severity),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () {
            showTimeSkewWarning(context, result);
          },
        ),
      ),
    );
  }
}
