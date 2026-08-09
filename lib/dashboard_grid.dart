import 'package:flutter/material.dart';
import 'package:lgu_one/Lost_Found/listing_screen.dart';
import 'package:lgu_one/auth/on_verified.dart';
import 'package:lgu_one/gpa/gpa_calculator_screen.dart';
import 'package:lgu_one/pastpapers/subject_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardGrid extends StatefulWidget {
  const DashboardGrid({super.key});

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<DashboardGrid> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GridItem(
                title: "LGU Student Portal",
                icon: Icons.account_balance,
                onTap: (){
                  openWebsite("https://student.lgu.edu.pk/");
                },),
              SizedBox(width: 14,),
              GridItem(
                title: "Lost and Found",
                icon: Icons.location_on_outlined,
                onTap: () => LguVerifiedTap.verify(
                  context,
                  onVerified: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ListingsScreen()),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 30,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GridItem(
                  title: "Past Papers",
                  icon: Icons.file_copy,
                onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SubjectScreen(),));
                },
                  ),
              SizedBox(width: 14,),
              GridItem(
                  title: "GPA/CGPA Calculator",
                  icon: Icons.calculate_outlined,
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => GpaCalculatorScreen(),));
                  },
              )
            ],
          ),
        ],
      ),
    );
  }
}



class GridItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const GridItem({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 160,
      width: 160,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0B3D2E) // dark green card
            : Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isDark
              ? const Color(0xFFD4AF37).withValues(alpha: 0.3) // gold tint
              : const Color(0xFF4CAF50).withValues(alpha: 0.25), // green tint
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
                // ICON CONTAINER (clean + modern)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.12)
                        : const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isDark
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF4CAF50),
                  ),
                ),

                const SizedBox(height: 12),

                // TITLE
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
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

Future<void> openWebsite(String link) async {
  final Uri url = Uri.parse(link);

  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw 'Could not launch $link';
  }
}