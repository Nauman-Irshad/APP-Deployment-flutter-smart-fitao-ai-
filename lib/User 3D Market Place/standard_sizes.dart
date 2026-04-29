import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'order_summary_screen.dart';

/// Allows only digits and at most one decimal point.
class _NumericOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text;
    if (t.isEmpty) return newValue;
    if (RegExp(r'^\d*\.?\d*$').hasMatch(t)) return newValue;
    return oldValue;
  }
}

class StandardSizesScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onBack;

  const StandardSizesScreen({
    super.key,
    required this.product,
    required this.onBack,
  });

  @override
  _StandardSizesScreenState createState() => _StandardSizesScreenState();
}

class _StandardSizesScreenState extends State<StandardSizesScreen> {
  /// User must select one Kurta size and one Pyjama size; then Proceed is enabled.
  String? _selectedKurtaSize;
  String? _selectedPyjamaSize;
  final Map<String, TextEditingController> _controllers = {};

  /// Kurta measurements: Brand Size -> Chest, Waist, Hip, Shoulder, Front Length, Sleeve Length (inches)
  final Map<String, Map<String, String>> _kurtaChart = {
    'S/36': {'chest': '41', 'waist': '36', 'hip': '42', 'shoulder': '17', 'frontLength': '38', 'sleeveLength': '24'},
    'M/38': {'chest': '43', 'waist': '38', 'hip': '44', 'shoulder': '17.5', 'frontLength': '41', 'sleeveLength': '24.5'},
    'L/40': {'chest': '45', 'waist': '40', 'hip': '46', 'shoulder': '18', 'frontLength': '42', 'sleeveLength': '25'},
    'XL/42': {'chest': '47', 'waist': '42', 'hip': '48', 'shoulder': '18.5', 'frontLength': '43', 'sleeveLength': '25.5'},
    'XXL/44': {'chest': '49', 'waist': '44', 'hip': '50', 'shoulder': '19', 'frontLength': '44', 'sleeveLength': '26'},
  };

  /// Churidar/Pyjama measurements: Brand Size -> Length only (Chest is in Kurta above)
  final Map<String, Map<String, String>> _churidarChart = {
    'S/36': {'length': '39'},
    'M/38': {'length': '40'},
    'L/40': {'length': '42'},
    'XL/42': {'length': '43'},
    'XXL/44': {'length': '44'},
  };

  /// Only digits and at most one decimal point (numbers only)
  static final _numericFormatter = _NumericOnlyFormatter();

  List<String> get _sizeOptions => _kurtaChart.keys.toList();

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  TextEditingController _getController(String sizeKey, String fieldKey, bool isKurta) {
    final key = '${isKurta ? "k" : "c"}_${sizeKey}_$fieldKey';
    if (!_controllers.containsKey(key)) {
      final v = isKurta
          ? _kurtaChart[sizeKey]![fieldKey] ?? ''
          : _churidarChart[sizeKey]![fieldKey] ?? '';
      _controllers[key] = TextEditingController(text: v);
    }
    return _controllers[key]!;
  }

  void _updateKurta(String sizeKey, String fieldKey, String value) {
    if (value.isEmpty || RegExp(r'^\d*\.?\d*$').hasMatch(value)) {
      _kurtaChart[sizeKey]![fieldKey] = value;
      setState(() {});
    }
  }

  void _updateChuridar(String sizeKey, String fieldKey, String value) {
    if (value.isEmpty || RegExp(r'^\d*\.?\d*$').hasMatch(value)) {
      _churidarChart[sizeKey]![fieldKey] = value;
      setState(() {});
    }
  }

  Widget _buildEditableCell({
    required String sizeKey,
    required String fieldKey,
    required bool isKurta,
  }) {
    final controller = _getController(sizeKey, fieldKey, isKurta);
    return SizedBox(
      width: 72,
      child: TextField(
        key: ValueKey('${isKurta ? "k" : "c"}_${sizeKey}_$fieldKey'),
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_numericFormatter],
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          hintText: '0',
        ),
        style: TextStyle(fontSize: 13),
        onChanged: (v) {
          if (isKurta) _updateKurta(sizeKey, fieldKey, v);
          else _updateChuridar(sizeKey, fieldKey, v);
        },
      ),
    );
  }

  Widget _buildSizeCell(String size, bool isSelected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSelected) Icon(Icons.check, color: Color(0xFF059669), size: 16),
        if (isSelected) SizedBox(width: 4),
        Text(
          size,
          style: TextStyle(
            color: isSelected ? Color(0xFF059669) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf9fafb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF059669)),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Back',
          style: TextStyle(color: Color(0xFF059669), fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Standard Size Chart',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select your size from the chart below',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),


            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Choose Kurta Size (select one)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _sizeOptions.map((size) {
                      final isSelected = _selectedKurtaSize == size;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedKurtaSize = size),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFFf0fdf4) : Colors.white,
                            border: Border.all(
                              color: isSelected ? Color(0xFF059669) : Colors.grey[200]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            size,
                            style: TextStyle(
                              color: isSelected ? Color(0xFF059669) : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '2. Choose Pyjama Size (select one)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _sizeOptions.map((size) {
                      final isSelected = _selectedPyjamaSize == size;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedPyjamaSize = size),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFFf0fdf4) : Colors.white,
                            border: Border.all(
                              color: isSelected ? Color(0xFF059669) : Colors.grey[200]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            size,
                            style: TextStyle(
                              color: isSelected ? Color(0xFF059669) : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),


            // Kurta Measurements
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kurta Measurements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Chest included. Scroll right → All boxes editable (numbers only).',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                      columns: [
                        DataColumn(label: Text('Brand Size', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Chest', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Waist', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Hip', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Shoulder', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Front Length', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Sleeve Length', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _kurtaChart.entries.map((entry) {
                        final isSelected = _selectedKurtaSize == entry.key;
                        final sizeKey = entry.key;
                        return DataRow(
                          color: MaterialStateProperty.all(
                            isSelected ? Color(0xFFf0fdf4) : null,
                          ),
                          cells: [
                            DataCell(_buildSizeCell(sizeKey, isSelected)),
                            DataCell(_buildEditableCell(sizeKey: sizeKey, fieldKey: 'chest', isKurta: true)),
                            DataCell(_buildEditableCell(sizeKey: sizeKey, fieldKey: 'waist', isKurta: true)),
                            DataCell(_buildEditableCell(sizeKey: sizeKey, fieldKey: 'hip', isKurta: true)),
                            DataCell(_buildEditableCell(sizeKey: sizeKey, fieldKey: 'shoulder', isKurta: true)),
                            DataCell(_buildEditableCell(sizeKey: sizeKey, fieldKey: 'frontLength', isKurta: true)),
                            DataCell(_buildEditableCell(sizeKey: sizeKey, fieldKey: 'sleeveLength', isKurta: true)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Churidar/Pyjama Measurements
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Churidar/Pyjama Measurements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Select size and edit length. Numbers only. Scroll right →',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                      columns: [
                        DataColumn(label: Text('Brand Size', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Length', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _churidarChart.entries.map((entry) {
                        final isSelected = _selectedPyjamaSize == entry.key;
                        final sizeKey = entry.key;
                        return DataRow(
                          color: MaterialStateProperty.all(
                            isSelected ? Color(0xFFf0fdf4) : null,
                          ),
                          cells: [
                            DataCell(_buildSizeCell(sizeKey, isSelected)),
                            DataCell(_buildEditableCell(sizeKey: sizeKey, fieldKey: 'length', isKurta: false)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Single button at bottom: Final Size Chart (enabled only when both sizes selected)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedKurtaSize != null && _selectedPyjamaSize != null)
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FinalSizeChartScreen(
                              product: widget.product,
                              kurtaSize: _selectedKurtaSize!,
                              pyjamaSize: _selectedPyjamaSize!,
                              kurtaMeasurements: Map.from(_kurtaChart[_selectedKurtaSize]!),
                              pyjamaLength: _churidarChart[_selectedPyjamaSize]!['length'] ?? '',
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF059669),
                  disabledBackgroundColor: Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedKurtaSize != null && _selectedPyjamaSize != null
                      ? 'Final Size Chart'
                      : 'Select both Kurta and Pyjama size to continue',
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Read-only final chart: shows selected Kurta & Pyjama sizes in detail. Back returns to standard size screen.
class FinalSizeChartScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  final String kurtaSize;
  final String pyjamaSize;
  final Map<String, String> kurtaMeasurements;
  final String pyjamaLength;

  const FinalSizeChartScreen({
    super.key,
    required this.product,
    required this.kurtaSize,
    required this.pyjamaSize,
    required this.kurtaMeasurements,
    required this.pyjamaLength,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf9fafb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF059669)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Back to Standard Size',
          style: TextStyle(color: Color(0xFF059669), fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Final Size Chart',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your selected sizes (read-only). Tap Back to change.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 24),

            // Kurta section – read-only detail
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kurta – Size $kurtaSize',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                  SizedBox(height: 16),
                  _readOnlyRow('Chest', kurtaMeasurements['chest'] ?? '–'),
                  _readOnlyRow('Waist', kurtaMeasurements['waist'] ?? '–'),
                  _readOnlyRow('Hip', kurtaMeasurements['hip'] ?? '–'),
                  _readOnlyRow('Shoulder', kurtaMeasurements['shoulder'] ?? '–'),
                  _readOnlyRow('Front Length', kurtaMeasurements['frontLength'] ?? '–'),
                  _readOnlyRow('Sleeve Length', kurtaMeasurements['sleeveLength'] ?? '–'),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Pyjama section – read-only
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pyjama – Size $pyjamaSize',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                  SizedBox(height: 16),
                  _readOnlyRow('Length', pyjamaLength),
                ],
              ),
            ),

            SizedBox(height: 20),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Product',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Expanded(
                    child: Text(
                      product['title'] ?? '',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    'PKR ${product['price']}',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Checkout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderSummaryScreen(
                        product: product,
                        kurtaSize: kurtaSize,
                        pyjamaSize: pyjamaSize,
                        kurtaMeasurements: Map<String, String>.from(kurtaMeasurements),
                        pyjamaLength: pyjamaLength,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.shopping_cart_checkout, size: 22, color: Colors.white),
                label: Text(
                  'Checkout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF059669),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            // Back button to change size
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, size: 20, color: Color(0xFF059669)),
                label: Text(
                  'Back to Standard Size',
                  style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF059669), width: 2),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _readOnlyRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700], fontSize: 15),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
