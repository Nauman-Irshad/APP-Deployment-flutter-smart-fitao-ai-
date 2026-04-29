import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/app_backend.dart';
import 'tracking.dart' as tracking;
import 'tracking_order_firebase_shared.dart';

/// Firebase: user’s order tracking (stream + actions).
class UserOrdersPageFirebase extends StatefulWidget {
  const UserOrdersPageFirebase({super.key});

  @override
  State<UserOrdersPageFirebase> createState() => _UserOrdersPageFirebaseState();
}

class _UserOrdersPageFirebaseState extends State<UserOrdersPageFirebase> {
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
      if (p.role != 'user') {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in with a user account.')),
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
      role: 'user',
      themeColor: Colors.green,
      ordersStream: backend.streamOrdersForUser(uid),
      appBarTitle: name == null ? 'Track Orders' : 'Hi, $name',
    );
  }
}
