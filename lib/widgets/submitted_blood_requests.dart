import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../common/styles.dart';
import '../data/blood_request.dart';
import '../widgets/blood_request_tile.dart';

class SubmittedBloodRequests extends StatefulWidget {
  final bool activeOnly;

  const SubmittedBloodRequests({
    required this.activeOnly,
    Key? key,
  }) : super(key: key);

  @override
  _SubmittedBloodRequestsState createState() => _SubmittedBloodRequestsState();
}

class _SubmittedBloodRequestsState extends State<SubmittedBloodRequests> {
  late Future<QuerySnapshot<Map<String, dynamic>>> _submittedRequests;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      // User not authenticated - set empty query
      _submittedRequests = Future.value(
        FirebaseFirestore.instance
            .collection('blood_requests')
            .where('uid', isEqualTo: '')
            .orderBy('submittedAt', descending: true)
            .limit(0)
            .get(),
      );
      return;
    }

    // ✅ Fetch user's submitted blood requests
    if (widget.activeOnly) {
      _submittedRequests = FirebaseFirestore.instance
          .collection('blood_requests')
          .where('uid', isEqualTo: userId)
          .where('isFulfilled', isEqualTo: false)
          .orderBy('submittedAt', descending: true)
          .get();
    } else {
      _submittedRequests = FirebaseFirestore.instance
          .collection('blood_requests')
          .where('uid', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .limit(20)
          .get();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Please login to view your requests',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: MainColors.primary),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _submittedRequests,
      builder: (context, snapshot) {
        // ❌ ERROR STATE
        if (snapshot.hasError) {
          print('🔴 Error fetching submitted requests: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Could not fetch your requests\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: MainColors.primary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loadRequests();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // ⏳ LOADING STATE
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✅ DONE STATE
        if (snapshot.connectionState == ConnectionState.done) {
          // Empty state
          if (snapshot.data?.docs.isEmpty ?? true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(IconAssets.bloodBag, height: 140),
                  const SizedBox(height: 16),
                  const Text(
                    'No requests yet!',
                    style: TextStyle(fontFamily: Fonts.logo, fontSize: 20),
                  ),
                ],
              ),
            );
          }

          // Display requests
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadRequests();
              });
              await _submittedRequests;
            },
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, i) {
                final doc = snapshot.data!.docs[i];
                final data = doc.data();

                try {
                  return BloodRequestTile(
                    request: BloodRequest.fromJson(
                      data,
                      id: doc.id,
                    ),
                  );
                } catch (e) {
                  print('🔴 Error parsing blood request: $e');
                  return const SizedBox.shrink();
                }
              },
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}