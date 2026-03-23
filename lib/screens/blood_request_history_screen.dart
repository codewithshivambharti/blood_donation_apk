import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../common/styles.dart';
import '../data/blood_request.dart';
import '../widgets/blood_request_tile.dart';

class BloodRequestHistoryScreen extends StatefulWidget {
  static const route = 'blood-request-history';
  const BloodRequestHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BloodRequestHistoryScreen> createState() =>
      _BloodRequestHistoryScreenState();
}

class _BloodRequestHistoryScreenState
    extends State<BloodRequestHistoryScreen> {
  late Future<QuerySnapshot<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = FirebaseFirestore.instance
        .collection('blood_requests')
        .orderBy('submittedAt', descending: true)
        .limit(50)
        .get();
  }

  // ✅ Fulfilled by label
  String _fulfilledLabel(String? fulfilledBy) {
    switch (fulfilledBy) {
      case 'blood_bank':
        return '🏦 Fulfilled by Blood Bank';
      case 'blood_bank_auto':
        return '⚡ Auto-fulfilled from Blood Bank';
      case 'donor':
        return '🩸 Fulfilled by Donor';
      default:
        return '✅ Fulfilled';
    }
  }

  // ✅ Fulfilled by color
  Color _fulfilledColor(String? fulfilledBy) {
    switch (fulfilledBy) {
      case 'blood_bank':
      case 'blood_bank_auto':
        return Colors.blue;
      case 'donor':
        return Colors.green;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(IconAssets.bloodBag,
                    height: 120),
                const SizedBox(height: 16),
                const Text(
                  'No requests yet!',
                  style: TextStyle(
                      fontFamily: Fonts.logo, fontSize: 20),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() => _load()),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              try {
                final request = BloodRequest.fromJson(
                  docs[i].data(),
                  id: docs[i].id,
                );
                return Column(
                  children: [
                    BloodRequestTile(request: request),

                    // ✅ Fulfilled info bar
                    if (request.isFulfilled)
                      Container(
                        margin: const EdgeInsets.fromLTRB(
                            12, 0, 12, 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _fulfilledColor(
                              request.fulfilledBy)
                              .withOpacity(0.08),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border.all(
                            color: _fulfilledColor(
                                request.fulfilledBy)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _fulfilledColor(
                                  request.fulfilledBy),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _fulfilledLabel(
                                    request.fulfilledBy),
                                style: TextStyle(
                                  color: _fulfilledColor(
                                      request.fulfilledBy),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // ✅ Show fulfilled date
                            if (request.fulfilledAt != null)
                              Text(
                                _formatDate(
                                    request.fulfilledAt!),
                                style: TextStyle(
                                  color: _fulfilledColor(
                                      request.fulfilledBy)
                                      .withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),

                    // ✅ Pending badge
                    if (!request.isFulfilled)
                      Container(
                        margin: const EdgeInsets.fromLTRB(
                            12, 0, 12, 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border.all(
                              color: Colors.orange.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.hourglass_empty,
                                color: Colors.orange, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Pending — Donor needed',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              } catch (e) {
                return const SizedBox.shrink();
              }
            },
          ),
        );
      },
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}