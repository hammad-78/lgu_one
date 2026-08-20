import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/admin/admin_home.dart';
import 'package:lgu_one/auth/signIn.dart';
import 'package:lgu_one/home_screen.dart';

class SplashService {
  void isLogin(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user != null) {
      FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get()
          .then((doc) {
        final data = doc.data();
        // Robust check: handles bool, string "true", or role "admin"
        final bool isAdmin = doc.exists &&
            (data?['isAdmin'] == true ||
             data?['isAdmin']?.toString().toLowerCase() == 'true' ||
             data?['role']?.toString().toLowerCase() == 'admin');

        if (isAdmin) {
          Timer(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHome()),
            );
          });
        } else {
          Timer(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          });
        }
      }).catchError((e) {
        // Fallback to student home on Firestore error
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    } else {
      Timer(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      });
    }
  }
}
