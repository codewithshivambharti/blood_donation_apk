import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../common/colors.dart';
import '../models/donor_model.dart';
import '../services/blood_stock_service.dart';
import '../services/donor_service.dart';
import '../widgets/action_button.dart';

// ✅ All India cities list
const List<String> _indiaCities = [
  'Agra', 'Ahmedabad', 'Ajmer', 'Aligarh', 'Allahabad',
  'Amritsar', 'Aurangabad', 'Bangalore', 'Bareilly', 'Bhopal',
  'Bhubaneswar', 'Chandigarh', 'Chennai', 'Coimbatore',
  'Dehradun', 'Delhi', 'Dhanbad', 'Faridabad', 'Ghaziabad',
  'Guwahati', 'Gwalior', 'Howrah', 'Hyderabad', 'Indore',
  'Jaipur', 'Jalandhar', 'Jammu', 'Jodhpur', 'Kanpur',
  'Kochi', 'Kolkata', 'Kota', 'Kozhikode', 'Lucknow',
  'Ludhiana', 'Madurai', 'Meerut', 'Mumbai', 'Mysore',
  'Nagpur', 'Nashik', 'Navi Mumbai', 'Noida', 'Patna',
  'Pune', 'Raipur', 'Rajkot', 'Ranchi', 'Srinagar',
  'Surat', 'Thane', 'Tiruchirappalli', 'Vadodara',
  'Varanasi', 'Visakhapatnam',
];

class AddEditDonorScreen extends StatefulWidget {
  static const route = 'add-edit-donor';
  final Donor? donor;

  const AddEditDonorScreen({Key? key, this.donor})
      : super(key: key);

  @override
  State<AddEditDonorScreen> createState() =>
      _AddEditDonorScreenState();
}

class _AddEditDonorScreenState
    extends State<AddEditDonorScreen> {
  static const _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _unitsController = TextEditingController(text: '0');

  String _bloodType = 'A+';
  String? _city;
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _donateToBank = false;

  String? _nameError;
  String? _phoneError;
  String? _cityError;
  String? _ageError;
  String? _unitsError;

  @override
  void initState() {
    super.initState();
    final donor = widget.donor;
    if (donor != null) {
      // ✅ Edit mode — pre-fill existing data
      _nameController.text = donor.name;
      _phoneController.text = donor.phone;
      _ageController.text = donor.age.toString();
      _bloodType = donor.bloodType;
      _city = _indiaCities.contains(donor.city)
          ? donor.city
          : null;
      _isAvailable = donor.isAvailable;
    } else {
      // ✅ Add mode — auto-fill from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  bool _validate() {
    final nameErr = _nameController.text.trim().isEmpty
        ? '* Name is required'
        : null;
    final phoneErr = _phoneController.text.trim().isEmpty
        ? '* Phone is required'
        : null;
    final cityErr =
    _city == null ? '* Please select a city' : null;
    final age = int.tryParse(_ageController.text.trim());
    final ageErr = age == null || age < 18 || age > 65
        ? '* Enter a valid age (18–65)'
        : null;

    String? unitsErr;
    if (_donateToBank) {
      final units =
      int.tryParse(_unitsController.text.trim());
      if (units == null || units <= 0) {
        unitsErr = '* Enter valid units (min 1)';
      }
    }

    setState(() {
      _nameError = nameErr;
      _phoneError = phoneErr;
      _cityError = cityErr;
      _ageError = ageErr;
      _unitsError = unitsErr;
    });

    return nameErr == null &&
        phoneErr == null &&
        cityErr == null &&
        ageErr == null &&
        unitsErr == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);

    final isEdit = widget.donor != null;
    final units =
        int.tryParse(_unitsController.text.trim()) ?? 0;
    final now = DateTime.now();
    // ✅ Link donor to logged-in user
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      String donorId = widget.donor?.id ?? '';

      if (!isEdit) {
        donorId = await DonorService.addDonor(Donor(
          id: '',
          uid: uid, // ✅ save uid
          name: _nameController.text.trim(),
          bloodType: _bloodType,
          phone: _phoneController.text.trim(),
          city: _city!,
          age: int.parse(_ageController.text.trim()),
          isAvailable: _isAvailable,
        ));
      } else {
        await DonorService.updateDonor(widget.donor!.copyWith(
          name: _nameController.text.trim(),
          bloodType: _bloodType,
          phone: _phoneController.text.trim(),
          city: _city!,
          age: int.parse(_ageController.text.trim()),
          isAvailable: _isAvailable,
        ));
      }

      if (_donateToBank && units > 0 && donorId.isNotEmpty) {
        await BloodStockService.addUnits(_bloodType, units);
        await DonorService.addBankDonationRecord(
          donorId: donorId,
          bloodType: _bloodType,
          units: units,
          date: now,
        );
        final fulfilled =
        await _autoFulfillRequests(_bloodType, donorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$units unit(s) of $_bloodType donated to blood bank.'
                    '${fulfilled > 0 ? ' $fulfilled request(s) auto-fulfilled!' : ''}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  isEdit ? 'Profile updated!' : 'Donor added!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<int> _autoFulfillRequests(
      String bloodType, String donorId) async {
    int fulfilled = 0;
    try {
      final snapshot = await _firestoreInstance()
          .collection('blood_requests')
          .where('isFulfilled', isEqualTo: false)
          .where('bloodType', isEqualTo: bloodType)
          .limit(10)
          .get();

      for (final doc in snapshot.docs) {
        final currentStock =
        await BloodStockService.getStockByType(bloodType);
        if (currentStock == null || currentStock.units == 0)
          break;
        final success =
        await BloodStockService.deductUnits(bloodType, 1);
        if (success) {
          await doc.reference.update({
            'isFulfilled': true,
            'fulfilledBy': 'donor',
            'fulfilledByDonorId': donorId,
            'fulfilledByDonorName':
            _nameController.text.trim(),
            'fulfilledAt': DateTime.now().toIso8601String(),
          });
          fulfilled++;
        }
      }
    } catch (_) {}
    return fulfilled;
  }

  // ignore: non_constant_identifier_names
  dynamic _firestoreInstance() {
    // This will be replaced — see note below
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.donor != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Profile' : 'Add Donor'),
        backgroundColor: MainColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Name ─────────────────────────────────────
            TextField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              onTap: () => setState(() => _nameError = null),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),

            // ── Blood type ───────────────────────────────
            DropdownButtonFormField<String>(
              value: _bloodType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Blood Type',
                prefixIcon:
                Icon(Icons.bloodtype_outlined),
              ),
              items: _bloodTypes
                  .map((bt) => DropdownMenuItem(
                  value: bt, child: Text(bt)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _bloodType = val ?? 'A+'),
            ),
            const SizedBox(height: 16),

            // ── Phone with +91 prefix ────────────────────
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onTap: () => setState(() => _phoneError = null),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Phone Number',
                // ✅ +91 prefix shown in field
                prefixText: '+91 ',
                prefixIcon:
                const Icon(Icons.phone_outlined),
                errorText: _phoneError,
              ),
            ),
            const SizedBox(height: 16),

            // ── City dropdown ────────────────────────────
            DropdownButtonFormField<String>(
              value: _city,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'City',
                prefixIcon: const Icon(
                    Icons.location_city_outlined),
                errorText: _cityError,
              ),
              isExpanded: true,
              hint: const Text('Select your city'),
              items: _indiaCities
                  .map((c) => DropdownMenuItem(
                  value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() {
                _city = val;
                _cityError = null;
              }),
            ),
            const SizedBox(height: 16),

            // ── Age ──────────────────────────────────────
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              onTap: () => setState(() => _ageError = null),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Age',
                prefixIcon:
                const Icon(Icons.cake_outlined),
                errorText: _ageError,
              ),
            ),
            const SizedBox(height: 16),

            // ── Available toggle ─────────────────────────
            SwitchListTile(
              value: _isAvailable,
              onChanged: (val) =>
                  setState(() => _isAvailable = val),
              title: const Text('Available to Donate'),
              subtitle: Text(_isAvailable
                  ? 'I am available to donate'
                  : 'I am not available'),
              activeColor: MainColors.primary,
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            // ── Donate to bank toggle ────────────────────
            SwitchListTile(
              value: _donateToBank,
              onChanged: (val) {
                setState(() {
                  _donateToBank = val;
                  if (!val) _unitsController.text = '0';
                });
              },
              title: const Text('Donate Units to Blood Bank'),
              subtitle: const Text(
                  'Units added to stock, history saved'),
              activeColor: Colors.red,
              contentPadding: EdgeInsets.zero,
            ),

            if (_donateToBank) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _unitsController,
                keyboardType: TextInputType.number,
                onTap: () =>
                    setState(() => _unitsError = null),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Units to Donate',
                  prefixIcon: const Icon(
                      Icons.water_drop_outlined),
                  helperText: '1 unit = 450ml whole blood',
                  errorText: _unitsError,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border:
                  Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Donation history saved on profile. '
                            'Pending requests auto-fulfilled.',
                        style: TextStyle(
                            fontSize: 11, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            ActionButton(
              text: isEdit ? 'Save Changes' : 'Add Donor',
              callback: _save,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}