import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("About LGU Connect")),

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
                    isDark ? primary.withValues(alpha: 0.8) : secondary,
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
                  "LGU Connect is the official campus companion app for Lahore Garrison University, helping students stay connected through lost & found, societies, job opportunities, and collaboration — all in one place.",
            ),

            // 🎯 PURPOSE
            _card(
              context,
              icon: Icons.flag,
              title: "Purpose",
              text:
                  """
LGU Connect brings students, societies, and campus resources together in one place — making everyday campus life simpler and more connected.""",
            ),

            // 👨‍💻 DEVELOPERS
            _card(
              context,
              icon: Icons.code,
              title: "Developed By",
              text:
                  "Hammad Ali Khan - Student LGU"
                  ,
            ),

            // 📊 VERSION INFO
            _card(
              context,
              icon: Icons.system_update,
              title: "App Version",
              text: "Version 1.0.0",
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
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
