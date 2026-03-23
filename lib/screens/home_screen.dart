import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../screens/add_blood_request_screen.dart';
import '../screens/add_edit_donor_screen.dart';
import '../screens/blood_bank_screen.dart';
import '../screens/blood_request_history_screen.dart';
import '../screens/donor_list_screen.dart';
import '../services/blood_stock_service.dart';
import '../widgets/all_blood_requests.dart';
import '../widgets/custom_drawer.dart';

class HomeScreen extends StatefulWidget {
  static const route = 'home';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<DonorListScreenState> _donorListKey = GlobalKey();

  // ✅ Order: Dashboard=0, Request=1, Donors=2, Blood Bank=3, History=4
  String _title() {
    switch (_currentIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Request Blood';
      case 2: return 'Donors';
      case 3: return 'Blood Bank';
      case 4: return 'History';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _currentIndex == 0 ? const CustomDrawer() : null,
      appBar: AppBar(
        title: Text(_title()),
        backgroundColor: MainColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 0 — Dashboard
          Offstage(
            offstage: _currentIndex != 0,
            child: const _DashboardTab(),
          ),
          // 1 — Request Blood
          Offstage(
            offstage: _currentIndex != 1,
            child: const AddBloodRequestScreen(embeddedMode: true),
          ),
          // 2 — Donors
          Offstage(
            offstage: _currentIndex != 2,
            child: DonorListScreen(key: _donorListKey),
          ),
          // 3 — Blood Bank
          Offstage(
            offstage: _currentIndex != 3,
            child: const BloodBankScreen(),
          ),
          // 4 — History
          Offstage(
            offstage: _currentIndex != 4,
            child: const BloodRequestHistoryScreen(),
          ),
        ],
      ),
      // ✅ FAB only on Donors tab (index 2)
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton(
        backgroundColor: MainColors.primary,
        tooltip: 'Add Donor',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditDonorScreen(),
            ),
          );
          if (result == true) {
            _donorListKey.currentState?.loadDonors();
          }
        },
        child: const Icon(Icons.person_add,
            color: Colors.white),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: MainColors.primary,
        unselectedItemColor: Colors.grey,
        unselectedLabelStyle:
        const TextStyle(color: Colors.grey),
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          // 0
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          // 1
          BottomNavigationBarItem(
            icon: Icon(Icons.bloodtype_outlined),
            activeIcon: Icon(Icons.bloodtype),
            label: 'Request',
          ),
          // 2
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Donors',
          ),
          // 3
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop_outlined),
            activeIcon: Icon(Icons.water_drop),
            label: 'Blood Bank',
          ),
          // 4
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  int _totalRequests = 0;
  int _availableDonors = 0;
  List<String> _lowStockTypes = [];
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('blood_requests')
            .where('isFulfilled', isEqualTo: false)
            .count()
            .get(),
        FirebaseFirestore.instance
            .collection('donors')
            .where('isAvailable', isEqualTo: true)
            .count()
            .get(),
      ]);
      final lowStock = await BloodStockService.getLowStockTypes();
      if (mounted) {
        setState(() {
          _totalRequests = results[0].count ?? 0;
          _availableDonors = results[1].count ?? 0;
          _lowStockTypes = lowStock;
        });
      }
    } catch (e) {
      try {
        final results = await Future.wait([
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('isFulfilled', isEqualTo: false)
              .get(),
          FirebaseFirestore.instance
              .collection('donors')
              .where('isAvailable', isEqualTo: true)
              .get(),
        ]);
        final lowStock =
        await BloodStockService.getLowStockTypes();
        if (mounted) {
          setState(() {
            _totalRequests = results[0].docs.length;
            _availableDonors = results[1].docs.length;
            _lowStockTypes = lowStock;
          });
        }
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          IconAssets.bloodBagHand,
                          height: 80,
                          width: 80,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Donate Blood,\nSave Lives',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                color: MainColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bloodtype,
                        label: 'Active Requests',
                        value: _statsLoading
                            ? '—'
                            : '$_totalRequests',
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people,
                        label: 'Available Donors',
                        value: _statsLoading
                            ? '—'
                            : '$_availableDonors',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_lowStockTypes.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 12, 16, 0),
                  child: Card(
                    color: Colors.orange[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: Colors.orange.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Low stock: ${_lowStockTypes.join(', ')} — donors needed!',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(
                child: SizedBox(height: 16)),
            SliverAppBar(
              title: Text(
                'Current Requests',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: MainColors.primary),
              ),
              primary: false,
              pinned: true,
              backgroundColor:
              Theme.of(context).scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
            ),
            const AllBloodRequests(),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}