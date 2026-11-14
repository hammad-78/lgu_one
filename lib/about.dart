import 'package:flutter/material.dart';
import 'package:lgu_one/utils/web_layout.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isWideWeb(context)) {
      return Scaffold(
        appBar: AppBar(title: const Text("About LGU Connect")),
        body: WebScrollPage(maxWidth: 1000, child: _buildWide(context)),
      );
    }

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
                  colors: isDark
                      ? [secondary, const Color(0xFF145A45)]
                      : [primary, secondary],
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
                  "Welcome to the unofficial campus companion app for Lahore Garrison University. We help students stay connected through societies, lost & found, and job opportunities.\n\nStudents can even tap into the collaboration tab to share ideas and find groups to work together.",
            ),

            // 👨‍💻 DEVELOPERS
            _card(
              context,
              icon: Icons.code,
              title: "Developed By",
              text: "Hammad Ali Khan - Student LGU",
            ),

            // 📊 VERSION INFO
            _card(
              context,
              icon: Icons.system_update,
              title: "App Version",
              text: "Alpha",
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          decoration: webHeroDecoration(context),
          child: Row(
            children: [
              Container(
                width: 84,
                height: 84,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/lgu_connect_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 28),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LGU Connect",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Empowering Students • Connecting Opportunities",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _card(
                context,
                icon: Icons.info_outline,
                title: "About the App",
                text: _aboutText,
                outerPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _card(
                    context,
                    icon: Icons.code,
                    title: "Developed By",
                    text: "Hammad Ali Khan - Student LGU",
                    outerPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),
                  _card(
                    context,
                    icon: Icons.system_update,
                    title: "App Version",
                    text: "Alpha",
                    outerPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Unofficial · Student Initiative",
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  static const _aboutText =
      "Welcome to the unofficial campus companion app for Lahore Garrison University. We help students stay connected through societies, lost & found, and job opportunities.\n\nStudents can even tap into the collaboration tab to share ideas and find groups to work together.";

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
    EdgeInsets outerPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: outerPadding,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: isDark ? Colors.white : theme.colorScheme.primary,
                  ),
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
              Text(text, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
