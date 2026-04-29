import 'package:flutter/material.dart';

import 'product_opener.dart';

class FeedbackButtonScreen extends StatelessWidget {
  final List<Map<String, String>> pendingProducts = [
    {'title': 'Designer Suit 1', 'image': 'assets/6.webp'},
    {'title': 'Designer Suit 2', 'image': 'assets/2.webp'},
    {'title': 'Designer Suit 3', 'image': 'assets/3.webp'},
    {'title': 'Designer Suit 4', 'image': 'assets/4.webp'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: pendingProducts.isEmpty
          ? const Center(
              child: Text(
                'No products available',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingProducts.length,
              itemBuilder: (context, index) {
                final product = pendingProducts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductOpenerScreen(
                          title: product['title']!,
                          images: [product['image']!],
                          image: product['image'],
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          product['image']!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(product['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                );
              },
            ),
    );
  }
}