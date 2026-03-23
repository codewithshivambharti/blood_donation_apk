import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../services/admin_service.dart';
import '../utils/tools.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';
import 'home_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = 'login';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  String? _emailError;
  String? _passError;
  bool _isLoading = false;
  bool _isAdminMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    final emailError =
    Validators.required(_emailController.text, 'Email');
    final passError =
    Validators.required(_passController.text, 'Password');
    setState(() {
      _emailError = emailError;
      _passError = passError;
    });
    return emailError == null && passError == null;
  }

  void _onAdminModeToggle(bool isAdmin) {
    setState(() {
      _isAdminMode = isAdmin;
      _emailError = null;
      _passError = null;
      _emailController.clear();
      _passController.clear();
    });
  }

  Future<void> _login() async {
    if (!_validateFields()) return;

    setState(() {
      _emailError = null;
      _passError = null;
      _isLoading = true;
    });

    try {
      // ✅ Direct Firebase login for both user and admin
      // No local validation — Firebase handles credentials
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text,
      );

      // ✅ After login — check if admin mode matches
      if (_isAdminMode && !AdminService.isCurrentUserAdmin) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. You are not an admin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          HomeScreen.route,
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _emailError = 'No user found for that email';
        } else if (e.code == 'wrong-password') {
          _passError = 'Wrong password provided';
        } else if (e.code == 'invalid-credential') {
          _emailError = 'Invalid email or password';
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message ?? 'Authentication failed'),
              ),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_isAdminMode) return;
    if (Tools.isNullOrEmpty(_emailController.text)) {
      setState(() => _emailError = '* Please specify your email');
      return;
    }

    setState(() {
      _emailError = null;
      _passError = null;
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Password reset email sent. Please check your inbox'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message ?? 'Authentication failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MainColors.primary,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(IconAssets.logo),
                          const SizedBox(height: 16),

                          // ── User / Admin toggle ─────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ModeTab(
                                  label: 'User',
                                  icon: Icons.person_outline,
                                  selected: !_isAdminMode,
                                  onTap: () =>
                                      _onAdminModeToggle(false),
                                ),
                                _ModeTab(
                                  label: 'Admin',
                                  icon: Icons
                                      .admin_panel_settings_outlined,
                                  selected: _isAdminMode,
                                  onTap: () =>
                                      _onAdminModeToggle(true),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Admin restricted badge ──────────────
                          if (_isAdminMode)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius:
                                BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.red.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.shield,
                                      color: Colors.red, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Admin Login — Restricted Access',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            child: Text(
                              _isAdminMode ? 'Admin Login' : 'Login',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: MainColors.primary),
                            ),
                          ),
                          const SizedBox(height: 8),

                          _emailField(),
                          const SizedBox(height: 18),
                          _passField(),
                          const SizedBox(height: 32),

                          ActionButton(
                            text: _isAdminMode
                                ? 'Login as Admin'
                                : 'Login',
                            callback: _login,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 16),

                          if (!_isAdminMode)
                            GestureDetector(
                              onTap: _resetPassword,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  'Reset Password',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                      color: MainColors.primary),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (!_isAdminMode)
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, RegistrationScreen.route),
                      child: RichText(
                        text: const TextSpan(
                          text: 'New user? ',
                          style: TextStyle(
                              color: Colors.white, fontSize: 16),
                          children: [
                            TextSpan(
                              text: 'Create Account',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emailField() => TextField(
    controller: _emailController,
    keyboardType: TextInputType.emailAddress,
    onTap: () => setState(() => _emailError = null),
    decoration: InputDecoration(
      border: const OutlineInputBorder(),
      labelText: _isAdminMode ? 'Admin Email' : 'Email',
      prefixIcon: const Icon(Icons.email_outlined),
      errorText: _emailError,
    ),
  );

  Widget _passField() => TextField(
    controller: _passController,
    obscureText: true,
    onTap: () => setState(() => _passError = null),
    decoration: InputDecoration(
      border: const OutlineInputBorder(),
      labelText: _isAdminMode ? 'Admin Password' : 'Password',
      prefixIcon: const Icon(Icons.lock_outline),
      errorText: _passError,
    ),
  );
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? MainColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[600],
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}