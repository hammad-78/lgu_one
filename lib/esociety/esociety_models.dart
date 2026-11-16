import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Where an idea stands with the Entrepreneurship Society.
enum IdeaStatus {
  submitted('submitted', 'Submitted', Icons.send_outlined, Color(0xFF1E88E5)),
  underReview(
    'under_review',
    'In review',
    Icons.manage_search,
    Color(0xFFF9A825),
  ),
  shortlisted(
    'shortlisted',
    'Shortlisted',
    Icons.star_outline,
    Color(0xFF8E24AA),
  ),
  accepted('accepted', 'Accepted', Icons.verified_outlined, Color(0xFF2E7D32)),
  declined('declined', 'Not selected', Icons.block, Color(0xFFC62828)),
  withdrawn('withdrawn', 'Withdrawn', Icons.undo, Color(0xFF757575));

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const IdeaStatus(this.value, this.label, this.icon, this.color);

  static IdeaStatus parse(Object? value) => IdeaStatus.values.firstWhere(
    (s) => s.value == value,
    orElse: () => IdeaStatus.submitted,
  );

  /// Statuses the society can move an idea to.
  static const List<IdeaStatus> societyChoices = [
    submitted,
    underReview,
    shortlisted,
    accepted,
    declined,
  ];

  bool get isClosed => this == declined || this == withdrawn;
}

/// The student's answer to the latest appointment.
enum AppointmentState {
  proposed('proposed', 'Awaiting your reply', Color(0xFF1E88E5)),
  confirmed('confirmed', 'Confirmed', Color(0xFF2E7D32)),
  reschedule('reschedule', 'Student asked for another time', Color(0xFFEF6C00)),
  cancelled('cancelled', 'Cancelled', Color(0xFF757575));

  final String value;
  final String label;
  final Color color;
  const AppointmentState(this.value, this.label, this.color);

  static AppointmentState? parse(Object? value) {
    for (final s in AppointmentState.values) {
      if (s.value == value) return s;
    }
    return null;
  }
}

const List<String> kIdeaCategories = [
  'Tech / App',
  'E-commerce',
  'Food & Beverage',
  'Education',
  'Health',
  'Fashion & Retail',
  'Social impact',
  'Services',
  'Other',
];

const List<String> kIdeaStages = [
  'Just an idea',
  'Researching',
  'Prototype / MVP',
  'Already running',
];

const List<String> kIdeaHelpOptions = [
  'Mentorship',
  'Funding',
  'Team members',
  'Marketing',
  'Technical help',
  'Legal / registration',
];

DateTime? _toDate(Object? value) => value is Timestamp ? value.toDate() : null;

final DateFormat kAppointmentFormat = DateFormat('EEE, d MMM yyyy · h:mm a');
final DateFormat kShortDateFormat = DateFormat('d MMM yyyy');
final DateFormat kTimeFormat = DateFormat('h:mm a');

/// "Just now", "5m", "3h", "Yesterday", or a date.
String relativeTime(DateTime? time) {
  if (time == null) return 'Just now';
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return kShortDateFormat.format(time);
}

/// A startup idea a signed-in student shared with the society.
class Idea {
  final String id;
  final String studentUid;
  final String studentName;
  final String studentEmail;
  final String? studentPhoto;
  final String degree;
  final int? semester;
  final String? whatsapp;

  final String title;
  final String problem;
  final String solution;
  final String targetCustomers;
  final String category;
  final String stage;
  final int teamSize;
  final List<String> helpNeeded;

  final IdeaStatus status;
  final int? reviewRating;
  final String reviewText;
  final String reviewedBy;
  final DateTime? reviewedAt;

  final DateTime? appointmentAt;
  final String appointmentPlace;
  final String appointmentNote;
  final AppointmentState? appointmentState;

  final String lastMessagePreview;
  final String lastMessageBy;
  final DateTime? lastActivityAt;
  final bool unreadForStudent;
  final bool unreadForSociety;
  final DateTime? createdAt;

  const Idea({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.studentEmail,
    required this.studentPhoto,
    required this.degree,
    required this.semester,
    required this.whatsapp,
    required this.title,
    required this.problem,
    required this.solution,
    required this.targetCustomers,
    required this.category,
    required this.stage,
    required this.teamSize,
    required this.helpNeeded,
    required this.status,
    required this.reviewRating,
    required this.reviewText,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.appointmentAt,
    required this.appointmentPlace,
    required this.appointmentNote,
    required this.appointmentState,
    required this.lastMessagePreview,
    required this.lastMessageBy,
    required this.lastActivityAt,
    required this.unreadForStudent,
    required this.unreadForSociety,
    required this.createdAt,
  });

  factory Idea.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    String s(String key) => (d[key] ?? '').toString();
    final whatsapp = s('whatsapp');
    final photo = s('studentPhoto');
    return Idea(
      id: doc.id,
      studentUid: s('studentUid'),
      studentName: s('studentName'),
      studentEmail: s('studentEmail'),
      studentPhoto: photo.isEmpty ? null : photo,
      degree: s('degree'),
      semester: (d['semester'] as num?)?.toInt(),
      whatsapp: whatsapp.isEmpty ? null : whatsapp,
      title: s('title'),
      problem: s('problem'),
      solution: s('solution'),
      targetCustomers: s('targetCustomers'),
      category: s('category'),
      stage: s('stage'),
      teamSize: (d['teamSize'] as num?)?.toInt() ?? 1,
      helpNeeded: ((d['helpNeeded'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      status: IdeaStatus.parse(d['status']),
      reviewRating: (d['reviewRating'] as num?)?.toInt(),
      reviewText: s('reviewText'),
      reviewedBy: s('reviewedBy'),
      reviewedAt: _toDate(d['reviewedAt']),
      appointmentAt: _toDate(d['appointmentAt']),
      appointmentPlace: s('appointmentPlace'),
      appointmentNote: s('appointmentNote'),
      appointmentState: AppointmentState.parse(d['appointmentState']),
      lastMessagePreview: s('lastMessagePreview'),
      lastMessageBy: s('lastMessageBy'),
      lastActivityAt: _toDate(d['lastActivityAt']),
      unreadForStudent: d['unreadForStudent'] == true,
      unreadForSociety: d['unreadForSociety'] == true,
      createdAt: _toDate(d['createdAt']),
    );
  }

  bool get hasReview => reviewRating != null || reviewText.isNotEmpty;

  /// An appointment that has not happened yet and was not cancelled.
  bool get hasUpcomingAppointment =>
      appointmentAt != null &&
      appointmentState != AppointmentState.cancelled &&
      appointmentAt!.isAfter(DateTime.now().subtract(const Duration(hours: 2)));

  String get studentLine {
    final parts = <String>[
      if (degree.isNotEmpty) degree,
      if (semester != null) 'Semester $semester',
    ];
    return parts.join(' · ');
  }
}

/// Kinds of entries in an idea's conversation thread.
enum MessageKind {
  text('text'),
  appointment('appointment'),
  appointmentReply('appointment_reply'),
  status('status'),
  review('review');

  final String value;
  const MessageKind(this.value);

  static MessageKind parse(Object? value) => MessageKind.values.firstWhere(
    (k) => k.value == value,
    orElse: () => MessageKind.text,
  );
}

/// One entry in the conversation between a student and the society.
class IdeaMessage {
  final String id;
  final MessageKind kind;
  final bool fromSociety;
  final String senderName;
  final String text;
  final DateTime? createdAt;
  final DateTime? appointmentAt;
  final String appointmentPlace;
  final String? appointmentReply;
  final String? status;
  final int? rating;

  const IdeaMessage({
    required this.id,
    required this.kind,
    required this.fromSociety,
    required this.senderName,
    required this.text,
    required this.createdAt,
    required this.appointmentAt,
    required this.appointmentPlace,
    required this.appointmentReply,
    required this.status,
    required this.rating,
  });

  factory IdeaMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return IdeaMessage(
      id: doc.id,
      kind: MessageKind.parse(d['kind']),
      fromSociety: d['senderRole'] == 'society',
      senderName: (d['senderName'] ?? '').toString(),
      text: (d['text'] ?? '').toString(),
      // Pending server timestamps read as null until the write lands.
      createdAt: _toDate(d['createdAt']) ?? DateTime.now(),
      appointmentAt: _toDate(d['appointmentAt']),
      appointmentPlace: (d['appointmentPlace'] ?? '').toString(),
      appointmentReply: d['appointmentReply']?.toString(),
      status: d['status']?.toString(),
      rating: (d['rating'] as num?)?.toInt(),
    );
  }
}

/// A society member's review of a student collaboration.
class CollabReview {
  final String reviewerUid;
  final String reviewerName;
  final int rating;
  final String comment;
  final DateTime? updatedAt;

  const CollabReview({
    required this.reviewerUid,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.updatedAt,
  });

  factory CollabReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return CollabReview(
      reviewerUid: doc.id,
      reviewerName: (d['reviewerName'] ?? 'E-Society').toString(),
      rating: (d['rating'] as num?)?.toInt() ?? 0,
      comment: (d['comment'] ?? '').toString(),
      updatedAt: _toDate(d['updatedAt']),
    );
  }
}

/// A signed-in Entrepreneurship Society portal member.
class EsocietyMember {
  final String uid;
  final String name;
  final String role;
  final String email;
  const EsocietyMember({
    required this.uid,
    required this.name,
    required this.role,
    required this.email,
  });
}
