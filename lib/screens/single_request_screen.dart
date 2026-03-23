import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/colors.dart';
import '../data/blood_request.dart';
import '../services/admin_service.dart';
import '../services/blood_stock_service.dart';
import '../utils/blood_types.dart';
import '../utils/tools.dart';

class SingleRequestScreen extends StatelessWidget {
  final BloodRequest request;
  const SingleRequestScreen({Key? key, required this.request})
      : super(key: key);

  Future<void> _openGoogleMaps(BuildContext context) async {
    final lat = request.medicalCenter.latitude;
    final lng = request.medicalCenter.longitude;
    final name = Uri.encodeComponent(request.medicalCenter.name);

    // ✅ Try Google Maps app first
    final appUri =
    Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    // ✅ Fallback to browser
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '&destination=$lat,$lng'
          '&destination_place_name=$name',
    );
    // ✅ Also try maps:// for iOS
    final mapsUri =
    Uri.parse('maps://?daddr=$lat,$lng&dirflg=d');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri,
            mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri,
            mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri,
            mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not open Google Maps')),
          );
        }
      }
    } catch (e) {
      // ✅ Final fallback — open in browser directly
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri,
            mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _callContact(BuildContext context) async {
    final uri = Uri.parse('tel:+91${request.contactNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not open dialer')),
        );
      }
    }
  }

  String _fulfilledByText() {
    switch (request.fulfilledBy) {
      case 'blood_bank':
        return 'Fulfilled by Blood Bank (Admin)';
      case 'blood_bank_auto':
        return 'Auto-fulfilled from Blood Bank stock';
      case 'donor':
        return 'Fulfilled by a Donor';
      default:
        return 'Request has been fulfilled';
    }
  }

  String _fulfilledAtText() {
    if (request.fulfilledAt == null) return '';
    final date = DateTime.tryParse(request.fulfilledAt!);
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'on ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.bodySmall?.copyWith(fontSize: 14);
    final bodyStyle = textTheme.bodyLarge?.copyWith(fontSize: 16);
    const bodyWrap = EdgeInsets.only(top: 4, bottom: 16);
    final isAdmin = AdminService.isCurrentUserAdmin;
    final isOwner =
        request.uid == FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar:
      AppBar(title: const Text('Blood Request Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fulfilled banner ──────────────────────────
              if (request.isFulfilled)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fulfilledByText(),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (request.fulfilledAt != null)
                              Text(
                                _fulfilledAtText(),
                                style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              Text('Submitted By', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(
                  '${request.submittedBy} on ${Tools.formatDate(request.submittedAt)}',
                  style: bodyStyle,
                ),
              ),
              Text('Patient Name', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(request.patientName,
                    style: bodyStyle),
              ),
              Text('Location', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(
                  '${request.medicalCenter.name} - ${request.medicalCenter.location}',
                  style: bodyStyle,
                ),
              ),
              Text('Blood Type', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(request.bloodType.name,
                    style: bodyStyle),
              ),

              // ✅ Units required
              Text('Units Required', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Row(
                  children: [
                    const Icon(Icons.water_drop,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${request.unitsRequired} unit(s)  '
                          '(${request.unitsRequired * 450}ml)',
                      style: bodyStyle?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              Text('Possible Donors', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(
                  request.bloodType.possibleDonors
                      .map((e) => e.name)
                      .join('   /   '),
                  style: bodyStyle,
                ),
              ),
              if (request.note != null &&
                  request.note!.isNotEmpty) ...[
                Text('Notes', style: titleStyle),
                Padding(
                  padding: bodyWrap,
                  child:
                  Text(request.note!, style: bodyStyle),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(thickness: 1),

              // ── Get Directions + Share ────────────────────
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor:
                          MainColors.primaryDark,
                        ),
                        // ✅ Fixed — opens Google Maps
                        onPressed: () =>
                            _openGoogleMaps(context),
                        icon: const Icon(
                            Icons.navigation_outlined),
                        label:
                        const Text('Get Directions'),
                      ),
                    ),
                    const VerticalDivider(thickness: 1),
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor:
                          MainColors.primaryDark,
                        ),
                        onPressed: () {
                          Share.share(
                            '${request.patientName} needs '
                                '${request.unitsRequired} unit(s) of '
                                '${request.bloodType.name} blood by '
                                '${Tools.formatDate(request.requestDate)}.\n'
                                'Donate at: ${request.medicalCenter.name}, '
                                '${request.medicalCenter.location}.\n\n'
                                'Contact +91${request.contactNumber}.',
                          );
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 12),

              // ── Contact ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 24),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MainColors.primary,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () => _callContact(context),
                  child: Center(
                    child: Text(
                      'Contact',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),

              if (!request.isFulfilled && isAdmin)
                _FulfillFromBankBtn(request: request),

              if (!request.isFulfilled && isOwner)
                _MarkFulfilledBtn(request: request),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fulfill from Blood Bank ───────────────────────────────
class _FulfillFromBankBtn extends StatefulWidget {
  final BloodRequest request;
  const _FulfillFromBankBtn({Key? key, required this.request})
      : super(key: key);

  @override
  State<_FulfillFromBankBtn> createState() =>
      _FulfillFromBankBtnState();
}

class _FulfillFromBankBtnState
    extends State<_FulfillFromBankBtn> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: const Icon(Icons.water_drop,
            color: Colors.white),
        label: Center(
          child: Text(
            'Fulfill from Blood Bank',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white),
          ),
        ),
        onPressed: () async {
          setState(() => _isLoading = true);
          try {
            final bloodType = widget.request.bloodType.name;
            final unitsNeeded =
                widget.request.unitsRequired;

            // ✅ Check if enough stock for all units
            final stock = await BloodStockService
                .getStockByType(bloodType);
            if (stock == null ||
                stock.units < unitsNeeded) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Not enough $bloodType stock. '
                          'Available: ${stock?.units ?? 0}, '
                          'Needed: $unitsNeeded.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }

            // ✅ Deduct required units
            final success =
            await BloodStockService.deductUnits(
                bloodType, unitsNeeded);
            if (!success) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Not enough stock to fulfill')),
                );
              }
              return;
            }

            await FirebaseFirestore.instance
                .collection('blood_requests')
                .doc(widget.request.id)
                .update({
              'isFulfilled': true,
              'fulfilledBy': 'blood_bank',
              'fulfilledAt':
              DateTime.now().toIso8601String(),
            });
            widget.request.isFulfilled = true;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Request fulfilled! $unitsNeeded unit(s) '
                        'of $bloodType deducted from bank.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')));
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
      ),
    );
  }
}

// ── Mark as Fulfilled by Donor ────────────────────────────
class _MarkFulfilledBtn extends StatefulWidget {
  final BloodRequest request;
  const _MarkFulfilledBtn({Key? key, required this.request})
      : super(key: key);

  @override
  _MarkFulfilledBtnState createState() =>
      _MarkFulfilledBtnState();
}

class _MarkFulfilledBtnState
    extends State<_MarkFulfilledBtn> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () async {
          setState(() => _isLoading = true);
          try {
            await FirebaseFirestore.instance
                .collection('blood_requests')
                .doc(widget.request.id)
                .update({
              'isFulfilled': true,
              'fulfilledBy': 'donor',
              'fulfilledAt':
              DateTime.now().toIso8601String(),
            });
            widget.request.isFulfilled = true;
            if (mounted) Navigator.pop(context);
          } on FirebaseException catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.message ??
                      'A Firebase error occurred'),
                ),
              );
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Something went wrong. Please try again'),
                ),
              );
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
        child: Center(
          child: Text(
            'Mark as Fulfilled by Donor',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}