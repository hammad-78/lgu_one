import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/about.dart';
import 'package:lgu_one/admin/admin_signin.dart';
import 'package:lgu_one/auth/lgu_email_auth_dialog.dart';
import 'package:lgu_one/collaboration/collaboration_screen.dart';
import 'package:lgu_one/events/upcoming_events_screen.dart';
import 'package:lgu_one/dashboard_grid.dart';
import 'package:lgu_one/jobs/jobs_swiper.dart';
import 'package:lgu_one/news_section/news_carousel.dart';
import 'package:lgu_one/notification/notification_service.dart';
import 'package:lgu_one/notification/notification_screen.dart';
import 'package:lgu_one/recommendation_page.dart';
import 'package:lgu_one/societies/society_screen.dart';
import 'package:lgu_one/utils/whatsApp_support.dart';
import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _jobsKey = GlobalKey();
  Set<String> _seenIds = {};
  bool _showNotificationBanner = false;
  bool _notificationPermanentlyDenied = false;

  final NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
    _loadSeenIds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotificationPermissionStatus();
    }
  }

  Future<void> _loadSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _seenIds = prefs.getStringList('seen_notification_ids')?.toSet() ?? {};
    });
  }

  Future<void> _initializeNotifications() async {
    await notificationService.initLocalNotification(context);
    await notificationService.requestNotificationPermission();
    await _refreshNotificationPermissionStatus();
    await notificationService.getDeviceToken();
    if (!mounted) return;
    notificationService.firebaseInit(context);
    await notificationService.setupInteractMessage(context);
    notificationService.isTokenRefreshed();
  }

  Future<void> _enableNotifications() async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      await _refreshNotificationPermissionStatus();
      return;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      return;
    }

    // If the system dialog is suppressed, request() returns almost instantly
    // and permission is still "denied" -> send the user to settings.
    final stopwatch = Stopwatch()..start();
    final granted = await notificationService.requestNotificationPermission();
    stopwatch.stop();
    if (!mounted) return;

    await _refreshNotificationPermissionStatus();

    if (!granted && stopwatch.elapsedMilliseconds < 400) {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    }
}

  Future<void> _refreshNotificationPermissionStatus() async {
    final permissionStatus = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _notificationPermanentlyDenied =
          permissionStatus.isPermanentlyDenied || permissionStatus.isRestricted;
      _showNotificationBanner = !permissionStatus.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/lgu_connect_icon.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Text('LGU Connect', style: theme.appBarTheme.titleTextStyle),
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
                    icon: Image.asset(
                      'assets/images/bell_icon.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
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
                      right: 2,
                      top: 2,
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
      body: Scrollbar(
        controller: _scrollController,
        child: ListView(
          controller: _scrollController,
          children: [
            const SizedBox(height: 5),
            if (_showNotificationBanner) _buildNotificationBanner(theme),
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
              imageAsset: "assets/images/calender_icon.png",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpcomingEventsScreen()),
              ),
              isEvent: true,
            ),
            _buildQuickActionCard(
              context,
              title: "Join LGU Societies",
              icon: Icons.handshake,
              imageAsset: "assets/images/handshake_icon.png",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SocietiesScreen()),
              ),
            ),
            _buildQuickActionCard(
              context,
              title: "Student Collaboration",
              icon: Icons.diversity_3,
              imageAsset: "assets/images/group_icon.png",
              onTap: () async {
                if (!await showLguEmailAuthDialog(context) ||
                    !context.mounted) {
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CollaborationScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
            Padding(
              key: _jobsKey,
              padding: const EdgeInsets.fromLTRB(20, 10, 0, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.16)
                          : theme.colorScheme.primary.withValues(alpha: 0.12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/suitecase_icon.png',
                      width: 27,
                      height: 27,
                      fit: BoxFit.contain,
                    ),
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
                  Icon(
                    Icons.swipe,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
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
      ),
    );
  }

  Widget _buildNotificationBanner(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF5D4B12)
        : const Color(0xFFFFF3CD);
    final foregroundColor = isDark
        ? const Color(0xFFFFF3CD)
        : const Color(0xFF5D4300);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none, size: 18, color: foregroundColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enable notifications to stay updated',
              style: theme.textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _enableNotifications,
            style: TextButton.styleFrom(
              foregroundColor: foregroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _notificationPermanentlyDenied ? 'Open Settings' : 'Enable',
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showNotificationBanner = false),
            icon: Icon(Icons.close, size: 18, color: foregroundColor),
            tooltip: 'Dismiss',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? imageAsset,
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
              color: theme.colorScheme.primary.withValues(
                alpha: isDark ? 0.3 : 0.25,
              ),
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
                child: imageAsset == null
                    ? Icon(icon, size: 22, color: theme.colorScheme.primary)
                    : Image.asset(
                        imageAsset,
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: isEvent
                    ? _buildEventSubtitle(context, title)
                    : Text(
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
          .where(
            'eventDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
          )
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
            final diff = DateTime(
              eventDate.year,
              eventDate.month,
              eventDate.day,
            ).difference(startOfToday).inDays;
            String countdown;
            if (diff == 0)
            {
              countdown = "Today";
            }
            else if (diff == 1)
             {
              countdown = "Tomorrow";
             }
            else {
              countdown = "in $diff days";
            }
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

  Widget _drawerIcon(String assetPath) {
    return SizedBox.square(
      dimension: 30,
      child: Image.asset(
        assetPath,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _buildDrawer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highlight = theme.colorScheme.primary;

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
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          "assets/images/lgu_connect_icon.png",
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "LGU-Connect",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: _drawerIcon("assets/images/home_icon.png"),
            title: const Text("Home"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: _drawerIcon("assets/images/abouUs_icon.png"),
            title: const Text("About Us"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const About()),
              );
            },
          ),
          ListTile(
            leading: _drawerIcon("assets/images/recommendation_icon.png"),
            title: const Text("Recommendations"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecommendationsPage(),
                ),
              );
            },
          ),
          ListTile(
           leading: _drawerIcon("assets/images/message_icon.png"),
            title: const Text("Contact us"),
            onTap: () => contactUsOnWhatsApp(context),
          ),
          ListTile(
            leading: _drawerIcon("assets/images/cache_icon.png"),
            title: const Text("Clear Cache"),
            onTap: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await clearRememberedLguStudentEmail();
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
            leading: _drawerIcon("assets/images/group_icon.png"),
            title: const Text("Admin Signin"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminSignin()),
              );
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
      child: Icon(
        Icons.school,
        size: 55,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}