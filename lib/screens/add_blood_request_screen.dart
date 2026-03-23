import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/medical_center.dart';
import '../services/blood_stock_service.dart';
import '../utils/blood_types.dart';
import '../utils/tools.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';
import '../widgets/medical_center_picker.dart';

class AddBloodRequestScreen extends StatefulWidget {
  static const route = 'add-request';
  final bool embeddedMode;

  const AddBloodRequestScreen({
    Key? key,
    this.embeddedMode = false,
  }) : super(key: key);

  @override
  _AddBloodRequestScreenState createState() =>
      _AddBloodRequestScreenState();
}

class _AddBloodRequestScreenState
    extends State<AddBloodRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _noteController = TextEditingController();
  final _unitsController =
  TextEditingController(text: '1'); // ✅ units field
  String? _bloodType = 'A+';
  MedicalCenter? _medicalCenter;
  DateTime? _requestDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _patientNameController.dispose();
    _contactNumberController.dispose();
    _noteController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Please login to submit a blood request')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bloodType = _bloodType!;
      final unitsRequired =
          int.tryParse(_unitsController.text.trim()) ?? 1;

      // ✅ Check blood bank stock
      final stock =
      await BloodStockService.getStockByType(bloodType);
      final availableUnits = stock?.units ?? 0;
      // ✅ Fulfill only if stock >= requested units
      final hasStock = availableUnits >= unitsRequired;

      await FirebaseFirestore.instance
          .collection('blood_requests')
          .add({
        'uid': user.uid,
        'submittedBy': user.displayName ?? 'Unknown User',
        'patientName': _patientNameController.text.trim(),
        'bloodType': bloodType,
        'unitsRequired': unitsRequired, // ✅ save units
        'contactNumber': _contactNumberController.text.trim(),
        'note': _noteController.text.trim(),
        'submittedAt': DateTime.now(),
        'requestDate': _requestDate,
        'isFulfilled': hasStock,
        'fulfilledBy': hasStock ? 'blood_bank_auto' : null,
        'fulfilledAt':
        hasStock ? DateTime.now().toIso8601String() : null,
        'medicalCenter': _medicalCenter!.toJson(),
        'status': hasStock ? 'fulfilled' : 'active',
      });

      // ✅ Deduct requested units from blood bank
      if (hasStock) {
        await BloodStockService.deductUnits(
            bloodType, unitsRequired);
      }

      _resetFields();

      if (mounted) {
        if (hasStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Request submitted & auto-fulfilled! '
                    '$unitsRequired unit(s) of $bloodType deducted from bank.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Request submitted. Only $availableUnits unit(s) '
                    'available, $unitsRequired needed. Donor required.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        if (!widget.embeddedMode) Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text('Authentication error: ${e.message}')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        String msg = 'Something went wrong. Please try again';
        if (e.code == 'permission-denied') {
          msg = 'You do not have permission to submit requests.';
        } else if (e.code == 'unavailable') {
          msg = 'Service temporarily unavailable.';
        } else if (e.code == 'network-request-failed') {
          msg = 'Network error. Check your connection.';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
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

  void _resetFields() {
    _patientNameController.clear();
    _contactNumberController.clear();
    _noteController.clear();
    _unitsController.text = '1';
    setState(() {
      _bloodType = 'A+';
      _requestDate = null;
      _medicalCenter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const spacer = SizedBox(height: 16);

    final form = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _patientNameField(),
            spacer,
            _contactNumberField(),
            spacer,
            _bloodTypeSelector(),
            spacer,
            _unitsField(), // ✅ units field
            spacer,
            _medicalCenterSelector(),
            spacer,
            _requestDatePicker(),
            spacer,
            _noteField(),
            const SizedBox(height: 24),
            ActionButton(
              callback: _submit,
              text: 'Submit',
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );

    if (widget.embeddedMode) return SafeArea(child: form);

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Blood Request')),
      body: SafeArea(child: form),
    );
  }

  // ✅ Units required field
  Widget _unitsField() => TextFormField(
    controller: _unitsController,
    keyboardType: TextInputType.number,
    validator: (v) {
      final units = int.tryParse(v ?? '');
      if (units == null || units < 1) {
        return '* Enter valid units (min 1)';
      }
      return null;
    },
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Units Required',
      helperText: '1 unit = 450ml whole blood',
      prefixIcon: Icon(Icons.water_drop_outlined),
    ),
  );

  Widget _patientNameField() => TextFormField(
    controller: _patientNameController,
    keyboardType: TextInputType.name,
    textCapitalization: TextCapitalization.words,
    validator: (v) =>
        Validators.required(v ?? '', 'Patient name'),
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Patient Name',
      prefixIcon: Icon(Icons.person),
    ),
  );

  Widget _contactNumberField() => TextFormField(
    controller: _contactNumberController,
    keyboardType: TextInputType.phone,
    validator: (v) =>
    Validators.required(v ?? '', 'Contact number') ??
        Validators.phone(v ?? ''),
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Contact number',
      prefixText: '+91 ',
      prefixIcon: Icon(Icons.phone),
    ),
  );

  Widget _noteField() => TextFormField(
    controller: _noteController,
    keyboardType: TextInputType.multiline,
    textCapitalization: TextCapitalization.sentences,
    minLines: 3,
    maxLines: 5,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Notes (Optional)',
      alignLabelWithHint: true,
      prefixIcon: Icon(Icons.note),
    ),
  );

  Widget _bloodTypeSelector() => DropdownButtonFormField<String>(
    value: _bloodType,
    onChanged: (v) => setState(() => _bloodType = v),
    validator: (v) =>
    v == null ? '* Please select a blood type' : null,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Blood Type',
      prefixIcon: Icon(Icons.bloodtype),
    ),
    items: BloodTypeUtils.bloodTypes
        .map((v) =>
        DropdownMenuItem(value: v, child: Text(v)))
        .toList(),
  );

  Widget _medicalCenterSelector() => GestureDetector(
    onTap: () async {
      final picked =
      await showModalBottomSheet<MedicalCenter>(
        context: context,
        builder: (_) => const MedicalCenterPicker(),
        isScrollControlled: true,
      );
      if (picked != null) {
        setState(() => _medicalCenter = picked);
      }
    },
    child: AbsorbPointer(
      child: TextFormField(
        key: ValueKey<String>(
            _medicalCenter?.name ?? 'none'),
        initialValue: _medicalCenter?.name,
        validator: (_) => _medicalCenter == null
            ? '* Please select a medical center'
            : null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Medical Center',
          prefixIcon: Icon(Icons.location_on),
        ),
      ),
    ),
  );

  Widget _requestDatePicker() => GestureDetector(
    onTap: () async {
      final today = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: today,
        firstDate: today,
        lastDate: today.add(const Duration(days: 365)),
      );
      if (picked != null) {
        setState(() => _requestDate = picked);
      }
    },
    child: AbsorbPointer(
      child: TextFormField(
        key: ValueKey<DateTime>(
            _requestDate ?? DateTime.now()),
        initialValue: _requestDate != null
            ? Tools.formatDate(_requestDate!)
            : null,
        validator: (_) => _requestDate == null
            ? '* Please select a date'
            : null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Request date',
          helperText:
          'The date on which you need the blood to be ready',
          prefixIcon: Icon(Icons.calendar_today),
        ),
      ),
    ),
  );
}