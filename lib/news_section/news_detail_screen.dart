import 'package:flutter/material.dart';
import 'news_model.dart';
import '../utils/app_cached_image.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsModel news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool _isImageExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final news = widget.news;

    return Scaffold(
      appBar: AppBar(
        title: const Text('News Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    _isImageExpanded
                        ? _ExpandedNewsImage(
                            imageUrl: news.image,
                            fallbackColor: colorScheme.primary,
                          )
                        : AspectRatio(
                            aspectRatio: 16 / 9,
                            child: _NewsImage(
                              imageUrl: news.image,
                              fit: BoxFit.cover,
                              fallbackColor: colorScheme.primary,
                            ),
                          ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Material(
                        color: colorScheme.surface.withValues(alpha: 0.9),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: _isImageExpanded
                              ? 'Collapse image'
                              : 'View full image',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            _isImageExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: colorScheme.onSurface,
                          ),
                          onPressed: () {
                            setState(() {
                              _isImageExpanded = !_isImageExpanded;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    news.type,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (news.date.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    news.date,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              news.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 26,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 18),
            Divider(color: colorScheme.onSurface.withValues(alpha: 0.12)),
            const SizedBox(height: 16),
            Text(
              news.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.65,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final Color color;

  const _ImageFallback({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 44,
        color: color.withValues(alpha: 0.65),
      ),
    );
  }
}

class _NewsImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Color fallbackColor;

  const _NewsImage({
    required this.imageUrl,
    required this.fit,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _ImageFallback(color: fallbackColor);
    }

    return AppCachedImage(
      imageUrl: imageUrl,
      width: double.infinity,
      fit: fit,
      memCacheWidth: 1080,
      memCacheHeight: 1080,
      errorWidget: _ImageFallback(color: fallbackColor),
    );
  }
}

class _ExpandedNewsImage extends StatelessWidget {
  final String imageUrl;
  final Color fallbackColor;

  const _ExpandedNewsImage({
    required this.imageUrl,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return _NewsImage(
      imageUrl: imageUrl,
      fit: BoxFit.fitWidth,
      fallbackColor: fallbackColor,
    );
  }
}