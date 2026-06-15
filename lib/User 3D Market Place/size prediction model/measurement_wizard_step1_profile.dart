import 'package:flutter/material.dart';

import 'cloth_measurement_models.dart';
import 'cloth_wizard_layout.dart';

typedef ClothStep1Complete = void Function(ClothWizardStep1Data data);

/// Flutter port of `MeasurementWizardStep1.tsx` — UI copy unchanged.

class MeasurementWizardStep1Profile extends StatefulWidget {
  final ClothStep1Complete onComplete;
  final ClothWizardStep1Data? initialValues;

  const MeasurementWizardStep1Profile({
    super.key,
    required this.onComplete,
    this.initialValues,
  });

  @override
  State<MeasurementWizardStep1Profile> createState() =>
      _MeasurementWizardStep1ProfileState();
}

class _MeasurementWizardStep1ProfileState
    extends State<MeasurementWizardStep1Profile> {
  static const _defaults = ClothWizardStep1Data(
    age: '30',
    heightFeet: '5',
    heightInches: '9',
    weight: '165',
  );

  late TextEditingController _age;
  late TextEditingController _heightFeet;
  late TextEditingController _heightInches;
  late TextEditingController _weight;

  String? _focusedField;
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    final i = widget.initialValues;
    _age = TextEditingController(text: _pick(i?.age, _defaults.age));
    _heightFeet =
        TextEditingController(text: _pick(i?.heightFeet, _defaults.heightFeet));
    _heightInches = TextEditingController(
        text: _pick(i?.heightInches, _defaults.heightInches));
    _weight = TextEditingController(text: _pick(i?.weight, _defaults.weight));
  }

  String _pick(String? v, String d) =>
      (v != null && v.trim().isNotEmpty) ? v.trim() : d;

  @override
  void dispose() {
    _age.dispose();
    _heightFeet.dispose();
    _heightInches.dispose();
    _weight.dispose();
    super.dispose();
  }

  bool _validateForm() {
    _errors.clear();
    final ageNum = int.tryParse(_age.text);
    final feetNum = int.tryParse(_heightFeet.text);
    final inchesNum = int.tryParse(_heightInches.text);
    final weightNum = double.tryParse(_weight.text);

    if (_age.text.isNotEmpty &&
        (ageNum == null || ageNum < 18 || ageNum > 100)) {
      _errors['age'] = 'Age must be between 18 and 100 years';
    }
    if (_heightFeet.text.isNotEmpty &&
        (feetNum == null || feetNum < 4 || feetNum > 7)) {
      _errors['heightFeet'] = 'Feet must be between 4 and 7';
    }
    if (_heightInches.text.isNotEmpty &&
        (inchesNum == null || inchesNum < 0 || inchesNum > 11)) {
      _errors['heightInches'] = 'Inches must be between 0 and 11';
    }
    if (_weight.text.isNotEmpty &&
        (weightNum == null || weightNum < 100 || weightNum > 350)) {
      _errors['weight'] = 'Weight must be between 100 and 350 lbs';
    }
    setState(() {});
    return _errors.isEmpty;
  }

  bool get _isFormValid {
    if (_age.text.isEmpty ||
        _heightFeet.text.isEmpty ||
        _heightInches.text.isEmpty ||
        _weight.text.isEmpty) {
      return false;
    }
    final ageNum = int.tryParse(_age.text);
    final feetNum = int.tryParse(_heightFeet.text);
    final inchesNum = int.tryParse(_heightInches.text);
    final weightNum = double.tryParse(_weight.text);
    if (ageNum == null || ageNum < 18 || ageNum > 100) return false;
    if (feetNum == null || feetNum < 4 || feetNum > 7) return false;
    if (inchesNum == null || inchesNum < 0 || inchesNum > 11) return false;
    if (weightNum == null || weightNum < 100 || weightNum > 350) return false;
    return true;
  }

  void _submit() {
    if (!_validateForm()) return;
    widget.onComplete(ClothWizardStep1Data(
      age: _age.text,
      heightFeet: _heightFeet.text,
      heightInches: _heightInches.text,
      weight: _weight.text,
    ));
  }

  static const _green = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    final titleSize = ClothWizardLayout.stepTitleSize(context);
    final maxW = ClothWizardLayout.contentMaxWidth(context);
    return SingleChildScrollView(
      padding: ClothWizardLayout.pagePadding(context),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: maxW > 0 ? maxW : double.infinity),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step 1 of 3',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _green,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Profile',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter age, height, and weight. We use these with your fit choices to predict kameez-friendly body measurements in inches.',
            style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Container(height: 8, decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 8, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)))),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 8, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)))),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Age, height & weight',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 24),
                _fieldLabel('Age (years)', 'age'),
                _numberField(
                  controller: _age,
                  hint: '30',
                  suffix: 'years',
                  fieldKey: 'age',
                  min: 18,
                  max: 100,
                ),
                if (_errors['age'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_errors['age']!,
                        style: const TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                const SizedBox(height: 24),
                _fieldLabel('Height', 'heightFeet'),
                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        controller: _heightFeet,
                        hint: 'Feet',
                        suffix: 'ft',
                        fieldKey: 'heightFeet',
                        min: 4,
                        max: 7,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(
                        controller: _heightInches,
                        hint: 'Inches',
                        suffix: 'in',
                        fieldKey: 'heightInches',
                        min: 0,
                        max: 11,
                      ),
                    ),
                  ],
                ),
                if (_errors['heightFeet'] != null ||
                    _errors['heightInches'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _errors['heightFeet'] ?? _errors['heightInches']!,
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                _fieldLabel('Weight (lbs)', 'weight'),
                _numberField(
                  controller: _weight,
                  hint: '165',
                  suffix: 'lbs',
                  fieldKey: 'weight',
                  min: 100,
                  max: 350,
                  step: true,
                ),
                if (_errors['weight'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_errors['weight']!,
                        style: const TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isFormValid ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid ? _green : Colors.grey[300],
                      foregroundColor: _isFormValid ? Colors.white : Colors.grey[500],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _isFormValid ? 2 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue to customization',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, String fieldKey) {
    final err = _errors.containsKey(fieldKey) ||
        (fieldKey == 'heightFeet' &&
            (_errors.containsKey('heightFeet') ||
                _errors.containsKey('heightInches')));
    final focus = _focusedField == fieldKey ||
        (fieldKey == 'heightFeet' &&
            (_focusedField == 'heightFeet' || _focusedField == 'heightInches'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: err ? Colors.red[700] : focus ? _green : Colors.grey[800],
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String hint,
    required String suffix,
    required String fieldKey,
    int? min,
    int? max,
    bool step = false,
  }) {
    final err = _errors[fieldKey] != null;
    final focus = _focusedField == fieldKey;
    return TextField(
      controller: controller,
      keyboardType:
          step ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        suffixText: suffix,
        suffixStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: err ? Colors.red : focus ? _green : Colors.grey[300]!,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: err ? Colors.red : focus ? _green : Colors.grey[200]!,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: err ? Colors.red : _green, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      onTap: () => setState(() => _focusedField = fieldKey),
      onChanged: (_) {
        _errors.remove(fieldKey);
        setState(() {});
      },
      onSubmitted: (_) {
        _focusedField = null;
        _validateForm();
      },
      onEditingComplete: () {
        _focusedField = null;
        _validateForm();
      },
    );
  }
}
