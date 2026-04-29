import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SizePredictorScreen extends StatefulWidget {
  const SizePredictorScreen({super.key});

  @override
  _SizePredictorScreenState createState() => _SizePredictorScreenState();
}

class _SizePredictorScreenState extends State<SizePredictorScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController chestController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController hipController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  String? predictedSize;

  void _predictSize() {
    if (_formKey.currentState!.validate()) {
      double chest = double.parse(chestController.text);
      double waist = double.parse(waistController.text);
      double hip = double.parse(hipController.text);
      double height = double.parse(heightController.text);

      if (chest < 36 && waist < 30) {
        predictedSize = 'S';
      } else if (chest < 40 && waist < 34) {
        predictedSize = 'M';
      } else if (chest < 44 && waist < 38) {
        predictedSize = 'L';
      } else {
        predictedSize = 'XL';
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Size Predictor", style: GoogleFonts.roboto()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Enter your measurements", style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildMeasurementField("Chest (inches)", chestController),
                const SizedBox(height: 10),
                _buildMeasurementField("Waist (inches)", waistController),
                const SizedBox(height: 10),
                _buildMeasurementField("Hip (inches)", hipController),
                const SizedBox(height: 10),
                _buildMeasurementField("Height (inches)", heightController),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _predictSize,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Predict Size", style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 20),
                if (predictedSize != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Suggested Size: $predictedSize",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (double.tryParse(value) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
    );
  }
}