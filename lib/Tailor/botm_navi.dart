import 'package:flutter/material.dart';
import 'tailor_center.dart';
import 't_product.dart';
import 't_messages.dart';
import 't_profile.dart';
import 't_income.dart';

class BotmNavScreen extends StatefulWidget {
  const BotmNavScreen({super.key});

  @override
  State<BotmNavScreen> createState() => _BotmNavScreenState();
}

class _BotmNavScreenState extends State<BotmNavScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int? _hoveredIndex;
  late List<AnimationController> _hoverControllers;

  final List<Widget> _pages = const [
    TailorCenterScreen(),
    ProductsScreen(),
    IncomeScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.home, 'label': 'Home'},
    {'icon': Icons.shopping_bag_outlined, 'label': 'Products'},
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Income'},
    {'icon': Icons.message_outlined, 'label': 'Messages'},
    {'icon': Icons.person, 'label': 'Me'},
  ];

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: Container(
        height: 70,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            _navItems.length,
            (index) => _AnimatedNavButton(
              icon: _navItems[index]['icon'] as IconData,
              label: _navItems[index]['label'] as String,
              isSelected: _selectedIndex == index,
              isHovered: _hoveredIndex == index,
              animationController: _hoverControllers[index],
              onTap: () => _onItemTapped(index),
              onHover: (isHovering) => _onItemHover(index, isHovering),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isHovered;
  final AnimationController animationController;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _AnimatedNavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isHovered,
    required this.animationController,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final liftAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    return Expanded(
      child: MouseRegion(
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
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected || isHovered
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected || isHovered
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected || isHovered
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}