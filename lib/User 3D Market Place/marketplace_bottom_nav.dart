import 'package:flutter/material.dart';

import 'marketplace_theme.dart';
import 'shopping_cart.dart';

/// Shared bottom menu bar for marketplace, cart, checkout, and product pages.
class MarketplaceBottomNav extends StatelessWidget {
  const MarketplaceBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ShoppingCart.instance,
      builder: (context, _) {
        final count = ShoppingCart.instance.itemCount;
        return _buildBar(context, count);
      },
    );
  }

  Widget _buildBar(BuildContext context, int count) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex.clamp(0, 5),
        onTap: onTap,
        selectedItemColor: MarketplaceTheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.video_collection_outlined),
            label: 'Reel',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            label: '2D Try On',
          ),
          BottomNavigationBarItem(
            icon: _CartNavIcon(count: count),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// Pop product/checkout routes and switch the main marketplace tab.
  static void goToTab(BuildContext context, int index) {
    ShoppingCart.instance.onNavigateToTab?.call(index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _CartNavIcon extends StatelessWidget {
  const _CartNavIcon({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart_outlined),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: MarketplaceTheme.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
