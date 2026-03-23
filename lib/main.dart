import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'common/colors.dart';
import 'common/hive_boxes.dart';
import 'common/styles.dart';
import 'screens/add_blood_request_screen.dart';
import 'screens/add_news_item.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/news_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/who_can_donate_screen.dart';
import 'services/admin_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ✅ Keep user logged in across browser/app restarts
    await FirebaseAuth.instance
        .setPersistence(Persistence.LOCAL);
  } catch (e) {
    // Already initialized
  }

  await Hive.initFlutter();
  await Hive.openBox(ConfigBox.key);

  await AdminService.ensureAdminExists();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blood Donation',
      theme: ThemeData(
        primarySwatch: MainColors.swatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: Fonts.text,
      ),
      initialRoute: SplashScreen.route,
      routes: {
        HomeScreen.route: (_) => const HomeScreen(),
        TutorialScreen.route: (_) => const TutorialScreen(),
        LoginScreen.route: (_) => const LoginScreen(),
        RegistrationScreen.route: (_) =>
        const RegistrationScreen(),
        SplashScreen.route: (_) => const SplashScreen(),
        ProfileScreen.route: (_) => const ProfileScreen(),
        WhoCanDonateScreen.route: (_) =>
        const WhoCanDonateScreen(),
        AddBloodRequestScreen.route: (_) =>
        const AddBloodRequestScreen(),
        NewsScreen.route: (_) => const NewsScreen(),
        AddNewsItem.route: (_) => const AddNewsItem(),
        EditProfileScreen.route: (_) =>
        const EditProfileScreen(),
      },
    );
  }
}