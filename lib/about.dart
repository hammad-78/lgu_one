import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("About LGU Connect"),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // 🌿 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary,
                    isDark ? primary.withOpacity(0.8) : secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.school, size: 65, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "LGU Connect",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Empowering Students • Connecting Opportunities",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📘 ABOUT APP
            _card(
              context,
              icon: Icons.info_outline,
              title: "About the App",
              text:
              "LGU Connect is a modern student platform designed for university students "
                  "to access academic tools, career opportunities, campus news, societies, "
                  "and essential student services — all in one place.",
            ),

            // 🎯 PURPOSE
            _card(
              context,
              icon: Icons.flag,
              title: "Purpose",
              text:
              "Our goal is to simplify student life by providing digital access to learning, "
                  "career growth, and campus engagement through a unified mobile experience.",
            ),

            // 👨‍💻 DEVELOPERS
            _card(
              context,
              icon: Icons.code,
              title: "Developed By",
              text:
              "LGU Student Development Team\nDesigned & Built by passionate university students "
                  "to improve campus digital experience.",
            ),

            // 📊 VERSION INFO
            _card(
              context,
              icon: Icons.system_update,
              title: "App Version",
              text: "Version 1.0.0 (Beta Release)\nLast Updated: April 2026",
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _card(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String text,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}