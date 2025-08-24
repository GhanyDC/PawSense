import 'package:pawsense/core/models/support/ticket_status.dart';

class SupportTicket {
  final String id;
  final String title;
  final String description;
  final String submitterName;
  final String submitterEmail;
  final String category;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime lastReply;
  final bool isFavorited;

  SupportTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.submitterName,
    required this.submitterEmail,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.lastReply,
    this.isFavorited = false,
  });

  String get formattedCreatedAt {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedLastReply {
    return '${lastReply.year}-${lastReply.month.toString().padLeft(2, '0')}-${lastReply.day.toString().padLeft(2, '0')} ${lastReply.hour.toString().padLeft(2, '0')}:${lastReply.minute.toString().padLeft(2, '0')}';
  }
}