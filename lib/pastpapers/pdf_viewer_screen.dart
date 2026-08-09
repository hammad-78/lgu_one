import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool isLoading = true;
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() {
              isLoading = false; // hide loader
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url)); // 👈 dynamic URL
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}