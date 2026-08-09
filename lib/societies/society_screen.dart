import 'package:flutter/material.dart';
import 'data.dart';
import 'society_card.dart';

class SocietiesScreen extends StatelessWidget {
  const SocietiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("LGU Societies"),
      ),

      body: ListView(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Discover & Join Societies",
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  "Join student communities, events & opportunities at LGU",
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // LIST
          ...SocietyData.societies.map(
                (society) => SocietyCard(society: society),
          ),
        ],
      ),
    );
  }
}