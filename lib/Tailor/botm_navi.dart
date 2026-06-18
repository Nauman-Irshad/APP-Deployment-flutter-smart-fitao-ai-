import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Order-Tracking-System/tailor_tracking_order.dart';
import '../services/role_order_badges.dart';
import '../services/tailor_chat_service.dart';
import '../widgets/nav_badge_icon.dart';
import 'tailor_add_rate_dialog.dart';
import 'tailor_center.dart';
import 'tailor_reel_upload_screen.dart';
import 't_messages.dart';
import 't_profile.dart';

class BotmNavScreen extends StatefulWidget {
  const BotmNavScreen({super.key});

  @override
  State<BotmNavScreen> createState() => _BotmNavScreenState();
}

class _BotmNavScreenState extends State<BotmNavScreen> with TickerProviderStateMixin {
  static const int _navHome = 0;
  static const int _navOrders = 1;
  static const int _navMessages = 2;
  static const int _navAddVideo = 3;
  static const int _navAddRate = 4;
  static const int _navMe = 5;

  int _selectedNavIndex = 0;
  int? _hoveredIndex;
  late List<AnimationController> _hoverControllers;

  final List<Widget> _pages = const [
    TailorCenterScreen(),
    TailorOrdersPageFirebase(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.home, 'label': 'Home', 'badge': 'none'},
    {'icon': Icons.receipt_long_outlined, 'label': 'Orders', 'badge': 'orders'},
    {'icon': Icons.message_outlined, 'label': 'Messages', 'badge': 'messages'},
    {'icon': Icons.video_call_outlined, 'label': 'Add video', 'badge': 'none'},
    {'icon': Icons.payments_outlined, 'label': 'Add rate', 'badge': 'none'},
    {'icon': Icons.person, 'label': 'Me', 'badge': 'none'},
  ];

  int get _bodyIndex {
    switch (_selectedNavIndex) {
      case _navOrders:
        return 1;
      case _navMessages:
        return 2;
      case _navMe:
        return 3;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _hoverControllers = List.generate(
      _navItems.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _hoverControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _openAddVideo() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const TailorReelUploadScreen(openGalleryOnStart: true),
      ),
    );
  }

  Future<void> _openAddRate() async {
    await TailorAddRateDialog.show(context);
  }

  void _onItemTapped(int index) {
    if (index == _navAddVideo) {
      _openAddVideo();
      return;
    }
    if (index == _navAddRate) {
      _openAddRate();
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (index == _navMessages && uid.isNotEmpty) {
      TailorChatService.markAllReadForTailor(uid);
    }
    setState(() {
      _selectedNavIndex = index;
    });
  }

  void _onItemHover(int index, bool isHovering) {
    setState(() {
      _hoveredIndex = isHovering ? index : null;
    });
    if (isHovering) {
      _hoverControllers[index].forward();
    } else {
      _hoverControllers[index].reverse();
    }
  }

  int _badgeForIndex(int index, int orders, int messages) {
    final kind = _navItems[index]['badge'] as String;
    if (kind == 'orders') return orders;
    if (kind == 'messages') return messages;
    return 0;
  }

  bool _isNavSelected(int index) {
    if (index == _navAddVideo || index == _navAddRate) return false;
    return _selectedNavIndex == index;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: SafeArea(child: _pages[_bodyIndex]),
      bottomNavigationBar: StreamBuilder<int>(
        stream: RoleOrderBadges.tailorPendingCount(uid),
        builder: (context, orderSnap) {
          return StreamBuilder<int>(
            stream: RoleOrderBadges.tailorUnreadMessages(uid),
            builder: (context, msgSnap) {
              final orders = orderSnap.data ?? 0;
              final messages = msgSnap.data ?? 0;
              return Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: List.generate(
                      _navItems.length,
                      (index) => SizedBox(
                        width: 72,
                        child: _AnimatedNavButton(
                          icon: _navItems[index]['icon'] as IconData,
                          label: _navItems[index]['label'] as String,
                          badgeCount: _badgeForIndex(index, orders, messages),
                          isSelected: _isNavSelected(index),
                          isHovered: _hoveredIndex == index,
                          animationController: _hoverControllers[index],
                          onTap: () => _onItemTapped(index),
                          onHover: (isHovering) => _onItemHover(index, isHovering),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AnimatedNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final bool isSelected;
  final bool isHovered;
  final AnimationController animationController;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _AnimatedNavButton({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    required this.isSelected,
    required this.isHovered,
    required this.animationController,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final liftAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );
    final tint = isSelected || isHovered
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: liftAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, liftAnimation.value),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected || isHovered
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NavBadgeIcon(
                      icon: icon,
                      count: badgeCount,
                      iconSize: 18,
                      color: tint,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.1,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: tint,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
