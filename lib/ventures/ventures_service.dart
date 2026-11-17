import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/ventures/collab_post.dart';
import 'package:lgu_one/ventures/team_fields.dart';

/// Writes that tie team posts (`collaborations`) to E-Society ideas.
class VenturesService {
  VenturesService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get posts =>
      _db.collection('collaborations');

  static DocumentReference<Map<String, dynamic>> _idea(String id) =>
      _db.collection('esociety_ideas').doc(id);

  /// The `info` map of a new team post, waiting for admin approval.
  static Map<String, dynamic> postInfo({
    required User student,
    required String ownerName,
    required String title,
    required String category,
    required String whatsapp,
    required TeamDraft draft,
    String? ideaId,
  }) => {
    'title': title,
    'description': draft.pitch.text.trim(),
    'category': category,
    'requiredPosts': List<String>.from(draft.roles),
    'existingMembers': draft.members,
    'requiredMembers': draft.target,
    'whatsappNumber': whatsapp,
    'status': 'pending',
    'ownerUid': student.uid,
    'ownerName': ownerName,
    'createdAt': FieldValue.serverTimestamp(),
    'ideaId': ?ideaId,
  };

  /// Posts a team on its own, or for an existing [idea] (linking both
  /// ways). Returns the new post's id.
  static Future<String> postTeam({
    required User student,
    required String ownerName,
    required String title,
    required String category,
    required String whatsapp,
    required TeamDraft draft,
    Idea? idea,
  }) async {
    final ref = posts.doc();
    final batch = _db.batch();
    batch.set(ref, {
      'info': postInfo(
        student: student,
        ownerName: ownerName,
        title: title,
        category: category,
        whatsapp: whatsapp,
        draft: draft,
        ideaId: idea?.id,
      ),
    });
    if (idea != null) batch.update(_idea(idea.id), {'collabId': ref.id});
    await batch.commit();
    return ref.id;
  }

  /// Owner stops looking for people (off the board), or asks to go back on
  /// it, which needs an admin's approval again.
  static Future<void> setRecruiting(CollabPost post, {required bool open}) =>
      posts.doc(post.id).update({'info.status': open ? 'pending' : 'closed'});

  /// Deletes a post and, for an idea's team, unlinks it from the idea.
  static Future<void> deletePost(String postId, {String? ideaId}) async {
    final batch = _db.batch();
    batch.delete(posts.doc(postId));
    if (ideaId != null) {
      batch.update(_idea(ideaId), {'collabId': FieldValue.delete()});
    }
    await batch.commit();
  }

  /// Keeps the public badge on an idea's team post in step with the
  /// society's stage. Only Shortlisted and Accepted show; anything else
  /// clears it. Best effort: the post may have been deleted.
  static Future<void> syncSocietyStage(Idea idea, IdeaStatus status) async {
    final id = idea.collabId;
    if (id == null) return;
    final show =
        status == IdeaStatus.shortlisted || status == IdeaStatus.accepted;
    try {
      await posts.doc(id).update({
        'info.societyStage': show ? status.value : FieldValue.delete(),
      });
    } catch (_) {
      // The stage change itself already went through.
    }
  }
}
