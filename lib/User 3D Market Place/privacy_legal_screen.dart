import 'package:flutter/material.dart';

import 'privacy_legal_content.dart';

enum PrivacyLegalSection { overview, privacy, terms, dataCollected, protection }

class PrivacyLegalScreen extends StatelessWidget {
  const PrivacyLegalScreen({
    super.key,
    this.initialSection = PrivacyLegalSection.overview,
  });

  final PrivacyLegalSection initialSection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: Text(
          _titleFor(initialSection),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: _sectionsFor(initialSection),
      ),
    );
  }

  String _titleFor(PrivacyLegalSection s) {
    switch (s) {
      case PrivacyLegalSection.overview:
        return 'Privacy & Security';
      case PrivacyLegalSection.privacy:
        return 'Privacy Policy';
      case PrivacyLegalSection.terms:
        return 'Terms of Service';
      case PrivacyLegalSection.dataCollected:
        return 'Data We Collect';
      case PrivacyLegalSection.protection:
        return 'How We Protect Data';
    }
  }

  List<Widget> _sectionsFor(PrivacyLegalSection s) {
    if (s == PrivacyLegalSection.overview) {
      return [
        _heroCard(),
        const SizedBox(height: 16),
        _navCard(contextHint: true),
        const SizedBox(height: 16),
        _bulletCard(
          title: 'Quick summary',
          icon: Icons.info_outline,
          body: PrivacyLegalContent.dataProtectionSummary,
        ),
        const SizedBox(height: 16),
        _listCard(
          title: 'What we collect',
          icon: Icons.folder_open_outlined,
          items: PrivacyLegalContent.dataWeCollect,
        ),
        const SizedBox(height: 16),
        _listCard(
          title: 'How we protect it',
          icon: Icons.verified_user_outlined,
          items: PrivacyLegalContent.howWeProtect,
        ),
        const SizedBox(height: 12),
        _footerNote(),
      ];
    }
    if (s == PrivacyLegalSection.privacy) {
      return [
        _docCard(PrivacyLegalContent.privacyPolicy),
        const SizedBox(height: 12),
        _footerNote(),
      ];
    }
    if (s == PrivacyLegalSection.terms) {
      return [
        _docCard(PrivacyLegalContent.termsOfService),
        const SizedBox(height: 12),
        _footerNote(),
      ];
    }
    if (s == PrivacyLegalSection.dataCollected) {
      return [
        _listCard(
          title: 'Data we collect from you',
          icon: Icons.folder_open_outlined,
          items: PrivacyLegalContent.dataWeCollect,
        ),
        const SizedBox(height: 12),
        _footerNote(),
      ];
    }
    return [
      _bulletCard(
        title: 'Our security approach',
        icon: Icons.shield_outlined,
        body: PrivacyLegalContent.dataProtectionSummary,
      ),
      const SizedBox(height: 16),
      _listCard(
        title: 'Protection measures',
        icon: Icons.lock_outline,
        items: PrivacyLegalContent.howWeProtect,
      ),
      const SizedBox(height: 12),
      _footerNote(),
    ];
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your privacy matters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${PrivacyLegalContent.appName} uses Firebase and secure cloud services. '
            'Below is how we handle your data and keep your account safe.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navCard({bool contextHint = false}) {
    return Builder(
      builder: (context) {
        return _surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Legal documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              _navRow(
                context,
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                section: PrivacyLegalSection.privacy,
              ),
              _navRow(
                context,
                icon: Icons.gavel_outlined,
                label: 'Terms of Service',
                section: PrivacyLegalSection.terms,
              ),
              _navRow(
                context,
                icon: Icons.folder_open_outlined,
                label: 'Data we collect',
                section: PrivacyLegalSection.dataCollected,
              ),
              _navRow(
                context,
                icon: Icons.lock_outline,
                label: 'How we protect your data',
                section: PrivacyLegalSection.protection,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required PrivacyLegalSection section,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrivacyLegalScreen(initialSection: section),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _bulletCard({
    required String title,
    required IconData icon,
    required String body,
  }) {
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2E7D32), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body.trim(),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listCard({
    required String title,
    required IconData icon,
    required List<({String title, String detail})> items,
  }) {
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2E7D32), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            _listItem(items[i].title, items[i].detail),
          ],
        ],
      ),
    );
  }

  Widget _listItem(String title, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF2E7D32),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _docCard(String text) {
    return _surface(
      child: Text(
        text.trim(),
        style: TextStyle(
          fontSize: 14,
          height: 1.55,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _footerNote() {
    return Center(
      child: Text(
        'Last updated: ${PrivacyLegalContent.lastUpdated} · ${PrivacyLegalContent.appName}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _surface({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
