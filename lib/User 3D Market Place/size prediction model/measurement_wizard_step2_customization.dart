import 'package:flutter/material.dart';

import 'cloth_measurement_models.dart';
import 'cloth_wizard_layout.dart';

typedef ClothStep2Complete = Future<void> Function(ClothWizardBodyPrefs data);

/// Flutter port of `MeasurementWizardStepBodyPrefs.tsx` — option strings unchanged.

class MeasurementWizardStep2Customization extends StatefulWidget {
  final ClothStep2Complete onComplete;
  final VoidCallback? onBack;
  final String? serverError;
  final ClothWizardBodyPrefs? initialValues;

  const MeasurementWizardStep2Customization({
    super.key,
    required this.onComplete,
    this.onBack,
    this.serverError,
    this.initialValues,
  });

  @override
  State<MeasurementWizardStep2Customization> createState() =>
      _MeasurementWizardStep2CustomizationState();
}

class _MeasurementWizardStep2CustomizationState
    extends State<MeasurementWizardStep2Customization> {
  static const _bodyTypes = [
    {'value': 'Slim', 'label': 'Slim'},
    {'value': 'Athletic', 'label': 'Athletic'},
    {'value': 'Average', 'label': 'Average'},
    {'value': 'Heavy', 'label': 'Heavy'},
  ];

  static const _collar = [
    {'value': 'Narrow', 'label': 'Narrow (tight collar)'},
    {'value': 'Regular', 'label': 'Regular'},
    {'value': 'Loose', 'label': 'Loose (comfort collar)'},
  ];

  static const _shoulder = [
    {'value': 'Narrow', 'label': 'Narrow'},
    {'value': 'Average', 'label': 'Average'},
    {'value': 'Broad', 'label': 'Broad'},
  ];

  static const _fit = [
    {'value': 'Tight', 'label': 'Tight (body fit)'},
    {'value': 'Regular', 'label': 'Regular (standard fit)'},
    {'value': 'Loose', 'label': 'Loose (relaxed fit)'},
  ];

  late String _bodyType;
  late String _collarFit;
  late String _shoulderType;
  late String _fitPreference;
  bool _loading = false;

  static const _green = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    final i = widget.initialValues;
    _bodyType = i?.bodyType ?? 'Athletic';
    _collarFit = i?.collarFit ?? 'Loose';
    _shoulderType = i?.shoulderType ?? 'Average';
    _fitPreference = i?.fitPreference ?? 'Regular';
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await widget.onComplete(ClothWizardBodyPrefs(
        bodyType: _bodyType,
        collarFit: _collarFit,
        shoulderType: _shoulderType,
        fitPreference: _fitPreference,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<Map<String, String>> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _green, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: options
                  .map((o) => DropdownMenuItem(
                        value: o['value'],
                        child: Text(o['label']!,
                            style: const TextStyle(fontSize: 15)),
                      ))
                  .toList(),
              onChanged: _loading ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleSize = ClothWizardLayout.stepTitleSize(context);
    final maxW = ClothWizardLayout.contentMaxWidth(context);
    final narrowActions = MediaQuery.sizeOf(context).width < 420;

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
            'Step 2 of 3',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _green,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Customization',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Body type, collar, shoulders, and fit preference refine how we translate your profile into garment-ready numbers.',
            style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Container(height: 8, decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 8, decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(4)))),
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
                if (widget.serverError != null &&
                    widget.serverError!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      widget.serverError!,
                      style: TextStyle(fontSize: 13, color: Colors.red[900]),
                    ),
                  ),
                _dropdown(
                  label: 'Body type',
                  value: _bodyType,
                  options: _bodyTypes,
                  onChanged: (v) => setState(() => _bodyType = v ?? _bodyType),
                ),
                const SizedBox(height: 22),
                _dropdown(
                  label: 'Collar fit',
                  value: _collarFit,
                  options: _collar,
                  onChanged: (v) => setState(() => _collarFit = v ?? _collarFit),
                ),
                const SizedBox(height: 22),
                _dropdown(
                  label: 'Shoulder type',
                  value: _shoulderType,
                  options: _shoulder,
                  onChanged: (v) =>
                      setState(() => _shoulderType = v ?? _shoulderType),
                ),
                const SizedBox(height: 22),
                _dropdown(
                  label: 'Fit preference',
                  value: _fitPreference,
                  options: _fit,
                  onChanged: (v) =>
                      setState(() => _fitPreference = v ?? _fitPreference),
                ),
                const SizedBox(height: 28),
                _step2ActionBar(narrowActions),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _step2ActionBar(bool narrow) {
    final continueBtn = ElevatedButton(
      onPressed: _loading ? null : () => _submit(),
      style: ElevatedButton.styleFrom(
        backgroundColor: _loading ? Colors.grey[300] : _green,
        foregroundColor: _loading ? Colors.grey[500] : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _loading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 10),
                Text('Working…',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ],
            )
          : Text(
              'Get my measurements',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
    );

    final backBtn = widget.onBack == null
        ? null
        : OutlinedButton(
            onPressed: _loading ? null : widget.onBack,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey[400]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 18),
                const SizedBox(width: 6),
                Text('Back to profile'),
              ],
            ),
          );

    if (narrow && backBtn != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: double.infinity, child: backBtn),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: continueBtn),
        ],
      );
    }

    return Row(
      children: [
        if (backBtn != null) ...[
          Expanded(child: backBtn),
          const SizedBox(width: 12),
        ],
        Expanded(child: continueBtn),
      ],
    );
  }
}
