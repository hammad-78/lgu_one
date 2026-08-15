import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/admin/admin_jobs_screen.dart';
import 'package:lgu_one/admin/admin_lost_found.dart';
import 'package:lgu_one/admin/admin_news_screen.dart';
import 'package:lgu_one/home_screen.dart';

// TODO: update these imports to point to your actual screen files
// import 'package:lgu_one/lost_found_list_screen.dart';
// import 'package:lgu_one/collaboration_list_screen.dart';
// import 'package:lgu_one/events_list_screen.dart';
// import 'package:lgu_one/add_job_screen.dart';

class AdminHome extends StatefulWidget {

  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final user = FirebaseAuth.instance.currentUser;

  String? name;
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user!.uid)
          .get();

      debugPrint("Doc exists: ${doc.exists}");
      debugPrint("Doc data: ${doc.data()}");

      final data = doc.data();

      setState(() {
        name = data?['name'];
        role = data?['role'];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("FETCH ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Reusable action button for the admin dashboard grid.
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
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
              backgroundColor: Colors.green.withValues(alpha: 0.12),
              child: Icon(icon, color: Colors.green, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text("Admin Home Page"),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            InkWell(
              onTap: () async {
                await FirebaseAuth.instance.signOut();

                if (!mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              child: const Icon(Icons.logout),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green,
                  child: Text(
                    name?.substring(0, 1).toUpperCase() ?? "H",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Text(
                  name ?? "No Name",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role ?? "No Role",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                "Manage",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildActionButton(
                  icon: Icons.search,
                  label: "Lost & Found Listings",
                  onTap: () {
                    // TODO: replace with your actual screen
                    _navigate(const AdminLostFound());
                  },
                ),
                _buildActionButton(
                  icon: Icons.groups_outlined,
                  label: "Collaboration Listings",
                  onTap: () {
                    // TODO: replace with your actual screen
                    // _navigate(const CollaborationListScreen());
                  },
                ),
                _buildActionButton(
                  icon: Icons.event_outlined,
                  label: "Upcoming Events",
                  onTap: () {
                    // TODO: replace with your actual screen
                    // _navigate(const EventsListScreen());
                  },
                ),
                _buildActionButton(
                  icon: Icons.work_outline,
                  label: "Add Job",
                  onTap: () {
                    _navigate(const AdminJobsScreen());
                  },
                ),
                _buildActionButton(
                  icon: Icons.article_outlined,
                  label: "Add News",
                  onTap: () {
                    _navigate(const AdminNewsScreen());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}