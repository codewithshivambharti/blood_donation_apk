import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../common/hive_boxes.dart';
import '../utils/blood_types.dart';
import '../widgets/action_button.dart';

const kProfileDiameter = 120.0;

class EditProfileScreen extends StatefulWidget {
  static const route = 'edit-profile';
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _picker = ImagePicker();
  late User _oldUser;
  String? _bloodType;
  File? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    _nameController.text = user.displayName ?? '';
    _emailController.text = user.email ?? '';
    _oldUser = user;
    _bloodType = Hive.box(ConfigBox.key).get(
      ConfigBox.bloodType,
      defaultValue: BloodType.aPos.name,
    ) as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),
                _imageRow(),
                const SizedBox(height: 36),
                _nameField(),
                const SizedBox(height: 18),
                _emailField(),
                const SizedBox(height: 18),
                _bloodTypeSelector(),
                const SizedBox(height: 36),
                ActionButton(
                  text: 'Save',
                  callback: _save,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageRow() => InkWell(
    onTap: _getImage,
    borderRadius: BorderRadius.circular(90),
    child: Container(
      width: kProfileDiameter,
      height: kProfileDiameter,
      decoration: BoxDecoration(
        color: MainColors.accent,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (_image != null)
            Image.file(
              _image!,
              fit: BoxFit.cover,
              height: kProfileDiameter,
              width: kProfileDiameter,
            )
          else if (_oldUser.photoURL != null)
            CachedNetworkImage(
              imageUrl: _oldUser.photoURL!,
              height: kProfileDiameter,
              width: kProfileDiameter,
              fit: BoxFit.cover,
              placeholder: (_, __) => const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            )
          else
            SvgPicture.asset(IconAssets.donor),
          Container(
            height: 30,
            width: kProfileDiameter,
            color: MainColors.primary,
            child: const Icon(
              Icons.upload_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _nameField() => TextFormField(
    controller: _nameController,
    keyboardType: TextInputType.name,
    textCapitalization: TextCapitalization.words,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Name',
      prefixIcon: Icon(Icons.person_outline_rounded),
    ),
  );

  Widget _emailField() => TextFormField(
    controller: _emailController,
    keyboardType: TextInputType.emailAddress,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Email',
      prefixIcon: Icon(Icons.email_outlined),
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

  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? newProfileUrl;

      if (_image != null) {
        Fluttertoast.showToast(msg: 'Uploading image...');
        final ref = FirebaseStorage.instance
            .ref()
            .child('avatars/${user.uid}');
        await ref.putFile(_image!);
        newProfileUrl = await ref.getDownloadURL();
      }

      if (_nameController.text != _oldUser.displayName ||
          newProfileUrl != null) {
        await user.updateDisplayName(_nameController.text);
        await user.updatePhotoURL(newProfileUrl);
      }

      if (_emailController.text != _oldUser.email) {
        await user.updateEmail(_emailController.text);
      }

      final initialBloodType = Hive.box(ConfigBox.key).get(
        ConfigBox.bloodType,
        defaultValue: BloodType.aPos.name,
      ) as String?;

      if (_bloodType != null && _bloodType != initialBloodType) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'bloodType': _bloodType});
        Hive.box(ConfigBox.key).put(ConfigBox.bloodType, _bloodType);
      }

      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? 'A Firebase error occurred');
    } catch (_) {
      Fluttertoast.showToast(msg: 'Something went wrong. Please try again');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}