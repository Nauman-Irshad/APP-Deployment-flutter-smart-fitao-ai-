import 'package:flutter/material.dart';

import '../Order-Tracking-System/services/app_backend.dart';
import '../User 3D Market Place/ai_chatbot_screen.dart';
import '../services/customer_fitting_store.dart';
import 'try_on_order_session.dart';
import 'try_on_tailor_chat_screen.dart';
import 'try_on_theme.dart';

/// After 2D try-on: AI chatbot + available tailors with stitching price (PKR).
class TryOnFindTailorScreen extends StatefulWidget {
  const TryOnFindTailorScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const TryOnFindTailorScreen()),
    );
  }

  @override
  State<TryOnFindTailorScreen> createState() => _TryOnFindTailorScreenState();
}

class _TryOnFindTailorScreenState extends State<TryOnFindTailorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  Future<List<AppUserProfile>>? _tailorsFuture;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: 1);
    _tailorsFuture = AppBackend.instance.fetchTailorsForCustomerChat();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TryOnTheme.white,
      appBar: AppBar(
        backgroundColor: TryOnTheme.white,
        foregroundColor: TryOnTheme.brown,
        elevation: 0,
        title: Text('Find tailor', style: TryOnTheme.heading(size: 18)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: TryOnTheme.brown,
          unselectedLabelColor: TryOnTheme.brownMuted,
          indicatorColor: TryOnTheme.brown,
          tabs: const [
            Tab(text: 'AI Chat Bot', icon: Icon(Icons.smart_toy_outlined, size: 20)),
            Tab(text: 'Tailors & price', icon: Icon(Icons.cut, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFf0fdf4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              TryOnOrderSession.instance.sizeSummary,
              style: TryOnTheme.body(size: 12, weight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                const _AiChatTab(),
                _TailorsTab(future: _tailorsFuture),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiChatTab extends StatelessWidget {
  const _AiChatTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined, size: 56, color: TryOnTheme.brown.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Smart Fiatio AI Chat Bot',
            textAlign: TextAlign.center,
            style: TryOnTheme.heading(size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            'Ask about kurta size, fabric, delivery, returns, or your 2D try-on result.',
            textAlign: TextAlign.center,
            style: TryOnTheme.body(size: 14, color: TryOnTheme.brownMuted),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const AiChatbotScreen()),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Open AI Chat Bot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TailorsTab extends StatelessWidget {
  const _TailorsTab({required this.future});
  final Future<List<AppUserProfile>>? future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppUserProfile>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load tailors: ${snap.error}',
                  style: TryOnTheme.body(size: 14, color: TryOnTheme.errText)),
            ),
          );
        }
        final tailors = snap.data ?? [];
        if (tailors.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'No tailor registered yet',
                style: TryOnTheme.body(size: 15, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '1) Run tailor app → Register / login:\n'
                '   tailorahmedsmartfitao@gmail.com / Tailor@12345\n'
                '2) Set stitching rate (Add rate)\n'
                '3) Come back here to chat & place order',
                style: TryOnTheme.body(size: 13, color: TryOnTheme.brownMuted),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Registered tailors — stitching price (PKR)',
              style: TryOnTheme.body(size: 14, weight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...tailors.map((t) => _TailorCard(tailor: t)),
          ],
        );
      },
    );
  }
}

class _TailorCard extends StatelessWidget {
  const _TailorCard({required this.tailor});
  final AppUserProfile tailor;

  @override
  Widget build(BuildContext context) {
    final label = tailor.shopName.isNotEmpty ? tailor.shopName : tailor.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: TryOnTheme.gray),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFf0fdf4),
                child: Icon(Icons.person, color: TryOnTheme.brown),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TryOnTheme.body(size: 15, weight: FontWeight.w700)),
                    Text(
                      '${tailor.name} · PKR ${tailor.stitchingRate.toStringAsFixed(0)} / stitch',
                      style: TryOnTheme.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await CustomerFittingStore.syncSessionFromLocal();
                    if (!context.mounted) return;
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => TryOnTailorChatScreen(tailor: tailor),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TryOnTheme.brown,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await CustomerFittingStore.syncSessionFromLocal();
                    if (!context.mounted) return;
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => TryOnTailorChatScreen(tailor: tailor),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chat with $label to confirm stitching order.'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Order stitch'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
