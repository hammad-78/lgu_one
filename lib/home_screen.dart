import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/about.dart';
import 'package:lgu_one/admin/admin_signin.dart';
import 'package:lgu_one/auth/on_verified.dart';
import 'package:lgu_one/collaboration/collaboration_screen.dart';
import 'package:lgu_one/dashboard_grid.dart';
import 'package:lgu_one/gpa/gpa_calculator_screen.dart';
import 'package:lgu_one/jobs/jobs_swiper.dart';
import 'package:lgu_one/news_section/news_carousel.dart';
import 'package:lgu_one/notification/notification_service.dart';
import 'package:lgu_one/recommendation_page.dart';
import 'package:lgu_one/societies/society_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _jobsKey = GlobalKey();


  NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    notificationService.initLocalNotification(context);
    notificationService.firebaseInit(context);
    notificationService.setupInteractMessage(context);
    notificationService.isTokenRefreshed();
    _initNotifications(); // ← replace direct calls with this
  }

  Future<void> _initNotifications() async {
    await notificationService.requestNotificationPermission(); // wait for permission
    await notificationService.getDeviceToken();               // then fetch + save token
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // 👈 adjust (15–30 looks best)
          ),
        ),

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              color: Theme.of(context).appBarTheme.iconTheme?.color,
            ),
            const SizedBox(width: 8),
            Text(
              'LGU Connect',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: Theme.of(context).appBarTheme.iconTheme?.color,
              size: 25,
            ),
            onPressed: () {},
          ),
          SizedBox(width: 15),
        ],
      ),

      drawer: _buildDrawer(),

      body: ListView(
        controller: _scrollController,
        children: [
          SizedBox(height: 5),
          //Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 25,
                  color: Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Latest News & Updates",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          NewsCarousel(),
          SizedBox(height: 10),
          DashboardGrid(),

          SizedBox(height: 10),

          // Upcoming Events
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {

                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0B3D2E) // same dark green card
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

                    child: Row(
                      children: [
                        // icon badge — echoes the gold/green accent instead of plain iconTheme color
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.12)
                                : const Color(0xFF4CAF50).withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            Icons.event,
                            size: 22,
                            color: isDark
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFF4CAF50),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Text(
                            "Upcoming Events",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),

                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black45,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Join Societies
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SocietiesScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0B3D2E) // same dark green card
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

                  child: Row(
                    children: [
                      // icon badge — echoes the gold/green accent instead of plain iconTheme color
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.12)
                              : const Color(0xFF4CAF50).withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          Icons.groups,
                          size: 22,
                          color: isDark
                              ? const Color(0xFFD4AF37)
                              : const Color(0xFF4CAF50),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          "Join LGU Societies",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black45,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
          //Collaboration
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return LguVerifiedTap(

                  onVerified: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CollaborationScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0B3D2E) // same dark green card
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

                    child: Row(
                      children: [
                        // icon badge — echoes the gold/green accent instead of plain iconTheme color
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.12)
                                : const Color(0xFF4CAF50).withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            Icons.diversity_3,
                            size: 22,
                            color: isDark
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFF4CAF50),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Text(
                            "Student Collaboration",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),

                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black45,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 10),

          Padding(
            key: _jobsKey,
            padding: const EdgeInsets.fromLTRB(20, 10, 0, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 25,
                  color: Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Jobs and Internship Opportunities",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Swipe hint
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.swipe, size: 14, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  "Swipe",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Swiper
          const JobsSwiper(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = theme.iconTheme.color; // already correctly tuned per mode — keep using this
    final highlight = isDark ? theme.colorScheme.secondary : const Color(0xFF4CAF50);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF0B3D2E) : Colors.white;

    return Drawer(
      // ✅ FIX: explicit background so it actually matches the app instead of
      // falling back to Flutter's default Material surface color
      backgroundColor: scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 🔝 HEADER
          Container(
            decoration: BoxDecoration(
              // ✅ FIX: card color instead of colorScheme.primary, which is
              // identical to scaffoldBackgroundColor in dark mode and was
              // invisible
              color: cardBg,
              border: Border(
                bottom: BorderSide(
                  color: highlight.withValues(alpha: isDark ? 0.3 : 0.25),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: highlight, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: highlight.withValues(alpha: 0.15),
                        child: const AnimatedAvatar(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "LGU-Connect",
                        style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 🏠 HOME
          ListTile(
            leading: Icon(Icons.home_outlined, color: iconColor),
            title: const Text("Home"),
            onTap: () => Navigator.pop(context),
          ),

          // 📰 ABOUT US
          ListTile(
            leading: Icon(Icons.article_outlined, color: iconColor),
            title: const Text("About Us"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => About()),
              );
            },
          ),

          // ⭐ RECOMMENDATIONS
          ListTile(
            leading: Icon(Icons.star_outline, color: iconColor),
            title: const Text("Recommendation"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecommendationsPage()),
              );
            },
          ),

          // 💼 JOBS AND INTERNSHIPS
          ListTile(
            leading: Icon(Icons.work_outline, color: iconColor),
            title: const Text("Career Opportunities"),
            onTap: () async {
              Navigator.pop(context);

              await Future.delayed(const Duration(milliseconds: 350));

              if (_jobsKey.currentContext != null) {
                Scrollable.ensureVisible(
                  _jobsKey.currentContext!,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                  alignment: 0.05,
                );
              }
            },
          ),

          // 🧮 GPA
          ListTile(
            leading: Icon(Icons.calculate_outlined, color: iconColor),
            title: const Text("GPA Calculator"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GpaCalculatorScreen()),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    highlight.withValues(alpha: isDark ? 0.6 : 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ⚙ SETTINGS
          ListTile(
            leading: Icon(Icons.settings_outlined, color: iconColor),
            title: const Text("Settings"),
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: highlight.withValues(alpha: 0.3)),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.info_outline, color: highlight),
                        const SizedBox(width: 8),
                        const Text("Settings"),
                      ],
                    ),
                    content: const Text(
                      "No additional settings are required at the moment.",
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),


        //  🚪 LOGOUT
          ListTile(
            leading: const Icon(Icons.login, color: Colors.green),
            title: const Text(
              "Admin Login",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AdminSignin(),));
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// Circular Avatar for Drawer

class AnimatedAvatar extends StatefulWidget {
  const AnimatedAvatar({super.key});

  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(Icons.school, size: 55, color: Colors.black),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
