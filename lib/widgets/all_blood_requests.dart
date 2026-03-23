import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../common/styles.dart';
import '../data/blood_request.dart';
import '../widgets/blood_request_tile.dart';

class AllBloodRequests extends StatefulWidget {
  const AllBloodRequests({Key? key}) : super(key: key);

  @override
  _AllBloodRequestsState createState() => _AllBloodRequestsState();
}

class _AllBloodRequestsState extends State<AllBloodRequests> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _query;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    // ✅ Check if user is authenticated
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // If user is not authenticated, use empty stream
      _query = const Stream.empty();
    } else {
      // ✅ User is authenticated, fetch blood requests
      _query = FirebaseFirestore.instance
          .collection('blood_requests')
          .where('isFulfilled', isEqualTo: false)
          .orderBy('requestDate')
          .limit(30)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check authentication status
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Please login to view blood requests',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: MainColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _query,
      builder: (context, snapshot) {
        // ❌ ERROR STATE
        if (snapshot.hasError) {
          print('🔴 Error fetching blood requests: ${snapshot.error}');
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Could not fetch blood requests\n${snapshot.error}',
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
                        _initializeStream();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // ⏳ LOADING STATE
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ ACTIVE STATE
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data?.docs.isEmpty ?? true) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
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
              ),
            );
          } else {
            // ✅ Display blood requests
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) {
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
                childCount: snapshot.data?.size ?? 0,
              ),
            );
          }
        }

        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}