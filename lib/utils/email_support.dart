import 'package:url_launcher/url_launcher.dart';

Future<void> openSocietyEmail(String email, String societyName) async {
  final emailUri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {
      'subject': 'Joining $societyName',
      'body':
          'Refered by LGU-Connect: \n\n Hi, I would like to join $societyName. Please share the next steps.',
    },
  );

  try {
    await launchUrl(emailUri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}
