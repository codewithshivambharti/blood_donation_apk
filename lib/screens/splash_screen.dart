import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';

import '../common/assets.dart';
import '../common/hive_boxes.dart';
import '../common/styles.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'tutorial_screen.dart';

class SplashScreen extends StatefulWidget {
  static const route = '/';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final isFirstLaunch = Hive.box(ConfigBox.key)
        .get(ConfigBox.isFirstLaunch, defaultValue: true)
    as bool;

    if (isFirstLaunch) {
      Navigator.of(context)
          .pushReplacementNamed(TutorialScreen.route);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // ✅ Timeout — slow network shouldn't block splash
        await user.reload().timeout(
          const Duration(seconds: 3),
          onTimeout: () {},
        );

        final refreshedUser =
            FirebaseAuth.instance.currentUser;

        if (refreshedUser != null) {
          await _updateCachedData();
          if (mounted) {
            Navigator.of(context)
                .pushReplacementNamed(HomeScreen.route);
          }
          return;
        }
      } catch (e) {
        // ✅ Network error — use cached user if still exists
        if (FirebaseAuth.instance.currentUser != null) {
          if (mounted) {
            Navigator.of(context)
                .pushReplacementNamed(HomeScreen.route);
          }
          return;
        }
        // Token invalid — force login
        await FirebaseAuth.instance.signOut();
      }
    }

    if (mounted) {
      Navigator.of(context)
          .pushReplacementNamed(LoginScreen.route);
    }
  }

  Future<void> _updateCachedData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data();
      if (data == null) return;

      final configBox = Hive.box(ConfigBox.key);
      configBox.put(
          ConfigBox.bloodType, data['bloodType'] as String?);
      configBox.put(ConfigBox.isAdmin,
          (data['isAdmin'] as bool?) ?? false);
    } catch (e) {
      debugPrint('Failed to update cached data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(IconAssets.logo),
              const SizedBox(height: 28),
              Text(
                'Blood Donation',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontFamily: Fonts.logo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}