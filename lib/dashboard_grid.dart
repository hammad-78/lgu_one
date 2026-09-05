import 'package:flutter/material.dart';
import 'package:lgu_one/Lost_Found/listing_screen.dart';
import 'package:lgu_one/auth/lgu_email_auth_dialog.dart';
import 'package:lgu_one/gpa/gpa_calculator_screen.dart';
import 'package:lgu_one/student_portal_screen.dart';

class DashboardGrid extends StatefulWidget {
  const DashboardGrid({super.key});

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<DashboardGrid> {
  @override
  Widget build(BuildContext context) {
    final items = [
      GridItem(
        title: "LGU Student Portal",
        icon: Icons.account_balance,
        imageAsset: "assets/images/lahore_garrison_university_logo.png",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentPortalScreen()),
          );
        },
      ),
      GridItem(
        title: "Lost and Found",
        icon: Icons.location_on_outlined,
        imageAsset: "assets/images/lostnfound.png",
        onTap: () async {
          if (!await showLguEmailAuthDialog(context) || !context.mounted) {
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListingsScreen()),
          );
        },
      ),
      GridItem(
        title: "GPA/CGPA Calculator",
        icon: Icons.calculate_outlined,
        imageAsset: "assets/images/calculator_icon.png",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GpaCalculatorScreen()),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => items[index],
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                        Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? imageAsset;
  final VoidCallback? onTap;

  const GridItem({
    super.key,
    required this.title,
    required this.icon,
    this.imageAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 160,
      width: 160,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.25),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  child: imageAsset == null
                      ? Icon(
                          icon,
                          size: 28,
                          color: theme.colorScheme.primary,
                        )
                      : Image.asset(
                          imageAsset!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.3,
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
