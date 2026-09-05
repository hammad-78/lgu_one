import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lgu_one/home_screen.dart';

class SplashService {
  void isLogin(BuildContext context) {
    Timer(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }
}

