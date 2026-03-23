import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../common/colors.dart';
import '../models/donor_model.dart';
import '../services/donor_service.dart';
import 'add_edit_donor_screen.dart';
import 'donor_profile_screen.dart';

class DonorListScreen extends StatefulWidget {
  static const route = 'donor-list';
  const DonorListScreen({Key? key}) : super(key: key);

  @override
  State<DonorListScreen> createState() => DonorListScreenState();
}

class DonorListScreenState extends State<DonorListScreen> {
  static const _bloodTypes = [
    '', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  List<Donor> _donors = [];
  bool _isLoading = true;
  String _selectedBloodType = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadDonors();
  }

  Future<void> loadDonors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final donors = await DonorService.getDonors(
        bloodType:
        _selectedBloodType.isEmpty ? null : _selectedBloodType,
      );
      if (mounted) setState(() => _donors = donors);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Donor> get _filtered {
    if (_searchQuery.isEmpty) return _donors;
    final q = _searchQuery.toLowerCase();
    return _donors
        .where((d) =>
    d.name.toLowerCase().contains(q) ||
        d.city.toLowerCase().contains(q))
        .toList();
  }

  void _openProfile(Donor donor) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DonorProfileScreen(donorId: donor.id),
      ),
    );
    loadDonors();
  }

  // ✅ Check if this donor belongs to logged-in user
  bool _isMyProfile(Donor donor) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && donor.uid == user.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or city...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedBloodType,
                items: _bloodTypes
                    .map((bt) => DropdownMenuItem(
                  value: bt,
                  child: Text(bt.isEmpty ? 'All' : bt),
                ))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedBloodType = val ?? '');
                  loadDonors();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? const Center(child: Text('No donors found'))
              : RefreshIndicator(
            onRefresh: loadDonors,
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final donor = _filtered[i];
                final isMe = _isMyProfile(donor);
                return ListTile(
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                        MainColors.primary,
                        child: Text(
                          donor.bloodType,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: -2,
                        child: CircleAvatar(
                          radius: 5,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor:
                            donor.isAvailable
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(donor.name),
                      // ✅ "You" badge for logged-in user's profile
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2),
                          decoration: BoxDecoration(
                            color: MainColors.primary,
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight:
                                FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                      '${donor.city} · Age ${donor.age}'),
                  trailing:
                  const Icon(Icons.chevron_right),
                  onTap: () => _openProfile(donor),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}