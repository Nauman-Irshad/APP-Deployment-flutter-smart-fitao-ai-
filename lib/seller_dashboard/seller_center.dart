import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Order-Tracking-System/seller_tracking_order.dart';
import '../services/role_order_badges.dart';
import '../widgets/nav_badge_icon.dart';
import '../Order-Tracking-System/services/app_backend.dart';

class SellerCenterScreen extends StatefulWidget {
  const SellerCenterScreen({super.key});

  @override
  State<SellerCenterScreen> createState() => _SellerCenterScreenState();
}

class _SellerCenterScreenState extends State<SellerCenterScreen> {
  String _selectedFilter = 'Day';
  AppUserProfile? _sellerProfile;

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final p = await AppBackend.instance.getUserProfile(user.uid);
      if (mounted) setState(() => _sellerProfile = p);
    } catch (_) {
      if (mounted) setState(() => _sellerProfile = null);
    }
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  static List<String> _dayBucketLabels() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return short[d.weekday - 1];
    });
  }

  static List<String> _weekBucketLabels() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final anchorMonday = day.subtract(Duration(days: day.weekday - DateTime.monday));
    return List.generate(7, (i) {
      final weekStart = anchorMonday.subtract(Duration(days: 7 * (6 - i)));
      return '${weekStart.day}/${weekStart.month}';
    });
  }

  static List<String> _monthBucketLabels() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return List.generate(7, (k) {
      final d = DateTime(now.year, now.month - (6 - k), 1);
      return months[d.month - 1];
    });
  }

  List<String> _chartBottomLabels() {
    switch (_selectedFilter) {
      case 'Week':
        return _weekBucketLabels();
      case 'Month':
        return _monthBucketLabels();
      default:
        return _dayBucketLabels();
    }
  }

  static double _chartMaxY(List<double> sales, List<double> profit) {
    final m = [...sales, ...profit].fold<double>(0, (a, b) => math.max(a, b));
    if (m <= 0) return 100;
    return m * 1.15;
  }

  static double _niceYInterval(double maxY) {
    if (maxY <= 0) return 25;
    final raw = maxY / 4;
    if (raw < 1) return 1;
    final exp = (math.log(raw) / math.ln10).floor();
    final frac = raw / math.pow(10, exp);
    double niceFrac;
    if (frac <= 1) {
      niceFrac = 1;
    } else if (frac <= 2) {
      niceFrac = 2;
    } else if (frac <= 5) {
      niceFrac = 5;
    } else {
      niceFrac = 10;
    }
    return niceFrac * math.pow(10, exp);
  }

  static String _formatPkr(double v) {
    final n = v.round();
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    if (n < 0) return '-$buf';
    return buf.toString();
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, List<String> labels) {
    const style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.bold,
      fontSize: 11,
    );
    final i = value.round();
    if (i < 0 || i >= labels.length) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(labels[i], style: style),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta, double maxY, double interval) {
    const style = TextStyle(
      color: Color(0xff67727d),
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    if (value < 0 || value > maxY * 1.02) return const SizedBox.shrink();
    final rounded = (value / interval).round() * interval;
    if ((value - rounded).abs() > interval * 0.01 && value != 0) {
      return const SizedBox.shrink();
    }
    final text = value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
    return Text(text, style: style, textAlign: TextAlign.left);
  }

  int _statusCount(SellerAnalyticsSnapshot snap, String key) => snap.orderStatusCounts[key] ?? 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seller Center',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_sellerProfile != null)
              Text(
                _sellerProfile!.name.isNotEmpty ? _sellerProfile!.name : _sellerProfile!.email,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        centerTitle: false,
        actions: [
          StreamBuilder<int>(
            stream: user == null
                ? Stream.value(0)
                : RoleOrderBadges.sellerPendingCount(user.uid),
            builder: (context, snap) {
              final pending = snap.data ?? 0;
              return TextButton.icon(
                onPressed: () {
                  if (FirebaseAuth.instance.currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign in as a seller to track orders')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const SellerOrdersPageFirebase()),
                  );
                },
                icon: NavBadgeIcon(
                  icon: Icons.local_shipping_outlined,
                  count: pending,
                  iconSize: 20,
                  color: primary,
                ),
                label: const Text('Track orders'),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Sign in as a seller to view your dashboard.'))
          : StreamBuilder<SellerAnalyticsSnapshot>(
              stream: AppBackend.instance.streamSellerAnalytics(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load analytics: ${snapshot.error}'));
                }
                final data = snapshot.data ?? SellerAnalyticsSnapshot.empty();
                final salesB = data.salesBucketsByPeriod[_selectedFilter] ?? List<double>.filled(7, 0);
                final profitB = data.profitBucketsByPeriod[_selectedFilter] ?? List<double>.filled(7, 0);
                final currentSales = List<FlSpot>.generate(7, (i) => FlSpot(i.toDouble(), salesB[i]));
                final currentProfit = List<FlSpot>.generate(7, (i) => FlSpot(i.toDouble(), profitB[i]));
                final salesTotal = data.totalSalesByPeriod[_selectedFilter] ?? 0;
                final profitTotal = data.totalProfitByPeriod[_selectedFilter] ?? 0;
                final chartMaxY = _chartMaxY(salesB, profitB);
                final yInterval = _niceYInterval(chartMaxY);
                final bottomLabels = _chartBottomLabels();

                return SingleChildScrollView(
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
                                  _sellerProfile == null
                                      ? 'Seller'
                                      : (_sellerProfile!.shopName.isNotEmpty
                                          ? _sellerProfile!.shopName
                                          : _sellerProfile!.name),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _sellerProfile == null
                                      ? 'Loading profile…'
                                      : (_sellerProfile!.shopName.isNotEmpty
                                          ? _sellerProfile!.name
                                          : (_sellerProfile!.address.isNotEmpty
                                              ? _sellerProfile!.address
                                              : _sellerProfile!.email)),
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_sellerProfile != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${_sellerProfile!.uid}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Business Advisor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _TimeFilter(
                                      text: 'Day',
                                      isSelected: _selectedFilter == 'Day',
                                      onTap: () => _onFilterSelected('Day'),
                                    ),
                                    _TimeFilter(
                                      text: 'Week',
                                      isSelected: _selectedFilter == 'Week',
                                      onTap: () => _onFilterSelected('Week'),
                                    ),
                                    _TimeFilter(
                                      text: 'Month',
                                      isSelected: _selectedFilter == 'Month',
                                      onTap: () => _onFilterSelected('Month'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1F9D6E), Color(0xFF166E4D)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1F9D6E).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Total Sales',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'PKR ${_formatPkr(salesTotal)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF2ECA8B), Color(0xFF1F9D6E)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2ECA8B).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Total Profit',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'PKR ${_formatPkr(profitTotal)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Sales & profit count only after you tap Confirm Payment on a delivered order.',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true, drawVerticalLine: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: 1,
                                        getTitlesWidget: (v, m) => _bottomTitleWidgets(v, m, bottomLabels),
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: yInterval,
                                        getTitlesWidget: (v, m) => _leftTitleWidgets(v, m, chartMaxY, yInterval),
                                        reservedSize: 42,
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: const Color(0xff37434d).withOpacity(0.1)),
                                  ),
                                  minX: 0,
                                  maxX: 6,
                                  minY: 0,
                                  maxY: chartMaxY,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: currentSales,
                                      isCurved: true,
                                      color: Colors.blue,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.blue.withOpacity(0.1),
                                      ),
                                    ),
                                    LineChartBarData(
                                      spots: currentProfit,
                                      isCurved: true,
                                      color: Colors.green,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.green.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LegendItem(color: Colors.blue, text: 'Sales'),
                                SizedBox(width: 20),
                                _LegendItem(color: Colors.green, text: 'Profit'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Order Status',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SellerOrdersPageFirebase(),
                                  ),
                                );
                              },
                              child: _StatusCard(
                                title: 'Pending',
                                count: '${_statusCount(data, 'pending')}',
                                color: Colors.orange,
                                icon: Icons.hourglass_empty,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatusCard(
                              title: 'Cancelled',
                              count: '${_statusCount(data, 'cancelled')}',
                              color: Colors.red,
                              icon: Icons.cancel_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SellerOrdersPageFirebase(),
                                  ),
                                );
                              },
                              child: _StatusCard(
                                title: 'Shipped',
                                count: '${_statusCount(data, 'shipped')}',
                                color: Colors.blue,
                                icon: Icons.local_shipping_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SellerOrdersPageFirebase(),
                                  ),
                                );
                              },
                              child: _StatusCard(
                                title: 'Completed',
                                count: '${_statusCount(data, 'completed')}',
                                color: Colors.green,
                                icon: Icons.check_circle_outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_statusCount(data, 'other') > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Other / tailor workflow: ${_statusCount(data, 'other')}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Expanded(
                            child: _StatusCard(
                              title: 'Return',
                              count: '0',
                              color: Colors.indigo,
                              icon: Icons.assignment_return_outlined,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _StatusCard(
                              title: 'Feedback',
                              count: '0',
                              color: Colors.teal,
                              icon: Icons.rate_review_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Products wise Sales',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: data.productSales.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'No orders yet. Sales by product will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (var i = 0; i < data.productSales.length; i++) ...[
                                    if (i > 0) const Divider(height: 1),
                                    _ProductSaleItem(
                                      name: data.productSales[i].productName,
                                      sales: '${data.productSales[i].orderCount} Orders',
                                      revenue: 'PKR ${_formatPkr(data.productSales[i].totalSalesPkr)}',
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _TimeFilter extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeFilter({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ProductSaleItem extends StatelessWidget {
  final String name;
  final String sales;
  final String revenue;

  const _ProductSaleItem({
    required this.name,
    required this.sales,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sales, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        revenue,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14,
        ),
      ),
    );
  }
}
