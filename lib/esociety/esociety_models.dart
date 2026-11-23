import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

/// How long a meeting slot lasts. Two meetings closer than this clash.
const Duration kMeetingLength = Duration(minutes: 30);

final DateFormat kMeetingFormat = DateFormat("EEE d MMM 'at' h:mm a");
final DateFormat kShortDateFormat = DateFormat('d MMM yyyy');
final DateFormat kTimeFormat = DateFormat('h:mm a');

DateTime? _toDate(Object? value) => value is Timestamp ? value.toDate() : null;

/// "Just now", "5m ago", "3h ago", "Yesterday", or a date.
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

/// An idea a student sent to the Entrepreneurship Society
/// (`esociety_ideas/{id}`). The society sends a meeting time; the student
/// can ask for another one, which the society approves.
class Idea {
  final String id;
  final String studentUid;
  final String studentName;
  final String studentEmail;
  final String? studentPhoto;
  final String degree;
  final int? semester;
  final String whatsapp;

  final String title;
  final String description;
  final String category;
  final List<String> roles;
  final int teamSize;
  final int teamWanted;
  final DateTime? createdAt;

  final DateTime? meetingAt;
  final String meetingPlace;

  /// A new time the student asked for, waiting for the society.
  final DateTime? requestedAt;
  final String requestNote;

  /// Set aside by the society.
  final bool deactivated;

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
    required this.description,
    required this.category,
    required this.roles,
    required this.teamSize,
    required this.teamWanted,
    required this.createdAt,
    required this.meetingAt,
    required this.meetingPlace,
    required this.requestedAt,
    required this.requestNote,
    required this.deactivated,
  });

  factory Idea.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    String s(String key) => (d[key] ?? '').toString();
    int n(String key, int fallback) => (d[key] as num?)?.toInt() ?? fallback;
    final photo = s('studentPhoto');
    return Idea(
      id: doc.id,
      studentUid: s('studentUid'),
      studentName: s('studentName'),
      studentEmail: s('studentEmail'),
      studentPhoto: photo.isEmpty ? null : photo,
      degree: s('degree'),
      semester: (d['semester'] as num?)?.toInt(),
      whatsapp: s('whatsapp'),
      title: s('title'),
      description: s('description'),
      category: s('category'),
      roles: ((d['roles'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      teamSize: n('teamSize', 1),
      teamWanted: n('teamWanted', 0),
      createdAt: _toDate(d['createdAt']),
      meetingAt: _toDate(d['meetingAt']),
      meetingPlace: s('meetingPlace'),
      requestedAt: _toDate(d['requestedAt']),
      requestNote: s('requestNote'),
      deactivated: d['deactivated'] == true,
    );
  }

  /// The meeting time has gone by.
  bool get meetingPassed =>
      meetingAt != null && meetingAt!.isBefore(DateTime.now());

  /// Deactivated, or its meeting has happened: listed under Past.
  bool get isPast => deactivated || (meetingPassed && requestedAt == null);

  /// A meeting still to come, on an active idea.
  bool get hasUpcomingMeeting =>
      !deactivated && meetingAt != null && !meetingPassed;

  String get studentLine => [
    if (degree.isNotEmpty) degree,
    if (semester != null) 'semester $semester',
  ].join(', ');

  String get teamLine => teamWanted > 0
      ? '$teamSize of $teamWanted members'
      : '$teamSize ${teamSize == 1 ? 'member' : 'members'}';
}

/// The active idea whose meeting is within [kMeetingLength] of [at], other
/// than [except]. Null when the time is free.
Idea? meetingClash(List<Idea> ideas, DateTime at, {String? except}) {
  for (final i in ideas) {
    if (i.id == except || !i.hasUpcomingMeeting) continue;
    if (i.meetingAt!.difference(at).abs() < kMeetingLength) return i;
  }
  return null;
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
