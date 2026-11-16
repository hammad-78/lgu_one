import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lgu_one/esociety/esociety_models.dart';

/// Firestore access for the Entrepreneurship Society.
///
/// Data layout:
/// - `esociety_ideas/{ideaId}`: an idea, its status, review and the latest
///   appointment, plus last-activity and unread flags for both sides.
/// - `esociety_ideas/{ideaId}/messages/{id}`: the conversation thread
///   (replies, appointments, status changes and reviews, in order).
/// - `collaborations/{id}/esociety_reviews/{memberUid}`: one review per
///   society member on a student collaboration.
/// - `esociety_members/{uid}`: portal accounts (managed in the console).
class EsocietyService {
  EsocietyService._();
  static final EsocietyService instance = EsocietyService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ideas =>
      _db.collection('esociety_ideas');

  CollectionReference<Map<String, dynamic>> _messages(String ideaId) =>
      _ideas.doc(ideaId).collection('messages');

  static String _preview(String text) {
    final oneLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return oneLine.length > 90 ? '${oneLine.substring(0, 90)}…' : oneLine;
  }

  // ─── Portal membership ────────────────────────────────────────────────────

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

  // ─── Student side ─────────────────────────────────────────────────────────

  /// The student's own ideas, most recent activity first.
  Stream<List<Idea>> studentIdeas(String uid) {
    return _ideas.where('studentUid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(Idea.fromDoc).toList();
      list.sort(_byActivity);
      return list;
    });
  }

  Future<void> submitIdea({
    required User student,
    required Map<String, dynamic> profile,
    required String title,
    required String problem,
    required String solution,
    required String targetCustomers,
    required String category,
    required String stage,
    required int teamSize,
    required List<String> helpNeeded,
    required String? whatsapp,
  }) async {
    final name = (profile['name'] ?? '').toString().trim();
    final studentName = name.isNotEmpty
        ? name
        : (student.displayName ?? student.email ?? 'Student');
    final photo = profile.containsKey('photoUrl')
        ? profile['photoUrl']
        : student.photoURL;

    final ref = _ideas.doc();
    final batch = _db.batch();
    batch.set(ref, {
      'studentUid': student.uid,
      'studentName': studentName,
      'studentEmail': student.email,
      'studentPhoto': photo,
      'degree': (profile['degree'] ?? '').toString(),
      'semester': profile['semester'],
      'whatsapp': whatsapp,
      'title': title,
      'problem': problem,
      'solution': solution,
      'targetCustomers': targetCustomers,
      'category': category,
      'stage': stage,
      'teamSize': teamSize,
      'helpNeeded': helpNeeded,
      'status': IdeaStatus.submitted.value,
      'lastMessagePreview': 'Idea submitted',
      'lastMessageBy': 'student',
      'lastActivityAt': FieldValue.serverTimestamp(),
      'unreadForStudent': false,
      'unreadForSociety': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(ref.collection('messages').doc(), {
      'kind': MessageKind.status.value,
      'status': IdeaStatus.submitted.value,
      'senderRole': 'student',
      'senderUid': student.uid,
      'senderName': studentName,
      'text': 'Idea shared with the Entrepreneurship Society.',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> withdrawIdea(Idea idea, User student) async {
    final batch = _db.batch();
    batch.update(_ideas.doc(idea.id), {
      'status': IdeaStatus.withdrawn.value,
      'lastMessagePreview': 'Idea withdrawn by the student',
      'lastMessageBy': 'student',
      'lastActivityAt': FieldValue.serverTimestamp(),
      'unreadForSociety': true,
    });
    batch.set(_messages(idea.id).doc(), {
      'kind': MessageKind.status.value,
      'status': IdeaStatus.withdrawn.value,
      'senderRole': 'student',
      'senderUid': student.uid,
      'senderName': idea.studentName,
      'text': 'The student withdrew this idea.',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Student confirms the appointment, or asks for another time.
  Future<void> answerAppointment(
    Idea idea,
    User student, {
    required bool confirm,
    String note = '',
  }) async {
    final state = confirm
        ? AppointmentState.confirmed
        : AppointmentState.reschedule;
    final text = confirm
        ? 'Confirmed the appointment.${note.isEmpty ? '' : '\n$note'}'
        : 'Asked for another time.${note.isEmpty ? '' : '\n$note'}';
    final batch = _db.batch();
    batch.update(_ideas.doc(idea.id), {
      'appointmentState': state.value,
      'lastMessagePreview': _preview(text),
      'lastMessageBy': 'student',
      'lastActivityAt': FieldValue.serverTimestamp(),
      'unreadForSociety': true,
    });
    batch.set(_messages(idea.id).doc(), {
      'kind': MessageKind.appointmentReply.value,
      'appointmentReply': state.value,
      'senderRole': 'student',
      'senderUid': student.uid,
      'senderName': idea.studentName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ─── Shared ───────────────────────────────────────────────────────────────

  Stream<Idea?> idea(String id) => _ideas
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Idea.fromDoc(doc) : null);

  Stream<List<IdeaMessage>> messages(String ideaId) => _messages(ideaId)
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(IdeaMessage.fromDoc).toList());

  /// Posts a plain reply. [fromSociety] decides whose side it lands on.
  Future<void> sendReply({
    required String ideaId,
    required bool fromSociety,
    required String senderUid,
    required String senderName,
    required String text,
  }) async {
    final batch = _db.batch();
    batch.update(_ideas.doc(ideaId), {
      'lastMessagePreview': _preview(text),
      'lastMessageBy': fromSociety ? 'society' : 'student',
      'lastActivityAt': FieldValue.serverTimestamp(),
      if (fromSociety) 'unreadForStudent': true else 'unreadForSociety': true,
    });
    batch.set(_messages(ideaId).doc(), {
      'kind': MessageKind.text.value,
      'senderRole': fromSociety ? 'society' : 'student',
      'senderUid': senderUid,
      'senderName': senderName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Clears the unread flag for whoever is viewing the thread.
  Future<void> markRead(Idea idea, {required bool asSociety}) async {
    if (asSociety ? !idea.unreadForSociety : !idea.unreadForStudent) return;
    try {
      await _ideas.doc(idea.id).update({
        asSociety ? 'unreadForSociety' : 'unreadForStudent': false,
      });
    } catch (_) {
      // Not worth bothering the user about.
    }
  }

  // ─── Society side ─────────────────────────────────────────────────────────

  /// Every idea, most recent activity first.
  Stream<List<Idea>> allIdeas() => _ideas.snapshots().map((snap) {
    final list = snap.docs.map(Idea.fromDoc).toList();
    list.sort(_byActivity);
    return list;
  });

  Future<void> setStatus(
    Idea idea,
    EsocietyMember member,
    IdeaStatus status, {
    String note = '',
  }) async {
    final text =
        'Status changed to ${status.label}.${note.isEmpty ? '' : '\n$note'}';
    final batch = _db.batch();
    batch.update(_ideas.doc(idea.id), {
      'status': status.value,
      'lastMessagePreview': _preview(text),
      'lastMessageBy': 'society',
      'lastActivityAt': FieldValue.serverTimestamp(),
      'unreadForStudent': true,
    });
    batch.set(_messages(idea.id).doc(), {
      'kind': MessageKind.status.value,
      'status': status.value,
      'senderRole': 'society',
      'senderUid': member.uid,
      'senderName': member.name,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> saveReview(
    Idea idea,
    EsocietyMember member, {
    required int rating,
    required String text,
  }) async {
    final batch = _db.batch();
    batch.update(_ideas.doc(idea.id), {
      'reviewRating': rating,
      'reviewText': text,
      'reviewedBy': member.name,
      'reviewedAt': FieldValue.serverTimestamp(),
      'lastMessagePreview': _preview('Review: $rating/5 · $text'),
      'lastMessageBy': 'society',
      'lastActivityAt': FieldValue.serverTimestamp(),
      'unreadForStudent': true,
      // Reviewing an untouched idea means it is being looked at.
      if (idea.status == IdeaStatus.submitted)
        'status': IdeaStatus.underReview.value,
    });
    batch.set(_messages(idea.id).doc(), {
      'kind': MessageKind.review.value,
      'rating': rating,
      'senderRole': 'society',
      'senderUid': member.uid,
      'senderName': member.name,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> setAppointment(
    Idea idea,
    EsocietyMember member, {
    required DateTime at,
    required String place,
    required String note,
  }) async {
    final summary = 'Appointment: ${kAppointmentFormat.format(at)}';
    final batch = _db.batch();
    batch.update(_ideas.doc(idea.id), {
      'appointmentAt': Timestamp.fromDate(at),
      'appointmentPlace': place,
      'appointmentNote': note,
      'appointmentState': AppointmentState.proposed.value,
      'lastMessagePreview': _preview(summary),
      'lastMessageBy': 'society',
      'lastActivityAt': FieldValue.serverTimestamp(),
      'unreadForStudent': true,
    });
    batch.set(_messages(idea.id).doc(), {
      'kind': MessageKind.appointment.value,
      'appointmentAt': Timestamp.fromDate(at),
      'appointmentPlace': place,
      'senderRole': 'society',
      'senderUid': member.uid,
      'senderName': member.name,
      'text': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> cancelAppointment(Idea idea, EsocietyMember member) async {
    const text = 'The appointment was cancelled.';
    final batch = _db.batch();
    batch.update(_ideas.doc(idea.id), {
      'appointmentState': AppointmentState.cancelled.value,
      'lastMessagePreview': text,
      'lastMessageBy': 'society',
      'lastActivityAt': FieldValue.serverTimestamp(),
      'unreadForStudent': true,
    });
    batch.set(_messages(idea.id).doc(), {
      'kind': MessageKind.appointmentReply.value,
      'appointmentReply': AppointmentState.cancelled.value,
      'senderRole': 'society',
      'senderUid': member.uid,
      'senderName': member.name,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ─── Collaborations ───────────────────────────────────────────────────────

  /// Approved / open student collaborations, newest first.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> collaborations() {
    return _db
        .collection('collaborations')
        .orderBy('info.createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.where((doc) {
            final info = doc.data()['info'];
            final status = info is Map
                ? (info['status'] ?? '').toString().toLowerCase()
                : '';
            return status == 'open' || status == 'approved';
          }).toList(),
        );
  }

  Stream<List<CollabReview>> collabReviews(String collabId) => _db
      .collection('collaborations')
      .doc(collabId)
      .collection('esociety_reviews')
      .snapshots()
      .map((snap) {
        final list = snap.docs.map(CollabReview.fromDoc).toList();
        list.sort(
          (a, b) => (b.updatedAt ?? DateTime.now()).compareTo(
            a.updatedAt ?? DateTime.now(),
          ),
        );
        return list;
      });

  Future<void> saveCollabReview(
    String collabId,
    EsocietyMember member, {
    required int rating,
    required String comment,
  }) {
    return _db
        .collection('collaborations')
        .doc(collabId)
        .collection('esociety_reviews')
        .doc(member.uid)
        .set({
          'reviewerName': member.name,
          'rating': rating,
          'comment': comment,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteCollabReview(String collabId, EsocietyMember member) {
    return _db
        .collection('collaborations')
        .doc(collabId)
        .collection('esociety_reviews')
        .doc(member.uid)
        .delete();
  }

  static int _byActivity(Idea a, Idea b) {
    final now = DateTime.now();
    return (b.lastActivityAt ?? b.createdAt ?? now).compareTo(
      a.lastActivityAt ?? a.createdAt ?? now,
    );
  }
}
