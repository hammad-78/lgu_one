import 'package:cloud_firestore/cloud_firestore.dart';

class Society {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int memberCount;
  final String presidentPhone;
  final String email;

  Society({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.memberCount,
    required this.presidentPhone,
    required this.email,
  });

  factory Society.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    return Society(
      id: document.id,
      name: (data['name'] ?? 'Untitled Society').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      presidentPhone: (data['presidentPhone'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
    );
  }
}
