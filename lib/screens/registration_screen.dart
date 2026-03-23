import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../utils/blood_types.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';
import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  static const route = 'register';
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passError;
  String? _bloodType = 'A+';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // ✅ Fixed: compute errors before setState
  bool _validateFields() {
    final nameError =
    Validators.required(_nameController.text, 'Name');
    final emailError =
    Validators.required(_emailController.text, 'Email');
    final passError =
    Validators.required(_passController.text, 'Password');
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passError = passError;
    });
    return nameError == null && emailError == null && passError == null;
  }

  Future<void> _register() async {
    if (!_validateFields()) return;

    setState(() {
      _nameError = null;
      _emailError = null;
      _passError = null;
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text,
      );

      final user = credential.user!;
      await user.updateDisplayName(_nameController.text.trim());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {'bloodType': _bloodType, 'isAdmin': false},
        SetOptions(merge: true),
      );
      unawaited(user.sendEmailVerification());

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          HomeScreen.route,
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          _passError = 'The password provided is too weak';
        } else if (e.code == 'email-already-in-use') {
          _emailError = 'An account already exists for that email';
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text(e.message ?? 'Authentication failed')),
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
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(IconAssets.logo),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Register',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: MainColors.primary),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _nameField(),
                      const SizedBox(height: 18),
                      _emailField(),
                      const SizedBox(height: 18),
                      _passField(),
                      const SizedBox(height: 18),
                      _bloodTypeSelector(),
                      const SizedBox(height: 32),
                      ActionButton(
                        text: 'Register',
                        callback: _register,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameField() => TextField(
    controller: _nameController,
    keyboardType: TextInputType.name,
    textCapitalization: TextCapitalization.words,
    onTap: () => setState(() => _nameError = null),
    decoration: InputDecoration(
      border: const OutlineInputBorder(),
      labelText: 'Name',
      prefixIcon: const Icon(Icons.person_outline_rounded),
      errorText: _nameError,
    ),
  );

  Widget _emailField() => TextField(
    controller: _emailController,
    keyboardType: TextInputType.emailAddress,
    onTap: () => setState(() => _emailError = null),
    decoration: InputDecoration(
      border: const OutlineInputBorder(),
      labelText: 'Email',
      prefixIcon: const Icon(Icons.email_outlined),
      errorText: _emailError,
    ),
  );

  Widget _passField() => TextField(
    controller: _passController,
    onTap: () => setState(() => _passError = null),
    obscureText: true,
    decoration: InputDecoration(
      border: const OutlineInputBorder(),
      labelText: 'Password',
      prefixIcon: const Icon(Icons.lock_outline),
      errorText: _passError,
    ),
  );

  Widget _bloodTypeSelector() => DropdownButtonFormField<String>(
    value: _bloodType,
    onChanged: (v) => setState(() => _bloodType = v),
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Blood Type',
      prefixIcon: Icon(Icons.bloodtype_outlined),
    ),
    items: BloodTypeUtils.bloodTypes
        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
        .toList(),
  );
}