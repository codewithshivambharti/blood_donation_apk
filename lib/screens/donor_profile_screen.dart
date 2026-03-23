import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../common/colors.dart';
import '../models/donor_model.dart';
import '../services/donor_service.dart';
import 'add_edit_donor_screen.dart';

class DonorProfileScreen extends StatefulWidget {
  static const route = 'donor-profile';
  final String donorId;

  const DonorProfileScreen({Key? key, required this.donorId})
      : super(key: key);

  @override
  State<DonorProfileScreen> createState() =>
      _DonorProfileScreenState();
}

class _DonorProfileScreenState
    extends State<DonorProfileScreen> {
  Donor? _donor;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  // ✅ Only logged-in user can edit their own profile
  bool get _isMyProfile {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && _donor?.uid == user.uid;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadDonor(widget.donorId);
  }

  Future<void> _loadDonor(String id) async {
    setState(() => _isLoading = true);
    try {
      final donor = await DonorService.getDonor(id);
      final history = await DonorService.getDonationHistory(id);
      if (mounted) {
        setState(() {
          _donor = donor;
          _history = history;
        });
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

  Future<void> _toggleAvailability() async {
    if (_donor == null || !_isMyProfile) return;
    try {
      await DonorService.toggleAvailability(_donor!);
      await _loadDonor(widget.donorId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _openEdit() async {
    if (_donor == null || !_isMyProfile) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditDonorScreen(donor: _donor)),
    );
    if (result == true) _loadDonor(widget.donorId);
  }

  Future<void> _addDonation() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null || _donor == null) return;
    try {
      await DonorService.addDonationRecord(_donor!.id, picked);
      if (mounted) {
        await _loadDonor(widget.donorId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation record added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_donor?.name ?? 'Donor Profile'),
        backgroundColor: MainColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // ✅ Edit only visible to profile owner
          if (_isMyProfile)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: _openEdit,
            ),
          if (_isMyProfile)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Donation',
              onPressed: _addDonation,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _donor == null
          ? const Center(child: Text('Donor not found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileCard(),
            const SizedBox(height: 24),
            const Text(
              'Donation History',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _historyList(),
          ],
        ),
      ),
    );
  }

  Widget _profileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: MainColors.primary,
                  child: Text(
                    _donor!.bloodType,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: _donor!.isAvailable
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _donor!.name,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),

            // ✅ "Your Profile" badge
            if (_isMyProfile) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: MainColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: MainColors.primary.withOpacity(0.4)),
                ),
                child: const Text(
                  'Your Profile',
                  style: TextStyle(
                    color: MainColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: MainColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MainColors.primary),
              ),
              child: Text(
                'Blood Group: ${_donor!.bloodType}',
                style: const TextStyle(
                  color: MainColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (_donor!.donatedUnits > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                  border:
                  Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop,
                        color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Total Donated: ${_donor!.donatedUnits} unit(s)',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // ✅ Availability toggle — only owner can change
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _donor!.isAvailable
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: _donor!.isAvailable
                      ? Colors.green
                      : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _donor!.isAvailable
                      ? 'Available to Donate'
                      : 'Not Available',
                  style: TextStyle(
                    color: _donor!.isAvailable
                        ? Colors.green
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isMyProfile) ...[
                  Switch(
                    value: _donor!.isAvailable,
                    onChanged: (_) => _toggleAvailability(),
                    activeColor: MainColors.primary,
                  ),
                ],
              ],
            ),

            const Divider(),
            _infoRow(Icons.location_city, _donor!.city),
            _infoRow(Icons.phone, '+91 ${_donor!.phone}'),
            _infoRow(Icons.cake, 'Age ${_donor!.age}'),
            _infoRow(
              Icons.calendar_today,
              _donor!.lastDonationDate != null
                  ? 'Last donated: ${_formatDate(_donor!.lastDonationDate!)}'
                  : 'No donations yet',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: MainColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );

  Widget _historyList() {
    if (_history.isEmpty) {
      return const Text(
        'No donation records yet.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, i) {
        final record = _history[i];
        final type = record['type'] ?? 'manual';
        final date =
            DateTime.tryParse(record['date'] ?? '') ??
                DateTime.now();
        final units = record['units'] as int?;
        final bloodType =
            record['bloodType'] as String? ?? '';

        if (type == 'bank_donation') {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red[100],
              child: const Icon(Icons.water_drop,
                  color: Colors.red, size: 18),
            ),
            title: Text(
              'Blood Bank Donation — $bloodType',
              style:
              const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(_formatDate(date)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border:
                Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                '${units ?? 1} unit(s)',
                style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            dense: true,
          );
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green[100],
            child: const Icon(Icons.favorite,
                color: Colors.green, size: 18),
          ),
          title: const Text(
            'Manual Donation',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(_formatDate(date)),
          dense: true,
        );
      },
    );
  }
}