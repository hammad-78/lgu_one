import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'card.dart';
import 'model.dart';

class JobsSwiper extends StatelessWidget {
  const JobsSwiper({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error.toString();
          final isPermission = err.contains('permission-denied') ||
              err.contains('PERMISSION_DENIED');
          return Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade400, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    isPermission
                        ? "Permission denied for 'jobs' collection"
                        : "Unable to load jobs",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B3D2E) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B3D2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off_outlined,
                      size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    "No career opportunities available right now",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final jobsList = docs.map((doc) => Job.fromDocument(doc)).toList();

        // Sort by createdAt descending in memory safely
        jobsList.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

        return Transform.translate(
          offset: const Offset(0, -12),
          child: SizedBox(
            height: 500,
            child: CardSwiper(
              cardsCount: jobsList.length,
              numberOfCardsDisplayed: jobsList.length < 2 ? jobsList.length : 2,
              isDisabled: jobsList.length <= 1,
              cardBuilder: (context, index, h, v) {
                return JobCard(job: jobsList[index]);
              },
            ),
          ),
        );
      },
    );
  }
}
