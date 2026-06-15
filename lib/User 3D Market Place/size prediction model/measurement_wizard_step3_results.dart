import 'dart:convert';
import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloth_derived_lower_body.dart';
import 'cloth_measurement_accuracy.dart';
import 'cloth_measurement_merge.dart';
import 'cloth_studio_bridge.dart';
import 'studio_opener.dart';
import 'cloth_prediction_keys.dart';
import 'cloth_prediction_service.dart';
import 'cloth_wizard_layout.dart';
import '../../../services/customer_fitting_store.dart';

/// Flutter port of `Result3DAndChart.tsx` (same user-visible strings).

class MeasurementWizardStep3Results extends StatefulWidget {
  final Map<String, double> measurementsCm;
  final int heightTotalInches;
  final String bodyType;
  final String fitPreference;
  final VoidCallback onStartOver;
  final VoidCallback onEditDetails;
  final VoidCallback onEditQuestions;
  final ValueChanged<Map<String, double>> onContinueToTryOn;

  const MeasurementWizardStep3Results({
    super.key,
    required this.measurementsCm,
    required this.heightTotalInches,
    required this.bodyType,
    required this.fitPreference,
    required this.onStartOver,
    required this.onEditDetails,
    required this.onEditQuestions,
    required this.onContinueToTryOn,
  });

  @override
  State<MeasurementWizardStep3Results> createState() =>
      _MeasurementWizardStep3ResultsState();
}

class _MeasurementWizardStep3ResultsState extends State<MeasurementWizardStep3Results>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _modelMetrics;
  bool _showResults = false;
  int _progress = 0;
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  final Map<String, TextEditingController> _inchCtrls = {};
  final ScrollController _resultsScrollCtrl = ScrollController();
  String? _saveMessage;

  static const _green = Color(0xFF059669);

  Map<String, double> get _baseCm {
    final hCm = widget.heightTotalInches > 0
        ? widget.heightTotalInches * 2.54
        : null;
    return clothMergeDerivedLowerBody(
      Map<String, double>.from(widget.measurementsCm),
      hCm,
    );
  }

  static String _formatInchField(double? cm) {
    if (cm == null || cm.isNaN) return '';
    final inches = clothCmToInches(cm);
    return ((inches * 10).round() / 10).toStringAsFixed(1);
  }

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressCtrl,
      curve: Curves.easeOutCubic,
    );
    _progressAnim.addListener(() {
      setState(() {
        _progress = (_progressAnim.value * 100).round().clamp(0, 100);
      });
    });
    _progressCtrl.forward().then((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _showResults = true);
    });

    _syncInchInputsFromBase();
    _fetchMetrics();
  }

  void _syncInchInputsFromBase() {
    final base = _baseCm;
    for (final row in clothTwelveSummaryRows) {
      final k = row['apiField']!;
      final fmt = _formatInchField(base[k]);
      _inchCtrls.putIfAbsent(k, TextEditingController.new).text = fmt;
    }
  }

  Future<void> _fetchMetrics() async {
    final m = await ClothPredictionService.instance.fetchModelMetrics();
    if (mounted) setState(() => _modelMetrics = m);
  }

  @override
  void dispose() {
    for (final c in _inchCtrls.values) {
      c.dispose();
    }
    _resultsScrollCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Map<String, String> _inchInputStrings() {
    return _inchCtrls.map((k, c) => MapEntry(k, c.text));
  }

  Future<void> _handleOpenStudio() async {
    final merged =
        clothMergeMeasurementsFromInputs(_baseCm, _inchInputStrings());
    final perTarget = _modelMetrics?['per_target'] as Map<String, dynamic>?;
    final meanRaw = _modelMetrics?['mean_r2'];
    final meanR2 = meanRaw is num ? meanRaw.toDouble() : null;
    await StudioOpener.openFromMeasurements(
      context,
      measurementsCm: merged,
      fitPreference: widget.fitPreference,
      perTargetR2: perTarget,
      meanR2: meanR2,
    );
  }

  Future<void> _handleSave() async {
    final merged = clothMergeMeasurementsFromInputs(_baseCm, _inchInputStrings());
    final perTarget = _modelMetrics?['per_target'] as Map<String, dynamic>?;
    final meanRaw = _modelMetrics?['mean_r2'];
    final meanR2 = meanRaw is num ? meanRaw.toDouble() : null;
    final payload = clothBuildStoredFitPayload(
      merged,
      widget.fitPreference,
      perTargetR2: perTarget,
      meanR2: meanR2,
    );
    final prefs = await SharedPreferences.getInstance();
    final fitJson = jsonEncode(payload);
    await prefs.setString(clothStorageKeyLastFit, fitJson);
    CustomerFittingStore.webPersistLastFitJson(fitJson);
    await CustomerFittingStore.applySavedSizeToSession();
    if (!mounted) return;
    setState(() {
      _saveMessage = 'Size saved — your measurements are updated.';
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Size saved'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future<void>.delayed(const Duration(seconds: 4)).then((_) {
      if (mounted) setState(() => _saveMessage = null);
    });
  }

  Widget _classicLoadingPopup() {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: LayoutBuilder(
          builder: (ctx, _) {
            final mq = MediaQuery.sizeOf(ctx);
            final m = mq.width < 360 ? 16.0 : 28.0;
            return Container(
              margin: EdgeInsets.all(m),
              constraints:
                  BoxConstraints(maxWidth: min(400.0, mq.width - m * 2)),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFADADAD)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE8E8E8), Color(0xFFDADADA)],
                      ),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFADADAD)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top,
                            size: 18, color: Colors.grey[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please wait…',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.grey[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      children: [
                        Text(
                          'Cloth size prediction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Synthesizing your profile and fit choices into measurement estimates…',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Progress',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700])),
                            Text('$_progress%',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _green)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress / 100,
                            minHeight: 10,
                            backgroundColor: Colors.grey[300],
                            color: _green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Almost there — preparing your measurements…',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _measurementTableRow({
    required bool narrow,
    required String label,
    required String apiField,
    required String predictedDisplay,
    required bool isDerived,
  }) {
    _inchCtrls.putIfAbsent(apiField, TextEditingController.new);
    final predictedStyle = TextStyle(
      fontSize: narrow ? 12 : 13,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w600,
    );
    final predictedText = Text(
      predictedDisplay != '—' ? '$predictedDisplay in' : '—',
      textAlign: TextAlign.right,
      style: predictedStyle,
    );
    final badge = Tooltip(
      message: clothSourceBadgeTitle(isDerived),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDerived ? Colors.orange[100] : const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDerived
                ? Colors.orange[300]!
                : const Color(0xFF86EFAC),
          ),
        ),
        child: Text(
          'AI',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDerived ? Colors.orange[900] : const Color(0xFF14532D),
          ),
        ),
      ),
    );
    final labelWidget = Text(
      label,
      style: TextStyle(
        fontSize: narrow ? 11 : 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[900],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
    final field = SizedBox(
      height: narrow ? 36 : 32,
      child: TextField(
        controller: _inchCtrls[apiField],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: narrow ? 12 : 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: const Color(0xFFFFFEFF),
          hintText: 'Edit',
          suffixText: 'in',
          suffixStyle: TextStyle(fontSize: 10, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFADADAD)),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );

    final decoration = BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFD4D4D4)),
      borderRadius: BorderRadius.circular(4),
    );
    final pad = const EdgeInsets.symmetric(horizontal: 10, vertical: 8);

    if (narrow) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: pad,
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: labelWidget),
                const SizedBox(width: 8),
                badge,
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 72, child: predictedText),
                const SizedBox(width: 8),
                Expanded(child: field),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: pad,
      decoration: decoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 5, child: labelWidget),
          const SizedBox(width: 6),
          badge,
          const SizedBox(width: 8),
          SizedBox(width: 74, child: predictedText),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: field),
        ],
      ),
    );
  }

  Widget _classicResultsPopup(BuildContext context, Map<String, double> base) {
    final mq = MediaQuery.sizeOf(context);
    final sidePad = ClothWizardLayout.horizontalPadding(context);
    final narrow = mq.width < 440;
    final dialogW = min(560.0, max(180.0, mq.width - sidePad * 2));
    final verticalInset = narrow ? 12.0 : 24.0;
    final dialogH =
        max(280.0, min(mq.height * 0.92, mq.height - verticalInset * 2));

    Widget primaryActions() {
      final saveBtn = ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: const Text('Save'),
      );
      return SizedBox(
        width: double.infinity,
        child: saveBtn,
      );
    }

    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: sidePad,
            vertical: verticalInset,
          ),
          child: SizedBox(
            width: dialogW,
            height: dialogH,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF808080)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? 8 : 10,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFECECEC), Color(0xFFD8D8D8)],
                        ),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFADADAD)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.analytics_outlined,
                              size: 18, color: Colors.grey[900]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your results',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: narrow ? 13 : 14,
                                    color: Colors.grey[900],
                                  ),
                                ),
                                Text(
                                  'Step 3 of 3 · Measurements (inches)',
                                  style: TextStyle(
                                    fontSize: narrow ? 10 : 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Back to customization',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.close,
                                size: 20, color: Colors.grey[800]),
                            onPressed: widget.onEditQuestions,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _resultsScrollCtrl,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _resultsScrollCtrl,
                          padding: EdgeInsets.all(narrow ? 10 : 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${widget.bodyType} · ${widget.fitPreference}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: narrow ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Values come from AI (neural or geometry). '
                                'Edit inches anytime — tap Save to store your updated sizes.',
                                style: TextStyle(
                                  fontSize: narrow ? 10 : 11,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...clothTwelveSummaryRows.map((row) {
                                final apiField = row['apiField']!;
                                final label = row['label']!;
                                final isDerived =
                                    clothDerivedLowerBodyFields
                                        .contains(apiField);
                                final predictedStr =
                                    _formatInchField(base[apiField]);
                                final predictedDisplay =
                                    predictedStr.isNotEmpty
                                        ? predictedStr
                                        : '—';
                                return _measurementTableRow(
                                  narrow: narrow,
                                  label: label,
                                  apiField: apiField,
                                  predictedDisplay: predictedDisplay,
                                  isDerived: isDerived,
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(narrow ? 10 : 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8E8E8),
                        border: Border(
                          top: BorderSide(color: Color(0xFFADADAD)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          primaryActions(),
                          if (_saveMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _saveMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.green[900]),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              TextButton(
                                onPressed: widget.onEditDetails,
                                child: Text(
                                  'Edit age, height & weight',
                                  style: TextStyle(fontSize: narrow ? 12 : 14),
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onEditQuestions,
                                child: Text(
                                  'Back to customization',
                                  style: TextStyle(fontSize: narrow ? 12 : 14),
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onStartOver,
                                child: Text(
                                  'Start over',
                                  style: TextStyle(fontSize: narrow ? 12 : 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _handleOpenStudio,
                            icon: const Icon(Icons.view_in_ar_outlined, size: 18),
                            label: const Text('Open 3D Studio'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              final merged = clothMergeMeasurementsFromInputs(
                                  _baseCm, _inchInputStrings());
                              widget.onContinueToTryOn(merged);
                            },
                            icon:
                                const Icon(Icons.checkroom_outlined, size: 18),
                            label: const Text('Continue to 2D Try-On'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = _baseCm;
    final sz = MediaQuery.sizeOf(context);

    // Bounded size: this widget can sit inside a Column in a scroll view;
    // StackFit.expand + unbounded height causes layout failure.
    return SizedBox(
      height: sz.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.grey[200]!.withValues(alpha: 0.35)),
          if (_showResults)
            _classicResultsPopup(context, base)
          else
            _classicLoadingPopup(),
        ],
      ),
    );
  }
}
