import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> contactUsOnWhatsApp(BuildContext context) async {
	final whatsappUri = Uri.parse('https://wa.me/923714744050');

	try {
		final launched = await launchUrl(
			whatsappUri,
			mode: LaunchMode.externalApplication,
		);

		if (!launched && context.mounted) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Unable to open WhatsApp.')),
			);
		}
	} catch (e) {
		if (context.mounted) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Unable to open WhatsApp.')),
			);
		}
	}
}

Future<void> openWhatsApp(String phone, String message) async {
	final encodedMessage = Uri.encodeComponent(message);

	final appUri =
		Uri.parse('whatsapp://send?phone=+92$phone&text=$encodedMessage');
	final webUri = Uri.parse('https://wa.me/92$phone?text=$encodedMessage');

	try {
		if (await canLaunchUrl(appUri)) {
			await launchUrl(appUri, mode: LaunchMode.externalApplication);
		} else {
			await launchUrl(webUri, mode: LaunchMode.externalApplication);
		}
	} catch (_) {}
}
