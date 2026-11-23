import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lgu_one/ventures/collab_post.dart';
import 'package:lgu_one/ventures/team_fields.dart';

/// Writes for student posts (`collaborations`) and the copy sent to the
/// Entrepreneurship Society (`esociety_ideas`).
class VenturesService {
  VenturesService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get posts =>
      _db.collection('collaborations');

  /// Posts the student's idea to the board (after admin approval) and, when
  /// [toSociety] is set, sends it to the E-Society portal too.
  static Future<void> submit({
    required User student,
    required Map<String, dynamic> profile,
    required String title,
    required String category,
    required String whatsapp,
    required TeamDraft draft,
    required bool toSociety,
  }) async {
    final profileName = (profile['name'] ?? '').toString().trim();
    final name = profileName.isNotEmpty
        ? profileName
        : (student.displayName ?? student.email ?? 'Student');
    final description = draft.pitch.text.trim();
    final roles = List<String>.from(draft.roles);

    final batch = _db.batch();
    batch.set(posts.doc(), {
      'info': {
        'title': title,
        'description': description,
        'category': category,
        'requiredPosts': roles,
        'existingMembers': draft.members,
        'requiredMembers': draft.target,
        'whatsappNumber': whatsapp,
        'status': 'pending',
        'ownerUid': student.uid,
        'ownerName': name,
        'createdAt': FieldValue.serverTimestamp(),
      },
    });
    if (toSociety) {
      batch.set(_db.collection('esociety_ideas').doc(), {
        'studentUid': student.uid,
        'studentName': name,
        'studentEmail': student.email,
        'studentPhoto': profile.containsKey('photoUrl')
            ? profile['photoUrl']
            : student.photoURL,
        'degree': (profile['degree'] ?? '').toString(),
        'semester': profile['semester'],
        'whatsapp': whatsapp,
        'title': title,
        'description': description,
        'category': category,
        'roles': roles,
        'teamSize': draft.members,
        'teamWanted': draft.target,
        'createdAt': FieldValue.serverTimestamp(),
        'meetingAt': null,
        'meetingPlace': '',
        'requestedAt': null,
        'requestNote': '',
        'deactivated': false,
      });
    }
    await batch.commit();
  }

  /// Owner stops looking for people (off the board), or asks to go back on
  /// it, which needs an admin's approval again.
  static Future<void> setRecruiting(CollabPost post, {required bool open}) =>
      posts.doc(post.id).update({'info.status': open ? 'pending' : 'closed'});

  static Future<void> deletePost(String postId) => posts.doc(postId).delete();
}
