import 'package:cloud_firestore/cloud_firestore.dart';

/// A team post on the collaboration board (`collaborations/{id}`).
///
/// Fields live under `info`. A few very old posts were stored flat, so both
/// shapes are read.
class CollabPost {
  final String id;
  final Map<String, dynamic> info;
  final String title;
  final String description;
  final String category;
  final int requiredMembers;
  final int existingMembers;
  final List<String> roles;
  final String status;
  final String whatsapp;
  final String? ownerUid;
  final String ownerName;
  final DateTime? createdAt;

  const CollabPost({
    required this.id,
    required this.info,
    required this.title,
    required this.description,
    required this.category,
    required this.requiredMembers,
    required this.existingMembers,
    required this.roles,
    required this.status,
    required this.whatsapp,
    required this.ownerUid,
    required this.ownerName,
    required this.createdAt,
  });

  factory CollabPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final raw = data['info'];
    final info = raw is Map
        ? Map<String, dynamic>.from(raw)
        : Map<String, dynamic>.from(data);
    int toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    String? optional(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    final created = info['createdAt'];
    return CollabPost(
      id: doc.id,
      info: info,
      title: (info['title'] ?? '').toString(),
      description: (info['description'] ?? '').toString(),
      category: (info['category'] ?? '').toString(),
      requiredMembers: toInt(info['requiredMembers']),
      existingMembers: toInt(info['existingMembers']),
      roles: info['requiredPosts'] is List
          ? (info['requiredPosts'] as List)
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : const [],
      status: (info['status'] ?? '').toString().toLowerCase(),
      whatsapp: (info['whatsappNumber'] ?? '').toString(),
      ownerUid: optional(info['ownerUid']),
      ownerName: (info['ownerName'] ?? '').toString(),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  /// Approved and on the board.
  bool get isOpen => status == 'open' || status == 'approved';

  bool get isPending => status == 'pending';

  bool get isRejected => status == 'rejected';

  /// How the owner sees where their post stands.
  String get statusLabel => isOpen
      ? 'On the board'
      : isPending
      ? 'Waiting for approval'
      : isRejected
      ? 'Not approved'
      : status.isEmpty
      ? 'Unknown'
      : '${status[0].toUpperCase()}${status.substring(1)}';

  /// "2/5 members", or just the current count when no target was set.
  String get membersLine => requiredMembers > 0
      ? '$existingMembers/$requiredMembers members'
      : '$existingMembers ${existingMembers == 1 ? 'member' : 'members'}';

  /// Words a search box matches against.
  String get searchText =>
      '$title $description $category ${roles.join(' ')}'.toLowerCase();
}

/// Reads for the board.
class CollabBoard {
  CollabBoard._();

  static CollectionReference<Map<String, dynamic>> get _posts =>
      FirebaseFirestore.instance.collection('collaborations');

  /// Approved posts, newest first.
  static Stream<List<CollabPost>> openPosts() => _posts
      .orderBy('info.createdAt', descending: true)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map(CollabPost.fromDoc).where((p) => p.isOpen).toList(),
      );

  /// One post, live. Null once it is deleted.
  static Stream<CollabPost?> post(String id) => _posts
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? CollabPost.fromDoc(doc) : null);

  /// Posts the student owns, in any state, newest first.
  static Stream<List<CollabPost>> postsBy(String uid) =>
      _posts.where('info.ownerUid', isEqualTo: uid).snapshots().map((snap) {
        final list = snap.docs.map(CollabPost.fromDoc).toList();
        final epoch = DateTime.fromMillisecondsSinceEpoch(0);
        list.sort(
          (a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch),
        );
        return list;
      });
}
