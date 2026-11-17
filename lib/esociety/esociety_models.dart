import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Where an idea stands with the Entrepreneurship Society. The first four
/// form the path an idea moves along; the last two close it.
enum IdeaStatus {
  submitted('submitted', 'Submitted', Icons.outbox_outlined, Color(0xFF5B6B62)),
  underReview(
    'under_review',
    'In review',
    Icons.manage_search,
    Color(0xFF2E7D4F),
  ),
  shortlisted(
    'shortlisted',
    'Shortlisted',
    Icons.bookmark_added_outlined,
    Color(0xFF2E7D4F),
  ),
  accepted('accepted', 'Accepted', Icons.verified_outlined, Color(0xFF1B5E20)),
  declined(
    'declined',
    'Not selected',
    Icons.do_not_disturb_on_outlined,
    Color(0xFFA3412F),
  ),
  withdrawn('withdrawn', 'Withdrawn', Icons.undo, Color(0xFF7A847E));

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const IdeaStatus(this.value, this.label, this.icon, this.color);

  static IdeaStatus parse(Object? value) => IdeaStatus.values.firstWhere(
    (s) => s.value == value,
    orElse: () => IdeaStatus.submitted,
  );

  /// The path an idea moves along, in order.
  static const List<IdeaStatus> track = [
    submitted,
    underReview,
    shortlisted,
    accepted,
  ];

  /// Statuses the society can move an idea to.
  static const List<IdeaStatus> societyChoices = [
    submitted,
    underReview,
    shortlisted,
    accepted,
    declined,
  ];

  bool get isClosed => this == declined || this == withdrawn;

  /// Position on [track], or -1 when the idea is closed.
  int get trackIndex => track.indexOf(this);

  /// The stage a society member would normally move the idea to next.
  IdeaStatus? get next => switch (this) {
    submitted => underReview,
    underReview => shortlisted,
    shortlisted => accepted,
    declined => underReview,
    _ => null,
  };

  /// Button text for moving to [next].
  String get nextAction => switch (this) {
    submitted => 'Start review',
    underReview => 'Shortlist',
    shortlisted => 'Accept',
    declined => 'Reopen',
    _ => '',
  };
}

/// The student's answer to the latest appointment.
enum AppointmentState {
  proposed('proposed', Color(0xFFA86B12)),
  confirmed('confirmed', Color(0xFF2E7D4F)),
  reschedule('reschedule', Color(0xFFA3412F)),
  cancelled('cancelled', Color(0xFF7A847E));

  final String value;
  final Color color;
  const AppointmentState(this.value, this.color);

  /// What the state means, worded for whoever is looking.
  String label({required bool forSociety}) => switch (this) {
    proposed =>
      forSociety ? 'Waiting for the student to confirm' : 'Please confirm',
    confirmed => 'Confirmed',
    reschedule =>
      forSociety
          ? 'Student asked for another time'
          : 'You asked for another time',
    cancelled => 'Cancelled',
  };

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

final DateFormat kAppointmentFormat = DateFormat("EEE d MMM 'at' h:mm a");
final DateFormat kShortDateFormat = DateFormat('d MMM yyyy');
final DateFormat kDayFormat = DateFormat('EEEE d MMMM');
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

  /// For a declined idea, the stage it had reached.
  final IdeaStatus? closedFrom;
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

  /// The team post on the collaboration board, when the student is also
  /// looking for teammates.
  final String? collabId;

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
    required this.closedFrom,
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
    this.collabId,
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
      closedFrom: d['closedFromStatus'] == null
          ? null
          : IdeaStatus.parse(d['closedFromStatus']),
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
      collabId: s('collabId').isEmpty ? null : s('collabId'),
    );
  }

  bool get hasReview => reviewRating != null || reviewText.isNotEmpty;

  /// An appointment that has not happened yet and was not cancelled, on an
  /// idea the student has not withdrawn.
  bool get hasUpcomingAppointment =>
      appointmentAt != null &&
      status != IdeaStatus.withdrawn &&
      appointmentState != AppointmentState.cancelled &&
      appointmentAt!.isAfter(DateTime.now().subtract(const Duration(hours: 2)));

  String get studentLine {
    final parts = <String>[
      if (degree.isNotEmpty) degree,
      if (semester != null) 'semester $semester',
    ];
    return parts.join(', ');
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
