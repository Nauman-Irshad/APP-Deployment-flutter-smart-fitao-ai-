import 'package:flutter/material.dart';

import '../services/marketplace_badge_service.dart';
import 'marketplace_theme.dart';
import 'shopping_cart.dart';

/// Shared bottom menu bar for marketplace, cart, checkout, and product pages.
class MarketplaceBottomNav extends StatelessWidget {
  const MarketplaceBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.chatUnread = 0,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int chatUnread;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ShoppingCart.instance,
      builder: (context, _) {
        final count = ShoppingCart.instance.itemCount;
        return ListenableBuilder(
          listenable: MarketplaceBadgeService.instance,
          builder: (context, _) {
            final newProducts = MarketplaceBadgeService.instance.newProducts;
            final newReels = MarketplaceBadgeService.instance.newReels;
            return _buildBar(context, count, newProducts, newReels, chatUnread);
          },
        );
      },
    );
  }

  Widget _buildBar(
    BuildContext context,
    int cartCount,
    int newProducts,
    int newReels,
    int chatUnread,
  ) {
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
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: _BadgeNavIcon(
              icon: Icons.home,
              count: newProducts,
              accent: Colors.red,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _BadgeNavIcon(
              icon: Icons.video_collection_outlined,
              count: newReels,
              accent: Colors.red,
            ),
            label: 'Reel',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            label: '2D Try On',
          ),
          BottomNavigationBarItem(
            icon: _CartNavIcon(count: cartCount),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: _BadgeNavIcon(
              icon: Icons.chat_bubble_outline,
              count: chatUnread,
              accent: Colors.red,
            ),
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

  /// Pop nested routes and switch the main marketplace tab (keeps home screen state).
  static void goToTab(BuildContext context, int index) {
    final nav = Navigator.of(context);
    while (nav.canPop()) {
      nav.pop();
    }
    ShoppingCart.instance.onNavigateToTab?.call(index);
  }
}

class _BadgeNavIcon extends StatelessWidget {
  const _BadgeNavIcon({
    required this.icon,
    required this.count,
    required this.accent,
  });

  final IconData icon;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: accent,
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
