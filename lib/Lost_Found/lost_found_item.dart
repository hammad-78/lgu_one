import 'package:cloud_firestore/cloud_firestore.dart';

/// Categories shown in both the post form and the listings filter.
const List<String> lostFoundCategories = [
  'Electronics',
  'ID Card',
  'Bag',
  'Books',
  'Keys',
  'Documents',
  'Clothing',
  'Other',
];

class LostFoundItem {
  final String id;
  final String type; // 'lost' or 'found'
  final String category;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String location;
  final DateTime date;
  final String whatsappNumber; // E.164 format, e.g. +923001234567
  final String secretKeyHash; // SHA-256 hash only — never the plain code
  final String status; // 'pending', 'active', 'rejected', 'resolved'
  final DateTime createdAt;

  const LostFoundItem({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.location,
    required this.date,
    required this.whatsappNumber,
    required this.secretKeyHash,
    required this.status,
    required this.createdAt,
  });

  factory LostFoundItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LostFoundItem(
      id: doc.id,
      type: data['type'] as String? ?? 'lost',
      category: data['category'] as String? ?? 'Other',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? const []),
      location: data['location'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      whatsappNumber: data['whatsappNumber'] as String? ?? '',
      secretKeyHash: data['secretKeyHash'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
