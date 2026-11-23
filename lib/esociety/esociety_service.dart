import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lgu_one/esociety/esociety_models.dart';

/// Firestore access for the Entrepreneurship Society.
///
/// - `esociety_ideas/{ideaId}`: an idea a student sent, with its meeting
///   time, the student's request for another time, and `deactivated`.
/// - `esociety_members/{uid}`: portal accounts (managed in the console).
class EsocietyService {
  EsocietyService._();
  static final EsocietyService instance = EsocietyService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get ideas =>
      _db.collection('esociety_ideas');

  /// The portal member for [user], or null if the account has no access.
  /// Admins may use the portal too.
  Future<EsocietyMember?> memberFor(User user) async {
    final member = await _db.collection('esociety_members').doc(user.uid).get();
    if (member.exists) {
      final d = member.data() ?? const {};
      if (d['active'] == false) return null;
      return EsocietyMember(
        uid: user.uid,
        name: (d['name'] ?? user.displayName ?? 'E-Society').toString(),
        role: (d['role'] ?? 'Member').toString(),
        email: user.email ?? '',
      );
    }
    final admin = await _db.collection('admins').doc(user.uid).get();
    if (admin.exists) {
      final d = admin.data() ?? const {};
      final isAdmin =
          d['isAdmin'] == true ||
          d['isAdmin']?.toString().toLowerCase() == 'true' ||
          d['role']?.toString().toLowerCase() == 'admin';
      if (!isAdmin) return null;
      return EsocietyMember(
        uid: user.uid,
        name: (d['name'] ?? user.displayName ?? 'Administrator').toString(),
        role: 'Admin',
        email: user.email ?? '',
      );
    }
    return null;
  }

  /// The student's own ideas, newest first.
  Stream<List<Idea>> studentIdeas(String uid) => ideas
      .where('studentUid', isEqualTo: uid)
      .snapshots()
      .map((snap) => _newestFirst(snap.docs.map(Idea.fromDoc)));

  /// Every idea, newest first.
  Stream<List<Idea>> allIdeas() => ideas.snapshots().map(
    (snap) => _newestFirst(snap.docs.map(Idea.fromDoc)),
  );

  /// Student asks for another meeting time.
  Future<void> requestTime(Idea idea, DateTime at, String note) => ideas
      .doc(idea.id)
      .update({'requestedAt': Timestamp.fromDate(at), 'requestNote': note});

  /// Society sends a meeting time. Replaces any request from the student.
  Future<void> setMeeting(Idea idea, DateTime at, String place) =>
      ideas.doc(idea.id).update({
        'meetingAt': Timestamp.fromDate(at),
        'meetingPlace': place,
        'requestedAt': null,
        'requestNote': '',
        'deactivated': false,
      });

  /// Society accepts the time the student asked for.
  Future<void> approveRequest(Idea idea) =>
      setMeeting(idea, idea.requestedAt!, idea.meetingPlace);

  Future<void> setDeactivated(Idea idea, bool deactivated) =>
      ideas.doc(idea.id).update({'deactivated': deactivated});

  static List<Idea> _newestFirst(Iterable<Idea> list) {
    final epoch = DateTime.now();
    return list.toList()
      ..sort((a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch));
  }
}
