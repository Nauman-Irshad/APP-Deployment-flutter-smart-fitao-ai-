import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Order-Tracking-System/services/app_backend.dart';

/// Tailor stitching rate dialog — used from menu bar and dashboard.
class TailorAddRateDialog {
  TailorAddRateDialog._();

  static Future<void> show(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in as a tailor to set your rate')),
      );
      return;
    }

    AppUserProfile? existing;
    try {
      existing = await AppBackend.instance.getUserProfile(user.uid);
    } catch (_) {}

    final rateCtrl = TextEditingController(
      text: existing != null && existing.stitchingRate > 0
          ? existing.stitchingRate.toStringAsFixed(0)
          : '500',
    );
    final profitCtrl = TextEditingController(
      text: existing != null && existing.tailorProfitPerUnit > 0
          ? existing.tailorProfitPerUnit.toStringAsFixed(0)
          : '500',
    );
    var available = existing?.available ?? true;
    bool? ok;
    var rateText = '';
    var profitText = '';
    try {
      ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add rate'),
          content: StatefulBuilder(
            builder: (ctx, setS) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Stitching rate (PKR per unit)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: profitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Profit (PKR per unit)',
                    helperText: 'Dashboard only — not shown to customers',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available for custom orders'),
                  value: available,
                  onChanged: (v) => setS(() => available = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      );
      rateText = rateCtrl.text;
      profitText = profitCtrl.text;
    } finally {
      rateCtrl.dispose();
      profitCtrl.dispose();
    }
    if (ok != true || !context.mounted) return;

    final rate = double.tryParse(rateText.trim()) ?? 0;
    if (rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a rate greater than 0')),
      );
      return;
    }
    final profit = double.tryParse(profitText.trim()) ?? -1;
    if (profit < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profit must be 0 or greater')),
      );
      return;
    }
    try {
      await AppBackend.instance.setTailorAvailableAndRate(
        uid: user.uid,
        stitchingRatePkrPerUnit: rate,
        tailorProfitPerUnit: profit,
        available: available,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rate saved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }
}
