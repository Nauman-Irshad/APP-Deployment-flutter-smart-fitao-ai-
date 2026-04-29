import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tools',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Basic Function',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  ToolItem(
                    icon: Icons.add_box,
                    color: Colors.blue,
                    label: 'Add Products',
                    isNew: false,
                  ),
                  ToolItem(
                    icon: Icons.inventory_2,
                    color: Colors.deepOrange,
                    label: 'Products',
                    isNew: false,
                  ),
                  ToolItem(
                    icon: Icons.receipt_long,
                    color: Colors.purple,
                    label: 'Orders',
                    isNew: false,
                  ),
                  ToolItem(
                    icon: Icons.assignment_return,
                    color: Colors.purple,
                    label: 'Return Order',
                    isNew: true,
                  ),
                  ToolItem(
                    icon: Icons.thumb_up_alt_outlined,
                    color: Colors.orange,
                    label: 'Customer Feedback',
                    isNew: true,
                  ),
                  ToolItem(
                    icon: Icons.attach_money,
                    color: Colors.teal,
                    label: 'My Income',
                    isNew: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),


            const Text(
              'Business upgrading',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  ToolItem(
                    icon: Icons.bar_chart,
                    color: Colors.blue,
                    label: 'Business Advisor',
                    isNew: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ToolItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isNew;

  const ToolItem({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            if (isNew)
              Positioned(
                right: -8,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}