import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/app_backend.dart';
import 'tracking.dart' as tracking;
import 'tracking_order_firebase_shared.dart';

/// Firebase: tailor’s order tracking (stream, rates, actions).
class TailorOrdersPageFirebase extends StatefulWidget {
  const TailorOrdersPageFirebase({super.key});

  @override
  State<TailorOrdersPageFirebase> createState() => _TailorOrdersPageFirebaseState();
}

class _TailorOrdersPageFirebaseState extends State<TailorOrdersPageFirebase> {
  AppUserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfileAndValidateRole();
  }

  Future<void> _loadProfileAndValidateRole() async {
    try {
      final p = await AppBackend.instance.getUserProfile(AppBackend.instance.currentUid);
      if (!mounted) return;
      if (p.role != 'tailor') {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in with a tailor account.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const tracking.RoleSelectionScreen()),
        );
        return;
      }
      setState(() => _profile = p);
    } catch (_) {
      if (mounted) setState(() => _profile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = AppBackend.instance;
    final uid = backend.currentUid;
    final name = _profile?.name;
    return TrackOrdersPageFirebase(
      role: 'tailor',
      themeColor: Colors.purple,
      ordersStream: backend.streamOrdersForTailor(uid),
      appBarTitle: name == null ? 'Track Orders' : 'Hi, $name',
    );
  }
}

/// Entry that matches previous [TailorDashboardPageFirebase] API.
class TailorDashboardPageFirebase extends StatelessWidget {
  const TailorDashboardPageFirebase({super.key});

  @override
  Widget build(BuildContext context) {
    return const TailorOrdersPageFirebase();
  }
}
