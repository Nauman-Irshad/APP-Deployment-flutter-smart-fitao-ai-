import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Order-Tracking-System/services/app_backend.dart';
import '../core/navigation/app_navigation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() {
        _profile = null;
        _loading = false;
      });
      return;
    }
    try {
      final p = await AppBackend.instance.getUserProfile(user.uid);
      if (mounted) setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _profile = null;
        _loading = false;
      });
    }
  }

  String _appBarTitle() {
    if (_loading) return 'Me';
    final p = _profile;
    if (p == null) return 'Seller';
    return p.shopName.isNotEmpty ? p.shopName : p.name;
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: null,
        title: Text(
          _appBarTitle(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage('assets/2.webp'),
                  backgroundColor: Colors.black12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loading
                            ? 'Loading…'
                            : (p == null
                                ? 'Not signed in'
                                : (p.shopName.isNotEmpty ? p.shopName : p.name)),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _loading
                            ? ''
                            : (p == null
                                ? 'Sign in again from role selection'
                                : (p.shopName.isNotEmpty
                                    ? p.name
                                    : (p.address.isNotEmpty ? p.address : p.email))),
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (p != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${p.uid}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            
            const Text(
              'Number of days as a seller:',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '1198 Days',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF1F9D6E),
              ),
            ),

            const SizedBox(height: 30),

            
            _buildOption(
              context,
              title: 'Seller Account',
              icon: Icons.person_outline,
              destination: const _SellerAccountScreen(),
            ),
            const Divider(),
            _buildOption(
              context,
              title: 'Bank Account',
              icon: Icons.account_balance,
              destination: const _BankAccountScreen(),
            ),
            const Divider(),
            _buildOption(
              context,
              title: 'Business Account',
              icon: Icons.business,
              destination: const _BusinessAccountScreen(),
            ),

            const SizedBox(height: 30),

            
            Center(
              child: ElevatedButton.icon(
                onPressed: () => AppNavigation.logoutToRolePicker(context),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context,
      {required String title,
      required IconData icon,
      required Widget destination}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}



class _SellerAccountScreen extends StatelessWidget {
  const _SellerAccountScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Seller Center',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Card(
          elevation: 0,
          color: const Color(0xFFDFF3EA), 
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: const [
                _SellerField(
                  label: 'Short Code',
                  value: 'P2NBNTP**',
                ),
                _DividerLine(),
                _SellerField(
                  label: 'First and Last Name',
                  value: 'AbdulRehman',
                  requiredField: true,
                  showInfo: true,
                  showChevron: true,
                ),
                _DividerLine(),
                _SellerField(
                  label: 'Internal Contact Email',
                  value: 'abdulrehman@gmail.com',
                  showInfo: true,
                  showChevron: true,
                ),
                _DividerLine(),
                _SellerField(
                  label: 'Contact Mobile Phone Number',
                  value: '+92 333438****',
                  showInfo: true,
                  showChevron: true,
                ),
                _DividerLine(),
                _SellerField(
                  label: 'Display Name / Shop Name',
                  value: 'AbdulRehman.Store',
                  requiredField: true,
                  showInfo: true,
                  showChevron: true,
                ),
                _DividerLine(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BankAccountScreen extends StatelessWidget {
  const _BankAccountScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bank Account',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Card(
          elevation: 0,
          color: const Color(0xFFDFF3EA), 
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: const [
                _FieldRow(
                  label: 'Account Title',
                  value: 'AbdulRehman',
                  requiredField: true,
                ),
                _DividerLine(),
                _FieldRow(
                  label: 'Account Number',
                  value: '14275642610**',
                  requiredField: true,
                  showInfo: true,
                ),
                _DividerLine(),
                _FieldRow(
                  label: 'Bank Code',
                  value: '8088',
                  requiredField: true,
                ),
                _DividerLine(),
                _FieldRow(
                  label: 'IBAN (e.g PK00AAAA00000***000)',
                  value: 'PK40MUC***4261000939',
                ),
                _DividerLine(),
                _FieldRow(
                  label: 'Branch Name',
                  value: 'N/A',
                  valueMuted: true,
                ),
                _DividerLine(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BusinessAccountScreen extends StatelessWidget {
  const _BusinessAccountScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Business Information',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Card(
          elevation: 0,
          color: const Color(0xFFDFF3EA), 
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: const [
                _FieldRow(label: 'Seller Type', value: 'Individual'),
                _DividerLine(),
                _FieldRow(
                  label: 'Address',
                  value:
                      'House #1 BLOCK NEAR NADRA OFFICE, JOHAR TOWN LAHORE',
                  requiredField: true,
                  showInfo: true,
                  maxLines: 1,
                ),
                _DividerLine(),
                _FieldRow(
                  label: 'Country region',
                  value: 'Pakistan',
                  requiredField: true,
                  showInfo: true,
                ),
                _DividerLine(),
                _FieldRow(
                  label: 'Business Registration Number',
                  value: 'N/A',
                  valueMuted: true,
                ),
                _DividerLine(),
                _UploadRow(
                  label: 'Upload ID - Front and Back Side',
                  requiredField: true,
                  showInfo: true,
                ),
                _DividerLine(),
                _FieldRow(
                  label: 'CNIC Number',
                  value: '3520242***71',
                  requiredField: true,
                  showInfo: true,
                ),
                _DividerLine(),
                _FieldRow(
                  label: 'Address',
                  value: 'Punjab/Lahore - Johar Town',
                  requiredField: true,
                  showInfo: true,
                  maxLines: 1,
                ),
                _DividerLine(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1),
    );
  }
}

class _SellerField extends StatelessWidget {
  final String label;
  final String value;
  final bool requiredField;
  final bool showInfo;
  final bool showChevron;

  const _SellerField({
    required this.label,
    required this.value,
    this.requiredField = false,
    this.showInfo = false,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    
    final labelStyle = TextStyle(
      fontSize: 15,
      color: Colors.grey.shade700,
      fontWeight: FontWeight.w500,
    );

    final valueStyle = const TextStyle(
      fontSize: 20,
      color: Colors.black,
      fontWeight: FontWeight.w500,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (requiredField)
                    const Text('* ',
                        style: TextStyle(color: Colors.red, fontSize: 16)),
                  Flexible(child: Text(label, style: labelStyle)),
                  if (showInfo) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: valueStyle),
            ],
          ),
        ),
        if (showChevron) ...[
          const SizedBox(width: 10),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final bool requiredField;
  final bool showInfo;
  final bool valueMuted;
  final int maxLines;

  const _FieldRow({
    required this.label,
    required this.value,
    this.requiredField = false,
    this.showInfo = false,
    this.valueMuted = false,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    
    final labelStyle = TextStyle(
      fontSize: 14, 
      color: Colors.grey.shade700,
      fontWeight: FontWeight.w500,
    );

    final valueStyle = TextStyle(
      fontSize: 18,
      color: valueMuted ? Colors.grey.shade400 : Colors.black,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (requiredField)
              const Text('* ',
                  style: TextStyle(color: Colors.red, fontSize: 16)),
            Flexible(child: Text(label, style: labelStyle)),
            if (showInfo) ...[
              const SizedBox(width: 6),
              Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: valueStyle,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _UploadRow extends StatelessWidget {
  final String label;
  final bool requiredField;
  final bool showInfo;

  const _UploadRow({
    required this.label,
    this.requiredField = false,
    this.showInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 14,
      color: Colors.grey.shade700,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (requiredField)
              const Text('* ',
                  style: TextStyle(color: Colors.red, fontSize: 16)),
            Flexible(child: Text(label, style: labelStyle)),
            if (showInfo) ...[
              const SizedBox(width: 6),
              Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFDFF3EA), 
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1F9D6E).withOpacity(0.3)),
          ),
          child: const Icon(Icons.image_outlined, color: Color(0xFF1F9D6E)),
        ),
      ],
    );
  }
}