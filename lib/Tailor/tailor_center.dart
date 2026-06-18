import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../Order-Tracking-System/tailor_tracking_order.dart';
import '../services/role_order_badges.dart';
import '../widgets/nav_badge_icon.dart';
import '../Order-Tracking-System/services/app_backend.dart';

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class TailorCenterScreen extends StatefulWidget {
  const TailorCenterScreen({super.key});

  @override
  State<TailorCenterScreen> createState() => _TailorCenterScreenState();
}

class _TailorCenterScreenState extends State<TailorCenterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _selectedEarningsPeriod = 'Day';
  String _selectedOrdersPeriod = 'Day';
  AppUserProfile? _tailorProfile;

  static const List<String> _periodLabels = ['Day', 'Week', 'Month'];

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

  List<String> _bottomLabelsFor(String period) {
    switch (period) {
      case 'Week':
        return _weekBucketLabels();
      case 'Month':
        return _monthBucketLabels();
      default:
        return _dayBucketLabels();
    }
  }

  static String _formatPkr(double v) {
    final n = v.round();
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static double _chartMaxY2(List<double> a, List<double> b) {
    final m = [...a, ...b].fold<double>(0, (x, y) => math.max(x, y));
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

  static double _chartMaxYCount(List<double> a, List<double> b) {
    final m = [...a, ...b].fold<double>(0, (x, y) => math.max(x, y));
    if (m <= 0) return 5;
    return (m * 1.2).ceilToDouble();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _loadTailorProfile();
  }

  Future<void> _loadTailorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final p = await AppBackend.instance.getUserProfile(user.uid);
      if (mounted) setState(() => _tailorProfile = p);
    } catch (_) {
      if (mounted) setState(() => _tailorProfile = null);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _periodChips({
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periodLabels.map((period) {
          final isSelected = selected == period;
          return GestureDetector(
            onTap: () => onSelect(period),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Fitao AI Tailor Center',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_tailorProfile != null)
              Text(
                _tailorProfile!.name.isNotEmpty ? _tailorProfile!.name : _tailorProfile!.email,
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
                : RoleOrderBadges.tailorPendingCount(user.uid),
            builder: (context, snap) {
              final pending = snap.data ?? 0;
              return TextButton.icon(
                onPressed: () {
                  if (FirebaseAuth.instance.currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign in as a tailor to track orders')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const TailorOrdersPageFirebase()),
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
          const SizedBox(width: 4),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Sign in as a tailor to view your dashboard.'))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: StreamBuilder<TailorDashboardSnapshot>(
                  stream: AppBackend.instance.streamTailorDashboard(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Could not load dashboard: ${snapshot.error}'));
                    }
                    final dash = snapshot.data ?? TailorDashboardSnapshot.empty();
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AnimatedContainer(
                            delay: 0,
                            animationController: _animationController,
                            child: _profileHeader(primary),
                          ),
                          const SizedBox(height: 20),
                          _AnimatedContainer(
                            delay: 100,
                            animationController: _animationController,
                            child: _totalEarningsCard(primary, dash),
                          ),
                          const SizedBox(height: 20),
                          _AnimatedContainer(
                            delay: 200,
                            animationController: _animationController,
                            child: _insightsCard(primary, dash),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _profileHeader(Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary, width: 3.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withValues(alpha: 0.3), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/4.webp',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tailorProfile == null
                      ? 'Tailor'
                      : (_tailorProfile!.shopName.isNotEmpty
                          ? _tailorProfile!.shopName
                          : _tailorProfile!.name),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  _tailorProfile == null
                      ? 'Loading profile…'
                      : (_tailorProfile!.shopName.isNotEmpty
                          ? _tailorProfile!.name
                          : (_tailorProfile!.address.isNotEmpty
                              ? _tailorProfile!.address
                              : _tailorProfile!.email)),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_tailorProfile != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${_tailorProfile!.uid}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalEarningsCard(Color primary, TailorDashboardSnapshot dash) {
    final salesB = dash.earningsSalesBuckets[_selectedEarningsPeriod] ?? List<double>.filled(7, 0);
    final profitB = dash.earningsProfitBuckets[_selectedEarningsPeriod] ?? List<double>.filled(7, 0);
    final salesTotal = dash.totalSalesByPeriod[_selectedEarningsPeriod] ?? 0;
    final profitTotal = dash.totalProfitByPeriod[_selectedEarningsPeriod] ?? 0;
    final chartMax = _chartMaxY2(salesB, profitB);
    final yInterval = _niceYInterval(chartMax);
    final labels = _bottomLabelsFor(_selectedEarningsPeriod);
    final salesSpots = List<FlSpot>.generate(7, (i) => FlSpot(i.toDouble(), salesB[i]));
    final profitSpots = List<FlSpot>.generate(7, (i) => FlSpot(i.toDouble(), profitB[i]));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Earnings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: primary,
                ),
              ),
              Flexible(child: _periodChips(selected: _selectedEarningsPeriod, onSelect: (p) => setState(() => _selectedEarningsPeriod = p))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Per order: stitching fee (sales) and PKR 500 tailor profit.',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, size: 16, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            'Total Sales',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${_formatPkr(salesTotal)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, size: 16, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            'Total Profit',
                            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${_formatPkr(profitTotal)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                backgroundColor: Colors.white,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value > chartMax * 1.02) return const SizedBox.shrink();
                        final t = value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(t, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: chartMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: salesSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.green,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.green.withValues(alpha: 0.4),
                          Colors.green.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: profitSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.orange,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.orange.withValues(alpha: 0.4),
                          Colors.orange.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(width: 16, height: 3, color: Colors.green),
                  const SizedBox(width: 6),
                  const Text('Sales', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Container(width: 16, height: 3, color: Colors.orange),
                  const SizedBox(width: 6),
                  const Text('Profit', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insightsCard(Color primary, TailorDashboardSnapshot dash) {
    final totalB = dash.ordersTotalBuckets[_selectedOrdersPeriod] ?? List<double>.filled(7, 0);
    final doneB = dash.ordersCompletedBuckets[_selectedOrdersPeriod] ?? List<double>.filled(7, 0);
    final totalSum = totalB.fold<double>(0, (a, b) => a + b);
    final doneSum = doneB.fold<double>(0, (a, b) => a + b);
    final maxCt = _chartMaxYCount(totalB, doneB);
    final labels = _bottomLabelsFor(_selectedOrdersPeriod);
    final totalSpots = List<FlSpot>.generate(7, (i) => FlSpot(i.toDouble(), totalB[i]));
    final doneSpots = List<FlSpot>.generate(7, (i) => FlSpot(i.toDouble(), doneB[i]));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shopping_bag_outlined, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Orders & activity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primary),
                ),
              ),
              Flexible(child: _periodChips(selected: _selectedOrdersPeriod, onSelect: (p) => setState(() => _selectedOrdersPeriod = p))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OrderStatusBox(
                  title: 'Total orders',
                  value: totalSum.round(),
                  color: primary,
                  icon: Icons.shopping_cart_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OrderStatusBox(
                  title: 'Payments released',
                  value: doneSum.round(),
                  color: Colors.teal,
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Product-wise Sales',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Stitching revenue after customer releases payment (by product).',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          if (dash.productSales.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No released tailoring payments yet.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...dash.productSales.map((row) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    Text(
                      'Rs ${_formatPkr(row.totalSalesPkr)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${row.orderCount} orders',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
          Text(
            'Order status analytics',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Total orders (assigned to you) vs completed when tailoring payment is released.',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                backgroundColor: Colors.white,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxCt / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.12),
                    strokeWidth: 1,
                    dashArray: const [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            labels[i],
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: math.max(1, maxCt / 5),
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.25), width: 1.5),
                ),
                minY: 0,
                maxY: maxCt,
                lineBarsData: [
                  LineChartBarData(
                    spots: totalSpots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: primary,
                    barWidth: 3.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primary.withValues(alpha: 0.3),
                          primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: doneSpots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: Colors.teal,
                    barWidth: 3.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.teal,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.teal.withValues(alpha: 0.25),
                          Colors.teal.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.grey.shade900.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendItem(color: primary, label: 'Total orders'),
              _LegendItem(color: Colors.teal, label: 'Completed (payment released)'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedContainer extends StatelessWidget {
  final Widget child;
  final int delay;
  final AnimationController animationController;

  const _AnimatedContainer({
    required this.child,
    required this.delay,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          delay / 1000,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          delay / 1000,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

class _OrderStatusBox extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;

  const _OrderStatusBox({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
