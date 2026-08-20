import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/admin/admin_collaboration.dart';
import 'package:lgu_one/admin/admin_events_screen.dart';
import 'package:lgu_one/admin/admin_jobs_screen.dart';
import 'package:lgu_one/admin/admin_lost_found.dart';
import 'package:lgu_one/admin/admin_news_screen.dart';
import 'package:lgu_one/home_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String? _name;
  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _name = data?['name'];
          _role = data?['role'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Admin Data Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: isDark ? Border.all(color: theme.colorScheme.primary.withOpacity(0.2)) : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String avatarChar = "A";
    if (_name != null && _name!.trim().isNotEmpty) {
      avatarChar = _name!.trim()[0].toUpperCase();
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: isDark ? Border.all(color: theme.colorScheme.primary.withOpacity(0.2)) : null,
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            avatarChar,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name ?? "Administrator",
                                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _role ?? "Staff",
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    "Management Console",
                    style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildActionButton(
                        context: context,
                        icon: Icons.search,
                        label: "Lost & Found",
                        onTap: () => _navigate(const AdminLostFound()),
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.groups_outlined,
                        label: "Collaborations",
                        onTap: () => _navigate(const AdminCollaboration()),
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.event_note,
                        label: "Events",
                        onTap: () => _navigate(const AdminEventsScreen()),
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.work_outline,
                        label: "Jobs",
                        onTap: () => _navigate(const AdminJobsScreen()),
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.newspaper,
                        label: "News Feed",
                        onTap: () => _navigate(const AdminNewsScreen()),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
