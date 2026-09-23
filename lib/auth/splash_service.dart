import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/home_screen.dart';
import 'package:lgu_one/utils/app_cached_image.dart';

class SplashService {
  void isLogin(BuildContext context) {
    // Proactively warm up news & jobs image cache while splash plays
    _warmUpCache(context);

    Timer(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  void _warmUpCache(BuildContext context) {
    try {
      // Warm up top 5 news images
      FirebaseFirestore.instance
          .collection('news')
          .limit(5)
          .get()
          .then((snapshot) {
        if (!context.mounted) return;
        final urls = snapshot.docs
            .map((doc) => doc.data()['image']?.toString())
            .whereType<String>();
        AppImageCache.precache(context, urls);
      }).catchError((_) {});

      // Warm up top 5 job images
      FirebaseFirestore.instance
          .collection('jobs')
          .limit(5)
          .get()
          .then((snapshot) {
        if (!context.mounted) return;
        final urls = snapshot.docs
            .map((doc) => doc.data()['image']?.toString())
            .whereType<String>();
        AppImageCache.precache(context, urls);
      }).catchError((_) {});
    } catch (_) {}
  }
}


