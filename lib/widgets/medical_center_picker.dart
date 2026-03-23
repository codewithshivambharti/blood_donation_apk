import 'package:flutter/material.dart';

import '../data/lists/blood_banks.dart';
import '../data/lists/hospitals.dart';
import '../data/lists/lrc_centers.dart';
import '../data/lists/medical_centers.dart';
import '../data/medical_center.dart';

class MedicalCenterPicker extends StatefulWidget {
  const MedicalCenterPicker({Key? key}) : super(key: key);

  @override
  _MedicalCenterPickerState createState() => _MedicalCenterPickerState();
}

class _MedicalCenterPickerState extends State<MedicalCenterPicker> {
  final _searchController = TextEditingController();
  MedicalCenterCategory _category = MedicalCenterCategory.hospitals;
  List<MedicalCenter> _centers = hospitals;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MedicalCenter> get _filtered {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _centers;
    return _centers
        .where((c) =>
    c.name.toLowerCase().contains(query) ||
        c.location.toLowerCase().contains(query))
        .toList();
  }

  void _onCategoryChanged(MedicalCenterCategory? cat) {
    if (cat == null || cat == _category) return;
    setState(() {
      _category = cat;
      switch (cat) {
        case MedicalCenterCategory.hospitals:
          _centers = hospitals;
          break;
        case MedicalCenterCategory.lrcCenters:
          _centers = lrcCenters;
          break;
        case MedicalCenterCategory.bloodBanks:
          _centers = bloodBanks;
          break;
        case MedicalCenterCategory.medicalCenters:
          _centers = medicalCenters;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filtered = _filtered;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search',
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<MedicalCenterCategory>(
                      value: _category,
                      onChanged: _onCategoryChanged,
                      items: MedicalCenterCategory.values
                          .map(
                            (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No results found'))
                  : ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  title: Text(
                    filtered[i].name,
                    style: textTheme.bodySmall,
                  ),
                  subtitle: Text(
                    filtered[i].location,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: textTheme.bodySmall?.color),
                  ),
                  onTap: () => Navigator.pop(context, filtered[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum MedicalCenterCategory { hospitals, lrcCenters, bloodBanks, medicalCenters }

extension MedicalCenterCategoryLabel on MedicalCenterCategory {
  String get label {
    switch (this) {
      case MedicalCenterCategory.hospitals:
        return 'Hospitals';
      case MedicalCenterCategory.lrcCenters:
        return 'Red Cross';
      case MedicalCenterCategory.bloodBanks:
        return 'Blood Banks';
      case MedicalCenterCategory.medicalCenters:
        return 'Others';
    }
  }
}