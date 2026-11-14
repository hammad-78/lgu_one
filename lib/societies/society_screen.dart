import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lgu_one/utils/web_layout.dart';
import 'society_card.dart';
import 'model.dart';

class SocietiesScreen extends StatelessWidget {
  const SocietiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("LGU Societies")),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('societies')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load societies: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final societies =
              snapshot.data?.docs.map(Society.fromDocument).toList() ??
              <Society>[];

          if (isWideWeb(context)) {
            return WebScrollPage(
              maxWidth: 1040,
              header: WebPageHeader(
                icon: Icon(Icons.groups, color: theme.colorScheme.primary),
                title: "Discover & Join Societies",
                subtitle:
                    "Join student communities, events & opportunities at LGU",
              ),
              child: societies.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No societies available yet.')),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 500,
                            mainAxisExtent: 124,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: societies.length,
                      itemBuilder: (context, i) => SocietyCard(
                        society: societies[i],
                        margin: EdgeInsets.zero,
                      ),
                    ),
            );
          }

          return ListView(
            children: [
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
              if (societies.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No societies available yet.')),
                )
              else
                ...societies.map((society) => SocietyCard(society: society)),
            ],
          );
        },
      ),
    );
  }
}
