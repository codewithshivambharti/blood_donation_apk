import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';

import '../common/app_config.dart';
import '../common/assets.dart';
import '../common/colors.dart';
import '../common/hive_boxes.dart';
import '../screens/add_blood_request_screen.dart';
import '../screens/add_news_item.dart';
import '../screens/login_screen.dart';
import '../screens/news_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/who_can_donate_screen.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool _showAdmin = false;

  bool get _isAdmin =>
      Hive.box(ConfigBox.key).get(
        ConfigBox.isAdmin,
        defaultValue: false,
      ) as bool;

  Future<void> _onLogoutTapped() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YES'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginScreen.route,
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              accountName: Text(user?.displayName ?? 'Blood Donation'),
              accountEmail: Text(user?.email ?? AppConfig.email),
              currentAccountPicture: Hero(
                tag: 'profilePicHero',
                child: Container(
                  decoration: BoxDecoration(
                    color: MainColors.accent,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: user?.photoURL != null
                      ? CachedNetworkImage(
                    imageUrl: user!.photoURL!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white70,
                        ),
                      ),
                    ),
                  )
                      : SvgPicture.asset(IconAssets.donor),
                ),
              ),
              otherAccountsPictures: [
                if (_isAdmin)
                  InkWell(
                    onTap: () => setState(() => _showAdmin = !_showAdmin),
                    child: const Tooltip(
                      message: 'Admin Screens',
                      child: CircleAvatar(
                        child: Icon(Icons.admin_panel_settings),
                      ),
                    ),
                  ),
                InkWell(
                  onTap: _onLogoutTapped,
                  child: const Tooltip(
                    message: 'Logout',
                    child: CircleAvatar(child: Icon(Icons.logout)),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(children: _screens),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> get _screens => [
    const _DrawerTile(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      destination: ProfileScreen.route,
    ),
    const _DrawerTile(
      title: 'Request Blood',
      icon: Icons.bloodtype_outlined,
      destination: AddBloodRequestScreen.route,
    ),
    if (_showAdmin)
      const _DrawerTile(
        title: 'Add News',
        icon: Icons.add_circle_outline,
        destination: AddNewsItem.route,
      ),
    const _DrawerTile(
      title: 'News and Tips',
      icon: Icons.notifications_outlined,
      destination: NewsScreen.route,
    ),
    const _DrawerTile(
      title: 'Can I donate blood?',
      icon: Icons.help_outline,
      destination: WhoCanDonateScreen.route,
    ),
  ];
}

class _DrawerTile extends StatelessWidget {
  final String title;
  final String destination;
  final IconData icon;

  const _DrawerTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.destination,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      onTap: () {
        Navigator.pop(context);
        Navigator.of(context).pushNamed(destination);
      },
    );
  }
}