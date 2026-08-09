import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'model.dart';

class SocietyCard extends StatelessWidget {
  final Society society;

  const SocietyCard({super.key, required this.society});

  Future<void> openWhatsApp(String phone, String message) async {
    final encodedMessage = Uri.encodeComponent(message);

    final Uri appUri =
    Uri.parse("whatsapp://send?phone=+92$phone&text=$encodedMessage");

    final Uri webUri =
    Uri.parse("https://wa.me/92$phone?text=$encodedMessage");

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // ✅ FIX: colorScheme.primary is identical to scaffoldBackgroundColor in
    // dark mode (both 0xFF021E16) — using it for text made the society name
    // invisible. highlight resolves correctly in both modes instead.
    final highlight = isDark ? theme.colorScheme.secondary : const Color(0xFF4CAF50);
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;

    return Card(
      // ✅ cardTheme already supplies color, elevation: 3, borderRadius: 16 —
      // no need to hand-roll a BoxDecoration + boxShadow that duplicates it
      // (and doesn't dim correctly in dark mode like the rest of your app does)
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🖼 IMAGE — with loading + error handling
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                society.imageUrl,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 60,
                    width: 60,
                    color: highlight.withValues(alpha: isDark ? 0.12 : 0.08),
                    child: Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: highlight,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 60,
                  width: 60,
                  color: highlight.withValues(alpha: isDark ? 0.12 : 0.08),
                  child: Icon(Icons.groups, color: highlight, size: 26),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // TEXT SECTION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    society.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: highlight, // ✅ fixed — was invisible in dark mode
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    society.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: subTextColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: highlight),
                      const SizedBox(width: 4),
                      Text(
                        "${society.memberCount}+ members",
                        style: TextStyle(
                          color: highlight,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // BUTTON — already correctly themed via elevatedButtonTheme, untouched
            ElevatedButton(
              onPressed: () {
                openWhatsApp(
                  society.presidentPhone,
                  "Hi, I want to join ${society.name}!",
                );
              },
              child: const Text("Join"),
            ),
          ],
        ),
      ),
    );
  }
}