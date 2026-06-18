import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Order-Tracking-System/seller_tracking_order.dart';
import '../services/role_order_badges.dart';
import '../services/seller_chat_service.dart';
import '../widgets/nav_badge_icon.dart';
import 'messages.dart';
import 'product.dart';
import 'profile.dart';
import 'seller_center.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  static const int _ordersTab = 1;
  static const int _messagesTab = 3;

  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    SellerCenterScreen(),
    SellerOrdersPageFirebase(),
    ProductsScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (index == _messagesTab && uid.isNotEmpty) {
      SellerChatService.markAllReadForSeller(uid);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: StreamBuilder<int>(
        stream: RoleOrderBadges.sellerPendingCount(uid),
        builder: (context, orderSnap) {
          return StreamBuilder<int>(
            stream: RoleOrderBadges.sellerUnreadMessages(uid),
            builder: (context, msgSnap) {
              final orders = orderSnap.data ?? 0;
              final messages = msgSnap.data ?? 0;
              return BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedItemColor: primary,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: NavBadgeIcon(
                      icon: Icons.local_shipping_outlined,
                      count: orders,
                      color: _selectedIndex == 1 ? primary : Colors.grey,
                    ),
                    label: 'Orders',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_bag_outlined),
                    label: 'Products',
                  ),
                  BottomNavigationBarItem(
                    icon: NavBadgeIcon(
                      icon: Icons.message_outlined,
                      count: messages,
                      color: _selectedIndex == 3 ? primary : Colors.grey,
                    ),
                    label: 'Chat',
                  ),
                  const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
