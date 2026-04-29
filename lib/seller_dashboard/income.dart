import 'package:flutter/material.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: null,
        title: const Text(
          'My Income',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),


        actions: const [
          SizedBox(width: 10),
        ],
      ),

      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: const [
                  Tab(text: "Overview"),
                  Tab(text: "Order History"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [

                  _OverviewTab(),

                  _OrderHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSummaryRow(context, "Total Income Available", "Rs. 24,500"),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                _buildSummaryRow(context, "Pending Income", "Rs. 5,200",
                    isPending: true),
              ],
            ),
          ),
          const SizedBox(height: 24),


          const Text(
            "Recent Orders",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),


          _buildOrderCard(context, "ORD-982123", "Rs. 1,250", "Delivered",
              Colors.green),
          _buildOrderCard(
              context, "ORD-982124", "Rs. 850", "Processing", Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String title, String amount,
      {bool isPending = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                color: isPending
                    ? Colors.orange
                    : Theme.of(context).colorScheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Icon(
          isPending ? Icons.pending_actions : Icons.account_balance_wallet,
          color: isPending
              ? Colors.orange.withOpacity(0.2)
              : Theme.of(context).colorScheme.primary.withOpacity(0.2),
          size: 40,
        ),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, String orderId, String amount,
      String status, Color statusColor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.shopping_bag_outlined,
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(orderId,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(amount,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
                color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _OrderHistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Orders History",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        _buildHistoryItem(context, "ORD-981001", "Rs. 2,200", "Completed",
            "20 Oct 2025"),
        _buildHistoryItem(context, "ORD-981002", "Rs. 500", "Cancelled",
            "18 Oct 2025"),
        _buildHistoryItem(context, "ORD-981003", "Rs. 3,500", "Completed",
            "15 Oct 2025"),
        _buildHistoryItem(context, "ORD-981004", "Rs. 1,000", "Returned",
            "12 Oct 2025"),
        _buildHistoryItem(context, "ORD-981005", "Rs. 450", "Completed",
            "10 Oct 2025"),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, String orderId, String price,
      String status, String date) {
    Color statusColor = Colors.green;
    if (status == 'Cancelled') statusColor = Colors.red;
    if (status == 'Returned') statusColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$date • $status"),
        trailing: Text(
          price,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(
            status == 'Completed'
                ? Icons.check
                : (status == 'Cancelled' ? Icons.close : Icons.replay),
            color: statusColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}


