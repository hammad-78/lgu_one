import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/about.dart';
import 'package:lgu_one/admin/admin_signin.dart';
import 'package:lgu_one/auth/on_verified.dart';
import 'package:lgu_one/collaboration/collaboration_screen.dart';
import 'package:lgu_one/events/upcoming_events_screen.dart';
import 'package:lgu_one/dashboard_grid.dart';
import 'package:lgu_one/gpa/gpa_calculator_screen.dart';
import 'package:lgu_one/jobs/jobs_swiper.dart';
import 'package:lgu_one/news_section/news_carousel.dart';
import 'package:lgu_one/notification/notification_service.dart';
import 'package:lgu_one/notification/notification_screen.dart';
import 'package:lgu_one/recommendation_page.dart';
import 'package:lgu_one/societies/society_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _jobsKey = GlobalKey();
  Set<String> _seenIds = {};

  NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    notificationService.initLocalNotification(context);
    notificationService.firebaseInit(context);
    notificationService.setupInteractMessage(context);
    notificationService.isTokenRefreshed();
    _initNotifications();
    _loadSeenIds();
  }

  Future<void> _loadSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _seenIds = prefs.getStringList('seen_notification_ids')?.toSet() ?? {};
    });
  }

  Future<void> _initNotifications() async {
    await notificationService.requestNotificationPermission();
    await notificationService.getDeviceToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs
                    .where((doc) => !_seenIds.contains(doc.id))
                    .length;
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: Theme.of(context).appBarTheme.iconTheme?.color,
                      size: 25,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                      _loadSeenIds(); // Refresh seen IDs when returning
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 15),
        ],
      ),
      drawer: _buildDrawer(),
      body: ListView(
        controller: _scrollController,
        children: [
          const SizedBox(height: 5),
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
          const NewsCarousel(),
          const SizedBox(height: 10),
          const DashboardGrid(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final now = DateTime.now();
                final startOfToday = DateTime(now.year, now.month, now.day);

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events')
                      .where('eventDate',
                          isGreaterThanOrEqualTo:
                              Timestamp.fromDate(startOfToday))
                      .orderBy('eventDate', descending: false)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String eventSubtitle = "No upcoming events right now";
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final data = snapshot.data!.docs.first.data()
                          as Map<String, dynamic>;
                      final title = data['title'] ?? 'Upcoming Event';
                      if (data['eventDate'] is Timestamp) {
                        final eventDate =
                            (data['eventDate'] as Timestamp).toDate();
                        final diff = DateTime(
                                eventDate.year, eventDate.month, eventDate.day)
                            .difference(startOfToday)
                            .inDays;
                        String countdown;
                        if (diff == 0) {
                          countdown = "Today";
                        } else if (diff == 1) {
                          countdown = "Tomorrow";
                        } else {
                          countdown = "in $diff days";
                        }
                        eventSubtitle = "$title — $countdown";
                      } else {
                        eventSubtitle = title;
                      }
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UpcomingEventsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0B3D2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFFD4AF37)
                                    .withValues(alpha: 0.3)
                                : const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.25),
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFFD4AF37)
                                        .withValues(alpha: 0.12)
                                    : const Color(0xFF4CAF50)
                                        .withValues(alpha: 0.12),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Upcoming Events",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    eventSubtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFFD4AF37)
                                          : const Color(0xFF4CAF50),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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
                );
              },
            ),
          ),
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
                      MaterialPageRoute(
                          builder: (_) => const SocietiesScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B3D2E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                            : const Color(0xFF4CAF50).withValues(alpha: 0.25),
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
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return LguVerifiedTap(
                  onVerified: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CollaborationScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B3D2E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                            : const Color(0xFF4CAF50).withValues(alpha: 0.25),
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
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          const SizedBox(height: 10),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.swipe,
                    size: 14,
                    color: Theme.of(context)
                        .iconTheme
                        .color
                        ?.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  "Swipe",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
          const JobsSwiper(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = theme.iconTheme.color;
    final highlight =
        isDark ? theme.colorScheme.secondary : const Color(0xFF4CAF50);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF0B3D2E) : Colors.white;

    return Drawer(
      backgroundColor: scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
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
                        style:
                            theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.home_outlined, color: iconColor),
            title: const Text("Home"),
            onTap: () => Navigator.pop(context),
          ),
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
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: iconColor),
            title: const Text("Clear Login Cache"),
            onTap: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('lgu_remember_me');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Login cache cleared successfully."),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.login, color: Colors.green),
            title: const Text(
              "Admin Login",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminSignin(),
                  ));
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

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
      child: const Icon(Icons.school, size: 55, color: Colors.black),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
