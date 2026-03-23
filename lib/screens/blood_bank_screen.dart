import 'package:flutter/material.dart';
import '../common/colors.dart';
import '../models/blood_stock_model.dart';
import '../services/admin_service.dart';
import '../services/blood_stock_service.dart';
import '../widgets/action_button.dart';

class BloodBankScreen extends StatefulWidget {
  static const route = 'blood-bank';
  const BloodBankScreen({Key? key}) : super(key: key);

  @override
  State<BloodBankScreen> createState() => _BloodBankScreenState();
}

class _BloodBankScreenState extends State<BloodBankScreen> {
  List<BloodStock> _stock = [];
  bool _isLoading = true;

  bool get _isAdmin => AdminService.isCurrentUserAdmin;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    setState(() => _isLoading = true);
    try {
      final stock = await BloodStockService.getStock();
      final allTypes = BloodStockService.bloodTypes;
      final result = allTypes.map((type) {
        final found =
        stock.where((s) => s.bloodType == type).toList();
        return found.isNotEmpty
            ? found.first
            : BloodStock(
          id: '',
          bloodType: type,
          units: 0,
          updatedAt: DateTime.now(),
        );
      }).toList();
      if (mounted) setState(() => _stock = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Admin: update stock dialog ────────────────────────────────
  void _showUpdateDialog(BloodStock stock) {
    final controller = TextEditingController();
    String action = 'add';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Update ${stock.bloodType} Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current units: ${stock.units}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'add',
                      groupValue: action,
                      title: const Text('Add'),
                      onChanged: (v) =>
                          setDialogState(() => action = v ?? 'add'),
                      activeColor: MainColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'deduct',
                      groupValue: action,
                      title: const Text('Deduct'),
                      onChanged: (v) =>
                          setDialogState(() => action = v ?? 'add'),
                      activeColor: MainColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Units',
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: MainColors.primary),
              onPressed: () async {
                final units =
                int.tryParse(controller.text.trim());
                if (units == null || units <= 0) return;
                Navigator.pop(ctx);
                try {
                  if (action == 'add') {
                    await BloodStockService.addUnits(
                        stock.bloodType, units);
                  } else {
                    final success =
                    await BloodStockService.deductUnits(
                        stock.bloodType, units);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text('Not enough units in stock')),
                      );
                      return;
                    }
                  }
                  _loadStock();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Stock updated for ${stock.bloodType}'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Update',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Donor: donate units dialog ────────────────────────────────
  void _showDonateDialog() {
    String selectedType = 'A+';
    // ✅ Donor can enter how many units to donate
    final unitsController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Donate to Blood Bank'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Blood type selector ─────────────────────
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Your Blood Type',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                  isDense: true,
                ),
                items: BloodStockService.bloodTypes
                    .map((bt) => DropdownMenuItem(
                    value: bt, child: Text(bt)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedType = v ?? 'A+'),
              ),
              const SizedBox(height: 12),

              // ── Units input ─────────────────────────────
              TextField(
                controller: unitsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Units to Donate',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                  helperText: '1 unit = 450ml whole blood',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // ── Info card ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A healthy adult can donate 1 unit (450ml) every 3 months.',
                        style: TextStyle(
                            fontSize: 11, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: MainColors.primary),
              onPressed: () async {
                final units =
                    int.tryParse(unitsController.text.trim()) ?? 0;
                if (units <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                        Text('Please enter valid units')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await BloodStockService.addUnits(
                      selectedType, units);
                  _loadStock();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Thank you! $units unit(s) of '
                              '$selectedType added to blood bank 🩸',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Confirm Donation',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadStock,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ─────────────────────────────────
          Row(
            children: [
              const Icon(Icons.water_drop, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Blood Bank Stock',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_isAdmin)
                Chip(
                  label: const Text('Admin',
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: MainColors.primary,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isAdmin
                ? 'Tap any card to update stock'
                : 'Current blood availability',
            style: TextStyle(
                color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),

          // ── Stock grid ──────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: _stock.length,
            itemBuilder: (context, i) => _StockCard(
              stock: _stock[i],
              isAdmin: _isAdmin,
              onTap: _isAdmin
                  ? () => _showUpdateDialog(_stock[i])
                  : null,
            ),
          ),

          const SizedBox(height: 24),

          // ── Donate section (non-admin only) ─────────
          if (!_isAdmin) ...[
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.favorite,
                    color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Donate Blood to Bank',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your donation saves lives. '
                  'Enter how many units you want to donate.',
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            ActionButton(
              text: 'Donate Blood Units',
              callback: _showDonateDialog,
            ),
          ],
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final BloodStock stock;
  final bool isAdmin;
  final VoidCallback? onTap;

  const _StockCard({
    required this.stock,
    required this.isAdmin,
    this.onTap,
  });

  Color get _statusColor {
    if (stock.units == 0) return Colors.red;
    if (stock.units < 5) return Colors.orange;
    return Colors.green;
  }

  String get _statusLabel {
    if (stock.units == 0) return 'Out of Stock';
    if (stock.units < 5) return 'Low Stock';
    return 'Available';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: _statusColor.withOpacity(0.4), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: MainColors.primary,
                    child: Text(
                      stock.bloodType,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isAdmin)
                    const Icon(Icons.edit,
                        size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${stock.units} units',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}