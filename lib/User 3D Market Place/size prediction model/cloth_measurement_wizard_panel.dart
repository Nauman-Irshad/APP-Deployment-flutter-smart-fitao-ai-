import 'package:flutter/material.dart';

import 'cloth_measurement_models.dart';
import 'cloth_prediction_config.dart';
import 'cloth_prediction_keys.dart';
import 'cloth_prediction_service.dart';
import 'measurement_wizard_step1_profile.dart';
import 'measurement_wizard_step2_customization.dart';
import 'measurement_wizard_step3_results.dart';

/// Flutter port of React `App.tsx` wizard flow (steps 1→2→3).

class ClothMeasurementWizardPanel extends StatefulWidget {
  /// Called after step 3 when user taps **Continue to 2D Try-On** — [mergedCm] is edit-merge + geometry (cm).
  final void Function(
    ClothWizardStep1Data step1,
    Map<String, double> mergedCm,
    ClothWizardBodyPrefs prefs,
  ) onContinueToTryOn;

  const ClothMeasurementWizardPanel({
    super.key,
    required this.onContinueToTryOn,
  });

  @override
  State<ClothMeasurementWizardPanel> createState() =>
      _ClothMeasurementWizardPanelState();
}

class _ClothMeasurementWizardPanelState
    extends State<ClothMeasurementWizardPanel> {
  int _step = 1;
  ClothWizardStep1Data? _step1;
  ClothWizardBodyPrefs? _prefs;
  Map<String, double>? _predictionsCm;
  String? _predictError;

  int _heightTotalInches(ClothWizardStep1Data s) {
    final ft = int.tryParse(s.heightFeet) ?? 0;
    final inch = int.tryParse(s.heightInches) ?? 0;
    return ft * 12 + inch;
  }

  Future<void> _onBodyPrefsComplete(ClothWizardBodyPrefs data) async {
    final s1 = _step1;
    if (s1 == null) return;
    setState(() => _predictError = null);
    try {
      final raw = await ClothPredictionService.instance.predict(
        step1: s1,
        prefs: data,
      );
      final dyn = Map<String, dynamic>.from(raw);
      if (!clothIsCorePredictionComplete(dyn)) {
        setState(() {
          _predictError =
              'Server returned incomplete measurements (core body fields missing). Check Flask and the model.';
        });
        return;
      }
      setState(() {
        _prefs = data;
        _predictionsCm = raw;
        _step = 3;
      });
    } catch (e) {
      setState(() {
        _predictError = e is ClothPredictionException
            ? e.message
            : (ClothPredictionConfig.usesLiveRender
                ? 'Live size API (${ClothPredictionConfig.baseUrl}) — wait and try Predict again.'
                : 'Could not reach /predict at ${ClothPredictionConfig.baseUrl}. '
                    'Run: pifuhd-main\\Ai Cloth Size Prediction\\start-flask.ps1');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 1) {
      return MeasurementWizardStep1Profile(
        initialValues: _step1,
        onComplete: (d) => setState(() {
          _step1 = d;
          _step = 2;
          _predictError = null;
        }),
      );
    }
    if (_step == 2) {
      return MeasurementWizardStep2Customization(
        initialValues: _prefs,
        serverError: _predictError,
        onBack: () => setState(() {
          _predictError = null;
          _step = 1;
        }),
        onComplete: _onBodyPrefsComplete,
      );
    }
    final s1 = _step1!;
    final prefs = _prefs!;
    final pred = _predictionsCm!;
    return MeasurementWizardStep3Results(
      measurementsCm: pred,
      heightTotalInches: _heightTotalInches(s1),
      bodyType: prefs.bodyType,
      fitPreference: prefs.fitPreference,
      onStartOver: () => setState(() {
        _step = 1;
        _step1 = null;
        _prefs = null;
        _predictionsCm = null;
        _predictError = null;
      }),
      onEditDetails: () => setState(() {
        _predictError = null;
        _step = 1;
      }),
      onEditQuestions: () => setState(() {
        _predictError = null;
        _step = 2;
      }),
      onContinueToTryOn: (mergedCm) =>
          widget.onContinueToTryOn(s1, mergedCm, prefs),
    );
  }
}
