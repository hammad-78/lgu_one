import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/auth/student_auth_service.dart';
import 'package:lgu_one/ventures/explore_tab.dart';
import 'package:lgu_one/ventures/my_ventures_tab.dart';

enum VenturesTab { explore, mine }

/// Ventures: student startup ideas and teams in one place. Explore is the
/// board of teams looking for people; My ventures holds the student's ideas
/// shared with the Entrepreneurship Society and the teams they posted.
class VenturesScreen extends StatelessWidget {
  final VenturesTab initialTab;
  const VenturesScreen({super.key, this.initialTab = VenturesTab.explore});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.index,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ventures'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Explore'),
              Tab(text: 'My ventures'),
            ],
          ),
        ),
        body: SafeArea(
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, _) {
              final student = StudentAuthService.instance.currentStudent;
              return TabBarView(
                // Tabs change only from the tab labels.
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const ExploreTab(),
                  MyVenturesTab(student: student),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
