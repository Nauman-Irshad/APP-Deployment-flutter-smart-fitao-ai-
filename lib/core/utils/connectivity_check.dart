import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseConnectivityCheckPage extends StatefulWidget {
  const FirebaseConnectivityCheckPage({super.key});

  @override
  State<FirebaseConnectivityCheckPage> createState() => _FirebaseConnectivityCheckPageState();
}

class _FirebaseConnectivityCheckPageState extends State<FirebaseConnectivityCheckPage> {
  String _status = 'Not checked';
  String _appInfo = '';

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _status = 'Checking...');
    try {
      final apps = Firebase.apps;
      final firstApp = Firebase.app();
      final options = firstApp.options;
      _appInfo = 'apps: ${apps.length}\nappName: ${firstApp.name}\nprojectId: ${options.projectId}\nappId: ${options.appId}';
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('orders').limit(1).get();
      if (snapshot.docs.isEmpty) {
        setState(() => _status = 'Connected — no orders found (read OK)');
      } else {
        setState(() => _status = 'Connected — read ${snapshot.docs.length} order(s)');
      }
    } catch (e, st) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Connectivity Check'), backgroundColor: Color(0xFF059669)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(_status),
            SizedBox(height: 16),
            Text('App Info:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(_appInfo.isNotEmpty ? _appInfo : '—'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkConnection,
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF059669)),
              child: Text('Re-check'),
            ),
          ],
        ),
      ),
    );
  }
}
