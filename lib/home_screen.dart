import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/about.dart';
import 'package:lgu_one/admin/admin_signin.dart';
import 'package:lgu_one/auth/signIn.dart';
import 'package:lgu_one/collaboration/collaboration_screen.dart';
import 'package:lgu_one/events/upcoming_events_screen.dart';
import 'package:lgu_one/dashboard_grid.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            const Icon(Icons.school),
            const SizedBox(width: 8),
            Text(
              'LGU Connect',
              style: theme.appBarTheme.titleTextStyle,
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
                    icon: const Icon(
                      Icons.notifications_none,
                      size: 25,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                      _loadSeenIds();
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
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Latest News & Updates",
                    style: theme.textTheme.headlineMedium?.copyWith(
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
          
          // Quick Action Cards
          _buildQuickActionCard(
            context,
            title: "Upcoming Events",
            icon: Icons.event,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpcomingEventsScreen())),
            isEvent: true,
          ),
          _buildQuickActionCard(
            context,
            title: "Join LGU Societies",
            icon: Icons.groups,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SocietiesScreen())),
          ),
          _buildQuickActionCard(
            context,
            title: "Student Collaboration",
            icon: Icons.diversity_3,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollaborationScreen())),
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
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Jobs and Internship Opportunities",
                    style: theme.textTheme.headlineMedium?.copyWith(
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  "Swipe",
                  style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

  Widget _buildQuickActionCard(BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isEvent = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: isEvent ? _buildEventSubtitle(context, title) : Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventSubtitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .orderBy('eventDate', descending: false)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        String eventSubtitle = "No upcoming events right now";
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final eventTitle = data['title'] ?? 'Upcoming Event';
          if (data['eventDate'] is Timestamp) {
            final eventDate = (data['eventDate'] as Timestamp).toDate();
            final diff = DateTime(eventDate.year, eventDate.month, eventDate.day)
                .difference(startOfToday)
                .inDays;
            String countdown;
            if (diff == 0) countdown = "Today";
            else if (diff == 1) countdown = "Tomorrow";
            else countdown = "in $diff days";
            eventSubtitle = "$eventTitle — $countdown";
          } else {
            eventSubtitle = eventTitle;
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              eventSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = theme.iconTheme.color;
    final highlight = theme.colorScheme.primary;

    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
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
                        child: Image.asset("assets/images/lgu_connect_icon.png"),
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
                MaterialPageRoute(builder: (context) => const About()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.star_outline, color: iconColor),
            title: const Text("Recommendations"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecommendationsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: iconColor),
            title: const Text("Clear Cache History"),
            onTap: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Cache history cleared successfully."),
                  ),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: highlight.withValues(alpha: 0.2)),
          ),
          ListTile(
            leading: Icon(Icons.admin_panel_settings_outlined, color: iconColor),
            title: const Text("Admin Signin"),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminSignin(),
                  ));
            },
          ),
          ListTile(
            leading: Icon(
              user != null ? Icons.logout : Icons.login,
              color: user != null ? Colors.red : Colors.green,
            ),
            title: Text(
              user != null ? "Logout" : "Student Signin",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () async {
              if (user != null) {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                    (route) => false,
                  );
                }
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              }
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
      child: Icon(Icons.school, size: 55, color: Theme.of(context).colorScheme.onSurface),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
