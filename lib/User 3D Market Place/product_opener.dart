import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'size_predictor.dart';

class ProductOpenerScreen extends StatefulWidget {
  final String title;

  final List<String> images = [
    'assets/1.webp',
    'assets/2.webp',
    'assets/3.webp',
    'assets/4.webp',
    'assets/5.webp',
  ];

  ProductOpenerScreen({super.key, required this.title, required image, required List images});

  @override
  _ProductOpenerScreenState createState() => _ProductOpenerScreenState();
}

class _ProductOpenerScreenState extends State<ProductOpenerScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;
  Timer? _timer;

  final List<String> sizes = ['S', 'M', 'L', 'XL'];
  String? selectedSize;

  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= widget.images.length) _currentPage = 0;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoScroll() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSizeSelector() {
    return Row(
      children: sizes.map((s) {
        bool isSelected = selectedSize == s;
        return GestureDetector(
          onTap: () => setState(() => selectedSize = s),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? Colors.deepPurple : Colors.grey[200],
            ),
            child: Text(
              s,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text("Quantity:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () {
            if (quantity > 1) setState(() => quantity--);
          },
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(quantity.toString(), style: const TextStyle(fontSize: 16)),
        IconButton(
          onPressed: () {
            setState(() => quantity++);
          },
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  // Reviews section removed – app no longer uses reviews here.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _stopAutoScroll();
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: _stopAutoScroll,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: AssetImage(widget.images[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.title, style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("In Stock", style: GoogleFonts.roboto(color: Colors.green, fontSize: 16)),
                const SizedBox(height: 8),
                Text("PKR 8,490.00", style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(
                  "This grey casual kameez shalwar is perfect for daily wear. Comfortable fabric with stylish design.",
                  style: GoogleFonts.roboto(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Text("Sizes", style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildSizeSelector(),
                const SizedBox(height: 20),
                _buildQuantitySelector(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedSize == null
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product added to cart!")));
                          },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text("BUY NOW", style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SizePredictorScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.deepPurple),
                    child: const Center(
                      child: Text("CUSTOMIZATION: HIRE A TAILOR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text("SKU: J-10000162840", style: GoogleFonts.roboto(color: Colors.grey)),
                const SizedBox(height: 20),
                const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}