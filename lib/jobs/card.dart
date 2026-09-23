import 'package:flutter/material.dart';
import 'model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_cached_image.dart';

class JobCard extends StatelessWidget {
  final Job job;

  const JobCard({super.key, required this.job});

  Future<void> openLink(BuildContext context) async {
    if (job.link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No apply link provided")),
      );
      return;
    }
    try {
      final String formattedLink = job.link.startsWith('http') ? job.link : 'https://${job.link}';
      final Uri url = Uri.parse(formattedLink);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open link: ${job.link}")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid link format: ${job.link}")),
        );
      }
    }
  }

  void _showImagePreview(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Job image preview',
      barrierColor: Colors.black.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 32,
                  maxHeight: MediaQuery.sizeOf(context).height - 80,
                ),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: AppCachedImage(
                    imageUrl: job.image,
                    fit: BoxFit.contain,
                    memCacheWidth: 1600,
                    memCacheHeight: 2000,
                    errorWidget: const Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close image preview',
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => openLink(context),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Stack(
          children: [

            /// 🌄 Image (Fast disk cache + skeleton loading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showImagePreview(context),
                  child: AppCachedImage(
                    imageUrl: job.image,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    memCacheHeight: 1000,
                    errorWidget: Container(
                      color: Colors.grey.shade800,
                      child: const Center(
                        child: Icon(
                          Icons.work_outline,
                          size: 44,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// 🌑 Gradient Overlay (Improved)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            /// 📄 Content
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// Title
                    Text(
                      job.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    /// Description
                    Text(
                      job.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    /// Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: isDark
                            ? ElevatedButton.styleFrom(
                                backgroundColor: theme.cardTheme.color,
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              )
                            : null,
                        onPressed: () => openLink(context),
                        child: const Text("Apply Now"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}