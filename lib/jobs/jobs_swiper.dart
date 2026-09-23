import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../utils/app_cached_image.dart';
import 'card.dart';
import 'model.dart';

class JobsSwiper extends StatefulWidget {
  const JobsSwiper({super.key});

  @override
  State<JobsSwiper> createState() => _JobsSwiperState();
}

class _JobsSwiperState extends State<JobsSwiper> {
  final CardSwiperController _swiperController = CardSwiperController();
  late final Stream<QuerySnapshot> _jobsStream =
      FirebaseFirestore.instance.collection('jobs').snapshots();
  int _currentIndex = 0;

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: _jobsStream,
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
          return _buildSkeletonJobSwiper(context);
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

        // Proactively pre-cache job images into disk & memory cache
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppImageCache.precache(context, jobsList.map((j) => j.image));
          }
        });

        return Transform.translate(
          offset: const Offset(0, -12),
          child: SizedBox(
            height: 500,
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: jobsList.length,
              initialIndex: _currentIndex.clamp(0, jobsList.length - 1),
              numberOfCardsDisplayed: jobsList.length < 2 ? jobsList.length : 2,
              isDisabled: jobsList.length <= 1,
              onSwipe: (previousIndex, currentIndex, direction) {
                if (currentIndex != null) {
                  _currentIndex = currentIndex;
                }
                return true;
              },
              cardBuilder: (context, index, h, v) {
                return JobCard(job: jobsList[index]);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonJobSwiper(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF0F382A) : Colors.grey.shade300;
    final highlightColor =
        isDark ? const Color(0xFF1E5240) : Colors.grey.shade100;

    return Transform.translate(
      offset: const Offset(0, -12),
      child: Container(
        height: 480,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Skeletonizer(
          enabled: true,
          containersColor: baseColor,
          effect: ShimmerEffect(
            baseColor: baseColor,
            highlightColor: highlightColor,
            duration: const Duration(milliseconds: 1200),
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Background image bone
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Bone(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Bottom content card
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black45 : Colors.white70,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(words: 3, fontSize: 18),
                        const SizedBox(height: 8),
                        Bone.text(words: 10, fontSize: 13),
                        const SizedBox(height: 6),
                        Bone.text(words: 6, fontSize: 13),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Bone.button(
                              width: 80,
                              height: 28,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            Bone.button(
                              width: 100,
                              height: 36,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
